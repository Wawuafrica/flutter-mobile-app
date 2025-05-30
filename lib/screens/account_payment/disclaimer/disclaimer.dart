import 'package:flutter/material.dart';
import 'package:wawu_mobile/screens/main_screen/main_screen.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';

class Disclaimer extends StatelessWidget {
  const Disclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Disclaimer')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: wawuColors.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Image.asset('assets/images/other/book.webp'),
              ),
            ),
            SizedBox(height: 30),
            Text(
              "Hey, so WawuAfrica helps women connect and find opportunities, but we're not liable for any financial losses, damage, or scams that may happen on our site.  Your safety's important to us; be careful, double-check things, and be smart about transactions.  Use secure payment methods and don't visit strangers or  share private info.",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
            ),
            SizedBox(height: 20),
            Text(
              "Using WawAfrica means you've read this, and you're taking the risk yourself",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
            ),
            SizedBox(height: 30),
            CustomButton(
              widget: Text(
                'Proceed To Wawu',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              color: wawuColors.primary,
              function: () {
                Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (context) => MainScreen()),
  (Route<dynamic> route) => false,
);
              },
            ),
          ],
        ),
      ),
    );
  }
}
