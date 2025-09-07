import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/gig_provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/widgets/gig_card/gig_card.dart';

class RecentlyViewedGigsSection extends StatelessWidget {
  const RecentlyViewedGigsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final gigProvider = Provider.of<GigProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    if (userProvider.currentUser == null) {
      return const SizedBox.shrink();
    }

    if (gigProvider.isRecentlyViewedLoading &&
        gigProvider.recentlyViewedGigs.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (gigProvider.recentlyViewedGigs.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(
          child: Text(
            'No recently viewed gigs yet',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      height: 250, // Fixed height for horizontal scroll
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        itemCount: gigProvider.recentlyViewedGigs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final gig = gigProvider.recentlyViewedGigs[index];
          return SizedBox(
            width: 280, // Fixed width for each card
            child: GigCard(gig: gig),
          );
        },
      ),
    );
  }
}
