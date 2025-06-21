import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:wawu_mobile/models/gig.dart';
import 'package:wawu_mobile/services/api_service.dart';
import 'package:wawu_mobile/services/pusher_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GigProvider extends ChangeNotifier {
  final ApiService _apiService;
  final PusherService _pusherService;

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

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
  final List<Gig> _recentlyViewedGigs = [];
  final String _recentGigsKey = 'recently_viewed_gigs';
  bool _isRecentlyViewedLoading = false;
  bool _isDisposed = false;

  List<Gig> get recentlyViewedGigs => List.unmodifiable(_recentlyViewedGigs);
  bool get isRecentlyViewedLoading => _isRecentlyViewedLoading;

  List<Gig> get gigs => List.unmodifiable(_gigsByStatus['all'] ?? []);
  List<Gig> gigsForStatus(String? status) =>
      List.unmodifiable(_gigsByStatus[status ?? 'all'] ?? []);
  Gig? get selectedGig => _selectedGig;

  GigProvider({ApiService? apiService, PusherService? pusherService})
    : _apiService = apiService ?? ApiService(),
      _pusherService = pusherService ?? PusherService() {
    debugPrint('[RecentlyViewed] GigProvider constructor called.');
    _loadRecentlyViewedGigs();
  }

  void _setLoading(bool loading) {
    if (_isDisposed) return;
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    if (_isDisposed) return;
    _error = error;
    notifyListeners();
  }

  void _safeNotifyListeners() {
    if (_isDisposed) return;
    notifyListeners();
  }

  Future<void> _loadRecentlyViewedGigs() async {
    if (_isDisposed) return;

    debugPrint('[RecentlyViewed] _loadRecentlyViewedGigs called.');
    _isRecentlyViewedLoading = true;
    _safeNotifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedGigsJson = prefs.getStringList(_recentGigsKey);

      if (_isDisposed) return;

      if (savedGigsJson != null && savedGigsJson.isNotEmpty) {
        _recentlyViewedGigs.clear();

        for (final jsonStr in savedGigsJson) {
          if (_isDisposed) return;

          try {
            if (jsonStr.trim().isEmpty) continue;

            final Map<String, dynamic> json = jsonDecode(jsonStr);

            // More robust validation
            if (!_isValidGigJson(json)) {
              debugPrint('[RecentlyViewed][WARNING] Skipping invalid gig data');
              continue;
            }

            final gig = Gig.fromJson(json);

            // Additional validation after creating Gig object
            if (!_isValidGig(gig)) {
              debugPrint(
                '[RecentlyViewed][WARNING] Skipping invalid gig object',
              );
              continue;
            }

            _recentlyViewedGigs.add(gig);
            debugPrint(
              '[RecentlyViewed] Loaded gig: uuid=${gig.uuid}, title=${gig.title}',
            );
          } catch (e, stackTrace) {
            debugPrint('[RecentlyViewed][ERROR] Error decoding gig: $e');
            debugPrint('[RecentlyViewed][ERROR] Stack trace: $stackTrace');
            continue;
          }
        }

        debugPrint(
          '[RecentlyViewed] Successfully loaded ${_recentlyViewedGigs.length} gigs',
        );
      } else {
        debugPrint('[RecentlyViewed] No saved gigs found');
      }
    } catch (e, stackTrace) {
      debugPrint('[RecentlyViewed][ERROR] Error loading gigs: $e');
      debugPrint('[RecentlyViewed][ERROR] Stack trace: $stackTrace');
      _recentlyViewedGigs.clear();
    } finally {
      if (!_isDisposed) {
        _isRecentlyViewedLoading = false;
        _safeNotifyListeners();
      }
    }
  }

  bool _isValidGigJson(Map<String, dynamic> json) {
    try {
      // Check for required fields
      if (json['uuid'] == null ||
          json['title'] == null ||
          json['description'] == null ||
          json['seller'] == null ||
          json['created_at'] == null) {
        return false;
      }

      // Check if uuid and title are not empty strings
      if (json['uuid'].toString().trim().isEmpty ||
          json['title'].toString().trim().isEmpty) {
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('[RecentlyViewed][ERROR] Error validating gig JSON: $e');
      return false;
    }
  }

  bool _isValidGig(Gig gig) {
    try {
      return gig.uuid.trim().isNotEmpty && gig.title.trim().isNotEmpty;
    } catch (e) {
      debugPrint('[RecentlyViewed][ERROR] Error validating gig object: $e');
      return false;
    }
  }

  Future<void> _saveRecentlyViewedGigs() async {
    if (_isDisposed) return;

    debugPrint('[RecentlyViewed] Saving ${_recentlyViewedGigs.length} gigs');

    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> gigJsons = [];

      for (final gig in _recentlyViewedGigs) {
        if (_isDisposed) return;

        try {
          if (!_isValidGig(gig)) {
            debugPrint(
              '[RecentlyViewed][WARNING] Skipping invalid gig during save',
            );
            continue;
          }

          final jsonString = jsonEncode(gig.toJson());
          gigJsons.add(jsonString);
        } catch (e) {
          debugPrint(
            '[RecentlyViewed][ERROR] Error serializing gig ${gig.uuid}: $e',
          );
          continue;
        }
      }

      if (!_isDisposed) {
        await prefs.setStringList(_recentGigsKey, gigJsons);
        debugPrint(
          '[RecentlyViewed] Successfully saved ${gigJsons.length} gigs',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[RecentlyViewed][ERROR] Exception saving gigs: $e');
      debugPrint('[RecentlyViewed][ERROR] Stack trace: $stackTrace');
    }
  }

  Future<void> addRecentlyViewedGig(Gig? gig) async {
    debugPrint('[RecentlyViewed] addRecentlyViewedGig called');

    if (_isDisposed) {
      debugPrint('[RecentlyViewed][ERROR] Provider is disposed');
      return;
    }

    if (gig == null) {
      debugPrint('[RecentlyViewed][ERROR] Attempted to add null gig');
      return;
    }

    if (!_isValidGig(gig)) {
      debugPrint('[RecentlyViewed][ERROR] Attempted to add invalid gig');
      return;
    }

    try {
      debugPrint(
        '[RecentlyViewed] Adding gig: uuid=${gig.uuid}, title=${gig.title}',
      );

      // Remove existing entry if it exists
      _recentlyViewedGigs.removeWhere((g) => g.uuid == gig.uuid);

      // Add to beginning of list
      _recentlyViewedGigs.insert(0, gig);

      // Keep only last 5 items
      if (_recentlyViewedGigs.length > 5) {
        final removed = _recentlyViewedGigs.removeLast();
        debugPrint('[RecentlyViewed] Removed oldest gig: ${removed.uuid}');
      }

      // Save to storage asynchronously
      _saveRecentlyViewedGigs().catchError((error) {
        debugPrint('[RecentlyViewed][ERROR] Failed to save: $error');
      });

      _safeNotifyListeners();
      debugPrint('[RecentlyViewed] Successfully added gig');
    } catch (e, stackTrace) {
      debugPrint(
        '[RecentlyViewed][ERROR] Exception in addRecentlyViewedGig: $e',
      );
      debugPrint('[RecentlyViewed][ERROR] Stack trace: $stackTrace');
    }
  }

  Future<void> clearRecentlyViewedGigs() async {
    debugPrint('[RecentlyViewed] Clearing recently viewed gigs');

    _recentlyViewedGigs.clear();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentGigsKey);
      debugPrint('[RecentlyViewed] Cleared from SharedPreferences');
    } catch (e) {
      debugPrint(
        '[RecentlyViewed][ERROR] Failed to clear from SharedPreferences: $e',
      );
    }

    _safeNotifyListeners();
  }

  // Method to be called on logout
  Future<void> clearUserData() async {
    debugPrint('[GigProvider] Clearing all user data');

    // Clear all gig data
    _gigsByStatus.forEach((key, _) => _gigsByStatus[key] = []);
    _selectedGig = null;

    // Clear recently viewed gigs
    await clearRecentlyViewedGigs();

    // Unsubscribe from channels
    if (_isGeneralChannelSubscribed) {
      _pusherService.unsubscribeFromChannel('gigs');
      _isGeneralChannelSubscribed = false;
    }

    for (final channel in _specificGigChannels) {
      _pusherService.unsubscribeFromChannel(channel);
    }
    _specificGigChannels.clear();

    // Reset loading states
    _isLoading = false;
    _error = null;
    _isRecentlyViewedLoading = false;

    _safeNotifyListeners();
    debugPrint('[GigProvider] User data cleared successfully');
  }

  // Fetch a single gig by its UUID, update selectedGig, and notify listeners
  Future<Gig?> fetchGigById(String gigId) async {
    if (_isDisposed) return null;
    _setLoading(true);
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/seller/gig/$gigId',
      );
      if (_isDisposed) return null;
      if (response['statusCode'] == 200 && response['data'] != null) {
        final gig = Gig.fromJson(response['data'] as Map<String, dynamic>);
        selectGig(gig);
        _setLoading(false);
        return gig;
      } else {
        _setLoading(false);
        _setError('Failed to fetch gig details.');
        return null;
      }
    } catch (e) {
      _setLoading(false);
      _setError('Failed to fetch gig details: $e');
      return null;
    }
  }
  Future<List<Gig>> fetchGigs({String? status}) async {
    if (_isDisposed) return [];

    _setLoading(true);
    _setError(null);

    try {
      final Map<String, dynamic> queryParams =
          status != null && status.isNotEmpty ? {'status': status} : {};
      final response = await _apiService.get<Map<String, dynamic>>(
        '/seller/gig',
        queryParameters: queryParams,
      );

      if (_isDisposed) return [];

      if (response['statusCode'] == 200 && response['data'] is List) {
        final List<dynamic> gigsJson = response['data'] as List<dynamic>;

        final List<Gig> gigs =
            gigsJson
                .map((json) => Gig.fromJson(json as Map<String, dynamic>))
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        final statusKey = status ?? 'all';
        _gigsByStatus[statusKey] = gigs;

        if (status != null) {
          final existingGigs = <String, Gig>{};
          for (final gig in _gigsByStatus['all'] ?? <Gig>[]) {
            existingGigs[gig.uuid] = gig;
          }
          for (final gig in gigs) {
            existingGigs[gig.uuid] = gig;
          }
          final allGigs =
              existingGigs.values.toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _gigsByStatus['all'] = allGigs;
        }

        if (!_isGeneralChannelSubscribed) {
          await _subscribeToGeneralGigsChannel();
        }

        _setLoading(false);
        return gigs;
      } else {
        final errorMessage = 'Invalid response format from /seller/gig';
        _setError(errorMessage);
        _setLoading(false);
        return [];
      }
    } catch (e) {
      final errorMessage = 'Failed to fetch gigs: $e';
      _setError(errorMessage);
      _setLoading(false);
      return [];
    }
  }

  Future<Gig?> createGig(FormData payload) async {
    if (_isDisposed) return null;

    _setLoading(true);
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/seller/gig',
        data: payload,
      );

      if (_isDisposed) return null;

      if (response['statusCode'] == 200 && response['data'] != null) {
        final gig = Gig.fromJson(response['data'] as Map<String, dynamic>);
        _gigsByStatus['all']!.insert(0, gig);
        _gigsByStatus['PENDING']!.insert(0, gig);
        _safeNotifyListeners();
        _setLoading(false);
        return gig;
      }
      _setLoading(false);
      return null;
    } catch (e) {
      debugPrint('Failed to create gig: $e');
      _setLoading(false);
      return null;
    }
  }

  Future<bool> postReview(String gigId, Map<String, dynamic> reviewData) async {
    if (_isDisposed) return false;

    _setLoading(true);
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/seller/gig/review/$gigId',
        data: reviewData,
      );
      _setLoading(false);
      return response['statusCode'] == 200;
    } catch (e) {
      debugPrint('Failed to post review: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<List<Gig>> fetchGigsBySubCategory(String subCategoryId) async {
    if (_isDisposed) return [];

    _setLoading(true);
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/services/$subCategoryId/gigs',
        queryParameters: {'status': 'VERIFIED'},
      );

      if (_isDisposed) return [];

      if (response['statusCode'] == 200 && response['data'] is List) {
        final List<dynamic> gigsJson = response['data'] as List<dynamic>;
        final gigs =
            gigsJson
                .map((json) => Gig.fromJson(json as Map<String, dynamic>))
                .toList();
        _setLoading(false);
        return gigs;
      }
      _setLoading(false);
      return [];
    } catch (e) {
      debugPrint('Failed to fetch gigs by subcategory: $e');
      _setLoading(false);
      return [];
    }
  }

  void selectGig(Gig gig) {
    if (_isDisposed) return;
    _selectedGig = gig;
    _safeNotifyListeners();
  }

  void clearSelectedGig() {
    if (_isDisposed) return;
    _selectedGig = null;
    _safeNotifyListeners();
  }

  Future<void> _subscribeToGeneralGigsChannel() async {
    if (_isDisposed) return;

    const channelName = 'gigs';
    try {
      final success = await _pusherService.subscribeToChannel(channelName);
      if (!success) {
        debugPrint('Failed to subscribe to general gigs channel');
        return;
      }

      _isGeneralChannelSubscribed = true;

      _pusherService.bindToEvent(channelName, 'gig.created', (event) {
        if (_isDisposed) return;

        try {
          if (event.data is String) {
            final gigData = jsonDecode(event.data) as Map<String, dynamic>;
            final newGig = Gig.fromJson({...gigData, 'status': 'PENDING'});
            _gigsByStatus['all']!.insert(0, newGig);
            _gigsByStatus['PENDING']!.insert(0, newGig);
            _safeNotifyListeners();
          }
        } catch (e) {
          debugPrint('GigProvider: Error processing gig.created event: $e');
        }
      });

      _pusherService.bindToEvent(channelName, 'gig.deleted', (event) {
        if (_isDisposed) return;

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
              _safeNotifyListeners();
            }
          }
        } catch (e) {
          debugPrint('GigProvider: Error processing gig.deleted event: $e');
        }
      });
    } catch (e) {
      debugPrint(
        'GigProvider: Failed to subscribe to general gigs channel: $e',
      );
    }
  }

  Future<void> subscribeToSpecificGigChannel(String gigUuid) async {
    if (_isDisposed) return;

    final channelName = 'gig.$gigUuid';

    if (_specificGigChannels.contains(channelName)) {
      return;
    }

    try {
      final success = await _pusherService.subscribeToChannel(channelName);
      if (!success) {
        return;
      }

      _specificGigChannels.add(channelName);

      _pusherService.bindToEvent(
        channelName,
        'gig.approved',
        _handleGigApprovedEvent,
      );
      _pusherService.bindToEvent(
        channelName,
        'gig.rejected',
        _handleGigRejectedEvent,
      );
      _pusherService.bindToEvent(
        channelName,
        'gig.review',
        _handleGigReviewEvent,
      );
    } catch (e) {
      debugPrint(
        'Failed to subscribe to specific gig channel $channelName: $e',
      );
    }
  }

  void _handleGigApprovedEvent(PusherEvent event) {
    if (_isDisposed) return;

    try {
      if (event.data is String) {
        final eventData = jsonDecode(event.data) as Map<String, dynamic>;
        final gigUuid = eventData['gig_uuid'] as String?;
        if (gigUuid != null && eventData['gig'] is Map<String, dynamic>) {
          final updatedGig = Gig.fromJson(
            eventData['gig'] as Map<String, dynamic>,
          );
          _updateGigInAllLists(gigUuid, updatedGig);
        }
      }
    } catch (e) {
      debugPrint('GigProvider: Error processing gig.approved event: $e');
    }
  }

  void _handleGigRejectedEvent(PusherEvent event) {
    if (_isDisposed) return;

    try {
      if (event.data is String) {
        final eventData = jsonDecode(event.data) as Map<String, dynamic>;
        final gigUuid = eventData['gig_uuid'] as String?;
        if (gigUuid != null && eventData['gig'] is Map<String, dynamic>) {
          final updatedGig = Gig.fromJson(
            eventData['gig'] as Map<String, dynamic>,
          );
          _updateGigInAllLists(gigUuid, updatedGig);
        }
      }
    } catch (e) {
      debugPrint('GigProvider: Error processing gig.rejected event: $e');
    }
  }

  void _handleGigReviewEvent(PusherEvent event) {
    if (_isDisposed) return;

    try {
      if (event.data is String) {
        final eventData = jsonDecode(event.data) as Map<String, dynamic>;
        final gigUuid = eventData['gig_uuid'] as String?;
        if (gigUuid != null && eventData['review'] is Map<String, dynamic>) {
          final newReview = Review.fromJson(
            eventData['review'] as Map<String, dynamic>,
          );
          _addReviewToGig(gigUuid, newReview);
        }
      }
    } catch (e) {
      debugPrint('GigProvider: Error processing gig.review event: $e');
    }
  }

  void _updateGigInAllLists(String gigUuid, Gig updatedGig) {
    if (_isDisposed) return;

    bool gigUpdated = false;
    for (final status in _gigsByStatus.keys) {
      final index = _gigsByStatus[status]!.indexWhere(
        (gig) => gig.uuid == gigUuid,
      );
      if (index != -1) {
        _gigsByStatus[status]![index] = updatedGig;
        gigUpdated = true;
      }
    }

    if (!gigUpdated) {
      _gigsByStatus['all']!.insert(0, updatedGig);
      if (_gigsByStatus.containsKey(updatedGig.status)) {
        _gigsByStatus[updatedGig.status]!.insert(0, updatedGig);
      }
    }

    for (final status in _gigsByStatus.keys) {
      if (status != 'all' && status != updatedGig.status) {
        _gigsByStatus[status]!.removeWhere((gig) => gig.uuid == gigUuid);
      }
    }

    for (final status in _gigsByStatus.keys) {
      _gigsByStatus[status]!.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    if (_selectedGig?.uuid == gigUuid) {
      _selectedGig = updatedGig;
    }

    _safeNotifyListeners();
  }

  void _addReviewToGig(String gigUuid, Review newReview) {
    if (_isDisposed) return;

    for (final status in _gigsByStatus.keys) {
      final index = _gigsByStatus[status]!.indexWhere(
        (gig) => gig.uuid == gigUuid,
      );
      if (index != -1) {
        final currentGig = _gigsByStatus[status]![index];
        final updatedReviews = [...currentGig.reviews, newReview];
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

    if (_selectedGig?.uuid == gigUuid) {
      final g = _selectedGig!;
      final updatedReviews = [...g.reviews, newReview];
      _selectedGig = Gig(
        uuid: g.uuid,
        title: g.title,
        description: g.description,
        keywords: g.keywords,
        about: g.about,
        seller: g.seller,
        services: g.services,
        pricings: g.pricings,
        faqs: g.faqs,
        assets: g.assets,
        status: g.status,
        reviews: updatedReviews,
      );
    }

    _safeNotifyListeners();
  }

  void unsubscribeFromSpecificGigChannel(String gigUuid) {
    if (_isDisposed) return;

    final channelName = 'gig.$gigUuid';
    if (_specificGigChannels.contains(channelName)) {
      _pusherService.unsubscribeFromChannel(channelName);
      _specificGigChannels.remove(channelName);
    }
  }

  // Deprecated - use clearUserData() instead
  @Deprecated('Use clearUserData() instead')
  Future<void> clearAll() async {
    await clearUserData();
  }

  @override
  void dispose() {
    debugPrint('[GigProvider] dispose() called');
    _isDisposed = true;

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
