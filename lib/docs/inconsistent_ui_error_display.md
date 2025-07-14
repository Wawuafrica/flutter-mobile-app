# Inconsistent UI Error Display

This document outlines all instances where UI screens do not follow the standard practice of displaying error messages using a dismissible `SnackBar`. The standard implementation should use `ScaffoldMessenger.of(context).showSnackBar(...)` to present errors to the user.

Any deviation from this pattern, such as using `AlertDialog`, `Text` widgets, or other custom displays, will be documented here with recommendations for refactoring.

---

### 1. `sign_up.dart` (Merch)

- **File Path**: `lib/screens/wawu_merch/merch_auth/sign_up.dart`
- **Location**: `_SignUpMerchState.build` method, line 380

**Problem Description**:

When a registration error occurs (`userProvider.hasError` is true), the error message is displayed directly in the UI using a `Text` widget with a red color. This is inconsistent with the required pattern of using a dismissible `SnackBar`.

**Code Snippet**:
```dart
// lib/screens/wawu_merch/merch_auth/sign_up.dart

if (userProvider.hasError && userProvider.errorMessage != null)
  Padding(
    padding: const EdgeInsets.only(bottom: 10.0),
    child: Text(
      userProvider.errorMessage!,
      style: TextStyle(color: Colors.red),
      textAlign: TextAlign.center,
    ),
  ),
```

**Recommendation**:

Refactor the code to use a `WidgetsBinding.instance.addPostFrameCallback` to show a `SnackBar` when `userProvider.hasError` is true. The `Text` widget should be removed.

**Example Refactor**:
```dart
// In the build method

WidgetsBinding.instance.addPostFrameCallback((_) {
  if (userProvider.hasError && userProvider.errorMessage != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(userProvider.errorMessage!),
        backgroundColor: Colors.red,
      ),
    );
    // Optional: Call a method on the provider to clear the error state
    // userProvider.clearError(); 
  }
});

// Remove the Text widget from the widget tree
```

---

### 2. `sign_in.dart` (Merch)

- **File Path**: `lib/screens/wawu_merch/merch_auth/sign_in.dart`
- **Location**: `_SignInMerchState.build` method, line 87

**Problem Description**:

When a login error occurs (`userProvider.hasError` is true), the error message is displayed directly in the UI using a `Text` widget with a red color. This is inconsistent with the required pattern of using a dismissible `SnackBar`.

**Code Snippet**:
```dart
// lib/screens/wawu_merch/merch_auth/sign_in.dart

if (userProvider.hasError)
  Padding(
    padding: const EdgeInsets.only(bottom: 10.0),
    child: Text(
      userProvider.errorMessage ?? 'An error occurred',
      style: TextStyle(color: Colors.red),
      textAlign: TextAlign.center,
    ),
  ),
```

**Recommendation**:

Refactor the code to use a `WidgetsBinding.instance.addPostFrameCallback` to show a `SnackBar` when `userProvider.hasError` is true. The `Text` widget should be removed.

**Example Refactor**:
```dart
// In the build method

WidgetsBinding.instance.addPostFrameCallback((_) {
  if (userProvider.hasError && userProvider.errorMessage != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(userProvider.errorMessage!),
        backgroundColor: Colors.red,
      ),
    );
    // Optional: Call a method on the provider to clear the error state
    // userProvider.clearError(); 
  }
});

// Remove the Text widget from the widget tree
```

---

### 3. `wawu_ecommerce_screen.dart`

- **File Path**: `lib/screens/wawu_ecommerce_screen/wawu_ecommerce_screen.dart`
- **Location**: `_WawuEcommerceScreenState.build` method, line 207

**Problem Description**:

This screen implements a complex inline error view instead of a `SnackBar`. When an error occurs, it displays a `Text` widget, a `Retry` button, and a `Contact Support` button that opens a dialog. This is a significant architectural deviation.

