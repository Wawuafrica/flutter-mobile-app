import 'package:flutter/material.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:wawu_mobile/widgets/custom_textfield/custom_textfield.dart';

class FaqComponent extends StatefulWidget {
  const FaqComponent({super.key});

  @override
  State<FaqComponent> createState() => _FaqComponentState();
}

class _FaqComponentState extends State<FaqComponent> {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();
  List<Map<String, String>> faqs = [
    {
      'Question': 'Why choose us?',
      'Answer': 'Some stuff some stuff, this and that...',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...faqs.map((faq) {
          return Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.0),
            margin: EdgeInsets.only(top: 10.0),
            decoration: BoxDecoration(
              color: wawuColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        faq['Question'].toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        faq['Answer'].toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      faqs.remove(faq);
                    });
                  },
                  child: Icon(Icons.delete, color: Colors.white, size: 18),
                ),
              ],
            ),
          );
        }),

        CustomTextfield(
          hintText: 'Add Question',
          labelTextStyle2: true,
          controller: _questionController,
        ),
        CustomTextfield(
          hintText: 'Add Answer',
          labelTextStyle2: true,
          controller: _answerController,
        ),
        SizedBox(height: 20),
        CustomButton(
          function: _addFaq,
          widget: Text('Add FAQ', style: TextStyle(color: Colors.white)),
          color: wawuColors.primary,
        ),
      ],
    );
  }

  void _addFaq() {
    if (_answerController.text.trim().isNotEmpty &&
        _questionController.text.trim().isNotEmpty) {
      setState(() {
        faqs.add({
          'Question': _questionController.text.trim(),
          'Answer': _answerController.text.trim(),
        });
        _answerController.clear();
        _questionController.clear();
      });
    }
  }
}
