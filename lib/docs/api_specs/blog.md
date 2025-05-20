# Blog API Endpoints

## Overview
These endpoints handle blog content, including posts, comments, and categories.

## Base URL
`{{url}}/api/blog`

## Endpoints

### List Blog Posts
- **URL**: `/posts`
- **Method**: `GET`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
- **Query Parameters**:
  - `page`: Page number for pagination (default: 1)
  - `limit`: Results per page (default: 10)
  - `category`: Filter by category name
  - `search`: Search term
  - `sort`: Sort order (e.g., "recent", "popular")
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Success fetching posts",
    "data": {
      "posts": [
        {
          "uuid": "post_uuid_1",
          "title": "My Blog Post",
          "content": "<p>This is the content of my first blog post</p>",
          "excerpt": "This is the content of my first blog post",
          "page": "Home",
          "category": "Business",
          "status": "Published",
          "user": {
            "uuid": "user_uuid_1",
            "firstName": "Admin",
            "lastName": "User",
            "email": "admin@wawu.com"
          },
          "coverImage": {
            "name": "new_blog.png",
            "link": "http://example.com/storage/124/new_blog.png"
          },
          "created_at": "2025-05-14T03:21:17.000000Z",
          "updated_at": "2025-05-14T03:21:17.000000Z"
        }
      ],
      "pagination": {
        "total": 45,
        "count": 10,
        "perPage": 10,
        "currentPage": 1,
        "totalPages": 5,
        "hasMorePages": true
      }
    }
  }
  ```

### Get Blog Post
- **URL**: `/posts/{uuid}`
- **Method**: `GET`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Success fetching post",
    "data": {
      "uuid": "post_uuid_1",
      "title": "My Blog Post",
      "content": "<p>This is the content of my first blog post</p>",
      "page": "Home",
      "category": "Business",
      "status": "Published",
      "user": {
        "uuid": "user_uuid_1",
        "firstName": "Admin",
        "lastName": "User",
        "email": "admin@wawu.com"
      },
      "coverImage": {
        "name": "new_blog.png",
        "link": "http://example.com/storage/124/new_blog.png"
      },
      "created_at": "2025-05-14T03:21:17.000000Z",
      "updated_at": "2025-05-14T03:21:17.000000Z",
      "comments": [
        {
          "uuid": "comment_uuid_1",
          "content": "Great post!",
          "user": {
            "uuid": "user_uuid_2",
            "firstName": "John",
            "lastName": "Doe",
            "profileImage": {
              "name": "profile.jpg",
              "link": "http://example.com/storage/125/profile.jpg"
            }
          },
          "created_at": "2025-05-15T14:22:30.000000Z"
        }
      ],
      "tags": ["business", "entrepreneurship", "africa"]
    }
  }
  ```

### Create Blog Comment
- **URL**: `/posts/{uuid}/comments`
- **Method**: `POST`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token
- **Request Body**:
  ```json
  {
    "content": "This is my comment on the post!"
  }
  ```
- **Response**:
  ```json
  {
    "statusCode": 201,
    "message": "Comment created successfully",
    "data": {
      "uuid": "new_comment_uuid",
      "content": "This is my comment on the post!",
      "user": {
        "uuid": "user_uuid",
        "firstName": "John",
        "lastName": "Doe"
      },
      "created_at": "2025-05-17T08:05:45.000000Z"
    }
  }
  ```

### Get Blog Categories
- **URL**: `/categories`
- **Method**: `GET`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Success fetching categories",
    "data": {
      "categories": [
        {
          "uuid": "category_uuid_1",
          "name": "Business",
          "slug": "business",
          "description": "Business related articles",
          "count": 15
        },
        {
          "uuid": "category_uuid_2",
          "name": "Technology",
          "slug": "technology",
          "description": "Technology related articles",
          "count": 22
        },
        {
          "uuid": "category_uuid_3",
          "name": "Culture",
          "slug": "culture",
          "description": "African culture articles",
          "count": 8
        }
      ]
    }
  }
  ```

### Like a Blog Post
- **URL**: `/posts/{uuid}/like`
- **Method**: `POST`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Post liked successfully",
    "data": {
      "likes": 42
    }
  }
  ```

### Unlike a Blog Post
- **URL**: `/posts/{uuid}/unlike`
- **Method**: `DELETE`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Post unliked successfully",
    "data": {
      "likes": 41
    }
  }
  ```

### Get Featured Blog Posts
- **URL**: `/posts/featured`
- **Method**: `GET`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Success fetching featured posts",
    "data": {
      "posts": [/* Array of blog post objects */]
    }
  }
  ```

## Admin Endpoints (Not required for mobile app)

### Create Blog Post
- **URL**: `/posts`
- **Method**: `POST`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token (admin only)
- **Request Body (multipart/form-data)**:
  - `title`: Post title
  - `content`: Post content (HTML)
  - `category`: Category name
  - `tags[]`: Array of tags
  - `coverImage[file]`: Cover image file
  - `coverImage[fileName]`: Cover image name
  - `status`: Post status ("Draft" or "Published")
- **Response**:
  ```json
  {
    "statusCode": 201,
    "message": "Blog post created successfully",
    "data": {
      "uuid": "new_post_uuid",
      "title": "New Blog Post",
      "created_at": "2025-05-17T08:10:22.000000Z"
    }
  }
  ```

## Real-time Updates (Pusher)

### New Blog Post Event
- **Channel**: `blog`
- **Event**: `blogpost-created`
- **Data Format**:
  ```json
  {
    "uuid": "post_uuid",
    "title": "New Blog Post",
    "excerpt": "This is a new blog post",
    "category": "Business",
    "coverImage": {
      "name": "blog_cover.png",
      "link": "http://example.com/storage/128/blog_cover.png"
    },
    "created_at": "2025-05-17T08:12:30.000000Z"
  }
  ```

### Blog Post Updated Event
- **Channel**: `blog`
- **Event**: `blogpost-updated`
- **Data Format**:
  ```json
  {
    "uuid": "post_uuid",
    "title": "Updated Blog Post",
    "updated_at": "2025-05-17T08:15:45.000000Z"
  }
  ```