**Code Snippet**:
```dart
// lib/screens/wawu_ecommerce_screen/wawu_ecommerce_screen.dart

if (productProvider.hasError && productProvider.errorMessage != null) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Error: ${productProvider.errorMessage}',
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            productProvider.fetchProducts();
          },
          child: const Text('Retry'),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.mail_outline),
          label: const Text('Contact Support'),
          onPressed: () {
            showErrorSupportDialog(
              context: context,
              title: 'Contact Support',
              message: '...',
            );
          },
        ),
      ],
    ),
  );
}
```

**Recommendation**:

Refactor this logic to use a `SnackBar`. The primary error message should be displayed in the `SnackBar`. The `Retry` functionality can be provided via a `SnackBarAction`. The `Contact Support` dialog is a separate concern and could be triggered from a persistent button or menu item if necessary, but should not be part of the primary error display.

**Example Refactor**:
```dart
// In the build method

WidgetsBinding.instance.addPostFrameCallback((_) {
  if (productProvider.hasError && productProvider.errorMessage != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(productProvider.errorMessage!),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'RETRY',
          onPressed: () {
            productProvider.fetchProducts();
          },
        ),
      ),
    );
    // userProvider.clearError(); 
  }
});

// The widget tree should show a loading indicator or an empty state,
// not the inline error view.
```

---

### 4. `sign_up.dart` (Africa)

- **File Path**: `lib/screens/wawu_africa/sign_up/sign_up.dart`
- **Location**: `_SignUpState.build` method, line 445

**Problem Description**:

When a registration error occurs (`userProvider.hasError` is true), the error message is displayed directly in the UI using a `Text` widget with a red color. This is inconsistent with the required pattern of using a dismissible `SnackBar`.

**Code Snippet**:
```dart
// lib/screens/wawu_africa/sign_up/sign_up.dart

if (userProvider.hasError && userProvider.errorMessage != null)
  Padding(
    padding: const EdgeInsets.only(bottom: 10.0),
    child: Text(
      userProvider.errorMessage!,
      style: TextStyle(color: Colors.red),
      textAlign: TextAlign.center,
    ),
  ),
```

**Recommendation**:

Refactor the code to use a `WidgetsBinding.instance.addPostFrameCallback` to show a `SnackBar` when `userProvider.hasError` is true. The `Text` widget should be removed.

**Example Refactor**:
```dart
// In the build method

WidgetsBinding.instance.addPostFrameCallback((_) {
  if (userProvider.hasError && userProvider.errorMessage != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(userProvider.errorMessage!),
        backgroundColor: Colors.red,
      ),
    );
    // Optional: Call a method on the provider to clear the error state
    // userProvider.clearError(); 
  }
});

// Remove the Text widget from the widget tree
```

---

### 5. `sign_in.dart` (Africa)

- **File Path**: `lib/screens/wawu_africa/sign_in/sign_in.dart`
- **Location**: `_SignInState.build` method, line 118

**Problem Description**:

When a login error occurs (`userProvider.hasError` is true), the error message is displayed directly in the UI using a `Text` widget with a red color. This is inconsistent with the required pattern of using a dismissible `SnackBar`.

**Code Snippet**:
```dart
// lib/screens/wawu_africa/sign_in/sign_in.dart

if (userProvider.hasError)
  Padding(
    padding: const EdgeInsets.only(bottom: 10.0),
    child: Text(
      userProvider.errorMessage ?? 'An error occurred',
      style: TextStyle(color: Colors.red),
      textAlign: TextAlign.center,
    ),
  ),
```

**Recommendation**:

Refactor the code to use a `WidgetsBinding.instance.addPostFrameCallback` to show a `SnackBar` when `userProvider.hasError` is true. The `Text` widget should be removed.

**Example Refactor**:
```dart
// In the build method

WidgetsBinding.instance.addPostFrameCallback((_) {
  if (userProvider.hasError && userProvider.errorMessage != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(userProvider.errorMessage!),
        backgroundColor: Colors.red,
      ),
    );
    // Optional: Call a method on the provider to clear the error state
    // userProvider.clearError(); 
  }
});

// Remove the Text widget from the widget tree
```

---

### 6. `settings_screen.dart`

