import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/her_purchase_provider.dart';
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

  Future<void> _handleRegistration() async {
    setState(() {
      _isRegistering = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (userProvider.currentUser == null) {
      CustomSnackBar.show(
        context,
        message: 'Please log in or sign up to send a request',
        isError: true,
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SignUp()),
      );
      setState(() => _isRegistering = false);
      return;
    }

    final wawuProvider = Provider.of<WawuAfricaProvider>(
      context,
      listen: false,
    );
    final purchaseProvider = Provider.of<HerPurchaseProvider>(
      context,
      listen: false,
    ); // Get the provider
    final contentId = wawuProvider.selectedInstitutionContent?.id;

    if (contentId == null) {
      CustomSnackBar.show(
        context,
        message: 'Content ID is missing.',
        isError: true,
      );
      setState(() => _isRegistering = false);
      return;
    }

    try {
      // 1. Check if user has already paid for this specific content
      bool hasPaid = await purchaseProvider.hasPurchasedContent(
        contentId.toString(),
      );

      if (!hasPaid) {
        // 2. If not paid, show a payment dialog and initiate purchase
        final bool? wantsToPay = await _showPaymentConfirmationDialog();
        if (wantsToPay == true) {
          hasPaid = await purchaseProvider.purchaseContent(
            contentId.toString(),
          );
        }
      }

      // 3. If payment is confirmed (either previously or just now), proceed with registration
      if (hasPaid) {
        await wawuProvider.registerForContent(contentId);
        if (mounted) {
          CustomSnackBar.show(
            context,
            message: 'Request sent\nYou will be contacted soon',
            isError: false,
          );
        }
      } else {
        // User cancelled payment or it failed
        if (mounted && (purchaseProvider.errorMessage?.isNotEmpty ?? false)) {
          CustomSnackBar.show(
            context,
            message: purchaseProvider.errorMessage!,
            isError: true,
          );
        }
      }
    } catch (e) {
      // Handle errors from either provider
      if (mounted) {
        final errorMessage =
            purchaseProvider.errorMessage ??
            wawuProvider.errorMessage ??
            'An unexpected error occurred.';
        CustomSnackBar.show(context, message: errorMessage, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isRegistering = false);
      }
    }
  }

  /// Helper method to show a confirmation dialog as a modal bottom sheet.
  Future<bool?> _showPaymentConfirmationDialog() {
    return showModalBottomSheet<bool>(
      context: context,
      // Use the scaffold's background color for a seamless look
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // Apply rounded corners to the top
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      builder:
          (context) => Padding(
            // Add padding for content and respect the safe area at the bottom
            padding: EdgeInsets.fromLTRB(
              24,
              20,
              24,
              MediaQuery.of(context).padding.bottom + 24,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize
                      .min, // Make the sheet only as tall as its content
              children: [
                // 1. Grab Handle for visual affordance
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 28),

                // 2. Title
                const Text(
                  'One-Time Fee',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // 3. Descriptive Content
                const Text(
                  'A one-time fee is required to send a request to this institution. Do you want to proceed with the payment?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // 4. "Pay Now" Button (Primary Action)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          wawuColors
                              .primary, // Using the specific color from your FAB
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      'Pay Now',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 5. "Cancel" Button (Secondary Action)
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      strong: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
            // The image is always present but may be covered by the loader
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
            // The loader appears on top of the image when registering
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
                  placeholder:
                      (context, url) => Container(
                        height: 250,
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.pinkAccent,
                          ),
                        ),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        height: 250,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 50,
                        ),
                      ),
                ),
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    content.description,
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.7),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Requirements'),
                  MarkdownBody(
                    data: content.requirements,
                    styleSheet: markdownStyle,
                    shrinkWrap: true,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Key Benefits'),
                  MarkdownBody(
                    data: content.keyBenefits,
                    styleSheet: markdownStyle,
                    shrinkWrap: true,
                  ),
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
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
