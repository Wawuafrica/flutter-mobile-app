import 'package:flutter/material.dart';
import 'package:wawu_mobile/models/gig.dart'; // Assuming Review is defined in gig.dart
import 'package:wawu_mobile/utils/constants/colors.dart';

class ReviewComponent extends StatelessWidget {
  final Review review;

  const ReviewComponent({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          width: 0.5,
          color: const Color.fromARGB(255, 181, 181, 181),
        ),
        borderRadius: BorderRadius.circular(10.0),
      ),
      width: double.infinity,
      // height: 100,
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey,
                ),
                child:
                    review.user.profilePicture != null
                        ? Image.network(
                          review.user.profilePicture!,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => Image.asset(
                                'assets/images/other/avatar.webp',
                                fit: BoxFit.cover,
                              ),
                        )
                        : Image.asset(
                          'assets/images/other/avatar.webp',
                          fit: BoxFit.cover,
                        ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.user.fullName),
                    const SizedBox(height: 5.0),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          Icons.star,
                          size: 17,
                          color:
                              index < review.rating
                                  ? wawuColors.primary
                                  : Colors.grey,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Text(
                _formatDate(review.createdAt),
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
          Text(
            review.review,
            style: const TextStyle(
              fontSize: 12,
              overflow: TextOverflow.ellipsis,
            ),
            maxLines: 5,
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }
}
