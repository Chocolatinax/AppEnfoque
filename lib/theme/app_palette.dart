import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Paleta "Salvia Floria" como extensión del tema, con versión clara y oscura.
///
/// Uso en las pantallas:
/// ```dart
/// final p = context.palette;
/// Container(color: p.surfaceContainerLowest, child: Text('Hola', style: TextStyle(color: p.onSurface)));
/// ```
/// Los nombres son los mismos que en [AppColors], así migrar una pantalla
/// es cambiar `AppColors.x` por `p.x` (y quitar los `const` que dependan de ellos).
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color primary;
  final Color onPrimary;
  final Color primaryFixed;
  final Color onPrimaryFixed;
  final Color secondary;
  final Color secondaryContainer;
  final Color secondaryFixed;
  final Color onSecondaryFixedVariant;
  final Color tertiary;
  final Color onTertiary;
  final Color tertiaryContainer;
  final Color tertiaryFixed;
  final Color onTertiaryFixed;
  final Color surface;
  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color error;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color inverseSurface;
  final Color inverseOnSurface;
  final List<BoxShadow> cardShadow;

  const AppPalette({
    required this.primary,
    required this.onPrimary,
    required this.primaryFixed,
    required this.onPrimaryFixed,
    required this.secondary,
    required this.secondaryContainer,
    required this.secondaryFixed,
    required this.onSecondaryFixedVariant,
    required this.tertiary,
    required this.onTertiary,
    required this.tertiaryContainer,
    required this.tertiaryFixed,
    required this.onTertiaryFixed,
    required this.surface,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.error,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.inverseSurface,
    required this.inverseOnSurface,
    required this.cardShadow,
  });

  /// Modo claro: crema cálido + verde salvia.
  static const AppPalette light = AppPalette(
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryFixed: AppColors.primaryFixed,
    onPrimaryFixed: AppColors.onPrimaryFixed,
    secondary: AppColors.secondary,
    secondaryContainer: AppColors.secondaryContainer,
    secondaryFixed: AppColors.secondaryFixed,
    onSecondaryFixedVariant: AppColors.onSecondaryFixedVariant,
    tertiary: AppColors.tertiary,
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: AppColors.tertiaryContainer,
    tertiaryFixed: AppColors.tertiaryFixed,
    onTertiaryFixed: AppColors.onTertiaryFixed,
    surface: AppColors.surface,
    surfaceContainerLowest: AppColors.surfaceContainerLowest,
    surfaceContainerLow: AppColors.surfaceContainerLow,
    surfaceContainer: AppColors.surfaceContainer,
    surfaceContainerHigh: AppColors.surfaceContainerHigh,
    onSurface: AppColors.onSurface,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    error: AppColors.error,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onErrorContainer,
    inverseSurface: AppColors.inverseSurface,
    inverseOnSurface: AppColors.inverseOnSurface,
    cardShadow: AppColors.cardShadow,
  );

  /// Modo oscuro: verde bosque casi negro + salvia claro.
  /// Contrastes verificados: texto 13.5:1, secundario 8.7:1, primario 9.0:1 sobre tarjetas.
  static const AppPalette dark = AppPalette(
    primary: Color(0xFF8FCBA8),
    onPrimary: Color(0xFF0E2A1B),
    primaryFixed: Color(0xFF24412F),
    onPrimaryFixed: Color(0xFFCDE8D6),
    secondary: Color(0xFFA6C9B2),
    secondaryContainer: Color(0xFF4F7A63),
    secondaryFixed: Color(0xFF24332A),
    onSecondaryFixedVariant: Color(0xFFCDE8D6),
    tertiary: Color(0xFFF0A27A),
    onTertiary: Color(0xFF3A1A08),
    tertiaryContainer: Color(0xFFC8693A),
    tertiaryFixed: Color(0xFF4A2A18),
    onTertiaryFixed: Color(0xFFFFD9C4),
    surface: Color(0xFF121614),
    surfaceContainerLowest: Color(0xFF1A1F1C),
    surfaceContainerLow: Color(0xFF161B18),
    surfaceContainer: Color(0xFF222925),
    surfaceContainerHigh: Color(0xFF2B332E),
    onSurface: Color(0xFFE4E8E3),
    onSurfaceVariant: Color(0xFFB4BEB7),
    outline: Color(0xFF8C968F),
    outlineVariant: Color(0xFF3D4641),
    error: Color(0xFFF2B8B5),
    errorContainer: Color(0xFF5C1A16),
    onErrorContainer: Color(0xFFF9DEDC),
    inverseSurface: Color(0xFFE4E8E3),
    inverseOnSurface: Color(0xFF1C2620),
    cardShadow: [],
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    // Cambio directo entre claro y oscuro (sin interpolar cada color).
    if (other is! AppPalette) return this;
    return t < 0.5 ? this : other;
  }
}

/// Acceso corto: `context.palette.primary`
extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
