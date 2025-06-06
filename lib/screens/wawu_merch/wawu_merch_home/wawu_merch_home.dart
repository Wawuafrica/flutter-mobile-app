import 'package:flutter/material.dart';
import 'package:wawu_mobile/widgets/custom_intro_text/custom_intro_text.dart';
import 'package:wawu_mobile/widgets/e_card/e_card.dart';
import 'package:wawu_mobile/widgets/fading_carousel/fading_carousel.dart';

class WawuMerchHome extends StatelessWidget {
  const WawuMerchHome({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Widget> carouselItems = [
      Container(
        decoration: BoxDecoration(color: Colors.red.withAlpha(100)),
        child: Center(child: Text('Merch', style: TextStyle(fontSize: 20))),
      ),
      Container(
        decoration: BoxDecoration(color: Colors.green.withAlpha(100)),
        child: Center(
          child: Text('Adevertisement', style: TextStyle(fontSize: 20)),
        ),
      ),
      Container(
        decoration: BoxDecoration(color: Colors.blue.withAlpha(100)),
        child: Center(child: Text('Merch', style: TextStyle(fontSize: 20))),
      ),
    ];

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: ListView(
          children: [
            SizedBox(height: 20),
            CustomIntroText(text: 'Updates'),
            SizedBox(height: 20),
            FadingCarousel(height: 250, children: carouselItems),
            SizedBox(height: 20),
            CustomIntroText(text: 'Wawu-Merch'),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 10.0,
              children: [
                // Expanded(child: ECard(isMargin: false)),
                // Expanded(child: ECard(isMargin: false)),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 10.0,
              children: [
                // Expanded(child: ECard(isMargin: false)),
                // Expanded(child: ECard(isMargin: false)),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 10.0,
              children: [
                // Expanded(child: ECard(isMargin: false)),
                // Expanded(child: ECard(isMargin: false)),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 10.0,
              children: [
                // Expanded(child: ECard(isMargin: false)),
                // Expanded(child: ECard(isMargin: false)),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 10.0,
              children: [
                // Expanded(child: ECard(isMargin: false)),
                // Expanded(child: ECard(isMargin: false)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
