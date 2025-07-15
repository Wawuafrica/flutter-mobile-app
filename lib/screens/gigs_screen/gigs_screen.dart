import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/gig_provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/screens/gigs_screen/create_gig_screen/create_gig_screen.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/gig_card/gig_card.dart';
import 'package:wawu_mobile/widgets/custom_snackbar.dart'; // Import CustomSnackBar
import 'package:wawu_mobile/widgets/full_ui_error_display.dart'; // Import FullErrorDisplay

class GigsScreen extends StatelessWidget {
  const GigsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            if (userProvider.currentUser?.uuid == null) {
              return const Center(child: Text('Please log in to view gigs'));
            }

            return Column(
              children: [
                const TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'All'),
                    Tab(text: 'Pending'),
                    Tab(text: 'Verified'),
                    // Tab(text: 'Archived'),
                    Tab(text: 'Rejected'),
                  ],
                ),
                // Wrap TabBarView with Expanded to give it bounded height
                Expanded(
                  child: TabBarView(
                    children: [
                      GigTab(status: null, key: UniqueKey()),
                      GigTab(status: 'PENDING', key: UniqueKey()),
                      GigTab(status: 'VERIFIED', key: UniqueKey()),
                      // GigTab(status: 'ARCHIVED', key: UniqueKey()),
                      GigTab(status: 'REJECTED', key: UniqueKey()),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateGigScreen()),
            );
          },
          backgroundColor: wawuColors.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

class GigTab extends StatefulWidget {
  final String? status;

  const GigTab({super.key, this.status});

  @override
  _GigTabState createState() => _GigTabState();
}

class _GigTabState extends State<GigTab> with AutomaticKeepAliveClientMixin {
  bool _isInitialLoad = true;
  bool _isRefreshing = false;
  bool _hasShownError = false; // Flag to prevent multiple snackbars

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGigs();
    });
  }

  Future<void> _loadGigs() async {
    // Only set _isInitialLoad to true if it's genuinely the first load
    // and not a refresh triggered by pull-to-refresh.
    if (_isInitialLoad) {
      setState(() => _isInitialLoad = true);
    }

    final gigProvider = Provider.of<GigProvider>(context, listen: false);
    await gigProvider.fetchGigs(status: widget.status);

    if (mounted) {
      setState(() {
        _isInitialLoad = false;
        _isRefreshing = false; // Reset refreshing state after load
      });
    }
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing) return; // Prevent multiple refresh calls

    setState(() => _isRefreshing = true);
    // Call _loadGigs, which will internally handle the provider's loading state
    await _loadGigs();
  }

  // Function to show the support dialog (can be reused)
  void _showErrorSupportDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: const Text(
            'Contact Support',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: wawuColors.primary,
            ),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700]),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'OK',
                style: TextStyle(color: wawuColors.buttonSecondary),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<GigProvider>(
      builder: (context, provider, child) {
        // Only show snackbar for errors when there's existing data
        // This prevents conflict with FullErrorDisplay
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final gigs = provider.gigsForStatus(widget.status);
          if (provider.hasError &&
              provider.errorMessage != null &&
              !_hasShownError &&
              gigs.isNotEmpty) {
            // Only show snackbar when there's existing data
            CustomSnackBar.show(
              context,
              message: provider.errorMessage!,
              isError: true,
              actionLabel: 'RETRY',
              onActionPressed: () {
                provider.fetchGigs(status: widget.status);
              },
            );
            _hasShownError = true;
            // Clear error state with delay
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                provider.clearError();
              }
            });
          } else if (!provider.hasError && _hasShownError) {
            _hasShownError = false;
          }
        });

        final gigs = provider.gigsForStatus(widget.status);
        final bool isLoading = provider.isLoading && _isInitialLoad;

        // Show loading indicator on initial load
        if (isLoading && gigs.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(wawuColors.primary),
            ),
          );
        }

        // Show full error display if there's an error and no gigs are loaded
        if (provider.hasError && gigs.isEmpty && !isLoading) {
          return FullErrorDisplay(
            errorMessage:
                provider.errorMessage ??
                'Failed to load gigs. Please try again.',
            onRetry: () {
              provider.fetchGigs(status: widget.status);
            },
            onContactSupport: () {
              _showErrorSupportDialog(
                context,
                'If this problem persists, please contact our support team. We are here to help!',
              );
            },
          );
        }

        // Show empty state
        if (gigs.isEmpty) {
          return RefreshIndicator(
            onRefresh: _onRefresh,
            color: wawuColors.primary,
            child: Stack(
              children: [
                ListView(), // Needed for the indicator to work with RefreshIndicator
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.sentiment_dissatisfied_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.status == null
                            ? 'No gigs available yet.'
                            : 'No ${widget.status?.toLowerCase()} gigs found.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pull down to refresh or create a new gig.',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // Show content with pull-to-refresh
        return RefreshIndicator(
          onRefresh: _onRefresh,
          color: wawuColors.primary,
          child: Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 20.0,
                ),
                itemCount: gigs.length,
                itemBuilder: (context, index) {
                  final gig = gigs[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: GigCard(gig: gig),
                  );
                },
              ),
              if (_isRefreshing)
                const Positioned(
                  top: 20.0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          wawuColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
