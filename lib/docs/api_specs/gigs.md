# Gigs API Endpoints

## Overview
These endpoints handle gig/job listings, including creation, updates, and applications.

## Base URL
`{{url}}/api/gigs`

## Endpoints

### List Gigs
- **URL**: `/`
- **Method**: `GET`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token (optional)
- **Query Parameters**:
  - `page`: Page number for pagination (default: 1)
  - `limit`: Results per page (default: 10)
  - `category`: Filter by category UUID
  - `search`: Search term
  - `priceMin`: Minimum price
  - `priceMax`: Maximum price
  - `sort`: Sort order (e.g., "recent", "popular")
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Success fetching gigs",
    "data": {
      "gigs": [
        {
          "uuid": "gig_uuid_1",
          "title": "Full Frontend Web",
          "description": "Create your web frontend pages",
          "about": "This gig is for creating a fontend websites",
          "services": [
            {
              "uuid": "a0fe837c-3e02-4a16-8a12-987597c50228",
              "name": "Web Development"
            }
          ],
          "assets": {
            "photos": [
              {
                "name": "Sample1.png",
                "link": "http://example.com/storage/201/Sample1.png"
              },
              {
                "name": "Sample2.png",
                "link": "http://example.com/storage/202/Sample2.png"
              }
            ],
            "video": {
              "name": "video_sample.mp4",
              "link": "http://example.com/storage/203/video_sample.mp4"
            },
            "pdf": {
              "name": "invoice.pdf",
              "link": "http://example.com/storage/204/invoice.pdf"
            }
          },
          "pricing": [
            {
              "package": {
                "name": "Standard Package",
                "description": "This is the standard package",
                "amount": 10
              },
              "features": [
                {
                  "name": "SEO keywords",
                  "value": "yes"
                },
                {
                  "name": "Plugins/extensions installation",
                  "value": "yes"
                }
              ]
            }
          ],
          "seller": {
            "uuid": "user_uuid",
            "name": "John Doe",
            "profileImage": {
              "name": "profile.jpg",
              "link": "http://example.com/storage/123/profile.jpg"
            },
            "rating": 4.8
          },
          "createdAt": "2025-04-24T15:41:01.000000Z",
          "updatedAt": "2025-04-24T15:41:01.000000Z"
        }
      ],
      "pagination": {
        "total": 27,
        "count": 10,
        "perPage": 10,
        "currentPage": 1,
        "totalPages": 3,
        "hasMorePages": true
      }
    }
  }
  ```

### Get Gig Details
- **URL**: `/{uuid}`
- **Method**: `GET`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token (optional)
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Success fetching gig",
    "data": {
      "uuid": "gig_uuid_1",
      "title": "Full Frontend Web",
      "description": "Create your web frontend pages",
      "about": "This gig is for creating a fontend websites",
      "services": [
        {
          "uuid": "a0fe837c-3e02-4a16-8a12-987597c50228",
          "name": "Web Development"
        }
      ],
      "assets": {
        "photos": [
          {
            "name": "Sample1.png",
            "link": "http://example.com/storage/201/Sample1.png"
          },
          {
            "name": "Sample2.png",
            "link": "http://example.com/storage/202/Sample2.png"
          }
        ],
        "video": {
          "name": "video_sample.mp4",
          "link": "http://example.com/storage/203/video_sample.mp4"
        },
        "pdf": {
          "name": "invoice.pdf",
          "link": "http://example.com/storage/204/invoice.pdf"
        }
      },
      "pricing": [
        {
          "package": {
            "name": "Standard Package",
            "description": "This is the standard package",
            "amount": 10
          },
          "features": [
            {
              "name": "SEO keywords",
              "value": "yes"
            },
            {
              "name": "Plugins/extensions installation",
              "value": "yes"
            }
          ]
        }
      ],
      "seller": {
        "uuid": "user_uuid",
        "name": "John Doe",
        "profileImage": {
          "name": "profile.jpg",
          "link": "http://example.com/storage/123/profile.jpg"
        },
        "rating": 4.8,
        "reviews": 27,
        "memberSince": "2024-01-01"
      },
      "createdAt": "2025-04-24T15:41:01.000000Z",
      "updatedAt": "2025-04-24T15:41:01.000000Z"
    }
  }
  ```

### Create Gig
- **URL**: `/`
- **Method**: `POST`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token
- **Request Body (multipart/form-data)**:
  - `title`: Gig title
  - `description`: Short gig description
  - `about`: Detailed gig information
  - `services[1]`: Service category UUID
  - `asset[photos][1][file]`: First photo file
  - `asset[photos][1][fileName]`: First photo name
  - `asset[photos][2][file]`: Second photo file
  - `asset[photos][2][fileName]`: Second photo name
  - `asset[video][file]`: Video file
  - `asset[video][fileName]`: Video file name
  - `asset[pdf][file]`: PDF document
  - `asset[pdf][fileName]`: PDF name
  - `pricing[1][package][name]`: Package name
  - `pricing[1][package][description]`: Package description
  - `pricing[1][package][amount]`: Package price
  - `pricing[1][features][1][name]`: Feature name
  - `pricing[1][features][1][value]`: Feature value
  - `pricing[1][features][2][name]`: Second feature name
  - `pricing[1][features][2][value]`: Second feature value
- **Response**:
  ```json
  {
    "statusCode": 201,
    "message": "Gig created successfully",
    "data": {
      "uuid": "new_gig_uuid",
      "title": "Full Frontend Web",
      "description": "Create your web frontend pages"
    }
  }
  ```

### Update Gig
- **URL**: `/{uuid}`
- **Method**: `PUT` or `PATCH`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token
- **Request Body**: Same format as Create Gig
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Gig updated successfully",
    "data": {
      "uuid": "gig_uuid",
      "title": "Updated Frontend Web",
      "description": "Updated description"
    }
  }
  ```

### Delete Gig
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
    "message": "Gig deleted successfully"
  }
  ```

### Apply for Gig
- **URL**: `/{uuid}/apply`
- **Method**: `POST`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token
- **Request Body**:
  ```json
  {
    "message": "I am interested in this gig and have the required skills",
    "proposedAmount": 15,
    "proposedTimeline": "7 days"
  }
  ```
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Application submitted successfully",
    "data": {
      "uuid": "application_uuid",
      "status": "PENDING",
      "createdAt": "2025-05-17T07:25:00.000000Z"
    }
  }
  ```

### Get My Gigs (Seller)
- **URL**: `/my-gigs`
- **Method**: `GET`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token
- **Response**: Similar to List Gigs but with only the user's created gigs

### Get My Applications (Buyer)
- **URL**: `/my-applications`
- **Method**: `GET`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token
- **Response**: List of gigs the user has applied for with application status
