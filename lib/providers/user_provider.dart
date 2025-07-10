import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart' as dio;
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';

import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/pusher_service.dart';

class UserProvider extends ChangeNotifier {
  final ApiService _apiService;
  final AuthService _authService;
  final PusherService _pusherService;
  final Logger _logger = Logger();

  User? _currentUser;
  User? _viewedUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  set isLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  bool _hasError = false;
  String? _errorMessage;
  bool _isSuccess = false;
  String? _userChannelName;
  bool _isSubscribed = false;

  UserProvider({
    required ApiService apiService,
    required AuthService authService,
    required PusherService pusherService,
  }) : _apiService = apiService,
       _authService = authService,
       _pusherService = pusherService {
    _currentUser = _authService.currentUser;
    if (_currentUser != null && _authService.isAuthenticated) {
      _subscribeToUserChannel();
    }
  }

  User? get currentUser => _currentUser;
  User? get viewedUser => _viewedUser;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  bool get isSuccess => _isSuccess;
  bool get isAuthenticated => _authService.isAuthenticated;

  void setLoading() {
    isLoading = true;
  }

  void setError(String message) {
    isLoading = false;
    _hasError = true;
    _errorMessage = message;
    _isSuccess = false;
    notifyListeners();
  }

  void setSuccess() {
    isLoading = false;
    _hasError = false;
    _errorMessage = null;
    _isSuccess = true;
    notifyListeners();
  }

  void resetState() {
    isLoading = false;
    _hasError = false;
    _errorMessage = null;
    _isSuccess = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    setLoading();
    try {
      _currentUser = await _authService.signIn(email, password);
      if (_currentUser != null) {
        await _subscribeToUserChannel();
        setSuccess();
      } else {
        setError('Login failed: User object is null.');
      }
    } on AuthException catch (e) {
      setError(e.toString());
    } catch (e) {
      setError('An unexpected error occurred during login: $e');
    }
  }

  Future<void> register(Map<String, dynamic> userData) async {
    setLoading();
    try {
      _currentUser = await _authService.register(userData);
      if (_authService.isAuthenticated && _currentUser != null) {
        await _subscribeToUserChannel();
        setSuccess();
      } else {
        setError('Registration successful but failed to log in automatically.');
      }
    } on AuthException catch (e) {
      setError(e.toString());
    } catch (e) {
      setError('An unexpected error occurred during registration: $e');
    }
  }

  Future<void> logout() async {
    setLoading();
    try {
      if (_userChannelName != null && _isSubscribed) {
        _logger.i(
          'UserProvider: Unsubscribing from channel: $_userChannelName',
        );
        await _pusherService.unsubscribeFromChannel(_userChannelName!);
        _userChannelName = null;
        _isSubscribed = false;
      }
      await _authService.logout();
      _currentUser = null;
      _viewedUser = null;
      setSuccess();
    } on dio.DioException catch (e) {
      final (message, _) = _authService.extractErrorMessage(e);
      setError(message);
    } catch (e) {
      setError('Logout failed: $e');
    } finally {
      _currentUser = null;
      _viewedUser = null;
      resetState();
    }
  }

  Future<void> fetchCurrentUser() async {
    if (!_authService.isAuthenticated) {
      _currentUser = null;
      resetState();
      return;
    }
    setLoading();
    try {
      _currentUser = await _authService.getCurrentUserProfile();
      if (_currentUser != null) {
        await _subscribeToUserChannel();
        setSuccess();
      } else {
        setError('Failed to fetch user profile: User is null after fetch.');
      }
    } on AuthException catch (e) {
      final (message, _) = _authService.extractErrorMessage(e);
      setError(message);
    } catch (e) {
      setError('Failed to fetch current user profile: $e');
    }
  }

