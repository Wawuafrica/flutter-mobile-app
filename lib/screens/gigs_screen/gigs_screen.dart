import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/gig_provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/screens/gigs_screen/create_gig_screen/create_gig_screen.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/gig_card/gig_card.dart';

class GigsScreen extends StatelessWidget {
  const GigsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
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
                    Tab(text: 'Archived'),
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
                      GigTab(status: 'ARCHIVED', key: UniqueKey()),
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
    if (_isInitialLoad) setState(() => _isInitialLoad = true);

    final gigProvider = Provider.of<GigProvider>(context, listen: false);
    await gigProvider.fetchGigs(status: widget.status);

    if (mounted) {
      setState(() {
        _isInitialLoad = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    await _loadGigs();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<GigProvider>(
      builder: (context, provider, child) {
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

        // Show empty state
        if (gigs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'No gigs found',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _onRefresh,
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          );
        }

        // Show content with pull-to-refresh
        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: _onRefresh,
              color: wawuColors.primary,
              child: ListView.builder(
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
        );
      },
    );
  }
}
