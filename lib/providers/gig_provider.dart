import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:wawu_mobile/models/gig.dart';
import 'package:wawu_mobile/providers/base_provider.dart';
import 'package:wawu_mobile/services/api_service.dart';
import 'package:wawu_mobile/services/pusher_service.dart';

class GigProvider extends BaseProvider {
  final ApiService _apiService;
  final PusherService _pusherService;

  final Map<String, List<Gig>> _gigsByStatus = {
    'all': [],
    'PENDING': [],
    'VERIFIED': [],
    'ARCHIVED': [],
    'REJECTED': [],
  };
  Gig? _selectedGig;
  bool _isGeneralChannelSubscribed = false;
  final List<String> _specificGigChannels = [];

  List<Gig> get gigs => _gigsByStatus['all']!;
  List<Gig> gigsForStatus(String? status) => _gigsByStatus[status ?? 'all']!;
  Gig? get selectedGig => _selectedGig;

  GigProvider({ApiService? apiService, PusherService? pusherService})
    : _apiService = apiService ?? ApiService(),
      _pusherService = pusherService ?? PusherService();

  Future<List<Gig>> fetchGigs({String? status}) async {
    setLoading();

    try {
      final Map<String, dynamic> queryParams =
          status != null && status.isNotEmpty ? {'status': status} : {};
      final response = await _apiService.get<Map<String, dynamic>>(
        '/seller/gig',
        queryParameters: queryParams,
      );

      if (response['statusCode'] == 200 && response['data'] is List) {
        final List<dynamic> gigsJson = response['data'] as List<dynamic>;

        // Process and sort the gigs
        final List<Gig> gigs =
            gigsJson
                .map((json) => Gig.fromJson(json as Map<String, dynamic>))
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        final statusKey = status ?? 'all';
        _gigsByStatus[statusKey] = gigs;

        // Only update 'all' tab if we're not already fetching all gigs
        if (status != null) {
          // Create a map of existing gigs in 'all' by their UUID
          final existingGigs = <String, Gig>{};
          for (final gig in _gigsByStatus['all'] ?? <Gig>[]) {
            existingGigs[gig.uuid] = gig;
          }

          // Add or update gigs in 'all' list
          for (final gig in gigs) {
            existingGigs[gig.uuid] = gig;
          }

          // Convert back to list and sort
          final allGigs =
              existingGigs.values.toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          _gigsByStatus['all'] = allGigs;
        }

        if (!_isGeneralChannelSubscribed) {
          await _subscribeToGeneralGigsChannel();
        }

        setSuccess();
        return gigs;
      } else {
        debugPrint('Invalid response format from /seller/gig');
        _gigsByStatus[status ?? 'all'] = [];
        setError('Invalid response format from /seller/gig');
        return [];
      }
    } catch (e) {
      debugPrint('Failed to fetch gigs: $e');
      _gigsByStatus[status ?? 'all'] = [];
      setError('Failed to fetch gigs: $e');
      return [];
    }
  }

