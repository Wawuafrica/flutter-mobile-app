import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:wawu_mobile/models/wawu_africa_social.dart';

import '../models/wawu_africa_nest.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'base_provider.dart';
import 'user_provider.dart';

class WawuAfricaProvider extends BaseProvider {
  final ApiService _apiService;
  final UserProvider _userProvider;
  final SocketService _socketService;
  StreamSubscription? _socketSubscription;

  // Base URL for the Node.js/Express backend
  static const String _tsBackendBaseUrl = 'https://ts.wawuafrica.com/api';

  List<WawuAfricaCategory> _categories = [];
  List<WawuAfricaSubCategory> _subCategories = [];
  List<WawuAfricaInstitution> _institutions = [];
  List<WawuAfricaInstitutionContent> _institutionContents = [];
  WawuAfricaCategory? _selectedCategory;
  WawuAfricaSubCategory? _selectedSubCategory;
  WawuAfricaInstitution? _selectedInstitution;
  WawuAfricaInstitutionContent? _selectedInstitutionContent;

  List<Comment> _comments = [];
  bool _isSendingComment = false;
  final Map<String, int> _likeCounts = {};
  final Map<String, bool> _userLikes = {};

  List<WawuAfricaCategory> get categories => _categories;
  List<WawuAfricaSubCategory> get subCategories => _subCategories;
  List<WawuAfricaInstitution> get institutions => _institutions;
  List<WawuAfricaInstitutionContent> get institutionContents =>
      _institutionContents;
  WawuAfricaCategory? get selectedCategory => _selectedCategory;
  WawuAfricaSubCategory? get selectedSubCategory => _selectedSubCategory;
  WawuAfricaInstitution? get selectedInstitution => _selectedInstitution;
  WawuAfricaInstitutionContent? get selectedInstitutionContent =>
      _selectedInstitutionContent;

  List<Comment> get comments => _comments;
  bool get isSendingComment => _isSendingComment;

  int getLikeCount(String type, int id) => _likeCounts['$type-$id'] ?? 0;
  bool isLikedByUser(String type, int id) => _userLikes['$type-$id'] ?? false;

  WawuAfricaProvider({
    required ApiService apiService,
    required UserProvider userProvider,
    required SocketService socketService,
  }) : _apiService = apiService,
       _userProvider = userProvider,
       _socketService = socketService,
       super();

  // --- Main Data Fetching ---

  /// **UX IMPROVEMENT NOTE:**
  /// This function is structured to fetch all necessary data (comments, like counts, and user's like status)
  /// *before* notifying the UI to build the list. By using `Future.wait`, we run many API calls in parallel
  /// to minimize the total loading time. The UI will only see a single loading state, preventing the bad UX
  /// of comments appearing first and likes "popping in" a moment later.
  Future<void> fetchCommentsAndLikes(int contentId) async {
    setLoading();
    try {
      // 1. Fetch all comments first, as we need their IDs for the next steps.
      final commentsResponse = await _apiService.get<List<dynamic>>(
        '$_tsBackendBaseUrl/content/$contentId/comments',
      );
      final fetchedComments =
          commentsResponse
              .map((json) => Comment.fromJson(json as Map<String, dynamic>))
              .toList();

      // 2. Concurrently fetch all like counts and the user's specific like statuses.
      await Future.wait([
        _fetchInitialLikeCounts(contentId, fetchedComments),
        _fetchUserLikeStatus(contentId),
      ]);

      // 3. Only after all data is ready, update the state and notify the UI.
      _comments = fetchedComments;
      setSuccess();
      debugPrint(
        '✅ PROVIDER: Successfully fetched comments and all like data concurrently.',
      );
    } catch (e) {
      setError('Failed to load comments. Please try again.');
      debugPrint('❌ PROVIDER: Error fetching comments/likes: $e');
    }
  }

  /// Helper to get like counts for all comments and the main content.
  Future<void> _fetchInitialLikeCounts(
    int contentId,
    List<Comment> comments,
  ) async {
    List<Future<void>> futures = [];

    // Add future for the main content's like count
    futures.add(
      _apiService
          .get<Map<String, dynamic>>(
            '$_tsBackendBaseUrl/likes/count/content/$contentId',
          )
          .then((response) {
            _likeCounts['content-$contentId'] = response['count'] ?? 0;
          }),
    );

    // Recursively add futures for all comments and their replies
    void addCommentFutures(List<Comment> commentList) {
      for (var comment in commentList) {
        futures.add(
          _apiService
              .get<Map<String, dynamic>>(
                '$_tsBackendBaseUrl/likes/count/comment/${comment.id}',
              )
              .then((response) {
                _likeCounts['comment-${comment.id}'] = response['count'] ?? 0;
              }),
        );
        if (comment.replies.isNotEmpty) {
          addCommentFutures(comment.replies);
        }
      }
    }

    addCommentFutures(comments);

    // Execute all API calls in parallel
    await Future.wait(futures);
  }

