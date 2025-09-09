import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/models/gig.dart';
import 'package:wawu_mobile/providers/category_provider.dart';
import 'package:wawu_mobile/providers/gig_provider.dart';
import 'package:wawu_mobile/screens/search/search_screen.dart';
import 'package:wawu_mobile/widgets/gig_card/gig_card.dart';
import 'package:wawu_mobile/widgets/gig_card/horizontal_grid_card.dart';

class FilteredGigs extends StatefulWidget {
  const FilteredGigs({super.key});

  @override
  State<FilteredGigs> createState() => _FilteredGigsState();
}

class _FilteredGigsState extends State<FilteredGigs> {
  List<Gig> _gigs = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchGigs();
    });
  }

  Future<void> _fetchGigs() async {
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );
    final gigProvider = Provider.of<GigProvider>(context, listen: false);
    final selectedService = categoryProvider.selectedService;

    if (selectedService == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No service selected';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final gigs = await gigProvider.fetchGigsBySubCategory(
        selectedService.uuid,
      );
      if (mounted) {
        setState(() {
          _gigs = gigs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load gigs: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final selectedService = categoryProvider.selectedService;
    final serviceName = selectedService?.name ?? 'Gigs';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FC),
      body: RefreshIndicator(
        onRefresh: _fetchGigs,
        child: CustomScrollView(
          slivers: [
            // HEADER: This is the new header design
            SliverAppBar(
              expandedHeight: 300.0,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRect(
                        // Prevents the zoomed image from overflowing
                        child: Transform.scale(
                          scale:
                              1.5, // Zoom factor. 1.0 is normal, 1.5 is 50% zoom.
                          child: Image.asset(
                            'assets/background_wawu.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
                      child: Container(color: Colors.black.withOpacity(0.2)),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            const Color(0xFFF8F5FC),
                            const Color(0xFFF8F5FC).withOpacity(0.0),
                          ],
                          stops: const [0.0, 0.9],
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(
                            top: 60, left: 16, right: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              serviceName, // Dynamic title
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              readOnly: true,
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const SearchScreen())),
                              decoration: InputDecoration(
                                hintText: 'Search for Gigs',
                                hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.8)),
                                prefixIcon: const Icon(Icons.search,
                                    color: Colors.white70),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.2),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 0),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (!_isLoading) // Show count only after loading
                              Text(
                                '${_gigs.length} Gigs Found', // Dynamic results
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            // BODY: The content is now built with slivers
            _buildBodySlivers(),
          ],
        ),
      ),
    );
  }

  Widget _buildBodySlivers() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading gigs...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: _fetchGigs, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    if (_gigs.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Text(
            'No gigs available for this service',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: HorizontalGigCard(gig: _gigs[index]),
            );
          },
          childCount: _gigs.length,
        ),
      ),
    );
  }
}