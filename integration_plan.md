# Wawu Mobile App Integration Plan

## Overview
This document outlines the step-by-step plan for connecting providers and API services to UI components following the app's navigation flow.

## Navigation Flow & Integration Plan

### 1. Onboarding & Authentication

#### 1.1 Splash Screen
- **Provider**: None required
- **Status**: No integration needed

#### 1.2 Sign In Screen (`lib/screens/wawu_africa/sign_in/sign_in.dart`)
- **Provider**: `UserProvider`
- **Status**: Not connected
- **Integration Plan**:
  ```dart
  // Wrap with Consumer<UserProvider>
  Consumer<UserProvider>(
    builder: (context, userProvider, child) {
      return Scaffold(
        // Existing UI...
        
        // Add loading indicator
        if (userProvider.isLoading)
          CircularProgressIndicator(),
          
        // Add error message display
        if (userProvider.hasError)
          Text(userProvider.errorMessage ?? 'An error occurred'),
          
        // Connect login button
        CustomButton(
          function: () async {
            await userProvider.login(emailController.text, passwordController.text);
            if (userProvider.isSuccess && userProvider.currentUser != null) {
              Navigator.pushReplacement(
                context, 
                MaterialPageRoute(builder: (context) => MainScreen())
              );
            }
          },
          // Other properties...
        ),
      );
    }
  )
  ```

#### 1.3 Sign Up Screen (`lib/screens/wawu_africa/sign_up/sign_up.dart`)
- **Provider**: `UserProvider`
- **Status**: Not connected
- **Integration Plan**:
  ```dart
  // Wrap with Consumer<UserProvider>
  Consumer<UserProvider>(
    builder: (context, userProvider, child) {
      return Scaffold(
        // Existing UI...
        
        // Add loading and error states
        
        // Connect register button
        CustomButton(
          function: () async {
            final userData = {
              'name': nameController.text,
              'email': emailController.text,
              'password': passwordController.text,
              // Other fields...
            };
            
            await userProvider.register(userData);
            if (userProvider.isSuccess) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AccountType())
              );
            }
          },
          // Other properties...
        ),
      );
    }
  )
  ```

#### 1.4 Account Type Selection (`lib/screens/account_type/account_type.dart`)
- **Provider**: `UserProvider`
- **Status**: Not connected
- **Integration Plan**:
  ```dart
  Consumer<UserProvider>(
    builder: (context, userProvider, child) {
      return Scaffold(
        // Existing UI...
        
        // Connect account type selection
        // Update user profile with account type
        CustomButton(
          function: () async {
            await userProvider.updateCurrentUserProfile({
              'accountType': selectedAccountType,
            });
            
            if (userProvider.isSuccess) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => CategorySelection())
              );
            }
          },
          // Other properties...
        ),
      );
    }
  )
  ```

### 2. User Setup Flow

#### 2.1 Category Selection (`lib/screens/category_selection/category_selection.dart`)
- **Providers**: `CategoryProvider`, `UserProvider`
- **Status**: Not connected
- **Integration Plan**:
  ```dart
  Consumer2<CategoryProvider, UserProvider>(
    builder: (context, categoryProvider, userProvider, child) {
      // Load categories if not loaded
      if (!categoryProvider.isLoading && categoryProvider.categories.isEmpty) {
        categoryProvider.fetchCategories();
      }
      
      return Scaffold(
        // Existing UI...
        
        // Display categories from provider
        ListView.builder(
          itemCount: categoryProvider.categories.length,
          itemBuilder: (context, index) {
            final category = categoryProvider.categories[index];
            return CategoryItem(
              category: category,
              onSelected: (selected) {
                // Update selected categories
              },
            );
          },
        ),
        
        // Connect continue button
        CustomButton(
          function: () async {
            await userProvider.updateCurrentUserProfile({
              'categories': selectedCategories,
            });
            
            if (userProvider.isSuccess) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen())
              );
            }
          },
          // Other properties...
        ),
      );
    }
  )
  ```

