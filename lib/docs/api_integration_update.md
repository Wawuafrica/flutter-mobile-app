# Wawu Mobile: Updated API Integration Analysis

*Last Updated: May 17, 2025*

## Overview

Based on the detailed API specifications extracted from the Wawu backend, this document provides an updated analysis of API integration requirements, data mapping, and implementation priorities. The API specifications reveal a comprehensive backend with structured endpoints for all major features planned for the Wawu mobile application.

**API Base URL**: `https://staging.wawuafrica.com/api`

## API Integration Status

### Authentication & User Profile

The Wawu API provides complete authentication endpoints including:
- User registration and login
- Password reset flow
- Token refresh mechanism
- User profile management

**Integration Status**: Partially implemented in `AuthService` and `UserProvider`, but direct connections to API endpoints need to be established.

**Priority**: High - Authentication is foundational for all other features.

### Messaging System

The API provides robust chat functionality:
- Conversation listing
- Message history retrieval
- Real-time message delivery via Pusher
- Media sharing in messages
- Read status tracking

**Integration Status**: Basic structure implemented in `MessageProvider`, but API connections and Pusher event bindings need to be completed.

**Priority**: High - Core social feature of the platform.

### Notifications

The API includes comprehensive notification handling:
- Notification listing with pagination
- Unread count tracking
- Mark as read functionality
- Notification settings management
- Real-time delivery via Pusher

**Integration Status**: Basic structure implemented in `NotificationProvider`, but API connections need to be established.

**Priority**: High - Critical for user engagement.

### Gigs/Jobs

The API offers full freelance marketplace functionality:
- Gig listing and creation
- Detailed gig information retrieval
- Media assets management
- Pricing packages
- Application handling

**Integration Status**: Basic structure implemented in `GigProvider`, but API connections need to be established.

**Priority**: Medium-High - Core marketplace feature.

### Products/E-commerce

The API includes robust e-commerce capabilities:
- Product listing and creation
- Product details and variants
- Shopping cart functionality
- Order processing
- Review system

**Integration Status**: Basic structure implemented in `ProductProvider`, but API connections need to be established.

**Priority**: Medium-High - Core commerce feature.

### Blog Content

The API provides content management features:
- Blog post listing and retrieval
- Comments and likes
- Categories and tags
- Featured posts

**Integration Status**: Basic structure implemented in `BlogProvider`, but API connections need to be established.

**Priority**: Medium - Important for user engagement but not critical for core functionality.

### Categories

The API uses a three-tier hierarchy for categorization:
1. **Categories** (top level)
2. **Sub-categories** (middle level, currently called "categories" in the app)
3. **Services** (specific services under each sub-category)

The three-step creation process for gigs requires:
1. User selects a top-level category
2. User selects a sub-category from the selected category
3. User selects a specific service from the sub-category

**Integration Status**: Basic structure implemented in `CategoryProvider`, but needs updating to reflect the three-tier structure. The current app implementation treats sub-categories as top-level categories.

**Priority**: High - Critical for proper gig creation flow.

### Subscription Plans

The API provides subscription management capabilities:
- Plan listing and details
- Subscription creation and management
- Payment method handling
- Invoicing

**Integration Status**: Basic structure implemented in `PlanProvider`, but API connections need to be established.

**Priority**: Medium - Important for monetization but can be implemented after core features.

### Mentorship (Placeholder)

The API provides basic mentorship application functionality:
- Mentor application submission
- Mentee application submission
- Placeholder endpoints for mentorship management

**Integration Status**: Not implemented in the mobile app yet.

**Priority**: Low - This appears to be a future feature, currently only with form submission capabilities.

## File Uploads

All file uploads are handled as multipart form data directly within their respective endpoints rather than through separate file upload endpoints. This applies to:

1. **Profile pictures**: Sent as multipart form data with the profile update endpoint
2. **Gig media**: Sent as multipart form data with the gig creation/update endpoints
3. **Product images**: Sent as multipart form data with the product creation/update endpoints
4. **Message attachments**: Sent as multipart form data with the message sending endpoint

