import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wawu_mobile/screens/plan/plan.dart';
import 'package:wawu_mobile/screens/profile/change_password_screen/change_password_screen.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:wawu_mobile/widgets/custom_dropdown/custom_dropdown.dart';
import 'package:wawu_mobile/widgets/custom_intro_text/custom_intro_text.dart';
import 'package:wawu_mobile/widgets/custom_textfield/custom_textfield.dart';
import 'package:wawu_mobile/widgets/upload_image/upload_image.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _skillController = TextEditingController();
  final List<String> _skills = [];
  final int _maxAboutLength = 200;
  String? selectedCertificateValue;
  File? _profileImage;
  File? _coverImage;

  Future<void> _pickImage(String imageType) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        switch (imageType) {
          case 'profile':
            _profileImage = File(pickedFile.path);
            break;
          case 'cover':
            _coverImage = File(pickedFile.path);
            break;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: ListView(
          children: [
            Column(
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
                            _coverImage == null
                                ? Text(
                                  'Add Cover Photo',
                                  textAlign: TextAlign.center,
                                )
                                : Image.file(_coverImage!, fit: BoxFit.cover),
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
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                  ),
                                  child:
                                      _profileImage == null
                                          ? Image.asset(
                                            'assets/images/other/avatar.jpg',
                                          )
                                          : Image.file(
                                            _profileImage!,
                                            fit: BoxFit.cover,
                                          ),
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
                          onTap: () {
                            _pickImage('profile');
                          },
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
                          onTap: () {
                            _pickImage('cover');
                          },
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
                SizedBox(height: 10),
                Text(
                  'Mavis Nwaokorie',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'Seller',
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color.fromARGB(255, 125, 125, 125),
                    fontWeight: FontWeight.w200,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Software Developer',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: wawuColors.primary,
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  spacing: 5,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 15,
                      color: wawuColors.primary,
                    ),
                    Text(
                      'Not Verified',
                      style: TextStyle(
                        fontSize: 13,
                        color: wawuColors.primary,
                        fontWeight: FontWeight.w200,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  spacing: 5,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.star,
                      size: 15,
                      color: const Color.fromARGB(255, 162, 162, 162),
                    ),
                    Icon(
                      Icons.star,
                      size: 15,
                      color: const Color.fromARGB(255, 162, 162, 162),
                    ),
                    Icon(
                      Icons.star,
                      size: 15,
                      color: const Color.fromARGB(255, 162, 162, 162),
                    ),
                    Icon(
                      Icons.star,
                      size: 15,
                      color: const Color.fromARGB(255, 162, 162, 162),
                    ),
                    Icon(
                      Icons.star,
                      size: 15,
                      color: const Color.fromARGB(255, 162, 162, 162),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                CustomIntroText(text: 'Name'),
                SizedBox(height: 10),
                CustomTextfield(
                  hintText: 'Jane',
                  labelTextStyle2: true,
                  labelText: 'First Name',
                ),
                SizedBox(height: 10),
                CustomTextfield(
                  hintText: 'Doe',
                  labelTextStyle2: true,
                  labelText: 'Last Name',
                ),
                SizedBox(height: 20),
                CustomIntroText(text: 'Credentials'),
                SizedBox(height: 10),
                CustomTextfield(
                  hintText: '+234123456789',
                  labelTextStyle2: true,
                  labelText: 'Phone Number',
                ),
                SizedBox(height: 10),
                CustomTextfield(
                  hintText: 'admin@gmail.com',
                  labelTextStyle2: true,
                  labelText: 'Email',
                ),
                CustomTextfield(
                  hintText: '***********',
                  labelTextStyle2: true,
                  labelText: 'Password',
                ),
                SizedBox(height: 20),
                Row(
                  spacing: 10.0,
                  children: [
                    Expanded(
                      child: CustomButton(
                        function: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChangePasswordScreen(),
                            ),
                          );
                        },
                        widget: Text(
                          'Change Email',
                          style: TextStyle(color: Colors.white),
                        ),
                        color: wawuColors.primary,
                      ),
                    ),
                    Expanded(
                      child: CustomButton(
                        function: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChangePasswordScreen(),
                            ),
                          );
                        },
                        widget: Text(
                          'Change Password',
                          style: TextStyle(color: Colors.white),
                        ),
                        color: wawuColors.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                CustomIntroText(text: 'About'),
                SizedBox(height: 20),
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
                CustomIntroText(text: 'Skills'),
                const SizedBox(height: 10),
                CustomTextfield(
                  controller: _skillController,
                  hintText: 'Add a skill...',
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: _addSkill,
                  child: CustomButton(
                    widget: Text('Add', style: TextStyle(color: Colors.white)),
                    color: wawuColors.buttonPrimary,
                    textColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                // Display Skills
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
                CustomIntroText(text: 'Education'),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 25),
                    Text(
                      'Certification',
                      style: TextStyle(fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 5),
                    CustomDropdown(
                      options: ['BSc', 'High School', 'MSc', 'PhD'],
                      label: 'Select Certificate',
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Institution',
                      style: TextStyle(fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 5),
                    CustomDropdown(
                      options: [
                        'University Of Lagos',
                        'University Of Ibadan',
                        'University Of Port Harcourt',
                      ],
                      label: 'Select Institution',
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                CustomIntroText(text: 'Professional Certification'),
                const SizedBox(height: 25),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Name',
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    CustomDropdown(
                      options: ['CAC', 'Skill Certificate', 'MIT'],
                      label: 'Select Certificate',
                    ),
                    const SizedBox(height: 20),
                    CustomTextfield(
                      hintText: 'Enter Organization Name',
                      labelTextStyle2: true,
                      labelText: 'Organization',
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Text(
                  'Add a valid means of identification as this will help us...',
                  style: TextStyle(
                    color: const Color.fromARGB(255, 125, 125, 125),
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 20),
                UploadImage(),
                SizedBox(height: 40),
                CustomIntroText(text: 'Means Of Identification'),
                SizedBox(height: 20),
                UploadImage(),
                SizedBox(height: 20),
                Text(
                  'Acceptable means of identification',
                  style: TextStyle(
                    color: const Color.fromARGB(255, 125, 125, 125),
                    fontSize: 13,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 25),
                    Text(
                      'Country',
                      style: TextStyle(fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 5),
                    CustomDropdown(
                      options: ['Nigeria', 'Ghana', 'South Africa'],
                      label: 'Select Country',
                    ),
                    SizedBox(height: 20),
                    Text(
                      'State',
                      style: TextStyle(fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 5),
                    CustomDropdown(
                      options: ['Lagos', 'Abuja', 'Rivers'],
                      label: 'Select State',
                    ),
                  ],
                ),
                SizedBox(height: 30),
                CustomIntroText(text: 'Social Handles'),
                SizedBox(height: 20),
                CustomTextfield(
                  hintText: 'Enter your social media handle',
                  labelText: 'Facebook',
                  labelTextStyle2: true,
                ),
                SizedBox(height: 20),
                CustomTextfield(
                  hintText: 'Enter your social media handle',
                  labelText: 'LinkedIn',
                  labelTextStyle2: true,
                ),
                SizedBox(height: 20),
                CustomTextfield(
                  hintText: 'Enter your social media handle',
                  labelText: 'Instagram',
                  labelTextStyle2: true,
                ),
                SizedBox(height: 20),
                CustomTextfield(
                  hintText: 'Enter your social media handle',
                  labelText: 'X fka Twitter',
                  labelTextStyle2: true,
                ),
                SizedBox(height: 40),
                CustomButton(
                  function: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Plan()),
                    );
                  },
                  widget: Text(
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
          ],
        ),
      ),
    );
  }
}
