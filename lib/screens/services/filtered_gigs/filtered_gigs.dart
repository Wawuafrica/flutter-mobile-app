import 'package:flutter/material.dart';
import 'package:wawu_mobile/widgets/gig_card/gig_card.dart';

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
