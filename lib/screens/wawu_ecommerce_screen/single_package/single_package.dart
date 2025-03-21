import 'package:flutter/material.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:wawu_mobile/widgets/custom_intro_text/custom_intro_text.dart';
import 'package:wawu_mobile/widgets/e_card/e_card.dart';
import 'package:wawu_mobile/widgets/fading_carousel/fading_carousel.dart';

class SinglePackage extends StatelessWidget {
  const SinglePackage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Widget> carouselItems = [
      Container(
        decoration: BoxDecoration(color: Colors.red.withAlpha(0)),
        child: Image.asset(
          'assets/images/section/video.png',
          fit: BoxFit.cover,
        ),
      ),
      Container(
        decoration: BoxDecoration(color: Colors.red.withAlpha(0)),
        child: Image.asset(
          'assets/images/section/video.png',
          fit: BoxFit.cover,
        ),
      ),
      Container(
        decoration: BoxDecoration(color: Colors.red.withAlpha(0)),
        child: Image.asset(
          'assets/images/section/video.png',
          fit: BoxFit.cover,
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Package Name')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: ListView(
          children: [
            FadingCarousel(height: 180, children: carouselItems),
            SizedBox(height: 20),
            Text(
              'NIKE SNEAKERS',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: wawuColors.primary,
              ),
            ),
            SizedBox(height: 5),
            Text('Vision Alta Men’s Shoes Size'),
            SizedBox(height: 10),
            Row(
              spacing: 10.0,
              children: [
                Text(
                  '\$2,500',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                ),
                Text(
                  '\$5,000',
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 13,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                Text(
                  '50% off',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: wawuColors.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            SizedBox(height: 40, child: _buildSelectorContext()),
            SizedBox(height: 20),
            CustomIntroText(text: 'Product Details'),
            SizedBox(height: 10),
            Text(
              'Perhaps the most iconic sneaker of all-time, this original "Chicago"? colorway is the cornerstone to Jordan, the shoe has stood the test of time, becoming the most famous colorway of the Air Jordan 1. This 2015 release saw the',
            ),
            SizedBox(height: 20),
            CustomButton(
              widget: Text('Buy Now', style: TextStyle(color: Colors.white)),
              color: wawuColors.primary,
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: wawuColors.primary.withAlpha(50),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Delivery In'),
                  Text(
                    '48 Hours',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            SizedBox(height: 40),
            CustomIntroText(text: 'Similar To'),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 10.0,
              children: [
                Expanded(child: ECard(isMargin: false)),
                Expanded(child: ECard(isMargin: false)),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 10.0,
              children: [
                Expanded(child: ECard(isMargin: false)),
                Expanded(child: ECard(isMargin: false)),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorContext() {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        Container(
          padding: EdgeInsets.all(10.0),
          margin: EdgeInsets.symmetric(horizontal: 5.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: wawuColors.primary),
            color: wawuColors.primary,
          ),
          child: Center(
            child: Text(
              '5 UK',
              style: TextStyle(fontSize: 11, color: Colors.white),
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(10.0),
          margin: EdgeInsets.symmetric(horizontal: 5.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: wawuColors.primary),
          ),
          child: Center(child: Text('5 UK', style: TextStyle(fontSize: 11))),
        ),
        Container(
          padding: EdgeInsets.all(10.0),
          margin: EdgeInsets.symmetric(horizontal: 5.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: wawuColors.primary),
          ),
          child: Center(child: Text('5 UK', style: TextStyle(fontSize: 11))),
        ),
        Container(
          padding: EdgeInsets.all(10.0),
          margin: EdgeInsets.symmetric(horizontal: 5.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: wawuColors.primary),
          ),
          child: Center(child: Text('5 UK', style: TextStyle(fontSize: 11))),
        ),
        Container(
          padding: EdgeInsets.all(10.0),
          margin: EdgeInsets.symmetric(horizontal: 5.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: wawuColors.primary),
          ),
          child: Center(child: Text('5 UK', style: TextStyle(fontSize: 11))),
        ),
        Container(
          padding: EdgeInsets.all(10.0),
          margin: EdgeInsets.symmetric(horizontal: 5.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: wawuColors.primary),
          ),
          child: Center(child: Text('5 UK', style: TextStyle(fontSize: 11))),
        ),
      ],
    );
  }
}
