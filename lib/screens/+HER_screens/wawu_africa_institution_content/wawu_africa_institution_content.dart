import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/wawu_africa_provider.dart';
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
    double opacity = (_scrollController.offset / scrollThreshold).clamp(0.0, 1.0);
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

    final provider = Provider.of<WawuAfricaProvider>(context, listen: false);
    final contentId = provider.selectedInstitutionContent?.id;

    if (contentId == null) {
      CustomSnackBar.show(context, message: 'Content ID is missing.', isError: true);
      setState(() {
        _isRegistering = false;
      });
      return;
    }

    final success = await provider.registerForContent(contentId);

    if (mounted) {
      if (success) {
        CustomSnackBar.show(context, message: 'Registration successful!', isError: false);
      } else {
        CustomSnackBar.show(context, message: provider.errorMessage ?? 'Registration failed.', isError: true);
      }
    }
    
    setState(() {
      _isRegistering = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WawuAfricaProvider>(context);
    final content = provider.selectedInstitutionContent;
    final institution = provider.selectedInstitution;

    if (content == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(
          child: Text('No content selected. Please go back.'),
        ),
      );
    }

    final markdownStyle =
        MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: TextStyle(color: Colors.grey[700], fontSize: 16, height: 1.5),
      strong: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      listBullet: const TextStyle(
          color: Color(0xFFF50057), fontSize: 16, fontWeight: FontWeight.bold),
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
      // Floating Action Button for the registration action
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isRegistering ? null : _handleRegistration,
        backgroundColor: const Color(0xFFF50057),
        icon: institution?.profileImageUrl.isNotEmpty ?? false
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: institution!.profileImageUrl,
                  height: 24,
                  width: 24,
                  fit: BoxFit.cover,
                ),
              )
            : null,
        label: _isRegistering
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 1.0,
              )
            : const Text(
                'Send a request',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image with Scrim
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
                // Gradient Scrim for AppBar visibility
                Container(
                  height: 120, // Scrim only covers the top portion
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

            // Content Section
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
                  // The button is now a FAB, so we add padding at the bottom
                  // to ensure the last piece of content is not hidden by it.
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

