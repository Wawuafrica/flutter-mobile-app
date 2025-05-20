import 'dart:convert';
import '../models/review.dart';
import '../providers/base_provider.dart';
import '../services/api_service.dart';
import '../services/pusher_service.dart';

/// ReviewProvider manages the state of reviews.
///
/// This provider handles:
/// - Fetching reviews for a user
/// - Fetching reviews for a gig
/// - Creating new reviews
/// - Real-time updates via Pusher
class ReviewProvider extends BaseProvider {
  final ApiService _apiService;
  final PusherService _pusherService;

  List<Review> _reviews = [];
  bool _isSubscribed = false;

  // Getters
  List<Review> get reviews => _reviews;

  ReviewProvider({ApiService? apiService, PusherService? pusherService})
      : _apiService = apiService ?? ApiService(),
        _pusherService = pusherService ?? PusherService();

  /// Fetches reviews for a specific user
  Future<List<Review>> fetchUserReviews(String userId) async {
    final result = await handleAsync(() async {
      // Call the API to get reviews for a user
      final response = await _apiService.get<Map<String, dynamic>>(
        '/users/$userId/reviews',
      );

      if (response.containsKey('data') && response['data'] is List) {
        final List<dynamic> reviewsJson = response['data'] as List<dynamic>;
        final List<Review> fetchedReviews = reviewsJson
            .map((json) => Review.fromJson(json as Map<String, dynamic>))
            .toList();

        // Sort reviews by creation date, newest first
        fetchedReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        _reviews = fetchedReviews;

        // Subscribe to reviews channel if not already subscribed
        if (!_isSubscribed) {
          await _subscribeToReviewsChannel();
        }

        return fetchedReviews;
      } else {
        // Handle empty or invalid response
        _reviews = [];
        return [];
      }
    }, errorMessage: 'Failed to fetch user reviews');

    final List<Review> typedResult = result?.cast<Review>() ?? []; return typedResult;
  }

  /// Fetches reviews for a specific gig
  Future<List<Review>> fetchGigReviews(String gigId) async {
    final result = await handleAsync(() async {
      // Call the API to get reviews for a gig
      final response = await _apiService.get<Map<String, dynamic>>(
        '/gigs/$gigId/reviews',
      );

      if (response.containsKey('data') && response['data'] is List) {
        final List<dynamic> reviewsJson = response['data'] as List<dynamic>;
        final List<Review> fetchedReviews = reviewsJson
            .map((json) => Review.fromJson(json as Map<String, dynamic>))
            .toList();

        // Sort reviews by creation date, newest first
        fetchedReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        _reviews = fetchedReviews;

        return fetchedReviews;
      } else {
        // Handle empty or invalid response
        _reviews = [];
        return [];
      }
    }, errorMessage: 'Failed to fetch gig reviews');

    final List<Review> typedResult = result?.cast<Review>() ?? []; return typedResult;
  }

  /// Creates a new review
  Future<Review?> createReview({
    required String gigId,
    required String reviewedId,
    required double rating,
    required String comment,
  }) async {
    return await handleAsync(() async {
      // Create the API request payload
      final Map<String, dynamic> payload = {
        'gig_id': gigId,
        'reviewed_id': reviewedId,
        'rating': rating,
        'comment': comment,
      };

      // Call the API to create the review
      final response = await _apiService.post<Map<String, dynamic>>(
        '/reviews',
        data: payload,
      );

      if (response.containsKey('data')) {
        final review = Review.fromJson(response['data'] as Map<String, dynamic>);

        // Add to reviews if we're currently viewing reviews for this user or gig
        if (_reviews.isNotEmpty && 
            (_reviews.first.reviewedId == reviewedId || _reviews.first.gigId == gigId)) {
          _reviews.add(review);
          _reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          notifyListeners();
        }

        return review;
      } else {
        throw Exception('Invalid response format when creating review');
      }
    }, errorMessage: 'Failed to create review');
  }

