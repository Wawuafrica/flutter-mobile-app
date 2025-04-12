import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/screens/account_type/account_type.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:wawu_mobile/widgets/custom_intro_bar/custom_intro_bar.dart';
import 'package:wawu_mobile/widgets/custom_textfield/custom_textfield.dart';
import 'provider/user_provider.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  bool isChecked = false;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController referralCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 35.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomIntroBar(
                text: 'Sign Up',
                desc: 'Wanna show off your superpower?  Start here.',
              ),
              CustomTextfield(
                controller: emailController,
                labelText: 'Email Address',
                hintText: 'Enter your email address',
                labelTextStyle2: true,
              ),
              SizedBox(height: 20),
              CustomTextfield(
                controller: firstNameController,
                labelText: 'First Name',
                hintText: 'Enter your first name',
                labelTextStyle2: true,
              ),
              SizedBox(height: 20),
              CustomTextfield(
                controller: lastNameController,
                labelText: 'Last Name',
                hintText: 'Enter your last name',
                labelTextStyle2: true,
              ),
              SizedBox(height: 20),
              CustomTextfield(
                controller: passwordController,
                labelText: 'Password',
                hintText: 'Enter your password',
                labelTextStyle2: true,
              ),
              SizedBox(height: 20),
              CustomTextfield(
                controller: referralCodeController,
                labelText: 'Referral Code',
                hintText: '******',
                labelTextStyle2: true,
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Checkbox(
                    value: isChecked,
                    onChanged: (value) {
                      setState(() {
                        isChecked = value!;
                      });
                    },
                  ),
                  Flexible(
                    child: Text(
                      'Hi superwomen by continuing, you agree to these easy rules to keep us both safe and get you better service',
                      style: TextStyle(fontSize: 13),
                      softWrap: true,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  return CustomButton(
                    function: () {
                      final userData = {
                        'email': emailController.text,
                        'firstName': firstNameController.text,
                        'lastName': lastNameController.text,
                        'password': passwordController.text,
                        'referralCode': referralCodeController.text,
                      };
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AccountType(userData: userData),
                        ),
                      );
                    },
                    widget: Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    color: wawuColors.buttonPrimary,
                    textColor: Colors.white,
                  );
                },
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account?',
                    style: TextStyle(fontSize: 13),
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Login',
                    style: TextStyle(
                      color: wawuColors.buttonSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Container(
                      width: double.infinity,
                      height: 1,
                      color: const Color.fromARGB(255, 209, 209, 209),
                    ),
                  ),
                  Text('Or', style: TextStyle(fontSize: 13)),
                  Flexible(
                    child: Container(
                      width: double.infinity,
                      height: 1,
                      color: const Color.fromARGB(255, 209, 209, 209),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),
              CustomButton(
                border: Border.all(
                  color: const Color.fromARGB(255, 216, 216, 216),
                ),
                widget: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/images/svg/google.svg',
                      width: 20,
                      height: 20,
                    ),
                    Text('Continue with Google'),
                  ],
                ),
                color: Colors.white,
                textColor: Colors.black,
              ),
              SizedBox(height: 10),
              CustomButton(
                border: Border.all(
                  color: const Color.fromARGB(255, 216, 216, 216),
                ),
                widget: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/images/svg/apple.svg',
                      width: 20,
                      height: 20,
                    ),
                    Text('Continue with Apple'),
                  ],
                ),
                color: Colors.white,
                textColor: Colors.black,
              ),
              SizedBox(height: 10),
              CustomButton(
                border: Border.all(
                  color: const Color.fromARGB(255, 216, 216, 216),
                ),
                widget: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/images/svg/facebook.svg',
                      width: 20,
                    ),
                    Text('Continue with Facebook'),
                  ],
                ),
                color: Colors.white,
                textColor: Colors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
