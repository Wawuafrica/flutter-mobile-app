# Products API Endpoints

## Overview
These endpoints handle e-commerce product listings, including creation, updates, and ordering.

## Base URL
`{{url}}/api/products`

## Endpoints

### List Products
- **URL**: `/`
- **Method**: `GET`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token (optional)
- **Query Parameters**:
  - `page`: Page number for pagination (default: 1)
  - `limit`: Results per page (default: 20)
  - `category`: Filter by category UUID
  - `search`: Search term
  - `priceMin`: Minimum price
  - `priceMax`: Maximum price
  - `sort`: Sort order (e.g., "recent", "popular", "price_asc", "price_desc")
  - `sellerId`: Filter by seller ID
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Success fetching products",
    "data": {
      "products": [
        {
          "id": "product_uuid_1",
          "name": "African Print Dress",
          "description": "Beautiful African print dress with modern design",
          "price": 59.99,
          "currency": "USD",
          "seller_id": "seller_uuid_1",
          "seller_name": "African Fashions",
          "categories": ["women's clothing", "african print"],
          "tags": ["dress", "ankara", "fashion"],
          "image_urls": [
            "http://example.com/storage/401/dress_front.jpg",
            "http://example.com/storage/402/dress_back.jpg"
          ],
          "stock_quantity": 15,
          "rating": 4.7,
          "review_count": 42,
          "is_featured": true,
          "is_available": true,
          "attributes": {
            "sizes": ["S", "M", "L", "XL"],
            "colors": ["Red/Gold", "Blue/White", "Green/Yellow"],
            "material": "100% Cotton"
          },
          "discount_type": "percentage",
          "discount_value": 10,
          "created_at": "2025-03-14T12:30:45.000000Z",
          "updated_at": "2025-05-10T09:15:22.000000Z"
        }
      ],
      "pagination": {
        "total": 127,
        "count": 20,
        "perPage": 20,
        "currentPage": 1,
        "totalPages": 7,
        "hasMorePages": true
      }
    }
  }
  ```

### Get Featured Products
- **URL**: `/featured`
- **Method**: `GET`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Success fetching featured products",
    "data": {
      "products": [/* Array of product objects as shown above */]
    }
  }
  ```

### Get Product Details
- **URL**: `/{id}`
- **Method**: `GET`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token (optional)
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Success fetching product",
    "data": {
      "id": "product_uuid_1",
      "name": "African Print Dress",
      "description": "Beautiful African print dress with modern design",
      "detailed_description": "This stunning African print dress combines traditional Ankara patterns with a modern cut. Perfect for formal occasions or making a statement at casual events. Each piece is carefully crafted by our skilled artisans.",
      "price": 59.99,
      "currency": "USD",
      "seller": {
        "id": "seller_uuid_1",
        "name": "African Fashions",
        "avatar": "http://example.com/storage/123/seller_avatar.jpg",
        "rating": 4.8,
        "products_count": 37,
        "joined_date": "2024-01-15"
      },
      "categories": ["women's clothing", "african print"],
      "tags": ["dress", "ankara", "fashion"],
      "images": [
        {
          "url": "http://example.com/storage/401/dress_front.jpg",
          "is_primary": true
        },
        {
          "url": "http://example.com/storage/402/dress_back.jpg",
          "is_primary": false
        }
      ],
      "stock_quantity": 15,
      "rating": 4.7,
      "reviews": [
        {
          "id": "review_uuid_1",
          "user": {
            "id": "user_uuid_5",
            "name": "Sarah Johnson",
            "avatar": "http://example.com/storage/501/user_avatar.jpg"
          },
          "rating": 5,
          "comment": "Beautiful dress, excellent quality!",
          "created_at": "2025-05-10T14:22:30.000000Z"
        }
      ],
      "is_featured": true,
      "is_available": true,
      "attributes": {
        "sizes": ["S", "M", "L", "XL"],
        "colors": ["Red/Gold", "Blue/White", "Green/Yellow"],
        "material": "100% Cotton"
      },
      "discount_type": "percentage",
      "discount_value": 10,
      "shipping_info": {
        "available_regions": ["North America", "Europe", "Africa"],
        "estimated_delivery": "7-14 business days"
      },
      "return_policy": "30-day returns for unworn items",
      "created_at": "2025-03-14T12:30:45.000000Z",
      "updated_at": "2025-05-10T09:15:22.000000Z"
    }
  }
  ```

### Create Product (Seller)
- **URL**: `/`
- **Method**: `POST`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token
- **Request Body (multipart/form-data)**:
  - `name`: Product name
  - `description`: Product description
  - `price`: Product price
  - `currency`: Currency code (e.g., "USD", "NGN")
  - `categories[]`: Category IDs
  - `tags[]`: Product tags
  - `images[0][file]`: First image file
  - `images[0][fileName]`: First image name
  - `images[1][file]`: Second image file
  - `images[1][fileName]`: Second image name
  - `stock_quantity`: Available stock
  - `attributes[sizes][]`: Available sizes
  - `attributes[colors][]`: Available colors
  - `attributes[material]`: Material information
  - `discount_type`: Type of discount (optional)
  - `discount_value`: Discount amount (optional)
  - `shipping_info`: Shipping details (optional)
  - `return_policy`: Return policy (optional)
- **Response**:
  ```json
  {
    "statusCode": 201,
    "message": "Product created successfully",
    "data": {
      "id": "new_product_uuid",
      "name": "African Print Dress",
      "created_at": "2025-05-17T07:45:30.000000Z"
    }
  }
  ```

### Update Product (Seller)
- **URL**: `/{id}`
- **Method**: `PUT` or `PATCH`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token
- **Request Body**: Same format as Create Product
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Product updated successfully",
    "data": {
      "id": "product_uuid",
      "name": "Updated African Print Dress",
      "updated_at": "2025-05-17T07:48:15.000000Z"
    }
  }
  ```