  /// Updates an existing review
  Future<Review?> updateReview({
    required String reviewId,
    required double rating,
    required String comment,
  }) async {
    return await handleAsync(() async {
      // Create the API request payload
      final Map<String, dynamic> payload = {
        'rating': rating,
        'comment': comment,
      };

      // Call the API to update the review
      final response = await _apiService.put<Map<String, dynamic>>(
        '/reviews/$reviewId',
        data: payload,
      );

      if (response.containsKey('data')) {
        final updatedReview = Review.fromJson(response['data'] as Map<String, dynamic>);

        // Update in reviews list if present
        for (int i = 0; i < _reviews.length; i++) {
          if (_reviews[i].id == reviewId) {
            _reviews[i] = updatedReview;
            notifyListeners();
            break;
          }
        }

        return updatedReview;
      } else {
        throw Exception('Invalid response format when updating review');
      }
    }, errorMessage: 'Failed to update review');
  }

  /// Deletes a review
  Future<bool> deleteReview(String reviewId) async {
    final result = await handleAsync(() async {
      // Call the API to delete the review
      await _apiService.delete<Map<String, dynamic>>(
        '/reviews/$reviewId',
      );

      // Remove from reviews list if present
      _reviews.removeWhere((review) => review.id == reviewId);
      notifyListeners();

      return true;
    }, errorMessage: 'Failed to delete review');

    return result ?? false;
  }

  /// Subscribes to reviews channel for real-time updates
  Future<void> _subscribeToReviewsChannel() async {
    // Channel for reviews
    const channelName = 'reviews';

    final channel = await _pusherService.subscribeToChannel(channelName);
    if (channel != null) {
      _isSubscribed = true;

      // Bind to review created event
      _pusherService.bindToEvent(channelName, 'ReviewCreated', (data) async {
        if (data is String) {
          final jsonData = jsonDecode(data) as Map<String, dynamic>;
          
          if (jsonData.containsKey('review') && jsonData['review'] is Map<String, dynamic>) {
            final reviewData = jsonData['review'] as Map<String, dynamic>;
            final review = Review.fromJson(reviewData);

            // Add to reviews if we're currently viewing reviews for this user or gig
            if (_reviews.isNotEmpty && 
                (_reviews.first.reviewedId == review.reviewedId || _reviews.first.gigId == review.gigId)) {
              _reviews.add(review);
              _reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              notifyListeners();
            }
          }
        }
      });

      // Bind to review updated event
      _pusherService.bindToEvent(channelName, 'ReviewUpdated', (data) async {
        if (data is String) {
          final jsonData = jsonDecode(data) as Map<String, dynamic>;
          
          if (jsonData.containsKey('review') && jsonData['review'] is Map<String, dynamic>) {
            final reviewData = jsonData['review'] as Map<String, dynamic>;
            final updatedReview = Review.fromJson(reviewData);

            // Update in reviews list if present
            for (int i = 0; i < _reviews.length; i++) {
              if (_reviews[i].id == updatedReview.id) {
                _reviews[i] = updatedReview;
                notifyListeners();
                break;
              }
            }
          }
        }
      });

      // Bind to review deleted event
      _pusherService.bindToEvent(channelName, 'ReviewDeleted', (data) async {
        if (data is String) {
          final jsonData = jsonDecode(data) as Map<String, dynamic>;
          
          if (jsonData.containsKey('review_id')) {
            final reviewId = jsonData['review_id'] as String;
            
            // Remove from reviews list if present
            _reviews.removeWhere((review) => review.id == reviewId);
            notifyListeners();
          }
        }
      });
    }
  }

  /// Clears all review data
  void clearAll() {
    _reviews = [];
    _isSubscribed = false;
    resetState();
  }

  @override
  void dispose() {
    if (_isSubscribed) {
      _pusherService.unsubscribeFromChannel('reviews');
    }
    super.dispose();
  }
}