  /// **FIX FOR LIKES NOT SHOWING**: Fetches which items the current user has liked.
  /// NOTE: This requires a new backend endpoint.
  Future<void> _fetchUserLikeStatus(int contentId) async {
    // If user is not logged in, we can skip this.
    if (_userProvider.currentUser == null) return;

    try {
      final response = await _apiService.get<List<dynamic>>(
        '$_tsBackendBaseUrl/likes/user-status/content/$contentId',
      );

      // Clear previous user likes for this page and populate with new data
      _userLikes.clear();
      for (var like in response) {
        final key = '${like['likeable_type']}-${like['likeable_id']}';
        _userLikes[key] = true;
      }
    } catch (e) {
      debugPrint(
        '⚠️ PROVIDER: Could not fetch user like status. The backend endpoint might be missing. Error: $e',
      );
    }
  }

  // --- Social Actions (Comments, Likes, Deletes) ---

  Future<void> postComment({
    required String comment,
    required int contentId,
    int? parentCommentId,
  }) async {
    _isSendingComment = true;
    notifyListeners();
    try {
      await _apiService.post(
        '$_tsBackendBaseUrl/comments',
        data: {
          'comment': comment,
          'wawu_africa_institution_content_id': contentId,
          if (parentCommentId != null) 'parent_comment_id': parentCommentId,
        },
      );
      debugPrint('✅ PROVIDER: Comment posted successfully.');
    } catch (e) {
      setError('Failed to post comment.');
      debugPrint('❌ PROVIDER: Error posting comment: $e');
      rethrow;
    } finally {
      _isSendingComment = false;
      notifyListeners();
    }
  }

  Future<void> toggleLike(String likeableType, int likeableId) async {
    final key = '$likeableType-$likeableId';
    final wasLiked = _userLikes[key] ?? false;

    // Optimistic UI update: change state immediately and notify listeners.
    _userLikes[key] = !wasLiked;
    _likeCounts[key] = (_likeCounts[key] ?? 0) + (!wasLiked ? 1 : -1);
    notifyListeners();
    debugPrint(
      'PROVIDER: Optimistically updated like for $key. New state: ${!wasLiked}',
    );

    try {
      await _apiService.post(
        '$_tsBackendBaseUrl/likes/toggle',
        data: {'likeable_id': likeableId, 'likeable_type': likeableType},
      );
    } catch (e) {
      // If API call fails, revert the state and notify listeners again.
      _userLikes[key] = wasLiked;
      _likeCounts[key] = (_likeCounts[key] ?? 0) - (!wasLiked ? 1 : -1);
      notifyListeners();
      debugPrint(
        '❌ PROVIDER: Error toggling like for $key. Reverted state. Error: $e',
      );
    }
  }

  Future<void> deleteComment(int commentId) async {
    // Optimistically remove the comment from the UI immediately.
    _removeCommentById(_comments, commentId);
    notifyListeners();
    debugPrint('PROVIDER: Optimistically removed comment ID: $commentId');

    try {
      await _apiService.delete('$_tsBackendBaseUrl/comments/$commentId');
    } catch (e) {
      // If the deletion fails, we would ideally re-fetch the comments
      // to restore state, but for now, we'll just log the error.
      // A snackbar could also be shown to the user.
      debugPrint(
        '❌ PROVIDER: Error deleting comment ID: $commentId. UI state may be inconsistent. Error: $e',
      );
    }
  }

  // --- Real-time Socket Event Handling ---

  void listenToRealtimeUpdates(int contentId) {
    _socketService.joinContentRoom(contentId);
    _socketSubscription = _socketService.socketResponseStream.listen((
      eventData,
    ) {
      final event = eventData['event'];
      final data = eventData['data'];

      switch (event) {
        case 'new_comment':
          _handleNewComment(data);
          break;
        case 'like_update':
          _handleLikeUpdate(data);
          break;
        case 'deleted_comment':
          _handleDeletedComment(data);
          break;
      }
    });
  }

  void _handleNewComment(Map<String, dynamic> data) {
    final newComment = Comment.fromJson(data);
    if (newComment.parentCommentId != null) {
      final parent = _findCommentById(_comments, newComment.parentCommentId!);
      parent?.replies.add(newComment);
    } else {
      _comments.add(newComment);
    }
    notifyListeners();
  }

  void _handleLikeUpdate(Map<String, dynamic> data) {
    final type = data['likeable_type'] as String;
    final id = data['likeable_id'] as int;
    final count = data['count'] as int;
    final key = '$type-$id';
    _likeCounts[key] = count;
    notifyListeners();
    debugPrint(
      'PROVIDER (REAL-TIME): Received like update for $key. New count: $count',
    );
  }

  void _handleDeletedComment(Map<String, dynamic> data) {
    final commentId = data['id'] as int;
    debugPrint(
      'PROVIDER (REAL-TIME): Received delete event for comment ID: $commentId',
    );
    final removed = _removeCommentById(_comments, commentId);
    if (removed) {
      notifyListeners();
    }
  }

