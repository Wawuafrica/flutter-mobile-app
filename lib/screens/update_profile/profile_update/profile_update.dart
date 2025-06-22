import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/category_provider.dart';
import 'package:wawu_mobile/providers/dropdown_data_provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/screens/plan/plan.dart';
import 'package:wawu_mobile/screens/account_payment/disclaimer/disclaimer.dart';
import 'package:wawu_mobile/screens/wawu_africa/sign_up/countries.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:wawu_mobile/widgets/custom_dropdown/custom_dropdown.dart';
import 'package:wawu_mobile/widgets/custom_intro_text/custom_intro_text.dart';
import 'package:wawu_mobile/widgets/custom_textfield/custom_textfield.dart';
import 'package:wawu_mobile/widgets/onboarding/onboarding_progress_indicator.dart';
import 'package:wawu_mobile/widgets/upload_image/upload_image.dart';

class ProfileUpdate extends StatefulWidget {
  const ProfileUpdate({super.key});

  @override
  State<ProfileUpdate> createState() => _ProfileUpdateState();
}

class _ProfileUpdateState extends State<ProfileUpdate> {
  final _formKey =
      GlobalKey<FormState>(); // Added GlobalKey for form validation

  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _skillController = TextEditingController();
  final List<String> _skills = [];
  final int _maxAboutLength = 200;

  String? _selectedCertification;
  String? _selectedInstitution;
  final TextEditingController _educationCourseOfStudyController =
      TextEditingController();
  final TextEditingController _educationGraduationDateController =
      TextEditingController(); // New field
  final TextEditingController _customInstitutionController =
      TextEditingController();

  final TextEditingController _professionalCertificationNameController =
      TextEditingController();
  final TextEditingController _professionalCertificationOrganizationController =
      TextEditingController();
  final TextEditingController _professionalCertificationEndDateController =
      TextEditingController(); // New field

  XFile? _profileImage;
  Uint8List? _profileWebImageBytes; // To store bytes for web profile image
  XFile? _coverImage;
  Uint8List? _coverWebImageBytes; // To store bytes for web cover image
  XFile? _professionalCertificationImage;
  XFile? _meansOfIdentification;

  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _linkedInController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _twitterController = TextEditingController();

  String? _selectedCountry;
  final TextEditingController _stateController = TextEditingController();

  bool _isSavingProfile = false;
  bool _isDirty = false; // To track if any field has been changed

  // --- IMPORTANT DEBUGGING FLAG ---
  // Set this to `true` to force Web behavior (e.g., when debugging web on a mobile build).
  // Set this to `false` to force Mobile behavior (e.g., when debugging mobile on a web build).
  // REMEMBER TO CHANGE THIS TO `kIsWeb` BEFORE DEPLOYING TO PRODUCTION.
  final bool _forceIsWeb =
      kIsWeb; // Default to kIsWeb, change to true/false for debugging

  bool _isLoading = true; // Start with loading state

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final dropdownProvider = Provider.of<DropdownDataProvider>(
      context,
      listen: false,
    );

