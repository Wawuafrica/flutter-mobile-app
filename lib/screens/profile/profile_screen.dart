import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/models/user.dart'; // Ensure .dart is present
import 'package:wawu_mobile/providers/category_provider.dart';
import 'package:wawu_mobile/providers/dropdown_data_provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart'; // Ensure .dart is present
import 'package:wawu_mobile/providers/skill_provider.dart'; // Add this import
import 'package:wawu_mobile/screens/profile/change_password_screen/change_password_screen.dart';
import 'package:wawu_mobile/services/api_service.dart';
import 'package:wawu_mobile/services/auth_service.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:wawu_mobile/widgets/custom_dropdown/custom_dropdown.dart';
// import 'package:wawu_mobile/widgets/custom_dropdown/custom_dropdown.dart'; // Keep if still used elsewhere, otherwise remove
import 'package:wawu_mobile/widgets/custom_intro_text/custom_intro_text.dart';
import 'package:wawu_mobile/widgets/custom_textfield/custom_textfield.dart';
import 'package:wawu_mobile/widgets/upload_image/upload_image.dart';
import 'package:wawu_mobile/models/country.dart';
import 'package:wawu_mobile/providers/location_provider.dart';

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

  // Add dropdown state for skills
  String? _selectedSkill;

  // New controllers for education fields (replacing dropdowns)
  String? _selectedCertification;
  String? _selectedInstitution;
  final TextEditingController _educationCourseOfStudyController =
      TextEditingController();
  final TextEditingController _educationGraduationDateController =
      TextEditingController();
  final TextEditingController _customInstitutionController =
      TextEditingController();

  // New controllers for professional certification fields (replacing dropdown)
  final TextEditingController _professionalCertificationNameController =
      TextEditingController();
  final TextEditingController _professionalCertificationOrganizationController =
      TextEditingController();
  final TextEditingController _educationEndDateController =
      TextEditingController();
  final TextEditingController _courseOfStudyController =
      TextEditingController();
  final TextEditingController _graduationDateController =
      TextEditingController();

  XFile? _profileImage;
  XFile? _coverImage;
  XFile? _professionalCertificationImage;
  XFile? _meansOfIdentificationImage; // Controller for Means of ID upload

  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _linkedInController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _twitterController = TextEditingController();

  // New controllers for country and state (replacing dropdown)
  final TextEditingController _stateController = TextEditingController();

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  Country? _selectedCountry;

  bool _isDirty = false; // Track if any field has been changed
  bool _isLoading = true; // Start with loading state

  // Declare services without initialization
  late final ApiService apiService;
  late final AuthService authService;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    apiService = Provider.of<ApiService>(context, listen: false);
    authService = AuthService(apiService: apiService);

    final dropdownProvider = Provider.of<DropdownDataProvider>(
      context,
      listen: false,
    );

    final skillProvider = Provider.of<SkillProvider>(context, listen: false);

    // Fetch all dropdown data and skills concurrently
    await Future.wait([
      dropdownProvider.fetchDropdownData(),
      skillProvider.fetchSkills(),
    ]);

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;
    if (user != null) {
      _aboutController.text = user.additionalInfo?.about ?? '';
      _skills = user.additionalInfo?.skills ?? [];

      if (user.additionalInfo?.education != null &&
          user.additionalInfo!.education!.isNotEmpty) {
        final latestEducation = user.additionalInfo!.education!.last;
        _selectedCertification = latestEducation.certification;
        _selectedInstitution = latestEducation.institution;
        _educationCourseOfStudyController.text =
            latestEducation.courseOfStudy ?? '';
        _educationGraduationDateController.text =
            latestEducation.graduationDate ?? '';
        if (latestEducation.certification == 'School-Level Qualifications') {
          _customInstitutionController.text = latestEducation.institution ?? '';
        } else {
          _selectedInstitution = latestEducation.institution;
        }
      }

      if (user.additionalInfo?.professionalCertification != null &&
          user.additionalInfo!.professionalCertification!.isNotEmpty) {
        final latestProfCert =
            user.additionalInfo!.professionalCertification!.last;
        _professionalCertificationNameController.text =
            latestProfCert.name ?? '';
        _professionalCertificationOrganizationController.text =
            latestProfCert.organization ?? '';
      }

      if (user.additionalInfo?.education != null &&
          user.additionalInfo!.education!.isNotEmpty) {
        final education = user.additionalInfo!.education!.last;
        _courseOfStudyController.text = education.courseOfStudy ?? '';
        _graduationDateController.text = education.graduationDate ?? '';
        _educationEndDateController.text = education.endDate ?? '';
      }

      final locationProvider = Provider.of<LocationProvider>(
        context,
        listen: false,
      );
      if (user.country != null && locationProvider.countries.isNotEmpty) {
        _selectedCountry = locationProvider.countries.firstWhere(
          (c) => c.name == user.country,
          orElse: () => Country(id: 0, name: user.country!, flag: ''),
        );
      }
      _stateController.text = user.state ?? '';

      // Extract just the username/ID from the stored full URL for display
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

      _phoneController.text = user.phoneNumber ?? '';
      _emailController.text = user.email ?? '';
    }

    _addListeners();

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
      _courseOfStudyController,
      _graduationDateController,
      _facebookController,
      _linkedInController,
      _instagramController,
      _twitterController,
      _stateController,
      _customInstitutionController,
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
      });
    }
  }

  // Modified skill addition method to support both dropdown and manual input
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
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );

    Map<String, dynamic> payload = {};
    if (_aboutController.text.isNotEmpty) {
      payload['about'] = _aboutController.text;
    }
    if (_skills.isNotEmpty) payload['skills'] = _skills;
    if (_selectedCertification != null) {
      payload['educationCertification'] = _selectedCertification;
      // Conditionally add institution based on the selected certification
      if (_selectedCertification == 'School-Level Qualifications') {
        if (_customInstitutionController.text.isNotEmpty) {
          payload['educationInstitution'] = _customInstitutionController.text;
        }
      } else {
        if (_selectedInstitution != null) {
          payload['educationInstitution'] = _selectedInstitution;
        }
      }
    }
    if (_educationCourseOfStudyController.text.isNotEmpty) {
      payload['educationCourseOfStudy'] =
          _educationCourseOfStudyController.text;
    }
    if (_educationGraduationDateController.text.isNotEmpty) {
      payload['educationGraduationDate'] =
          _educationGraduationDateController.text;
    }
    if (_professionalCertificationNameController.text.isNotEmpty) {
      payload['professionalCertificationName'] =
          _professionalCertificationNameController.text;
    }
    if (_professionalCertificationOrganizationController.text.isNotEmpty) {
      payload['professionalCertificationOrganization'] =
          _professionalCertificationOrganizationController.text;
    }
    if (_educationEndDateController.text.isNotEmpty) {
      payload['educationEndDate'] = _educationEndDateController.text;
    }
    if (_stateController.text.isNotEmpty) {
      payload['state'] = _stateController.text;
    }
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                userProvider.errorMessage ?? 'Failed to update profile',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDirty = false; // Reset dirtiness after save
        });
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
    _courseOfStudyController.dispose();
    _graduationDateController.dispose();
    _facebookController.dispose();
    _linkedInController.dispose();
    _instagramController.dispose();
    _twitterController.dispose();
    _stateController.dispose();
    _customInstitutionController.dispose();

    _professionalCertificationNameController
        .dispose(); // Dispose new controllers
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Widget _buildEducationCard(Education education) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B46C1), Color(0xFF9333EA)],
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
                  education.graduationDate ?? 'N/A',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
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
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B46C1), Color(0xFF9333EA)],
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
              ],
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
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
    return Consumer4<
      CategoryProvider,
      UserProvider,
      DropdownDataProvider,
      SkillProvider
    >(
      builder: (
        context,
        categoryProvider,
        userProvider,
        dropdownProvider,
        skillProvider,
        child,
      ) {
        final user = userProvider.currentUser;
        final fullName =
            '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim();

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
                      // Cover Image with Edit Button
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
                                          ? Image.network(
                                            user!.coverImage!,
                                            fit: BoxFit.cover,
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
                      // Profile Image with Edit Button
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
                                                    ? Image.network(
                                                      user!.profileImage!,
                                                      fit: BoxFit.cover,
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
                if (user?.status ==
                    'VERIFIED') // Assuming status or another field indicates verification
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 5.0,
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
                      const Text(
                        'Verified',
                        style: TextStyle(
                          fontSize: 14,
                          color: wawuColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
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
                  // readOnly: true,
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
                    decoration: InputDecoration(
                      hintText: 'Tell us about yourself...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const CustomIntroText(text: 'Skills'),
                  const SizedBox(height: 10),

                  // Skills Dropdown Section
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
                        _skillController
                            .clear(); // Clear manual input when dropdown is used
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
                              color: wawuColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(skill),
                                const SizedBox(width: 5),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _skills.remove(skill);
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
                  if (user?.additionalInfo?.education != null &&
                      user!.additionalInfo!.education!.isNotEmpty)
                    for (Education edu in user.additionalInfo!.education!)
                      _buildEducationCard(edu),
                  const SizedBox(height: 12),
                  if (user?.additionalInfo?.education == null ||
                      user!.additionalInfo!.education!.isEmpty)
                    const Text('No education available'),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 25),
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
                            // When the certificate type changes, clear the other institution field
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
                        labelText: 'Graduation Date',
                        labelTextStyle2: true,
                        suffixIcon: Icons.calendar_today,
                        readOnly: true,
                        onTap:
                            () => _selectGraduationDate(
                              _educationGraduationDateController,
                            ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Graduation Date is required';
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
                  if (user?.additionalInfo?.professionalCertification != null &&
                      user!
                          .additionalInfo!
                          .professionalCertification!
                          .isNotEmpty)
                    for (ProfessionalCertification cert
                        in user.additionalInfo!.professionalCertification!)
                      _buildCertificationCard(cert),
                  const SizedBox(height: 12),
                  if (user?.additionalInfo?.professionalCertification == null ||
                      user!.additionalInfo!.professionalCertification!.isEmpty)
                    const Text('No certifications available'),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 25),
                      CustomTextfield(
                        controller: _professionalCertificationNameController,
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
                      // Display existing professional certification image if available
                      if (user?.additionalInfo?.professionalCertification !=
                              null &&
                          user!
                              .additionalInfo!
                              .professionalCertification!
                              .isNotEmpty &&
                          user
                                  .additionalInfo!
                                  .professionalCertification!
                                  .last
                                  .file
                                  ?.link !=
                              null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(5),
                            image: DecorationImage(
                              image: NetworkImage(
                                user
                                    .additionalInfo!
                                    .professionalCertification!
                                    .last
                                    .file!
                                    .link!,
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      UploadImage(
                        labelText: 'Upload Certification Document',
                        onImageChanged: (xfile) {
                          setState(() {
                            _professionalCertificationImage = xfile;
                          });
                        },
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 40),
                const CustomIntroText(text: 'Means Of Identification'),
                const SizedBox(height: 20),
                if (user?.additionalInfo?.meansOfIdentification?.file?.link !=
                    null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(5),
                      image: DecorationImage(
                        image: NetworkImage(
                          user!
                              .additionalInfo!
                              .meansOfIdentification!
                              .file!
                              .link!,
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  UploadImage(
                    labelText: 'Upload Means of ID',
                    onImageChanged: (xfile) {
                      // Enable upload for means of ID
                      setState(() {
                        _meansOfIdentificationImage = xfile;
                      });
                    },
                  ),
                const SizedBox(height: 20),
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
                        return CustomDropdown<Country>(
                          options: locationProvider.countries,
                          label: 'Select Country',
                          selectedValue: _selectedCountry,
                          isDisabled: true,
                          onChanged: (value) {
                            setState(() {
                              _selectedCountry = value;
                            });
                          },
                          itemBuilder:
                              (context, country, isSelected) => Row(
                                children: [
                                  if (country.flag != null &&
                                      country.flag!.isNotEmpty)
                                    Image.network(
                                      country.flag!,
                                      width: 24,
                                      height: 24,
                                      errorBuilder:
                                          (_, __, ___) =>
                                              SizedBox(width: 24, height: 24),
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
                    CustomTextfield(
                      controller: _stateController,
                      hintText: 'Enter State',
                      labelText: 'State',
                      labelTextStyle2: true,
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                if (user?.role != 'BUYER') ...[
                  const CustomIntroText(text: 'Social Handles'),
                  const SizedBox(height: 20),
                  CustomTextfield(
                    controller: _facebookController,
                    hintText: 'Enter your Facebook username (e.g., yourname)',
                    labelText: 'Facebook',
                    labelTextStyle2: true,
                    suffixIcon: FontAwesomeIcons.facebook, // Facebook icon
                  ),
                  const SizedBox(height: 20),
                  CustomTextfield(
                    controller: _linkedInController,
                    hintText:
                        'Enter your LinkedIn profile ID (e.g., in/yourname)',
                    labelText: 'LinkedIn',
                    labelTextStyle2: true,
                    suffixIcon:
                        FontAwesomeIcons
                            .linkedin, // LinkedIn icon - typically requires a custom font icon or an image
                  ),
                  const SizedBox(height: 20),
                  CustomTextfield(
                    controller: _instagramController,
                    hintText: 'Enter your Instagram username (e.g., @yourname)',
                    labelText: 'Instagram',
                    labelTextStyle2: true,
                    suffixIcon: FontAwesomeIcons.instagram, // Instagram icon
                  ),
                  const SizedBox(height: 20),
                  CustomTextfield(
                    controller: _twitterController,
                    hintText:
                        'Enter your X (Twitter) username (e.g., @yourname)',
                    labelText: 'Twitter',
                    labelTextStyle2: true,
                    suffixIcon:
                        FontAwesomeIcons
                            .twitter, // Twitter (X) icon - typically requires a custom font icon or an image
                  ),
                  const SizedBox(height: 40),
                ],
                CustomButton(
                  widget:
                      userProvider.isLoading
                          ? CircularProgressIndicator()
                          : const Text(
                            'Save Profile',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  function: userProvider.isLoading ? null : _saveProfile,
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
