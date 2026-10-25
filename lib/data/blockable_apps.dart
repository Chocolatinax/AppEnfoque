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

  const InstalledApp({
    required this.name,
    required this.packageName,
    this.icon,
    this.essential = false,
  });

  bool get isRecommended => BlockableApps.recommendedPackages.contains(packageName);
}

/// Apps distractoras conocidas, con sus nombres de paquete en Android.
class BlockableApp {
  final String name;
  final List<String> packages; // algunas apps tienen más de un paquete según el país

  const BlockableApp(this.name, this.packages);
}

class BlockableApps {
  BlockableApps._();

  /// Redes sociales y apps de entretenimiento que el atajo "Recomendadas" marca si están instaladas.
  static const List<BlockableApp> all = [
    BlockableApp('Instagram', ['com.instagram.android']),
    BlockableApp('TikTok', ['com.zhiliaoapp.musically', 'com.ss.android.ugc.trill']),
    BlockableApp('YouTube', ['com.google.android.youtube']),
    BlockableApp('X (Twitter)', ['com.twitter.android']),
    BlockableApp('Facebook', ['com.facebook.katana']),
    BlockableApp('Snapchat', ['com.snapchat.android']),
    BlockableApp('Netflix', ['com.netflix.mediaclient']),
    BlockableApp('Reddit', ['com.reddit.frontpage']),
    BlockableApp('Pinterest', ['com.pinterest']),
    BlockableApp('Twitch', ['tv.twitch.android.app']),
    BlockableApp('Discord', ['com.discord']),
    BlockableApp('Threads', ['com.instagram.barcelona']),
  ];

  /// Selección por defecto cuando no se puede leer la lista del teléfono (iOS / pruebas).
  static const List<String> defaultSelection = ['Instagram', 'TikTok', 'YouTube'];

  static final Set<String> recommendedPackages = {for (final app in all) ...app.packages};

  /// Catálogo como lista de apps (se usa fuera de Android).
  static List<InstalledApp> get catalogAsInstalled => [
        for (final app in all) InstalledApp(name: app.name, packageName: app.packages.first),
      ];

  /// Paquetes de Android para una lista de nombres del catálogo
  /// (compatibilidad con tareas creadas antes de guardar los paquetes).
  static List<String> packagesFor(Iterable<String> names) =>
      all.where((app) => names.contains(app.name)).expand((app) => app.packages).toList();

  /// Nombre visible a partir de un paquete del catálogo.
  static String nameForPackage(String package) {
    for (final app in all) {
      if (app.packages.contains(package)) return app.name;
    }
    return 'Esta app';
  }
}
