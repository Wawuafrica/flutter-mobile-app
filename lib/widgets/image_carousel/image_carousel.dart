import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';

class ImageTextCarousel extends StatefulWidget {
  const ImageTextCarousel({super.key});

  @override
  _ImageTextCarouselState createState() => _ImageTextCarouselState();
}

final List<Map<String, String>> carouselItems = [
  {
    'image': 'assets/images/onboarding_images/oi1.png',
    'text': 'Welcome to Wawu Mobile!',
  },
  {
    'image': 'assets/images/onboarding_images/oi2.png',
    'text': 'Explore amazing features.',
  },
  {
    'image': 'assets/images/onboarding_images/oi3.png',
    'text': 'Get started now!',
  },
];

class _ImageTextCarouselState extends State<ImageTextCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Carousel Slider
        CarouselSlider(
          items:
              carouselItems.map((item) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(item['image']!, height: 200, fit: BoxFit.cover),
                    const SizedBox(height: 20),
                    Text(
                      item['text']!,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }).toList(),
          options: CarouselOptions(
            height: 300,
            autoPlay: true,
            enlargeCenterPage: true,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),
        const SizedBox(height: 20),
        // Page Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children:
              carouselItems.map((item) {
                int index = carouselItems.indexOf(item);
                return Container(
                  width: 30,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(10),
                    color:
                        _currentIndex == index
                            ? wawuColors.borderPrimary
                            : Colors.grey,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}