  Future<Gig?> createGig(FormData payload) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/seller/gig',
        data: payload,
      );
      if (response['statusCode'] == 200 && response['data'] != null) {
        final gig = Gig.fromJson(response['data'] as Map<String, dynamic>);
        _gigsByStatus['all']!.insert(0, gig);
        _gigsByStatus['PENDING']!.insert(0, gig);
        notifyListeners();
        return gig;
      }
      return null;
    } catch (e) {
      debugPrint('Failed to create gig: $e');
      return null;
    }
  }

  Future<bool> postReview(String gigId, Map<String, dynamic> reviewData) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/seller/gig/$gigId/reviews',
        data: reviewData,
      );
      return response['statusCode'] == 200;
    } catch (e) {
      debugPrint('Failed to post review: $e');
      return false;
    }
  }

  Future<List<Gig>> fetchGigsBySubCategory(String subCategoryId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/seller/gig/sub-category/$subCategoryId',
        queryParameters: {'status': 'VERIFIED'},
      );
      if (response['statusCode'] == 200 && response['data'] is List) {
        final List<dynamic> gigsJson = response['data'] as List<dynamic>;
        final gigs =
            gigsJson
                .map((json) => Gig.fromJson(json as Map<String, dynamic>))
                .toList();
        return gigs;
      }
      return [];
    } catch (e) {
      debugPrint('Failed to fetch gigs by subcategory: $e');
      return [];
    }
  }

  void selectGig(String gigUuid) {
    try {
      _selectedGig = _gigsByStatus.values
          .expand((gigs) => gigs)
          .firstWhere(
            (gig) => gig.uuid == gigUuid,
            orElse: () => throw Exception('Gig not found'),
          );

      for (final channel in _specificGigChannels) {
        _pusherService.unsubscribeFromChannel(channel);
      }
      _specificGigChannels.clear();

      final channels = [
        'gig.approved.$gigUuid',
        'gig.rejected.$gigUuid',
        'gig.review.$gigUuid',
      ];

      for (final channel in channels) {
        _pusherService.subscribeToChannel(channel).then((chan) {
          if (chan != null) {
            _specificGigChannels.add(channel);
            _pusherService.bindToEvent(channel, channel.split('.')[1], (data) {
              _handleGigEvent(channel, data);
            });
          }
        });
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to select gig: $e');
    }
  }

  void clearSelectedGig() {
    for (final channel in _specificGigChannels) {
      _pusherService.unsubscribeFromChannel(channel);
    }
    _specificGigChannels.clear();
    _selectedGig = null;
    notifyListeners();
  }

  Future<void> _subscribeToGeneralGigsChannel() async {
    const channelName = 'gigs';
    try {
      final channel = await _pusherService.subscribeToChannel(channelName);
      if (channel == null) {
        debugPrint('Failed to subscribe to general gigs channel');
        return;
      }

      _isGeneralChannelSubscribed = true;

      _pusherService.bindToEvent(channelName, 'gig.created', (data) {
        if (data is String) {
          final gigData = jsonDecode(data) as Map<String, dynamic>;
          final newGig = Gig.fromJson({...gigData, 'status': 'PENDING'});
          _gigsByStatus['all']!.insert(0, newGig);
          _gigsByStatus['PENDING']!.insert(0, newGig);
          _gigsByStatus['all']!.sort(
            (a, b) => b.createdAt.compareTo(a.createdAt),
          );
          _gigsByStatus['PENDING']!.sort(
            (a, b) => b.createdAt.compareTo(a.createdAt),
          );
          notifyListeners();
        }
      });

      _pusherService.bindToEvent(channelName, 'gig.deleted', (data) {
        if (data is String) {
          final deletedGigData = jsonDecode(data) as Map<String, dynamic>;
          final gigUuid = deletedGigData['gig_uuid'] as String?;
          if (gigUuid != null) {
            for (final status in _gigsByStatus.keys) {
              _gigsByStatus[status]!.removeWhere((gig) => gig.uuid == gigUuid);
            }
            if (_selectedGig?.uuid == gigUuid) {
              _selectedGig = null;
            }
            notifyListeners();
          }
        }
      });
    } catch (e) {
      debugPrint('Failed to subscribe to general gigs channel: $e');
    }
  }

  void _handleGigEvent(String channel, dynamic data) {
    try {
      if (data is String) {
        final eventData = jsonDecode(data) as Map<String, dynamic>;
        final gigUuid = eventData['gig_uuid'] as String?;
        if (gigUuid != null && eventData['gig'] is Map<String, dynamic>) {
          final updatedGig = Gig.fromJson(
            eventData['gig'] as Map<String, dynamic>,
          );
          for (final status in _gigsByStatus.keys) {
            final index = _gigsByStatus[status]!.indexWhere(
              (gig) => gig.uuid == gigUuid,
            );
            if (index != -1) {
              _gigsByStatus[status]![index] = updatedGig;
            } else if (status == updatedGig.status ||
                (status == 'all' && updatedGig.status.isNotEmpty)) {
              _gigsByStatus[status]!.insert(0, updatedGig);
            }
            _gigsByStatus[status]!.sort(
              (a, b) => b.createdAt.compareTo(a.createdAt),
            );
          }
          if (_selectedGig?.uuid == gigUuid) {
            _selectedGig = updatedGig;
          }
          notifyListeners();
        } else {
          debugPrint('Gig event missing gig data on $channel');
        }
      }
    } catch (e) {
      debugPrint('Failed to handle gig event on $channel: $e');
    }
  }

  void clearAll() {
    _gigsByStatus.forEach((key, _) => _gigsByStatus[key] = []);
    clearSelectedGig();
    _isGeneralChannelSubscribed = false;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_isGeneralChannelSubscribed) {
      _pusherService.unsubscribeFromChannel('gigs');
    }
    for (final channel in _specificGigChannels) {
      _pusherService.unsubscribeFromChannel(channel);
    }
    _specificGigChannels.clear();
    super.dispose();
  }
}
