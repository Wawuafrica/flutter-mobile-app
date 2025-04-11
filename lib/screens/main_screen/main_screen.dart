import 'package:flutter/material.dart';
import 'package:wawu_mobile/screens/blog_screen/blog_screen.dart';
import 'package:wawu_mobile/screens/gigs_screen/gigs_screen.dart';
import 'package:wawu_mobile/screens/home_screen/home_screen.dart';
import 'package:wawu_mobile/screens/messages_screen/messages_screen.dart';
import 'package:wawu_mobile/screens/notifications/notifications.dart';
import 'package:wawu_mobile/screens/settings_screen/settings_screen.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_bottom_navigation_bar/custom_bottom_navigation_bar.dart';

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

  final List<Widget> _screens = [
    HomeScreen(),
    BlogScreen(),
    MessagesScreen(),
    GigsScreen(),
    SettingsScreen(),
  ];

  final List<Widget> _titles = [
    Row(
      spacing: 10.0,
      children: [
        Container(
          width: 40,
          height: 40,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(shape: BoxShape.circle),
          child: Image.asset(
            'assets/images/other/avatar.webp',
            cacheWidth: 40,
            fit: BoxFit.cover,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hello Mavis",
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
    Text("Blog"),
    Text("Messages"),
    Text("Gigs"),
    Text("Settings"),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _isSearchOpen = false; // Close search when switching pages
    });
  }

  List<Widget> _getAppBarActions() {
    switch (_selectedIndex) {
      case 0: // HomeScreen: Search and Notifications
      case 1: // BlogScreen: Search and Notifications
      case 2: // MessagesScreen: Search and Notifications
      case 3: // GigsScreen: Search and Notifications
        return [_buildSearchButton(), _buildNotificationsButton()];
      case 4: // SettingsScreen: No actions
        return [];
      default:
        return [];
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

  /// Smoothly Animated Search Bar
  Widget _buildInPageSearchBar() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      curve: Curves.ease,
      height: _isSearchOpen ? 55 : 0,
      child: ClipRRect(
        child: SizedBox(
          height: _isSearchOpen ? 55 : 0,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
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
      margin: EdgeInsets.only(right: 10),
      height: 36,
      width: 36,
      child: IconButton(
        icon: Icon(Icons.notifications, size: 17, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Notifications()),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _titles[_selectedIndex],
        automaticallyImplyLeading: false,
        actions: _getAppBarActions(),
      ),
      body: Column(
        children: [
          _buildInPageSearchBar(),
          Expanded(
            child: IndexedStack(index: _selectedIndex, children: _screens),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
