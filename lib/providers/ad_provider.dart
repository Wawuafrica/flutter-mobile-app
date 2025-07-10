import 'package:wawu_mobile/providers/base_provider.dart';
import '../models/ad.dart';
import '../services/api_service.dart';
import '../services/pusher_service.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:logger/logger.dart';

/// AdProvider manages the state of advertisements with real-time updates.
///
/// This provider handles:
/// - Fetching ads with pagination
/// - Real-time updates via Pusher (create/update/delete)
class AdProvider extends BaseProvider {
  final ApiService _apiService;
  final PusherService _pusherService;
  final Logger _logger = Logger();

  List<Ad> _ads = [];
  bool _pusherEventsInitialized = false;
  final Set<String> _subscribedAdChannels = {}; // Track ad-specific channels

  // Getters
  List<Ad> get ads => _ads;

  AdProvider({
    required ApiService apiService,
    required PusherService pusherService,
  }) : _apiService = apiService,
       _pusherService = pusherService {
    _initializePusherEvents();
  }

  /// Initialize Pusher event listeners for ads
  void _initializePusherEvents() {
    if (_pusherEventsInitialized || !_pusherService.isInitialized) {
      return;
    }

    _logger.i('AdProvider: Initializing Pusher events for ads');

    // Listen for new ads created on 'ads' channel
    _pusherService.bindToEvent('ads', 'ad.created', _handleAdCreated);

    // Listen for ad deletions on 'ads' channel
    _pusherService.bindToEvent('ads', 'ad.deleted', _handleAdDeleted);

    _pusherEventsInitialized = true;
    _logger.d('AdProvider: Pusher events initialized successfully');
  }

  /// Handle new ad created event
  void _handleAdCreated(PusherEvent event) {
    try {
      _logger.i('AdProvider: Received ad.created event: ${event.data}');
      final adData = event.data as Map<String, dynamic>;

      final newAd = Ad.fromJson(adData);

      // Add new ad to the beginning of the list
      _ads.insert(0, newAd);
      notifyListeners();

      _logger.d('AdProvider: New ad added: ${newAd.uuid}');
    } catch (e) {
      _logger.e('AdProvider: Error handling ad.created event: $e');
    }
  }

  /// Handle ad updated event
  void _handleAdUpdated(PusherEvent event) {
    try {
      _logger.i('AdProvider: Received ad.updated event: ${event.data}');
      final adData = event.data as Map<String, dynamic>;

      final updatedAd = Ad.fromJson(adData);

      // Update ad in the list
      final adIndex = _ads.indexWhere((ad) => ad.uuid == updatedAd.uuid);
      if (adIndex != -1) {
        _ads[adIndex] = updatedAd;
        notifyListeners();
        _logger.d('AdProvider: Ad updated: ${updatedAd.uuid}');
      } else {
        _logger.w(
          'AdProvider: Updated ad not found in list: ${updatedAd.uuid}',
        );
      }
    } catch (e) {
      _logger.e('AdProvider: Error handling ad.updated event: $e');
    }
  }

  /// Handle ad deleted event
  void _handleAdDeleted(PusherEvent event) {
    try {
      _logger.i('AdProvider: Received ad.deleted event: ${event.data}');
      final eventData = event.data as Map<String, dynamic>;
      final deletedAdUuid = eventData['uuid'] as String?;

      if (deletedAdUuid == null) {
        throw Exception('Could not extract ad UUID from deletion event');
      }

      // Remove ad from the list
      final initialLength = _ads.length;
      _ads.removeWhere((ad) => ad.uuid == deletedAdUuid);

      if (_ads.length < initialLength) {
        notifyListeners();
        _logger.d('AdProvider: Ad deleted: $deletedAdUuid');
      } else {
        _logger.w('AdProvider: Deleted ad not found in list: $deletedAdUuid');
      }
    } catch (e) {
      _logger.e('AdProvider: Error handling ad.deleted event: $e');
    }
  }

