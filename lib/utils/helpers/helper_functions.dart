import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class wawuHelperFunctions{
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }
}