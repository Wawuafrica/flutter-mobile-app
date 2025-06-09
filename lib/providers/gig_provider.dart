import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
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
        '/services/$subCategoryId/gigs',
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

  void selectGig(Gig gig) {
    _selectedGig = gig;
  }

  void clearSelectedGig() {
    _selectedGig = null;
    notifyListeners();
  }

  Future<void> _subscribeToGeneralGigsChannel() async {
    const channelName = 'gigs';
    try {
      final success = await _pusherService.subscribeToChannel(channelName);
      if (!success) {
        debugPrint('Failed to subscribe to general gigs channel');
        return;
      }

      _isGeneralChannelSubscribed = true;

      // Bind to gig.created event
      _pusherService.bindToEvent(channelName, 'gig.created', (event) {
        try {
          if (event.data is String) {
            final gigData = jsonDecode(event.data) as Map<String, dynamic>;
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
            debugPrint('GigProvider: New gig created and added to lists');
          } else {
            debugPrint('GigProvider: Invalid gig.created event data format');
          }
        } catch (e) {
          debugPrint('GigProvider: Error processing gig.created event: $e');
        }
      });

      // Bind to gig.deleted event
      _pusherService.bindToEvent(channelName, 'gig.deleted', (event) {
        try {
          if (event.data is String) {
            final deletedGigData =
                jsonDecode(event.data) as Map<String, dynamic>;
            final gigUuid = deletedGigData['gig_uuid'] as String?;
            if (gigUuid != null) {
              for (final status in _gigsByStatus.keys) {
                _gigsByStatus[status]!.removeWhere(
                  (gig) => gig.uuid == gigUuid,
                );
              }
              if (_selectedGig?.uuid == gigUuid) {
                _selectedGig = null;
              }
              notifyListeners();
              debugPrint('GigProvider: Gig $gigUuid removed from all lists');
            } else {
              debugPrint('GigProvider: gig.deleted event missing gig_uuid');
            }
          } else {
            debugPrint('GigProvider: Invalid gig.deleted event data format');
          }
        } catch (e) {
          debugPrint('GigProvider: Error processing gig.deleted event: $e');
        }
      });

      debugPrint(
        'GigProvider: Successfully subscribed to general gigs channel and bound events',
      );
    } catch (e) {
      debugPrint(
        'GigProvider: Failed to subscribe to general gigs channel: $e',
      );
    }
  }

  Future<void> subscribeToSpecificGigChannel(String gigUuid) async {
    final channelName = 'gig.$gigUuid';

    if (_specificGigChannels.contains(channelName)) {
      debugPrint(
        'GigProvider: Already subscribed to specific gig channel: $channelName',
      );
      return;
    }

    try {
      final success = await _pusherService.subscribeToChannel(channelName);
      if (!success) {
        debugPrint(
          'GigProvider: Failed to subscribe to specific gig channel: $channelName',
        );
        return;
      }

      _specificGigChannels.add(channelName);

      // Bind to gig.approved event
      _pusherService.bindToEvent(channelName, 'gig.approved', (event) {
        _handleGigApprovedEvent(channelName, event);
      });

      // Bind to gig.rejected event
      _pusherService.bindToEvent(channelName, 'gig.rejected', (event) {
        _handleGigRejectedEvent(channelName, event);
      });

      // Bind to gig.review event (new review added)
      _pusherService.bindToEvent(channelName, 'gig.review', (event) {
        _handleGigReviewEvent(channelName, event);
      });

      debugPrint(
        'GigProvider: Successfully subscribed to specific gig channel: $channelName',
      );
    } catch (e) {
      debugPrint(
        'GigProvider: Failed to subscribe to specific gig channel $channelName: $e',
      );
    }
  }

  void _handleGigApprovedEvent(String channel, PusherEvent event) {
    try {
      if (event.data is String) {
        final eventData = jsonDecode(event.data) as Map<String, dynamic>;
        final gigUuid = eventData['gig_uuid'] as String?;
        if (gigUuid != null && eventData['gig'] is Map<String, dynamic>) {
          final updatedGig = Gig.fromJson(
            eventData['gig'] as Map<String, dynamic>,
          );

          // Update gig status to VERIFIED
          final approvedGig = Gig(
            uuid: updatedGig.uuid,
            title: updatedGig.title,
            description: updatedGig.description,
            keywords: updatedGig.keywords,
            about: updatedGig.about,
            seller: updatedGig.seller,
            services: updatedGig.services,
            pricings: updatedGig.pricings,
            faqs: updatedGig.faqs,
            assets: updatedGig.assets,
            status: 'VERIFIED', // Set status to VERIFIED for approved gigs
            reviews: updatedGig.reviews,
          );

          _updateGigInAllLists(gigUuid, approvedGig);
          debugPrint('GigProvider: Gig $gigUuid approved and updated');
        }
      }
    } catch (e) {
      debugPrint('GigProvider: Error processing gig.approved event: $e');
    }
  }

  void _handleGigRejectedEvent(String channel, PusherEvent event) {
    try {
      if (event.data is String) {
        final eventData = jsonDecode(event.data) as Map<String, dynamic>;
        final gigUuid = eventData['gig_uuid'] as String?;
        if (gigUuid != null && eventData['gig'] is Map<String, dynamic>) {
          final updatedGig = Gig.fromJson(
            eventData['gig'] as Map<String, dynamic>,
          );

          // Update gig status to REJECTED
          final rejectedGig = Gig(
            uuid: updatedGig.uuid,
            title: updatedGig.title,
            description: updatedGig.description,
            keywords: updatedGig.keywords,
            about: updatedGig.about,
            seller: updatedGig.seller,
            services: updatedGig.services,
            pricings: updatedGig.pricings,
            faqs: updatedGig.faqs,
            assets: updatedGig.assets,
            status: 'REJECTED', // Set status to REJECTED for rejected gigs
            reviews: updatedGig.reviews,
          );

          _updateGigInAllLists(gigUuid, rejectedGig);
          debugPrint('GigProvider: Gig $gigUuid rejected and updated');
        }
      }
    } catch (e) {
      debugPrint('GigProvider: Error processing gig.rejected event: $e');
    }
  }

  void _handleGigReviewEvent(String channel, PusherEvent event) {
    try {
      if (event.data is String) {
        final eventData = jsonDecode(event.data) as Map<String, dynamic>;
        final gigUuid = eventData['gig_uuid'] as String?;

        if (gigUuid != null) {
          // Check if we have review data
          if (eventData['review'] is Map<String, dynamic>) {
            final reviewData = eventData['review'] as Map<String, dynamic>;
            final newReview = Review.fromJson(reviewData);

            // Add review to the gig
            _addReviewToGig(gigUuid, newReview);
            debugPrint('GigProvider: New review added to gig $gigUuid');
          } else if (eventData['gig'] is Map<String, dynamic>) {
            // If full gig data is provided with updated reviews
            final updatedGig = Gig.fromJson(
              eventData['gig'] as Map<String, dynamic>,
            );
            _updateGigInAllLists(gigUuid, updatedGig);
            debugPrint('GigProvider: Gig $gigUuid updated with new reviews');
          }
        }
      }
    } catch (e) {
      debugPrint('GigProvider: Error processing gig.review event: $e');
    }
  }

  void _updateGigInAllLists(String gigUuid, Gig updatedGig) {
    bool gigUpdated = false;

    // Update existing gig in all status lists
    for (final status in _gigsByStatus.keys) {
      final index = _gigsByStatus[status]!.indexWhere(
        (gig) => gig.uuid == gigUuid,
      );
      if (index != -1) {
        _gigsByStatus[status]![index] = updatedGig;
        gigUpdated = true;
      }
    }

    // If gig wasn't found in existing lists but should be added
    if (!gigUpdated) {
      // Add to 'all' list
      _gigsByStatus['all']!.insert(0, updatedGig);

      // Add to specific status list if it exists
      if (_gigsByStatus.containsKey(updatedGig.status)) {
        _gigsByStatus[updatedGig.status]!.insert(0, updatedGig);
      }
    }

    // Remove gig from status lists where it no longer belongs
    for (final status in _gigsByStatus.keys) {
      if (status != 'all' && status != updatedGig.status) {
        _gigsByStatus[status]!.removeWhere((gig) => gig.uuid == gigUuid);
      }
    }

    // Sort all lists after updates
    for (final status in _gigsByStatus.keys) {
      _gigsByStatus[status]!.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    // Update selected gig if it matches
    if (_selectedGig?.uuid == gigUuid) {
      _selectedGig = updatedGig;
    }

    notifyListeners();
  }

  void _addReviewToGig(String gigUuid, Review newReview) {
    for (final status in _gigsByStatus.keys) {
      final index = _gigsByStatus[status]!.indexWhere(
        (gig) => gig.uuid == gigUuid,
      );
      if (index != -1) {
        final currentGig = _gigsByStatus[status]![index];
        final updatedReviews = [...currentGig.reviews, newReview];

        // Create updated gig with new review
        final updatedGig = Gig(
          uuid: currentGig.uuid,
          title: currentGig.title,
          description: currentGig.description,
          keywords: currentGig.keywords,
          about: currentGig.about,
          seller: currentGig.seller,
          services: currentGig.services,
          pricings: currentGig.pricings,
          faqs: currentGig.faqs,
          assets: currentGig.assets,
          status: currentGig.status,
          reviews: updatedReviews,
        );

        _gigsByStatus[status]![index] = updatedGig;
      }
    }

    // Update selected gig if it matches
    if (_selectedGig?.uuid == gigUuid) {
      final updatedReviews = [..._selectedGig!.reviews, newReview];
      _selectedGig = Gig(
        uuid: _selectedGig!.uuid,
        title: _selectedGig!.title,
        description: _selectedGig!.description,
        keywords: _selectedGig!.keywords,
        about: _selectedGig!.about,
        seller: _selectedGig!.seller,
        services: _selectedGig!.services,
        pricings: _selectedGig!.pricings,
        faqs: _selectedGig!.faqs,
        assets: _selectedGig!.assets,
        status: _selectedGig!.status,
        reviews: updatedReviews,
      );
    }

    notifyListeners();
  }

  void unsubscribeFromSpecificGigChannel(String gigUuid) {
    final channelName = 'gig.$gigUuid';
    if (_specificGigChannels.contains(channelName)) {
      _pusherService.unsubscribeFromChannel(channelName);
      _specificGigChannels.remove(channelName);
      debugPrint(
        'GigProvider: Unsubscribed from specific gig channel: $channelName',
      );
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
