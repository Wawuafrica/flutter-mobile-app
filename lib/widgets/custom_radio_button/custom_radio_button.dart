// import 'package:flutter/material.dart';

// class CustomRadioButton extends StatelessWidget {
//   final String label;
//   final bool isSelected;
//   final Function() onTap;

//   const CustomRadioButton({
//     super.key,
//     required this.label,
//     required this.isSelected,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Row(
//         children: [
//           Container(
//             width: 20,
//             height: 20,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               border: Border.all(
//                 color: isSelected ? wawuColors.primary : Colors.grey,
//                 width: 2,
//               ),
//             ),
//             child: Center(
//               child:
//                   isSelected
//                       ? Container(
//                         width: 10,
//                         height: 10,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: Colors.blue,
//                         ),
//                       )
//                       : null,
//             ),
//           ),
//           SizedBox(width: 10),
//           Text(
//             label,
//             style: TextStyle(
//               color: isSelected ? Colors.blue : Colors.black,
//               fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
