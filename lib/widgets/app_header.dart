import 'package:flutter/material.dart';

/// The banner from your first photo (logo + Nexus Middle East details),
/// shown at the top of every main screen — this is "Image 1" from your
/// message used as the application header, exactly as you asked.
class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE1E5E7))),
      ),
      child: Image.asset(
        'assets/images/header.jpg',
        height: 46,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
      ),
    );
  }
}
