import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
// import 'package:wawu_mobile/screens/notifications/notifications.dart';
import 'package:wawu_mobile/screens/settings_screen/merch_settings_screen.dart';
import 'package:wawu_mobile/screens/wawu_merch/wawu_merch_home/wawu_merch_home.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
// Import CustomNavItem along with CustomBottomNavigationBar
import 'package:wawu_mobile/widgets/custom_bottom_navigation_bar/custom_bottom_navigation_bar.dart';

class WawuMerchMain extends StatefulWidget {
  const WawuMerchMain({super.key});

  @override
  State<WawuMerchMain> createState() => _WawuMerchMainState();
}

class _WawuMerchMainState extends State<WawuMerchMain> {
  int _selectedIndex = 0;
  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();

  final List<Widget> _screens = [WawuMerchHome(), MerchSettingsScreen()];

  // Fixed _titles list - moved userProvider access to build method
  List<Widget> _getTitles(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return [
      Row(
        children: [
          Container(
            width: 40,
            height: 40,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(shape: BoxShape.circle),
            child:
                userProvider.currentUser?.profileImage != null &&
                        userProvider.currentUser!.profileImage!.startsWith(
                          'http',
                        )
                    ? Image.network(
                      userProvider.currentUser!.profileImage!,
                      cacheWidth: 70,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Image.asset(
                            'assets/images/other/avatar.webp',
                            cacheWidth: 250,
                            fit: BoxFit.cover,
                          ),
                    )
                    : Image.asset(
                      userProvider.currentUser?.profileImage ??
                          'assets/images/other/avatar.webp',
                      cacheWidth: 250,
                      fit: BoxFit.cover,
                    ),
          ),
          SizedBox(width: 10.0), // Replaced spacing with SizedBox
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hello ${userProvider.currentUser?.firstName ?? 'User'}",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              Text(
                "Welcome to Wawu-Merch",
                style: TextStyle(fontSize: 11, color: wawuColors.buttonPrimary),
              ),
            ],
          ),
        ],
      ),
      Text("Settings"),
    ];
  }

  // Define the CustomNavItems for WawuMerchMain
  final List<CustomNavItem> _merchNavItems = [
    CustomNavItem(iconPath: 'assets/images/svg/home.svg', label: 'Home'),
    CustomNavItem(
      iconPath: 'assets/images/svg/settings.svg',
      label: 'Settings',
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _isSearchOpen = false; // Close search when switching pages
    });
  }

  List<Widget> _getAppBarActions() {
    switch (_selectedIndex) {
      case 0: // WawuMerchHome: Search and Notifications
        return [];
      case 1: // MerchSettingsScreen: No actions
        return [];
      default:
        return [];
    }
  }

  // Widget _buildSearchButton() {
  //   return Container(
  //     decoration: BoxDecoration(
  //       color: wawuColors.primary.withAlpha(30),
  //       shape: BoxShape.circle,
  //     ),
  //     margin: EdgeInsets.only(right: 10),
  //     height: 36,
  //     width: 36,
  //     child: IconButton(
  //       icon: Icon(Icons.search, size: 17, color: wawuColors.primary),
  //       onPressed: () {
  //         setState(() {
  //           _isSearchOpen = !_isSearchOpen;
  //         });
  //       },
  //     ),
  //   );
  // }

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

  // Widget _buildNotificationsButton() {
  //   return Container(
  //     decoration: BoxDecoration(
  //       color: wawuColors.purpleDarkestContainer,
  //       shape: BoxShape.circle,
  //     ),
  //     margin: EdgeInsets.only(right: 10),
  //     height: 36,
  //     width: 36,
  //     child: IconButton(
  //       icon: Icon(Icons.notifications, size: 17, color: Colors.white),
  //       onPressed: () {
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(builder: (context) => Notifications()),
  //         );
  //       },
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final titles = _getTitles(context);

    return Scaffold(
      appBar: AppBar(
        title: titles[_selectedIndex],
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
        items: _merchNavItems,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
