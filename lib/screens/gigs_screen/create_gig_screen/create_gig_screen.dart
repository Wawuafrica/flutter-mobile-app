import 'package:flutter/material.dart';
import 'package:wawu_mobile/screens/gigs_screen/faq_component/faq_component.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_intro_text/custom_intro_text.dart';
import 'package:wawu_mobile/widgets/custom_textfield/custom_textfield.dart';
import 'package:wawu_mobile/widgets/package_grid_component/package_grid_component.dart';
import 'package:wawu_mobile/widgets/upload_image/upload_image.dart';

class CreateGigScreen extends StatelessWidget {
  const CreateGigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create A New Gig')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 10),
              CustomIntroText(text: 'Title & Details'),
              SizedBox(height: 10),
              CustomTextfield(labelText: 'Title'),
              CustomTextfield(
                hintText: 'Description',
                labelTextStyle2: true,
                maxLines: true,
              ),
              SizedBox(height: 20),
              CustomTextfield(labelText: 'Keywords'),
              CustomTextfield(
                hintText: 'About this gig',
                labelTextStyle2: true,
                maxLines: true,
              ),
              SizedBox(height: 40),
              CustomIntroText(text: 'Assets'),
              SizedBox(height: 20),
              Text('Add at Least 3 Photos'),
              SizedBox(height: 20),
              // UploadImage(),
              SizedBox(height: 20),
              Text('Upload a video'),
              SizedBox(height: 20),
              // UploadImage(),
              SizedBox(height: 20),
              Text('Upload a PDF'),
              SizedBox(height: 20),
              // UploadImage(),
              SizedBox(height: 40),
              CustomIntroText(text: 'Packages'),
              SizedBox(height: 20),
              PackageGridComponent(),
              SizedBox(height: 40),
              CustomIntroText(text: 'FAQ'),
              SizedBox(height: 10),
              //FAQ SECTION
              FaqComponent(),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: wawuColors.purpleDarkContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.done, color: Colors.white, size: 20),
      ),
    );
  }
}
