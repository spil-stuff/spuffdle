import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryBackgroundColor = Color.fromARGB(255,18,18,19);
  static const Color secondaryBackgroundColor = Color.fromARGB(255, 30, 30, 30);
  static const Color highlightColor = Color.fromARGB(255, 2, 151, 209);
  static const Color secondaryHighlightColor = Color.fromARGB(255, 101, 177, 201);
  static const Color primaryColor = Colors.white;
  static const Color secondaryColor = Colors.grey;
  static const Color tertiaryColor = Color.fromARGB(255, 75, 75, 75);
  static const Color green = Color.fromARGB(255,83,141,78);
  static const Color yellow = Color.fromARGB(255, 141, 141, 78);
  static const Color red = Color.fromARGB(255, 141, 78, 78);
}

class AppStyles {
  static const TextStyle whiteText = TextStyle(fontSize: 17, color: AppColors.primaryColor);
  static const TextStyle greyText = TextStyle(fontSize: 16, color: AppColors.secondaryColor, fontWeight: FontWeight.normal);
}