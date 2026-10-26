import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../data/blockable_apps.dart';

/// Aviso del código nativo: el usuario abrió una app bloqueada.
class BlockedAppEvent {
  final String packageName;
  final DateTime detectedAt;

  const BlockedAppEvent(this.packageName, this.detectedAt);
}

/// Puente entre Flutter y el bloqueo nativo de Android (Kotlin).
///
/// Usa el platform channel "floria/app_blocker" (ver MainActivity.kt).
/// En iOS (y en las pruebas) no hace nada: el bloqueo solo existe en Android,
/// que es la plataforma definida en el alcance del proyecto.
class AppBlocker {
  AppBlocker._() {
    if (isSupported) _channel.setMethodCallHandler(_onNativeCall);
  }

  static final AppBlocker instance = AppBlocker._();

  static const MethodChannel _channel = MethodChannel('floria/app_blocker');

  final StreamController<BlockedAppEvent> _events = StreamController<BlockedAppEvent>.broadcast();

  /// Se emite cada vez que el usuario intenta abrir una app bloqueada.
  Stream<BlockedAppEvent> get blockedAppOpened => _events.stream;

  /// El bloqueo solo funciona en Android.
  bool get isSupported => !kIsWeb && Platform.isAndroid;

  /// ¿El usuario activó el Servicio de Accesibilidad de Floria?
  Future<bool> isEnabled() async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('isServiceEnabled') ?? false;
    } catch (_) {
      return false;
    }
  }

  List<InstalledApp>? _cachedApps;

  /// Apps instaladas que se pueden bloquear, ordenadas por nombre.
  /// Fuera de Android devuelve el catálogo de apps conocidas.
  Future<List<InstalledApp>> getLaunchableApps({bool refresh = false}) async {
    if (!isSupported) return BlockableApps.catalogAsInstalled;
    if (_cachedApps != null && !refresh) return _cachedApps!;
    try {
      final raw = await _channel.invokeListMethod<Map<Object?, Object?>>('getLaunchableApps') ?? [];
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

  /// Abre los ajustes de Accesibilidad de Android.
  Future<void> openSettings() => _call('openAccessibilitySettings');

  /// Empieza a bloquear los [packages] hasta [until] (fin del bloque de enfoque).
  /// Si Floria se cierra y no se vuelve a abrir, el bloqueo se libera solo a esa hora.
  Future<void> start(List<String> packages, {required DateTime until}) =>
      _call('startBlocking', {'packages': packages, 'until': until.millisecondsSinceEpoch});

  /// Aviso de app bloqueada que llegó mientras Floria estaba cerrada (o null).
  Future<BlockedAppEvent?> consumePendingBlockedApp() async {
    if (!isSupported) return null;
    try {
      final raw = await _channel.invokeMapMethod<String, Object?>('consumePendingBlockedApp');
      if (raw == null) return null;
      return BlockedAppEvent(
        raw['package'] as String,
        DateTime.fromMillisecondsSinceEpoch(raw['detectedAt'] as int),
      );
    } catch (_) {
      return null;
    }
  }

  /// Deja de bloquear (descanso, pausa de emergencia o fin de la sesión).
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
