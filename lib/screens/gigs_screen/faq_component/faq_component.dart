import 'package:flutter/material.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_button/custom_button.dart';
import 'package:wawu_mobile/widgets/custom_textfield/custom_textfield.dart';

class FaqComponent extends StatefulWidget {
  final ValueChanged<List<Map<String, dynamic>>> onFaqsChanged;

  const FaqComponent({super.key, required this.onFaqsChanged});

  @override
  State<FaqComponent> createState() => _FaqComponentState();
}

class _FaqComponentState extends State<FaqComponent> {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();
  final List<Map<String, dynamic>> _faqs = [];

  @override
  void initState() {
    super.initState();
    widget.onFaqsChanged(List<Map<String, dynamic>>.from(_faqs));
  }

  void _addFaq() {
    if (_answerController.text.trim().isNotEmpty && _questionController.text.trim().isNotEmpty) {
      setState(() {
        _faqs.add({
          'Question': _questionController.text.trim(),
          'Answer': _answerController.text.trim(),
        });
        _answerController.clear();
        _questionController.clear();
        widget.onFaqsChanged(List<Map<String, dynamic>>.from(_faqs));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ..._faqs.asMap().entries.map((entry) {
          final faq = entry.value;
          return Container(
            key: UniqueKey(), // Ensure unique key
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            margin: const EdgeInsets.only(top: 10.0),
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
                        faq['Question']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        faq['Answer']!,
                        style: const TextStyle(
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
                      _faqs.removeAt(entry.key);
                      widget.onFaqsChanged(List<Map<String, dynamic>>.from(_faqs));
                    });
                  },
                  child: const Icon(Icons.delete, color: Colors.white, size: 18),
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
        const SizedBox(height: 20),
        CustomButton(
          function: _addFaq,
          widget: const Text('Add FAQ', style: TextStyle(color: Colors.white)),
          color: wawuColors.primary,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }
}