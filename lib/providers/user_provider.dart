import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart' as dio;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/pusher_service.dart';

class UserProvider extends ChangeNotifier {
  final ApiService _apiService;
  final AuthService _authService;
  final PusherService _pusherService;

  User? _currentUser;
  User? _viewedUser;

  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _isSuccess = false;
  String? _userChannelName;

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
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  bool get isSuccess => _isSuccess;
  bool get isAuthenticated => _authService.isAuthenticated;

  void setLoading() {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    _isSuccess = false;
    notifyListeners();
  }

  void setError(String message) {
    _isLoading = false;
    _hasError = true;
    _errorMessage = message;
    _isSuccess = false;
    notifyListeners();
  }

  void setSuccess() {
    _isLoading = false;
    _hasError = false;
    _errorMessage = null;
    _isSuccess = true;
    notifyListeners();
  }

  void resetState() {
    _isLoading = false;
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
      setError(e.message);
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
      setError(e.message);
    } catch (e) {
      setError('An unexpected error occurred during registration: $e');
    }
  }

  Future<void> logout() async {
    setLoading();
    try {
      if (_userChannelName != null) {
        await _pusherService.unsubscribeFromChannel(_userChannelName!);
        _userChannelName = null;
      }
      await _authService.logout();
      _currentUser = null;
      _viewedUser = null;
      setSuccess();
      print('User logged out successfully.');
    } on AuthException catch (e) {
      setError(e.message);
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
      print('Attempted to fetch current user when not authenticated.');
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
      setError(e.message);
    } catch (e) {
      setError('An unexpected error occurred while fetching user profile: $e');
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
        print(
          'Account Type updated successfully for: ${_currentUser!.email} to role: ${_currentUser!.role}',
        );
      } else {
        final message =
            response['message'] as String? ??
            'Failed to update account type: Invalid response structure.';
        setError(message);
      }
    } on dio.DioError catch (e) {
      setError(AuthService.extractErrorMessage(e));
    } catch (e) {
      setError('Failed to update account type: $e');
    }
  }

  Future<void> updateCurrentUserProfile({
    required String about,
    required List<String> skills,
    String? educationCertification,
    String? educationGraduationDate,
    String? educationInstitution,
    String? educationCourseOfStudy,
    String? professionalCertificationName,
    String? professionalCertificationOrganization,
    String? professionalCertificationEndDate,
    XFile? professionalCertificationImage,
    XFile? meansOfIdentification,
    String? country,
    String? state,
    required Map<String, String> socialHandles,
    String? subCategoryUuid,
    XFile? profileImage,
    XFile? coverImage,
  }) async {
    if (!_authService.isAuthenticated ||
        _authService.currentUser == null ||
        _authService.currentUser!.uuid.isEmpty) {
      setError('User not authenticated for profile update.');
      return;
    }

    setLoading();

    try {
      // --- Step 1: Update Profile Data ---
      final profileFormData = dio.FormData.fromMap({
        'about': about.trim(),
        if (skills.isNotEmpty)
          for (int i = 0; i < skills.length; i++) 'skills[$i]': skills[i],
        if (educationCertification != null || educationInstitution != null) ...{
          'education[0][certification]': educationCertification ?? '',
          'education[0][institution]': educationInstitution ?? '',
          'education[0][courseOfStudy]': educationCourseOfStudy ?? '',
          'education[0][graduationDate]': educationGraduationDate ?? '',
        },
        if (meansOfIdentification != null) ...{
          'meansOfIdentification[file]':
              kIsWeb
                  ? dio.MultipartFile.fromBytes(
                    await meansOfIdentification.readAsBytes(),
                    filename: 'id_doc.png',
                  )
                  : await dio.MultipartFile.fromFile(
                    meansOfIdentification.path,
                    filename: meansOfIdentification.path.split('/').last,
                  ),
          'meansOfIdentification[fileName]':
              kIsWeb
                  ? 'id_doc.png'
                  : meansOfIdentification.path.split('/').last,
        },
        if (professionalCertificationName != null ||
            professionalCertificationOrganization != null ||
            professionalCertificationImage != null) ...{
          'professionalCertification[0][name]':
              professionalCertificationName ?? '',
          'professionalCertification[0][organization]':
              professionalCertificationOrganization?.trim() ?? '',
          'professionalCertification[0][endDate]':
              professionalCertificationEndDate?.trim() ?? '',
          if (professionalCertificationImage != null) ...{
            'professionalCertification[0][file]':
                kIsWeb
                    ? dio.MultipartFile.fromBytes(
                      await professionalCertificationImage.readAsBytes(),
                      filename: 'cert_doc.png',
                    )
                    : await dio.MultipartFile.fromFile(
                      professionalCertificationImage.path,
                      filename:
                          professionalCertificationImage.path.split('/').last,
                    ),
            'professionalCertification[0][fileName]':
                kIsWeb
                    ? 'cert_doc.png'
                    : professionalCertificationImage.path.split('/').last,
          },
        },
        'country': country?.trim() ?? '',
        'state': state?.trim() ?? '',
        'social[facebook]': socialHandles['facebook']?.trim() ?? '',
        'social[linkedIn]': socialHandles['linkedIn']?.trim() ?? '',
        'social[instagram]': socialHandles['instagram']?.trim() ?? '',
        'social[twitter]': socialHandles['twitter']?.trim() ?? '',
        if (subCategoryUuid != null) 'serviceSubCategories[0]': subCategoryUuid,
      });

      final profileResponse = await _apiService.post(
        '/user/profile/update',
        data: profileFormData,
      );

      if (profileResponse['statusCode'] != 200 ||
          !profileResponse.containsKey('data')) {
        final message =
            profileResponse['message'] as String? ??
            'Failed to update profile data: Invalid response structure.';
        setError(message);
        return;
      }

      // --- Step 2: Update Profile and Cover Images ---
      if (profileImage != null || coverImage != null) {
        final imageFormData = dio.FormData.fromMap({
          if (profileImage != null) ...{
            'profileImage[file]':
                kIsWeb
                    ? dio.MultipartFile.fromBytes(
                      await profileImage.readAsBytes(),
                      filename: 'jondoe_dp.png',
                    )
                    : await dio.MultipartFile.fromFile(
                      profileImage.path,
                      filename: 'jondoe_dp.png',
                    ),
            'profileImage[fileName]': 'jondoe_dp.png',
          },
          if (coverImage != null) ...{
            'coverImage[file]':
                kIsWeb
                    ? dio.MultipartFile.fromBytes(
                      await coverImage.readAsBytes(),
                      filename: 'cover_image.png',
                    )
                    : await dio.MultipartFile.fromFile(
                      coverImage.path,
                      filename: 'cover_image.png',
                    ),
            'coverImage[fileName]': 'cover_image.png',
          },
        });

        final imageResponse = await _apiService.post(
          '/user/profile/image/update',
          data: imageFormData,
        );

        if (imageResponse['statusCode'] != 200 ||
            !imageResponse.containsKey('data')) {
          final message =
              imageResponse['message'] as String? ??
              'Failed to update images: Invalid response structure.';
          setError(message);
          return;
        }
      }

      // Update local user data
      _currentUser = await _authService.getCurrentUserProfile();
      if (_currentUser != null) {
        await _authService.saveUser(_currentUser!);
        setSuccess();
        print('User profile updated successfully for: ${_currentUser!.email}');
      } else {
        setError('Failed to fetch updated user profile after update.');
      }
    } on dio.DioError catch (e) {
      setError(AuthService.extractErrorMessage(e));
    } catch (e) {
      setError('Failed to update profile: $e');
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
    } on dio.DioError catch (e) {
      setError(AuthService.extractErrorMessage(e));
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
      print(
        'Cannot subscribe to user channel: user not authenticated or UUID missing.',
      );
      return;
    }

    final channelName = 'user.profile.${_authService.currentUser!.uuid}';
    if (_userChannelName == channelName) {
      return;
    }

    if (_userChannelName != null && _userChannelName!.isNotEmpty) {
      await _pusherService.unsubscribeFromChannel(_userChannelName!);
      print('Unsubscribed from old Pusher channel: $_userChannelName');
      _userChannelName = null;
    }

    try {
      final channel = await _pusherService.subscribeToChannel(channelName);
      if (channel != null) {
        _userChannelName = channelName;
        print('Subscribed to Pusher channel: $channelName');

        _pusherService.bindToEvent(channelName, 'user.profile.updated', (
          eventDataString,
        ) {
          try {
            final Map<String, dynamic> eventData =
                jsonDecode(eventDataString) as Map<String, dynamic>;
            _currentUser =
                _currentUser?.copyWith(
                  firstName: eventData['firstName'] as String?,
                  lastName: eventData['lastName'] as String?,
                  email: eventData['email'] as String?,
                  phoneNumber: eventData['phoneNumber'] as String?,
                  role: eventData['role'] as String?,
                  profileImage: eventData['profileImage'] as String?,
                  coverImage: eventData['coverImage'] as String?,
                  profileCompletionRate:
                      eventData['profileCompletionRate'] as int?,
                  additionalInfo:
                      eventData['additionalInfo'] != null &&
                              eventData['additionalInfo'] is Map
                          ? AdditionalInfo.fromJson(eventData['additionalInfo'])
                          : _currentUser?.additionalInfo,
                ) ??
                User.fromJson(eventData);

            _authService.saveUser(_currentUser!);
            notifyListeners();
            print('User profile updated via Pusher: ${_currentUser!.email}');
          } catch (e) {
            print(
              'Error processing user.profile.updated event: $e. Data: $eventDataString',
            );
          }
        });
      } else {
        print(
          'Failed to subscribe to Pusher channel: $channelName. Channel is null.',
        );
        _userChannelName = null;
      }
    } catch (e) {
      print('Error subscribing or binding to Pusher channel $channelName: $e');
      _userChannelName = null;
    }
  }

  @override
  void dispose() {
    if (_userChannelName != null) {
      _pusherService.unsubscribeFromChannel(_userChannelName!);
    }
    super.dispose();
  }
}