### Implementation Example (Profile Picture Update):

```dart
Future<bool> updateProfileWithImage(File imageFile, Map<String, dynamic> profileData) async {
  try {
    // Create multipart request
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiService.baseUrl}/auth/profile')
    );
    
    // Add auth headers
    request.headers.addAll({
      'Api-Token': await _authService.getToken(),
      'channel': 'mobile'
    });
    
    // Add profile data as fields
    profileData.forEach((key, value) {
      request.fields[key] = value.toString();
    });
    
    // Add image file
    request.files.add(
      await http.MultipartFile.fromPath(
        'profilePicture',
        imageFile.path,
      )
    );
    
    // Send request
    final response = await request.send();
    
    return response.statusCode == 200;
  } catch (e) {
    _logger.e('Failed to update profile with image: $e');
    return false;
  }
}
```

## Data Mapping & UI Components

### Home Screen

**Required Data**:
- Featured products (`ProductProvider.fetchFeaturedProducts()`)
- Featured gigs (`GigProvider.fetchFeaturedGigs()`)
- Latest blog posts (`BlogProvider.fetchLatestPosts()`)
- User notification count (`NotificationProvider.fetchUnreadCount()`)
- User profile summary (`UserProvider.currentUser`)
- Top-level categories (`CategoryProvider.fetchCategories()`)

**UI Components**:
- Featured carousels
- Category quick access
- Notification badge

### Profile Screen

**Required Data**:
- Complete user profile (`UserProvider.fetchCurrentUser()`)
- Profile completion rate
- Portfolio items
- User skills and certifications

**UI Components**:
- Profile header with image/cover
- Profile completion progress
- Editable fields
- Skills and education sections

### Messages Screen

**Required Data**:
- Conversation list (`MessageProvider.fetchConversations()`)
- Message history for selected conversation (`MessageProvider.fetchMessages()`)
- Unread message counts

**UI Components**:
- Conversation list with last message
- Message bubbles with sent/delivered/read status
- Media message rendering
- Real-time message updates

### Notifications Screen

**Required Data**:
- Notification list (`NotificationProvider.fetchNotifications()`)
- Notification preferences (`NotificationProvider.fetchNotificationSettings()`)

**UI Components**:
- Notification list with read/unread status
- Mark as read functionality
- Settings toggle for notification preferences

### Gigs Screen

**Required Data**:
- Gig listings (`GigProvider.fetchGigs()`)
- Categories (`CategoryProvider.fetchCategories()`)
- Sub-categories (when a category is selected) (`CategoryProvider.fetchSubCategories(categoryId)`)
- Services (when a sub-category is selected) (`CategoryProvider.fetchServices(subCategoryId)`)
- User's gig applications (`GigProvider.fetchMyApplications()`)

**UI Components**:
- Gig cards with key information
- Three-tier category navigation (Categories > Sub-categories > Services)
- Search functionality
- Application status tracking

### Products Screen

**Required Data**:
- Product listings (`ProductProvider.fetchProducts()`)
- Product categories (`CategoryProvider.fetchProductCategories()`)
- Cart items (`ProductProvider.cartItems`)
- Order history (`ProductProvider.fetchOrders()`)

**UI Components**:
- Product cards with images and pricing
- Category filters
- Cart management interface
- Checkout process

### Blog Screen

**Required Data**:
- Blog posts (`BlogProvider.fetchPosts()`)
- Blog categories (`CategoryProvider.fetchBlogCategories()`)
- Featured posts (`BlogProvider.fetchFeaturedPosts()`)

**UI Components**:
- Article cards with featured image
- Category filters
- Comment section
- Like functionality

## Implementation Recommendations

### API Service Improvements

1. **Base URL Configuration**:
   ```dart
   // In ApiService
   final String baseUrl = const String.fromEnvironment(
     'API_BASE_URL',
     defaultValue: 'https://staging.wawuafrica.com/api',
   );
   ```

