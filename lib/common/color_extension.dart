import 'package:flutter/material.dart';

class TColor {
  // Primary - Dark Navy Blue (like Nexo)
  static Color get primary => const Color(0xFF1A2332);
  static Color get primary500 => const Color(0xFF243044);
  static Color get primary20 => const Color(0xFF2E3D56);
  static Color get primary10 => const Color(0xFF384A68);
  static Color get primary5 => const Color(0xFF42577A);
  static Color get primary0 => const Color(0xFF4C648C);

  // Primary Background - Dark Navy
  static const Color primaryBg = Color(0xFF1E2A3A);
  
  // Secondary - Teal/Green (like Nexo accent)
  static Color get secondary => const Color(0xFF00D395);
  static Color get secondary50 => const Color(0xFF33DCAA);
  static Color get secondary0 => const Color(0xFF66E5BF);

  // Green accent colors
  static Color get secondaryG => const Color(0xFF00D395);
  static Color get secondaryG50 => const Color(0xFF4ECCA3);

  // Grays
  static Color get gray => const Color(0xFF0E0E12);
  static Color get gray80 => const Color(0xFF1C1C23);
  static Color get gray70 => const Color(0xFF353542);
  static Color get gray60 => const Color(0xFF4E4E61);
  static Color get gray50 => const Color(0xFF666680);
  static Color get gray40 => const Color(0xFF83839C);
  static Color get gray30 => const Color(0xFFA2A2B5);
  static Color get gray20 => const Color(0xFFC1C1CD);
  static Color get gray10 => const Color(0xFFE0E0E6);

  // Accent colors
  static Color get yellow => const Color(0xFFFFD54F);
  static const Color secondaryYellow = Color(0xFFFFD54F);
  static const Color coinBronze = Color(0xFFCD7F32);

  // Utility colors
  static Color get border => const Color(0xFF2E3D56);
  static Color get primaryText => Colors.white;
  static Color get secondaryText => const Color(0xFF8A94A6);
  static Color get black => const Color(0xFF000000);
  static Color get white => Colors.white;
}
