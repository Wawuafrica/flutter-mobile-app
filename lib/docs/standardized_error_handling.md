# Standardized Error Handling Implementation

This document outlines the plan to standardize error handling across the application using SnackBars with consistent styling and retry functionality where applicable.

## Standard Implementation Pattern

### 1. Basic Error SnackBar

```dart
// For simple error messages
void showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}
```

### 2. Error with Retry Action

```dart
// For errors where retry is possible
void showErrorWithRetry(
  BuildContext context, 
  String message, 
  VoidCallback onRetry,
) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      action: SnackBarAction(
        label: 'RETRY',
        textColor: Colors.white,
        onPressed: onRetry,
      ),
      duration: Duration(seconds: 5),
    ),
  );
}
```

## Screens Requiring Updates

### 1. Authentication Flows

#### File: `lib/screens/wawu_africa/sign_in/sign_in.dart`
- **Current**: Uses inline Text widget for errors
- **Fix**: Replace with `showErrorSnackBar`
- **Code Location**: `_SignInState.build`
- **Retry**: Not needed (form validation handles retry)

#### File: `lib/screens/wawu_africa/sign_up/sign_up.dart`
- **Current**: Uses inline Text widget for errors
- **Fix**: Replace with `showErrorSnackBar`
- **Code Location**: `_SignUpState.build`
- **Retry**: Not needed (form validation handles retry)

### 2. Profile Management

#### File: `lib/screens/update_profile/profile_update/profile_update.dart`
- **Current**: Mixed error display methods
- **Fix**: Use `showErrorWithRetry` for save failures
- **Code Location**: `_ProfileUpdateState._saveProfile`
- **Retry**: Yes, allow retry on save failure

### 3. Gig Management

#### File: `lib/screens/gigs_screen/create_gig_screen/create_gig_screen.dart`
- **Current**: Inline error display with retry button
- **Fix**: Use `showErrorWithRetry`
- **Code Location**: `_CreateGigScreenState._createGig`
- **Retry**: Yes, especially for network failures

#### File: `lib/screens/gigs_screen/single_gig_screen/single_gig_screen.dart`
- **Current**: Inline error display
- **Fix**: Use `showErrorSnackBar` for non-critical errors
- **Code Location**: `_SingleGigScreenState` methods
- **Retry**: Only for loading gig details

### 4. E-commerce

#### File: `lib/screens/wawu_ecommerce_screen/wawu_ecommerce_screen.dart`
- **Current**: Complex inline error view
- **Fix**: Use `showErrorWithRetry` for product loading
- **Code Location**: `_WawuEcommerceScreenState`
- **Retry**: Yes, for product loading failures

#### File: `lib/screens/cart_screen/cart_screen.dart`
- **Current**: Inline error display
- **Fix**: Use `showErrorSnackBar`
- **Code Location**: Various methods
- **Retry**: For cart operations

### 5. Messages

#### File: `lib/screens/messages_screen/messages_screen.dart`
- **Current**: Custom error display
- **Fix**: Use `showErrorWithRetry`
- **Code Location**: `_MessagesScreenState` methods
- **Retry**: Yes, for message loading

## Implementation Steps

1. **Create Utility Class**
   - Add `error_utils.dart` in `lib/utils/` with standard methods
   - Include both simple and retry variants

2. **Update Providers**
   - Ensure all providers set error states consistently
   - Clear errors after display

3. **Update UI Components**
   - Replace all inline error displays with standard SnackBars
   - Add retry functionality where applicable
   - Ensure proper error message handling

4. **Testing**
   - Test all error scenarios
   - Verify retry functionality
   - Check for proper cleanup

## Error Message Guidelines

1. **Be Specific**
   - Instead of "An error occurred", say "Failed to load products"
   - Include error codes if available

2. **Be Helpful**
   - Suggest actions when possible
   - For network errors, suggest checking connection

3. **Be Consistent**
   - Use similar wording for similar errors
   - Maintain consistent capitalization and punctuation

## Common Error Scenarios

### Network Errors
- **Message**: "Unable to connect to server. Please check your internet connection."
- **Action**: Show retry button

### Server Errors
- **Message**: "Server error (500). Please try again later."
- **Action**: Show retry with delay

### Validation Errors
- **Message**: "Please fill in all required fields correctly."
- **Action**: Highlight problematic fields

### Timeout
- **Message**: "Request timed out. The server is taking too long to respond."
- **Action**: Show retry button
