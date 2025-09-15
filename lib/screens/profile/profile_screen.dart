import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wawu_mobile/models/user.dart';
import 'package:wawu_mobile/providers/category_provider.dart';
import 'package:wawu_mobile/providers/dropdown_data_provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/providers/skill_provider.dart';
import 'package:wawu_mobile/screens/profile/change_password_screen/change_password_screen.dart';
import 'package:wawu_mobile/services/api_service.dart';
import 'package:wawu_mobile/services/auth_service.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/utils/helpers/cache_manager.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:wawu_mobile/widgets/custom_dropdown/custom_dropdown.dart';
import 'package:wawu_mobile/widgets/custom_intro_text/custom_intro_text.dart';
import 'package:wawu_mobile/widgets/custom_textfield/custom_textfield.dart';
import 'package:wawu_mobile/widgets/upload_image/upload_image.dart';
import 'package:wawu_mobile/models/country.dart';
import 'package:wawu_mobile/providers/location_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wawu_mobile/widgets/custom_snackbar.dart'; // Import CustomSnackBar
import 'package:wawu_mobile/widgets/full_ui_error_display.dart'; // Import FullErrorDisplay

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _skillController = TextEditingController();
  List<String> _skills = [];
  final int _maxAboutLength = 200;

  String? _selectedSkill;
  String? _selectedCertification;
  String? _selectedInstitution;
  final TextEditingController _educationCourseOfStudyController =
      TextEditingController();
  final TextEditingController _educationGraduationDateController =
      TextEditingController();
  final TextEditingController _customInstitutionController =
      TextEditingController(); // For 'School-Level Qualifications'
  final TextEditingController _professionalCertificationNameController =
      TextEditingController();
  final TextEditingController _professionalCertificationOrganizationController =
      TextEditingController();
  final TextEditingController _educationEndDateController =
      TextEditingController();

  XFile? _profileImage;
  XFile? _coverImage;
  XFile? _professionalCertificationImage;
  XFile? _meansOfIdentificationImage;

  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _linkedInController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _twitterController = TextEditingController();

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  Country? _selectedCountry;
  String? _selectedState;

  bool _isDirty = false;
  bool _isLoading = true;

  late final ApiService apiService;
  late final AuthService authService;

  // Flags to prevent showing multiple snackbars for the same error
  bool _hasShownUserError = false;
  bool _hasShownDropdownError = false;
  bool _hasShownSkillError = false;
  bool _hasShownLocationError = false;

  @override
  void initState() {
    super.initState();
    apiService = Provider.of<ApiService>(context, listen: false);
    authService = AuthService(apiService: apiService);
    _addListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  // Call this method whenever the widget is rebuilt with new data (e.g., after a profile update)
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This ensures that if the user data changes (e.g., from a Pusher event or successful update),
    // the UI elements are re-initialized with the latest data.
    _initializeControllersFromUser();
  }

  void _initializeControllersFromUser() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    if (user != null) {
      _aboutController.text = user.additionalInfo?.about ?? '';
      _skills = user.additionalInfo?.skills ?? [];

      // Education
      if (user.additionalInfo?.education != null &&
          user.additionalInfo!.education!.isNotEmpty) {
        final latestEducation = user.additionalInfo!.education!.last;
        _selectedCertification = latestEducation.certification;
        _educationCourseOfStudyController.text =
            latestEducation.courseOfStudy ?? '';
        _educationGraduationDateController.text =
            latestEducation.startDate ?? '';
        _educationEndDateController.text = latestEducation.endDate ?? '';

        if (latestEducation.certification == 'School-Level Qualifications') {
          _customInstitutionController.text = latestEducation.institution ?? '';
          _selectedInstitution = null; // Ensure dropdown is not selected
        } else {
          _selectedInstitution = latestEducation.institution;
          _customInstitutionController.clear(); // Ensure custom field is clear
        }
      } else {
        _selectedCertification = null;
        _selectedInstitution = null;
        _educationCourseOfStudyController.clear();
        _educationGraduationDateController.clear();
        _educationEndDateController.clear();
        _customInstitutionController.clear();
      }

      // Professional Certification
      if (user.additionalInfo?.professionalCertification != null &&
          user.additionalInfo!.professionalCertification!.isNotEmpty) {
        final latestProfCert =
            user.additionalInfo!.professionalCertification!.last;
        _professionalCertificationNameController.text =
            latestProfCert.name ?? '';
        _professionalCertificationOrganizationController.text =
            latestProfCert.organization ?? '';
      } else {
        _professionalCertificationNameController.clear();
        _professionalCertificationOrganizationController.clear();
      }

      // Location
      if (user.country != null && locationProvider.countries.isNotEmpty) {
        _selectedCountry = locationProvider.countries.firstWhere(
          (c) => c.name.toLowerCase() == user.country!.toLowerCase(),
          orElse: () => Country(id: 0, name: user.country!, flag: ''),
        );
        if (_selectedCountry != null && _selectedCountry!.id != 0) {
          // Fetch states and set the user's state
          locationProvider.fetchStates(_selectedCountry!.id).then((_) {
            if (mounted) {
              setState(() {
                _selectedState = user.state;
              });
            }
          });
        }
      } else {
        _selectedCountry = null;
        _selectedState = null;
      }

      // Social Handles
      _facebookController.text =
          user.additionalInfo?.socialHandles?['facebook']?.split('/').last ??
          '';
      _linkedInController.text =
          user.additionalInfo?.socialHandles?['linkedIn']?.split('/').last ??
          '';
      _instagramController.text =
          user.additionalInfo?.socialHandles?['instagram']
              ?.replaceAll('https://www.instagram.com/', '')
              .replaceAll('/', '') ??
          '';
      _twitterController.text =
          user.additionalInfo?.socialHandles?['twitter']?.split('/').last ?? '';

      // Phone and Email
      _phoneController.text = user.phoneNumber ?? '';
      _emailController.text = user.email ?? '';
    }
  }

  Future<void> _loadInitialData() async {
    final dropdownProvider = Provider.of<DropdownDataProvider>(
      context,
      listen: false,
    );
    final skillProvider = Provider.of<SkillProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        dropdownProvider.fetchDropdownData().catchError((e) {
          CustomSnackBar.show(
            context,
            message: 'Failed to load dropdown data: $e',
            isError: true,
          );
          dropdownProvider.clearError();
        }),
        skillProvider.fetchSkills().catchError((e) {
          CustomSnackBar.show(
            context,
            message: 'Failed to load skills: $e',
            isError: true,
          );
          skillProvider.clearError();
        }),
        locationProvider.fetchCountries().catchError((e) {
          CustomSnackBar.show(
            context,
            message: 'Failed to load countries: $e',
            isError: true,
          );
          locationProvider.clearError();
        }),
        userProvider.fetchCurrentUser().catchError((e) {
          CustomSnackBar.show(
            context,
            message: 'Failed to load user profile: $e',
            isError: true,
          );
          userProvider.resetState();
        }),
      ]);
    } catch (e) {
      // Catch-all for any unhandled errors during Future.wait
      CustomSnackBar.show(
        context,
        message: 'An unexpected error occurred during initial data load: $e',
        isError: true,
      );
    }

    _initializeControllersFromUser(); // Initialize controllers after data is fetched

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addListeners() {
    final controllers = [
      _aboutController,
      _skillController,
      _educationCourseOfStudyController,
      _educationGraduationDateController,
      _professionalCertificationNameController,
      _professionalCertificationOrganizationController,
      _educationEndDateController,
      _customInstitutionController,
      _facebookController,
      _linkedInController,
      _instagramController,
      _twitterController,
      _phoneController,
      _emailController,
    ];
    for (var controller in controllers) {
      controller.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() {
    if (!_isDirty) {
      setState(() {
        _isDirty = true;
      });
    }
  }

  Future<void> _pickImageForProfileAndCover(String imageType) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        if (imageType == 'profile') {
          _profileImage = pickedFile;
        } else if (imageType == 'cover') {
          _coverImage = pickedFile;
        }
        _isDirty = true;
      });
    } else {
      CustomSnackBar.show(
        context,
        message: 'No image selected.',
        isError: false, // Informative, not an error
      );
    }
  }

  void _addSkill() {
    String skillToAdd = '';

    if (_selectedSkill != null && _selectedSkill!.isNotEmpty) {
      skillToAdd = _selectedSkill!;
    } else if (_skillController.text.trim().isNotEmpty) {
      skillToAdd = _skillController.text.trim();
    }

    if (skillToAdd.isNotEmpty && !_skills.contains(skillToAdd)) {
      setState(() {
        _skills.add(skillToAdd);
        _skillController.clear();
        _selectedSkill = null;
        _isDirty = true;
      });
    } else if (skillToAdd.isEmpty) {
      CustomSnackBar.show(
        context,
        message: 'Please select or enter a skill to add.',
        isError: true,
      );
    } else if (_skills.contains(skillToAdd)) {
      CustomSnackBar.show(
        context,
        message: 'Skill "$skillToAdd" is already added.',
        isError: false, // Not an error, but informative
      );
    }
  }

  Future<void> _selectGraduationDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      setState(() {
        controller.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        _isDirty = true;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      CustomSnackBar.show(
        context,
        message: 'Please fill all required fields correctly.',
        isError: true,
      );
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );

    Map<String, dynamic> payload = {};

    // Basic Info
    if (_aboutController.text.isNotEmpty) {
      payload['about'] = _aboutController.text;
    }
    if (_skills.isNotEmpty) payload['skills'] = _skills;
    if (_phoneController.text.isNotEmpty) {
      payload['phoneNumber'] = _phoneController.text;
    }

    // Education
    // Only add education fields if at least one of them is provided
    if (_selectedCertification != null ||
        _selectedInstitution != null ||
        _customInstitutionController.text.isNotEmpty ||
        _educationCourseOfStudyController.text.isNotEmpty ||
        _educationGraduationDateController.text.isNotEmpty ||
        _educationEndDateController.text.isNotEmpty) {
      payload['educationCertification'] = _selectedCertification;
      if (_selectedCertification == 'School-Level Qualifications') {
        payload['educationInstitution'] = _customInstitutionController.text;
      } else {
        payload['educationInstitution'] = _selectedInstitution;
      }
      payload['educationCourseOfStudy'] =
          _educationCourseOfStudyController.text;
      payload['educationGraduationDate'] =
          _educationGraduationDateController.text;
      payload['educationEndDate'] = _educationEndDateController.text;
    }

    // Professional Certification
    // Only add professional certification fields if at least one of them is provided
    if (_professionalCertificationNameController.text.isNotEmpty ||
        _professionalCertificationOrganizationController.text.isNotEmpty ||
        _professionalCertificationImage != null) {
      payload['professionalCertificationName'] =
          _professionalCertificationNameController.text;
      payload['professionalCertificationOrganization'] =
          _professionalCertificationOrganizationController.text;
    }

    // Location
    if (_selectedCountry != null) {
      payload['country'] = _selectedCountry!.name;
    }
    if (_selectedState != null) {
      payload['state'] = _selectedState;
    }

    // Social Handles
    Map<String, String> socialHandles = {};
    if (_facebookController.text.isNotEmpty) {
      socialHandles['facebook'] =
          'https://www.facebook.com/${_facebookController.text.trim()}';
    }
    if (_linkedInController.text.isNotEmpty) {
      socialHandles['linkedIn'] =
          'https://www.linkedin.com/in/${_linkedInController.text.trim()}';
    }
    if (_instagramController.text.isNotEmpty) {
      socialHandles['instagram'] =
          'https://www.instagram.com/${_instagramController.text.trim()}';
    }
    if (_twitterController.text.isNotEmpty) {
      socialHandles['twitter'] =
          'https://twitter.com/${_twitterController.text.trim()}';
    }
    if (socialHandles.isNotEmpty) payload['socialHandles'] = socialHandles;

    // Subcategory
    if (categoryProvider.selectedSubCategory?.uuid != null) {
      payload['subCategoryUuid'] = categoryProvider.selectedSubCategory!.uuid;
    }

    try {
      await userProvider.updateCurrentUserProfile(
        data: payload,
        profileImage: _profileImage,
        coverImage: _coverImage,
        professionalCertificationImage: _professionalCertificationImage,
        meansOfIdentification: _meansOfIdentificationImage,
      );

      if (userProvider.isSuccess) {
        if (mounted) {
          CustomSnackBar.show(
            context,
            message: 'Profile updated successfully!',
            isError: false,
          );
          // Clear file selections after successful upload
          setState(() {
            _profileImage = null;
            _coverImage = null;
            _professionalCertificationImage = null;
            _meansOfIdentificationImage = null;
          });
          // Re-load initial data to refresh UI and state
          await _loadInitialData();
        }
      } else {
        if (mounted) {
          CustomSnackBar.show(
            context,
            message: userProvider.errorMessage ?? 'Failed to update profile',
            isError: true,
          );
          userProvider.resetState(); // Clear error state
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Error updating profile: $e',
          isError: true,
        );
        userProvider.resetState(); // Clear error state
      }
    }
  }

  @override
  void dispose() {
    _aboutController.dispose();
    _skillController.dispose();
    _educationCourseOfStudyController.dispose();
    _educationGraduationDateController.dispose();
    _professionalCertificationOrganizationController.dispose();
    _educationEndDateController.dispose();
    _customInstitutionController.dispose();
    _professionalCertificationNameController.dispose();
    _facebookController.dispose();
    _linkedInController.dispose();
    _instagramController.dispose();
    _twitterController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Function to show the support dialog (can be reused)
  void _showErrorSupportDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: const Text(
            'Contact Support',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: wawuColors.primary,
            ),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700]),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'OK',
                style: TextStyle(color: wawuColors.buttonSecondary),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildEducationCard(Education education) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 10), // Add margin for spacing
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [wawuColors.primary, Color(0xFF9333EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  education.certification ?? 'N/A',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  education.institution ?? 'N/A',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  education.courseOfStudy ?? 'N/A',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${education.startDate ?? 'N/A'} - ${education.endDate ?? 'N/A'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50), // Adjusted alpha
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationCard(ProfessionalCertification cert) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 10), // Add margin for spacing
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [wawuColors.primary, Color(0xFF9333EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cert.name ?? 'N/A',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  cert.organization ?? 'N/A',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                if (cert.file?.link != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse(cert.file!.link!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        CustomSnackBar.show(
                          context,
                          message: 'Could not open document link.',
                          isError: true,
                        );
                      }
                    },
                    child: Text(
                      'Document: ${cert.file!.name ?? 'View Document'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50), // Adjusted alpha
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile'), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Consumer5<
      CategoryProvider,
      UserProvider,
      DropdownDataProvider,
      SkillProvider,
      LocationProvider
    >(
      builder: (
        context,
        categoryProvider,
        userProvider,
        dropdownProvider,
        skillProvider,
        locationProvider,
        child,
      ) {
        // Listen for errors from UserProvider and display SnackBar
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (userProvider.hasError &&
              userProvider.errorMessage != null &&
              !_hasShownUserError) {
            CustomSnackBar.show(
              context,
              message: userProvider.errorMessage!,
              isError: true,
              actionLabel: 'RETRY',
              onActionPressed: () {
                userProvider.fetchCurrentUser();
              },
            );
            _hasShownUserError = true;
            userProvider.resetState(); // Clear error state
          } else if (!userProvider.hasError && _hasShownUserError) {
            _hasShownUserError = false;
          }
        });

        // Listen for errors from DropdownDataProvider and display SnackBar
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (dropdownProvider.hasError &&
              dropdownProvider.errorMessage != null &&
              !_hasShownDropdownError) {
            CustomSnackBar.show(
              context,
              message: dropdownProvider.errorMessage!,
              isError: true,
              actionLabel: 'RETRY',
              onActionPressed: () {
                dropdownProvider.fetchDropdownData();
              },
            );
            _hasShownDropdownError = true;
            dropdownProvider.clearError(); // Clear error state
          } else if (!dropdownProvider.hasError && _hasShownDropdownError) {
            _hasShownDropdownError = false;
          }
        });

        // Listen for errors from SkillProvider and display SnackBar
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (skillProvider.hasError &&
              skillProvider.errorMessage != null &&
              !_hasShownSkillError) {
            CustomSnackBar.show(
              context,
              message: skillProvider.errorMessage!,
              isError: true,
              actionLabel: 'RETRY',
              onActionPressed: () {
                skillProvider.fetchSkills();
              },
            );
            _hasShownSkillError = true;
            skillProvider.clearError(); // Clear error state
          } else if (!skillProvider.hasError && _hasShownSkillError) {
            _hasShownSkillError = false;
          }
        });

        // Listen for errors from LocationProvider and display SnackBar
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (locationProvider.hasError &&
              locationProvider.errorMessage != null &&
              !_hasShownLocationError) {
            CustomSnackBar.show(
              context,
              message: locationProvider.errorMessage!,
              isError: true,
              actionLabel: 'RETRY',
              onActionPressed: () {
                locationProvider.fetchCountries();
              },
            );
            _hasShownLocationError = true;
            locationProvider.clearError(); // Clear error state
          } else if (!locationProvider.hasError && _hasShownLocationError) {
            _hasShownLocationError = false;
          }
        });

        final user = userProvider.currentUser;
        final fullName =
            '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim();

        // Determine if education inputs should be hidden (assuming one-time update for primary education)
        final hasEducation =
            user?.additionalInfo?.education != null &&
            user!.additionalInfo!.education!.isNotEmpty;

        // Determine if professional cert inputs should be hidden (assuming one-time update)
        final hasProfessionalCertification =
            user?.additionalInfo?.professionalCertification != null &&
            user!.additionalInfo!.professionalCertification!.isNotEmpty;

        // Determine if means of ID inputs should be hidden (assuming one-time update)
        final hasMeansOfIdentification =
            user?.additionalInfo?.meansOfIdentification?.file?.link != null;

        return Scaffold(
          appBar: AppBar(title: const Text('Profile'), centerTitle: true),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 160,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 100,
                        child: Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 100,
                              color: wawuColors.primary.withAlpha(50),
                              child:
                                  _coverImage != null
                                      ? Image.file(
                                        File(_coverImage!.path),
                                        key: ValueKey(_coverImage!.path),
                                        fit: BoxFit.cover,
                                      )
                                      : (user?.coverImage != null
                                          ? CachedNetworkImage(
                                            cacheManager:
                                                CustomCacheManager.instance,

                                            imageUrl: user!.coverImage!,
                                            fit: BoxFit.cover,
                                            placeholder:
                                                (context, url) => Container(
                                                  color: Colors.grey[200],
                                                  child: const Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ),
                                                ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Center(
                                                      child: Text(
                                                        'Add Cover Photo',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ),
                                          )
                                          : const Center(
                                            child: Text(
                                              'Add Cover Photo',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          )),
                            ),
                            Positioned(
                              right: 10,
                              bottom: -10,
                              child: GestureDetector(
                                onTap:
                                    () => _pickImageForProfileAndCover('cover'),
                                child: ClipOval(
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    color: const Color.fromARGB(
                                      255,
                                      219,
                                      219,
                                      219,
                                    ),
                                    child: Icon(
                                      Icons.camera_alt,
                                      size: 13,
                                      color: wawuColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 50,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: SizedBox(
                            width: 104,
                            height: 104,
                            child: Stack(
                              children: [
                                ClipOval(
                                  child: Container(
                                    padding: const EdgeInsets.all(2.0),
                                    color: wawuColors.white,
                                    child: ClipOval(
                                      child: Container(
                                        width: 100,
                                        height: 100,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                        ),
                                        child:
                                            _profileImage != null
                                                ? Image.file(
                                                  File(_profileImage!.path),
                                                  key: ValueKey(
                                                    _profileImage!.path,
                                                  ),
                                                  fit: BoxFit.cover,
                                                )
                                                : (user?.profileImage != null
                                                    ? CachedNetworkImage(
                                                      cacheManager:
                                                          CustomCacheManager
                                                              .instance,

                                                      imageUrl:
                                                          user!.profileImage!,
                                                      fit: BoxFit.cover,
                                                      placeholder:
                                                          (
                                                            context,
                                                            url,
                                                          ) => Container(
                                                            color:
                                                                Colors
                                                                    .grey[200],
                                                            child: const Center(
                                                              child:
                                                                  CircularProgressIndicator(),
                                                            ),
                                                          ),
                                                      errorWidget:
                                                          (
                                                            context,
                                                            url,
                                                            error,
                                                          ) => Image.asset(
                                                            'assets/images/other/avatar.webp',
                                                            cacheWidth: 200,
                                                          ),
                                                    )
                                                    : Image.asset(
                                                      'assets/images/other/avatar.webp',
                                                      cacheWidth: 200,
                                                    )),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 4,
                                  bottom: 4,
                                  child: GestureDetector(
                                    onTap:
                                        () => _pickImageForProfileAndCover(
                                          'profile',
                                        ),
                                    child: ClipOval(
                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        color: const Color.fromARGB(
                                          255,
                                          219,
                                          219,
                                          219,
                                        ),
                                        child: Icon(
                                          Icons.camera_alt,
                                          size: 13,
                                          color: wawuColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    user?.role ?? 'Role',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color.fromARGB(255, 125, 125, 125),
                      fontWeight: FontWeight.w200,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (user?.status == 'VERIFIED')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: wawuColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Verified',
                        style: TextStyle(
                          fontSize: 14,
                          color: wawuColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                if (user?.status != 'VERIFIED')
                  Wrap(
                    spacing: 5,
                    alignment: WrapAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 15,
                        color: wawuColors.primary,
                      ),
                      const Text(
                        'Not Verified',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color.fromARGB(255, 125, 125, 125),
                          fontWeight: FontWeight.w200,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final rating =
                        user?.profileCompletionRate != null
                            ? (user!.profileCompletionRate! / 20).floor()
                            : 4;
                    return Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: wawuColors.primary,
                      size: 20,
                    );
                  }),
                ),
                const SizedBox(height: 20),
                const CustomIntroText(text: 'Credentials'),
                const SizedBox(height: 10),
                CustomTextfield(
                  controller: _phoneController,
                  labelText: 'Phone Number',
                  hintText: 'Phone Number',
                  labelTextStyle2: true,
                  // Removed readOnly to allow updates
                ),
                const SizedBox(height: 10),
                CustomTextfield(
                  controller: _emailController,
                  labelText: 'Email',
                  hintText: 'Email',
                  labelTextStyle2: true,
                  readOnly: true,
                ),
                const SizedBox(height: 10),
                CustomButton(
                  function: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                ChangePasswordScreen(authService: authService),
                      ),
                    );
                  },
                  widget: const Text(
                    'Change Password',
                    style: TextStyle(color: Colors.white),
                  ),
                  color: wawuColors.primary,
                ),
                const SizedBox(height: 20),
                if (user?.role != 'BUYER') ...[
                  const CustomIntroText(text: 'About'),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _aboutController,
                    maxLength: _maxAboutLength,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Tell us about yourself...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const CustomIntroText(text: 'Skills'),
                  const SizedBox(height: 10),
                  // Skill dropdown and loading/error handling
                  if (skillProvider.isLoading && skillProvider.skills.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else if (skillProvider.hasError &&
                      skillProvider.skills.isEmpty &&
                      !skillProvider.isLoading)
                    FullErrorDisplay(
                      errorMessage:
                          skillProvider.errorMessage ??
                          'Failed to load skills. Please try again.',
                      onRetry: () {
                        skillProvider.fetchSkills();
                      },
                      onContactSupport: () {
                        _showErrorSupportDialog(
                          context,
                          'If this problem persists, please contact our support team. We are here to help!',
                        );
                      },
                    )
                  else ...[
                    CustomDropdown(
                      options:
                          skillProvider.skills
                              .map((skill) => skill.name)
                              .toList(),
                      label: 'Select Skill',
                      selectedValue: _selectedSkill,
                      onChanged: (value) {
                        setState(() {
                          _selectedSkill = value;
                          _skillController.clear();
                          _isDirty = true;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: _addSkill,
                      child: CustomButton(
                        widget: const Text(
                          'Add Skill',
                          style: TextStyle(color: Colors.white),
                        ),
                        color: wawuColors.buttonPrimary,
                        textColor: Colors.white,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children:
                        _skills.map((skill) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: wawuColors.primary.withAlpha(
                                50,
                              ), // Adjusted alpha
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  skill,
                                  style: TextStyle(
                                    fontSize: 12,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _skills.remove(skill);
                                      _isDirty = true;
                                    });
                                  },
                                  child: const Icon(Icons.close, size: 16),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 30),
                  const CustomIntroText(text: 'Education'),
                  const SizedBox(height: 12),
                  // Display existing education cards
                  if (user?.additionalInfo?.education != null)
                    for (Education edu in user!.additionalInfo!.education!)
                      _buildEducationCard(edu),
                  if (user?.additionalInfo?.education == null ||
                      user!.additionalInfo!.education!.isEmpty)
                    // Education Input Fields (conditionally hidden after first entry)
                    if (!hasEducation)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 25),
                          const Text(
                            'Certificate',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CustomDropdown(
                            options:
                                dropdownProvider.certifications
                                    .map((e) => e.name)
                                    .toList(),
                            label: 'Select Certificate',
                            selectedValue: _selectedCertification,
                            onChanged: (value) {
                              setState(() {
                                _isDirty = true;
                                _selectedCertification = value;
                                if (value == 'School-Level Qualifications') {
                                  _selectedInstitution = null;
                                } else {
                                  _customInstitutionController.clear();
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          if (_selectedCertification ==
                              'School-Level Qualifications')
                            CustomTextfield(
                              controller: _customInstitutionController,
                              hintText: 'Enter your institution',
                              labelText: 'Institution',
                              labelTextStyle2: true,
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Institution',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                CustomDropdown(
                                  options:
                                      dropdownProvider.institutions
                                          .map((e) => e.name)
                                          .toList(),
                                  label: 'Select Institution',
                                  selectedValue: _selectedInstitution,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedInstitution = value;
                                      _isDirty = true;
                                    });
                                  },
                                ),
                              ],
                            ),
                          const SizedBox(height: 10),
                          CustomTextfield(
                            controller: _educationCourseOfStudyController,
                            hintText: 'Enter your course of study',
                            labelText: 'Course of Study',
                            labelTextStyle2: true,
                          ),
                          const SizedBox(height: 10),
                          CustomTextfield(
                            controller: _educationGraduationDateController,
                            hintText: 'YYYY-MM-DD',
                            labelText: 'Start Date',
                            labelTextStyle2: true,
                            suffixIcon: Icons.calendar_today,
                            readOnly: true,
                            onTap:
                                () => _selectGraduationDate(
                                  _educationGraduationDateController,
                                ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Start Date is required';
                              }
                              return null;
                            },
                          ),
                          CustomTextfield(
                            controller: _educationEndDateController,
                            hintText: 'YYYY-MM-DD',
                            labelText: 'End Date',
                            labelTextStyle2: true,
                            suffixIcon: Icons.calendar_today,
                            readOnly: true,
                            onTap:
                                () => _selectGraduationDate(
                                  _educationEndDateController,
                                ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'End Date is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                  const SizedBox(height: 30),
                  const CustomIntroText(text: 'Professional Certification'),
                  const SizedBox(height: 10),
                  // Display existing professional certification cards
                  if (user?.additionalInfo?.professionalCertification != null)
                    for (ProfessionalCertification cert
                        in user!.additionalInfo!.professionalCertification!)
                      _buildCertificationCard(cert),
                  if (user?.additionalInfo?.professionalCertification == null ||
                      user!.additionalInfo!.professionalCertification!.isEmpty)
                    // Professional Certification Input Fields (conditionally hidden after first entry)
                    if (!hasProfessionalCertification)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 25),
                          CustomTextfield(
                            controller:
                                _professionalCertificationNameController,
                            hintText:
                                'Enter Certificate Name (e.g., CAC, Skill Certificate)',
                            labelText: 'Name',
                            labelTextStyle2: true,
                          ),
                          const SizedBox(height: 20),
                          CustomTextfield(
                            controller:
                                _professionalCertificationOrganizationController,
                            hintText: 'Your Registered Company Name',
                            labelText: 'Organization',
                            labelTextStyle2: true,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Upload Certification Document',
                            style: TextStyle(
                              color: Color.fromARGB(255, 125, 125, 125),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 20),
                          UploadImage(
                            labelText: 'Upload Certification Document',
                            onImageChanged: (xfile) {
                              setState(() {
                                _professionalCertificationImage = xfile;
                                _isDirty = true;
                              });
                            },
                          ),
                        ],
                      ),
                ],
                const SizedBox(height: 40),
                const CustomIntroText(text: 'Means Of Identification'),
                const SizedBox(height: 20),
                // Display existing means of identification
                if (hasMeansOfIdentification)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: CachedNetworkImage(
                      imageUrl:
                          user!
                              .additionalInfo!
                              .meansOfIdentification!
                              .file!
                              .link!,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => const Center(
                            child: Icon(Icons.error, color: Colors.red),
                          ),
                    ),
                  )
                else // Conditionally show upload image if no ID is present
                  UploadImage(
                    labelText: 'Upload Means of ID',
                    onImageChanged: (xfile) {
                      setState(() {
                        _meansOfIdentificationImage = xfile;
                        _isDirty = true;
                      });
                    },
                  ),
                const SizedBox(height: 8),
                const Text(
                  'Acceptable proof of address documents',
                  style: TextStyle(
                    color: Color.fromARGB(255, 125, 125, 125),
                    fontSize: 13,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 25),
                    const Text(
                      'Country',
                      style: TextStyle(fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 5),
                    Consumer<LocationProvider>(
                      builder: (context, locationProvider, child) {
                        // Display full error screen if country loading failed critically
                        if (locationProvider.hasError &&
                            locationProvider.countries.isEmpty &&
                            !locationProvider.isLoading) {
                          return FullErrorDisplay(
                            errorMessage:
                                locationProvider.errorMessage ??
                                'Failed to load countries. Please try again.',
                            onRetry: () {
                              locationProvider.fetchCountries();
                            },
                            onContactSupport: () {
                              _showErrorSupportDialog(
                                context,
                                'If this problem persists, please contact our support team. We are here to help!',
                              );
                            },
                          );
                        }

                        if (locationProvider.isLoading &&
                            locationProvider.countries.isEmpty) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        return CustomDropdown<Country>(
                          options: locationProvider.countries,
                          label: 'Select Country',
                          selectedValue: _selectedCountry,
                          // Allow changing country even if one is set
                          onChanged: (value) {
                            setState(() {
                              _selectedCountry = value;
                              _selectedState =
                                  null; // Reset state when country changes
                              final countries = locationProvider.countries;
                              final selected = countries.firstWhere(
                                (c) => c.name == value?.name,
                                orElse:
                                    () =>
                                        countries.isNotEmpty
                                            ? countries.first
                                            : Country(id: 0, name: ''),
                              );
                              if (selected.id != 0) {
                                locationProvider.fetchStates(selected.id);
                              }
                              _isDirty = true;
                            });
                          },
                          itemBuilder:
                              (context, country, isSelected) => Row(
                                children: [
                                  if (country.flag != null &&
                                      country.flag!.isNotEmpty)
                                    SvgPicture.network(
                                      country.flag!,
                                      width: 24,
                                      height: 24,
                                      placeholderBuilder:
                                          (_) => const SizedBox(
                                            width: 24,
                                            height: 24,
                                          ),
                                    ),
                                  const SizedBox(width: 8),
                                  Text(country.name),
                                ],
                              ),
                          getLabel: (country) => country.name,
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'State/Province',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Consumer<LocationProvider>(
                      builder: (context, locationProvider, _) {
                        // Display full error screen if state loading failed critically
                        if (locationProvider.hasError &&
                            locationProvider.states.isEmpty &&
                            !locationProvider.isLoading) {
                          return FullErrorDisplay(
                            errorMessage:
                                locationProvider.errorMessage ??
                                'Failed to load states. Please try again.',
                            onRetry: () {
                              if (_selectedCountry != null) {
                                locationProvider.fetchStates(
                                  _selectedCountry!.id,
                                );
                              } else {
                                CustomSnackBar.show(
                                  context,
                                  message:
                                      'Please select a country first to load states.',
                                  isError: true,
                                );
                              }
                            },
                            onContactSupport: () {
                              _showErrorSupportDialog(
                                context,
                                'If this problem persists, please contact our support team. We are here to help!',
                              );
                            },
                          );
                        }

                        // Ensure options are not null and handle loading/error states
                        final List<String> stateOptions =
                            locationProvider.states.map((s) => s.name).toList();

                        if (_selectedCountry == null ||
                            locationProvider.countries.isEmpty) {
                          return AbsorbPointer(
                            // Make it un-interactable if no country selected
                            child: CustomDropdown(
                              label: 'Select your state',
                              options:
                                  const [], // Empty options if no country selected
                              selectedValue: null,
                              onChanged: (_) {},
                              isDisabled: false,
                            ),
                          );
                        }
                        if (locationProvider.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        return CustomDropdown(
                          label: 'Select your state',
                          options: stateOptions,
                          selectedValue: _selectedState,
                          onChanged: (value) {
                            setState(() {
                              _selectedState = value;
                              _isDirty = true;
                            });
                          },
                          // Allow changing state even if one is set
                          isDisabled: false,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                if (user?.role != 'BUYER') ...[
                  const CustomIntroText(text: 'Social Handles'),
                  const SizedBox(height: 20),
                  CustomTextfield(
                    controller: _facebookController,
                    hintText: '@wawu.africa',
                    labelText: 'Facebook',
                    labelTextStyle2: true,
                    suffixIcon: FontAwesomeIcons.facebook,
                  ),
                  const SizedBox(height: 20),
                  CustomTextfield(
                    controller: _linkedInController,
                    hintText: '@wawu.africa',
                    labelText: 'LinkedIn',
                    labelTextStyle2: true,
                    suffixIcon: FontAwesomeIcons.linkedin,
                  ),
                  const SizedBox(height: 20),
                  CustomTextfield(
                    controller: _instagramController,
                    hintText: '@wawu.africa',
                    labelText: 'Instagram',
                    labelTextStyle2: true,
                    suffixIcon: FontAwesomeIcons.instagram,
                  ),
                  const SizedBox(height: 20),
                  CustomTextfield(
                    controller: _twitterController,
                    hintText: '@wawu.africa',
                    labelText: 'Twitter',
                    labelTextStyle2: true,
                    suffixIcon: FontAwesomeIcons.xTwitter,
                  ),
                  const SizedBox(height: 40),
                ],
                CustomButton(
                  widget:
                      userProvider.isLoading
                          ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          )
                          : const Text(
                            'Save Profile',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  function: (userProvider.isLoading) ? null : _saveProfile,
                  color: wawuColors.primary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
