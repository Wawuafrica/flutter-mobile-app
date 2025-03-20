import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Terms of Use')),
      body: Container(
        padding: EdgeInsets.only(left: 10.0, right: 10.0, bottom: 20.0),
        height: MediaQuery.of(context).size.height,
        child: Markdown(
          data: '''
# Terms of Use

Welcome to Wawu! By accessing or using our platform (the "Service"), you agree to comply with and be bound by the following Terms of Use ("Terms"), which constitute a legally binding agreement between you and Wawu. If you do not agree with these Terms, please do not use our Service.

## 1. Introduction

### 1.1 About the Service
Wawu provides a platform that connects freelancers (hereinafter referred to as "Freelancers") with businesses or individuals seeking to hire services (hereinafter referred to as "Clients"). Our Service allows Freelancers to offer their skills and services, and Clients to find and hire Freelancers for various projects.

### 1.2 Acceptance of Terms
By using our platform, you agree to these Terms, as well as any policies or guidelines incorporated by reference. If you are using our Service on behalf of an organization or other entity, you represent that you have the authority to bind that entity to these Terms.

## 2. Account Registration

### 2.1 Account Creation
To use certain features of the Service, you must create an account. You agree to provide accurate, complete, and current information when registering, and to update your account details as necessary to keep them accurate.

### 2.2 Account Responsibility
You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. Notify us immediately of any unauthorized use of your account.

### 2.3 Eligibility
You must be at least 18 years old to use the Service. By using the platform, you represent that you meet this requirement.

## 3. Service Usage

### 3.1 Freelancers
Freelancers may offer their services through the platform, set their own rates, and define the scope of their work. You are responsible for the quality and accuracy of the services you provide, and you agree to fulfill all terms and deadlines as agreed upon with Clients.

### 3.2 Clients
Clients may post job opportunities, request quotes, or hire Freelancers for various projects. You agree to provide clear, complete, and accurate information about the project requirements and expectations.

### 3.3 Communication
All communication between Freelancers and Clients should be conducted through the platform's messaging system. Any external communication may result in the suspension or termination of your account.
          ''',
        ),
      ),
    );
  }
}
