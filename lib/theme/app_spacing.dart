/// Medidas compartidas para mantener un diseño consistente y con aire.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Margen lateral de las pantallas.
  static const double screen = 20;

  /// Área táctil mínima recomendada (Material / WCAG): 48 x 48 dp.
  static const double minTouchTarget = 48;
}

class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double sheet = 24;
  static const double pill = 999;
}
