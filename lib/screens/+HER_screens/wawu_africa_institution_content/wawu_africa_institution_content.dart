import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/plan_provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/providers/wawu_africa_provider.dart';
import 'package:wawu_mobile/screens/wawu_africa/sign_up/sign_up.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_snackbar.dart';

class WawuAfricaInstitutionContentScreen extends StatefulWidget {
  const WawuAfricaInstitutionContentScreen({super.key});

  @override
  State<WawuAfricaInstitutionContentScreen> createState() =>
      _WawuAfricaInstitutionContentScreenState();
}

class _WawuAfricaInstitutionContentScreenState
    extends State<WawuAfricaInstitutionContentScreen> {
  late final ScrollController _scrollController;
  Color _appBarBgColor = Colors.transparent;
  Color _appBarItemColor = Colors.white;
  bool _isRegistering = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    const scrollThreshold = 150.0;
    double opacity = (_scrollController.offset / scrollThreshold).clamp(
      0.0,
      1.0,
    );
    Color itemColor = opacity > 0.5 ? Colors.black : Colors.white;

    if (opacity != (_appBarBgColor.opacity) || itemColor != _appBarItemColor) {
      setState(() {
        _appBarBgColor = Colors.white.withOpacity(opacity);
        _appBarItemColor = itemColor;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  /// --- REFACTORED: Handles registration with graceful subscription checking ---
  Future<void> _handleRegistration() async {
    setState(() => _isRegistering = true);

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final wawuProvider = Provider.of<WawuAfricaProvider>(context, listen: false);
    final planProvider = Provider.of<PlanProvider>(context, listen: false);

    // 1. Check if user is logged in
    if (userProvider.currentUser == null) {
      CustomSnackBar.show(
        context,
        message: 'Please log in or sign up to send a request',
        isError: true,
      );
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SignUp()),
        );
      }
      setState(() => _isRegistering = false);
      return;
    }

    final contentId = wawuProvider.selectedInstitutionContent?.id;
    if (contentId == null) {
      CustomSnackBar.show(context, message: 'Content ID is missing.', isError: true);
      setState(() => _isRegistering = false);
      return;
    }

    // 2. Gracefully handle offline state, like in main_screen.dart
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'No internet connection. Please try again later.',
          isError: true,
        );
      }
      setState(() => _isRegistering = false);
      return;
    }

    try {
      // FIX: Convert String role to int roleId, as required by the provider.
      int getRoleId(String? roleName) {
        switch (roleName?.toUpperCase()) {
          case 'BUYER':
            return 1;
          case 'PROFESSIONAL':
            return 2;
          case 'ARTISAN':
            return 3;
          default:
            return 0; // Default for guest or unknown roles
        }
      }

      final int roleId = getRoleId(userProvider.currentUser!.role);

      // 3. CRITICAL: Force a check against all sources (cache, backend, IAP)
      // to get the most up-to-date subscription status.
      await planProvider.fetchUserSubscriptionDetails(
        userProvider.currentUser!.uuid,
        roleId, // Use the corrected integer roleId
      );

      if (!mounted) return;

      // 4. Now, check the provider for an active subscription
      if (planProvider.hasActiveSubscription) {
        // If subscribed, proceed to register for the content
        await wawuProvider.registerForContent(contentId);
        if (mounted) {
          CustomSnackBar.show(
            context,
            message: 'Request sent\nYou will be contacted soon',
          );
        }
      } else {
        // 5. If not subscribed, guide the user through the subscription process
        final bool? wantsToSubscribe = await _showSubscriptionDialog(planProvider);

        if (wantsToSubscribe == true && mounted) {
          // Initiate the subscription purchase flow
          await planProvider.purchaseSubscription(
            planUuid: '', // planUuid is handled internally by the provider
            userId: userProvider.currentUser!.uuid,
          );

          // The purchase result is handled asynchronously by PlanProvider.
          // Inform the user about the next step.
          CustomSnackBar.show(
            context,
            message: 'Once your subscription is confirmed, please tap "Send a request" again.',
          );
        }
      }
    } catch (e) {
      debugPrint('[WawuAfricaContentScreen] Error during registration: $e');
      
      // -- START FIX: Check for the specific error message --
      String errorMessage = 'An error occurred. Please check your connection and try again.';
      bool isError = true;

      // Check for the "already registered" error from the API
      if (e.toString().toLowerCase().contains('user is already registered')) {
        errorMessage = 'You have already sent a request for this content.';
        isError = false; // This is an informational message, not a critical error
      }

      if (mounted) {
        CustomSnackBar.show(
          context,
          message: errorMessage,
          isError: isError,
        );
      }
      // -- END FIX --
      
    } finally {
      if (mounted) {
        setState(() => _isRegistering = false);
      }
    }
  }

  /// Helper method to show the new subscription dialog.
  Future<bool?> _showSubscriptionDialog(PlanProvider planProvider) async {
    // Ensure IAP is initialized to get product details
    if (!planProvider.isIapInitialized) {
      await planProvider.initializeIAP();
    }

    ProductDetails? product;
    if (planProvider.iapProducts.isNotEmpty) {
      product = planProvider.iapProducts.first;
    }

    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 20, 24, MediaQuery.of(context).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Subscription Required',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Text(
              'A yearly subscription is required to send requests to institutions. This gives you unlimited access.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: wawuColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  // Show price if available, otherwise show a generic message
                  product != null
                      ? 'Subscribe Now for ${product.price}/year'
                      : 'Subscribe Now',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black54)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Build method remains the same as before
    final provider = Provider.of<WawuAfricaProvider>(context);
    final content = provider.selectedInstitutionContent;
    final institution = provider.selectedInstitution;

    if (content == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('No content selected. Please go back.')),
      );
    }

    final markdownStyle = MarkdownStyleSheet.fromTheme(
      Theme.of(context),
    ).copyWith(
      p: TextStyle(color: Colors.grey[700], fontSize: 16, height: 1.5),
      strong:
          const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      listBullet: const TextStyle(
        color: Color(0xFFF50057),
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _appBarBgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _appBarItemColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _appBarBgColor.opacity > 0.5 ? content.name : '',
          style: TextStyle(color: _appBarItemColor, fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isRegistering ? null : _handleRegistration,
        backgroundColor: const Color(0xFFF50057),
        icon: Stack(
          alignment: Alignment.center,
          children: [
            if (institution?.profileImageUrl.isNotEmpty ?? false)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: institution!.profileImageUrl,
                  height: 24,
                  width: 24,
                  fit: BoxFit.cover,
                ),
              ),
            if (_isRegistering)
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
          ],
        ),
        label: AnimatedOpacity(
          opacity: _isRegistering ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: const Text(
            'Send a request',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: content.imageUrl,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 250,
                    color: Colors.grey[200],
                    child: const Center(
                        child: CircularProgressIndicator(color: Colors.pinkAccent)),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 250,
                    color: Colors.grey[200],
                    child: const Icon(Icons.error_outline,
                        color: Colors.red, size: 50),
                  ),
                ),
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.name,
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    content.description,
                    style: TextStyle(
                        color: Colors.black.withOpacity(0.7),
                        fontSize: 16,
                        height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Requirements'),
                  MarkdownBody(
                      data: content.requirements,
                      styleSheet: markdownStyle,
                      shrinkWrap: true),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Key Benefits'),
                  MarkdownBody(
                      data: content.keyBenefits,
                      styleSheet: markdownStyle,
                      shrinkWrap: true),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
            color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}