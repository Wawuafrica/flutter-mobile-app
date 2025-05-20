# Categories API Endpoints

## Overview
These endpoints handle the three-tier category structure:

1. **Categories** (top level)
2. **Sub-categories** (middle level, currently called "categories" in the app)
3. **Services** (specific services under each sub-category)

## Base URL
`{{url}}/api/categories`

## Endpoints

### List Categories
- **URL**: `/`
- **Method**: `GET`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
- **Query Parameters**:
  - `type`: Category type (e.g., "product", "service", "blog")
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Success fetching categories",
    "data": {
      "categories": [
        {
          "uuid": "category_uuid_1",
          "name": "Technology",
          "slug": "technology",
          "description": "Technology services",
          "icon": "http://staging.wawuafrica.com/storage/icons/tech.png",
          "subCategories": [
            {
              "uuid": "subcategory_uuid_1",
              "name": "Web Development",
              "slug": "web-development",
              "services": [
                {
                  "uuid": "service_uuid_1",
                  "name": "Frontend Development"
                },
                {
                  "uuid": "service_uuid_2",
                  "name": "Backend Development"
                }
              ]
            },
            {
              "uuid": "subcategory_uuid_2",
              "name": "Mobile App Development",
              "slug": "mobile-app-development",
              "services": [
                {
                  "uuid": "service_uuid_3",
                  "name": "iOS Development"
                },
                {
                  "uuid": "service_uuid_4",
                  "name": "Android Development"
                }
              ]
            }
          ]
        },
        {
          "uuid": "category_uuid_2",
          "name": "Fashion",
          "slug": "fashion",
          "description": "Fashion and clothing",
          "icon": "http://staging.wawuafrica.com/storage/icons/fashion.png",
          "subCategories": []
        }
      ]
    }
  }
  ```

### Get Category by ID
- **URL**: `/{uuid}`
- **Method**: `GET`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Success fetching category",
    "data": {
      "uuid": "category_uuid_1",
      "name": "Web Development",
      "slug": "web-development",
      "type": "service",
      "description": "Web development services",
      "icon": "http://example.com/storage/icons/web.png",
      "subCategories": [
        {
          "uuid": "subcategory_uuid_1",
          "name": "Frontend Development",
          "slug": "frontend-development"
        },
        {
          "uuid": "subcategory_uuid_2",
          "name": "Backend Development",
          "slug": "backend-development"
        }
      ],
      "createdAt": "2025-01-15T10:30:00.000000Z",
      "updatedAt": "2025-01-15T10:30:00.000000Z"
    }
  }
  ```

### Get Sub-Categories by Category ID
- **URL**: `/categories/{uuid}/subcategories`
- **Method**: `GET`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Success fetching sub-categories",
    "data": {
      "subCategories": [
        {
          "uuid": "subcategory_uuid_1",
          "name": "Web Development",
          "slug": "web-development",
          "description": "Web development services",
          "icon": "http://staging.wawuafrica.com/storage/icons/web.png"
        },
        {
          "uuid": "subcategory_uuid_2",
          "name": "Mobile App Development",
          "slug": "mobile-app-development",
          "description": "Mobile application development services",
          "icon": "http://staging.wawuafrica.com/storage/icons/mobile.png"
        }
      ]
    }
  }
  ```

### Get Services by Sub-Category ID
- **URL**: `/subcategories/{uuid}/services`
- **Method**: `GET`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Success fetching services",
    "data": {
      "services": [
        {
          "uuid": "service_uuid_1",
          "name": "Frontend Development",
          "description": "Creating user interfaces and experiences"
        },
        {
          "uuid": "service_uuid_2",
          "name": "Backend Development",
          "description": "Server-side programming and database management"
        }
      ]
    }
  }
  ```

### Get Blog Categories
- **URL**: `/blog`
- **Method**: `GET`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Success fetching blog categories",
    "data": {
      "categories": [
        {
          "uuid": "category_uuid_5",
          "name": "Business",
          "slug": "business",
          "description": "Business related articles",
          "icon": "http://example.com/storage/icons/business.png"
        },
        {
          "uuid": "category_uuid_6",
          "name": "Technology",
          "slug": "technology",
          "description": "Technology related articles",
          "icon": "http://example.com/storage/icons/tech.png"
        },
        {
          "uuid": "category_uuid_7",
          "name": "Culture",
          "slug": "culture",
          "description": "African culture articles",
          "icon": "http://example.com/storage/icons/culture.png"
        }
      ]
    }
  }
  ```

## Admin Endpoints (Not required for mobile app)

### Create Category
- **URL**: `/`
- **Method**: `POST`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token (admin only)
- **Request Body (multipart/form-data)**:
  - `name`: Category name
  - `type`: Category type (e.g., "product", "service", "blog")
  - `description`: Category description
  - `icon[file]`: Icon file
  - `icon[fileName]`: Icon file name
- **Response**:
  ```json
  {
    "statusCode": 201,
    "message": "Category created successfully",
    "data": {
      "uuid": "new_category_uuid",
      "name": "New Category",
      "slug": "new-category",
      "type": "product",
      "created_at": "2025-05-17T08:30:45.000000Z"
    }
  }
  ```

### Update Category
- **URL**: `/{uuid}`
- **Method**: `PUT` or `PATCH`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token (admin only)
- **Request Body**: Same format as Create Category
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Category updated successfully",
    "data": {
      "uuid": "category_uuid",
      "name": "Updated Category",
      "updated_at": "2025-05-17T08:32:22.000000Z"
    }
  }
  ```

### Delete Category
- **URL**: `/{uuid}`
- **Method**: `DELETE`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token (admin only)
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Category deleted successfully"
  }
  ```

## Real-time Updates (Pusher)

### Category Updated Event
- **Channel**: `categories`
- **Event**: `category-updated`
- **Data Format**:
  ```json
  {
    "uuid": "category_uuid",
    "name": "Updated Category",
    "slug": "updated-category",
    "type": "product",
    "updated_at": "2025-05-17T08:35:10.000000Z"
  }
  ```
