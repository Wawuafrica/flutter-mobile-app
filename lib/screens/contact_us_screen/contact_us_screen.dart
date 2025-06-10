import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Contact Us')),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Don't hesitate to contact us whether you have a suggestion on our improvement, a complain to discuss or an issue to solve.",
            ),
            SizedBox(height: 40),
            Row(
              spacing: 10.0,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _makePhoneCall('07050622222'),
                    child: Column(
                      spacing: 10.0,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: wawuColors.primary,
                          ),
                          child: Center(
                            child: FaIcon(
                              FontAwesomeIcons.phone,
                              color: Colors.white,
                              size: 15,
                            ),
                          ),
                        ),
                        Text(
                          'Call Us',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Our team is on the line',
                          style: TextStyle(
                            color: Color.fromARGB(255, 181, 181, 181),
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          'Mon-Fri • 9-17',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color.fromARGB(255, 181, 181, 181),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _sendEmail('support@wawuafrica.com'),
                    child: Column(
                      spacing: 10.0,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: wawuColors.primary,
                          ),
                          child: Center(
                            child: FaIcon(
                              FontAwesomeIcons.message,
                              color: Colors.white,
                              size: 15,
                            ),
                          ),
                        ),
                        Text(
                          'Email Us',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Our team is on the line',
                          style: TextStyle(
                            color: Color.fromARGB(255, 181, 181, 181),
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          'Mon-Fri • 9-17',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color.fromARGB(255, 181, 181, 181),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 40),
            Text(
              'Contact Us on Social Media',
              style: TextStyle(
                color: const Color.fromARGB(255, 182, 182, 182),
                fontSize: 12,
              ),
            ),
            SizedBox(height: 10),
            _buildSocialContactCard(
              'Instagram',
              FontAwesomeIcons.instagram,
              () => _openSocialMedia('https://instagram.com/wawu.africa'),
            ),
            SizedBox(height: 10),
            _buildSocialContactCard(
              'TikTok',
              FontAwesomeIcons.tiktok,
              () => _openSocialMedia('https://tiktok.com/@wawuafrica'),
            ),
            SizedBox(height: 10),
            _buildSocialContactCard(
              'Twitter',
              FontAwesomeIcons.twitter,
              () => _openSocialMedia('https://twitter.com/wawu_africa'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialContactCard(
    String text,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 70,
        padding: EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey, width: 0.5),
        ),
        child: Row(
          spacing: 10.0,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: wawuColors.primary,
              ),
              child: Center(child: FaIcon(icon, color: Colors.white, size: 15)),
            ),
            Expanded(child: Text(text)),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: wawuColors.primary.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: FaIcon(
                  FontAwesomeIcons.arrowUpFromBracket,
                  color: Colors.black,
                  size: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  void _sendEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Contact%20from%20Wawu%20App',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  void _openSocialMedia(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
