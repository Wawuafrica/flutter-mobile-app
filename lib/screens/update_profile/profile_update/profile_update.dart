import 'package:flutter/material.dart';
import 'package:wawu_mobile/screens/plan/plan.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:wawu_mobile/widgets/custom_dropdown/custom_dropdown.dart';
import 'package:wawu_mobile/widgets/custom_intro_text/custom_intro_text.dart';
import 'package:wawu_mobile/widgets/custom_textfield/custom_textfield.dart';
import 'package:wawu_mobile/widgets/upload_image/upload_image.dart';

class ProfileUpdate extends StatefulWidget {
  const ProfileUpdate({super.key});

  @override
  State<ProfileUpdate> createState() => _ProfileUpdateState();
}

class _ProfileUpdateState extends State<ProfileUpdate> {
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _skillController = TextEditingController();
  final List<String> _skills = [];
  final int _maxAboutLength = 200;
  String? selectedCertificateValue;

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
      appBar: AppBar(title: Text('Profile'), centerTitle: true),
      body: ListView(
        children: [
          Container(
            padding: EdgeInsets.all(20.0),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 100,
                      padding: EdgeInsets.all(20.0),
                      color: wawuColors.primary.withAlpha(50),
                      child: Text(
                        'Add Cover Photo',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Positioned(
                      top: 50,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipOval(
                              child: Container(
                                width: 100,
                                height: 100,
                                color: Colors.white,
                                child: Image.asset(
                                  'assets/images/other/avatar.png',
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
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
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 70),
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
                    'Save',
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
        ],
      ),
    );
  }
}
