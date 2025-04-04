import 'package:flutter/material.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/comment_component/comment_component.dart';
import 'package:wawu_mobile/widgets/custom_intro_text/custom_intro_text.dart';
import 'package:wawu_mobile/widgets/fading_carousel/fading_carousel.dart';

class SingleBlogScreen extends StatelessWidget {
  const SingleBlogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Widget> carouselItems = [
      Container(
        decoration: BoxDecoration(color: Colors.red.withAlpha(0)),
        child: Image.asset(
          'assets/images/section/graphics.png',
          fit: BoxFit.cover,
        ),
      ),
      Container(
        decoration: BoxDecoration(color: Colors.red.withAlpha(0)),
        child: Image.asset(
          'assets/images/section/graphics.png',
          fit: BoxFit.cover,
        ),
      ),
      Container(
        decoration: BoxDecoration(color: Colors.red.withAlpha(0)),
        child: Image.asset(
          'assets/images/section/graphics.png',
          fit: BoxFit.cover,
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Blog')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: ListView(
          children: [
            FadingCarousel(height: 180, children: carouselItems),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(15.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                color: wawuColors.primary.withAlpha(40),
              ),
              child: Text(
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 10.0,
              children: [
                Container(
                  width: 50,
                  height: 25,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: wawuColors.primary.withAlpha(70)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.thumb_up_alt,
                        size: 10,
                        color: wawuColors.primary,
                      ),
                      Text(
                        '2K',
                        style: TextStyle(
                          fontSize: 11,
                          color: wawuColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 50,
                  height: 25,
                  decoration: BoxDecoration(
                    color: wawuColors.primary.withAlpha(70),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.mode_comment,
                        size: 10,
                        color: wawuColors.primary,
                      ),
                      Text(
                        '1.1K',
                        style: TextStyle(
                          fontSize: 11,
                          color: wawuColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            CustomIntroText(text: 'Comments'),
            SizedBox(height: 10),
            CommentComponent(),
            SizedBox(height: 10),
            CommentComponent(),
            SizedBox(height: 10),
            CommentComponent(),
            SizedBox(height: 10),
            CommentComponent(),
            SizedBox(height: 80),
          ],
        ),
      ),
      bottomSheet: _buildBottomSheet(),
    );
  }

  Widget _buildBottomSheet() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.only(
        top: 10.0,
        bottom: 15.0,
        left: 10.0,
        right: 10.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: wawuColors.buttonSecondary.withAlpha(20),
                borderRadius: BorderRadius.circular(60),
                border: Border.all(color: Colors.transparent, width: 1),
              ),
              padding: EdgeInsets.fromLTRB(15.0, 0.0, 15.0, 0.0),
              child: TextField(
                // controller: _messageController,
                maxLines: 1,
                decoration: InputDecoration(
                  hintText: 'Comment',
                  hintStyle: TextStyle(
                    color: Color.fromARGB(255, 201, 201, 201),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {}, // Disable if empty
            icon: Icon(Icons.send, color: wawuColors.purpleDarkContainer),
          ),
        ],
      ),
    );
  }
}
