import 'package:flutter/material.dart';
import 'package:wawu_mobile/utils/theme/custom_themes/checkbox_theme.dart';
import 'package:wawu_mobile/utils/theme/custom_themes/outlined_button_theme.dart';
import 'package:wawu_mobile/utils/theme/custom_themes/text_field_theme.dart';
import 'package:wawu_mobile/utils/theme/custom_themes/text_theme.dart';

import 'custom_themes/elevated_button_theme.dart';
import 'custom_themes/appbar_theme.dart';
class wawuTheme{
  wawuTheme._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    brightness: Brightness.light,
    primaryColor: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    textTheme: wawuTextTheme.lightTextTheme,
    appBarTheme: wawuAppBarTheme.lightAppBarTheme,
    checkboxTheme: wawuCheckBoxTheme.lightCheckBoxTheme,
    elevatedButtonTheme: wawuElevatedButtonTheme.lightElevatedButtonTheme,
    outlinedButtonTheme: wawuOutlinedButtonTheme.lightOutlinedButtonTheme,
    inputDecorationTheme: wawuTextFieldTheme.lightInputDecorationTheme,
  );
}