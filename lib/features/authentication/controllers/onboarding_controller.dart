import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class OnBoardingProvider with ChangeNotifier {
  final pageController = PageController();
  int _currentIndex = 0;
  bool _hasSeenOnboarding = false;
  int get currentIndex => _currentIndex;
  bool get hasSeenOnboarding => _hasSeenOnboarding;

  OnBoardingProvider() {
    Future.microtask(() => loadOnboardingStatus());
  }

  // ✅ Load onboarding status from SharedPreferences
  Future<void> loadOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading onboarding status: $e");
    }
  }

  /// Update current index when page scrolls
  void updatePageIndicator(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  /// Jump to the specific dot selected page
  void dotNavigationClick(int index) {
    _currentIndex = index;
    pageController.jumpToPage(index); // ✅ Use `pageController` directly
    notifyListeners();
  }


  /// Update current index and jump to the next screen
  // ✅ Function to go to the next page or login screen
  Future<void> nextPage(BuildContext context) async {
    if (_currentIndex < 2) { // Assuming 3 pages (0,1,2)
      _currentIndex++;
      pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
      notifyListeners();
    } else {
      await completeOnboarding(context);
    }
  }


  // ✅ Save onboarding completion and navigate
  Future<void> completeOnboarding(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenOnboarding', true);
      _hasSeenOnboarding = true;
      notifyListeners();

      // ✅ Navigate after state update
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, "/login");
      }
    } catch (e) {
      debugPrint("Error saving onboarding status: $e");
    }
  }


  /// Update current index & jump to the last page
  // ✅ Skip onboarding and go to login screen
  Future<void> skipPage(BuildContext context) async {
    await completeOnboarding(context);
  }
}

