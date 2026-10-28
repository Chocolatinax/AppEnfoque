import 'dart:typed_data';

/// Una app que se puede bloquear.
///
/// En Android viene de la lista de apps instaladas (con su ícono).
/// En iOS y en las pruebas se usa el catálogo de abajo (sin ícono).
class InstalledApp {
  final String name;
  final String packageName;
  final Uint8List? icon;

  /// Apps esenciales (teléfono, mensajes, ajustes, reloj): el atajo "Todas" no las marca.
  final bool essential;

  /// Si es null, se decide por el catálogo de redes sociales (Android).
  /// En iOS se indica a mano: ahí "Recomendadas" son solo 4 de las 9.
  final bool? recommended;

  const InstalledApp({
    required this.name,
    required this.packageName,
    this.icon,
    this.essential = false,
    this.recommended,
  });

  bool get isRecommended =>
      recommended ?? BlockableApps.recommendedPackages.contains(packageName);
}

/// Apps distractoras conocidas, con sus nombres de paquete en Android.
class BlockableApp {
  final String name;
  final List<String>
      packages; // algunas apps tienen más de un paquete según el país

  const BlockableApp(this.name, this.packages);
}

class BlockableApps {
  BlockableApps._();

  /// Redes sociales que distraen. En Android son las "Recomendadas" (las que estén
  /// instaladas); en iOS son la lista completa ("Todas") y las recomendadas son
  /// [catalogRecommended]. Cualquier otra app se puede elegir a mano en Android.
  static const List<BlockableApp> all = [
    BlockableApp('Instagram', ['com.instagram.android']),
    BlockableApp(
        'TikTok', ['com.zhiliaoapp.musically', 'com.ss.android.ugc.trill']),
    BlockableApp('Facebook', ['com.facebook.katana']),
    BlockableApp('X (Twitter)', ['com.twitter.android']),
    BlockableApp('YouTube', ['com.google.android.youtube']),
    BlockableApp('Snapchat', ['com.snapchat.android']),
    BlockableApp('Threads', ['com.instagram.barcelona']),
    BlockableApp('Pinterest', ['com.pinterest']),
    BlockableApp('Reddit', ['com.reddit.frontpage']),
  ];

  /// Selección por defecto cuando no se puede leer la lista del teléfono (iOS / pruebas):
  /// todas las redes sociales.
  static List<String> get defaultSelection => catalogRecommended;

  /// "Recomendadas" fuera de Android (iOS): las 4 redes sociales que más distraen.
  /// "Todas" sigue marcando las 9 del catálogo.
  static const List<String> catalogRecommended = [
    'TikTok',
    'Instagram',
    'Facebook',
    'Snapchat',
  ];

  static final Set<String> recommendedPackages = {
    for (final app in all) ...app.packages
  };

  /// Catálogo como lista de apps (se usa fuera de Android).
  static List<InstalledApp> get catalogAsInstalled => [
        for (final app in all)
          InstalledApp(
            name: app.name,
            packageName: app.packages.first,
            recommended: catalogRecommended.contains(app.name),
          ),
      ];

  /// Paquetes de Android para una lista de nombres del catálogo
  /// (compatibilidad con tareas creadas antes de guardar los paquetes).
  static List<String> packagesFor(Iterable<String> names) => all
      .where((app) => names.contains(app.name))
      .expand((app) => app.packages)
      .toList();

  /// Nombre visible a partir de un paquete del catálogo.
  static String nameForPackage(String package) {
    for (final app in all) {
      if (app.packages.contains(package)) return app.name;
    }
    return 'Esta app';
  }
}
