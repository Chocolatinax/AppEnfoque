import 'package:firebase_analytics/firebase_analytics.dart';
import 'analytics_service.dart';

class FirebaseAnalyticsService implements AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  bool _enabled;

  FirebaseAnalyticsService({required bool enabled}) : _enabled = enabled;

  @override
  bool get enabled => _enabled;

  @override
  Future<void> setEnabled(bool value) async {
    _enabled = value;
    await _analytics.setAnalyticsCollectionEnabled(value);
  }

  @override
  Future<void> log(String name,
      [Map<String, Object> parameters = const {}]) async {
    if (!_enabled) return;
    await _analytics.logEvent(name: name, parameters: parameters);
  }
}
