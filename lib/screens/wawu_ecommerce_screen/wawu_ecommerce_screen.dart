import 'package:flutter/material.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/e_card/e_card.dart';

class WawuEcommerceScreen extends StatefulWidget {
  const WawuEcommerceScreen({super.key});

  @override
  State<WawuEcommerceScreen> createState() => _WawuEcommerceScreenState();
}

class _WawuEcommerceScreenState extends State<WawuEcommerceScreen> {
  int _selectedIndex = 0;
  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wawu E-commerce'),
        actions: [
          Container(
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
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: ListView(
          children: [
            _buildInPageSearchBar(),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 10.0,
              children: [
                Expanded(child: ECard(isMargin: false)),
                Expanded(child: ECard(isMargin: false)),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 10.0,
              children: [
                Expanded(child: ECard(isMargin: false)),
                Expanded(child: ECard(isMargin: false)),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 10.0,
              children: [
                Expanded(child: ECard(isMargin: false)),
                Expanded(child: ECard(isMargin: false)),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 10.0,
              children: [
                Expanded(child: ECard(isMargin: false)),
                Expanded(child: ECard(isMargin: false)),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 10.0,
              children: [
                Expanded(child: ECard(isMargin: false)),
                Expanded(child: ECard(isMargin: false)),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 10.0,
              children: [
                Expanded(child: ECard(isMargin: false)),
                Expanded(child: ECard(isMargin: false)),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 10.0,
              children: [
                Expanded(child: ECard(isMargin: false)),
                Expanded(child: ECard(isMargin: false)),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 10.0,
              children: [
                Expanded(child: ECard(isMargin: false)),
                Expanded(child: ECard(isMargin: false)),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 10.0,
              children: [
                Expanded(child: ECard(isMargin: false)),
                Expanded(child: ECard(isMargin: false)),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 10.0,
              children: [
                Expanded(child: ECard(isMargin: false)),
                Expanded(child: ECard(isMargin: false)),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 10.0,
              children: [
                Expanded(child: ECard(isMargin: false)),
                Expanded(child: ECard(isMargin: false)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInPageSearchBar() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      curve: Curves.ease,
      height: _isSearchOpen ? 55 : 0,
      child: ClipRRect(
        child: SizedBox(
          height: _isSearchOpen ? 55 : 0,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 0.0, vertical: 10.0),
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
}
