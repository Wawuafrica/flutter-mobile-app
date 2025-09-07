import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

// The class is now a StatefulWidget to manage the scroll state.
class WawuAfricaInstitutionContent extends StatefulWidget {
  const WawuAfricaInstitutionContent({super.key});

  @override
  State<WawuAfricaInstitutionContent> createState() => _WawuAfricaInstitutionContentState();
}

class _WawuAfricaInstitutionContentState extends State<WawuAfricaInstitutionContent> {
  // --- STATE MANAGEMENT LOGIC ---
  // All the logic for controlling the AppBar is now inside this state class.
  late final ScrollController _scrollController;
  Color _appBarBgColor = Colors.transparent;
  Color _appBarItemColor = Colors.white;

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
  // --- END OF STATE MANAGEMENT LOGIC ---


  // --- SIMULATED BACKEND DATA ---
  final String heroImageUrl =
      'https://images.pexels.com/photos/774042/pexels-photo-774042.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2';
  final String chipperLogoUrl =
      'https://pbs.twimg.com/profile_images/1671852374029279232/V35sODf6_400x400.jpg';
  final String title = 'Oxygen X – Standalone Digital Lending Platform';
  final String introduction =
      'Oxygen X is Access Corporation’s standalone digital lending platform, designed to provide quick and accessible financial solutions to individuals and businesses in Nigeria.';
  final String requirementsMarkdown = """
* **Age:** Must be at least 18 years old.
* **Residency:** Nigerian citizen or resident.
* **Income:** Steady income source; salaried or self-employed.
* **Identification:** Valid ID (e.g., National ID, Driver’s License, Passport).
* **Bank Verification Number (BVN):** Required for identity verification.
""";
  final String keyBenefitsMarkdown = """
* **Fast Approval:** Receive loan decisions within minutes, with funds disbursed directly to your bank account.
* **Flexible Loan Terms:** Repayment periods range from 3 to 24 months, depending on the loan amount and your selected plan.
* **No Hidden Fees:** Transparent pricing with no hidden charges; only a processing fee is deducted upfront.
* **Wide Accessibility:** Available to both Access Bank customers and non-customers, broadening access to financial services.
* **Diverse Loan Options:** Offers personal loans, business loans, and asset financing, including partnerships for device and solar product financing.
""";
  // --- END OF SIMULATED DATA ---

  @override
  Widget build(BuildContext context) {
    final markdownStyle = MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: TextStyle(color: Colors.grey[700], fontSize: 16, height: 1.5),
      strong: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      listBullet: const TextStyle(color: Color(0xFFF50057), fontSize: 16, fontWeight: FontWeight.bold),
    );
    
    // The Scaffold is now the root of this widget's build method.
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on_outlined, color: _appBarItemColor, size: 20),
            const SizedBox(width: 4),
            Text(
              'Estaport Ave, 13 Lekki...',
              style: TextStyle(color: _appBarItemColor, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
            Icon(Icons.keyboard_arrow_down, color: _appBarItemColor),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image
            CachedNetworkImage(
              imageUrl: heroImageUrl,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 250,
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator(color: Colors.pinkAccent)),
              ),
              errorWidget: (context, url, error) => Container(
                height: 250,
                color: Colors.grey[200],
                child: const Icon(Icons.error_outline, color: Colors.red, size: 50),
              ),
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    introduction,
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.7),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Requirements'),
                  MarkdownBody(
                    data: requirementsMarkdown,
                    styleSheet: markdownStyle,
                    shrinkWrap: true,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Key Benefits'),
                  MarkdownBody(
                    data: keyBenefitsMarkdown,
                    styleSheet: markdownStyle,
                    shrinkWrap: true,
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF50057),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      print('Request button tapped!');
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: CachedNetworkImage(
                            imageUrl: chipperLogoUrl,
                            height: 24,
                            width: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Send a request',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
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