- **File Path**: `lib/screens/settings_screen/settings_screen.dart`
- **Location**: `_SettingsScreenState.build` method, line 271

**Problem Description**:

When `planProvider.hasError` is true, the UI displays a custom inline widget with the hardcoded text "No active subscription" and a "View Plans" button. This is problematic because it hides the actual error message from the user and uses a custom UI instead of a `SnackBar`.

**Code Snippet**:
```dart
// lib/screens/settings_screen/settings_screen.dart

if (hasError || subscriptionData == null) {
  return Container(
    // ... styling
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'No active subscription',
          // ... styling
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () { /* Navigate to plans */ },
          child: Text('View Plans'),
        ),
      ],
    ),
  );
}
```

**Recommendation**:

The logic should be separated. The `hasError` case should trigger a `SnackBar` with the actual error message from `planProvider.errorMessage`. The `subscriptionData == null` case can show the "No active subscription" view, but it should be treated as an empty state, not an error state.

**Example Refactor**:
```dart
// In the build method

// Handle the error state first
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (planProvider.hasError && planProvider.errorMessage != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(planProvider.errorMessage!),
        backgroundColor: Colors.red,
      ),
    );
    // planProvider.clearError(); 
  }
});

// Then, handle the empty state in the widget tree
if (subscriptionData == null) {
  return Container(
    // ... "No active subscription" UI
  );
}

// ... rest of the widget tree
```

---

### 7. `plan.dart`

- **File Path**: `lib/screens/plan/plan.dart`
- **Location**: `_PlanState.build` method, line 71

**Problem Description**:

This screen implements a complex inline error view instead of a `SnackBar`. When an error occurs, it displays a `Text` widget, a `Retry` button, and a `Contact Support` button that opens a dialog. This is a significant architectural deviation.

**Code Snippet**:
```dart
// lib/screens/plan/plan.dart

if (planProvider.hasError) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          planProvider.errorMessage ?? 'Failed to load plans',
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            planProvider.fetchAllPlans();
          },
          child: const Text('Retry'),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.mail_outline),
          label: const Text('Contact Support'),
          onPressed: () {
            showErrorSupportDialog(
              context: context,
              title: 'Contact Support',
              message: '...',
            );
          },
        ),
      ],
    ),
  );
}
```

**Recommendation**:

Refactor this logic to use a `SnackBar`. The primary error message should be displayed in the `SnackBar`. The `Retry` functionality can be provided via a `SnackBarAction`. The `Contact Support` dialog is a separate concern and could be triggered from a persistent button or menu item if necessary, but should not be part of the primary error display.

**Example Refactor**:
```dart
// In the build method

WidgetsBinding.instance.addPostFrameCallback((_) {
  if (planProvider.hasError && planProvider.errorMessage != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(planProvider.errorMessage!),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'RETRY',
          onPressed: () {
            planProvider.fetchAllPlans();
          },
        ),
      ),
    );
    // planProvider.clearError(); 
  }
});

// The widget tree should show a loading indicator or an empty state,
// not the inline error view.
```

---

### 8. `single_message_screen.dart`

- **File Path**: `lib/screens/messages_screen/single_message_screen/single_message_screen.dart`
- **Location**: `_SingleMessageScreenState.build` method, line 360

**Problem Description**:

When fetching a conversation fails, the screen displays an inline error view containing a `Text` widget and a "Go Back" button. This is inconsistent with the required `SnackBar` pattern.

**Code Snippet**:
```dart
// lib/screens/messages_screen/single_message_screen/single_message_screen.dart

if (messageProvider.hasError &&
    messageProvider.currentConversationId.isEmpty &&
    messageProvider.currentMessages.isEmpty) {
  return Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Error: ${messageProvider.errorMessage}'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    ),
  );
}
```

**Recommendation**:

Refactor the logic to show a `SnackBar` with the error message. The UI should likely pop the screen or show an empty state after the error is displayed, rather than showing a custom inline error view.

