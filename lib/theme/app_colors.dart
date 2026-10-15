import 'package:flutter/material.dart';

/// Paleta de colores tomada de los diseños (tokens de Stitch / Material 3).
/// Centralizarla aquí evita repetir códigos hexadecimales en cada pantalla.
class AppColors {
  AppColors._();

  // Primarios
  static const Color primary = Color(0xFF3525CD);
  static const Color primaryContainer = Color(0xFF4F46E5);
  static const Color primaryFixed = Color(0xFFE2DFFF);
  static const Color primaryFixedDim = Color(0xFFC3C0FF);

  // Secundarios
  static const Color secondary = Color(0xFF4648D4);
  static const Color secondaryContainer = Color(0xFF6063EE);
  static const Color secondaryFixed = Color(0xFFE1E0FF);
  static const Color onSecondaryFixedVariant = Color(0xFF2F2EBE);

  // Terciarios
  static const Color tertiary = Color(0xFF8F0055);
  static const Color tertiaryContainer = Color(0xFFB6166F);
  static const Color tertiaryFixed = Color(0xFFFFD9E4);

  // Superficies
  static const Color surface = Color(0xFFFCF8FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF6F2FF);
  static const Color surfaceContainer = Color(0xFFEFEBFF);
  static const Color surfaceContainerHigh = Color(0xFFE9E5FF);
  static const Color surfaceVariant = Color(0xFFE3DFFF);

  // Texto y bordes
  static const Color onSurface = Color(0xFF181445);
  static const Color onSurfaceVariant = Color(0xFF464555);
  static const Color outline = Color(0xFF777587);
  static const Color outlineVariant = Color(0xFFC7C4D8);

  // Estados
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color inverseSurface = Color(0xFF2D2A5B);
  static const Color inverseOnSurface = Color(0xFFF3EEFF);

  /// Sombra suave usada en las tarjetas de los diseños.
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0F1E1B4B),
      blurRadius: 12,
      offset: Offset(0, 2),
    ),
  ];
}
