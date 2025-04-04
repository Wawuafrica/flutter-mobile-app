import 'package:flutter/material.dart';
import 'package:wawu_mobile/screens/services/filtered_gigs/filtered_gigs.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';

class ServiceDetailed extends StatelessWidget {
  const ServiceDetailed({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Digital Marketting')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: ListView(
          children: [
            Container(
              padding: EdgeInsets.all(20.0),
              height: 100,
              decoration: BoxDecoration(color: wawuColors.purpleDarkContainer),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Digital Marketing',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 0.5),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor:
                      Colors.transparent, // This removes the divider line
                ),
                child: ExpansionTile(
                  title: Text('Search'),
                  childrenPadding: EdgeInsets.only(
                    left: 0,
                    right: 0,
                    bottom: 16,
                  ),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 10.0,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FilteredGigs(),
                                ),
                              );
                            },
                            child: Text(
                              'Search Engine Optimization (SEO)',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FilteredGigs(),
                                ),
                              );
                            },
                            child: Text(
                              'Search Engine Marketing (SEM)',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FilteredGigs(),
                                ),
                              );
                            },
                            child: Text(
                              'E-Commerce SEOs',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FilteredGigs(),
                                ),
                              );
                            },
                            child: Text(
                              'Local SEOs',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FilteredGigs(),
                                ),
                              );
                            },
                            child: Text(
                              'Video SEOs',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 0.5),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor:
                      Colors.transparent, // This removes the divider line
                ),
                child: ExpansionTile(
                  title: Text('Search'),
                  childrenPadding: EdgeInsets.only(
                    left: 0,
                    right: 0,
                    bottom: 16,
                  ),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 10.0,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FilteredGigs(),
                                ),
                              );
                            },
                            child: Text(
                              'Search Engine Optimization (SEO)',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FilteredGigs(),
                                ),
                              );
                            },
                            child: Text(
                              'Search Engine Marketing (SEM)',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FilteredGigs(),
                                ),
                              );
                            },
                            child: Text(
                              'E-Commerce SEOs',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FilteredGigs(),
                                ),
                              );
                            },
                            child: Text(
                              'Local SEOs',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FilteredGigs(),
                                ),
                              );
                            },
                            child: Text(
                              'Video SEOs',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 0.5),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor:
                      Colors.transparent, // This removes the divider line
                ),
                child: ExpansionTile(
                  title: Text('Search'),
                  childrenPadding: EdgeInsets.only(
                    left: 0,
                    right: 0,
                    bottom: 16,
                  ),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 10.0,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FilteredGigs(),
                                ),
                              );
                            },
                            child: Text(
                              'Search Engine Optimization (SEO)',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FilteredGigs(),
                                ),
                              );
                            },
                            child: Text(
                              'Search Engine Marketing (SEM)',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FilteredGigs(),
                                ),
                              );
                            },
                            child: Text(
                              'E-Commerce SEOs',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FilteredGigs(),
                                ),
                              );
                            },
                            child: Text(
                              'Local SEOs',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FilteredGigs(),
                                ),
                              );
                            },
                            child: Text(
                              'Video SEOs',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 0.5),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor:
                      Colors.transparent, // This removes the divider line
                ),
                child: ExpansionTile(
                  title: Text('Search'),
                  childrenPadding: EdgeInsets.only(
                    left: 0,
                    right: 0,
                    bottom: 16,
                  ),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 10.0,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FilteredGigs(),
                                ),
                              );
                            },
                            child: Text(
                              'Search Engine Optimization (SEO)',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FilteredGigs(),
                                ),
                              );
                            },
                            child: Text(
                              'Search Engine Marketing (SEM)',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FilteredGigs(),
                                ),
                              );
                            },
                            child: Text(
                              'E-Commerce SEOs',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FilteredGigs(),
                                ),
                              );
                            },
                            child: Text(
                              'Local SEOs',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FilteredGigs(),
                                ),
                              );
                            },
                            child: Text(
                              'Video SEOs',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 0.5),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor:
                      Colors.transparent, // This removes the divider line
                ),
                child: ExpansionTile(
                  title: Text('Search'),
                  childrenPadding: EdgeInsets.only(
                    left: 0,
                    right: 0,
                    bottom: 16,
                  ),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 10.0,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FilteredGigs(),
                                ),
                              );
                            },
                            child: Text(
                              'Search Engine Optimization (SEO)',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FilteredGigs(),
                                ),
                              );
                            },
                            child: Text(
                              'Search Engine Marketing (SEM)',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FilteredGigs(),
                                ),
                              );
                            },
                            child: Text(
                              'E-Commerce SEOs',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FilteredGigs(),
                                ),
                              );
                            },
                            child: Text(
                              'Local SEOs',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FilteredGigs(),
                                ),
                              );
                            },
                            child: Text(
                              'Video SEOs',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
