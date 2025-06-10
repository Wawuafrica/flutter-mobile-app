import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/screens/blog_screen/blog_screen.dart';
import 'package:wawu_mobile/screens/gigs_screen/gigs_screen.dart';
import 'package:wawu_mobile/screens/home_screen/home_screen.dart';
import 'package:wawu_mobile/screens/messages_screen/messages_screen.dart';
import 'package:wawu_mobile/screens/notifications/notifications.dart';
import 'package:wawu_mobile/screens/settings_screen/settings_screen.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
// Import the updated CustomBottomNavigationBar and CustomNavItem
import 'package:wawu_mobile/widgets/custom_bottom_navigation_bar/custom_bottom_navigation_bar.dart';
// Import the User model

class MainScreen extends StatefulWidget {
  final bool isAdmin;

  const MainScreen({super.key, this.isAdmin = false});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();

  // Define screens dynamically based on user role
  List<Widget> _screens = [];
  // Define custom nav items dynamically
  List<CustomNavItem> _customNavItems = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreensAndNavItems(); // Combined initialization
    });
  }

  void _initializeScreensAndNavItems() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;
    final isBuyer = currentUser?.role?.toUpperCase() == 'BUYER';

    setState(() {
      _screens = [
        const HomeScreen(),
        BlogScreen(),
        const MessagesScreen(),
        if (!isBuyer) const GigsScreen(), // Conditionally add GigsScreen
        const SettingsScreen(),
      ];

      // Now create the CustomNavItem list
      _customNavItems = [
        CustomNavItem(iconPath: 'assets/images/svg/home.svg', label: 'Home'),
        CustomNavItem(iconPath: 'assets/images/svg/blog.svg', label: 'Blog'),
        CustomNavItem(
          iconPath: 'assets/images/svg/message.svg',
          label: 'Messages',
        ),
        if (!isBuyer) // Conditionally add Gig item
          CustomNavItem(iconPath: 'assets/images/svg/gigs.svg', label: 'Gigs'),
        CustomNavItem(
          iconPath: 'assets/images/svg/settings.svg',
          label: 'Settings',
        ),
      ];

      // Ensure _selectedIndex doesn't go out of bounds if tabs are removed
      if (_selectedIndex >= _screens.length) {
        _selectedIndex =
            0; // Reset to the first tab if the current one is removed
      }
    });
  }

  List<Widget> _getAppBarTitles() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final List<Widget> titles = [
      Row(
        spacing: 10.0,
        children: [
          Container(
            width: 40,
            height: 40,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(shape: BoxShape.circle),
            child: Image.asset(
              userProvider.currentUser?.profileImage ??
                  'assets/images/other/avatar.webp',
              cacheWidth: 70,
              fit: BoxFit.cover,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hello ${userProvider.currentUser?.firstName}",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              Text(
                "Find Your Gig Today",
                style: TextStyle(fontSize: 11, color: wawuColors.buttonPrimary),
              ),
            ],
          ),
        ],
      ),
      const Text(
        'Blog',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const Text(
        'Messages',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const Text(
        // This will only be reached if GigsScreen is included
        'Gigs',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const Text(
        'Settings',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    ];

    // Filter titles based on the actual screens present
    final currentUser = userProvider.currentUser;
    final isBuyer = currentUser?.role?.toUpperCase() == 'BUYER';

    List<Widget> actualTitles = [];
    actualTitles.add(titles[0]); // Home
    actualTitles.add(titles[1]); // Blog
    actualTitles.add(titles[2]); // Messages
    if (!isBuyer) {
      actualTitles.add(titles[3]); // Gigs (if not buyer)
    }
    actualTitles.add(titles[4]); // Settings

    return actualTitles;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> _getAppBarActions() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;

    if (currentUser?.role?.toUpperCase() == 'BUYER') {
      // If the user is a BUYER, don't show the search bar
      return [
        _buildNotificationsButton(),
        // Add any other actions that buyers should have
      ];
    } else {
      // For other roles, show the search bar and notifications
      return [
        // _buildSearchButton(),
        _buildNotificationsButton(),
      ];
    }
  }

  Widget _buildSearchButton() {
    return Container(
      decoration: BoxDecoration(
        color: wawuColors.primary.withAlpha(30),
        shape: BoxShape.circle,
      ),
      margin: EdgeInsets.only(right: 10),
      height: 36,
      width: 36,
      child: IconButton(
        icon: Icon(Icons.search, size: 17, color: wawuColors.primary),
        onPressed: () {
          setState(() {
            _isSearchOpen = !_isSearchOpen;
          });
        },
      ),
    );
  }

  Widget _buildInPageSearchBar() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      curve: Curves.ease,
      height: _isSearchOpen ? 65 : 0,
      child: ClipRRect(
        child: SizedBox(
          height: _isSearchOpen ? 65 : 0,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
            child:
                _isSearchOpen
                    ? TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search...",
                        hintStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: wawuColors.primary.withAlpha(30),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: wawuColors.primary.withAlpha(60),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: wawuColors.primary),
                        ),
                      ),
                    )
                    : null,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsButton() {
    return Container(
      decoration: BoxDecoration(
        color: wawuColors.purpleDarkestContainer,
        shape: BoxShape.circle,
      ),
      margin: const EdgeInsets.only(right: 10),
      height: 36,
      width: 36,
      child: IconButton(
        icon: const Icon(Icons.notifications, size: 17, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Notifications()),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> appBarTitles =
        _getAppBarTitles(); // Get titles dynamically

    return Scaffold(
      appBar: AppBar(
        title: appBarTitles[_selectedIndex],
        automaticallyImplyLeading: false,
        actions: _getAppBarActions(),
      ),
      body: Column(
        children: [
          _buildInPageSearchBar(),
          const SizedBox.shrink(),
          Expanded(
            child: IndexedStack(index: _selectedIndex, children: _screens),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        items:
            _customNavItems, // Pass the dynamically generated CustomNavItem list
      ),
    );
  }
}
