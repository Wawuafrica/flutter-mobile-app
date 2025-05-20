# User Profile API Endpoints

## Overview
These endpoints handle user profile management, including retrieval, updates, and image uploads.

## Base URL
`{{url}}/api/user`

## Endpoints

### Get User Profile
- **URL**: `/profile`
- **Method**: `GET`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Success fetching user profile",
    "data": {
      "uuid": "user_uuid",
      "firstName": "John",
      "lastName": "Doe",
      "email": "user@example.com",
      "phoneNumber": "+1234567890",
      "jobType": "artisan",
      "type": "individual",
      "location": "Lagos, Nigeria",
      "professionalRole": "Software Engineer",
      "country": "Nigeria",
      "state": "Lagos",
      "createdAt": "2025-04-17T07:19:32.000000Z",
      "status": "ACTIVE",
      "profileImage": {
        "name": "profile_pic.jpg",
        "link": "http://example.com/storage/123/profile_pic.jpg"
      },
      "coverImage": {
        "name": "cover_image.jpg",
        "link": "http://example.com/storage/124/cover_image.jpg"
      },
      "role": "PROFESSIONAL",
      "profileCompletionRate": 85,
      "referralCode": "ABC123",
      "isSubscribed": false,
      "additionalInfo": {
        "about": "I am a Software Engineer with 5 years experience",
        "skills": [
          "Web Development",
          "Mobile App Development"
        ],
        "subCategories": [
          {
            "uuid": "decffc4e-7078-4993-b15d-700953744eb3",
            "name": "Web Development"
          }
        ],
        "preferredLanguage": "English",
        "education": [
          {
            "institution": "University of Lagos",
            "certification": "BSc",
            "courseOfStudy": "Computer Science",
            "graduationDate": "2016"
          }
        ],
        "professionalCertification": [
          {
            "name": "Completion of advanced Laravel",
            "organization": "Laravel",
            "endDate": "2018-09-01",
            "file": {
              "name": "cert.png",
              "link": "http://example.com/storage/125/cert.png"
            }
          }
        ],
        "meansOfIdentification": {
          "file": {
            "name": "myId.png",
            "link": "http://example.com/storage/126/myId.png"
          }
        },
        "socialHandles": {
          "twitter": "@tems",
          "facebook": "something",
          "linkedIn": null,
          "instagram": "someone"
        }
      }
    }
  }
  ```

### Update User Profile
- **URL**: `/profile/update`
- **Method**: `POST`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token
- **Request Body (multipart/form-data)**:
  - `country`: Country of residence
  - `state`: State of residence
  - `about`: User bio
  - `skills[1]`: First skill
  - `skills[2]`: Second skill
  - `serviceSubCategories[1]`: Service sub-category UUID
  - `education[1][institution]`: Institution name
  - `education[1][certification]`: Certification type
  - `education[1][courseOfStudy]`: Course of study
  - `education[1][graduationDate]`: Graduation year
  - `professionalCertification[1][name]`: Certification name
  - `professionalCertification[1][organization]`: Issuing organization
  - `professionalCertification[1][endDate]`: Issue date
  - `professionalCertification[1][file]`: Certificate file
  - `professionalCertification[1][fileName]`: Certificate file name
  - `social[twitter]`: Twitter handle
  - `social[facebook]`: Facebook URL
  - `social[instagram]`: Instagram handle
  - `meansOfIdentification[file]`: ID document
  - `meansOfIdentification[fileName]`: ID document file name
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Profile updated successfully",
    "data": {
      "uuid": "user_uuid",
      "profileCompletionRate": 95,
      "additionalInfo": {
        "about": "I am a Software Engineer with 5 years experience",
        "skills": [
          "Web Development",
          "Mobile App Development"
        ],
        "serviceSubCategories": [
          {
            "uuid": "decffc4e-7078-4993-b15d-700953744eb3",
            "name": "Web Development"
          }
        ]
      }
    }
  }
  ```

### Upload Profile/Cover Image
- **URL**: `/profile/image/update`
- **Method**: `POST`
- **Headers**:
  - `Authorization`: Bearer token
- **Request Body (multipart/form-data)**:
  - `profileImage[file]`: Profile image file
  - `profileImage[fileName]`: Profile image name
  - `coverImage[file]`: Cover image file
  - `coverImage[fileName]`: Cover image name
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Images updated successfully",
    "data": {
      "profileImage": {
        "name": "DP.png",
        "link": "http://example.com/storage/127/DP.png"
      },
      "coverImage": {
        "name": "cover_image.png",
        "link": "http://example.com/storage/128/cover_image.png"
      }
    }
  }
  ```

### Get User by ID
- **URL**: `/{uuid}`
- **Method**: `GET`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Success fetching user",
    "data": {
      "uuid": "user_uuid",
      "firstName": "John",
      "lastName": "Doe",
      "email": "user@example.com",
      "profileImage": {
        "name": "profile_pic.jpg",
        "link": "http://example.com/storage/123/profile_pic.jpg"
      },
      "role": "PROFESSIONAL"
    }
  }
  ```
