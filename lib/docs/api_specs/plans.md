# Subscription Plans API Endpoints

## Overview
These endpoints handle subscription plans and user subscriptions.

## Base URL
`{{url}}/api`

## Endpoints

### List Plans
- **URL**: `/plans`
- **Method**: `GET`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Success fetching plans",
    "data": {
      "plans": [
        {
          "uuid": "plan_uuid_1",
          "name": "Basic",
          "description": "Basic plan for individuals",
          "price": 9.99,
          "currency": "USD",
          "interval": "monthly",
          "features": [
            "Access to basic features",
            "Up to 10 listings",
            "Standard support"
          ],
          "isActive": true,
          "createdAt": "2025-01-01T00:00:00.000000Z",
          "updatedAt": "2025-01-01T00:00:00.000000Z"
        },
        {
          "uuid": "plan_uuid_2",
          "name": "Premium",
          "description": "Premium plan for professionals",
          "price": 29.99,
          "currency": "USD",
          "interval": "monthly",
          "features": [
            "Access to all features",
            "Unlimited listings",
            "Priority support",
            "Featured profile"
          ],
          "isActive": true,
          "createdAt": "2025-01-01T00:00:00.000000Z",
          "updatedAt": "2025-01-01T00:00:00.000000Z"
        }
      ]
    }
  }
  ```

### Get Plan Details
- **URL**: `/plans/{uuid}`
- **Method**: `GET`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Success fetching plan",
    "data": {
      "uuid": "plan_uuid_2",
      "name": "Premium",
      "description": "Premium plan for professionals",
      "price": 29.99,
      "currency": "USD",
      "interval": "monthly",
      "features": [
        "Access to all features",
        "Unlimited listings",
        "Priority support",
        "Featured profile"
      ],
      "isActive": true,
      "createdAt": "2025-01-01T00:00:00.000000Z",
      "updatedAt": "2025-01-01T00:00:00.000000Z"
    }
  }
  ```

### Create Subscription
- **URL**: `/subscriptions`
- **Method**: `POST`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token
- **Request Body**:
  ```json
  {
    "planId": "plan_uuid_2",
    "paymentMethodId": "payment_method_id"
  }
  ```
- **Response**:
  ```json
  {
    "statusCode": 201,
    "message": "Subscription created successfully",
    "data": {
      "uuid": "subscription_uuid_1",
      "plan": {
        "uuid": "plan_uuid_2",
        "name": "Premium"
      },
      "startDate": "2025-05-17T08:45:30.000000Z",
      "endDate": "2025-06-17T08:45:30.000000Z",
      "status": "active",
      "createdAt": "2025-05-17T08:45:30.000000Z"
    }
  }
  ```

### Get Current User's Subscription
- **URL**: `/subscriptions/me`
- **Method**: `GET`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Success fetching subscription",
    "data": {
      "subscription": {
        "uuid": "subscription_uuid_1",
        "plan": {
          "uuid": "plan_uuid_2",
          "name": "Premium",
          "description": "Premium plan for professionals",
          "price": 29.99,
          "currency": "USD",
          "interval": "monthly",
          "features": [
            "Access to all features",
            "Unlimited listings",
            "Priority support",
            "Featured profile"
          ]
        },
        "startDate": "2025-05-17T08:45:30.000000Z",
        "endDate": "2025-06-17T08:45:30.000000Z",
        "status": "active",
        "paymentMethod": "Visa ending in 4242",
        "autoRenew": true,
        "createdAt": "2025-05-17T08:45:30.000000Z",
        "updatedAt": "2025-05-17T08:45:30.000000Z"
      }
    }
  }
  ```

### Cancel Subscription
- **URL**: `/subscriptions/{uuid}/cancel`
- **Method**: `PUT`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Subscription cancelled successfully",
    "data": {
      "uuid": "subscription_uuid_1",
      "status": "cancelled",
      "endDate": "2025-06-17T08:45:30.000000Z",
      "updatedAt": "2025-05-17T08:50:15.000000Z"
    }
  }
  ```

### Update Payment Method
- **URL**: `/subscriptions/{uuid}/payment-method`
- **Method**: `PUT`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token
- **Request Body**:
  ```json
  {
    "paymentMethodId": "new_payment_method_id"
  }
  ```
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Payment method updated successfully",
    "data": {
      "uuid": "subscription_uuid_1",
      "paymentMethod": "Mastercard ending in 5555",
      "updatedAt": "2025-05-17T08:52:30.000000Z"
    }
  }
  ```

### Toggle Auto-Renew
- **URL**: `/subscriptions/{uuid}/auto-renew`
- **Method**: `PUT`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token
- **Request Body**:
  ```json
  {
    "autoRenew": false
  }
  ```
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Auto-renew setting updated successfully",
    "data": {
      "uuid": "subscription_uuid_1",
      "autoRenew": false,
      "updatedAt": "2025-05-17T08:55:45.000000Z"
    }
  }
  ```

### Get Subscription Invoices
- **URL**: `/subscriptions/{uuid}/invoices`
- **Method**: `GET`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Success fetching invoices",
    "data": {
      "invoices": [
        {
          "uuid": "invoice_uuid_1",
          "amount": 29.99,
          "currency": "USD",
          "status": "paid",
          "paidAt": "2025-05-17T08:45:30.000000Z",
          "periodStart": "2025-05-17T08:45:30.000000Z",
          "periodEnd": "2025-06-17T08:45:30.000000Z",
          "downloadUrl": "http://example.com/invoices/invoice_uuid_1.pdf",
          "createdAt": "2025-05-17T08:45:30.000000Z"
        }
      ]
    }
  }
  ```

## Real-time Updates (Pusher)

### Subscription Updated Event
- **Channel**: `user-{userId}`
- **Event**: `subscription-updated`
- **Data Format**:
  ```json
  {
    "uuid": "subscription_uuid_1",
    "status": "active",
    "plan": {
      "uuid": "plan_uuid_2",
      "name": "Premium"
    },
    "endDate": "2025-06-17T08:45:30.000000Z",
    "updatedAt": "2025-05-17T09:00:15.000000Z"
  }
  ```

### Plan Updated Event
- **Channel**: `plans`
- **Event**: `plan-updated`
- **Data Format**:
  ```json
  {
    "uuid": "plan_uuid_2",
    "name": "Premium",
    "price": 29.99,
    "updatedAt": "2025-05-17T09:05:22.000000Z"
  }
  ```