  Future<void> updateAccountType(int roleValue) async {
    if (!_authService.isAuthenticated ||
        _authService.currentUser == null ||
        _authService.currentUser!.uuid.isEmpty) {
      setError(
        'User not authenticated or UUID missing for account type update.',
      );
      return;
    }

    setLoading();
    try {
      final response = await _apiService.post(
        '/user/onboard/${_authService.currentUser!.uuid}',
        data: {'role': roleValue},
      );

      if (response['statusCode'] == 200 && response.containsKey('data')) {
        final updatedUser = User.fromJson(
          response['data'] as Map<String, dynamic>,
        );
        _currentUser = updatedUser;
        await _authService.saveUser(_currentUser!);
        setSuccess();
        _logger.i(
          'UserProvider: Account Type updated successfully for: ${_currentUser!.email} to role: ${_currentUser!.role}',
        );
      } else {
        final message =
            response['message'] as String? ??
            'Failed to update account type: Invalid response structure.';
        setError(message);
      }
    } on dio.DioException catch (e) {
      final (message, _) = _authService.extractErrorMessage(e);
      setError(message);
    } catch (e) {
      setError('Failed to update account type: $e');
    }
  }

  Future<void> updateCurrentUserProfile({
    Map<String, dynamic>? data,
    XFile? profileImage,
    XFile? coverImage,
    XFile? professionalCertificationImage,
    XFile? meansOfIdentification,
  }) async {
    if (!_authService.isAuthenticated ||
        _authService.currentUser == null ||
        _authService.currentUser!.uuid.isEmpty) {
      setError('User not authenticated for profile update.');
      return;
    }
    setLoading();
    try {
      if (profileImage != null || coverImage != null) {
        final imageFormDataMap = <String, dynamic>{};
        if (profileImage != null) {
          imageFormDataMap['profileImage[file]'] =
              kIsWeb
                  ? dio.MultipartFile.fromBytes(
                    await profileImage.readAsBytes(),
                    filename: 'profile_image.png',
                  )
                  : await dio.MultipartFile.fromFile(
                    profileImage.path,
                    filename: profileImage.path.split('/').last,
                  );
          imageFormDataMap['profileImage[fileName]'] =
              kIsWeb ? 'profile_image.png' : profileImage.path.split('/').last;
        }
        if (coverImage != null) {
          imageFormDataMap['coverImage[file]'] =
              kIsWeb
                  ? dio.MultipartFile.fromBytes(
                    await coverImage.readAsBytes(),
                    filename: 'cover_image.png',
                  )
                  : await dio.MultipartFile.fromFile(
                    coverImage.path,
                    filename: coverImage.path.split('/').last,
                  );
          imageFormDataMap['coverImage[fileName]'] =
              kIsWeb ? 'cover_image.png' : coverImage.path.split('/').last;
        }
        final imageResponse = await _apiService.post(
          '/user/profile/image/update',
          data: dio.FormData.fromMap(imageFormDataMap),
        );
        if (imageResponse['statusCode'] != 200) {
          final message =
              imageResponse['message'] as String? ??
              'Failed to update profile images.';
          setError(message);
          return;
        }
      }
      // Handle other profile data if present with logging
      final hasOtherData =
          data != null &&
              (data['about'] != null ||
                  (data['skills'] != null &&
                      data['skills'] is List &&
                      (data['skills'] as List).isNotEmpty) ||
                  (data['educationCertification']?.toString().isNotEmpty ==
                      true) ||
                  (data['educationInstitution']?.toString().isNotEmpty ==
                      true) ||
                  (data['educationCourseOfStudy']?.toString().isNotEmpty ==
                      true) ||
                  (data['educationGraduationDate']?.toString().isNotEmpty ==
                      true) ||
                  (data['educationEndDate']?.toString().isNotEmpty == true) ||
                  (data['professionalCertificationName']
                          ?.toString()
                          .isNotEmpty ==
                      true) ||
                  (data['professionalCertificationOrganization']
                          ?.toString()
                          .isNotEmpty ==
                      true) ||
                  (data['professionalCertificationEndDate']
                          ?.toString()
                          .isNotEmpty ==
                      true) ||
                  (data['country']?.toString().trim().isNotEmpty == true) ||
                  (data['state']?.toString().trim().isNotEmpty == true) ||
                  (data['social'] != null) ||
                  data['subCategoryUuid'] != null) ||
          professionalCertificationImage != null ||
          meansOfIdentification != null;

      if (hasOtherData) {
        final profileFormDataMap = <String, dynamic>{};

        // Use data map to add about
        if (data?['about'] != null) {
          profileFormDataMap['about'] = data!['about'].toString().trim();
        }

        // Add skills only if present and not empty
        if (data?['skills'] != null && data!['skills'] is List) {
          final skills = data['skills'] as List;
          if (skills.isNotEmpty) {
            for (int i = 0; i < skills.length; i++) {
              profileFormDataMap['skills[$i]'] = skills[i].toString();
            }
          }
        }

        // Add education data only if at least one field has value
        final hasEducationData =
            (data?['educationCertification']?.toString().isNotEmpty == true) ||
            (data?['educationInstitution']?.toString().isNotEmpty == true) ||
            (data?['educationCourseOfStudy']?.toString().isNotEmpty == true) ||
            (data?['educationGraduationDate']?.toString().isNotEmpty == true) ||
            (data?['educationEndDate']?.toString().isNotEmpty == true);
        if (hasEducationData) {
          if (data?['educationCertification'] != null) {
            profileFormDataMap['education[1][certification]'] =
                data!['educationCertification'].toString();
          }
          if (data?['educationInstitution'] != null) {
            profileFormDataMap['education[1][institution]'] =
                data!['educationInstitution'].toString();
          }
          if (data?['educationCourseOfStudy'] != null) {
            profileFormDataMap['education[1][courseOfStudy]'] =
                data!['educationCourseOfStudy'].toString();
          }
          if (data?['educationGraduationDate'] != null) {
            profileFormDataMap['education[1][startDate]'] =
                data!['educationGraduationDate'].toString();
          }
          if (data?['educationEndDate'] != null) {
            profileFormDataMap['education[1][endDate]'] =
                data!['educationEndDate'].toString();
          }
        }

        // Add means of identification only if provided
        if (meansOfIdentification != null) {
          profileFormDataMap['meansOfIdentification[file]'] =
              kIsWeb
                  ? dio.MultipartFile.fromBytes(
                    await meansOfIdentification.readAsBytes(),
                    filename: 'id_doc.png',
                  )
                  : await dio.MultipartFile.fromFile(
                    meansOfIdentification.path,
                    filename: meansOfIdentification.path.split('/').last,
                  );
          profileFormDataMap['meansOfIdentification[fileName]'] =
              kIsWeb
                  ? 'id_doc.png'
                  : meansOfIdentification.path.split('/').last;
        }

        // Add professional certification only if at least one field has value
        final hasProfessionalCertData =
            (data?['professionalCertificationName']?.toString().isNotEmpty ==
                true) ||
            (data?['professionalCertificationOrganization']
                    ?.toString()
                    .isNotEmpty ==
                true) ||
            (data?['professionalCertificationEndDate']?.toString().isNotEmpty ==
                true) ||
            (professionalCertificationImage != null);
        if (hasProfessionalCertData) {
          if (data?['professionalCertificationName'] != null) {
            profileFormDataMap['professionalCertification[1][name]'] =
                data!['professionalCertificationName'].toString();
          }
          if (data?['professionalCertificationOrganization'] != null) {
            profileFormDataMap['professionalCertification[1][organization]'] =
                data!['professionalCertificationOrganization']
                    .toString()
                    .trim();
          }
          if (data?['professionalCertificationEndDate'] != null) {
            profileFormDataMap['professionalCertification[1][endDate]'] =
                data!['professionalCertificationEndDate'].toString().trim();
          }
          if (professionalCertificationImage != null) {
            profileFormDataMap['professionalCertification[1][file]'] =
                kIsWeb
                    ? dio.MultipartFile.fromBytes(
                      await professionalCertificationImage.readAsBytes(),
                      filename: 'cert_doc.png',
                    )
                    : await dio.MultipartFile.fromFile(
                      professionalCertificationImage.path,
                      filename:
                          professionalCertificationImage.path.split('/').last,
                    );
            profileFormDataMap['professionalCertification[1][fileName]'] =
                kIsWeb
                    ? 'cert_doc.png'
                    : professionalCertificationImage.path.split('/').last;
          }
        }

        // Add location data only if not empty
        if (data?['country'] != null &&
            data!['country'].toString().trim().isNotEmpty) {
          profileFormDataMap['country'] = data['country'].toString().trim();
        }
        if (data?['state'] != null &&
            data!['state'].toString().trim().isNotEmpty) {
          profileFormDataMap['state'] = data['state'].toString().trim();
        }
        if (data?['phoneNumber'] != null &&
            data!['phoneNumber'].toString().trim().isNotEmpty) {
          profileFormDataMap['phoneNumber'] =
              data['phoneNumber'].toString().trim();
        }

        // Add social handles only if not empty and data contains it
        if (data?['social'] != null && data!['social'] is Map) {
          final socialMap = data['social'] as Map<String, dynamic>;
          if (socialMap['facebook'] != null &&
              socialMap['facebook'].toString().trim().isNotEmpty) {
            profileFormDataMap['social[facebook]'] =
                socialMap['facebook'].toString().trim();
          }
          if (socialMap['linkedIn'] != null &&
              socialMap['linkedIn'].toString().trim().isNotEmpty) {
            profileFormDataMap['social[linkedIn]'] =
                socialMap['linkedIn'].toString().trim();
          }
          if (socialMap['instagram'] != null &&
              socialMap['instagram'].toString().trim().isNotEmpty) {
            profileFormDataMap['social[instagram]'] =
                socialMap['instagram'].toString().trim();
          }
          if (socialMap['twitter'] != null &&
              socialMap['twitter'].toString().trim().isNotEmpty) {
            profileFormDataMap['social[twitter]'] =
                socialMap['twitter'].toString().trim();
          }
        }

        // Add subCategoryUuid if present
        if (data?['subCategoryUuid'] != null) {
          profileFormDataMap['subCategoryUuid'] = data!['subCategoryUuid'];
        }

        _logger.d('Updating profile with data: $profileFormDataMap');

        final response = await _apiService.post(
          '/user/profile/update',
          data: dio.FormData.fromMap(profileFormDataMap),
        );
        if (response['statusCode'] != 200) {
          final message =
              response['message'] as String? ??
              'Failed to update profile: Invalid response structure.';
          setError(message);
          return;
        }
      }

      final finalResponse = await _apiService.get('/user/profile');
      if (finalResponse['statusCode'] == 200 &&
          finalResponse.containsKey('data')) {
        final updatedUser = User.fromJson(
          finalResponse['data'] as Map<String, dynamic>,
        );
        _currentUser = updatedUser;
        await _authService.saveUser(_currentUser!);
        setSuccess();
      } else {
        setSuccess(); // Set success even if fetch fails, as updates might have gone through
      }
    } on dio.DioException catch (e) {
      setError('API error during profile update: ${e.message}');
    } catch (e) {
      setError('Unexpected error during profile update: $e');
    } finally {
      if (isLoading) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Deletes the current user's account by calling the /user/delete endpoint.
  Future<bool> deleteUserAccount() async {
    setLoading();
    try {
      final response = await _apiService.post(
        '/user/account/delete',
        // data: {},
      );
      if (response['statusCode'] == 200) {
        // Clear all user state and log out
        await logout();
        setSuccess();
        return true;
      } else {
        final message =
            response['message'] as String? ?? 'Failed to delete account.';
        setError(message);
        return false;
      }
    } catch (e) {
      setError('Failed to delete account: $e');
      return false;
    }
  }

  Future<void> fetchUserById(String userId) async {
    setLoading();
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/user/$userId',
      );
      if (response['statusCode'] == 200 && response.containsKey('data')) {
        _viewedUser = User.fromJson(response['data'] as Map<String, dynamic>);
        setSuccess();
      } else {
        final message =
            response['message'] as String? ??
            'Failed to fetch user profile by ID: Invalid response structure.';
        setError(message);
        _viewedUser = null;
      }
    } on dio.DioException catch (e) {
      final (message, _) = _authService.extractErrorMessage(e);
      setError(message);
      _viewedUser = null;
    } catch (e) {
      setError('Failed to fetch user profile: $e');
      _viewedUser = null;
    }
  }

