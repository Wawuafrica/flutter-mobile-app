import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Keys for onboarding state persistence
class OnboardingKeys {
  static const String onboardingStep = 'onboarding_step';
  static const String onboardingComplete = 'onboarding_complete';
  static const String onboardingRole = 'onboarding_role';
  static const String onboardingCategory = 'onboarding_category';
  static const String onboardingSubCategory = 'onboarding_subcategory';
  static const String onboardingPlan = 'onboarding_plan';
}

/// Service for managing onboarding progress persistence
class OnboardingStateService {
  /// Save the current onboarding step (e.g., as an int or string)
  static Future<void> saveStep(dynamic step) async {
    final prefs = await SharedPreferences.getInstance();
    if (step is int) {
      await prefs.setInt(OnboardingKeys.onboardingStep, step);
    } else if (step is String) {
      await prefs.setString(OnboardingKeys.onboardingStep, step);
    }
  }

  static Future<dynamic> getStep() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(OnboardingKeys.onboardingStep)) {
      return prefs.get(OnboardingKeys.onboardingStep);
    }
    return null;
  }

  static Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(OnboardingKeys.onboardingRole, role);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(OnboardingKeys.onboardingRole);
  }

  static Future<void> saveCategory(String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(OnboardingKeys.onboardingCategory, categoryId);
  }

  static Future<String?> getCategory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(OnboardingKeys.onboardingCategory);
  }

  static Future<void> saveSubCategory(String subCategoryId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(OnboardingKeys.onboardingSubCategory, subCategoryId);
  }

  static Future<String?> getSubCategory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(OnboardingKeys.onboardingSubCategory);
  }

  /// Mark onboarding as complete
  static Future<void> setComplete() async {
    final prefs = await SharedPreferences.getInstance();
    // ONLY set the completion flag to true - DO NOT clear it
    await prefs.setBool(OnboardingKeys.onboardingComplete, true);

    // Clear temporary onboarding progress keys but KEEP onboardingComplete
    await prefs.remove(OnboardingKeys.onboardingStep);
    await prefs.remove(OnboardingKeys.onboardingRole);
    await prefs.remove(OnboardingKeys.onboardingCategory);
    await prefs.remove(OnboardingKeys.onboardingSubCategory);
    await prefs.remove(OnboardingKeys.onboardingPlan);
  }

  /// Check if onboarding is complete
  static Future<bool> isComplete() async {
    final prefs = await SharedPreferences.getInstance();
    final isComplete =
        prefs.getBool(OnboardingKeys.onboardingComplete) ?? false;
    return isComplete;
  }

  /// Clear onboarding state (for testing or logout)
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(OnboardingKeys.onboardingStep);
    await prefs.remove(OnboardingKeys.onboardingComplete);
    await prefs.remove(OnboardingKeys.onboardingRole);
    await prefs.remove(OnboardingKeys.onboardingCategory);
    await prefs.remove(OnboardingKeys.onboardingSubCategory);
    await prefs.remove(OnboardingKeys.onboardingPlan);
  }

  /// Reset onboarding (for cases where user needs to go through onboarding again)
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OnboardingKeys.onboardingComplete, false);
    await prefs.remove(OnboardingKeys.onboardingStep);
    await prefs.remove(OnboardingKeys.onboardingRole);
    await prefs.remove(OnboardingKeys.onboardingCategory);
    await prefs.remove(OnboardingKeys.onboardingSubCategory);
    await prefs.remove(OnboardingKeys.onboardingPlan);
  }

  /// Save the selected plan as JSON string
  static Future<void> savePlan(Map<String, dynamic> planJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(OnboardingKeys.onboardingPlan, jsonEncode(planJson));
  }

  /// Retrieve the selected plan as JSON map
  static Future<Map<String, dynamic>?> getPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final planString = prefs.getString(OnboardingKeys.onboardingPlan);
    if (planString != null && planString.isNotEmpty) {
      try {
        return Map<String, dynamic>.from(jsonDecode(planString));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Clear the stored plan
  static Future<void> clearPlan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(OnboardingKeys.onboardingPlan);
  }

  /// Debug method to check current onboarding state
  static Future<Map<String, dynamic>> getDebugState() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'isComplete': prefs.getBool(OnboardingKeys.onboardingComplete) ?? false,
      'step': prefs.get(OnboardingKeys.onboardingStep),
      'role': prefs.getString(OnboardingKeys.onboardingRole),
      'category': prefs.getString(OnboardingKeys.onboardingCategory),
      'subCategory': prefs.getString(OnboardingKeys.onboardingSubCategory),
      'hasPlan': prefs.getString(OnboardingKeys.onboardingPlan) != null,
    };
  }
}
