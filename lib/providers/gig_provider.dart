// gig_provider.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:wawu_mobile/models/gig.dart';
import 'package:wawu_mobile/providers/base_provider.dart'; // Import BaseProvider
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/services/api_service.dart';
import 'package:wawu_mobile/services/pusher_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

// GigProvider now extends BaseProvider for standardized state management.
class GigProvider extends BaseProvider {
  final ApiService _apiService;
  final PusherService _pusherService;
  final UserProvider _userProvider;
  final Logger _logger = Logger();

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
  bool _isDisposed = false; // Keep this for safeDispose pattern

  // New field for suggested gigs
  List<Gig> _suggestedGigs = [];
  bool _isSuggestedGigsLoading = false;

  // New field for search results
  List<Gig> _searchResults = [];
  bool _isSearching = false;

  List<Gig> get recentlyViewedGigs => List.unmodifiable(_recentlyViewedGigs);
  bool get isRecentlyViewedLoading => _isRecentlyViewedLoading;

  List<Gig> get gigs => List.unmodifiable(_gigsByStatus['all'] ?? []);
  List<Gig> gigsForStatus(String? status) =>
      List.unmodifiable(_gigsByStatus[status ?? 'all'] ?? []);
  Gig? get selectedGig => _selectedGig;

  // New getter for suggested gigs
  List<Gig> get suggestedGigs => List.unmodifiable(_suggestedGigs);
  bool get isSuggestedGigsLoading => _isSuggestedGigsLoading;

  // New getters for search results
  List<Gig> get searchResults => List.unmodifiable(_searchResults);
  bool get isSearching => _isSearching;

  GigProvider({
    ApiService? apiService,
    PusherService? pusherService,
    required UserProvider userProvider,
  }) : _apiService = apiService ?? ApiService(),
       _pusherService = pusherService ?? PusherService(),
       _userProvider = userProvider {
    debugPrint('[RecentlyViewed] GigProvider constructor called.');
    // _loadRecentlyViewedGigs(); // Moved to _initializeData in HomeScreen
    // Optionally fetch suggested gigs on initialization
    // fetchSuggestedGigs();
  }

  void safeNotifyListeners() {
    if (_isDisposed) return;
    notifyListeners();
  }