  Future<void> _subscribeToUserChannel() async {
    if (!_authService.isAuthenticated ||
        _authService.currentUser == null ||
        _authService.currentUser!.uuid.isEmpty) {
      _logger.w(
        'UserProvider: Cannot subscribe, user not authenticated or UUID missing',
      );
      return;
    }

    if (!_pusherService.isInitialized) {
      _logger.w(
        'UserProvider: PusherService not initialized, cannot subscribe',
      );
      return;
    }

    final channelName = 'user.profile.${_authService.currentUser!.uuid}';
    if (_userChannelName == channelName && _isSubscribed) {
      _logger.d('UserProvider: Already subscribed to channel: $channelName');
      return;
    }

    // Unsubscribe from old channel if exists
    if (_userChannelName != null &&
        _userChannelName!.isNotEmpty &&
        _isSubscribed) {
      _logger.i(
        'UserProvider: Unsubscribing from old channel: $_userChannelName',
      );
      await _pusherService.unsubscribeFromChannel(_userChannelName!);
      _userChannelName = null;
      _isSubscribed = false;
    }

    try {
      _logger.i(
        'UserProvider: Attempting to subscribe to channel: $channelName',
      );
      final success = await _pusherService.subscribeToChannel(channelName);
      if (success) {
        _userChannelName = channelName;
        _isSubscribed = true;

        // Bind to user profile updated event
        _pusherService.bindToEvent(channelName, 'user.profile.updated', (
          event,
        ) {
          try {
            _logger.i(
              'UserProvider: Received user.profile.updated event: ${event.data}',
            );
            if (event.data == null) {
              _logger.w('UserProvider: Event data is null, skipping update');
              return;
            }

            final eventData = event.data as Map<String, dynamic>;
            final updatedUser = User.fromJson(eventData['user']);

            _currentUser = updatedUser;
            _authService.saveUser(_currentUser!);
            notifyListeners();
            _logger.i(
              'UserProvider: User profile updated: ${_currentUser!.uuid}',
            );
          } catch (e) {
            _logger.e(
              'UserProvider: Error processing user.profile.updated event: $e. Data: ${event.data}',
            );
            setError(
              'UserProvider: Error processing user.profile.updated event: $e',
            );
          }
        });
        _logger.i(
          'UserProvider: Successfully subscribed to channel: $channelName',
        );
      } else {
        _logger.e(
          'UserProvider: Failed to subscribe to Pusher channel: $channelName',
        );
        setError(
          'UserProvider: Failed to subscribe to Pusher channel: $channelName',
        );
        _userChannelName = null;
        _isSubscribed = false;
      }
    } catch (e) {
      _logger.e(
        'UserProvider: Error subscribing to Pusher channel $channelName: $e',
      );
      setError(
        'UserProvider: Error subscribing to Pusher channel $channelName: $e',
      );
      _userChannelName = null;
      _isSubscribed = false;
    }
  }

  @override
  void dispose() {
    if (_userChannelName != null && _isSubscribed) {
      _logger.i(
        'UserProvider: Disposing and unsubscribing from channel: $_userChannelName',
      );
      _pusherService.unsubscribeFromChannel(_userChannelName!);
    }
    super.dispose();
  }
}
