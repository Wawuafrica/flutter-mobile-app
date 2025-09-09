import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/models/gig.dart';
import 'package:wawu_mobile/providers/gig_provider.dart';

class GigReviewsSectionNew extends StatelessWidget {
  final Gig gig;
  const GigReviewsSectionNew({super.key, required this.gig});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${gig.reviews.length} Reviews',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            // TextButton(
            //   onPressed: () {},
            //   child: const Text('See All'),
            // ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: gig.reviews.length,
            itemBuilder: (context, index) {
              return _buildReviewCard(gig.reviews[index]);
            },
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          icon: const Icon(Icons.edit),
          label: const Text('Write a Review'),
          onPressed: () => _showReviewModal(context, gig.uuid),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.purple,
            side: const BorderSide(color: Colors.purple),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(Review review) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: review.user.profilePicture ?? '',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorWidget: (c, u, e) => Image.asset(
                      'assets/images/other/avatar.webp',
                      fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.user.fullName,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(Icons.star,
                            size: 16,
                            color: i < review.rating
                                ? Colors.amber
                                : Colors.grey.shade300),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.review,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  void _showReviewModal(BuildContext context, String gigUuid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _ReviewForm(gigUuid: gigUuid),
      ),
    );
  }
}

class _ReviewForm extends StatefulWidget {
  final String gigUuid;
  const _ReviewForm({required this.gigUuid});

  @override
  State<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<_ReviewForm> {
  final _reviewController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _selectedRating = 0;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Rate This Gig',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () => setState(() => _selectedRating = index + 1),
                  icon: Icon(
                    Icons.star,
                    color: index < _selectedRating
                        ? Colors.amber
                        : Colors.grey.shade300,
                    size: 32,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reviewController,
              decoration: const InputDecoration(
                hintText: 'Write your review...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Review cannot be empty' : null,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit Review',
                      style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _submitReview() async {
    if (!_formKey.currentState!.validate() || _selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating and write a review.')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    final provider = Provider.of<GigProvider>(context, listen: false);
    final success = await provider.postReview(widget.gigUuid, {
      'rating': _selectedRating,
      'review': _reviewController.text,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Review submitted!' : provider.errorMessage ?? 'Failed to post review.')),
      );
      if (success) {
        Navigator.pop(context);
      }
    }
    setState(() => _isSubmitting = false);
  }
}
