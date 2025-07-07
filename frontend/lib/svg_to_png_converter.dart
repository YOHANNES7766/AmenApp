import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Note: This is a simple Flutter app to help you convert the SVG to PNG.
// Run this app, then take a screenshot of the SVG when it's displayed on screen.
// Then use the screenshot as your app icon.

void main() {
  runApp(const SvgRendererApp());
}

class SvgRendererApp extends StatelessWidget {
  const SvgRendererApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SizedBox(
            width: 512,
            height: 512,
            child: SvgPicture.asset(
              'assets/icons/new_icon/bible_study_circle.svg',
            ),
          ),
        ),
      ),
    );
  }
}