2. **Token Management**:
   ```dart
   // In ApiService
   Future<void> refreshToken() async {
     try {
       final response = await _dio.post<Map<String, dynamic>>(
         '/auth/refresh-token',
         options: Options(headers: {
           'Authorization': 'Bearer $_refreshToken'
         }),
       );
       
       final String newToken = response.data!['data']['token'] as String;
       setAuthToken(newToken);
       
       // Save token via AuthService
       await _authService.saveToken(newToken);
     } catch (e) {
       _logger.e('Token refresh failed: $e');
       // Force logout on token refresh failure
       await _authService.logout();
     }
   }
   ```

3. **Error Handling**:
   ```dart
   // Add to ApiService
   Future<T?> safeApiCall<T>(Future<T> Function() apiCall, {
     String? errorMessage,
     bool forceLogout = false,
   }) async {
     try {
       return await apiCall();
     } on DioException catch (e) {
       if (e.response?.statusCode == 401) {
         // Token expired
         if (forceLogout) {
           await _authService.logout();
         }
       }
       _logger.e('API error: ${e.message}');
       return null;
     } catch (e) {
       _logger.e('Unexpected error: $e');
       return null;
     }
   }
   ```

### Provider Updates

1. **UserProvider Updates**:
   ```dart
   // In UserProvider
   Future<User?> fetchCurrentUser() async {
     return await handleAsync(() async {
       final response = await _apiService.get<Map<String, dynamic>>(
         '/auth/me',
       );
       
       final user = User.fromJson(response['data']);
       _currentUser = user;
       
       // Subscribe to user-specific notifications
       _subscribeToUserChannels(user.uuid);
       
       return user;
     }, errorMessage: 'Failed to fetch user profile');
   }
   
   Future<bool> updateProfile(Map<String, dynamic> profileData) async {
     final result = await handleAsync(() async {
       final response = await _apiService.post<Map<String, dynamic>>(
         '/user/profile/update',
         data: profileData,
       );
       
       final user = User.fromJson(response['data']);
       _currentUser = user;
       
       return true;
     }, errorMessage: 'Failed to update profile');
     
     return result ?? false;
   }
   ```

2. **MessageProvider Updates**:
   ```dart
   // In CategoryProvider
Future<List<Category>> fetchCategories() async {
  return await handleAsync(() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/categories',
    );
    
    final List<dynamic> categoriesJson = response['data']['categories'];
    _categories = categoriesJson
        .map((json) => Category.fromJson(json))
        .toList();
    
    return _categories;
  }, errorMessage: 'Failed to fetch categories');
}

// Get all sub-categories for a specific category
Future<List<SubCategory>> fetchSubCategories(String categoryId) async {
  return await handleAsync(() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/categories/${categoryId}/subcategories',
    );
    
    final List<dynamic> subCategoriesJson = response['data']['subCategories'];
    return subCategoriesJson
        .map((json) => SubCategory.fromJson(json))
        .toList();
  }, errorMessage: 'Failed to fetch sub-categories');
}

// Get all services for a specific sub-category
Future<List<Service>> fetchServices(String subCategoryId) async {
  return await handleAsync(() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/subcategories/${subCategoryId}/services',
    );
    
    final List<dynamic> servicesJson = response['data']['services'];
    return servicesJson
        .map((json) => Service.fromJson(json))
        .toList();
  }, errorMessage: 'Failed to fetch services');
       
       return conversations;
     }, errorMessage: 'Failed to fetch conversations');
     
     return result ?? [];
   }
   ```

3. **ProductProvider Updates**:
   ```dart
   // In ProductProvider
   Future<bool> submitOrder({
     required Map<String, dynamic> orderData,
   }) async {
     final result = await handleAsync(() async {
       await _apiService.post<Map<String, dynamic>>(
         '/products/orders',
         data: orderData,
       );
       
       // Clear cart after successful order
       _cartItems.clear();
       
       return true;
     }, errorMessage: 'Failed to submit order');
     
     return result ?? false;
   }
   ```

### Pusher Service Improvements