### Delete Product (Seller)
- **URL**: `/{id}`
- **Method**: `DELETE`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Product deleted successfully"
  }
  ```

### Add Product Review
- **URL**: `/{id}/reviews`
- **Method**: `POST`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token
- **Request Body**:
  ```json
  {
    "rating": 5,
    "comment": "Excellent quality and fast shipping!",
    "images": [
      {
        "fileName": "review_photo.jpg",
        "file": "base64_encoded_image_data"
      }
    ]
  }
  ```
- **Response**:
  ```json
  {
    "statusCode": 201,
    "message": "Review submitted successfully",
    "data": {
      "id": "review_uuid",
      "rating": 5,
      "created_at": "2025-05-17T07:50:22.000000Z"
    }
  }
  ```

### Get Product Reviews
- **URL**: `/{id}/reviews`
- **Method**: `GET`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
- **Query Parameters**:
  - `page`: Page number for pagination (default: 1)
  - `limit`: Results per page (default: 10)
  - `rating`: Filter by rating (1-5)
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Success fetching reviews",
    "data": {
      "reviews": [
        {
          "id": "review_uuid_1",
          "user": {
            "id": "user_uuid_5",
            "name": "Sarah Johnson",
            "avatar": "http://example.com/storage/501/user_avatar.jpg"
          },
          "rating": 5,
          "comment": "Beautiful dress, excellent quality!",
          "images": [
            "http://example.com/storage/601/review_photo.jpg"
          ],
          "created_at": "2025-05-10T14:22:30.000000Z"
        }
      ],
      "statistics": {
        "averageRating": 4.7,
        "totalReviews": 42,
        "ratingDistribution": {
          "5": 28,
          "4": 10,
          "3": 2,
          "2": 1,
          "1": 1
        }
      },
      "pagination": {
        "total": 42,
        "count": 10,
        "perPage": 10,
        "currentPage": 1,
        "totalPages": 5,
        "hasMorePages": true
      }
    }
  }
  ```

## Order Endpoints

### Create Order
- **URL**: `/orders`
- **Method**: `POST`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token
- **Request Body**:
  ```json
  {
    "items": [
      {
        "product_id": "product_uuid_1",
        "quantity": 2,
        "attributes": {
          "size": "M",
          "color": "Red/Gold"
        }
      },
      {
        "product_id": "product_uuid_2",
        "quantity": 1,
        "attributes": {
          "size": "L",
          "color": "Blue/White"
        }
      }
    ],
    "shipping_address": {
      "name": "John Doe",
      "street": "123 Main St",
      "city": "Lagos",
      "state": "Lagos State",
      "country": "Nigeria",
      "postal_code": "100001",
      "phone": "+2341234567890"
    },
    "payment_method": "card",
    "payment_details": {
      "transaction_id": "txn_123456789"
    }
  }
  ```
- **Response**:
  ```json
  {
    "statusCode": 201,
    "message": "Order created successfully",
    "data": {
      "order_id": "order_uuid",
      "status": "PENDING",
      "total_amount": 139.97,
      "created_at": "2025-05-17T07:55:10.000000Z"
    }
  }
  ```

### Get My Orders
- **URL**: `/orders`
- **Method**: `GET`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token
- **Query Parameters**:
  - `page`: Page number for pagination (default: 1)
  - `limit`: Results per page (default: 10)
  - `status`: Filter by status (e.g., "PENDING", "SHIPPED", "DELIVERED", "CANCELLED")
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Success fetching orders",
    "data": {
      "orders": [
        {
          "id": "order_uuid_1",
          "status": "SHIPPED",
          "total_amount": 139.97,
          "items": [
            {
              "product_id": "product_uuid_1",
              "name": "African Print Dress",
              "price": 59.99,
              "quantity": 2,
              "image": "http://example.com/storage/401/dress_front.jpg",
              "attributes": {
                "size": "M",
                "color": "Red/Gold"
              }
            },
            {
              "product_id": "product_uuid_2",
              "name": "Beaded Necklace",
              "price": 19.99,
              "quantity": 1,
              "image": "http://example.com/storage/405/necklace.jpg",
              "attributes": {}
            }
          ],
          "shipping_address": {
            "name": "John Doe",
            "street": "123 Main St",
            "city": "Lagos",
            "state": "Lagos State"
          },
          "tracking_number": "TRK12345678",
          "created_at": "2025-05-10T18:22:45.000000Z",
          "updated_at": "2025-05-12T09:30:15.000000Z"
        }
      ],
      "pagination": {
        "total": 15,
        "count": 10,
        "perPage": 10,
        "currentPage": 1,
        "totalPages": 2,
        "hasMorePages": true
      }
    }
  }
  ```

## Real-time Updates (Pusher)

### Product Updated Event
- **Channel**: `products`
- **Event**: `product-updated`
- **Data Format**:
  ```json
  {
    "id": "product_uuid",
    "name": "African Print Dress",
    "price": 59.99,
    "stock_quantity": 14,
    "is_available": true,
    "updated_at": "2025-05-17T08:00:30.000000Z"
  }
  ```

### Product Stock Updated Event
- **Channel**: `products`
- **Event**: `product-stock-updated`
- **Data Format**:
  ```json
  {
    "product_id": "product_uuid",
    "stock_quantity": 14,
    "updated_at": "2025-05-17T08:01:22.000000Z"
  }
  ```
