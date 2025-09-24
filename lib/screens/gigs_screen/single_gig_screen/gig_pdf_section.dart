import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wawu_mobile/models/gig.dart';

class GigPdfSection extends StatelessWidget {
  final Gig gig;
  const GigPdfSection({super.key, required this.gig});

  Future<void> _launchUrl(String urlString, BuildContext context) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open the document: $urlString')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pdfLink = gig.assets.pdf?.link;
    if (pdfLink == null || pdfLink.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Documents',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => _launchUrl(pdfLink, context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf_rounded, color: Colors.purple, size: 30),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    gig.assets.pdf?.name ?? 'View Document',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                const Icon(Icons.open_in_new_rounded, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}