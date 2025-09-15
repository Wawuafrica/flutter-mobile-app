import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/wawu_africa_provider.dart';
import 'package:wawu_mobile/screens/+HER_screens/wawu_africa_sub_category/wawu_africa_sub_category.dart';
import 'package:wawu_mobile/screens/search/search_screen.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_intro_text/custom_intro_text.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final wawuAfricaProvider = Provider.of<WawuAfricaProvider>(context);
    final categories = wawuAfricaProvider.categories;
    final screenHeight = MediaQuery.of(context).size.height;
    final double statusBarHeight = MediaQuery.of(context).viewPadding.top + 50;
    final totalHeaderHeight = screenHeight * 0.6;

    // MODIFICATION: The root widget is now the Stack itself.
    // This allows the Stack to size itself based on its non-positioned children,
    // solving the infinite height error.
    return Stack(
      children: [
        // LAYER 1: BACKGROUND (STILL POSITIONED TO FILL THE STACK)
        // This will now expand to whatever size the foreground content dictates.
        Positioned.fill(
          child: ClipRRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/background_wawu.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.error),
                    );
                  },
                ),
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
                  child: Container(color: Colors.black.withOpacity(0.4)),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Theme.of(context).scaffoldBackgroundColor,
                      ],
                      stops: const [0.1, 0.9],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // LAYER 2: FOREGROUND (NOT POSITIONED)
        // By not wrapping this in Positioned.fill, this Column now defines
        // the Stack's height. The layout is now determined by the content.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            // This ensures the column doesn't try to shrink-wrap, which can cause issues.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status bar height spacing
              SizedBox(height: statusBarHeight + 66.0),

              // Search Bar Section
              SizedBox(
                height: 50.0,
                child: Hero(
                  tag: 'searchBar',
                  child: Material(
                    color: Colors.transparent,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.0,
                            ),
                          ),
                          child: TextField(
                            readOnly: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  transitionDuration: const Duration(
                                    milliseconds: 300,
                                  ),
                                  pageBuilder: (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                  ) =>
                                      const SearchScreen(),
                                  transitionsBuilder: (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                                ),
                              );
                            },
                            decoration: InputDecoration(
                              hintText: 'Search for gigs...',
                              hintStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w400,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Colors.white,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: const BorderSide(
                                  color: Colors.transparent,
                                  width: 1.0,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: const BorderSide(
                                  color: Colors.transparent,
                                  width: 1.0,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 2.0,
                                ),
                              ),
                              filled: false,
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
                ),
              ),

              const SizedBox(height: 20.0),

              // WAWUAfrica +HER Text
              const CustomIntroText(
                text: 'WAWUAfrica +HER',
                color: Colors.white,
              ),
              
              const SizedBox(height: 20.0),

              // ==== START: REPLACED GRIDVIEW WITH MANUAL LAYOUT ====
              Container(
                // Note: For the header to truly be dynamic, you might need to
                // remove this fixed height in the future. For now, it works.
                constraints: BoxConstraints(
                  minHeight: totalHeaderHeight * 0.45,
                ),
                color: Colors.transparent,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // --- ROW 1 ---
                    Row(
                      children: [
                        Expanded(
                          child: categories.isNotEmpty
                              ? _buildCategoryItem(
                                  context,
                                  wawuAfricaProvider,
                                  categories[0],
                                )
                              : const SizedBox(),
                        ),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: categories.length > 1
                              ? _buildCategoryItem(
                                  context,
                                  wawuAfricaProvider,
                                  categories[1],
                                )
                              : const SizedBox(),
                        ),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: categories.length > 2
                              ? _buildCategoryItem(
                                  context,
                                  wawuAfricaProvider,
                                  categories[2],
                                )
                              : const SizedBox(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10.0), // Vertical spacing
                    // --- ROW 2 ---
                    Row(
                      children: [
                        Expanded(
                          child: categories.length > 3
                              ? _buildCategoryItem(
                                  context,
                                  wawuAfricaProvider,
                                  categories[3],
                                )
                              : const SizedBox(),
                        ),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: categories.length > 4
                              ? _buildCategoryItem(
                                  context,
                                  wawuAfricaProvider,
                                  categories[4],
                                )
                              : const SizedBox(),
                        ),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: categories.length > 5
                              ? _buildCategoryItem(
                                  context,
                                  wawuAfricaProvider,
                                  categories[5],
                                )
                              : const SizedBox(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // ==== END: REPLACEMENT ====

              // Add some final padding at the bottom so the gradient fades nicely.
              const SizedBox(height: 20.0),
            ],
          ),
        ),
      ],
    );
  }

  // ==== HELPER WIDGET FOR CREATING EACH CATEGORY ITEM ====
  Widget _buildCategoryItem(
    BuildContext context,
    WawuAfricaProvider wawuAfricaProvider,
    dynamic category,
  ) {
    return AspectRatio(
      aspectRatio: 0.9,
      child: GestureDetector(
        onTap: () {
          wawuAfricaProvider.selectCategory(category);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WawuAfricaSubCategory(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(
              color: const Color.fromARGB(255, 201, 201, 201).withOpacity(0.2),
              width: 1.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.network(
                category.imageUrl,
                width: 40,
                height: 40,
                fit: BoxFit.contain,
                placeholderBuilder: (context) => const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    color: wawuColors.purpleDarkestContainer,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: wawuColors.purpleDarkestContainer,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}