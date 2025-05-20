# Testing Instructions

This document provides instructions for testing the state management, Pusher real-time event handling, and API services in the Wawu Mobile app.

## Testing State Management

### Prerequisites
- Flutter SDK installed and configured
- An IDE (e.g., VS Code, Android Studio)
- A device or emulator running the app

### Testing User Provider
1. **Login/Logout Flow**
   - Open the app and navigate to the login screen
   - Enter valid credentials and observe UI updates (loading indicator → success)
   - Verify user data is correctly displayed after login
   - Perform logout and verify UI resets to initial state

2. **Error Handling**
   - Enter invalid credentials and observe error message display
   - Check that loading indicator is properly shown/hidden

### Testing Message Provider
1. **Conversation List**
   - Navigate to messages screen
   - Verify loading indicator appears while fetching conversations
   - Confirm conversation list renders correctly after data loads

2. **Individual Conversation**
   - Select a conversation from the list
   - Verify loading indicator appears while fetching messages
   - Confirm messages render correctly with appropriate styling for sent/received
   - Send a new message and verify it appears in the conversation
   - Check message status indicators (sent, delivered, read)

### Testing Notification Provider
1. **Notification List**
   - Navigate to notifications screen
   - Verify loading indicator appears while fetching notifications
   - Confirm notifications render with correct read/unread status
   - Mark a notification as read and verify UI updates

2. **Badge Counter**
   - Verify unread notification count is displayed correctly
   - After marking notifications as read, verify counter decreases

### Testing Gig Provider
1. **Gig Listings**
   - Navigate to gigs screen
   - Verify loading indicator appears while fetching gigs
   - Confirm gigs render with correct information
   - Test filtering gigs by category/budget and verify results update

2. **Gig Details**
   - Select a gig to view details
   - Verify all gig information displays correctly
   - If applicable, test applying for a gig and verify status changes

### Testing Blog Provider
1. **Blog List**
   - Navigate to blog screen
   - Verify loading indicator appears while fetching posts
   - Confirm posts render with correct information
   - Test pagination by scrolling and verify more posts load

2. **Blog Post Details**
   - Select a post to view details
   - Verify full content and images load correctly
   - If applicable, test liking a post and verify UI updates

### Testing Product Provider
1. **Product List**
   - Navigate to e-commerce screen
   - Verify loading indicator appears while fetching products
   - Confirm products render with correct information
   - Test filtering products and verify results update

2. **Cart Functionality**
   - Add a product to cart and verify cart counter updates
   - Update quantity and verify cart total updates
   - Remove a product and verify cart updates
   - Test checkout process

## Testing Pusher Real-Time Updates

### Prerequisites
- Pusher account and dashboard access
- Knowledge of channel/event names used in the app

### Testing Real-Time Messages
1. Use the Pusher Debug Console to simulate a new message:
   - Channel: `conversation-{conversationId}` (get ID from app logs)
   - Event: `new-message`
   - Data: 
     ```json
     {
       "id": "msg123",
       "sender_id": "user456",
       "receiver_id": "user789",
       "content": "This is a test message from Pusher",
       "timestamp": "2023-06-15T14:30:00Z",
       "is_read": false
     }
     ```
2. Verify the message appears in the conversation in real-time

### Testing Real-Time Notifications
1. Use the Pusher Debug Console to simulate a new notification:
   - Channel: `user-notifications-{userId}` (get ID from app logs)
   - Event: `new-notification`
   - Data:
     ```json
     {
       "id": "notif123",
       "user_id": "user789",
       "title": "New notification",
       "message": "This is a test notification from Pusher",
       "timestamp": "2023-06-15T14:35:00Z",
       "is_read": false,
       "type": "system"
     }
     ```
2. Verify the notification appears in the notifications list in real-time
3. Verify the notification badge counter updates

### Testing Other Real-Time Updates
Follow similar steps for other real-time updates (gigs, blog posts, products) using the appropriate channel names and event types.

## Testing API Services

### Prerequisites
- API documentation or mock server
- Postman or similar API testing tool (optional)

### Testing with Mock Data
1. The app is currently configured to use mock data for API responses
2. Test different API scenarios by modifying the mock responses in:
   - `lib/services/api_service.dart`

### Testing with Real API
1. Update the API base URL in the app:
   ```
   flutter run --dart-define=API_BASE_URL=https://your-real-api.com/v1
   ```
2. Test API endpoints functionality through the app UI
3. Verify error handling by intentionally causing errors (e.g., disconnecting internet)

## Debugging Tips
1. The app uses Logger for detailed logging. Filter console output for:
   - API calls: Look for lines with "API:"
   - Pusher events: Look for lines with "Pusher:"
   - Provider state changes: Look for lines with "Provider:"

2. To simulate Pusher events locally:
   - Use the Pusher Debug Console
   - Or use the debug helper in `lib/services/pusher_service.dart`:
     ```dart
     PusherService().debugTriggerEvent('channel-name', 'event-name', jsonData);
     ``` 