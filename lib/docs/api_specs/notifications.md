# Notifications API Endpoints

## Overview
These endpoints handle user notifications, including listing, marking as read, and preferences.

## Base URL
`{{url}}/api/notifications`

## Endpoints

### List Notifications
- **URL**: `/`
- **Method**: `GET`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token
- **Query Parameters**:
  - `page`: Page number for pagination (default: 1)
  - `limit`: Results per page (default: 20)
  - `unread`: Filter for unread notifications only (boolean)
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Success fetching notifications",
    "data": {
      "notifications": [
        {
          "uuid": "notification_uuid_1",
          "title": "New Message",
          "body": "You have received a new message from Jane Smith",
          "type": "MESSAGE",
          "isRead": false,
          "data": {
            "conversationId": "conversation_uuid_1",
            "senderId": "user_uuid_2"
          },
          "createdAt": "2025-05-17T06:15:22.000000Z",
          "updatedAt": "2025-05-17T06:15:22.000000Z"
        },
        {
          "uuid": "notification_uuid_2",
          "title": "Gig Application Update",
          "body": "Your application for 'Full Frontend Web' has been accepted",
          "type": "GIG_APPLICATION",
          "isRead": true,
          "data": {
            "gigId": "gig_uuid_1",
            "applicationId": "application_uuid_1"
          },
          "createdAt": "2025-05-16T18:30:45.000000Z",
          "updatedAt": "2025-05-16T19:22:10.000000Z"
        }
      ],
      "pagination": {
        "total": 35,
        "count": 20,
        "perPage": 20,
        "currentPage": 1,
        "totalPages": 2,
        "hasMorePages": true
      },
      "unreadCount": 12
    }
  }
  ```

### Get Unread Count
- **URL**: `/unread-count`
- **Method**: `GET`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Success fetching unread count",
    "data": {
      "count": 12
    }
  }
  ```

### Mark Notification as Read
- **URL**: `/{uuid}/read`
- **Method**: `PUT` or `PATCH`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Notification marked as read",
    "data": {
      "uuid": "notification_uuid_1",
      "isRead": true,
      "updatedAt": "2025-05-17T07:35:12.000000Z"
    }
  }
  ```

### Mark All as Read
- **URL**: `/mark-all-as-read`
- **Method**: `PATCH`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "All notifications marked as read",
    "data": {
      "count": 12,
      "updatedAt": "2025-05-17T07:36:45.000000Z"
    }
  }
  ```

### Delete Notification
- **URL**: `/{uuid}`
- **Method**: `DELETE`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Notification deleted successfully"
  }
  ```

### Get Notification Settings
- **URL**: `/settings`
- **Method**: `GET`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Success fetching notification settings",
    "data": {
      "settings": {
        "email": {
          "messages": true,
          "gigApplications": true,
          "productOrders": true,
          "systemUpdates": false
        },
        "pushNotifications": {
          "messages": true,
          "gigApplications": true,
          "productOrders": true,
          "systemUpdates": true
        },
        "inApp": {
          "messages": true,
          "gigApplications": true,
          "productOrders": true,
          "systemUpdates": true
        }
      },
      "updatedAt": "2025-05-10T12:30:15.000000Z"
    }
  }
  ```

### Update Notification Settings
- **URL**: `/settings`
- **Method**: `PUT` or `PATCH`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token
- **Request Body**:
  ```json
  {
    "email": {
      "messages": true,
      "gigApplications": true,
      "productOrders": true,
      "systemUpdates": false
    },
    "pushNotifications": {
      "messages": true,
      "gigApplications": true,
      "productOrders": true,
      "systemUpdates": true
    },
    "inApp": {
      "messages": true,
      "gigApplications": true,
      "productOrders": true,
      "systemUpdates": true
    }
  }
  ```
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Notification settings updated successfully",
    "data": {
      "settings": {
        "email": {
          "messages": true,
          "gigApplications": true,
          "productOrders": true,
          "systemUpdates": false
        },
        "pushNotifications": {
          "messages": true,
          "gigApplications": true,
          "productOrders": true,
          "systemUpdates": true
        },
        "inApp": {
          "messages": true,
          "gigApplications": true,
          "productOrders": true,
          "systemUpdates": true
        }
      },
      "updatedAt": "2025-05-17T07:38:22.000000Z"
    }
  }
  ```

## Real-time Updates (Pusher)

### New Notification Event
- **Channel**: `user-notifications-{userId}`
- **Event**: `new-notification`
- **Data Format**:
  ```json
  {
    "uuid": "notification_uuid",
    "title": "New Message",
    "body": "You have received a new message from Jane Smith",
    "type": "MESSAGE",
    "isRead": false,
    "data": {
      "conversationId": "conversation_uuid_1",
      "senderId": "user_uuid_2"
    },
    "createdAt": "2025-05-17T07:39:30.000000Z",
    "updatedAt": "2025-05-17T07:39:30.000000Z"
  }
  ```