**Example Refactor**:
```dart
// In the build method

WidgetsBinding.instance.addPostFrameCallback((_) {
  if (provider.hasError && provider.errorMessage != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(provider.errorMessage!),
        backgroundColor: Colors.red,
      ),
    );
    // Clear the error state after showing the message
    provider.clearError();
  }
});

// Remove the inline error Text widget from the widget tree
```

---

### 11. `single_message_screen.dart`

- **File Path**: `lib/screens/messages_screen/single_message_screen/single_message_screen.dart`
- **Location**: `_SingleMessageScreenState.build` method, line 368

**Problem Description**:

Error messages are displayed directly in the UI using a `Text` widget when `messageProvider.errorMessage` is not null. This should be displayed as a dismissible `SnackBar` instead.

**Code Snippet**:
```dart
// lib/screens/messages_screen/single_message_screen/single_message_screen.dart

if (messageProvider.errorMessage != null)
  Text('Error: ${messageProvider.errorMessage}'),
```

**Recommendation**:

Refactor to use `ScaffoldMessenger` to show the error message as a `SnackBar` when `messageProvider.errorMessage` is not null.

**Example Refactor**:
```dart
// In the build method

WidgetsBinding.instance.addPostFrameCallback((_) {
  if (messageProvider.errorMessage != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: ${messageProvider.errorMessage}'),
        backgroundColor: Colors.red,
      ),
    );
    // Clear the error state after showing the message
    messageProvider.clearError();
  }
});

// Remove the inline error Text widget from the widget tree
```

---

### 12. `profile_screen.dart`

- **File Path**: `lib/screens/profile/profile_screen.dart`
- **Location**: `_ProfileScreenState._saveProfile` method, line 415

**Problem Description**:

Error messages during profile updates are shown using a direct `SnackBar` without using `ScaffoldMessenger`, which can cause issues with the widget lifecycle.

**Code Snippet**:
```dart
// lib/screens/profile/profile_screen.dart

Scaffold.of(context).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
```

**Recommendation**:

Update to use `ScaffoldMessenger` for showing the error message.

**Example Refactor**:
```dart
// Replace the error handling with:

if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Error updating profile: $e'),
      backgroundColor: Colors.red,
    ),
  );
}
```

---

### 13. `home_screen.dart`

- **File Path**: `lib/screens/home_screen/home_screen.dart`
- **Location**: `_HomeScreenState._refreshData` and `_handleAdTap` methods

**Problem Description**:

Error messages are shown using direct `SnackBar` without `ScaffoldMessenger`, and error states are handled inconsistently.

**Code Snippet**:
```dart
// In _refreshData
content: Text('Failed to refresh data: $error'),

// In _handleAdTap
SnackBar(content: Text('Error opening link: ${e.toString()}')),
```

**Recommendation**:

Standardize error handling using `ScaffoldMessenger` and ensure consistent error message formatting.

**Example Refactor**:
```dart
// For refresh errors
if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Failed to refresh data. Please try again.'),
      backgroundColor: Colors.red,
    ),
  );
}

// For ad tap errors
if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Could not open the link. Please try again later.'),
      backgroundColor: Colors.red,
    ),
  );
}
```

---

### 14. `create_gig_screen.dart`

- **File Path**: `lib/screens/gigs_screen/create_gig_screen/create_gig_screen.dart`
- **Location**: `_CreateGigScreenState._createGig` method

**Problem Description**:

Error handling uses direct dialogs and `SnackBar` without `ScaffoldMessenger`, and error messages are constructed in a way that might expose internal errors to users.

**Code Snippet**:
```dart
// Error message construction
String errorMessage = 'Failed to create gig';
// ...
content: Text(errorMessage),

// Later in the same method
content: Text('An unexpected error occurred: ${e.toString()}'),
```

**Recommendation**:

Standardize error handling with `ScaffoldMessenger` and use user-friendly error messages.

**Example Refactor**:
```dart
// For known error cases
if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Failed to create gig. Please check your input and try again.'),
      backgroundColor: Colors.red,
    ),
  );
}

// For unexpected errors
if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('An unexpected error occurred. Please try again later.'),
      backgroundColor: Colors.red,
    ),
  );
  // Log the actual error for debugging
  debugPrint('Create gig error: $e');
}
```

