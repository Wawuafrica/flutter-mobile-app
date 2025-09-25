import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Frequently Asked Questions')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            // NEW FAQs (as requested in the previous prompt)
            _buildFAQItem(
              context: context,
              question: 'What is WAWUAfrica',
              answer: const Text(
                'Women at Work Universal (WAWUAfrica) is a Pan-African platform whose name takes inspiration from "WOW." Its mission is to empower women by creating a safe, inclusive, and supportive environment. The platform helps women gain visibility, develop skills through learning, connect with clients, and grow their businesses to ensure they are fairly compensated for their work.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
            const Divider(),
            _buildFAQItem(
              context: context,
              question: 'Who can join WAWUAfrica',
              answer: const Text(
                'WAWUAfrica is a community focused on women, including women communities, organizations, freelancers, artisans, entrepreneurs, and professionals. We also welcome male allies and organizations that support women\'s economic empowerment to join as clients, buyers, or partners.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
            const Divider(),
            _buildFAQItem(
              context: context,
              question: 'Are there fees?',
              answer: const Text(
                'Yes, users pay a one-time annual or monthly fee to register. This payment is taken to maintain the platform, provide customer support, and fund empowerment programs for women.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
            const Divider(),

            // RESTORED: Original FAQs are now included below
            _buildFAQItem(
              context: context,
              question: 'How do I sign up as a Seller?',
              answer: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBulletPoint(
                    'Fill out a short signup form. You will be asked to create a unique username for identification in our system, provide a valid email address, and phone number, and confirm that you have read our Terms and Conditions.',
                  ),
                  _buildBulletPoint(
                    'Confirm your email address. When you submit the registration form, we will send a verification email to the email address you provided upon signing up. Follow the link provided in the email to activate your account.',
                  ),
                  _buildBulletPoint(
                    'You will be required to pay a one-time annual fee or monthly subscription fee to register.',
                  ),
                  _buildBulletPoint(
                    'Create and update your profile. Fill out your profile correctly and completely with all relevant certifications, qualifications and accreditations to let the buyer’s community know who you are as a person, your expertise and your portfolio. Sellers with incomplete profiles will not be verified and allowed to bid on projects.',
                  ),
                ],
              ),
            ),
            const Divider(),
            _buildFAQItem(
              context: context,
              question: 'How do I sign up as a Buyer?',
              answer: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBulletPoint(
                    'Fill out a short signup form. You will be asked to create a unique username for identification in our system, provide a valid email address, and phone number, and confirm that you have read our Terms and Conditions.',
                  ),
                  _buildBulletPoint(
                    'Confirm your email address. When you submit the registration form, we will send a verification email to the email address you provided upon signing up. Follow the link provided in the email to activate your account.',
                  ),
                  _buildBulletPoint(
                    'Create and update your profile. Fill out your profile correctly and completely with a valid ID to let the seller’s community know who you are as a person, your interests and your offers. Buyers with incomplete profiles will not be verified and allowed to request services.',
                  ),
                ],
              ),
            ),
            const Divider(),
            _buildFAQItem(
              context: context,
              question: 'What types of services can I offer on WAWUAfrica?',
              answer: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('You can offer any legal and ethical service, including:'),
                  const SizedBox(height: 8),
                  _buildBulletPoint('Writing & Translation'),
                  _buildBulletPoint('Graphic Design & Digital Marketing'),
                  _buildBulletPoint('Consulting & Coaching'),
                  _buildBulletPoint('Tech & Web Development'),
                  _buildBulletPoint('Handmade Crafts, Fashion and many more'),
                  const SizedBox(height: 8),
                  const Text(
                    '"Whatever you do, work heartily, as for the Lord and not for men." Colossians 3:23 (ESV)',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF290D43),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            _buildFAQItem(
              context: context,
              question: 'How does WAWUAfrica ensure safety for Women Sellers?',
              answer: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('We implement:'),
                  const SizedBox(height: 8),
                  _buildBulletPoint('Verified profiles to reduce scams.'),
                  _buildBulletPoint('Secure payment systems to prevent fraud.'),
                  _buildBulletPoint('A reporting system for harassment or misconduct.'),
                  _buildBulletPoint('Community guidelines promoting respect and professionalism.'),
                  const SizedBox(height: 8),
                  const Text(
                    '"Do not withhold good from those to whom it is due, when it is in your power to do it." Proverbs 3:27 (ESV)',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF290D43),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            _buildFAQItem(
              context: context,
              question: 'How does WAWUAfrica support skill development?',
              answer: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBulletPoint('We tell you about Jesus’s Death, His Burial and His Resurrection'),
                  _buildBulletPoint('Free and paid training webinars.'),
                  _buildBulletPoint('Mentorship programs.'),
                  _buildBulletPoint('Networking opportunities with industry experts.'),
                  _buildBulletPoint('Empowerment opportunities as grants'),
                  const SizedBox(height: 8),
                  const Text(
                    '"Teach a woman in the way she should go, and when she is old, she will not depart from it." Proverbs 22:6',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF290D43),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            _buildFAQItem(
              context: context,
              question: 'Can I collaborate with other freelancers on WAWUAfrica?',
              answer: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Yes! We encourage teamwork through:'),
                  const SizedBox(height: 8),
                  _buildBulletPoint('Project partnerships.'),
                  _buildBulletPoint('Women-led business collectives.'),
                  _buildBulletPoint('Discussion forums for networking.'),
                  const SizedBox(height: 8),
                  const Text(
                    '"Two are better than one because they have a good reward for their toil." Ecclesiastes 4:9 (ESV)',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF290D43),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            _buildFAQItem(
              context: context,
              question: 'Is WAWUAfrica going to provide work for me?',
              answer: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'WAWUAfrica does not offer any jobs, but we provide a platform for you to search for work. To get started, simply sign up and start bidding on projects or participating in contests. You can also send quotes or post your services.',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'For even when we were with you, we gave you this rule: "The one who is unwilling to work shall not eat." 2 Thessalonians 3:10',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF290D43),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            _buildFAQItem(
              context: context,
              question: 'How can I maximize my success on WAWUAfrica?',
              answer: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBulletPoint('Get to know Jesus'),
                  _buildBulletPoint('Complete your profile with a portfolio.'),
                  _buildBulletPoint('Communicate professionally with clients.'),
                  _buildBulletPoint('Deliver quality work on time.'),
                  _buildBulletPoint('Join WAWUAfrica’s training programs.'),
                  const SizedBox(height: 8),
                  const Text(
                    '"Commit your work to the Lord, and your plans will be established." Proverbs 16:3 (ESV)',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF290D43),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            _buildFAQItem(
              context: context,
              question: 'What if I face discrimination or unfair treatment?',
              answer: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('WAWUAfrica has a Zero-Tolerance Policy for discrimination. You can:'),
                  const SizedBox(height: 8),
                  _buildBulletPoint('Report the issue via the app.'),
                  _buildBulletPoint('Seek mediation from our support team.'),
                  _buildBulletPoint('Get legal advice if necessary.'),
                  const SizedBox(height: 8),
                  const Text(
                    '"Learn to do good; seek justice, correct oppression." Isaiah 1:17 (ESV)',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF290D43),
                    ),
                  ),
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
    // Apply a default text style to the answer for consistent sizing.
    final Widget styledAnswer = DefaultTextStyle(
      style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
      child: answer ?? const SizedBox.shrink(),
    );

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: TextStyle(
            fontSize: 15, // Reduced question font size
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.all(0),
        childrenPadding: const EdgeInsets.only(left: 0, right: 0, bottom: 16),
        iconColor: Colors.grey[600],
        collapsedIconColor: Colors.grey[600],
        shape: const Border(),
        collapsedShape: const Border(),
        children: [styledAnswer],
      ),
    );
  }

  // RESTORED: This helper method is needed for the original FAQs.
  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}