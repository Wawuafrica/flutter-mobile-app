// screens/search/search_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/gig_provider.dart';
import 'package:wawu_mobile/utils/constants/colors.dart'; // Assuming wawuColors is defined here
import 'package:wawu_mobile/widgets/gig_card/gig_card.dart'; // Import the GigCard widget

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isNotEmpty) {
      Provider.of<GigProvider>(context, listen: false).searchGigs(query);
    } else {
      // Clear search results if query is empty
      Provider.of<GigProvider>(context, listen: false).searchResults.clear();
      Provider.of<GigProvider>(context, listen: false).safeNotifyListeners(); // Notify to clear results
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(
            right: 16.0,
          ), // Added padding to the right
          child: Hero(
            tag:
                'searchBar', // Same tag as in HomeScreen for the Hero animation
            child: Material(
              color: Colors.transparent,
              child: TextField(
                controller: _searchController,
                autofocus: true, // Automatically focus the search bar
                onChanged: _performSearch,
                decoration: InputDecoration(
                  hintText: 'Search for gigs...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch(''); // Clear search results
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      10.0,
                    ), // Less border radius
                    borderSide: BorderSide(
                      color: wawuColors.borderPrimary.withOpacity(
                        0.5,
                      ), // Border color
                      width: 1.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      10.0,
                    ), // Less border radius
                    borderSide: BorderSide(
                      color: wawuColors.borderPrimary.withOpacity(
                        0.5,
                      ), // Border color
                      width: 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      10.0,
                    ), // Less border radius
                    borderSide: BorderSide(
                      color: Theme.of(
                        context,
                      ).primaryColor, // Focused border color
                      width: 2.0,
                    ),
                  ),
                  filled: false, // Not filled
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 15.0,
                    horizontal: 10.0,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Consumer<GigProvider>(
        builder: (context, gigProvider, child) {
          if (gigProvider.isSearching) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (gigProvider.searchResults.isEmpty && _searchController.text.isNotEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sentiment_dissatisfied,
                    size: 60,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No gigs found for your search.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          } else if (gigProvider.searchResults.isEmpty && _searchController.text.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Start typing to search for gigs!',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          } else {
            return GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Two items per row
                crossAxisSpacing: 5.0,
                mainAxisSpacing: 5.0,
                childAspectRatio: 0.75, // Adjust as needed to fit the GigCard
              ),
              itemCount: gigProvider.searchResults.length,
              itemBuilder: (context, index) {
                return GigCard(gig: gigProvider.searchResults[index]);
              },
            );
          }
        },
      ),
    );
  }
}