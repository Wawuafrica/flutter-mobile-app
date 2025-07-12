import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:wawu_mobile/models/gig.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/services/api_service.dart';
import 'package:wawu_mobile/services/pusher_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

class GigProvider extends ChangeNotifier {
  final ApiService _apiService;
  final PusherService _pusherService;
  final UserProvider _userProvider;
  final Logger _logger = Logger();

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

  GigProvider({
    ApiService? apiService,
    PusherService? pusherService,
    required UserProvider userProvider, // Make it required
  }) : _apiService = apiService ?? ApiService(),
       _pusherService = pusherService ?? PusherService(),
       _userProvider = userProvider {
    // Initialize it
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
        _logger.i('GigProvider: Fetch gig response: ${response['data']}');
        final gig = Gig.fromJson(response['data'] as Map<String, dynamic>);
        selectGig(gig);
        _safeNotifyListeners();
        // Subscribe to this specific gig's channel for real-time updates
        await subscribeToSpecificGigChannel(gig.uuid);
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

  // FIXED: The improved postReview method
  Future<bool> postReview(String gigId, Map<String, dynamic> reviewData) async {
    if (_isDisposed) return false;

    // We no longer need a global loading state here, the UI will handle its own.
    // _setLoading(true);

    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/seller/gig/review/$gigId',
        data: reviewData,
      );

      if (response['statusCode'] == 200) {
        // The review was successfully posted to the server.
        // Now, we create the review object locally for an instant UI update.
        Review newReview;

        // Ideal case: The server returns the created review object
        if (response['data'] != null) {
          newReview = Review.fromJson(response['data'] as Map<String, dynamic>);
        } else {
          // Fallback: Create the review object manually from local data
          final currentUser = _userProvider.currentUser;
          if (currentUser == null) {
            _setError('User not logged in.');
            return false;
          }

          newReview = Review(
            uuid:
                DateTime.now().millisecondsSinceEpoch
                    .toString(), // Temporary UUID
            rating: reviewData['rating'] as int,
            review: reviewData['review'] as String,
            user: ReviewUser(
              uuid: currentUser.uuid,
              firstName: currentUser.firstName ?? '',
              lastName: currentUser.lastName ?? '',
              email: currentUser.email ?? '',
              profilePicture:
                  currentUser
                      .profileImage, // Assuming profileImage on your User model
            ),
            createdAt: DateTime.now().toIso8601String(),
          );
        }

        // Add the newly created review to the gig in our local state
        _addReviewToGig(gigId, newReview);

        // _setLoading(false);
        return true;
      } else {
        // Handle API error
        final errorMsg =
            response['message'] as String? ?? 'Failed to submit review';
        _setError(errorMsg);
        // _setLoading(false);
        return false;
      }
    } catch (e) {
      debugPrint('Failed to post review: $e');
      _setError('An unexpected error occurred: $e');
      // _setLoading(false);
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
      debugPrint('Successfully subscribed to general gigs channel');

      // Bind to gig created event
      _pusherService.bindToEvent(channelName, 'gig.created', (event) {
        if (_isDisposed) return;
        debugPrint('Received gig.created event: ${event.data}');

        try {
          if (event.data is String) {
            final gigData = jsonDecode(event.data) as Map<String, dynamic>;
            final newGig = Gig.fromJson(gigData);

            // Add to appropriate lists
            _gigsByStatus['all']!.insert(0, newGig);
            if (_gigsByStatus.containsKey(newGig.status)) {
              _gigsByStatus[newGig.status]!.insert(0, newGig);
            }

            _safeNotifyListeners();
            debugPrint('Successfully added new gig: ${newGig.uuid}');
          }
        } catch (e) {
          debugPrint('GigProvider: Error processing gig.created event: $e');
        }
      });

      // Bind to gig deleted event
      _pusherService.bindToEvent(channelName, 'gig.deleted', (event) {
        if (_isDisposed) return;
        debugPrint('Received gig.deleted event: ${event.data}');

        try {
          if (event.data is String) {
            final deletedGigData =
                jsonDecode(event.data) as Map<String, dynamic>;
            final gigUuid = deletedGigData['data']['uuid'] as String?;

            if (gigUuid != null) {
              // Remove from all lists
              for (final status in _gigsByStatus.keys) {
                _gigsByStatus[status]!.removeWhere(
                  (gig) => gig.uuid == gigUuid,
                );
              }

              // Clear selected gig if it's the deleted one
              if (_selectedGig?.uuid == gigUuid) {
                _selectedGig = null;
              }

              _safeNotifyListeners();
              debugPrint('Successfully removed gig: $gigUuid');
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

  // FIXED: Corrected channel subscription for real-time updates
  Future<void> subscribeToSpecificGigChannel(String gigUuid) async {
    if (_isDisposed) return;

    final channelName = 'gig.approved.$gigUuid';
    final rejectedChannelName = 'gig.rejected.$gigUuid';
    final reviewChannelName =
        'gig.review.$gigUuid'; // Fixed: Correct channel name

    try {
      // Subscribe to gig approved channel
      if (!_specificGigChannels.contains(channelName)) {
        final success = await _pusherService.subscribeToChannel(channelName);
        if (success) {
          _specificGigChannels.add(channelName);
          debugPrint('Successfully subscribed to channel: $channelName');

          _pusherService.bindToEvent(channelName, 'gig.approved', (event) {
            if (_isDisposed) return;
            debugPrint('Received gig.approved event: ${event.data}');
            _handleGigApprovedEvent(event, gigUuid);
          });
        } else {
          debugPrint('Failed to subscribe to channel: $channelName');
        }
      }

      // Subscribe to gig rejected channel
      if (!_specificGigChannels.contains(rejectedChannelName)) {
        final success = await _pusherService.subscribeToChannel(
          rejectedChannelName,
        );
        if (success) {
          _specificGigChannels.add(rejectedChannelName);
          debugPrint(
            'Successfully subscribed to channel: $rejectedChannelName',
          );

          _pusherService.bindToEvent(rejectedChannelName, 'gig.rejected', (
            event,
          ) {
            if (_isDisposed) return;
            debugPrint('Received gig.rejected event: ${event.data}');
            _handleGigRejectedEvent(event, gigUuid);
          });
        } else {
          debugPrint('Failed to subscribe to channel: $rejectedChannelName');
        }
      }

      // FIXED: Subscribe to gig review channel with proper error handling
      if (!_specificGigChannels.contains(reviewChannelName)) {
        final success = await _pusherService.subscribeToChannel(
          reviewChannelName,
        );
        if (success) {
          _specificGigChannels.add(reviewChannelName);
          debugPrint('Successfully subscribed to channel: $reviewChannelName');

          _pusherService.bindToEvent(reviewChannelName, 'gig.review', (event) {
            if (_isDisposed) return;
            debugPrint('Received gig.review event: ${event.data}');
            _handleGigReviewEvent(event, gigUuid);
          });
        } else {
          debugPrint('Failed to subscribe to channel: $reviewChannelName');
        }
      }
    } catch (e) {
      debugPrint(
        'Failed to subscribe to specific gig channels for $gigUuid: $e',
      );
    }
  }

  void _handleGigApprovedEvent(PusherEvent event, String gigUuid) {
    if (_isDisposed) return;

    try {
      if (event.data is String) {
        final eventData = jsonDecode(event.data) as Map<String, dynamic>;

        // Extract the gig data from the event
        if (eventData['data'] is Map<String, dynamic>) {
          final updatedGig = Gig.fromJson(
            eventData['data'] as Map<String, dynamic>,
          );
          _updateGigInAllLists(gigUuid, updatedGig);
          debugPrint('Successfully updated gig status to VERIFIED: $gigUuid');
        }
      }
    } catch (e) {
      debugPrint('GigProvider: Error processing gig.approved event: $e');
    }
  }

  void _handleGigRejectedEvent(PusherEvent event, String gigUuid) {
    if (_isDisposed) return;

    try {
      if (event.data is String) {
        final eventData = jsonDecode(event.data) as Map<String, dynamic>;

        // Extract the gig data from the event
        if (eventData['data'] is Map<String, dynamic>) {
          final updatedGig = Gig.fromJson(
            eventData['data'] as Map<String, dynamic>,
          );
          _updateGigInAllLists(gigUuid, updatedGig);
          debugPrint('Successfully updated gig status to REJECTED: $gigUuid');
        }
      }
    } catch (e) {
      debugPrint('GigProvider: Error processing gig.rejected event: $e');
    }
  }

  // FIXED: Improved review event handling with better error handling and logging
  void _handleGigReviewEvent(PusherEvent event, String gigUuid) {
    if (_isDisposed) return;

    try {
      debugPrint('Processing gig.review event for gig: $gigUuid');
      debugPrint('Event data type: ${event.data.runtimeType}');
      debugPrint('Event data: ${event.data}');

      if (event.data is String) {
        final eventData = jsonDecode(event.data) as Map<String, dynamic>;
        debugPrint('Decoded event data: $eventData');

        // Handle different possible structures of the review data
        Review? newReview;

        if (eventData['review'] is Map<String, dynamic>) {
          newReview = Review.fromJson(
            eventData['review'] as Map<String, dynamic>,
          );
        } else if (eventData['data'] is Map<String, dynamic> &&
            eventData['data']['review'] is Map<String, dynamic>) {
          newReview = Review.fromJson(
            eventData['data']['review'] as Map<String, dynamic>,
          );
        } else if (eventData.containsKey('uuid') &&
            eventData.containsKey('rating')) {
          // The event data itself is the review
          newReview = Review.fromJson(eventData);
        }

        if (newReview != null) {
          _addReviewToGig(gigUuid, newReview);
          debugPrint('Successfully added new review to gig: $gigUuid');
          debugPrint(
            'Review rating: ${newReview.rating}, Review text: ${newReview.review}',
          );
        } else {
          debugPrint('Could not extract review data from event');
        }
      } else {
        debugPrint('Event data is not a string, received: ${event.data}');
      }
    } catch (e, stackTrace) {
      debugPrint('GigProvider: Error processing gig.review event: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  void _updateGigInAllLists(String gigUuid, Gig updatedGig) {
    if (_isDisposed) return;

    bool gigUpdated = false;

    // Update gig in all status lists
    for (final status in _gigsByStatus.keys) {
      final index = _gigsByStatus[status]!.indexWhere(
        (gig) => gig.uuid == gigUuid,
      );
      if (index != -1) {
        _gigsByStatus[status]![index] = updatedGig;
        gigUpdated = true;
      }
    }

    // If gig wasn't found in any list, add it
    if (!gigUpdated) {
      _gigsByStatus['all']!.insert(0, updatedGig);
      if (_gigsByStatus.containsKey(updatedGig.status)) {
        _gigsByStatus[updatedGig.status]!.insert(0, updatedGig);
      }
    }

    // Remove gig from inappropriate status lists
    for (final status in _gigsByStatus.keys) {
      if (status != 'all' && status != updatedGig.status) {
        _gigsByStatus[status]!.removeWhere((gig) => gig.uuid == gigUuid);
      }
    }

    // Re-sort all lists
    for (final status in _gigsByStatus.keys) {
      _gigsByStatus[status]!.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    // Update selected gig if it's the same one
    if (_selectedGig?.uuid == gigUuid) {
      _selectedGig = updatedGig;
    }

    _safeNotifyListeners();
  }

  // FIXED: Improved review addition with better error handling and validation
  void _addReviewToGig(String gigUuid, Review newReview) {
    if (_isDisposed) return;

    debugPrint('Adding review to gig: $gigUuid');
    debugPrint(
      'Review details: rating=${newReview.rating}, uuid=${newReview.uuid}',
    );

    // Update gig in all status lists
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

    // Update selected gig if it's the same one
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

    final channelNames = [
      'gig.approved.$gigUuid',
      'gig.rejected.$gigUuid',
      'gig.review.$gigUuid',
    ];

    for (final channelName in channelNames) {
      if (_specificGigChannels.contains(channelName)) {
        _pusherService.unsubscribeFromChannel(channelName);
        _specificGigChannels.remove(channelName);
        debugPrint('Unsubscribed from channel: $channelName');
      }
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
