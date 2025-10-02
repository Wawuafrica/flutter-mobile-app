import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/models/wawu_africa_nest.dart' as model;
import 'package:wawu_mobile/providers/ad_provider.dart';
import 'package:wawu_mobile/providers/wawu_africa_provider.dart';
import 'package:wawu_mobile/screens/+HER_screens/wawu_africa_institution_content/wawu_africa_institution_content.dart';
import 'package:wawu_mobile/screens/home_screen/ads_section.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/utils/error_utils.dart';
import 'package:wawu_mobile/widgets/full_ui_error_display.dart';

class WawuAfricaSingleInstitution extends StatefulWidget {
  const WawuAfricaSingleInstitution({super.key});

  @override
  State<WawuAfricaSingleInstitution> createState() =>
      _WawuAfricaSingleInstitutionState();
}

class _WawuAfricaSingleInstitutionState
    extends State<WawuAfricaSingleInstitution> {
  late ScrollController _scrollController;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adProvider = Provider.of<AdProvider>(context, listen: false);
      final provider = Provider.of<WawuAfricaProvider>(context, listen: false);
      final selectedInstitutionId = provider.selectedInstitution?.id;
      if (adProvider.ads.isEmpty && !adProvider.isLoading) {
        adProvider.fetchAds();
      }

      if (selectedInstitutionId != null) {
        provider.clearInstitutionContents();
        provider.fetchInstitutionContentsByInstitutionId(
          selectedInstitutionId.toString(),
        );
      } else {
        print("Error: No institution selected.");
        // Optionally, pop the navigation if no institution is selected
        // Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 180 && !_isScrolled) {
      setState(() {
        _isScrolled = true;
      });
    } else if (_scrollController.offset <= 180 && _isScrolled) {
      setState(() {
        _isScrolled = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WawuAfricaProvider>(context);
    final institution = provider.selectedInstitution;

    if (institution == null && !provider.isLoading) {
      // Handle the case where the selected institution is somehow null
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(
          child: Text('No institution was selected. Please go back.'),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _isScrolled ? institution?.name ?? 'Institution' : '',
          style: TextStyle(
            color: _isScrolled ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        centerTitle: true,
        elevation: _isScrolled ? 1.0 : 0.0,
        backgroundColor:
            _isScrolled
                ? Theme.of(context).scaffoldBackgroundColor
                : Colors.transparent,
        iconTheme: IconThemeData(
          color: _isScrolled ? Colors.black : Colors.white,
        ),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Header Section
          SliverToBoxAdapter(child: _buildHeaderSection(institution)),

          // Institution Info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildInstitutionInfo(institution),
                  const SizedBox(height: 30),

                  AdsSection(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Content List Body
          _buildContentBody(provider),
        ],
      ),
    );
  }

  Widget _buildContentBody(WawuAfricaProvider provider) {
    if (provider.isLoading && provider.institutionContents.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.hasError && provider.institutionContents.isEmpty) {
      return SliverFillRemaining(
        child: FullErrorDisplay(
          errorMessage:
              provider.errorMessage ?? 'Failed to load institution content.',
          onRetry: () {
            final selectedInstitutionId = provider.selectedInstitution?.id;
            if (selectedInstitutionId != null) {
              provider.fetchInstitutionContentsByInstitutionId(
                selectedInstitutionId.toString(),
              );
            }
          },
          onContactSupport:
              () => showErrorSupportDialog(
                context: context,
                message: 'If the problem persists, please contact support.',
                title: 'Error',
              ),
        ),
      );
    }

    if (provider.institutionContents.isEmpty) {
      return SliverFillRemaining(
        child: Center(
              child: Image.asset(
                'assets/wawuback.png',
                width: 220, // You can adjust the size as needed
                height: 220,
                fit: BoxFit.contain,
              ),
            ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final content = provider.institutionContents[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: _buildContentItem(context, content),
        );
      }, childCount: provider.institutionContents.length),
    );
  }

  Widget _buildHeaderSection(model.WawuAfricaInstitution? institution) {
    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          // Cover Image
          SizedBox(
            width: double.infinity,
            height: 200,
            child: CachedNetworkImage(
              imageUrl: institution?.coverImageUrl ?? '',
              fit: BoxFit.cover,
              placeholder:
                  (context, url) => Container(color: Colors.grey.shade300),
              errorWidget:
                  (context, url, error) => Container(
                    color: wawuColors.primary.withAlpha(30),
                    child: Icon(
                      Icons.image,
                      size: 60,
                      color: wawuColors.primary.withAlpha(50),
                    ),
                  ),
            ),
          ),

          // Gradient Overlay for Text Visibility
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                stops: const [0.0, 0.5], // Adjust stops for desired fade effect
              ),
            ),
          ),

          // Profile Image
          Positioned(
            bottom: 0,
            left: 20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: institution?.profileImageUrl ?? '',
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(color: Colors.grey.shade300),
                  errorWidget:
                      (context, url, error) => Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: wawuColors.primary.withAlpha(30),
                        ),
                        child: const Icon(
                          Icons.account_balance,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstitutionInfo(model.WawuAfricaInstitution? institution) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          institution?.name ?? 'Institution Name',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          institution?.description ?? 'No description available.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildContentItem(
    BuildContext context,
    model.WawuAfricaInstitutionContent content,
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToContent(context, content),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // MODIFIED: Replaced SizedBox with AspectRatio
            AspectRatio(
              aspectRatio: 4 / 2,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: CachedNetworkImage(
                  imageUrl: content.imageUrl,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(color: Colors.grey.shade200),
                  errorWidget:
                      (context, url, error) => Container(
                        color: wawuColors.primary.withAlpha(30),
                        child: Icon(
                          Icons.image,
                          size: 60,
                          color: wawuColors.primary.withAlpha(50),
                        ),
                      ),
                ),
              ),
            ),

            // Content Text (No changes below this line)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToContent(
    BuildContext context,
    model.WawuAfricaInstitutionContent content,
  ) {
    final provider = Provider.of<WawuAfricaProvider>(context, listen: false);
    provider.selectInstitutionContent(content); // Set the selected content
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WawuAfricaInstitutionContentScreen(),
      ),
    );
  }
}
