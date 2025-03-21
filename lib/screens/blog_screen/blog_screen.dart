import 'package:flutter/material.dart';
import 'package:wawu_mobile/screens/blog_screen/single_blog_screen/single_blog_screen.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_intro_text/custom_intro_text.dart';
import 'package:wawu_mobile/widgets/fading_carousel/fading_carousel.dart';
import 'package:wawu_mobile/widgets/filterable_widget/filterable_widget.dart';

class BlogScreen extends StatelessWidget {
  BlogScreen({super.key});

  // Simulated backend data
  final List<Map<String, String>> backendData = [
    {'title': 'Widget 1', 'description': 'Description 1', 'category': 'Wawu'},
    {
      'title': 'Widget 2',
      'description': 'Description 2',
      'category': 'Updates',
    },
    {
      'title': 'Widget 3',
      'description': 'Description 3',
      'category': 'Business',
    },
    {
      'title': 'Widget 3',
      'description': 'Description 3',
      'category': 'Business',
    },
    {
      'title': 'Widget 3',
      'description': 'Description 3',
      'category': 'Business',
    },
    {
      'title': 'Widget 3',
      'description': 'Description 3',
      'category': 'Business',
    },
    {
      'title': 'Widget 3',
      'description': 'Description 3',
      'category': 'Business',
    },
    {
      'title': 'Widget 3',
      'description': 'Description 3',
      'category': 'Business',
    },
    {
      'title': 'Widget 3',
      'description': 'Description 3',
      'category': 'Business',
    },
    {
      'title': 'Widget 3',
      'description': 'Description 3',
      'category': 'Business',
    },
    {'title': 'Widget 4', 'description': 'Description 4', 'category': 'Wawu'},
  ];

  @override
  Widget build(BuildContext context) {
    final List<Widget> carouselItems = [
      Container(
        decoration: BoxDecoration(color: Colors.red.withAlpha(100)),
        child: Center(
          child: Text('Blog Update', style: TextStyle(fontSize: 20)),
        ),
      ),
      Container(
        decoration: BoxDecoration(color: Colors.green.withAlpha(100)),
        child: Center(
          child: Text('Blog Update', style: TextStyle(fontSize: 20)),
        ),
      ),
      Container(
        decoration: BoxDecoration(color: Colors.blue.withAlpha(100)),
        child: Center(
          child: Text('Blog Update', style: TextStyle(fontSize: 20)),
        ),
      ),
    ];

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 20),
              CustomIntroText(text: 'Latest Today'),
              SizedBox(height: 10),
              FadingCarousel(children: carouselItems),
              SizedBox(height: 20),

              FilterableWidgetList(
                widgets: backendData,
                filterOptions: ['All', 'Wawu', 'Updates', 'Business'],
                itemBuilder: (widgetData) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SingleBlogScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 90,
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      child: Row(
                        spacing: 10.0,
                        children: [
                          Image.asset(
                            'assets/images/section/video.png',
                            width: 80,
                            // height: 80,
                            fit: BoxFit.cover,
                          ),
                          Expanded(
                            child: Column(
                              spacing: 8.0,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt...',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                                Row(
                                  spacing: 5.0,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 25,
                                      decoration: BoxDecoration(
                                        color: wawuColors.primary.withAlpha(70),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Center(
                                        child: Text(
                                          widgetData['title'] ?? '',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: wawuColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 50,
                                      height: 25,
                                      decoration: BoxDecoration(
                                        color: wawuColors.primary.withAlpha(70),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.thumb_up_alt,
                                            size: 10,
                                            color: wawuColors.primary,
                                          ),
                                          Text(
                                            '2K',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: wawuColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 50,
                                      height: 25,
                                      decoration: BoxDecoration(
                                        color: wawuColors.primary.withAlpha(70),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.mode_comment,
                                            size: 10,
                                            color: wawuColors.primary,
                                          ),
                                          Text(
                                            '1.1K',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: wawuColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
