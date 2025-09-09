import 'package:flutter/material.dart';
import 'package:wawu_mobile/models/gig.dart';

class GigFaqSectionNew extends StatelessWidget {
  final Gig gig;
  const GigFaqSectionNew({super.key, required this.gig});

  @override
  Widget build(BuildContext context) {
    if (gig.faqs.isEmpty) {
      return const SizedBox.shrink();
    }
    return ExpansionTile(
      title: const Text(
        'Frequently Asked Questions',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(top: 8),
      children: gig.faqs.map((faq) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          margin: const EdgeInsets.only(bottom: 12.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                faq.attributes.isNotEmpty ? faq.attributes[0].question : 'No question',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                faq.attributes.isNotEmpty ? faq.attributes[0].answer : 'No answer',
                style: TextStyle(color: Colors.grey.shade700, height: 1.5),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
