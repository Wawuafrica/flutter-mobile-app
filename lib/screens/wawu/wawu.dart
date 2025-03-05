import 'package:flutter/material.dart';
import 'package:wawu_mobile/screens/wawu_africa/wawu_africa.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_intro_bar/custom_intro_bar.dart';

class Wawu extends StatelessWidget {
  const Wawu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            SizedBox(height: 10),
            CustomIntroBar(
              text: 'Welcome To Wawu Mobile',
              desc: 'The world of possibilities',
            ),
            Expanded(
              flex: 5,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => WawuAfrica()),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: wawuColors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color.fromARGB(255, 210, 210, 210),
                    ),
                  ),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Wawu Africa',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        flex: 1,
                        child: Image.asset(
                          'assets/images/onboarding_images/oi1.png',
                          width: 150,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'This is just a dummy text, Content will be uploaded soon',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                          // fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              flex: 5,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => WawuAfrica()),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: wawuColors.primaryBackground,
                    borderRadius: BorderRadius.circular(10),
                    // border: Border.all(
                    //   color: const Color.fromARGB(255, 210, 210, 210),
                    // ),
                  ),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Wawu Marketplace',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        flex: 1,
                        child: Image.asset(
                          'assets/images/onboarding_images/oi2.png',
                          width: 150,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'This is just a dummy text, Content will be uploaded soon',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          // fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
