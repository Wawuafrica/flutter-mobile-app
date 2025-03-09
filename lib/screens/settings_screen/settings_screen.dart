import 'package:flutter/material.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_row_single_column/custom_row_single_column.dart';
import 'package:wawu_mobile/widgets/settings_button_card/settings_button_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: ListView(
          children: [
            SizedBox(height: 20),
            Container(width: double.infinity, height: 100, color: Colors.black),
            SizedBox(
              height: 50,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: -50,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Image.asset(
                        'assets/images/other/avatar.png',
                        width: 100,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Mavis Greene',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: wawuColors.primary,
              ),
              padding: EdgeInsets.all(30.0),
              child: Column(
                children: [
                  Expanded(
                    child: CustomRowSingleColumn(
                      leftText: 'Subscription Plan',
                      leftTextStyle: TextStyle(
                        color: wawuColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      rightText: 'Wawu Standard',
                      rightTextStyle: TextStyle(
                        color: wawuColors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: CustomRowSingleColumn(
                      leftText: 'One Month Plan',
                      leftTextStyle: TextStyle(
                        color: wawuColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      rightText: '28 Days Left',
                      rightTextStyle: TextStyle(
                        color: wawuColors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  SizedBox(height: 25),
                  Expanded(
                    child: CustomRowSingleColumn(
                      leftText: 'Upgrade Plan',
                      leftTextStyle: TextStyle(
                        color: wawuColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      rightText: '',
                      rightTextStyle: TextStyle(
                        color: wawuColors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            SettingsButtonCard(title: 'My Profile'),
            SettingsButtonCard(title: 'Checkout Details'),
            SettingsButtonCard(title: 'FAQ'),
            SettingsButtonCard(title: 'Invite People'),
            SettingsButtonCard(title: 'Contact Us'),
            SettingsButtonCard(title: 'About Us'),
            SettingsButtonCard(title: 'Terms of Use'),
            SizedBox(height: 40),
            Center(
              child: Text(
                'Log Out',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 10),
            Center(
              child: Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: const Color.fromARGB(255, 212, 212, 212),
                  fontSize: 12,
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
