import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/models/user.dart'; // Ensure .dart is present
import 'package:wawu_mobile/providers/category_provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart'; // Ensure .dart is present
import 'package:wawu_mobile/screens/profile/change_password_screen/change_password_screen.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
// import 'package:wawu_mobile/widgets/custom_dropdown/custom_dropdown.dart'; // Keep if still used elsewhere, otherwise remove
import 'package:wawu_mobile/widgets/custom_intro_text/custom_intro_text.dart';
import 'package:wawu_mobile/widgets/custom_textfield/custom_textfield.dart';
import 'package:wawu_mobile/widgets/upload_image/upload_image.dart';

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

  // New controllers for education fields (replacing dropdowns)
  final TextEditingController _educationCertificationController =
      TextEditingController();
  final TextEditingController _educationInstitutionController =
      TextEditingController();
  final TextEditingController _educationCourseOfStudyController =
      TextEditingController();
  final TextEditingController _educationGraduationDateController =
      TextEditingController();

  // New controllers for professional certification fields (replacing dropdown)
  final TextEditingController _professionalCertificationNameController =
      TextEditingController();
  final TextEditingController _professionalCertificationOrganizationController =
      TextEditingController();
  final TextEditingController _professionalCertificationEndDateController =
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
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();

  bool _isSavingProfile = false;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;
    if (user != null) {
      _aboutController.text = user.additionalInfo?.about ?? '';
      _skills = user.additionalInfo?.skills ?? [];

      // Initialize education fields from existing user data
      if (user.additionalInfo?.education != null &&
          user.additionalInfo!.education!.isNotEmpty) {
        final latestEducation =
            user.additionalInfo!.education!.last; // Access safely
        _educationCertificationController.text =
            latestEducation.certification ?? '';
        _educationInstitutionController.text =
            latestEducation.institution ?? '';
        _educationCourseOfStudyController.text =
            latestEducation.courseOfStudy ?? '';
        _educationGraduationDateController.text =
            latestEducation.graduationDate ?? '';
      }

      // Initialize professional certification fields from existing user data
      if (user.additionalInfo?.professionalCertification != null &&
          user.additionalInfo!.professionalCertification!.isNotEmpty) {
        final latestProfCert =
            user
                .additionalInfo!
                .professionalCertification!
                .last; // Access safely
        _professionalCertificationNameController.text =
            latestProfCert.name ?? '';
        _professionalCertificationOrganizationController.text =
            latestProfCert.organization ?? '';
        _professionalCertificationEndDateController.text =
            latestProfCert.endDate ?? '';
      }

      _countryController.text =
          user.country ?? ''; // Initialize country controller
      _stateController.text = user.state ?? '';
      _facebookController.text =
          user.additionalInfo?.socialHandles?['facebook'] ?? '';
      _linkedInController.text =
          user.additionalInfo?.socialHandles?['linkedIn'] ?? '';
      _instagramController.text =
          user.additionalInfo?.socialHandles?['instagram'] ?? '';
      _twitterController.text =
          user.additionalInfo?.socialHandles?['twitter'] ?? '';
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

  // Future<void> _pickProfessionalCertificationImage() async {
  //   final ImagePicker picker = ImagePicker();
  //   final XFile? pickedFile = await picker.pickImage(
  //     source: ImageSource.gallery,
  //   );

  //   if (pickedFile != null) {
  //     setState(() {
  //       _professionalCertificationImage = pickedFile;
  //     });
  //   }
  // }

  // Future<void> _pickMeansOfIdentificationImage() async {
  //   final ImagePicker picker = ImagePicker();
  //   final XFile? pickedFile = await picker.pickImage(
  //     source: ImageSource.gallery,
  //   );

  //   if (pickedFile != null) {
  //     setState(() {
  //       _meansOfIdentificationImage = pickedFile;
  //     });
  //   }
  // }

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

    try {
      await userProvider.updateCurrentUserProfile(
        about: _aboutController.text,
        skills: _skills,
        educationCertification: _educationCertificationController.text,
        educationInstitution: _educationInstitutionController.text,
        educationCourseOfStudy: _educationCourseOfStudyController.text,
        educationGraduationDate: _educationGraduationDateController.text,
        professionalCertificationName:
            _professionalCertificationNameController.text,
        professionalCertificationOrganization:
            _professionalCertificationOrganizationController.text,
        professionalCertificationEndDate:
            _professionalCertificationEndDateController.text,
        professionalCertificationImage: _professionalCertificationImage,
        meansOfIdentification:
            _meansOfIdentificationImage, // Pass the selected means of ID image
        country: _countryController.text, // Use country controller
        state: _stateController.text,
        socialHandles: {
          'facebook': _facebookController.text,
          'linkedIn': _linkedInController.text,
          'instagram': _instagramController.text,
          'twitter': _twitterController.text,
        },
        subCategoryUuid: categoryProvider.selectedSubCategory?.uuid,
        profileImage: _profileImage,
        coverImage: _coverImage,
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
          _isSavingProfile = false;
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
    _professionalCertificationEndDateController.dispose();
    _facebookController.dispose();
    _linkedInController.dispose();
    _instagramController.dispose();
    _twitterController.dispose();
    _stateController.dispose();
    _educationCertificationController.dispose(); // Dispose new controllers
    _educationInstitutionController.dispose(); // Dispose new controllers
    _professionalCertificationNameController
        .dispose(); // Dispose new controllers
    _countryController.dispose(); // Dispose new country controller
    super.dispose();
  }

  Widget _buildEducationCard(Education education) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              education.certification ?? 'Certification',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 5),
            Text('Institution: ${education.institution ?? 'N/A'}'),
            Text('Course: ${education.courseOfStudy ?? 'N/A'}'),
            Text('Graduation: ${education.graduationDate ?? 'N/A'}'),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalCertificationCard(ProfessionalCertification cert) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cert.name ?? 'Certification',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 5),
            Text('Organization: ${cert.organization ?? 'N/A'}'),
            Text('End Date: ${cert.endDate ?? 'N/A'}'),
            if (cert.file?.link != null) Text('Document: ${cert.file!.link}'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CategoryProvider, UserProvider>(
      builder: (context, categoryProvider, userProvider, child) {
        final user = userProvider.currentUser;
        final fullName =
            '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim();
        print(user?.toJson());
        // final selectedSubCategory = categoryProvider.selectedSubCategory;

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
                                      _profileImage != null
                                          ? Image.file(
                                            File(_profileImage!.path),
                                            key: ValueKey(_profileImage!.path),
                                            fit: BoxFit.cover,
                                          )
                                          : (user?.profileImage != null
                                              ? Image.network(
                                                user!.profileImage!,
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
                    user?.role ?? 'Role',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color.fromARGB(255, 125, 125, 125),
                      fontWeight: FontWeight.w200,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    user?.jobType ?? 'No Specialty Selected',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: wawuColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
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
                const CustomIntroText(text: 'Credentials'),
                const SizedBox(height: 10),
                CustomTextfield(
                  hintText: user?.phoneNumber ?? 'Phone Number',
                  labelText: 'Phone Number',
                  labelTextStyle2: true,
                  // enabled: false,
                ),
                const SizedBox(height: 10),
                CustomTextfield(
                  hintText: user?.email ?? 'Email',
                  labelText: 'Email',
                  labelTextStyle2: true,
                  // enabled: false,
                ),
                const SizedBox(height: 10),
                CustomButton(
                  function: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChangePasswordScreen(),
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
                const CustomIntroText(text: 'Education'),
                if (user?.additionalInfo?.education != null)
                  ...user!.additionalInfo!.education!.map(
                    (edu) => _buildEducationCard(edu),
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 25),
                    CustomTextfield(
                      controller: _educationCertificationController,
                      hintText: 'Enter Certification (e.g., BSc, MSc, PhD)',
                      labelText: 'Certification',
                      labelTextStyle2: true,
                    ),
                    const SizedBox(height: 10),
                    CustomTextfield(
                      controller: _educationInstitutionController,
                      hintText: 'Enter Institution (e.g., University Of Lagos)',
                      labelText: 'Institution',
                      labelTextStyle2: true,
                    ),
                    const SizedBox(height: 10),
                    CustomTextfield(
                      controller: _educationCourseOfStudyController,
                      hintText: 'Enter course of study',
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
                  ],
                ),
                const SizedBox(height: 30),
                const CustomIntroText(text: 'Professional Certification'),
                if (user?.additionalInfo?.professionalCertification != null)
                  ...user!.additionalInfo!.professionalCertification!.map(
                    (cert) => _buildProfessionalCertificationCard(cert),
                  ),
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
                      hintText: 'Enter Organization Name',
                      labelText: 'Organization',
                      labelTextStyle2: true,
                    ),
                    const SizedBox(height: 20),
                    CustomTextfield(
                      controller: _professionalCertificationEndDateController,
                      hintText: 'YYYY-MM-DD',
                      labelText: 'End Date',
                      labelTextStyle2: true,
                      suffixIcon: Icons.calendar_today,
                      readOnly: true,
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
                        height: 100,
                        width: 100,
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
                const SizedBox(height: 40),
                const CustomIntroText(text: 'Means Of Identification'),
                const SizedBox(height: 20),
                if (user?.additionalInfo?.meansOfIdentification?.file?.link !=
                    null)
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Means of Identification',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Document: ${user!.additionalInfo!.meansOfIdentification!.file!.link}',
                          ),
                          const SizedBox(height: 10),
                          // Display existing means of identification image if available
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            height: 100,
                            width: 100,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(5),
                              image: DecorationImage(
                                image: NetworkImage(
                                  user
                                      .additionalInfo!
                                      .meansOfIdentification!
                                      .file!
                                      .link!,
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
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
                    CustomTextfield(
                      controller: _countryController,
                      hintText: 'Enter Country',
                      labelText: 'Country',
                      labelTextStyle2: true,
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
                CustomButton(
                  function: _isSavingProfile ? null : _saveProfile,
                  widget:
                      _isSavingProfile
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            'Save Changes',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  color: wawuColors.primary,
                  textColor: Colors.white,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
