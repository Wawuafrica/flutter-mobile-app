# Authentication API Endpoints

## Overview
The authentication module handles user registration, login, token management, and account verification.

## Base URL
`{{url}}/api/auth`

## Endpoints

### Login
- **URL**: `/login`
- **Method**: `POST`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
- **Request Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "password123"
  }
  ```
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Login successful",
    "data": {
      "token": "jwt_token_here",
      "user": {
        "uuid": "user_uuid",
        "firstName": "John",
        "lastName": "Doe",
        "email": "user@example.com",
        "role": "USER",
        "status": "ACTIVE",
        "profileImage": {
          "name": "profile_pic.jpg",
          "link": "http://example.com/storage/123/profile_pic.jpg"
        }
      }
    }
  }
  ```

### Register
- **URL**: `/register`
- **Method**: `POST`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
- **Request Body**:
  ```json
  {
    "firstName": "John",
    "lastName": "Doe",
    "email": "user@example.com",
    "password": "password123",
    "passwordConfirmation": "password123",
    "phoneNumber": "+1234567890"
  }
  ```
- **Response**:
  ```json
  {
    "statusCode": 201,
    "message": "Registration successful",
    "data": {
      "token": "jwt_token_here",
      "user": {
        "uuid": "user_uuid",
        "firstName": "John",
        "lastName": "Doe",
        "email": "user@example.com",
        "role": "USER",
        "status": "PENDING",
        "createdAt": "2025-05-17T07:19:32.000000Z"
      }
    }
  }
  ```

### Logout
- **URL**: `/logout`
- **Method**: `POST`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Logout successful"
  }
  ```

### Request Password Reset
- **URL**: `/forgot-password`
- **Method**: `POST`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
- **Request Body**:
  ```json
  {
    "email": "user@example.com"
  }
  ```
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Password reset link has been sent to your email"
  }
  ```

### Reset Password
- **URL**: `/reset-password`
- **Method**: `POST`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
- **Request Body**:
  ```json
  {
    "token": "reset_token_from_email",
    "password": "new_password",
    "passwordConfirmation": "new_password"
  }
  ```
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Password has been reset"
  }
  ```

### Verify Email
- **URL**: `/verify-email`
- **Method**: `POST`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
- **Request Body**:
  ```json
  {
    "verificationCode": "123456"
  }
  ```
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Email verified successfully",
    "data": {
      "user": {
        "uuid": "user_uuid",
        "status": "ACTIVE",
        "emailVerifiedAt": "2025-05-17T07:19:32.000000Z"
      }
    }
  }
  ```

### Refresh Token
- **URL**: `/refresh-token`
- **Method**: `POST`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Token refreshed",
    "data": {
      "token": "new_jwt_token_here"
    }
  }
  ```