---

### 17. `update_profile_screen.dart`

- **File Path**: `lib/screens/update_profile/profile_update/profile_update.dart`
- **Location**: `_ProfileUpdateState._saveProfile` method

**Problem Description**:

Error messages during profile updates are shown using direct `SnackBar` without using `ScaffoldMessenger`, which can cause issues with the widget lifecycle.

**Code Snippet**:
```dart
// lib/screens/update_profile/profile_update/profile_update.dart

Scaffold.of(context).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
```

**Recommendation**:

Update to use `ScaffoldMessenger` for showing the error message and ensure proper error handling.

**Example Refactor**:
```dart
if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('Failed to update profile. Please try again.'),
      backgroundColor: Colors.red,
    ),
  );
  // Log the actual error for debugging
  debugPrint('Profile update error: $e');
}
```

---

### 18. `categories_screen.dart`

- **File Path**: `lib/screens/categories/categories_screen.dart`
- **Location**: `_CategoriesScreenState.build` method

**Problem Description**:

Error messages for category loading are displayed directly in the UI using a `Text` widget. These should be shown as dismissible `SnackBar` messages instead.

**Code Snippet**:
```dart
// lib/screens/categories/categories_screen.dart

'Error loading categories: ${categoryProvider.errorMessage}',
```

**Recommendation**:

Refactor to use `ScaffoldMessenger` to show the error message when category loading fails.

**Example Refactor**:
```dart
// In the build method

WidgetsBinding.instance.addPostFrameCallback((_) {
  if (categoryProvider.hasError && 
      categoryProvider.errorMessage != null && 
      mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to load categories: ${categoryProvider.errorMessage}'),
        backgroundColor: Colors.red,
      ),
    );
    // Clear the error after showing it
    categoryProvider.clearError();
  }
});
```

---

## General Recommendations

1. **Consistent Error Handling**:
   - Always use `ScaffoldMessenger.of(context).showSnackBar()` for displaying error messages
   - Ensure error messages are user-friendly and don't expose internal error details
   - Clear error states after displaying them to prevent duplicate messages

2. **Widget Lifecycle**:
   - Always check `mounted` before calling `setState` or accessing context in async callbacks
   - Use `WidgetsBinding.instance.addPostFrameCallback` for showing messages after the frame is built

3. **Error Messages**:
   - Keep error messages concise and actionable
   - Avoid technical jargon in user-facing messages
   - Log detailed errors to the console for debugging

4. **Loading States**:
   - Show loading indicators during async operations
   - Handle both success and error cases appropriately
   - Provide a way for users to retry failed operations

5. **Accessibility**:
   - Ensure error messages are announced to screen readers
   - Use appropriate colors and contrast for error states
   - Provide alternative text for error icons and images



---

### 9. `create_gig_screen.dart`

- **File Path**: `lib/screens/gigs_screen/create_gig_screen/create_gig_screen.dart`
- **Location**: `_CreateGigScreenState.build` method, line 871

**Problem Description**:

When fetching categories fails, the screen displays a full-screen inline error view containing a `Text` widget and a `Retry` button. This is inconsistent with the required `SnackBar` pattern.

**Code Snippet**:
```dart
// lib/screens/gigs_screen/create_gig_screen/create_gig_screen.dart

if (categoryProvider.hasError && _fetchType == FetchType.categories) {
  return Scaffold(
    appBar: AppBar(title: const Text('Create A New Gig')),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            categoryProvider.errorMessage ?? 'Failed to load categories',
          ),
          const SizedBox(height: 20),
          CustomButton(
            function: () {
              categoryProvider.fetchCategories();
            },
            widget: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}
```

**Recommendation**:

Refactor the logic to show a `SnackBar` with the error message and a `SnackBarAction` for the retry functionality. The main UI should show a loading indicator or an empty state instead of the inline error view.

