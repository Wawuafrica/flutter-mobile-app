// screens/search/search_screen.dart
import 'package:flutter/material.dart';
import 'package:wawu_mobile/utils/constants/colors.dart'; // Assuming wawuColors is defined here

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _searchResults = []; // Dummy list for search results

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    // In a real application, you would call a provider or API to fetch results.
    // For this example, we'll simulate some results.
    setState(() {
      if (query.isEmpty) {
        _searchResults = [];
      } else {
        _searchResults =
            [
                  'Graphic Design gig for "$query"',
                  'Web Development services with "$query"',
                  'Content writing related to "$query"',
                  'Video editing for "$query" projects',
                  'Marketing strategies for "$query" businesses',
                  'UI/UX design for "$query" apps',
                  'Mobile app development for "$query" platforms',
                  'Photography services for "$query" events',
                  'Social media management for "$query" brands',
                  'Data entry and analysis for "$query" reports',
                ]
                .where(
                  (result) =>
                      result.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
      }
    });
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
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _performSearch('');
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
                      color:
                          Theme.of(
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
      body:
          _searchResults.isEmpty && _searchController.text.isEmpty
              ? const Center(
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
              )
              : _searchResults.isEmpty && _searchController.text.isNotEmpty
              ? const Center(
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
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.work_outline,
                        color: wawuColors.primary,
                      ),
                      title: Text(_searchResults[index]),
                      onTap: () {
                        // In a real app, navigate to gig detail screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Tapped on: ${_searchResults[index]}',
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
    );
  }
}
