import 'package:flutter/material.dart';
import 'package:wawu_mobile/screens/update_profile/profile_update/profile_update.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';

class UpdateProfile extends StatelessWidget {
  const UpdateProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Update Profile')),
      body: Container(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(10.0),
              width: double.infinity,
              height: 350,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: wawuColors.primaryBackground.withOpacity(0.2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(shape: BoxShape.circle),
                    child: Image.asset(
                      'assets/images/other/avatar.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Mavis Nwaokorie',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Buyer',
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color.fromARGB(255, 125, 125, 125),
                      fontWeight: FontWeight.w200,
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
                ],
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Hey Superwoman,  being a pro on WawuAfrica means awesome and fun stuff.  Your skills are a game-changer! But you gotta update your profile so clients can find you faster.',
              style: TextStyle(
                fontSize: 13,
                color: const Color.fromARGB(255, 125, 125, 125),
                fontWeight: FontWeight.w200,
              ),
            ),

            Text(
              "We're so proud to have you! Have fun, make some cash, and stay safe.",
              style: TextStyle(
                fontSize: 13,
                color: const Color.fromARGB(255, 125, 125, 125),
                fontWeight: FontWeight.w200,
              ),
            ),

            SizedBox(height: 30),
            CustomButton(
              function: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileUpdate()),
                );
              },
              widget: Text(
                'Update Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              color: wawuColors.buttonPrimary,
              textColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
