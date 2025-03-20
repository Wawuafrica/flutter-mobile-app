import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Frequently Asked Questions')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            _buildFAQItem(
              context: context,
              question: 'What is Wawu?',
              answer: null,
            ),
            Divider(),
            _buildFAQItem(
              context: context,
              question: 'Who can join Wawu?',
              answer: null,
            ),
            Divider(),
            _buildFAQItem(
              context: context,
              question: 'Services can I offer on Wawu',
              answer: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You can offer a wide range of services, including but not limited to:',
                  ),
                  SizedBox(height: 8),
                  _buildBulletPoint('Writing and Content Creation'),
                  _buildBulletPoint('Graphic Design and Illustration'),
                  _buildBulletPoint('Web Development and Programming'),
                  _buildBulletPoint('Social Media Management'),
                  _buildBulletPoint('Virtual Assistant'),
                  _buildBulletPoint('Marketing and SEO'),
                  _buildBulletPoint('Coaching, Consulting, and Mentorship'),
                  _buildBulletPoint('Administrative Support'),
                  _buildBulletPoint('And more!'),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Was this helpful'),
                      SizedBox(width: 16),
                      _buildHelpfulCheckbox(),
                      SizedBox(width: 8),
                      _buildHelpfulCheckbox(),
                    ],
                  ),
                ],
              ),
            ),
            Divider(),
            _buildFAQItem(
              context: context,
              question: 'How do I find work on Wawu?',
              answer: null,
            ),
            Divider(),
            _buildFAQItem(
              context: context,
              question: 'How does the payment process work?',
              answer: null,
            ),
            Divider(),
            _buildFAQItem(
              context: context,
              question: 'How do I get paid?',
              answer: null,
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
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent, // This removes the divider line
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        initiallyExpanded: false,
        tilePadding: EdgeInsets.zero, // Remove default padding
        childrenPadding: EdgeInsets.only(
          left: 0,
          right: 0,
          bottom: 16,
        ), // Adjust padding
        iconColor: Colors.grey[600], // Customize the expand/collapse icon color
        collapsedIconColor:
            Colors.grey[600], // Customize the collapsed icon color
        shape: Border(), // Remove the border
        collapsedShape: Border(), // Remove the collapsed border
        children: answer != null ? [answer] : [SizedBox.shrink()],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text, style: TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildHelpfulCheckbox() {
    return Checkbox(
      value: false,
      onChanged: (value) {},
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
