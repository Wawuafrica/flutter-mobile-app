import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Frequently Asked Questions')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            // MODIFIED: Replaced old FAQs with the new content
            _buildFAQItem(
              context: context,
              question: 'What is WAWUAfrica',
              answer: const Text(
                'Women at Work Universal (WAWUAfrica) is a Pan-African platform whose name takes inspiration from "WOW." Its mission is to empower women by creating a safe, inclusive, and supportive environment. The platform helps women gain visibility, develop skills through learning, connect with clients, and grow their businesses to ensure they are fairly compensated for their work.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
            const Divider(),
            _buildFAQItem(
              context: context,
              question: 'Who can join WAWUAfrica',
              answer: const Text(
                'WAWUAfrica is a community focused on women, including women communities, organizations, freelancers, artisans, entrepreneurs, and professionals. We also welcome male allies and organizations that support women\'s economic empowerment to join as clients, buyers, or partners.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
            const Divider(),
            _buildFAQItem(
              context: context,
              question: 'Are there fees?',
              answer: const Text(
                'Yes, users pay a one-time annual or monthly fee to register. This payment is taken to maintain the platform, provide customer support, and fund empowerment programs for women.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem({
    required String question,
    required Widget? answer,
    required BuildContext context,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          question,
          style: TextStyle(
            fontSize: 15, // MODIFIED: Reduced from 16
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.all(0),
        childrenPadding: const EdgeInsets.only(left: 0, right: 0, bottom: 16),
        iconColor: Colors.grey[600],
        collapsedIconColor: Colors.grey[600],
        shape: const Border(),
        collapsedShape: const Border(),
        children: answer != null ? [answer] : [const SizedBox.shrink()],
      ),
    );
  }

  // REMOVED: The _buildBulletPoint method is no longer needed.
}
