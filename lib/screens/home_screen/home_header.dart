import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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
    final screenHeight = MediaQuery.of(context).size.height;
    // --- FIX START ---
    final double statusBarHeight = MediaQuery.of(context).viewPadding.top + 50;
    // --- FIX END ---
    final totalHeaderHeight = screenHeight * 0.6;

    return SizedBox(
      width: double.infinity,
      height: totalHeaderHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // LAYER 1: BACKGROUND (CLIPPED)
          // This part is fine and doesn't need changes.
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

          // LAYER 2: FOREGROUND (NOT CLIPPED)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- FIX START ---
                  // Replace the hardcoded height with the dynamic status bar height
                  // plus any additional margin you want.
                  SizedBox(height: statusBarHeight + 26.0), // Adjust 26.0 as needed
                  // --- FIX END ---

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
                                      pageBuilder:
                                          (
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

                  const SizedBox(height: 30.0),

                  // WAWUAfrica +HER Text
                  const CustomIntroText(
                    text: 'WAWUAfrica +HER',
                    color: Colors.white,
                  ),

                  // Use Expanded and LayoutBuilder for a robust, dynamic grid
                  Expanded(
                    child: Transform.translate(
                      offset: const Offset(0, -80),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const double gridSpacing = 10.0;
                          const int crossAxisCount = 3;
                          const int rowCount = 2;

                          // The specific pixel offset caused by the Stack's layout behavior
                          const double layoutErrorOffset = 66.0;

                          // Correct the available height by subtracting the offset
                          final double correctedHeight =
                              constraints.maxHeight - layoutErrorOffset;

                          final double itemWidth =
                              (constraints.maxWidth -
                                      (gridSpacing * (crossAxisCount - 1))) /
                                  crossAxisCount;

                          final double itemHeight = (correctedHeight -
                                  (gridSpacing * (rowCount - 1))) /
                              rowCount;

                          // Prevent errors if constraints are zero or negative
                          if (itemHeight <= 0 || itemWidth <= 0) {
                            return const SizedBox.shrink();
                          }

                          return GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: wawuAfricaProvider.categories.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: gridSpacing,
                              mainAxisSpacing: gridSpacing,
                              childAspectRatio: itemWidth / itemHeight,
                            ),
                            itemBuilder: (context, index) {
                              final category =
                                  wawuAfricaProvider.categories[index];
                              return GestureDetector(
                                onTap: () {
                                  wawuAfricaProvider.selectCategory(category);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const WawuAfricaSubCategory(),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(10.0),
                                    border: Border.all(
                                      color: const Color.fromARGB(
                                              255, 201, 201, 201)
                                          .withOpacity(0.2),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                        child: CachedNetworkImage(
                                          imageUrl: category.imageUrl,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.contain,
                                          placeholder: (context, url) =>
                                              const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.0,
                                              color: wawuColors
                                                  .purpleDarkestContainer,
                                            ),
                                          ),
                                          errorWidget: (
                                            context,
                                            url,
                                            error,
                                          ) =>
                                              const Icon(
                                            Icons.image_not_supported,
                                            color: wawuColors
                                                .purpleDarkestContainer,
                                            size: 50,
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
                                          color:
                                              wawuColors.purpleDarkestContainer,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}