import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/gig_provider.dart';
import 'package:wawu_mobile/providers/message_provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/screens/messages_screen/single_message_screen/single_message_screen.dart';
import 'package:wawu_mobile/screens/wawu_africa/sign_up/sign_up.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:wawu_mobile/widgets/custom_intro_text/custom_intro_text.dart';
import 'package:wawu_mobile/widgets/custom_textfield/custom_textfield.dart';
import 'package:wawu_mobile/widgets/package_grid_component/package_grid_component.dart';
import 'package:wawu_mobile/models/gig.dart';
import 'package:wawu_mobile/widgets/review_component/review_component.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
// Import the SignUpScreen

class SingleGigScreen extends StatefulWidget {
  const SingleGigScreen({super.key});

  @override
  State<SingleGigScreen> createState() => _SingleGigScreenState();
}

class _SingleGigScreenState extends State<SingleGigScreen> {
  final _reviewController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _selectedRating = 0;
  bool _isSubmittingReview = false;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void dispose() {
    _reviewController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo(String videoUrl) async {
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _videoController!.initialize();
      setState(() {
        _isVideoInitialized = true;
      });
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  Future<void> _navigateToMessageScreen(
    BuildContext context,
    String sellerId,
  ) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final messageProvider = Provider.of<MessageProvider>(
      context,
      listen: false,
    );

    // Check if the user is authenticated
    if (userProvider.currentUser == null) {
      // If not authenticated, navigate to the SignUpScreen
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SignUp()),
        );
      }
      return; // Stop execution here
    }

    final currentUserId = userProvider.currentUser!.uuid;

    try {
      await messageProvider.startConversation(currentUserId, sellerId);
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

  Future<void> _launchPDF(String pdfUrl) async {
    try {
      final Uri url = Uri.parse(pdfUrl);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $pdfUrl');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to open PDF: $e')));
      }
    }
  }

  void _showFullscreenImage(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      placeholder:
                          (context, url) => const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => const Center(
                            child: Icon(
                              Icons.error,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showFullscreenVideo(String videoUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) => _FullscreenVideoDialog(videoUrl: videoUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<GigProvider>(
          builder: (context, gigProvider, child) {
            final currentGig = gigProvider.selectedGig;
            return Text(currentGig?.title ?? 'Gig Details');
          },
        ),
      ),
      body: Consumer<GigProvider>(
        builder: (context, gigProvider, child) {
          final currentGig = gigProvider.selectedGig;

          if (currentGig == null) {
            return const Center(child: Text('No gig selected'));
          }

          return ListView(
            children: [
              _buildImageCarousel(context, currentGig),
              _buildProfileSection(context, currentGig),
              _buildGigDetails(context, currentGig),
              _buildPackagesSection(context, currentGig),
              // _buildPortfolioSection(context),
              _buildFaqSection(context, currentGig),
              _buildReviewsSection(context, currentGig),
            ],
          );
        },
      ),
    );
  }

  Widget _buildImageCarousel(BuildContext context, Gig gig) {
    // Calculate total item count (video + photos) with null safety
    final hasVideo = gig.assets.video?.link.isNotEmpty ?? false;
    final photoCount = gig.assets.photos.length;
    final totalItems = (hasVideo ? 1 : 0) + (photoCount > 0 ? photoCount : 1);

    return Container(
      width: double.infinity,
      height: 200,
      decoration: const BoxDecoration(color: Colors.grey),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: totalItems,
            itemBuilder: (context, index) {
              // First item is video if available
              if (hasVideo && index == 0) {
                return _buildVideoItem(context, gig);
              }

              // Adjust index for photos
              final photoIndex = hasVideo ? index - 1 : index;
              final photos = gig.assets.photos;
              final photo =
                  photos.isNotEmpty && photoIndex < photos.length
                      ? photos[photoIndex]
                      : null;

              return GestureDetector(
                onTap: () {
                  if (photo?.link.isNotEmpty == true) {
                    _showFullscreenImage(photo!.link);
                  }
                },
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  color: Colors.black,
                  child: Opacity(
                    opacity: 0.7,
                    child:
                        photo?.link.isNotEmpty == true
                            ? CachedNetworkImage(
                              imageUrl: photo!.link,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => Container(
                                    color: wawuColors.primary.withValues(
                                      alpha: 0.4,
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                              errorWidget:
                                  (context, url, error) =>
                                      Container(color: Colors.black),
                            )
                            : Container(color: Colors.black),
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

  Widget _buildVideoItem(BuildContext context, Gig gig) {
    final videoUrl = gig.assets.video?.link ?? '';

    return GestureDetector(
      onTap: () {
        if (videoUrl.isNotEmpty) {
          _showFullscreenVideo(videoUrl);
        }
      },
      child: Container(
        width: MediaQuery.of(context).size.width,
        color: Colors.black,
        child: Stack(
          children: [
            if (_videoController != null && _isVideoInitialized)
              Opacity(
                opacity: 0.7,
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: VideoPlayer(_videoController!),
                ),
              )
            else
              Container(
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            // Play button overlay
            Positioned.fill(
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (_videoController == null && videoUrl.isNotEmpty) {
                      _initializeVideo(videoUrl);
                    } else if (_videoController != null &&
                        _isVideoInitialized) {
                      setState(() {
                        if (_videoController!.value.isPlaying) {
                          _videoController!.pause();
                        } else {
                          _videoController!.play();
                        }
                      });
                    }
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      (_videoController?.value.isPlaying ?? false)
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, Gig gig) {
    return Container(
      color: Colors.transparent,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -40,
            left:
                MediaQuery.of(context).size.width / 2 -
                45, // Center the profile image
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: wawuColors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipOval(
                child:
                    gig.seller.profileImage?.isNotEmpty == true
                        ? CachedNetworkImage(
                          imageUrl: gig.seller.profileImage!,
                          fit: BoxFit.cover,
                          width: 90,
                          height: 90,
                          placeholder:
                              (context, url) => Container(
                                width: 90,
                                height: 90,
                                color: wawuColors.primary.withValues(
                                  alpha: 0.2,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Image.asset(
                                'assets/images/other/avatar.webp',
                                fit: BoxFit.cover,
                                width: 90,
                                height: 90,
                              ),
                        )
                        : Image.asset(
                          'assets/images/other/avatar.webp',
                          fit: BoxFit.cover,
                          width: 90,
                          height: 90,
                        ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right:
                MediaQuery.of(context).size.width / 2 -
                45, // Position message button next to profile
            child: GestureDetector(
              onTap: () => _navigateToMessageScreen(context, gig.seller.uuid),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: wawuColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
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

  Widget _buildGigDetails(BuildContext context, Gig gig) {
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
                      keyword.trim(),
                      style: TextStyle(color: wawuColors.primary, fontSize: 12),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 20),
          const CustomIntroText(text: 'About This Gig'),
          const SizedBox(height: 10),
          Text(gig.about, style: const TextStyle(fontSize: 14)),
          // Add PDF button if PDF link exists
          if (gig.assets.pdf?.link.isNotEmpty == true) ...[
            const SizedBox(height: 15),
            Center(
              child: CustomButton(
                widget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.picture_as_pdf,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'View PDF',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                color: wawuColors.primary,
                function: () => _launchPDF(gig.assets.pdf!.link),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPackagesSection(BuildContext context, Gig gig) {
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
                gig.pricings.length > 1
                    ? gig.pricings[1].package.name
                    : 'Standard',
          ),
          TextEditingController(
            text:
                gig.pricings.length > 2
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
                gig.pricings.length > 1
                    ? '₦${gig.pricings[1].package.amount}'
                    : '₦0',
          ),
          TextEditingController(
            text:
                gig.pricings.length > 2
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
      // Check if this feature has only "yes"/"no" values across all packages
      bool isYesNoFeature = true;
      List<String> featureValues = [];

      // Collect all values for this feature across all packages
      for (int i = 0; i < 3; i++) {
        if (i < gig.pricings.length) {
          final featureIndex = gig.pricings[i].features.indexWhere(
            (f) => f.name == featureName,
          );
          if (featureIndex != -1) {
            featureValues.add(
              gig.pricings[i].features[featureIndex].value.toLowerCase(),
            );
          } else {
            featureValues.add('');
          }
        } else {
          featureValues.add('');
        }
      }

      // Check if all non-empty values are either "yes" or "no"
      for (final value in featureValues) {
        if (value.isNotEmpty && value != 'yes' && value != 'no') {
          isYesNoFeature = false;
          break;
        }
      }

      if (isYesNoFeature) {
        // Use checkbox format for yes/no features
        final row = {
          'label': featureName,
          'isCheckbox': true,
          'values': [
            gig.pricings.isNotEmpty &&
                    gig.pricings[0].features.any((f) => f.name == featureName)
                ? gig.pricings[0].features
                        .firstWhere((f) => f.name == featureName)
                        .value
                        .toLowerCase() ==
                    'yes'
                : false,
            gig.pricings.length > 1 &&
                    gig.pricings[1].features.any((f) => f.name == featureName)
                ? gig.pricings[1].features
                        .firstWhere((f) => f.name == featureName)
                        .value
                        .toLowerCase() ==
                    'yes'
                : false,
            gig.pricings.length > 2 &&
                    gig.pricings[2].features.any((f) => f.name == featureName)
                ? gig.pricings[2].features
                        .firstWhere((f) => f.name == featureName)
                        .value
                        .toLowerCase() ==
                    'yes'
                : false,
          ],
        };
        packageData.add(row);
      } else {
        // Use text field format for other features
        final row = {
          'label': featureName,
          'isCheckbox': false,
          'controllers': [
            TextEditingController(
              text:
                  gig.pricings.isNotEmpty &&
                          gig.pricings[0].features.any(
                            (f) => f.name == featureName,
                          )
                      ? gig.pricings[0].features
                          .firstWhere((f) => f.name == featureName)
                          .value
                      : '',
            ),
            TextEditingController(
              text:
                  gig.pricings.length > 1 &&
                          gig.pricings[1].features.any(
                            (f) => f.name == featureName,
                          )
                      ? gig.pricings[1].features
                          .firstWhere((f) => f.name == featureName)
                          .value
                      : '',
            ),
            TextEditingController(
              text:
                  gig.pricings.length > 2 &&
                          gig.pricings[2].features.any(
                            (f) => f.name == featureName,
                          )
                      ? gig.pricings[2].features
                          .firstWhere((f) => f.name == featureName)
                          .value
                      : '',
            ),
          ],
        };
        packageData.add(row);
      }
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

  // Widget _buildPortfolioSection(BuildContext context) {
  //   return const Padding(
  //     padding: EdgeInsets.all(20.0),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         CustomIntroText(text: 'My Portfolio'),
  //         SizedBox(height: 10),
  //         Text('Portfolio items will be displayed here'),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildFaqSection(BuildContext context, Gig gig) {
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

  Widget _buildReviewsSection(BuildContext context, Gig gig) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomIntroText(text: 'Reviews'),
          const SizedBox(height: 10),
          Consumer<GigProvider>(
            builder: (context, gigProvider, child) {
              final currentGig = gigProvider.selectedGig ?? gig;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    currentGig.reviews
                        .map((review) => ReviewComponent(review: review))
                        .toList(),
              );
            },
          ),
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
                  widget:
                      _isSubmittingReview
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text(
                            'Send',
                            style: TextStyle(color: Colors.white),
                          ),
                  color: wawuColors.primary,
                  function:
                      _isSubmittingReview
                          ? null
                          : () async {
                            final userProvider = Provider.of<UserProvider>(
                              context,
                              listen: false,
                            );
                            // Check if the user is authenticated before submitting a review
                            if (userProvider.currentUser == null) {
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SignUp(),
                                  ),
                                );
                              }
                              return; // Stop execution here
                            }

                            if (_formKey.currentState!.validate()) {
                              if (_selectedRating == 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please select a rating'),
                                  ),
                                );
                                return;
                              }

                              setState(() => _isSubmittingReview = true);

                              final gigProvider = Provider.of<GigProvider>(
                                context,
                                listen: false,
                              );

                              final result = await gigProvider
                                  .postReview(gig.uuid, {
                                    'rating': _selectedRating,
                                    'review': _reviewController.text,
                                  });

                              if (context.mounted) {
                                if (result) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Review submitted successfully',
                                      ),
                                    ),
                                  );
                                  _reviewController.clear();
                                  setState(() => _selectedRating = 0);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        gigProvider.errorMessage ??
                                            'Failed to submit review',
                                      ),
                                    ),
                                  );
                                }
                                setState(() => _isSubmittingReview = false);
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

// Fullscreen Video Dialog Widget
class _FullscreenVideoDialog extends StatefulWidget {
  final String videoUrl;

  const _FullscreenVideoDialog({required this.videoUrl});

  @override
  State<_FullscreenVideoDialog> createState() => _FullscreenVideoDialogState();
}

class _FullscreenVideoDialogState extends State<_FullscreenVideoDialog> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      await _controller!.initialize();
      setState(() {
        _isInitialized = true;
      });
      // Auto-play the video when initialized
      _controller!.play();
    } catch (e) {
      print('Error initializing fullscreen video: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Stack(
          children: [
            // Video player
            if (_controller != null && _isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),

            // Close button
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),

            // Play/Pause button overlay
            if (_controller != null && _isInitialized)
              Positioned.fill(
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_controller!.value.isPlaying) {
                          _controller!.pause();
                        } else {
                          _controller!.play();
                        }
                      });
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _controller!.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),

            // Video controls (optional - you can remove this if you want simpler controls)
            if (_controller != null && _isInitialized)
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Progress bar
                      VideoProgressIndicator(
                        _controller!,
                        allowScrubbing: true,
                        colors: VideoProgressColors(
                          playedColor: Colors.white,
                          bufferedColor: Colors.white.withOpacity(0.3),
                          backgroundColor: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Time display
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_controller!.value.position),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _formatDuration(_controller!.value.duration),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}