#### 2.2 Profile Setup (`lib/screens/profile/profile_screen.dart`)
- **Provider**: `UserProvider`
- **Status**: Not connected
- **Integration Plan**:
  ```dart
  Consumer<UserProvider>(
    builder: (context, userProvider, child) {
      final user = userProvider.currentUser;
      
      // Handle loading and error states
      
      return Scaffold(
        // Existing UI...
        
        // Pre-fill form with existing user data if available
        CustomTextfield(
          controller: nameController..text = user?.name ?? '',
          // Other properties...
        ),
        
        // Connect save button
        CustomButton(
          function: () async {
            final profileData = {
              'name': nameController.text,
              'about': aboutController.text,
              'skills': skills,
              // Other fields...
            };
            
            await userProvider.updateCurrentUserProfile(
              profileData,
              profileImageFile: _profileImage,
              coverImageFile: _coverImage,
            );
            
            if (userProvider.isSuccess) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => Plan())
              );
            }
          },
          // Other properties...
        ),
      );
    }
  )
  ```

#### 2.3 Plan Selection (`lib/screens/plan/plan.dart`)
- **Provider**: `PlanProvider`
- **Status**: Not connected
- **Integration Plan**:
  ```dart
  Consumer<PlanProvider>(
    builder: (context, planProvider, child) {
      // Load plans if not loaded
      if (!planProvider.isLoading && planProvider.plans.isEmpty) {
        planProvider.fetchPlans();
      }
      
      return Scaffold(
        // Existing UI...
        
        // Display plans from provider
        ListView.builder(
          itemCount: planProvider.plans.length,
          itemBuilder: (context, index) {
            final plan = planProvider.plans[index];
            return PlanCard(
              plan: plan,
              onSelected: () async {
                await planProvider.selectPlan(plan.id);
                if (planProvider.isSuccess) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => MainScreen())
                  );
                }
              },
            );
          },
        ),
      );
    }
  )
  ```

### 3. Main App Flow

#### 3.1 Main Screen (`lib/screens/main_screen/main_screen.dart`)
- **Provider**: `UserProvider` (for auth state)
- **Status**: Not connected
- **Integration Plan**:
  ```dart
  Consumer<UserProvider>(
    builder: (context, userProvider, child) {
      // Check if user is authenticated
      if (!userProvider.isAuthenticated) {
        return SignIn();
      }
      
      return Scaffold(
        // Bottom navigation and app bar
        body: _pages[_selectedIndex],
      );
    }
  )
  ```

#### 3.2 Home Screen (`lib/screens/home_screen/home_screen.dart`)
- **Providers**: `GigProvider`, `CategoryProvider`, `BlogProvider`, `ProductProvider`
- **Status**: Not connected
- **Integration Plan**:
  ```dart
  MultiProvider(
    providers: [
      // Initialize data loading
      Consumer<GigProvider>(
        builder: (context, provider, _) {
          if (!provider.isLoading && provider.gigs.isEmpty) {
            provider.fetchGigs();
          }
          return SizedBox.shrink();
        }
      ),
      // Similar for other providers...
    ],
    child: Scaffold(
      body: ListView(
        children: [
          // Featured carousel
          Consumer<BlogProvider>(
            builder: (context, provider, _) {
              // Handle loading state
              // Display featured blogs in carousel
            },
          ),
          
          // Popular categories
          Consumer<CategoryProvider>(
            builder: (context, provider, _) {
              // Handle loading state
              // Display categories
            },
          ),
          
          // E-commerce section
          Consumer<ProductProvider>(
            builder: (context, provider, _) {
              // Handle loading state
              // Display products
            },
          ),
          
          // Recently viewed gigs
          Consumer<GigProvider>(
            builder: (context, provider, _) {
              // Handle loading state
              // Display recently viewed gigs
            },
          ),
        ],
      ),
    ),
  )
  ```

