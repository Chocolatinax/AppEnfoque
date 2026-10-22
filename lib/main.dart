import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/app_database.dart';
import 'data/session_repository.dart';
import 'data/task_repository.dart';
import 'screens/main_shell.dart';
import 'screens/welcome_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  // Abre la base de datos local (SQLite) y carga las tareas guardadas
  final database = await AppDatabase.open();
  final taskRepository = TaskRepository(database);
  final sessionRepository = SessionRepository(database);
  await Future.wait([taskRepository.load(), sessionRepository.load()]);

  runApp(FloriaApp(
    taskRepository: taskRepository,
    sessionRepository: sessionRepository,
  ));
}

/// Todas las pantallas usan la paleta adaptable (context.palette), así que la app
/// sigue el modo claro/oscuro del sistema. Con `false` se fuerza el modo claro.
const bool kDarkModeReady = true;

class FloriaApp extends StatelessWidget {
  final TaskRepository taskRepository;
  final SessionRepository sessionRepository;

  const FloriaApp({
    super.key,
    required this.taskRepository,
    required this.sessionRepository,
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
        home: taskRepository.tasks.isEmpty ? const WelcomeScreen() : const MainShell(),
      ),
      ),
    );
  }
}
