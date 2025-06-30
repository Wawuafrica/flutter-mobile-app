import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Frequently Asked Questions')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            _buildFAQItem(
              context: context,
              question: 'What is Wawu?',
              answer: Text(
                'WAWUAfrica, inspired by the exclamation "WOW," is the premier global work platform designed to empower women by providing a safe, inclusive, and supportive space to showcase their skills, connect with clients, and grow their businesses. ',
              ),
            ),
            Divider(),
            _buildFAQItem(
              context: context,
              question: 'Who can join Wawu?',
              answer: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WAWUAfrica is primarily for women freelancers, artisans, entrepreneurs, and professionals.  However, allies (men and organizations) who support women\'s economic empowerment are also welcome to join as clients, buyers or partners. ',
                  ),
                  SizedBox(height: 8),
                  Text(
                    '"There is neither Jew nor Greek, there is neither slave nor free, there is no male and female, for you are all one in Christ Jesus." Galatians 3:28 (ESV) ',
                  ),
                ],
              ),
            ),
            Divider(),
            _buildFAQItem(
              context: context,
              question: 'Services can I offer on Wawu',
              answer: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You can offer a wide range of legal and ethical services, including but not limited to: ',
                  ),
                  SizedBox(height: 8),
                  _buildBulletPoint('Writing and Content Creation'),
                  _buildBulletPoint('Graphic Design and Illustration'),
                  _buildBulletPoint('Web Development and Programming'),
                  _buildBulletPoint('Social Media Management'),
                  _buildBulletPoint('Virtual Assistant'),
                  _buildBulletPoint('Marketing and SEO'),
                  _buildBulletPoint('Coaching, Consulting, and Mentorship'),
                  _buildBulletPoint('Administrative Support'),
                  _buildBulletPoint('And many more! '),
                  SizedBox(height: 16),
                ],
              ),
            ),
            Divider(),
            _buildFAQItem(
              context: context,
              question: 'How do I find work on Wawu?',
              answer: Text(
                'Wawu Africa does not offer any jobs, but we provide a platform for you to search for work.  To get started, simply sign up and start bidding on projects or participating in contests.  You can also send quotes or post your services. ',
              ),
            ),
            Divider(),
            _buildFAQItem(
              context: context,
              question: 'How does the payment process work?',
              answer: Text(
                'This information is not explicitly detailed in the provided FAQ document. Please refer to the platform\'s official terms and conditions or contact support for details on the payment process.',
              ),
            ),
            Divider(),
            _buildFAQItem(
              context: context,
              question: 'How do I get paid?',
              answer: Text(
                'This information is not explicitly detailed in the provided FAQ document. Please refer to the platform\'s official terms and conditions or contact support for details on how you get paid.',
              ),
            ),
            Divider(),
            _buildFAQItem(
              context: context,
              question: 'Are there fees for using WAWUAfrica?',
              answer: Text(
                'Yes, sellers pay a one-time annual or monthly fee to register.  This payment is taken to maintain the platform, provide customer support, and fund empowerment programs for women. ',
              ),
            ),
            Divider(),
            _buildFAQItem(
              context: context,
              question: 'How do I sign up as a Seller?',
              answer: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1. Fill out a short signup form. You will be asked to create a unique username for identification in our system, provide a valid email address, and phone number, and confirm that you have read our Terms and Conditions. ',
                  ),
                  SizedBox(height: 8),
                  Text(
                    '2. Confirm your email address. When you submit the registration form, we will send a verification email to the email address you provided upon signing up. Follow the link provided in the email to activate your account. ',
                  ),
                  SizedBox(height: 8),
                  Text(
                    '3. You will be required to pay a one-time annual fee or monthly subscription fee to register. ',
                  ),
                  SizedBox(height: 8),
                  Text(
                    '4. Create and update your profile. Fill out your profile correctly and completely with all relevant certifications, qualifications and accreditations to let the buyer\'s community know who you are as a person, your expertise and your portfolio. Sellers with incomplete profiles will not be verified and allowed to bid on projects. ',
                  ),
                ],
              ),
            ),
            Divider(),
            _buildFAQItem(
              context: context,
              question: 'How do I sign up as a Buyer?',
              answer: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1. Fill out a short signup form. You will be asked to create a unique username for identification in our system, provide a valid email address, and phone number, and confirm that you have read our Terms and Conditions. ',
                  ),
                  SizedBox(height: 8),
                  Text(
                    '2. Confirm your email address. When you submit the registration form, we will send a verification email to the email address you provided upon signing up. Follow the link provided in the email to activate your account. ',
                  ),
                  SizedBox(height: 8),
                  Text(
                    '3. Create and update your profile. Fill out your profile correctly and completely with a valid ID to let the seller\'s community know who you are as a person, your interests and your offers. Buyers with incomplete profiles will not be verified and allowed to request services. ',
                  ),
                ],
              ),
            ),
            Divider(),
            _buildFAQItem(
              context: context,
              question: 'How does WAWUAfrica ensure safety for Women Sellers?',
              answer: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('We implement:'),
                  SizedBox(height: 8),
                  _buildBulletPoint('Verified profiles to reduce scams. '),
                  _buildBulletPoint(
                    'Secure payment systems to prevent fraud. ',
                  ),
                  _buildBulletPoint(
                    'A reporting system for harassment or misconduct. ',
                  ),
                  _buildBulletPoint(
                    'Community guidelines promoting respect and professionalism. ',
                  ),
                ],
              ),
            ),
            Divider(),
            _buildFAQItem(
              context: context,
              question: 'How does WAWUAfrica support skill development?',
              answer: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('We offer:'),
                  SizedBox(height: 8),
                  _buildBulletPoint(
                    'We tell you about Jesus\'s Death, His burial and His resurrection',
                  ),
                  _buildBulletPoint('Free and paid training webinars. '),
                  _buildBulletPoint('Mentorship programs. '),
                  _buildBulletPoint(
                    'Networking opportunities with industry experts. ',
                  ),
                  _buildBulletPoint('Empowerment opportunities as grants '),
                ],
              ),
            ),
            Divider(),
            _buildFAQItem(
              context: context,
              question:
                  'Can I collaborate with other freelancers on WAWUAfrica?',
              answer: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Yes! We encourage teamwork through: '),
                  SizedBox(height: 8),
                  _buildBulletPoint('Project partnerships. '),
                  _buildBulletPoint('Women-led business collectives. '),
                  _buildBulletPoint('Discussion forums for networking. '),
                ],
              ),
            ),
            Divider(),
            _buildFAQItem(
              context: context,
              question: 'What if I face discrimination or unfair treatment?',
              answer: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WAWUAfrica has a Zero-Tolerance Policy for discrimination. You can:',
                  ),
                  SizedBox(height: 8),
                  _buildBulletPoint('Report the issue via the app. '),
                  _buildBulletPoint('Seek mediation from our support team. '),
                  _buildBulletPoint('Get legal advice if necessary. '),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem({
    required String question,
    required Widget? answer,
    required BuildContext context,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent, // This removes the divider line
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        initiallyExpanded: false,
        tilePadding: EdgeInsets.zero, // Remove default padding
        childrenPadding: EdgeInsets.only(
          left: 0,
          right: 0,
          bottom: 16,
        ), // Adjust padding
        iconColor: Colors.grey[600], // Customize the expand/collapse icon color
        collapsedIconColor:
            Colors.grey[600], // Customize the collapsed icon color
        shape: Border(), // Remove the border
        collapsedShape: Border(), // Remove the collapsed border
        children: answer != null ? [answer] : [SizedBox.shrink()],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text('• '), Expanded(child: Text(text))],
      ),
    );
  }
}