    await dropdownProvider.fetchDropdownData();

    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    if (user != null) {
      if (user.additionalInfo?.education != null &&
          user.additionalInfo!.education!.isNotEmpty) {
        _selectedCertification =
            user.additionalInfo!.education!.last.certification;
        final latestEducation = user.additionalInfo!.education!.last;
        _selectedCertification = latestEducation.certification;
        if (latestEducation.certification == 'School-Level Qualifications') {
          _customInstitutionController.text = latestEducation.institution ?? '';
        } else {
          _selectedInstitution = latestEducation.institution;
        }
      }
      if (user.additionalInfo?.professionalCertification != null &&
          user.additionalInfo!.professionalCertification!.isNotEmpty) {
        _professionalCertificationNameController.text =
            user.additionalInfo!.professionalCertification!.last.name ?? '';
      }
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
      _professionalCertificationEndDateController,
      _facebookController,
      _linkedInController,
      _instagramController,
      _twitterController,
      _stateController,
      _customInstitutionController,
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
      _onFieldChanged(); // Mark as dirty
      setState(() {
        // If it's web, read the bytes immediately
        if (_forceIsWeb) {
          pickedFile.readAsBytes().then((bytes) {
            setState(() {
              if (imageType == 'profile') {
                _profileWebImageBytes = bytes;
                _profileImage =
                    pickedFile; // Keep XFile for potential API upload
              } else if (imageType == 'cover') {
                _coverWebImageBytes = bytes;
                _coverImage = pickedFile; // Keep XFile for potential API upload
              }
            });
          });
        } else {
          // If it's mobile, just store the XFile
          if (imageType == 'profile') {
            _profileImage = pickedFile;
          } else if (imageType == 'cover') {
            _coverImage = pickedFile;
          }
        }
      });
    }
  }

  void _addSkill() {
    if (_skillController.text.trim().isNotEmpty) {
      setState(() {
        _skills.add(_skillController.text.trim());
        _skillController.clear();
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

    setState(() {
      _isSavingProfile = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );

    // Dynamically build the payload
    Map<String, dynamic> payload = {};
    if (_aboutController.text.isNotEmpty) {
      payload['about'] = _aboutController.text;
    }
    if (_skills.isNotEmpty) payload['skills'] = _skills;
    if (_selectedCertification != null) {
      payload['educationCertification'] = _selectedCertification;
    }
    if (_selectedCertification == 'School-Level Qualifications') {
      if (_customInstitutionController.text.isNotEmpty) {
        payload['educationInstitution'] = _customInstitutionController.text;
      }
    } else {
      if (_selectedInstitution != null) {
        payload['educationInstitution'] = _selectedInstitution;
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
    if (_professionalCertificationEndDateController.text.isNotEmpty) {
      payload['professionalCertificationEndDate'] =
          _professionalCertificationEndDateController.text;
    }
    if (_selectedCountry != null) payload['country'] = _selectedCountry;
    if (_stateController.text.isNotEmpty) {
      payload['state'] = _stateController.text;
    }

    Map<String, String> socialHandles = {};
    if (_facebookController.text.isNotEmpty) {
      socialHandles['facebook'] = _facebookController.text;
    }
    if (_linkedInController.text.isNotEmpty) {
      socialHandles['linkedIn'] = _linkedInController.text;
    }
    if (_instagramController.text.isNotEmpty) {
      socialHandles['instagram'] = _instagramController.text;
    }
    if (_twitterController.text.isNotEmpty) {
      socialHandles['twitter'] = _twitterController.text;
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
        meansOfIdentification: _meansOfIdentification,
      );

      if (userProvider.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Plan()),
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
          _isSavingProfile = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Remove listeners to prevent memory leaks
    final controllers = [
      _aboutController,
      _skillController,
      _educationCourseOfStudyController,
      _educationGraduationDateController,
      _professionalCertificationNameController,
      _professionalCertificationOrganizationController,
      _professionalCertificationEndDateController,
      _facebookController,
      _linkedInController,
      _instagramController,
      _twitterController,
      _stateController,
      _customInstitutionController,
    ];

    for (var controller in controllers) {
      controller.removeListener(_onFieldChanged);
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile'), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Use the forced boolean for rendering logic
    final bool currentIsWeb = _forceIsWeb;

    return Consumer3<CategoryProvider, UserProvider, DropdownDataProvider>(
      builder: (
        context,
        categoryProvider,
        userProvider,
        dropdownProvider,
        child,
      ) {
        final selectedSubCategory = categoryProvider.selectedSubCategory;
        final user = userProvider.currentUser;
        final bool isBuyer = (user?.role?.toUpperCase() == 'BUYER');
        final fullName =
            '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            centerTitle: true,
            actions: [
              OnboardingProgressIndicator(
                currentStep: 'profile_update',
                steps: const [
                  'account_type',
                  'category_selection',
                  'subcategory_selection',
                  'update_profile',
                  'profile_update',
                  'plan',
                  'payment',
                  'payment_processing',
                  'verify_payment',
                  'disclaimer',
                ],
                stepLabels: const {
                  'account_type': 'Account',
                  'category_selection': 'Category',
                  'subcategory_selection': 'Subcategory',
                  'update_profile': 'Intro',
                  'profile_update': 'Profile',
                  'plan': 'Plan',
                  'payment': 'Payment',
                  'payment_processing': 'Processing',
                  'verify_payment': 'Verify',
                  'disclaimer': 'Disclaimer',
                },
              ),
            ],
          ),
          body: Form(
            // Wrap with Form widget
            key: _formKey, // Assign the GlobalKey
            child: ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 160,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 100,
                        color: wawuColors.primary.withAlpha(50),
                        child:
                            currentIsWeb
                                ? (_coverWebImageBytes != null
                                    ? Image.memory(
                                      _coverWebImageBytes!,
                                      fit: BoxFit.cover,
                                    )
                                    : const Center(
                                      child: Text(
                                        'Add Cover Photo',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ))
                                : (_coverImage != null
                                    ? Image.file(
                                      File(_coverImage!.path), // Added key
                                      key: ValueKey(_coverImage!.path),
                                      fit: BoxFit.cover,
                                    )
                                    : const Center(
                                      child: Text(
                                        'Add Cover Photo',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    )),
                      ),
                      Positioned(
                        top: 50,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: ClipOval(
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
                                      currentIsWeb
                                          ? (_profileWebImageBytes != null
                                              ? Image.memory(
                                                _profileWebImageBytes!,
                                                fit: BoxFit.cover,
                                              )
                                              : Image.asset(
                                                'assets/images/other/avatar.webp',
                                              ))
                                          : (_profileImage != null
                                              ? Image.file(
                                                File(
                                                  _profileImage!.path,
                                                ), // Added key
                                                key: ValueKey(
                                                  _profileImage!.path,
                                                ),
                                                fit: BoxFit.cover,
                                              )
                                              : Image.asset(
                                                'assets/images/other/avatar.webp',
                                              )),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 120,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: () => _pickImageForProfileAndCover('profile'),
                          child: ClipOval(
                            child: Container(
                              width: 30,
                              height: 30,
                              color: const Color.fromARGB(255, 219, 219, 219),
                              child: Icon(
                                Icons.camera_alt,
                                size: 13,
                                color: wawuColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 20,
                        bottom: 45,
                        child: GestureDetector(
                          onTap: () => _pickImageForProfileAndCover('cover'),
                          child: ClipOval(
                            child: Container(
                              width: 30,
                              height: 30,
                              color: const Color.fromARGB(255, 219, 219, 219),
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
                    userProvider.currentUser?.role ?? 'Role',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color.fromARGB(255, 125, 125, 125),
                      fontWeight: FontWeight.w200,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Conditionally display Specialty Selected for non-buyers
                if (!isBuyer)
                  Center(
                    child: Text(
                      selectedSubCategory != null
                          ? selectedSubCategory.name
                          : '',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: wawuColors.primary,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),

                // Conditionally display "Not Verified" for non-buyers
                if (!isBuyer)
                  Wrap(
                    spacing: 5,
                    alignment: WrapAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 15,
                        color: wawuColors.primary,
                      ),
                      Text(
                        userProvider.currentUser?.status == 'VERIFIED'
                            ? 'Verified'
                            : 'Not Verified',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color.fromARGB(255, 125, 125, 125),
                          fontWeight: FontWeight.w200,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 5,
                  alignment: WrapAlignment.center,
                  children: const [
                    Icon(
                      Icons.star,
                      size: 15,
                      color: Color.fromARGB(255, 162, 162, 162),
                    ),
                    Icon(
                      Icons.star,
                      size: 15,
                      color: Color.fromARGB(255, 162, 162, 162),
                    ),
                    Icon(
                      Icons.star,
                      size: 15,
                      color: Color.fromARGB(255, 162, 162, 162),
                    ),
                    Icon(
                      Icons.star,
                      size: 15,
                      color: Color.fromARGB(255, 162, 162, 162),
                    ),
                    Icon(
                      Icons.star,
                      size: 15,
                      color: Color.fromARGB(255, 162, 162, 162),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Conditionally display "About" section for non-buyers
                if (!isBuyer) ...[
                  const CustomIntroText(text: 'About'),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _aboutController,
                    maxLength: _maxAboutLength,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Tell us about yourself...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Conditionally display "Skills" section for non-buyers
                if (!isBuyer) ...[
                  const CustomIntroText(text: 'Skills'),
                  const SizedBox(height: 10),
                  CustomTextfield(
                    controller: _skillController,
                    hintText: 'Add a skill...',
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: _addSkill,
                    child: CustomButton(
                      widget: const Text(
                        'Add',
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
                              color: wawuColors.primary.withOpacity(0.2),
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
                ],

                // Conditionally display "Education" section for non-buyers
                if (!isBuyer) ...[
                  const CustomIntroText(text: 'Education'),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 25),
                      const Text(
                        'Certification',
                        style: TextStyle(fontWeight: FontWeight.w400),
                      ),
                      const SizedBox(height: 5),
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
                      if (_selectedCertification !=
                          'School-Level Qualifications')
                        const Text(
                          'Institution',
                          style: TextStyle(fontWeight: FontWeight.w400),
                        ),
                      const SizedBox(height: 5),
                      _selectedCertification == 'School-Level Qualifications'
                          ? CustomTextfield(
                            controller: _customInstitutionController,
                            hintText: 'Enter your institution',
                            labelText: 'Institution',
                            labelTextStyle2: true,
                          )
                          : CustomDropdown(
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
                        hintText: 'Enter course of study',
                        labelTextStyle2: true,
                        labelText: 'Course of Study',
                      ),
                      const SizedBox(height: 10),
                      CustomTextfield(
                        controller: _educationGraduationDateController,
                        hintText: 'YYYY-MM-DD',
                        labelText: 'Graduation Date',
                        labelTextStyle2: true,
                        suffixIcon: Icons.calendar_today,
                        readOnly: true, // Make it read-only
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
                    ],
                  ),
                  const SizedBox(height: 30),
                ],

                // Conditionally display "Professional Certification" section for non-buyers
                if (!isBuyer) ...[
                  const CustomIntroText(text: 'Professional Certification'),
                  const SizedBox(height: 25),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Name',
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      CustomTextfield(
                        controller: _professionalCertificationNameController,
                        hintText: 'Enter Certificate Name',
                        labelText: 'Certificate Name',
                        labelTextStyle2: true,
                      ),
                      const SizedBox(height: 20),
                      CustomTextfield(
                        controller:
                            _professionalCertificationOrganizationController,
                        hintText: 'Enter Organization Name',
                        labelTextStyle2: true,
                        labelText: 'Organization',
                      ),
                      const SizedBox(height: 20),
                      CustomTextfield(
                        controller: _professionalCertificationEndDateController,
                        hintText: 'YYYY-MM-DD',
                        labelText: 'End Date',
                        labelTextStyle2: true,
                        suffixIcon: Icons.calendar_today,
                        readOnly: true, // Make it read-only
                        onTap:
                            () => _selectGraduationDate(
                              _professionalCertificationEndDateController,
                            ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'End Date is required';
                          }
                          return null;
                        },
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
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],

                const CustomIntroText(text: 'Means Of Identification'),
                const SizedBox(height: 20),
                UploadImage(
                  labelText: 'Upload Means of ID',
                  onImageChanged: (xfile) {
                    setState(() {
                      _meansOfIdentification = xfile;
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
                    CustomDropdown(
                      options: Countries.all,
                      label: 'Select Country',
                      selectedValue: _selectedCountry,
                      onChanged: (value) {
                        setState(() {
                          _selectedCountry = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomTextfield(
                      controller: _stateController,
                      hintText: 'Enter State',
                      labelTextStyle2: true,
                      labelText: 'State',
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Conditionally display "Social Handles" for non-buyers
                if (!isBuyer) ...[
                  const CustomIntroText(text: 'Social Handles'),
                  const SizedBox(height: 20),
                  CustomTextfield(
                    controller: _facebookController,
                    hintText: 'Enter your social media handle',
                    labelText: 'Facebook',
                    labelTextStyle2: true,
                  ),
                  const SizedBox(height: 20),
                  CustomTextfield(
                    controller: _linkedInController,
                    hintText: 'Enter your social media handle',
                    labelText: 'LinkedIn',
                    labelTextStyle2: true,
                  ),
                  const SizedBox(height: 20),
                  CustomTextfield(
                    controller: _instagramController,
                    hintText: 'Enter your social media handle',
                    labelText: 'Instagram',
                    labelTextStyle2: true,
                  ),
                  const SizedBox(height: 20),
                  CustomTextfield(
                    controller: _twitterController,
                    hintText: 'Enter your social media handle',
                    labelText: 'X fka Twitter',
                    labelTextStyle2: true,
                  ),
                  const SizedBox(height: 40),
                ],

                ElevatedButton(
                  onPressed:
                      _isSavingProfile
                          ? null
                          : () {
                            final userProvider = Provider.of<UserProvider>(context, listen: false);
                            final role = userProvider.currentUser?.role?.toLowerCase();
                            if (!_isDirty) {
                              // Skip: Navigate to the next screen or back
                              if (role == 'buyer') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const Disclaimer(),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const Plan(),
                                  ),
                                );
                              }
                            } else {
                              // Continue: Save the profile
                              _saveProfile();
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        wawuColors
                            .primary, // Assuming wawuColors is defined; adjust if needed
                    foregroundColor: Colors.white,
                  ),
                  child:
                      _isSavingProfile
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(_isDirty ? 'Continue' : 'Skip'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