  // This method now only handles local loading from SharedPreferences.
  // The API fetch logic is moved to fetchRecentlyViewedGigs().
  Future<void> loadRecentlyViewedGigs() async {
    if (_isDisposed) return;
    if (_userProvider.currentUser == null) {
      _recentlyViewedGigs.clear();
      safeNotifyListeners();
      debugPrint('[RecentlyViewed] User not logged in, clearing local recently viewed gigs.');
      return;
    }

    debugPrint('[RecentlyViewed] _loadRecentlyViewedGigs called from local storage.');
    _isRecentlyViewedLoading = true;
    safeNotifyListeners();

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

            if (!_isValidGigJson(json)) {
              debugPrint('[RecentlyViewed][WARNING] Skipping invalid gig data');
              continue;
            }

            final gig = Gig.fromJson(json);

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
          '[RecentlyViewed] Successfully loaded ${_recentlyViewedGigs.length} gigs from local storage',
        );
      } else {
        debugPrint('[RecentlyViewed] No saved gigs found locally');
      }
    } catch (e, stackTrace) {
      debugPrint('[RecentlyViewed][ERROR] Error loading gigs from local storage: $e');
      debugPrint('[RecentlyViewed][ERROR] Stack trace: $stackTrace');
      _recentlyViewedGigs.clear();
    } finally {
      if (!_isDisposed) {
        _isRecentlyViewedLoading = false;
        safeNotifyListeners();
      }
    }
  }

  bool _isValidGigJson(Map<String, dynamic> json) {
    try {
      if (json['uuid'] == null ||
          json['title'] == null ||
          json['description'] == null ||
          json['seller'] == null ||
          json['created_at'] == null) {
        return false;
      }

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

    debugPrint('[RecentlyViewed] Saving ${_recentlyViewedGigs.length} gigs to local storage');

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
          '[RecentlyViewed] Successfully saved ${gigJsons.length} gigs to local storage',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[RecentlyViewed][ERROR] Exception saving gigs to local storage: $e');
      debugPrint('[RecentlyViewed][ERROR] Stack trace: $stackTrace');
    }
  }

  Future<void> fetchRecentlyViewedGigs() async {
    if (_isDisposed) return;
    if (_userProvider.currentUser == null) {
      debugPrint('[RecentlyViewed] Not fetching recently viewed gigs from API: User not logged in.');
      _recentlyViewedGigs.clear();
      _isRecentlyViewedLoading = false;
      safeNotifyListeners();
      return;
    }

    debugPrint('[RecentlyViewed] fetchRecentlyViewedGigs called (from API).');
    _isRecentlyViewedLoading = true;
    safeNotifyListeners();

    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/gigs/recently-viewed', // New API endpoint
      );

      if (_isDisposed) return;

      if (response['statusCode'] == 200 && response['data'] is List) {
        final List<dynamic> gigsJson = response['data'] as List<dynamic>;
        _recentlyViewedGigs.clear();
        for (final json in gigsJson) {
          try {
            if (!_isValidGigJson(json)) {
              debugPrint('[RecentlyViewed][WARNING] Skipping invalid gig data from API');
              continue;
            }
            final gig = Gig.fromJson(json as Map<String, dynamic>);
            if (!_isValidGig(gig)) {
              debugPrint(
                '[RecentlyViewed][WARNING] Skipping invalid gig object from API',
              );
              continue;
            }
            _recentlyViewedGigs.add(gig);
          } catch (e, stackTrace) {
            debugPrint('[RecentlyViewed][ERROR] Error decoding API gig: $e');
            debugPrint('[RecentlyViewed][ERROR] Stack trace: $stackTrace');
          }
        }
        debugPrint(
          '[RecentlyViewed] Successfully fetched ${_recentlyViewedGigs.length} recently viewed gigs from API.',
        );
        setSuccess(); // Indicate success for the operation
      } else {
        final errorMessage =
            response['message'] as String? ?? 'Failed to fetch recently viewed gigs.';
        setError(errorMessage);
        _recentlyViewedGigs.clear(); // Clear on API error
      }
    } catch (e, stackTrace) {
      debugPrint('[RecentlyViewed][ERROR] Error fetching recently viewed gigs from API: $e');
      debugPrint('[RecentlyViewed][ERROR] Stack trace: $stackTrace');
      setError(e.toString());
      _recentlyViewedGigs.clear(); // Clear on exception
    } finally {
      if (!_isDisposed) {
        _isRecentlyViewedLoading = false;
        safeNotifyListeners();
      }
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

      // Record gig view on the backend
      if (_userProvider.currentUser != null) {
        try {
          debugPrint('[RecentlyViewed] Recording gig view for ${gig.uuid} on backend.');
          await _apiService.post<Map<String, dynamic>>(
            '/gigs/${gig.uuid}/view', // New API endpoint
            data: {}, // No request body required for this endpoint
          );
          debugPrint('[RecentlyViewed] Successfully recorded gig view on backend.');
        } catch (e) {
          debugPrint('[RecentlyViewed][WARNING] Failed to record gig view on backend: $e');
          // Don't setError here as it's a secondary operation and shouldn't block the main flow.
          // Could log this error differently if needed.
        }
      }

      // Local storage logic (keep for immediate UI updates and robustness)
      _recentlyViewedGigs.removeWhere((g) => g.uuid == gig.uuid);
      _recentlyViewedGigs.insert(0, gig);
      if (_recentlyViewedGigs.length > 5) {
        final removed = _recentlyViewedGigs.removeLast();
        debugPrint('[RecentlyViewed] Removed oldest gig locally: ${removed.uuid}');
      }

      _saveRecentlyViewedGigs().catchError((error) {
        debugPrint('[RecentlyViewed][ERROR] Failed to save locally: $error');
      });

      safeNotifyListeners();
      debugPrint('[RecentlyViewed] Successfully added gig (local & API call initiated)');
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

    safeNotifyListeners();
  }

  Future<void> clearUserData() async {
    debugPrint('[GigProvider] Clearing all user data');

    _gigsByStatus.forEach((key, _) => _gigsByStatus[key] = []);
    _selectedGig = null;
    _suggestedGigs = [];
    _searchResults = []; // Clear search results on user data clear

    await clearRecentlyViewedGigs(); // This already handles local storage

    if (_isGeneralChannelSubscribed) {
      _pusherService.unsubscribeFromChannel('gigs');
      _isGeneralChannelSubscribed = false;
    }

    for (final channel in _specificGigChannels) {
      _pusherService.unsubscribeFromChannel(channel);
    }
    _specificGigChannels.clear();

    resetState();
    _isRecentlyViewedLoading = false;
    _isSuggestedGigsLoading = false;
    _isSearching = false; // Reset search loading state

    safeNotifyListeners();
    debugPrint('[GigProvider] User data cleared successfully');
  }

  Future<Gig?> fetchGigById(String gigId) async {
    if (_isDisposed) return null;
    setLoading();
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/seller/gig/$gigId',
      );
      if (_isDisposed) return null;
      if (response['statusCode'] == 200 && response['data'] != null) {
        _logger.i('GigProvider: Fetch gig response: ${response['data']}');
        final gig = Gig.fromJson(response['data'] as Map<String, dynamic>);
        selectGig(gig);
        await subscribeToSpecificGigChannel(gig.uuid);
        setSuccess();
        return gig;
      } else {
        setError('Failed to fetch gig details.');
        return null;
      }
    } catch (e) {
      setError(e.toString());
      return null;
    }
  }

  Future<List<Gig>> fetchGigs({String? status}) async {
    if (_isDisposed) return [];

    setLoading();

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

        setSuccess();
        return gigs;
      } else {
        final errorMessage =
            response['message'] as String? ??
            'Invalid response format from /seller/gig';
        setError(errorMessage);
        return [];
      }
    } catch (e) {
      setError(e.toString());
      return [];
    }
  }

  Future<void> fetchSuggestedGigs() async {
    if (_isDisposed) return;

    _isSuggestedGigsLoading = true;
    safeNotifyListeners();

    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/gigs/you-may-like',
      );

      if (_isDisposed) return;

      if (response['statusCode'] == 200 && response['data'] is List) {
        final List<dynamic> gigsJson = response['data'] as List<dynamic>;
        _suggestedGigs =
            gigsJson
                .map((json) => Gig.fromJson(json as Map<String, dynamic>))
                .toList();
        debugPrint(
          '[GigProvider] Successfully fetched ${_suggestedGigs.length} suggested gigs.',
        );
        setSuccess();
      } else {
        final errorMessage =
            response['message'] as String? ?? 'Failed to fetch suggested gigs.';
        setError(errorMessage);
        _suggestedGigs = [];
      }
    } catch (e) {
      debugPrint('[GigProvider] Error fetching suggested gigs: $e');
      setError(e.toString());
      _suggestedGigs = [];
    } finally {
      if (!_isDisposed) {
        _isSuggestedGigsLoading = false;
        safeNotifyListeners();
      }
    }
  }

  Future<List<Gig>> searchGigs(String keyword, {bool paginate = false, int pageNumber = 1}) async {
    if (_isDisposed) return [];

    if (keyword.length < 2) {
      _searchResults = [];
      _isSearching = false;
      safeNotifyListeners();
      return [];
    }

    _isSearching = true;
    safeNotifyListeners();

    try {
      final Map<String, dynamic> queryParameters = {
        'keyword': keyword,
        'paginate': paginate,
        'pageNumber': pageNumber,
      };

      final response = await _apiService.get<Map<String, dynamic>>(
        '/gigs/search',
        queryParameters: queryParameters,
      );

      if (_isDisposed) return [];

      if (response['statusCode'] == 200 && response['data'] is List) {
        final List<dynamic> gigsJson = response['data'] as List<dynamic>;
        _searchResults = gigsJson
            .map((json) => Gig.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint(
          '[GigProvider] Successfully fetched ${_searchResults.length} search results for keyword: $keyword',
        );
        setSuccess();
      } else {
        final errorMessage =
            response['message'] as String? ?? 'Failed to fetch search results.';
        setError(errorMessage);
        _searchResults = [];
      }
    } catch (e) {
      debugPrint('[GigProvider] Error searching gigs: $e');
      setError(e.toString());
      _searchResults = [];
    } finally {
      if (!_isDisposed) {
        _isSearching = false;
        safeNotifyListeners();
      }
    }
    return _searchResults;
  }

  Future<Gig?> createGig(FormData payload) async {
    if (_isDisposed) return null;

    setLoading();
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/seller/gig',
        data: payload,
      );
      print(response['data']);

      if (_isDisposed) return null;

      if (response['statusCode'] == 200 && response['data'] != null) {
        final gig = Gig.fromJson(response['data'] as Map<String, dynamic>);
        _gigsByStatus['all']!.insert(0, gig);
        _gigsByStatus['PENDING']!.insert(0, gig);
        safeNotifyListeners();
        setSuccess();
        return gig;
      }
      setError(
        response['message'] ?? 'Failed to create gig',
      );
      return null;
    } catch (e) {
      debugPrint('Failed to create gig: $e');
      setError(e.toString());
      return null;
    }
  }

  Future<bool> postReview(String gigId, Map<String, dynamic> reviewData) async {
    if (_isDisposed) return false;

    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/seller/gig/review/$gigId',
        data: reviewData,
      );

      if (response['statusCode'] == 200) {
        Review newReview;

        if (response['data'] != null) {
          newReview = Review.fromJson(response['data'] as Map<String, dynamic>);
        } else {
          final currentUser = _userProvider.currentUser;
          if (currentUser == null) {
            setError(
              'User not logged in to post review.',
            );
            return false;
          }

          newReview = Review(
            uuid: DateTime.now().millisecondsSinceEpoch.toString(),
            rating: reviewData['rating'] as int,
            review: reviewData['review'] as String,
            user: ReviewUser(
              uuid: currentUser.uuid,
              firstName: currentUser.firstName ?? '',
              lastName: currentUser.lastName ?? '',
              email: currentUser.email ?? '',
              profilePicture: currentUser.profileImage,
            ),
            createdAt: DateTime.now().toIso8601String(),
          );
        }

        _addReviewToGig(gigId, newReview);
        setSuccess();
        return true;
      } else {
        final errorMsg =
            response['message'] as String? ?? 'Failed to submit review';
        setError(errorMsg);
        return false;
      }
    } catch (e) {
      debugPrint('Failed to post review: $e');
      setError(
        'An unexpected error occurred: ${e.toString()}',
      );
      return false;
    }
  }

  Future<List<Gig>> fetchGigsBySubCategory(String subCategoryId) async {
    if (_isDisposed) return [];

    setLoading();
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
        setSuccess();
        return gigs;
      }
      setError(
        response['message'] ?? 'Failed to fetch gigs by subcategory',
      );
      return [];
    } catch (e) {
      debugPrint('Failed to fetch gigs by subcategory: $e');
      setError(e.toString());
      return [];
    }
  }

  void selectGig(Gig gig) {
    if (_isDisposed) return;
    _selectedGig = gig;
    setSuccess();
  }

  void clearSelectedGig() {
    if (_isDisposed) return;
    _selectedGig = null;
    setSuccess();
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

      _pusherService.bindToEvent(channelName, 'gig.created', (event) {
        if (_isDisposed) return;
        debugPrint('Received gig.created event: ${event.data}');

        try {
          if (event.data is String) {
            final gigData = jsonDecode(event.data) as Map<String, dynamic>;
            final newGig = Gig.fromJson(gigData);

            _gigsByStatus['all']!.insert(0, newGig);
            if (_gigsByStatus.containsKey(newGig.status)) {
              _gigsByStatus[newGig.status]!.insert(0, newGig);
            }

            setSuccess();
            debugPrint('Successfully added new gig: ${newGig.uuid}');
          }
        } catch (e) {
          debugPrint('GigProvider: Error processing gig.created event: $e');
          setError(
            'Error processing gig creation event: ${e.toString()}',
          );
        }
      });

      _pusherService.bindToEvent(channelName, 'gig.deleted', (event) {
        if (_isDisposed) return;
        debugPrint('Received gig.deleted event: ${event.data}');

        try {
          if (event.data is String) {
            final deletedGigData =
                jsonDecode(event.data) as Map<String, dynamic>;
            final gigUuid = deletedGigData['data']['uuid'] as String?;

            if (gigUuid != null) {
              for (final status in _gigsByStatus.keys) {
                _gigsByStatus[status]!.removeWhere(
                  (gig) => gig.uuid == gigUuid,
                );
              }

              if (_selectedGig?.uuid == gigUuid) {
                _selectedGig = null;
              }

              setSuccess();
              debugPrint('Successfully removed gig: $gigUuid');
            }
          }
        } catch (e) {
          debugPrint('GigProvider: Error processing gig.deleted event: $e');
          setError(
            'Error processing gig deletion event: ${e.toString()}',
          );
        }
      });
    } catch (e) {
      debugPrint(
        'GigProvider: Failed to subscribe to general gigs channel: $e',
      );
      setError(
        'Failed to subscribe to general gigs channel: ${e.toString()}',
      );
    }
  }

  Future<void> subscribeToSpecificGigChannel(String gigUuid) async {
    if (_isDisposed) return;

    final channelName = 'gig.approved.$gigUuid';
    final rejectedChannelName = 'gig.rejected.$gigUuid';
    final reviewChannelName = 'gig.review.$gigUuid';

    try {
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
          setError(
            'Failed to subscribe to approved channel: $channelName',
          );
        }
      }

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
          setError(
            'Failed to subscribe to rejected channel: $rejectedChannelName',
          );
        }
      }

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
          setError(
            'Failed to subscribe to review channel: $reviewChannelName',
          );
        }
      }
    } catch (e) {
      debugPrint(
        'Failed to subscribe to specific gig channels for $gigUuid: $e',
      );
      setError(
        'Failed to subscribe to specific gig channels: ${e.toString()}',
      );
    }
  }

  void _handleGigApprovedEvent(PusherEvent event, String gigUuid) {
    if (_isDisposed) return;

    try {
      if (event.data is String) {
        final eventData = jsonDecode(event.data) as Map<String, dynamic>;

        if (eventData['data'] is Map<String, dynamic>) {
          final updatedGig = Gig.fromJson(
            eventData['data'] as Map<String, dynamic>,
          );
          _updateGigInAllLists(gigUuid, updatedGig);
          setSuccess();
          debugPrint('Successfully updated gig status to VERIFIED: $gigUuid');
        }
      }
    } catch (e) {
      debugPrint('GigProvider: Error processing gig.approved event: $e');
      setError(
        'Error processing gig approval event: ${e.toString()}',
      );
    }
  }

  void _handleGigRejectedEvent(PusherEvent event, String gigUuid) {
    if (_isDisposed) return;

    try {
      if (event.data is String) {
        final eventData = jsonDecode(event.data) as Map<String, dynamic>;

        if (eventData['data'] is Map<String, dynamic>) {
          final updatedGig = Gig.fromJson(
            eventData['data'] as Map<String, dynamic>,
          );
          _updateGigInAllLists(gigUuid, updatedGig);
          setSuccess();
          debugPrint('Successfully updated gig status to REJECTED: $gigUuid');
        }
      }
    } catch (e) {
      debugPrint('GigProvider: Error processing gig.rejected event: $e');
      setError(
        'Error processing gig rejection event: ${e.toString()}',
      );
    }
  }

  void _handleGigReviewEvent(PusherEvent event, String gigUuid) {
    if (_isDisposed) return;

    try {
      debugPrint('Processing gig.review event for gig: $gigUuid');
      debugPrint('Event data type: ${event.data.runtimeType}');
      debugPrint('Event data: ${event.data}');

      if (event.data is String) {
        final eventData = jsonDecode(event.data) as Map<String, dynamic>;
        debugPrint('Decoded event data: $eventData');

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
          newReview = Review.fromJson(eventData);
        }

        if (newReview != null) {
          _addReviewToGig(gigUuid, newReview);
          setSuccess();
          debugPrint('Successfully added new review to gig: $gigUuid');
          debugPrint(
            'Review rating: ${newReview.rating}, Review text: ${newReview.review}',
          );
        } else {
          debugPrint('Could not extract review data from event');
          setError(
            'Could not extract review data from event for gig: $gigUuid',
          );
        }
      } else {
        debugPrint('Event data is not a string, received: ${event.data}');
        setError(
          'Unexpected event data type for gig review: ${event.data.runtimeType}',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('GigProvider: Error processing gig.review event: $e');
      debugPrint('Stack trace: $stackTrace');
      setError(
        'Error processing gig review event: ${e.toString()}',
      );
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

    safeNotifyListeners();
  }

  void _addReviewToGig(String gigUuid, Review newReview) {
    if (_isDisposed) return;

    debugPrint('Adding review to gig: $gigUuid');
    debugPrint(
      'Review details: rating=${newReview.rating}, uuid=${newReview.uuid}',
    );

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

    safeNotifyListeners();
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

  void clearError() {
    resetState();
  }

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