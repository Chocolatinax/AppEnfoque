import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/app_database.dart';
import 'data/session_repository.dart';
import 'models/session_clock.dart';
import 'data/task_repository.dart';
import 'screens/main_shell.dart';
import 'services/notification_service.dart';
import 'screens/welcome_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  // Notificaciones locales (inicio, descansos y fin de las sesiones)
  await NotificationService.instance.init();

  // Abre la base de datos local (SQLite) y carga las tareas guardadas
  final database = await AppDatabase.open();
  final taskRepository = TaskRepository(database);
  final sessionRepository = SessionRepository(database);
  await Future.wait([taskRepository.load(), sessionRepository.load()]);

  // ¿Quedó una sesión en curso cuando se cerró la app? (R5)
  ActiveSessionRecord? activeSession = await sessionRepository.loadActive();
  if (activeSession != null &&
      taskRepository.tasks.every((t) => t.id != activeSession!.taskId)) {
    await sessionRepository.clearActive(); // su tarea ya no existe
    activeSession = null;
  }

  runApp(FloriaApp(
    taskRepository: taskRepository,
    sessionRepository: sessionRepository,
    activeSession: activeSession,
  ));
}

/// Todas las pantallas usan la paleta adaptable (context.palette), así que la app
/// sigue el modo claro/oscuro del sistema. Con `false` se fuerza el modo claro.
const bool kDarkModeReady = true;

class FloriaApp extends StatelessWidget {
  final TaskRepository taskRepository;
  final SessionRepository sessionRepository;
  final ActiveSessionRecord? activeSession;

  const FloriaApp({
    super.key,
    required this.taskRepository,
    required this.sessionRepository,
    this.activeSession,
  });

  @override
  Widget build(BuildContext context) {
    // TaskScope y SessionScope dejan los datos disponibles en todas las pantallas
    return SessionScope(
      repository: sessionRepository,
      child: TaskScope(
        repository: taskRepository,
        child: MaterialApp(
          title: 'Floria',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: kDarkModeReady ? ThemeMode.system : ThemeMode.light,
          // Si ya hay tareas guardadas, se salta la bienvenida y entra directo.
          // Flujo: Bienvenida -> Tareas / Enfoque / Historial (+ Nueva tarea) -> Ajustes
          // Si había una sesión en curso, se retoma al abrir la app (R5).
          home: activeSession != null
              ? MainShell(resumeSession: activeSession)
              : taskRepository.tasks.isEmpty
                  ? const WelcomeScreen()
                  : const MainShell(),
        ),
      ),
    );
  }
}