**Example Refactor**:
```dart
// In the build method

WidgetsBinding.instance.addPostFrameCallback((_) {
  if (categoryProvider.hasError && categoryProvider.errorMessage != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(categoryProvider.errorMessage!),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'RETRY',
          onPressed: () {
            categoryProvider.fetchCategories();
          },
        ),
      ),
    );
    // categoryProvider.clearError(); 
  }
});

// The widget tree should show a loading indicator or an empty state,
// not the inline error view.
```

---

### 10. `sub_category_selection.dart`

- **File Path**: `lib/screens/category_selection/sub_category_selection.dart`
- **Location**: `_SubCategorySelectionState.build` method

**Problem Description**:

This screen contains two different types of inconsistent error handling:

1.  **Complex Inline Error View (`CategoryProvider`)**: When fetching subcategories fails (`categoryProvider.hasError`), it displays a full-screen error view with a `Text` widget, a `Retry` button, and a `Contact Support` button.
2.  **Simple Inline Error Text (`UserProvider`)**: When a user-related error occurs (`userProvider.hasError`), it displays a simple inline red `Text` widget.

**Code Snippets**:
```dart
// lib/screens/category_selection/sub_category_selection.dart

// Issue 1: Complex inline error for CategoryProvider
if (categoryProvider.hasError) {
  return Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Error loading subcategories: ${categoryProvider.errorMessage}'),
          ElevatedButton(
            onPressed: () { /* Retry logic */ },
            child: const Text('Retry'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.mail_outline),
            label: const Text('Contact Support'),
            onPressed: () { /* Show dialog */ },
          ),
        ],
      ),
    ),
  );
}

// ... inside the main widget tree

// Issue 2: Simple inline error for UserProvider
if (userProvider.hasError)
  Padding(
    padding: const EdgeInsets.symmetric(vertical: 10.0),
    child: Text(
      userProvider.errorMessage ?? 'An error occurred',
      style: const TextStyle(color: Colors.red),
      textAlign: TextAlign.center,
    ),
  ),
```

**Recommendation**:

Both error handling mechanisms should be refactored to use a single, consistent `SnackBar` pattern. The `addPostFrameCallback` should be used to check for errors from both providers and display a `SnackBar` accordingly. The `Retry` logic can be implemented using a `SnackBarAction`.

**Example Refactor**:
```dart
// In the build method

WidgetsBinding.instance.addPostFrameCallback((_) {
  // Handle CategoryProvider errors
  if (categoryProvider.hasError && categoryProvider.errorMessage != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(categoryProvider.errorMessage!),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'RETRY',
          onPressed: () {
            categoryProvider.fetchSubCategories(widget.categoryId);
          },
        ),
      ),
    );
    // categoryProvider.clearError(); 
  }

  // Handle UserProvider errors
  if (userProvider.hasError && userProvider.errorMessage != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(userProvider.errorMessage!),
        backgroundColor: Colors.red,
      ),
    );
    // userProvider.clearError(); 
  }
});

// The widget tree should show loading indicators or empty states,
// not inline error views.
```

---

### 11. `profile_update.dart`

- **File Path**: `lib/screens/update_profile/profile_update/profile_update.dart`
- **Location**: `ProfileUpdateState.build` method

**Problem Description**:

This screen consumes four providers (`CategoryProvider`, `UserProvider`, `DropdownDataProvider`, and `SkillProvider`) but completely lacks any error handling for them within the `build` method. If any of these providers encounter an error, it will fail silently without notifying the user. The UI will not display any error message, leading to a confusing and broken user experience.

**Code Snippet**:
```dart
// lib/screens/update_profile/profile_update/profile_update.dart

// ...
  return Consumer4<
    CategoryProvider,
    UserProvider,
    DropdownDataProvider,
    SkillProvider
  >(
    builder: (
      context,
      categoryProvider,
      userProvider,
      dropdownProvider,
      skillProvider,
      child,
    ) {
      // NO ERROR HANDLING for any of the providers.
      // if (userProvider.hasError) { ... }
      // if (categoryProvider.hasError) { ... }
      // etc.

      return Scaffold(
        // ... UI that depends on the providers' data
      );
    },
  );
// ...
```

