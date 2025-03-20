import 'package:flutter/material.dart';
import 'package:wawu_mobile/screens/gigs_screen/create_gig_screen/create_gig_screen.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/filterable_widget/filterable_widget.dart';
import 'package:wawu_mobile/widgets/gig_card/gig_card.dart';

class GigsScreen extends StatelessWidget {
  GigsScreen({super.key});

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
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: ListView(
          children: [
            SizedBox(height: 20),

            FilterableWidgetList(
              isStyle2: false,
              widgets: backendData,
              filterOptions: ['All', 'Achived', 'Verified', 'Trash'],
              itemBuilder: (widgetData) {
                return GigCard();
              },
            ),
          ],
        ),
      ),

      floatingActionButton: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateGigScreen()),
          );
        },
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: wawuColors.primary,
          ),
          child: Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