  // --- Utility and Cleanup ---

  bool _removeCommentById(List<Comment> commentList, int id) {
    for (int i = 0; i < commentList.length; i++) {
      if (commentList[i].id == id) {
        commentList.removeAt(i);
        return true;
      }
      if (_removeCommentById(commentList[i].replies, id)) {
        return true;
      }
    }
    return false;
  }

  Comment? _findCommentById(List<Comment> comments, int id) {
    for (var comment in comments) {
      if (comment.id == id) return comment;
      final foundInReply = _findCommentById(comment.replies, id);
      if (foundInReply != null) return foundInReply;
    }
    return null;
  }

  void stopListeningToRealtimeUpdates(int contentId) {
    _socketService.leaveContentRoom(contentId);
    _socketSubscription?.cancel();
    _comments = [];
    _likeCounts.clear();
    _userLikes.clear();
  }

  Future<List<WawuAfricaCategory>> fetchCategories() async {
    setLoading();
    try {
      final response = await _apiService.get<List<dynamic>>(
        '$_tsBackendBaseUrl/categories',
      );
      _categories =
          response
              .map(
                (json) =>
                    WawuAfricaCategory.fromJson(json as Map<String, dynamic>),
              )
              .toList();
      setSuccess();
      return _categories;
    } catch (e) {
      setError(e.toString());
      return [];
    }
  }

  Future<List<WawuAfricaSubCategory>> fetchSubCategories(
    String categoryId,
  ) async {
    setLoading();
    try {
      final response = await _apiService.get<List<dynamic>>(
        '$_tsBackendBaseUrl/sub-categories/category/$categoryId',
      );
      _subCategories =
          response
              .map(
                (json) => WawuAfricaSubCategory.fromJson(
                  json as Map<String, dynamic>,
                ),
              )
              .toList();
      setSuccess();
      return _subCategories;
    } catch (e) {
      setError(e.toString());
      return [];
    }
  }

  Future<List<WawuAfricaInstitution>> fetchInstitutionsBySubCategory(
    String subCategoryId,
  ) async {
    setLoading();
    try {
      final response = await _apiService.get<List<dynamic>>(
        '$_tsBackendBaseUrl/institutions/sub-category/$subCategoryId',
      );
      _institutions =
          response
              .map(
                (json) => WawuAfricaInstitution.fromJson(
                  json as Map<String, dynamic>,
                ),
              )
              .toList();
      setSuccess();
      return _institutions;
    } catch (e) {
      setError(e.toString());
      return [];
    }
  }

  Future<List<WawuAfricaInstitutionContent>>
  fetchInstitutionContentsByInstitutionId(String institutionId) async {
    setLoading();
    try {
      final response = await _apiService.get<List<dynamic>>(
        '$_tsBackendBaseUrl/institution-contents/institution/$institutionId',
      );
      _institutionContents =
          response
              .map(
                (json) => WawuAfricaInstitutionContent.fromJson(
                  json as Map<String, dynamic>,
                ),
              )
              .toList();
      setSuccess();
      return _institutionContents;
    } catch (e) {
      setError(e.toString());
      return [];
    }
  }

  Future<void> registerForContent(int institutionContentId) async {
    setLoading();
    try {
      final currentUserId = _userProvider.currentUser?.uuid ?? '';
      final userFullName =
          '${_userProvider.currentUser?.firstName ?? ''} ${_userProvider.currentUser?.lastName ?? ''}'
              .trim();
      final userEmail = _userProvider.currentUser?.email ?? '';
      if (currentUserId.isEmpty) {
        throw Exception('User information is missing. Please log in again.');
      }
      await _apiService.post<Map<String, dynamic>>(
        '$_tsBackendBaseUrl/register-user',
        data: {
          'user_id': currentUserId,
          'user_full_name': userFullName,
          'user_email': userEmail,
          'wawu_africa_inst_content_id': institutionContentId,
        },
      );
      setSuccess();
    } catch (e) {
      setError(e.toString());
      rethrow;
    }
  }

  void clearError() => resetState();
  void clearSubCategories() {
    _subCategories = [];
    notifyListeners();
  }

  void clearInstitutions() {
    _institutions = [];
    notifyListeners();
  }

  void clearInstitutionContents() {
    _institutionContents = [];
    notifyListeners();
  }

  void selectCategory(WawuAfricaCategory c) {
    _selectedCategory = c;
    notifyListeners();
  }

  void selectSubCategory(WawuAfricaSubCategory sc) {
    _selectedSubCategory = sc;
    notifyListeners();
  }

  void selectInstitution(WawuAfricaInstitution i) {
    _selectedInstitution = i;
    notifyListeners();
  }

  void selectInstitutionContent(WawuAfricaInstitutionContent c) {
    _selectedInstitutionContent = c;
    notifyListeners();
  }
}
