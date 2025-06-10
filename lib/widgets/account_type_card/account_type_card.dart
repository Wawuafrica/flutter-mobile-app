import 'package:flutter/material.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';

class AccountTypeCard extends StatelessWidget {
  final Color cardColor;
  final String text;
  final Color textColor;
  final String desc;
  final bool borderBlack;
  final GestureTapCallback navigate;
  final bool selected;

  const AccountTypeCard({
    super.key,
    required this.cardColor,
    required this.text,
    required this.desc,
    required this.textColor,
    this.borderBlack = false,
    required this.navigate,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: navigate,
      child: Container(
        padding: EdgeInsets.all(5.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border:
              selected
                  ? Border.all(color: wawuColors.primary, width: 2.0)
                  : null,
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.0),
          height: 220,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(10),
            border:
                borderBlack
                    ? Border.all(
                      color: const Color.fromARGB(255, 213, 213, 213),
                    )
                    : Border.all(color: cardColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward, color: textColor),
                ],
              ),
              SizedBox(height: 20),
              Text(desc, softWrap: true, style: TextStyle(color: textColor)),
            ],
          ),
        ),
      ),
    );
  }
}
