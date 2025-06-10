import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/gig_provider.dart';
import 'package:wawu_mobile/providers/message_provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/screens/messages_screen/single_message_screen/single_message_screen.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:wawu_mobile/widgets/custom_intro_text/custom_intro_text.dart';
import 'package:wawu_mobile/widgets/custom_textfield/custom_textfield.dart';
import 'package:wawu_mobile/widgets/package_grid_component/package_grid_component.dart';
import 'package:wawu_mobile/widgets/review_component/review_component.dart';

class SingleGigScreen extends StatefulWidget {
  const SingleGigScreen({super.key});

  @override
  State<SingleGigScreen> createState() => _SingleGigScreenState();
}

class _SingleGigScreenState extends State<SingleGigScreen> {
  final _reviewController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _selectedRating = 0;

  @override
  void dispose() {
    Provider.of<GigProvider>(context, listen: false).clearSelectedGig();
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _navigateToMessageScreen(
    BuildContext context,
    String sellerId,
  ) async {
    final messageProvider = Provider.of<MessageProvider>(
      context,
      listen: false,
    );
    final currentUserId =
        Provider.of<UserProvider>(context, listen: false).currentUser?.uuid ??
        '';

    if (currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to start a conversation')),
      );
      return;
    }

    try {
      await messageProvider.startConversation(currentUserId, sellerId);
      // await messageProvider.
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SingleMessageScreen(),
            settings: RouteSettings(arguments: {'recipientId': sellerId}),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start conversation: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GigProvider>(
      builder: (context, gigProvider, child) {
        final gig = gigProvider.selectedGig;
        if (gig == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(gig.title)),
          body: ListView(
            children: [
              _buildImageCarousel(context),
              _buildProfileSection(context),
              _buildGigDetails(context),
              _buildPackagesSection(context),
              _buildPortfolioSection(context),
              _buildFaqSection(context),
              _buildReviewsSection(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageCarousel(BuildContext context) {
    final gig = Provider.of<GigProvider>(context, listen: false).selectedGig;
    if (gig == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      height: 200,
      decoration: const BoxDecoration(color: Colors.grey),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount:
                gig.assets.photos.isNotEmpty ? gig.assets.photos.length : 1,
            itemBuilder: (context, index) {
              final photo =
                  gig.assets.photos.isNotEmpty
                      ? gig.assets.photos[index]
                      : null;
              return Container(
                width: MediaQuery.of(context).size.width,
                color: Colors.black,
                child: Opacity(
                  opacity: 0.7,
                  child:
                      photo != null
                          ? Image.network(
                            photo.link,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => Image.asset(
                                  'assets/images/section/graphics.png',
                                  fit: BoxFit.cover,
                                ),
                          )
                          : Image.asset(
                            'assets/images/section/graphics.png',
                            fit: BoxFit.cover,
                          ),
                ),
              );
            },
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: List.generate(5, (index) {
                  return Icon(
                    Icons.star,
                    color:
                        index < gig.averageRating.floor()
                            ? wawuColors.primary
                            : Colors.white,
                  );
                }),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    gig.averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(Icons.star, color: Colors.white, size: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    final gig = Provider.of<GigProvider>(context, listen: false).selectedGig;
    if (gig == null) return const SizedBox.shrink();

    return Container(
      color: Colors.transparent,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -40,
            left: 0,
            right: 0,
            child: Container(
              width: 90,
              height: 90,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: wawuColors.primary),
              ),
              padding: const EdgeInsets.all(2.0),
              child: Container(
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child:
                    gig.seller.profileImage != null
                        ? Image.network(
                          gig.seller.profileImage!,
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
            ),
          ),
          Positioned(
            bottom: 20,
            right: 140,
            child: GestureDetector(
              onTap: () => _navigateToMessageScreen(context, gig.seller.uuid),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: wawuColors.primary,
                ),
                child: const Center(
                  child: FaIcon(
                    FontAwesomeIcons.message,
                    color: Colors.white,
                    size: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGigDetails(BuildContext context) {
    final gig = Provider.of<GigProvider>(context, listen: false).selectedGig;
    if (gig == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              gig.seller.fullName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            gig.title,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: wawuColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(gig.description, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children:
                gig.keywords.split(',').map((keyword) {
                  return Container(
                    padding: const EdgeInsets.all(10.0),
                    margin: const EdgeInsets.symmetric(horizontal: 5.0),
                    decoration: BoxDecoration(
                      color: wawuColors.primary.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      keyword,
                      style: TextStyle(color: wawuColors.primary, fontSize: 12),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 20),
          const CustomIntroText(text: 'About This Gig'),
          const SizedBox(height: 10),
          Text(gig.about, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildPackagesSection(BuildContext context) {
    final gig = Provider.of<GigProvider>(context, listen: false).selectedGig;
    if (gig == null) return const SizedBox.shrink();

    // Prepare package data for PackageGridComponent
    final List<Map<String, dynamic>> packageData = [
      {
        'label': 'Package Titles',
        'isCheckbox': false,
        'controllers': [
          TextEditingController(
            text:
                gig.pricings.isNotEmpty
                    ? gig.pricings[0].package.name
                    : 'Basic',
          ),
          TextEditingController(
            text:
                gig.pricings.isNotEmpty
                    ? gig.pricings[1].package.name
                    : 'Standard',
          ),
          TextEditingController(
            text:
                gig.pricings.isNotEmpty
                    ? gig.pricings[2].package.name
                    : 'Premium',
          ),
        ],
      },
      {
        'label': 'Price (NGN)',
        'isCheckbox': false,
        'controllers': [
          TextEditingController(
            text:
                gig.pricings.isNotEmpty
                    ? '₦${gig.pricings[0].package.amount}'
                    : '₦0',
          ),
          TextEditingController(
            text:
                gig.pricings.isNotEmpty
                    ? '₦${gig.pricings[1].package.amount}'
                    : '₦0',
          ),
          TextEditingController(
            text:
                gig.pricings.isNotEmpty
                    ? '₦${gig.pricings[2].package.amount}'
                    : '₦0',
          ),
        ],
      },
    ];

    // Collect all unique feature names
    final Set<String> featureNames = {};
    for (final pricing in gig.pricings) {
      for (final feature in pricing.features) {
        featureNames.add(feature.name);
      }
    }

    // Add features to packageData
    for (final featureName in featureNames) {
      final row = {
        'label': featureName,
        'isCheckbox': true,
        'values': [
          gig.pricings.isNotEmpty &&
                  gig.pricings[0].features.any((f) => f.name == featureName)
              ? gig.pricings[0].features
                      .firstWhere((f) => f.name == featureName)
                      .value ==
                  'yes'
              : false,
          gig.pricings.isNotEmpty &&
                  gig.pricings[1].features.any((f) => f.name == featureName)
              ? gig.pricings[1].features
                      .firstWhere((f) => f.name == featureName)
                      .value ==
                  'yes'
              : false,
          gig.pricings.isNotEmpty &&
                  gig.pricings[2].features.any((f) => f.name == featureName)
              ? gig.pricings[2].features
                      .firstWhere((f) => f.name == featureName)
                      .value ==
                  'yes'
              : false,
        ],
      };
      packageData.add(row);
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomIntroText(text: 'Packages'),
          const SizedBox(height: 10),
          PackageGridComponent(initialData: packageData),
        ],
      ),
    );
  }

  Widget _buildPortfolioSection(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomIntroText(text: 'My Portfolio'),
          SizedBox(height: 10),
          Text('Portfolio items will be displayed here'),
        ],
      ),
    );
  }

  Widget _buildFaqSection(BuildContext context) {
    final gig = Provider.of<GigProvider>(context, listen: false).selectedGig;
    if (gig == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomIntroText(text: 'FAQ'),
          const SizedBox(height: 10),
          ...gig.faqs.map(
            (faq) => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              margin: const EdgeInsets.only(top: 10.0),
              decoration: BoxDecoration(
                color: wawuColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    faq.attributes.isNotEmpty
                        ? faq.attributes[0].question
                        : 'No question',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    faq.attributes.isNotEmpty
                        ? faq.attributes[0].answer
                        : 'No answer',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(BuildContext context) {
    final gig = Provider.of<GigProvider>(context, listen: false).selectedGig;
    if (gig == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomIntroText(text: 'Reviews'),
          const SizedBox(height: 10),
          ...gig.reviews.map((review) => ReviewComponent(review: review)),
          const SizedBox(height: 40),
          const Center(child: Text('Rate This Gig')),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => setState(() => _selectedRating = index + 1),
                child: Icon(
                  Icons.star,
                  color:
                      index < _selectedRating
                          ? wawuColors.primary
                          : wawuColors.primary.withAlpha(40),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Form(
            key: _formKey,
            child: Column(
              children: [
                CustomTextfield(
                  labelTextStyle2: true,
                  hintText: 'Write A Review',
                  controller: _reviewController,
                  maxLines: true,
                  maxLinesNum: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a review';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                CustomButton(
                  widget: const Text(
                    'Send',
                    style: TextStyle(color: Colors.white),
                  ),
                  color: wawuColors.primary,
                  function: () async {
                    if (_formKey.currentState!.validate()) {
                      if (_selectedRating == 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a rating'),
                          ),
                        );
                        return;
                      }
                      final gigProvider = Provider.of<GigProvider>(
                        context,
                        listen: false,
                      );
                      final userProvider = Provider.of<UserProvider>(
                        context,
                        listen: false,
                      );
                      final result = await gigProvider.postReview(gig.uuid, {
                        'rating': _selectedRating,
                        'review': _reviewController.text,
                        // 'user_id': userProvider.currentUser?.uuid ?? '',
                      });
                      if (result && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Review submitted successfully'),
                          ),
                        );
                        _reviewController.clear();
                        setState(() => _selectedRating = 0);
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
