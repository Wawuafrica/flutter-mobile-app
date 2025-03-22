import 'package:flutter/material.dart';
import 'package:wawu_mobile/screens/wawu/wawu.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wawu Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.soraTextTheme(Theme.of(context).textTheme),
        primaryTextTheme: GoogleFonts.soraTextTheme(
          Theme.of(context).primaryTextTheme,
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Wawu(),
    );
  }
}
