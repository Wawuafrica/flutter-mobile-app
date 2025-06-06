import 'package:flutter/material.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';

class PlanCard extends StatelessWidget {
  final String heading;
  final String desc;
  final double width;
  final List<Map<String, dynamic>> features;
  final GestureTapCallback? function;

  const PlanCard({
    super.key,
    required this.heading,
    required this.desc,
    this.features = const [],
    this.width = 300,
    this.function,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: wawuColors.primary.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment:
            features.isEmpty
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Allow dynamic height
        children: [
          // Header section
          Column(
            crossAxisAlignment:
                features.isEmpty
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
            children: [
              Text(
                heading,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign:
                    features.isEmpty ? TextAlign.center : TextAlign.start,
              ),
              const SizedBox(height: 10),
              Text(
                desc,
                style: const TextStyle(fontSize: 13),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign:
                    features.isEmpty ? TextAlign.center : TextAlign.start,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Features section
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (features.isNotEmpty)
                    ...features.map((feature) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              feature['check'] as bool
                                  ? Icons.check
                                  : Icons.close,
                              size: 20,
                              color:
                                  feature['check'] as bool
                                      ? Colors.green
                                      : Colors.red,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                feature['text'] as String,
                                style: const TextStyle(fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    })
                  else
                    const Center(
                      child: Text(
                        'Coming Soon',
                        style: TextStyle(
                          color: wawuColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Button section
          const SizedBox(height: 15),
          if (features.isNotEmpty)
            CustomButton(
              function: function,
              widget: const Text(
                'Continue',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              color: wawuColors.primary,
              textColor: Colors.white,
            ),
        ],
      ),
    );
  }
}
