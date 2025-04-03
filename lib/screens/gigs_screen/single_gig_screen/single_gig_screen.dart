import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wawu_mobile/screens/messages_screen/single_message_screen/single_message_screen.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:wawu_mobile/widgets/custom_intro_text/custom_intro_text.dart';
import 'package:wawu_mobile/widgets/custom_textfield/custom_textfield.dart';
import 'package:wawu_mobile/widgets/gig_card/gig_card.dart';
import 'package:wawu_mobile/widgets/package_grid_component/package_grid_component.dart';
import 'package:wawu_mobile/widgets/review_component/review_component.dart';

class SingleGigScreen extends StatelessWidget {
  const SingleGigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gig')),
      body: ListView(
        children: [
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(color: Colors.grey),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Container(
                      color: Colors.black,
                      width: MediaQuery.of(context).size.width,
                      child: Opacity(
                        opacity: 0.7,
                        child: Image.asset(
                          'assets/images/section/programming.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Container(
                      color: Colors.black,
                      width: MediaQuery.of(context).size.width,
                      child: Opacity(
                        opacity: 0.7,
                        child: Image.asset(
                          'assets/images/section/programming.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Container(
                      color: Colors.black,
                      width: MediaQuery.of(context).size.width,
                      child: Opacity(
                        opacity: 0.7,
                        child: Image.asset(
                          'assets/images/section/programming.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 0,
                  bottom: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Icon(Icons.star, color: wawuColors.primary),
                        Icon(Icons.star, color: wawuColors.primary),
                        Icon(Icons.star, color: wawuColors.primary),
                        Icon(Icons.star, color: Colors.white),
                        Icon(Icons.star, color: Colors.white),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '4.4',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Icon(Icons.star, color: Colors.white, size: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: Colors.transparent,
            height: 80,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -40,
                  left: 0,
                  right: 0,
                  child: Container(
                    width: 90,
                    height: 90,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: wawuColors.primary),
                    ),
                    padding: EdgeInsets.all(2.0),
                    child: Container(
                      clipBehavior: Clip.hardEdge,
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Image.asset(
                        'assets/images/other/avatar.jpg',
                        // fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  right: 140,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SingleMessageScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: wawuColors.primary,
                      ),
                      child: Center(
                        child: FaIcon(
                          FontAwesomeIcons.message,
                          color: Colors.white,
                          size: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: Text(
              'Jane Doe',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          // SizedBox(height: 10),
          //Section for verified seller
          // Center(
          //   child: Text(
          //     'Jane Doe',
          //     style: TextStyle(fontWeight: FontWeight.w600),
          //   ),
          // ),
          // SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'I will do this and that for you',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: wawuColors.primary,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Lorem ipsum dolor sit amet, consectetur adipiscing aliquam augue hendrerit cursus. Proin mollis eget massa sed scelerisque. Nullam laoreet dictum viverra. Nullam ornare, urna in mattis pulvinar, felis elit convallis orci, at molestie purus eros id nisl. Nullam maximus sed neque ac pellentesque. Ut pretium felis risus, a gravida tellus feugiat at. Nullam bibendum mi vel arcu condimentum, sed suscipit dui sollicitudin. Nam',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 20),
                Row(
                  spacing: 10.0,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: wawuColors.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'Typing',
                          style: TextStyle(
                            color: wawuColors.primary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: wawuColors.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'Writing',
                          style: TextStyle(
                            color: wawuColors.primary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: wawuColors.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'Blog',
                          style: TextStyle(
                            color: wawuColors.primary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                CustomIntroText(text: 'About This Gig'),
                SizedBox(height: 10),
                Text(
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut tellus ipsum, sodales non rhoncus sit amet, viverra eu mi. Curabitur congue condimentum turpis sit amet maximus. Donec elementum ligula tellus, et blandit tortor maximus nec. Nullam rutrum rhoncus metus, quis aliquam augue hendrerit cursus. Proin mollis eget massa sed scelerisque. Nullam laoreet dictum viverra. Nullam ornare, urna in mattis pulvinar, felis elit convallis orci, at molestie purus eros id nisl. Nullam maximus sed neque ac pellentesque. Ut pretium felis risus, a gravida tellus feugiat at. Nullam bibendum mi vel arcu condimentum, sed suscipit dui sollicitudin. Nam',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 20),
                CustomIntroText(text: 'Packages'),
                SizedBox(height: 10),
                PackageGridComponent(isClient: true),
                SizedBox(height: 20),
                CustomIntroText(text: 'My Portfolio'),
                SizedBox(height: 10),
                GigCard(),
                SizedBox(height: 10),
                GigCard(),
                SizedBox(height: 20),
                CustomIntroText(text: 'FAQ'),
                SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.0),
                  margin: EdgeInsets.only(top: 10.0),
                  decoration: BoxDecoration(
                    color: wawuColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Why Choose Us',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Cause we are this and that...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.0),
                  margin: EdgeInsets.only(top: 10.0),
                  decoration: BoxDecoration(
                    color: wawuColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Why Choose Us',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Cause we are this and that...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                CustomIntroText(text: 'Reviews'),
                SizedBox(height: 10),
                ReviewComponent(),
                SizedBox(height: 10),
                ReviewComponent(),
                SizedBox(height: 40),
                Center(child: Text('Rate This Gig')),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: wawuColors.primary.withAlpha(40)),
                    Icon(Icons.star, color: wawuColors.primary.withAlpha(40)),
                    Icon(Icons.star, color: wawuColors.primary.withAlpha(40)),
                    Icon(Icons.star, color: wawuColors.primary.withAlpha(40)),
                    Icon(Icons.star, color: wawuColors.primary.withAlpha(40)),
                  ],
                ),
                CustomTextfield(
                  labelTextStyle2: true,
                  hintText: 'Write A Review',
                ),
                SizedBox(height: 10),
                CustomButton(
                  widget: Text('Send', style: TextStyle(color: Colors.white)),
                  color: wawuColors.primary,
                ),
                SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
