import 'package:flutter/material.dart';
import 'package:wawu_mobile/screens/services/service_detailed/service_detailed.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_intro_text/custom_intro_text.dart';

class Services extends StatefulWidget {
  const Services({super.key});

  @override
  State<Services> createState() => _ServicesState();
}

class _ServicesState extends State<Services> {
  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Services'),
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
            SizedBox(height: 10),
            CustomIntroText(text: 'Professional Categories'),
            SizedBox(height: 20),
            _buildItem(),
            SizedBox(height: 10),
            _buildItem(),
            SizedBox(height: 10),
            _buildItem(),
            SizedBox(height: 10),
            _buildItem(),
            SizedBox(height: 10),
            _buildItem(),
            SizedBox(height: 10),
            _buildItem(),
            SizedBox(height: 10),
            _buildItem(),
            SizedBox(height: 10),
            _buildItem(),
            SizedBox(height: 10),
            _buildItem(),
            SizedBox(height: 10),
            _buildItem(),
            SizedBox(height: 30),
            CustomIntroText(text: 'Artisan Categories'),
            SizedBox(height: 20),
            _buildItem(),
            SizedBox(height: 10),
            _buildItem(),
            SizedBox(height: 10),
            _buildItem(),
            SizedBox(height: 10),
            _buildItem(),
            SizedBox(height: 10),
            _buildItem(),
            SizedBox(height: 10),
            _buildItem(),
            SizedBox(height: 10),
            _buildItem(),
            SizedBox(height: 10),
            _buildItem(),
            SizedBox(height: 10),
            _buildItem(),
            SizedBox(height: 10),
            _buildItem(),
          ],
        ),
      ),
    );
  }

  Widget _buildItem() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ServiceDetailed()),
        );
      },
      child: Container(
        padding: EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color.fromARGB(255, 235, 235, 235)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Digital Marketing',
              style: TextStyle(
                fontSize: 14,
                // fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
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
