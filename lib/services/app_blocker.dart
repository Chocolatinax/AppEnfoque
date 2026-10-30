import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../data/blockable_apps.dart';

class BlockedAppEvent {
  final String packageName;
  final DateTime detectedAt;

  const BlockedAppEvent(this.packageName, this.detectedAt);

  bool isFresh({required DateTime now, required DateTime sessionStart}) {
    final age = now.difference(detectedAt);
    return age <= maxPendingAge && !detectedAt.isBefore(sessionStart);
  }

  static const Duration maxPendingAge = Duration(seconds: 10);
}

// Puente con el código Kotlin (canal floria/app_blocker). En iOS no hace nada.
class AppBlocker {
  AppBlocker._() {
    if (isSupported) _channel.setMethodCallHandler(_onNativeCall);
  }

  static final AppBlocker instance = AppBlocker._();

  static const MethodChannel _channel = MethodChannel('floria/app_blocker');

  final StreamController<BlockedAppEvent> _events =
      StreamController<BlockedAppEvent>.broadcast();

  Stream<BlockedAppEvent> get blockedAppOpened => _events.stream;

  bool get isSupported => !kIsWeb && Platform.isAndroid;

  Future<bool> isEnabled() async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('isServiceEnabled') ?? false;
    } catch (_) {
      return false;
    }
  }

  List<InstalledApp>? _cachedApps;

  Future<List<InstalledApp>> getLaunchableApps({bool refresh = false}) async {
    if (!isSupported) return BlockableApps.catalogAsInstalled;
    if (_cachedApps != null && !refresh) return _cachedApps!;
    try {
      final raw = await _channel
              .invokeListMethod<Map<Object?, Object?>>('getLaunchableApps') ??
          [];
      _cachedApps = [
        for (final item in raw)
          InstalledApp(
            name: item['name'] as String,
            packageName: item['package'] as String,
            icon: item['icon'] as Uint8List?,
            essential: item['essential'] as bool? ?? false,
          ),
      ];
      return _cachedApps!;
    } catch (e) {
      debugPrint('[AppBlocker] getLaunchableApps falló: $e');
      return BlockableApps.catalogAsInstalled;
    }
  }

  Future<void> openSettings() => _call('openAccessibilitySettings');

  Future<void> start(List<String> packages,
          {required List<(DateTime, DateTime)> windows}) =>
      _call('startBlocking', {
        'packages': packages,
        'windows': [
          for (final (start, end) in windows) ...[
            start.millisecondsSinceEpoch,
            end.millisecondsSinceEpoch,
          ],
        ],
      });

  Future<BlockedAppEvent?> consumePendingBlockedApp() async {
    if (!isSupported) return null;
    try {
      final raw = await _channel
          .invokeMapMethod<String, Object?>('consumePendingBlockedApp');
      if (raw == null) return null;
      return BlockedAppEvent(
        raw['package'] as String,
        DateTime.fromMillisecondsSinceEpoch(raw['detectedAt'] as int),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> stop() => _call('stopBlocking');

  Future<void> _call(String method, [Map<String, Object?>? args]) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>(method, args);
    } catch (e) {
      debugPrint('[AppBlocker] $method falló: $e');
    }
  }

  Future<void> _onNativeCall(MethodCall call) async {
    if (call.method != 'blockedAppOpened') return;
    final args = Map<String, Object?>.from(call.arguments as Map);
    _events.add(BlockedAppEvent(
      args['package'] as String,
      DateTime.fromMillisecondsSinceEpoch(args['detectedAt'] as int),
    ));
  }
}
