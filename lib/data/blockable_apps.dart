import 'dart:typed_data';

class InstalledApp {
  final String name;
  final String packageName;
  final Uint8List? icon;

  final bool essential;

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

class BlockableApp {
  final String name;
  final List<String> packages;

  const BlockableApp(this.name, this.packages);
}

class BlockableApps {
  BlockableApps._();

  static const List<BlockableApp> all = [
    BlockableApp('Instagram', ['com.instagram.android']),
    BlockableApp(
        // TikTok tiene un paquete distinto según el país
        'TikTok',
        ['com.zhiliaoapp.musically', 'com.ss.android.ugc.trill']),
    BlockableApp('Facebook', ['com.facebook.katana']),
    BlockableApp('X (Twitter)', ['com.twitter.android']),
    BlockableApp('YouTube', ['com.google.android.youtube']),
    BlockableApp('Snapchat', ['com.snapchat.android']),
    BlockableApp('Threads', ['com.instagram.barcelona']),
    BlockableApp('Pinterest', ['com.pinterest']),
    BlockableApp('Reddit', ['com.reddit.frontpage']),
  ];

  static List<String> get defaultSelection => catalogRecommended;

  static const List<String> catalogRecommended = [
    'TikTok',
    'Instagram',
    'Facebook',
    'Snapchat',
  ];

  static final Set<String> recommendedPackages = {
    for (final app in all) ...app.packages
  };

  static List<InstalledApp> get catalogAsInstalled => [
        for (final app in all)
          InstalledApp(
            name: app.name,
            packageName: app.packages.first,
            recommended: catalogRecommended.contains(app.name),
          ),
      ];

  static List<String> packagesFor(Iterable<String> names) => all
      .where((app) => names.contains(app.name))
      .expand((app) => app.packages)
      .toList();

  static String nameForPackage(String package) {
    for (final app in all) {
      if (app.packages.contains(package)) return app.name;
    }
    return 'Esta app';
  }
}