#### 3.3 Services/Gigs Screen (`lib/screens/services/services.dart`)
- **Provider**: `GigProvider`, `CategoryProvider`
- **Status**: Not connected
- **Integration Plan**:
  ```dart
  Consumer2<GigProvider, CategoryProvider>(
    builder: (context, gigProvider, categoryProvider, child) {
      // Load data if needed
      
      return Scaffold(
        // Existing UI...
        
        // Display categories for filtering
        Consumer<CategoryProvider>(
          builder: (context, provider, _) {
            // Display category filters
          },
        ),
        
        // Display gigs
        Consumer<GigProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return CircularProgressIndicator();
            }
            
            return ListView.builder(
              itemCount: provider.filteredGigs.length,
              itemBuilder: (context, index) {
                return GigCard(
                  gig: provider.filteredGigs[index],
                  onTap: () {
                    provider.viewGig(provider.filteredGigs[index].id);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SingleGigScreen(
                          gigId: provider.filteredGigs[index].id,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      );
    }
  )
  ```

#### 3.4 Single Gig Screen (`lib/screens/gigs_screen/single_gig_screen.dart`)
- **Providers**: `GigProvider`, `ReviewProvider`, `ApplicationProvider`
- **Status**: Not connected
- **Integration Plan**:
  ```dart
  Consumer3<GigProvider, ReviewProvider, ApplicationProvider>(
    builder: (context, gigProvider, reviewProvider, applicationProvider, child) {
      // Load gig details if needed
      if (!gigProvider.isLoading && gigProvider.currentGig == null) {
        gigProvider.fetchGigById(widget.gigId);
      }
      
      // Load reviews if needed
      if (!reviewProvider.isLoading && reviewProvider.reviews.isEmpty) {
        reviewProvider.fetchReviewsForGig(widget.gigId);
      }
      
      // Handle loading states
      
      return Scaffold(
        // Display gig details
        // Display reviews
        // Connect apply button
        CustomButton(
          function: () async {
            await applicationProvider.applyForGig(widget.gigId);
            if (applicationProvider.isSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Application submitted successfully')),
              );
            }
          },
          // Other properties...
        ),
      );
    }
  )
  ```

#### 3.5 Messages Screen (`lib/screens/messages_screen/messages_screen.dart`)
- **Provider**: `MessageProvider`
- **Status**: Not connected
- **Integration Plan**:
  ```dart
  Consumer<MessageProvider>(
    builder: (context, messageProvider, child) {
      // Load messages if needed
      if (!messageProvider.isLoading && messageProvider.conversations.isEmpty) {
        messageProvider.fetchConversations();
      }
      
      // Handle loading and error states
      
      return Scaffold(
        // Display conversations
        ListView.builder(
          itemCount: messageProvider.conversations.length,
          itemBuilder: (context, index) {
            final conversation = messageProvider.conversations[index];
            return ConversationTile(
              conversation: conversation,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SingleMessageScreen(
                      conversationId: conversation.id,
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
    }
  )
  ```

#### 3.6 Single Message Screen (`lib/screens/messages_screen/single_message_screen.dart`)
- **Provider**: `MessageProvider`
- **Status**: Not connected
- **Integration Plan**:
  ```dart
  Consumer<MessageProvider>(
    builder: (context, messageProvider, child) {
      // Load messages for this conversation
      if (!messageProvider.isLoading && messageProvider.messages.isEmpty) {
        messageProvider.fetchMessages(widget.conversationId);
      }
      
      // Subscribe to real-time updates
      // This should be done in initState with a check to avoid duplicate subscriptions
      
      return Scaffold(
        // Display messages
        ListView.builder(
          itemCount: messageProvider.messages.length,
          itemBuilder: (context, index) {
            final message = messageProvider.messages[index];
            return MessageBubble(message: message);
          },
        ),
        
        // Connect send message functionality
        // Message input field and send button
      );
    }
  )
  ```

#### 3.7 Notifications Screen (`lib/screens/notifications/notifications.dart`)
- **Provider**: `NotificationProvider`
- **Status**: Not connected
- **Integration Plan**:
  ```dart
  Consumer<NotificationProvider>(
    builder: (context, notificationProvider, child) {
      // Load notifications if needed
      if (!notificationProvider.isLoading && notificationProvider.notifications.isEmpty) {
        notificationProvider.fetchNotifications();
      }
      
      // Handle loading and error states
      
      return Scaffold(
        // Display notifications
        ListView.builder(
          itemCount: notificationProvider.notifications.length,
          itemBuilder: (context, index) {
            final notification = notificationProvider.notifications[index];
            return NotificationTile(
              notification: notification,
              onTap: () {
                notificationProvider.markAsRead(notification.id);
                // Navigate based on notification type
              },
            );
          },
        ),
      );
    }
  )
  ```