```dart
// In PusherService
Future<void> initialize({
  required String userId,
}) async {
  // Initialize Pusher with application credentials
  _pusher = PusherClient(
    const String.fromEnvironment(
      'PUSHER_APP_KEY',
      defaultValue: 'app-key',
    ),
    PusherOptions(
      cluster: const String.fromEnvironment(
        'PUSHER_CLUSTER',
        defaultValue: 'eu',
      ),
      encrypted: true,
    ),
    enableLogging: true,
  );
  
  // Subscribe to user-specific channels
  await subscribeToChannel('user-$userId');
  await subscribeToChannel('user-notifications-$userId');
  
  // Subscribe to general channels
  await subscribeToChannel('products');
  await subscribeToChannel('gigs');
  await subscribeToChannel('blog');
}
```

## Implementation Prioritization

1. **Phase 1 - Core Authentication & Profile**:
   - Connect AuthService to `/auth/*` endpoints
   - Implement token refresh mechanism
   - Connect UserProvider to profile endpoints
   - Implement profile image upload using multipart form data in the user profile endpoints

2. **Phase 2 - Social & Engagement Features**:
   - Connect MessageProvider to messaging endpoints
   - Implement real-time chat via Pusher
   - Connect NotificationProvider to notification endpoints
   - Implement real-time notifications

3. **Phase 3 - Core Marketplace Features**:
   - Connect CategoryProvider to category endpoints
   - Connect GigProvider to gig endpoints
   - Connect ProductProvider to product endpoints
   - Implement cart functionality

4. **Phase 4 - Content & Secondary Features**:
   - Connect BlogProvider to blog endpoints
   - Implement comment & like functionality
   - Connect PlanProvider to subscription endpoints
   - Implement subscription management

5. **Phase 5 - Polish & Optimization**:
   - Implement caching for frequently accessed data
   - Add offline support for critical features
   - Optimize API calls and batch requests
   - Implement analytics tracking

## Integration Testing Plan

For each integrated endpoint, implement the following testing steps:

1. **Unit Tests**:
   - Test data models with sample API responses
   - Test provider methods with mocked API service

2. **Integration Tests**:
   - Test API calls against mock server
   - Verify error handling for network failures
   - Test token refresh mechanism

3. **UI Tests**:
   - Verify data binding to UI components
   - Test loading/error states
   - Verify real-time updates via Pusher

## Category Models Update

```dart
class Category {
  final String uuid;
  final String name;
  final String? slug;
  final String? description;
  final String? icon;
  
  const Category({
    required this.uuid,
    required this.name,
    this.slug,
    this.description,
    this.icon,
  });
  
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      uuid: json['uuid'],
      name: json['name'],
      slug: json['slug'],
      description: json['description'],
      icon: json['icon'],
    );
  }
}

class SubCategory {
  final String uuid;
  final String name;
  final String? slug;
  final String? description;
  final String? icon;
  
  const SubCategory({
    required this.uuid,
    required this.name,
    this.slug,
    this.description,
    this.icon,
  });
  
  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      uuid: json['uuid'],
      name: json['name'],
      slug: json['slug'],
      description: json['description'],
      icon: json['icon'],
    );
  }
}

class Service {
  final String uuid;
  final String name;
  final String? description;
  
  const Service({
    required this.uuid,
    required this.name,
    this.description,
  });
  
  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      uuid: json['uuid'],
      name: json['name'],
      description: json['description'],
    );
  }
}
```

## Conclusion

The Wawu API provides a comprehensive set of endpoints for all planned features of the mobile application. Key changes from the previous understanding:

1. The base URL is `https://staging.wawuafrica.com/api`
2. Categories follow a three-tier hierarchy (Categories > Sub-categories > Services) critical for the gig creation flow
3. File uploads are handled as multipart form data directly within their respective endpoints

Most core providers already have a good structure in place but need to be updated to reflect these changes, particularly in the CategoryProvider to support the three-tier structure.

By following the implementation priorities outlined in this document, you can systematically integrate all required features while ensuring the UI is handled separately as per your workflow.
