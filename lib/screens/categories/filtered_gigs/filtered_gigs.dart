import 'package:flutter/material.dart';

class FilteredGigs extends StatelessWidget {
  const FilteredGigs({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Search Digital Marketing')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: ListView(
          children: [
            // GigCard(),
            Text('GigCards'),
            SizedBox(height: 10),
            // GigCard(),
            SizedBox(height: 10),
            // GigCard(),
            SizedBox(height: 10),
            // GigCard(),
            SizedBox(height: 10),
            // GigCard(),
            SizedBox(height: 10),
            // GigCard(),
            SizedBox(height: 10),
            // GigCard(),
            SizedBox(height: 10),
            // GigCard(),
            SizedBox(height: 10),
            // GigCard(),
            SizedBox(height: 10),
            // GigCard(),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
