import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/session_clock.dart';
import '../models/task_model.dart';

/// Un aviso programado de la sesión.
class PlannedNotification {
  final DateTime at;
  final String title;
  final String body;

  const PlannedNotification(this.at, this.title, this.body);
}

/// Notificaciones locales de Floria (sin servidor: todo ocurre en el teléfono).
///
/// - Al iniciar una sesión: "Sesión de enfoque en curso" (fija en Android).
/// - Mientras la app está cerrada o en segundo plano: avisos al terminar cada
///   ronda, cada descanso, la pausa de emergencia y la sesión completa.
/// - Al terminar o abandonar: se borran todas.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const int _ongoingId = 1;
  static const int _firstScheduledId = 100;

  bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> init() async {
    if (!isSupported || _ready) return;
    try {
      tzdata.initializeTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          // El permiso se pide al iniciar la primera sesión, no al abrir la app
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('[Notificaciones] No se pudieron iniciar: $e');
    }
  }

  /// Pide el permiso de notificaciones (Android 13+ e iOS). Devuelve si quedó activado.
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      if (Platform.isAndroid) {
        return await _plugin
                .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
                ?.requestNotificationsPermission() ??
            false;
      }
      return await _plugin
              .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, sound: true) ??
          false;
    } catch (_) {
      return false;
    }
  }

  // ---------- Notificaciones de la sesión ----------

  /// "Sesión de enfoque en curso · Termina a las HH:MM".
  /// En Android queda fija; con [update] solo se actualiza la hora (sin sonar de nuevo).
  Future<void> showSessionInProgress(Task task, DateTime endsAt, {bool update = false}) async {
    if (!_ready) return;
    if (update && Platform.isIOS) return; // en iOS no hay notificaciones fijas
    try {
      await _plugin.show(
        id: _ongoingId,
        title: 'Sesión de enfoque en curso',
        body: '${task.title} · Termina a las ${_hhmm(endsAt)}',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'sesion_en_curso',
            'Sesión en curso',
            channelDescription: 'Muestra que tienes una sesión de enfoque activa',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
            onlyAlertOnce: true,
          ),
          iOS: DarwinNotificationDetails(presentSound: false),
        ),
      );
    } catch (e) {
      debugPrint('[Notificaciones] showSessionInProgress falló: $e');
    }
  }

  /// Programa los avisos que faltan de la sesión (se llama al salir de la app).
  Future<void> scheduleSessionEvents(SessionClock clock, Task task) async {
    if (!_ready) return;
    await cancelScheduled();
    final events = planSessionEvents(clock, task, DateTime.now());
    if (events.isEmpty) return;

    var mode = AndroidScheduleMode.inexactAllowWhileIdle;
    try {
      final exact = await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.canScheduleExactNotifications();
      if (exact == true) mode = AndroidScheduleMode.exactAllowWhileIdle;
    } catch (_) {}

    for (var i = 0; i < events.length; i++) {
      final e = events[i];
      try {
        await _plugin.zonedSchedule(
          id: _firstScheduledId + i,
          scheduledDate: tz.TZDateTime.from(e.at, tz.UTC),
          title: e.title,
          body: e.body,
          androidScheduleMode: mode,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'avisos_sesion',
              'Avisos de la sesión',
              channelDescription: 'Fin de las rondas, de los descansos y de la sesión',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
        );
      } catch (err) {
        debugPrint('[Notificaciones] No se pudo programar "${e.title}": $err');
      }
    }
  }

  /// Cancela los avisos programados (se llama al volver a la app).
  Future<void> cancelScheduled() async {
    if (!_ready) return;
    try {
      await _plugin.cancelAllPendingNotifications();
    } catch (_) {}
  }

  /// Borra todo: la notificación fija y los avisos (al terminar o abandonar).
  Future<void> cancelAll() async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  // ---------- Cálculo de los avisos (función pura, con pruebas) ----------

  /// Qué avisos faltan y a qué hora, según el reloj de la sesión.
  static List<PlannedNotification> planSessionEvents(SessionClock clock, Task task, DateTime now) {
    final position = clock.position(now);
    if (position.finished) return const [];

    final phases = clock.phases;
    final events = <PlannedNotification>[];
    // Si está en pausa, todo se corre lo que falte de la pausa
    var time = now.add(Duration(seconds: clock.pauseSecondsLeft(now)));
    if (clock.isPaused(now)) {
      events.add(PlannedNotification(time, 'Tu pausa terminó', 'De vuelta al enfoque: ${task.title}'));
    }

    for (var i = position.index; i < phases.length; i++) {
      final phase = phases[i];
      time = time.add(Duration(seconds: i == position.index ? position.secondsLeft : phase.seconds));
      final isLast = i == phases.length - 1;
      if (isLast) {
        events.add(PlannedNotification(time, '¡Sesión completada!', 'Abre Floria y cuéntanos si cumpliste tu objetivo.'));
      } else if (phase.isFocus) {
        events.add(PlannedNotification(
          time,
          '¡Ronda ${phase.round} completada!',
          'Toma un descanso de ${phases[i + 1].minutes} min.',
        ));
      } else {
        events.add(PlannedNotification(
          time,
          'Descanso terminado',
          'Vuelve a enfocarte: ronda ${phases[i + 1].round}.',
        ));
      }
    }
    return events;
  }

  static String _hhmm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
