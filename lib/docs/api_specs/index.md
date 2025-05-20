# Wawu API Specifications Index

## Overview

This directory contains detailed API endpoint specifications extracted from the Wawu API documentation. Each file focuses on a specific feature area and provides information about available endpoints, request/response formats, and real-time event handling.

## Available API Documentation

| Feature | File | Description |
|---------|------|-------------|
| Authentication | [auth.md](./auth.md) | User registration, login, token management, password reset |
| User Profile | [user_profile.md](./user_profile.md) | Profile management, image uploads, user information |
| Messaging | [messaging.md](./messaging.md) | Conversations, messages, real-time chat |
| Notifications | [notifications.md](./notifications.md) | User notifications, read status, preferences |
| Gigs/Jobs | [gigs.md](./gigs.md) | Freelance gig listings, applications, management |
| E-commerce | [products.md](./products.md) | Product listings, cart, orders, reviews |
| Blog | [blog.md](./blog.md) | Blog posts, comments, likes, categories |
| Categories | [categories.md](./categories.md) | Three-tier category structure (Categories > Sub-categories > Services) |
| Subscription Plans | [plans.md](./plans.md) | Subscription plans, user subscriptions, billing |
| Mentorship | [mentorship.md](./mentorship.md) | Mentor/mentee applications and management |

## Integration Status

For an analysis of the current integration status and implementation plan, see the main [API Integration Analysis](../api_integration_update.md) document.

## API Structure

The Wawu API follows these general conventions:

- Base URL: `https://staging.wawuafrica.com/api`
- Authentication: JWT tokens via Authorization header
- Response format: JSON with consistent structure:
  ```json
  {
    "statusCode": 200,
    "message": "Success message",
    "data": { /* Response data */ }
  }
  ```
- Real-time updates: Pusher for real-time events

## Using These Specifications

These specifications should be used as reference when implementing the corresponding features in the mobile application. Each provider in the app (e.g., `UserProvider`, `MessageProvider`) should map to the appropriate API endpoints documented here.

Key implementation steps:
1. Update `ApiService` to connect to the correct base URL
2. Implement endpoint methods in each provider
3. Configure Pusher for real-time updates
4. Add error handling for API responses
