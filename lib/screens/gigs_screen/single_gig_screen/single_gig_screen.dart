import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/gig_provider.dart';
import 'package:wawu_mobile/providers/message_provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/screens/gigs_screen/single_gig_screen/gig_description_card.dart';
import 'package:wawu_mobile/screens/gigs_screen/single_gig_screen/gig_faq_section_new.dart';
import 'package:wawu_mobile/screens/gigs_screen/single_gig_screen/gig_header.dart';
import 'package:wawu_mobile/screens/gigs_screen/single_gig_screen/gig_packages_section_new.dart';
import 'package:wawu_mobile/screens/gigs_screen/single_gig_screen/gig_reviews_section_new.dart';
import 'package:wawu_mobile/screens/gigs_screen/single_gig_screen/gig_seller_info_card.dart';
import 'package:wawu_mobile/screens/messages_screen/single_message_screen/single_message_screen.dart';
import 'package:wawu_mobile/screens/wawu_africa/sign_up/sign_up.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';

class SingleGigScreen extends StatefulWidget {
  const SingleGigScreen({super.key});

  @override
  State<SingleGigScreen> createState() => _SingleGigScreenState();
}

class _SingleGigScreenState extends State<SingleGigScreen> {
  late ScrollController _scrollController;
  bool _isAppBarOpaque = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    // Threshold is when the header image is about to be fully scrolled off
    const scrollThreshold = 200.0;
    final isOpaque = _scrollController.hasClients &&
        _scrollController.offset > scrollThreshold;
    if (isOpaque != _isAppBarOpaque) {
      setState(() {
        _isAppBarOpaque = isOpaque;
      });
    }
  }

  Future<void> _navigateToMessageScreen(
    BuildContext context,
    String sellerId,
  ) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final messageProvider =
        Provider.of<MessageProvider>(context, listen: false);

    if (userProvider.currentUser == null) {
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SignUp()),
        );
      }
      return;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<GigProvider>(
        builder: (context, gigProvider, child) {
          final currentGig = gigProvider.selectedGig;

          if (currentGig == null) {
            return const Center(child: Text('No gig selected'));
          }

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                expandedHeight: 250.0,
                pinned: true,
                backgroundColor: _isAppBarOpaque
                    ? Theme.of(context).scaffoldBackgroundColor
                    : Colors.transparent,
                elevation: _isAppBarOpaque ? 1 : 0,
                // Title that appears on scroll
                title: AnimatedOpacity(
                  opacity: _isAppBarOpaque ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    currentGig.title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      ),
                  ),
                ),
                // Let Flutter handle the back button automatically
                automaticallyImplyLeading: true,
                iconTheme: IconThemeData(
                  color: _isAppBarOpaque ? Colors.black : Colors.white,
                ),
                flexibleSpace: GigHeader(gig: currentGig),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      GigSellerInfoCard(
                        gig: currentGig,
                        onMessageTap: () => _navigateToMessageScreen(
                            context, currentGig.seller.uuid),
                      ),
                      const SizedBox(height: 16),
                      GigDescriptionCard(
                        title: 'Description',
                        content: currentGig.description,
                      ),
                      const SizedBox(height: 16),
                      GigDescriptionCard(
                        title: 'About',
                        content: currentGig.about,
                      ),
                      const SizedBox(height: 16),
                      GigPackagesSectionNew(gig: currentGig),
                      const SizedBox(height: 16),
                      GigFaqSectionNew(gig: currentGig),
                      const SizedBox(height: 16),
                      GigReviewsSectionNew(gig: currentGig),
                      const SizedBox(height: 76),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implement "Become a Seller" logic
        },
        backgroundColor: wawuColors.primary,
        icon: const Icon(Icons.store, color: Colors.white),
        label: const Text(
          'Become a Seller',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