#### 3.8 Profile Screen (Viewing) (`lib/screens/profile/profile_screen.dart`)
- **Provider**: `UserProvider`, `ReviewProvider`
- **Status**: Not connected
- **Integration Plan**:
  ```dart
  Consumer2<UserProvider, ReviewProvider>(
    builder: (context, userProvider, reviewProvider, child) {
      final user = userProvider.currentUser;
      
      // Load user reviews if needed
      if (!reviewProvider.isLoading && reviewProvider.reviews.isEmpty) {
        reviewProvider.fetchReviewsForUser(user?.id);
      }
      
      // Handle loading and error states
      
      return Scaffold(
        // Display user profile information
        // Display user reviews
        // Connect edit profile button
      );
    }
  )
  ```

#### 3.9 Blog Screen (`lib/screens/blog_screen/blog_screen.dart`)
- **Provider**: `BlogProvider`
- **Status**: Not connected
- **Integration Plan**:
  ```dart
  Consumer<BlogProvider>(
    builder: (context, blogProvider, child) {
      // Load blogs if needed
      if (!blogProvider.isLoading && blogProvider.blogs.isEmpty) {
        blogProvider.fetchBlogs();
      }
      
      // Handle loading and error states
      
      return Scaffold(
        // Display blog posts
        ListView.builder(
          itemCount: blogProvider.blogs.length,
          itemBuilder: (context, index) {
            final blog = blogProvider.blogs[index];
            return BlogCard(
              blog: blog,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SingleBlogScreen(
                      blogId: blog.id,
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
    }
  )
  ```

#### 3.10 E-commerce Screen (`lib/screens/wawu_ecommerce_screen/wawu_ecommerce_screen.dart`)
- **Provider**: `ProductProvider`
- **Status**: Not connected
- **Integration Plan**:
  ```dart
  Consumer<ProductProvider>(
    builder: (context, productProvider, child) {
      // Load products if needed
      if (!productProvider.isLoading && productProvider.products.isEmpty) {
        productProvider.fetchProducts();
      }
      
      // Handle loading and error states
      
      return Scaffold(
        // Display products
        GridView.builder(
          itemCount: productProvider.products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (context, index) {
            final product = productProvider.products[index];
            return ProductCard(
              product: product,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SinglePackage(
                      productId: product.id,
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
    }
  )
  ```

## Implementation Strategy

### Phase 1: Authentication & User Profile
1. Connect `UserProvider` to sign-in and sign-up screens
2. Implement profile screen with `UserProvider`
3. Add proper navigation based on authentication state

### Phase 2: Home Screen & Core Features
1. Connect `CategoryProvider` to category screens
2. Connect `GigProvider` to gig screens
3. Connect `ProductProvider` to e-commerce screens
4. Update home screen to use all relevant providers

### Phase 3: Messaging & Notifications
1. Connect `MessageProvider` to message screens
2. Connect `NotificationProvider` to notification screen
3. Implement real-time updates with `PusherService`

### Phase 4: Secondary Features
1. Connect `BlogProvider` to blog screens
2. Connect `ReviewProvider` to review sections
3. Connect `PlanProvider` to plan screen
4. Connect `ApplicationProvider` to application screens

## Best Practices

### Efficient Provider Usage
- Use `Selector` instead of `Consumer` when only a specific part of the provider state is needed
- Avoid rebuilding entire screens when only small parts change

### Proper Loading States
- Always handle loading, error, and success states
- Provide retry mechanisms for failed operations
- Show appropriate UI feedback during async operations

### Separation of Concerns
- Keep business logic in providers
- UI components should receive data and report user actions
- Avoid direct API calls from UI components
