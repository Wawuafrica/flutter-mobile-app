# Mentorship API Endpoints

## Overview
These endpoints handle the mentorship program, including mentor and mentee applications.

## Base URL
`{{url}}/api`

## Endpoints

### Submit Mentor Application
- **URL**: `/mentor`
- **Method**: `POST`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
- **Request Body**:
  ```json
  {
    "firstName": "Janet",
    "lastName": "Jackson",
    "email": "janetjacksone@test.com",
    "gender": "female",
    "professionalRole": "Software Engineer",
    "highestLevelOfEducation": "Masters",
    "race": "Black",
    "industryOfWork": "Tech",
    "companyName": "JTech Limited",
    "contactNumber": "+4543534534",
    "yearsOfExperience": 20,
    "currentJobDetails": "Lorem ipsum",
    "capacity": true,
    "reason": "Lorem ipsum",
    "values": "lorem ipsum",
    "commitment": "Lorem ipsum",
    "challenges": "Lorem ipsum",
    "beenAMentor": "Yes (formally)",
    "areaOfMentorship": "Software Engineering",
    "signature": {
      "fileName": "my_signature",
      "file": "image/base64"
    }
  }
  ```
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Success submitting mentor application form",
    "data": {
      "uuid": "02f141d9-495b-42b6-941d-23a0ca5cba57",
      "updatedAt": "2024-04-24T15:41:01.000000Z",
      "createdAt": "2024-04-24T15:41:01.000000Z",
      "firstName": "Janet",
      "lastName": "Jackson",
      "email": "janetjacksone@test.com",
      "gender": "female",
      "professionalRole": "Software Engineer",
      "highestLevelOfEducation": "Masters",
      "race": "Black",
      "industryOfWork": "Tech",
      "companyName": "JTech Limited",
      "contactNumber": "+4543534534",
      "yearsOfExperience": 20,
      "currentJobDetails": "Lorem ipsum",
      "capacity": true,
      "reason": "Lorem ipsum",
      "values": "lorem ipsum",
      "commitment": "Lorem ipsum",
      "challenges": "Lorem ipsum",
      "beenAMentor": "Yes (formally)",
      "areaOfMentorship": "Software Engineering",
      "signature": {
        "name": "my_signature",
        "link": "http://wawu.test/storage/27/my_signature"
      }
    }
  }
  ```

### Submit Mentee Application
- **URL**: `/mentee`
- **Method**: `POST`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
- **Request Body**:
  ```json
  {
    "firstName": "John",
    "lastName": "Jackson",
    "email": "johnjacksone@test.com",
    "phoneNumber": "3434234324",
    "address": "Lorem ipsum",
    "major": "Computer Science",
    "specialization": "Software Engineering",
    "bestContactType": "email",
    "reasonForApplication": "Lorem ipsum",
    "challenges": "Lorem ipsum",
    "helpToRender": "Something",
    "idealMentor": "A smart mentor",
    "mentorExperienceGain": "Lorem ipsum",
    "interests": "Coding",
    "additionalInfo": "Something",
    "signature": {
      "fileName": "my_signature",
      "file": "image/base64"
    }
  }
  ```
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Success submitting mentee application form",
    "data": {
      "uuid": "mentee_application_uuid",
      "updatedAt": "2025-05-17T08:20:01.000000Z",
      "createdAt": "2025-05-17T08:20:01.000000Z",
      "firstName": "John",
      "lastName": "Jackson",
      "email": "johnjacksone@test.com",
      "phoneNumber": "3434234324",
      "address": "Lorem ipsum",
      "major": "Computer Science",
      "specialization": "Software Engineering",
      "bestContactType": "email",
      "reasonForApplication": "Lorem ipsum",
      "challenges": "Lorem ipsum",
      "helpToRender": "Something",
      "idealMentor": "A smart mentor",
      "mentorExperienceGain": "Lorem ipsum",
      "interests": "Coding",
      "additionalInfo": "Something",
      "signature": {
        "name": "my_signature",
        "link": "http://wawu.test/storage/28/my_signature"
      }
    }
  }
  ```

### Get Mentorship Requests (Placeholder)
- **URL**: `/mentorship/requests`
- **Method**: `GET`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token
- **Query Parameters**:
  - `status`: Filter by status (e.g., "PENDING", "APPROVED", "REJECTED")
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Success fetching mentorship requests",
    "data": {
      "requests": [
        {
          "uuid": "request_uuid",
          "mentor": {
            "uuid": "mentor_uuid",
            "firstName": "Janet",
            "lastName": "Jackson",
            "professionalRole": "Software Engineer"
          },
          "mentee": {
            "uuid": "mentee_uuid",
            "firstName": "John",
            "lastName": "Doe",
            "specialization": "Software Engineering"
          },
          "status": "PENDING",
          "createdAt": "2025-05-10T14:22:30.000000Z"
        }
      ],
      "pagination": {
        "total": 12,
        "count": 10,
        "perPage": 10,
        "currentPage": 1,
        "totalPages": 2,
        "hasMorePages": true
      }
    }
  }
  ```

### Get Mentorship Sessions (Placeholder)
- **URL**: `/mentorship/sessions`
- **Method**: `GET`
- **Headers**:
  - `Api-Token`: API token
  - `channel`: Application channel
  - `Authorization`: Bearer token
- **Query Parameters**:
  - `status`: Filter by status (e.g., "ACTIVE", "COMPLETED")
- **Response**:
  ```json
  {
    "statusCode": 200,
    "message": "Success fetching mentorship sessions",
    "data": {
      "sessions": [
        {
          "uuid": "session_uuid",
          "mentor": {
            "uuid": "mentor_uuid",
            "firstName": "Janet",
            "lastName": "Jackson",
            "professionalRole": "Software Engineer"
          },
          "mentee": {
            "uuid": "mentee_uuid",
            "firstName": "John",
            "lastName": "Doe",
            "specialization": "Software Engineering"
          },
          "startDate": "2025-04-01T00:00:00.000000Z",
          "endDate": "2025-10-01T00:00:00.000000Z",
          "status": "ACTIVE",
          "progress": [
            {
              "date": "2025-04-15T00:00:00.000000Z",
              "notes": "Initial meeting - set goals and expectations"
            },
            {
              "date": "2025-05-01T00:00:00.000000Z",
              "notes": "Progress review - completed first project milestone"
            }
          ]
        }
      ],
      "pagination": {
        "total": 5,
        "count": 5,
        "perPage": 10,
        "currentPage": 1,
        "totalPages": 1,
        "hasMorePages": false
      }
    }
  }
  ```

## Note
The mentorship module appears to be in development and may not be fully implemented in the current API. The endpoints for mentorship requests and sessions are placeholders based on the documentation and may need to be updated once the API is fully implemented.
