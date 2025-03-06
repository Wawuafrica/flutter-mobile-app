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
        // border: Border.all(color: const Color.fromARGB(255, 217, 217, 217)),
      ),
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment:
            features.isEmpty
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
        spacing: 10.0,
        children: [
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
              ),
              const SizedBox(height: 10),
              Text(desc, style: const TextStyle(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 20),
          if (features.isNotEmpty)
            ...features.map((feature) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Column(
                  children: [
                    Row(
                      spacing: 10,
                      children: [
                        Icon(
                          feature['check'] as bool ? Icons.check : Icons.close,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          feature['text'] as String,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            })
          else
            Center(
              child: const Text(
                'Coming Soon',
                style: TextStyle(
                  color: wawuColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),

          SizedBox(height: 10),

          if (features.isNotEmpty)
            CustomButton(
              function: function,
              widget: Text(
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