  /// Subscribe to ad-specific events when viewing/managing a specific ad
  /// This subscribes to the ad.updated.{ad_uuid} channel for real-time updates
  Future<void> subscribeToAdEvents(String adUuid) async {
    if (!_pusherService.isInitialized) {
      _logger.w(
        'AdProvider: PusherService not initialized, cannot subscribe to ad events',
      );
      return;
    }

    final adChannel = 'ad.updated.$adUuid';

    if (_subscribedAdChannels.contains(adChannel)) {
      _logger.d('AdProvider: Already subscribed to channel: $adChannel');
      return;
    }

    _logger.i('AdProvider: Subscribing to events for ad: $adUuid');

    // Subscribe to ad-specific channel for real-time updates
    final success = await _pusherService.subscribeToChannel(adChannel);

    if (success) {
      _subscribedAdChannels.add(adChannel);

      // Bind to ad-specific update events
      _pusherService.bindToEvent(adChannel, 'ad.updated', _handleAdUpdated);

      _logger.d(
        'AdProvider: Successfully subscribed to ad channel: $adChannel',
      );
    } else {
      _logger.e('AdProvider: Failed to subscribe to ad channel: $adChannel');
    }
  }

  /// Unsubscribe from ad-specific events
  Future<void> unsubscribeFromAdEvents(String adUuid) async {
    if (!_pusherService.isInitialized) {
      return;
    }

    final adChannel = 'ad.updated.$adUuid';

    if (!_subscribedAdChannels.contains(adChannel)) {
      _logger.d('AdProvider: Not subscribed to channel: $adChannel');
      return;
    }

    _logger.i('AdProvider: Unsubscribing from events for ad: $adUuid');

    await _pusherService.unsubscribeFromChannel(adChannel);
    _subscribedAdChannels.remove(adChannel);

    _logger.d(
      'AdProvider: Successfully unsubscribed from ad channel: $adChannel',
    );
  }

  /// Unsubscribe from all ad-specific channels
  Future<void> unsubscribeFromAllAdEvents() async {
    if (!_pusherService.isInitialized) {
      return;
    }

    _logger.i('AdProvider: Unsubscribing from all ad-specific channels');

    for (final channel in _subscribedAdChannels.toList()) {
      await _pusherService.unsubscribeFromChannel(channel);
    }

    _subscribedAdChannels.clear();
    _logger.d('AdProvider: Unsubscribed from all ad-specific channels');
  }

  /// Fetch ads from the API
  Future<void> fetchAds() async {
    setLoading();

    try {
      _logger.i('AdProvider: Fetching from .../ads?paginate=1&pageNumber=1');
      final response = await _apiService.get(
        '/ads?paginate=1&pageNumber=1',
        fromJson: (data) {
          final List<dynamic> adsData = data['data'];
          return adsData.map((json) => Ad.fromJson(json)).toList();
        },
      );
      _logger.i('AdProvider: Ads fetched successfully: ${response.length} ads');
      setSuccess();
      _ads = response;

      // Initialize Pusher events if not already done and service is ready
      if (!_pusherEventsInitialized && _pusherService.isInitialized) {
        _initializePusherEvents();
      }
    } catch (e) {
      _logger.e('AdProvider: Error fetching ads: $e');
      setError('error message: ${e.toString()}');
    }
  }

  /// Get ad by UUID
  Ad? getAdByUuid(String uuid) {
    try {
      return _ads.firstWhere((ad) => ad.uuid == uuid);
    } catch (e) {
      return null;
    }
  }

  /// Filter ads by page
  List<Ad> getAdsByPage(String page) {
    return _ads
        .where((ad) => ad.page.toLowerCase() == page.toLowerCase())
        .toList();
  }

  /// Filter ads by timeframe
  List<Ad> getAdsByTimeframe(String timeframe) {
    return _ads
        .where((ad) => ad.timeframe.toLowerCase() == timeframe.toLowerCase())
        .toList();
  }

  /// Get active ads (you can implement your own logic for what constitutes "active")
  List<Ad> getActiveAds() {
    final now = DateTime.now();
    return _ads.where((ad) {
      // Example logic: ads are active if created within the last 30 days
      // You can modify this based on your business logic
      final daysSinceCreation = now.difference(ad.createdAt).inDays;
      return daysSinceCreation <= 30;
    }).toList();
  }

  /// Reset ads list and clear state
  void reset() {
    _ads = [];
    setSuccess();
    notifyListeners();
  }

  /// Refresh ads by fetching from API
  Future<void> refresh() async {
    reset();
    await fetchAds();
  }

  @override
  void dispose() {
    // Clean up ad-specific channel subscriptions
    unsubscribeFromAllAdEvents();
    super.dispose();
  }
}
