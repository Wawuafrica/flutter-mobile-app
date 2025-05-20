# Messaging API Endpoints

## Overview
These endpoints handle chat functionality, including conversations and messages.

## Base URL
`{{url}}/api/messages`

## Endpoints

### List Conversations
- **URL**: `/conversations`
- **Method**: `GET`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token
- **Query Parameters**:
  - `page`: Page number for pagination (default: 1)
  - `limit`: Results per page (default: 10)
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Success fetching conversations",
    "data": {
      "conversations": [
        {
          "uuid": "conversation_uuid_1",
          "name": "Jane Smith",
          "lastMessage": {
            "uuid": "message_uuid_1",
            "message": "Hello there",
            "sentAt": "2025-05-16T18:30:45.000000Z",
            "isRead": true,
            "sentByMe": false
          },
          "recipient": {
            "uuid": "user_uuid_2",
            "firstName": "Jane",
            "lastName": "Smith",
            "profileImage": {
              "name": "profile.jpg",
              "link": "http://example.com/storage/301/profile.jpg"
            }
          },
          "unreadCount": 0,
          "updatedAt": "2025-05-16T18:30:45.000000Z"
        },
        {
          "uuid": "conversation_uuid_2",
          "name": "Alex Johnson",
          "lastMessage": {
            "uuid": "message_uuid_2",
            "message": "When can we meet?",
            "sentAt": "2025-05-17T06:15:22.000000Z",
            "isRead": false,
            "sentByMe": false
          },
          "recipient": {
            "uuid": "user_uuid_3",
            "firstName": "Alex",
            "lastName": "Johnson",
            "profileImage": {
              "name": "alex.jpg",
              "link": "http://example.com/storage/302/alex.jpg"
            }
          },
          "unreadCount": 3,
          "updatedAt": "2025-05-17T06:15:22.000000Z"
        }
      ],
      "pagination": {
        "total": 8,
        "count": 2,
        "perPage": 10,
        "currentPage": 1,
        "totalPages": 1,
        "hasMorePages": false
      }
    }
  }
  ```

### Get Messages in Conversation
- **URL**: `/conversations/{uuid}/messages`
- **Method**: `GET`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token
- **Query Parameters**:
  - `page`: Page number for pagination (default: 1)
  - `limit`: Results per page (default: 20)
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Success fetching messages",
    "data": {
      "messages": [
        {
          "uuid": "message_uuid_1",
          "message": "Hi there",
          "media": [
            {
              "name": "chat image",
              "link": "https://example.com/storage/11/chat-image"
            }
          ],
          "user": {
            "uuid": "user_uuid_1",
            "firstName": "John",
            "lastName": "Doe"
          },
          "chat": {
            "uuid": "conversation_uuid_1",
            "name": "Jane Smith"
          },
          "createdAt": "2025-05-16T14:30:10.000000Z",
          "updatedAt": "2025-05-16T14:30:10.000000Z",
          "sentByMe": true,
          "isRead": true
        },
        {
          "uuid": "message_uuid_2",
          "message": "Hello! How can I help you?",
          "media": [],
          "user": {
            "uuid": "user_uuid_2",
            "firstName": "Jane",
            "lastName": "Smith"
          },
          "chat": {
            "uuid": "conversation_uuid_1",
            "name": "John Doe"
          },
          "createdAt": "2025-05-16T14:35:22.000000Z",
          "updatedAt": "2025-05-16T14:35:22.000000Z",
          "sentByMe": false,
          "isRead": true
        }
      ],
      "pagination": {
        "total": 24,
        "count": 20,
        "perPage": 20,
        "currentPage": 1,
        "totalPages": 2,
        "hasMorePages": true
      }
    }
  }
  ```

### Send Message
- **URL**: `/`
- **Method**: `POST`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token
- **Request Body (multipart/form-data)**:
  - `message`: Message text
  - `recipientId`: Recipient user UUID
  - `conversationId`: Conversation UUID (optional - if not provided, a new conversation will be created if needed)
  - `media[file]`: Media file (optional)
  - `media[fileName]`: Media file name (optional)
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Success sending a message",
    "data": {
      "uuid": "new_message_uuid",
      "message": "Hi there",
      "media": [
        {
          "name": "chat image",
          "link": "https://example.com/storage/11/chat-image"
        }
      ],
      "user": {
        "uuid": "user_uuid_1",
        "firstName": "John",
        "lastName": "Doe"
      },
      "chat": {
        "uuid": "conversation_uuid_1",
        "name": "Jane Smith"
      },
      "createdAt": "2025-05-17T07:30:04.000000Z",
      "updatedAt": "2025-05-17T07:30:04.000000Z",
      "sentByMe": true
    }
  }
  ```

### Mark Message as Read
- **URL**: `/{uuid}/read`
- **Method**: `PUT`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Message marked as read",
    "data": {
      "uuid": "message_uuid",
      "isRead": true,
      "readAt": "2025-05-17T07:31:15.000000Z"
    }
  }
  ```

### Delete Message
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
    "message": "Message deleted successfully"
  }
  ```

## Real-time Updates (Pusher)

### New Message Event
- **Channel**: `conversation-{conversationId}`
- **Event**: `new-message`
- **Data Format**:
  ```json
  {
    "uuid": "message_uuid",
    "message": "New message content",
    "media": [
      {
        "name": "image.jpg",
        "link": "https://example.com/storage/12/image.jpg"
      }
    ],
    "user": {
      "uuid": "user_uuid",
      "firstName": "John",
      "lastName": "Doe"
    },
    "chat": {
      "uuid": "conversation_uuid",
      "name": "Jane Smith"
    },
    "createdAt": "2025-05-17T07:32:45.000000Z",
    "updatedAt": "2025-05-17T07:32:45.000000Z",
    "sentByMe": false
  }
  ```

### Message Read Event
- **Channel**: `conversation-{conversationId}`
- **Event**: `message-read`
- **Data Format**:
  ```json
  {
    "uuid": "message_uuid",
    "readAt": "2025-05-17T07:33:22.000000Z",
    "readByUserId": "user_uuid"
  }
  ```
