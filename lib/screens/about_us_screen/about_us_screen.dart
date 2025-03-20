import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('About Us')),
      body: Container(
        padding: EdgeInsets.only(left: 10.0, right: 10.0, bottom: 20.0),
        height: MediaQuery.of(context).size.height, // Set a bounded height
        child: Markdown(
          data: '''
# **About Us**

Welcome to **Wawu**, where talent meets opportunity. At Wawu, we believe that great work can come from anywhere, and the right people can make any project a success. Our mission is simple: to connect talented freelancers with businesses of all sizes and industries, creating a marketplace that’s efficient, creative, and collaborative. We bring together the best of Upwork and Fiverr, combining the flexibility of freelance work with the reliability of professional services.

Whether you’re a business looking for top-tier professionals or a freelancer ready to offer your skills to the world, we’ve got you covered. Our platform is designed to make the process seamless, empowering both freelancers and businesses to achieve their goals, build lasting relationships, and grow together.

## What We Do

We provide a space for:
- **Freelancers of all kinds**—writers, designers, developers, marketers, and more—to showcase their expertise, find clients, and grow their careers.
- **Clients** to easily discover the right talent for their projects—whether short-term tasks, long-term contracts, or specialized skills.

## Why Choose Us?

- **A Diverse Pool of Talent**: With Wawu, you gain access to a wide range of skilled professionals from all corners of the globe. From small startups to large enterprises, we provide customized solutions for all.
- **Flexible, Transparent**: We believe in transparency. Freelancers set their own rates, and clients can find the perfect fit based on budget and skills. No hidden fees—just fair and open communication.
- **Easy Collaboration**: Our platform is designed with collaboration in mind. Tools for messaging, project management, and secure payment make working with talent easier than ever.

## Our Vision

To revolutionize how people and businesses connect with freelancers by creating a supportive, trusted, and innovative space that encourages collaboration, growth, and success.

## Our Values

- **Empowerment**: We believe in empowering both freelancers and clients to achieve their best work.
- **Integrity**: We are committed to honesty, transparency, and fairness.
- **Innovation**: We strive to stay ahead of the curve, offering new tools and features to make the platform better for everyone.
- **Community**: At the heart of everything, we are building a community where collaboration and mutual respect thrive.

Join us at Wawu, and let’s make something amazing together.

            ''',
        ),
      ),
    );
  }
}
