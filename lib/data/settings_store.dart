import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import 'app_database.dart';

class SettingsStore {
  static const analyticsConsent = 'analytics_consent';

  final AppDatabase _database;

  SettingsStore(this._database);

  Future<String?> get(String key) async {
    final rows = await _database.db
        .query('settings', where: 'key = ?', whereArgs: [key], limit: 1);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> set(String key, String value) => _database.db.insert(
        'settings',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  /// null = todavía no se le ha preguntado.
  Future<bool?> analyticsAllowed() async {
    final v = await get(analyticsConsent);
    return v == null ? null : v == 'yes';
  }

  Future<void> setAnalyticsAllowed(bool allowed) =>
      set(analyticsConsent, allowed ? 'yes' : 'no');
}
