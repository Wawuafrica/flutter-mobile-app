import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Collapsing Header with SliverAppBar',
      theme: ThemeData(primarySwatch: Colors.purple),
      debugShowCheckedModeBanner: false,
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatelessWidget {
  const DemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    // These constants are now used directly by the SliverAppBar
    const double expandedHeight = 300;
    const double collapsedHeight = kToolbarHeight; // Default app bar height

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Use SliverAppBar for a standard collapsing/expanding header
          SliverAppBar(
            pinned: true,
            expandedHeight: expandedHeight,
            collapsedHeight: collapsedHeight,
            // The leading widget is for the back button, which is standard
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.maybePop(context),
            ),
            // The flexibleSpace is where the "hero" content goes,
            // including the background image and the title animation.
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 60, bottom: 30), // Increased bottom padding
              // The title animates its opacity and position as it collapses
              title: Text(
                'Welcome To WAWUAfrica',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // The background image
                  Image.network(
                    'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?ixlib=rb-4.0.3&auto=format&fit=crop&w=2070&q=80',
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
                  // A gradient overlay for better text readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.25),
                          Colors.transparent,
                          Colors.white.withOpacity(0.3),
                          Colors.white.withOpacity(0.95),
                          Colors.white,
                        ],
                        stops: const [0.0, 0.18, 0.55, 0.85, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // The SliverToBoxAdapter holds the scrollable content.
          SliverToBoxAdapter(
            child: Column(
              children: [
               Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildProfileSection(),
                ),
                
                // A list of simple cards to show the scrolling behavior.
                for (var i = 0; i < 15; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildCard('Card Section ${i + 1}'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // A helper method to build the profile section
  static Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage(
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Excel Patrick',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Verified Seller',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Colors.purple,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.message, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // A helper method to build the simple card sections
  static Widget _buildCard(String title) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'This is a placeholder card to demonstrate the scrolling and stacking effect.',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
