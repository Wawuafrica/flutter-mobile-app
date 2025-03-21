import 'package:flutter/material.dart';
import 'package:wawu_mobile/screens/services/filtered_gigs/filtered_gigs.dart';
import 'package:wawu_mobile/screens/services/services.dart';
import 'package:wawu_mobile/screens/wawu_ecommerce_screen/wawu_ecommerce_screen.dart';
import 'package:wawu_mobile/widgets/custom_intro_text/custom_intro_text.dart';
import 'package:wawu_mobile/widgets/e_card/e_card.dart';
import 'package:wawu_mobile/widgets/fading_carousel/fading_carousel.dart';
import 'package:wawu_mobile/widgets/gig_card/gig_card.dart';
import 'package:wawu_mobile/widgets/image_text_card/image_text_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Example list of dynamically styled widgets
    final List<Widget> carouselItems = [
      Container(
        decoration: BoxDecoration(color: Colors.red.withAlpha(100)),
        child: Center(
          child: Text('Gig Of The Day', style: TextStyle(fontSize: 20)),
        ),
      ),
      Container(
        decoration: BoxDecoration(color: Colors.green.withAlpha(100)),
        child: Center(
          child: Text('Adevertisement', style: TextStyle(fontSize: 20)),
        ),
      ),
      Container(
        decoration: BoxDecoration(color: Colors.blue.withAlpha(100)),
        child: Center(child: Text('Blog Post', style: TextStyle(fontSize: 20))),
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
            CustomIntroText(
              text: 'Popular Services',
              isRightText: true,
              navFunction: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Services()),
                );
              },
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 160,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ImageTextCard(
                    function: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => FilteredGigs()),
                      );
                    },
                    text: 'Graphics & Design',
                    asset: 'assets/images/section/graphics.png',
                  ),
                  ImageTextCard(
                    function: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => FilteredGigs()),
                      );
                    },
                    text: 'Programming',
                    asset: 'assets/images/section/programming.png',
                  ),
                  ImageTextCard(
                    function: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => FilteredGigs()),
                      );
                    },
                    text: 'Video & Animation',
                    asset: 'assets/images/section/video.png',
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            CustomIntroText(
              text: 'Wawu E-commerce',
              isRightText: true,
              navFunction: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WawuEcommerceScreen(),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 220,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [ECard(), ECard(), ECard()],
              ),
            ),
            SizedBox(height: 40),
            CustomIntroText(text: 'Recently Viewed'),
            SizedBox(height: 20),
            GigCard(),
            SizedBox(height: 10),
            GigCard(),
            SizedBox(height: 10),
            GigCard(),
            SizedBox(height: 10),
            GigCard(),
            SizedBox(height: 10),
            GigCard(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
