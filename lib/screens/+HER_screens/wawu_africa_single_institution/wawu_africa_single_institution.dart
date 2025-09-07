import 'package:flutter/material.dart';
import 'package:wawu_mobile/screens/+HER_screens/wawu_africa_institution_content/wawu_africa_institution_content.dart';

class WawuAfricaSingleInstitution extends StatefulWidget {
  const WawuAfricaSingleInstitution({super.key});

  @override
  State<WawuAfricaSingleInstitution> createState() => _WawuAfricaSingleInstitutionState();
}

class _WawuAfricaSingleInstitutionState extends State<WawuAfricaSingleInstitution> {
  late ScrollController _scrollController;
  bool _isScrolled = false;

  // Dummy data - replace with your backend data
  final List<Map<String, dynamic>> dummyContent = const [
    {
      'id': '1',
      'title': 'African Traditional Medicine',
      'description': 'Exploring the rich heritage of traditional healing practices across Africa',
      'image': 'assets/images/traditional_medicine.jpg',
      'author': 'Dr. Amina Kone',
      'date': '2024-09-01',
    },
    {
      'id': '2',
      'title': 'West African Music Evolution',
      'description': 'The transformation of music from traditional rhythms to modern afrobeats',
      'image': 'assets/images/music_evolution.jpg',
      'author': 'Prof. Kwame Asante',
      'date': '2024-08-28',
    },
    {
      'id': '3',
      'title': 'Contemporary African Art',
      'description': 'Modern artistic expressions and their cultural significance',
      'image': 'assets/images/contemporary_art.jpg',
      'author': 'Dr. Fatima Ibrahim',
      'date': '2024-08-25',
    },
    {
      'id': '4',
      'title': 'African Literature Renaissance',
      'description': 'The new wave of African writers making global impact',
      'image': 'assets/images/literature.jpg',
      'author': 'Prof. Chinua Achebe Jr.',
      'date': '2024-08-22',
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Change app bar appearance when scrolled past header section
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Wawu Africa Institution',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: _isScrolled ? 1.0 : 0.0,
        backgroundColor: _isScrolled 
            ? Theme.of(context).scaffoldBackgroundColor
            : Colors.transparent,
        iconTheme: IconThemeData(
          color: _isScrolled ? Colors.black : Colors.white,
        ),
        titleTextStyle: TextStyle(
          color: _isScrolled ? Colors.black : Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Header Section
          SliverToBoxAdapter(
            child: _buildHeaderSection(),
          ),
          
          // Institution Info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildInstitutionInfo(),
                  const SizedBox(height: 30),
                  const Text(
                    'Content',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          
          // Content List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final content = dummyContent[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: _buildContentItem(context, content),
                );
              },
              childCount: dummyContent.length,
            ),
          ),
          
          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          // Cover Image
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.orange.shade400,
                  Colors.red.shade600,
                ],
              ),
            ),
            child: Image.asset(
              'assets/images/cover_image.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.orange.shade400,
                        Colors.red.shade600,
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.school,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Profile Image (50% overlapping)
          Positioned(
            bottom: 0,
            left: 20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/profile_image.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade400,
                            Colors.purple.shade600,
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.account_balance,
                        size: 60,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstitutionInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Wawu Africa Cultural Institute',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Preserving and promoting African culture, arts, and heritage through research, education, and community engagement.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              Icons.location_on,
              size: 16,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              'Port Harcourt, Rivers State, Nigeria',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContentItem(BuildContext context, Map<String, dynamic> content) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToContent(context, content),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content Image
            Container(
              width: double.infinity,
              height: 180,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Image.asset(
                  content['image'] ?? 'assets/images/placeholder.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.shade300,
                            Colors.purple.shade400,
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.image,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // Content Text
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content['title'] ?? 'Untitled',
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
                    content['description'] ?? 'No description available',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          content['author'] ?? 'Unknown Author',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        content['date'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToContent(BuildContext context, Map<String, dynamic> content) {
    // Example:
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WawuAfricaInstitutionContent(),
      ),
    );
  }
}