import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/app_database.dart';
import 'data/session_repository.dart';
import 'models/session_clock.dart';
import 'data/task_repository.dart';
import 'screens/main_shell.dart';
import 'services/notification_service.dart';
import 'screens/welcome_screen.dart';
import 'data/sqlite_session_repository.dart';
import 'data/sqlite_task_repository.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  await NotificationService.instance.init();

  final database = await AppDatabase.open();
  final taskRepository = SqliteTaskRepository(database);
  final sessionRepository = SqliteSessionRepository(database);
  await Future.wait([taskRepository.load(), sessionRepository.load()]);

  ActiveSessionRecord? activeSession = await sessionRepository.loadActive();
  if (activeSession != null &&
      taskRepository.tasks.every((t) => t.id != activeSession!.taskId)) {
    await sessionRepository.clearActive();
    activeSession = null;
  }

  runApp(FloriaApp(
    taskRepository: taskRepository,
    sessionRepository: sessionRepository,
    activeSession: activeSession,
  ));
}

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
