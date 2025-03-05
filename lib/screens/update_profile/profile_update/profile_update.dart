import 'package:flutter/material.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';

class ProfileUpdate extends StatelessWidget {
  const ProfileUpdate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile'), centerTitle: true),
      body: Container(
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
                  child: Text('Add Cover Photo', textAlign: TextAlign.center),
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
                              color: const Color.fromARGB(255, 219, 219, 219),
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
                Icon(Icons.check_circle, size: 15, color: wawuColors.primary),
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
    );
  }
}
