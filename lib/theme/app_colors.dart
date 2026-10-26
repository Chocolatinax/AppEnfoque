import 'package:flutter/material.dart';

/// Paleta "Salvia Floria" — versión CLARA, como constantes.
///
/// Todos los pares de texto/fondo pasan WCAG AA (4.5:1).
///
/// IMPORTANTE: estas constantes NO cambian con el modo oscuro. En código nuevo usa
/// `context.palette.<color>` (ver app_palette.dart), que sí se adapta al tema.
/// Estas constantes se mantienen mientras se migran las pantallas existentes.
class AppColors {
  AppColors._();

  // Primario (verde salvia profundo): acciones, temporizador, progreso
  static const Color primary = Color(0xFF2F6B4F);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF2F6B4F);
  static const Color primaryFixed = Color(0xFFDCEBE0); // fondos suaves / chips
  static const Color onPrimaryFixed = Color(0xFF1F4A35);
  static const Color primaryFixedDim = Color(0xFFB5D3BF);

  // Secundario (verde medio): íconos de apoyo, gráficas
  static const Color secondary = Color(0xFF46705A);
  static const Color secondaryContainer = Color(0xFF8DB39A); // solo decoración
  static const Color secondaryFixed = Color(0xFFE6EFE8);
  static const Color onSecondaryFixedVariant = Color(0xFF1F4A35);

  // Terciario = alerta (terracota): bloqueo, prioridad alta, abandonar
  static const Color tertiary = Color(0xFF9A4A24);
  static const Color tertiaryContainer = Color(0xFFC8693A); // solo decoración
  static const Color tertiaryFixed = Color(0xFFF7DFD0);
  static const Color onTertiaryFixed = Color(0xFF7A3A18);

  // Superficies (crema cálido)
  static const Color surface = Color(0xFFF7F5EF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F1EA);
  static const Color surfaceContainer = Color(0xFFEBEAE1);
  static const Color surfaceContainerHigh = Color(0xFFE3E2D8);
  static const Color surfaceVariant = Color(0xFFE3E2D8);

  // Texto y bordes
  static const Color onSurface = Color(0xFF1C2620);
  static const Color onSurfaceVariant = Color(0xFF4E5953);
  static const Color outline = Color(0xFF737D77);
  static const Color outlineVariant = Color(0xFFC5CBC4);

  // Estados
  static const Color error = Color(0xFFB3261E);
  static const Color errorContainer = Color(0xFFF9DEDC);
  static const Color onErrorContainer = Color(0xFF8C1D18);
  static const Color inverseSurface = Color(0xFF2B332E);
  static const Color inverseOnSurface = Color(0xFFEEF1EC);

  /// Sombra muy suave para tarjetas (en modo oscuro no se usa sombra).
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0D1C2620),
      blurRadius: 12,
      offset: Offset(0, 2),
    ),
  ];
}
