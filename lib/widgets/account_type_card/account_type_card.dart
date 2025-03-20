import 'package:flutter/material.dart';

class AccountTypeCard extends StatelessWidget {
  final Color cardColor;
  final String text;
  final Color textColor;
  final String desc;
  final bool borderBlack;
  final GestureTapCallback navigate;

  const AccountTypeCard({
    super.key,
    required this.cardColor,
    required this.text,
    required this.desc,
    required this.textColor,
    this.borderBlack = false,
    required this.navigate,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: navigate,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.0),
        height: 200,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(10),
          border:
              borderBlack
                  ? Border.all(color: const Color.fromARGB(255, 213, 213, 213))
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
    );
  }
}
