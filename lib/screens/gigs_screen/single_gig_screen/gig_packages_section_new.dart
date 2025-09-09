import 'package:flutter/material.dart';
import 'package:wawu_mobile/models/gig.dart';

class GigPackagesSectionNew extends StatelessWidget {
  final Gig gig;
  const GigPackagesSectionNew({super.key, required this.gig});

  @override
  Widget build(BuildContext context) {
    if (gig.pricings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Packages',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...gig.pricings.map((pricing) => _buildPackageCard(pricing)).toList(),
      ],
    );
  }

  Widget _buildPackageCard(Pricing pricing) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(255, 255, 255, 255).withOpacity(0.8),
            Colors.purple.shade100.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.purple.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                pricing.package.name,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                '₦${pricing.package.amount}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.purple),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...pricing.features.map((feature) => _buildFeatureRow(feature)),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(Feature feature) {
    final value = feature.value.toLowerCase();
    final bool isYes = value == 'yes';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(feature.name, style: TextStyle(color: Colors.grey.shade800)),
          isYes
              ? const Icon(Icons.check, color: Colors.purple, size: 18)
              : Text(
                  value == 'no' ? '-' : feature.value,
                  style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold),
                ),
        ],
      ),
    );
  }
}

