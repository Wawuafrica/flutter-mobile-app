import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/models/gig.dart';
import 'package:wawu_mobile/providers/category_provider.dart';
import 'package:wawu_mobile/providers/gig_provider.dart';
import 'package:wawu_mobile/widgets/gig_card/gig_card.dart';

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
      setState(() {
        _isLoading = false;
        _errorMessage = 'No service selected';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final gigs = await gigProvider.fetchGigsBySubCategory(
        selectedService.uuid,
      );
      setState(() {
        _gigs = gigs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load gigs: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        final selectedService = categoryProvider.selectedService;
        final serviceName = selectedService?.name ?? 'Search';

        return Scaffold(
          appBar: AppBar(title: Text(serviceName)),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: _buildBody(),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading gigs...',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
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
      );
    }

    if (_gigs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'No gigs available for this service',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchGigs,
      child: ListView.builder(
        itemCount: _gigs.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: GigCard(gig: _gigs[index]),
          );
        },
      ),
    );
  }
}
