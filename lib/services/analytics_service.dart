abstract class AnalyticsService {
  bool get enabled;
  Future<void> setEnabled(bool value);
  Future<void> log(String name, [Map<String, Object> parameters = const {}]);
}

class NoopAnalytics implements AnalyticsService {
  @override
  bool get enabled => false;

  @override
  Future<void> setEnabled(bool value) async {}

  @override
  Future<void> log(String name,
      [Map<String, Object> parameters = const {}]) async {}
}

/// Acceso global, igual que NotificationService. En las pruebas queda el Noop.
class Analytics {
  Analytics._();

  static AnalyticsService instance = NoopAnalytics();

  static void log(String name, [Map<String, Object> parameters = const {}]) {
    instance.log(name, parameters).catchError((_) {});
  }
}
