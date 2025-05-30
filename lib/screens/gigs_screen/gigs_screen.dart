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
        appBar: AppBar(
          title: const Text('Gigs'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Pending'),
              Tab(text: 'Verified'),
              Tab(text: 'Archived'),
              Tab(text: 'Rejected'),
            ],
          ),
        ),
        body: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            if (userProvider.currentUser?.uuid == null) {
              return const Center(child: Text('Please log in to view gigs'));
            }

            // final gigProvider = Provider.of<GigProvider>(context, listen: false);
            return TabBarView(
              children: [
                GigTab(status: null, key: UniqueKey()),
                GigTab(status: 'PENDING', key: UniqueKey()),
                GigTab(status: 'VERIFIED', key: UniqueKey()),
                GigTab(status: 'ARCHIVED', key: UniqueKey()),
                GigTab(status: 'REJECTED', key: UniqueKey()),
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
  bool _hasFetched = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final gigProvider = Provider.of<GigProvider>(context, listen: false);

    if (!_hasFetched) {
      gigProvider.fetchGigs(status: widget.status);
      _hasFetched = true;
    }

    return Consumer<GigProvider>(
      builder: (context, provider, child) {
        final gigs = provider.gigsForStatus(widget.status);

        if (gigs.isEmpty && !_hasFetched) {
          return const Center(child: CircularProgressIndicator());
        }

        if (gigs.isEmpty) {
          return const Center(child: Text('No gigs found'));
        }

        return RefreshIndicator(
          onRefresh: () => gigProvider.fetchGigs(status: widget.status),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: ListView.builder(
              itemCount: gigs.length,
              itemBuilder: (context, index) {
                final gig = gigs[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: GigCard(gig: gig),
                );
              },
            ),
          ),
        );
      },
    );
  }
}