**Recommendation**:

Implement a `WidgetsBinding.instance.addPostFrameCallback` to check the `hasError` status of all four providers. If any provider has an error, a `SnackBar` should be displayed with the corresponding error message. This ensures that no error goes unnoticed by the user.

**Example Refactor**:
```dart
// In the build method

WidgetsBinding.instance.addPostFrameCallback((_) {
  final providers = {
    'User': context.read<UserProvider>(),
    'Category': context.read<CategoryProvider>(),
    'Dropdown': context.read<DropdownDataProvider>(),
    'Skill': context.read<SkillProvider>(),
  };

  for (var providerEntry in providers.entries) {
    final provider = providerEntry.value;
    if (provider.hasError && provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${providerEntry.key} Error: ${provider.errorMessage!}'),
          backgroundColor: Colors.red,
        ),
      );
      // provider.clearError();
    }
  }
});

// The main widget tree remains the same.
```

---

### 12. `account_payment.dart`

- **File Path**: `lib/screens/account_payment/account_payment.dart`
- **Location**: `AccountPaymentState.build` method

**Problem Description**:

This screen consumes `PlanProvider` but does not check for `planProvider.hasError`. If an error occurs, the UI falls back to showing a "No plan selected" message, which is misleading and fails to inform the user of the actual error.

**Code Snippet**:
```dart
// lib/screens/account_payment/account_payment.dart

return Consumer<PlanProvider>(
  builder: (context, planProvider, child) {
    final selectedPlan = planProvider.selectedPlan;

    // NO CHECK for planProvider.hasError

    if (selectedPlan == null) {
      // This UI is shown for both a null plan AND an error state.
      return Scaffold(
        body: Center(
          child: Text('No plan selected'),
        ),
      );
    }

    return Scaffold(...);
  },
);
```

**Recommendation**:

Implement a `WidgetsBinding.instance.addPostFrameCallback` to check the `hasError` status of the `PlanProvider`. If an error exists, display it in a `SnackBar` to properly inform the user.

**Example Refactor**:
```dart
// In the build method

WidgetsBinding.instance.addPostFrameCallback((_) {
  final planProvider = context.read<PlanProvider>();
  if (planProvider.hasError && planProvider.errorMessage != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(planProvider.errorMessage!),
        backgroundColor: Colors.red,
      ),
    );
    // planProvider.clearError();
    // Optionally, navigate back if the error is critical
    Navigator.of(context).pop();
  }
});

// The main widget tree can then handle the selectedPlan == null case as a separate state.
```

---

### 14. `payment_webview.dart`

- **File Path**: `lib/screens/account_payment/payment_webview.dart`
- **Location**: `_PaymentWebViewState.initState` (WebViewController configuration)

**Problem Description**:

The `NavigationDelegate` for the `WebViewController` is missing an `onWebResourceError` handler. If the webview fails to load the payment URL due to network issues, a 404 error, or other web-related problems, the app provides no feedback. The user is left with a perpetual loading indicator or a generic web error page, which is a form of silent error handling.

**Code Snippet**:
```dart
// lib/screens/account_payment/payment_webview.dart

controller =
    WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) { ... },
          onPageFinished: (String url) { ... },
          onNavigationRequest: (NavigationRequest request) { ... },
          // onWebResourceError is missing here
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
```

**Recommendation**:

Add an `onWebResourceError` handler to the `NavigationDelegate`. This handler should log the error and pop the screen with a failure result, which can then be displayed as a `SnackBar` on the previous screen.

**Example Refactor**:
```dart
// In NavigationDelegate

..setNavigationDelegate(
  NavigationDelegate(
    // ... other delegates
    onWebResourceError: (WebResourceError error) {
      _logger.e('Web error: ${error.description}');
      if (hasHandledCallback) return;
      hasHandledCallback = true;

      _onPaymentFailed(
        'Failed to load payment page: ${error.description}',
        error.url ?? widget.paymentUrl,
      );
    },
  ),
)
```

---

*This document will be updated as UI screens are analyzed.*
