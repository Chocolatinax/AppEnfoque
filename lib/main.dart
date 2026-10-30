import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/app_data.dart';
import 'data/app_database.dart';
import 'data/session_repository.dart';
import 'data/task_repository.dart';
import 'firebase_options.dart';
import 'models/session_clock.dart';
import 'screens/main_shell.dart';
import 'screens/welcome_screen.dart';
import 'services/analytics_service.dart';
import 'services/auth_service.dart';
import 'services/firebase_analytics_service.dart';
import 'services/firebase_auth_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.instance.init();

  final database = await AppDatabase.open();
  final data =
      AppData(database: database, firestore: FirebaseFirestore.instance);
  await data.loadLocal();

  final consent = await data.settings.analyticsAllowed();
  Analytics.instance = FirebaseAnalyticsService(enabled: consent == true);
  await Analytics.instance.setEnabled(consent == true);

  final auth = FirebaseAuthService();
  await data.useAccount(auth.currentUser?.uid);

  ActiveSessionRecord? activeSession = await data.sessions.loadActive();
  if (activeSession != null &&
      data.tasks.tasks.every((t) => t.id != activeSession!.taskId)) {
    await data.sessions.clearActive();
    activeSession = null;
  }

  runApp(FloriaApp(auth: auth, data: data, activeSession: activeSession));
}

const bool kDarkModeReady = true;

class FloriaApp extends StatefulWidget {
  final AuthService auth;
  final AppData data;
  final ActiveSessionRecord? activeSession;

  const FloriaApp({
    super.key,
    required this.auth,
    required this.data,
    this.activeSession,
  });

  @override
  State<FloriaApp> createState() => _FloriaAppState();
}

class _FloriaAppState extends State<FloriaApp> {
  // La primera pantalla se decide una sola vez, al abrir la app
  late final Widget _home = widget.activeSession != null
      ? MainShell(resumeSession: widget.activeSession)
      : widget.data.tasks.tasks.isEmpty && !widget.data.usesCloud
          ? const WelcomeScreen()
          : const MainShell();

  @override
  void initState() {
    super.initState();
    widget.auth.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    widget.auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  // Al iniciar o cerrar sesión se cambia entre SQLite y Firestore
  void _onAuthChanged() => widget.data.useAccount(widget.auth.currentUser?.uid);

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return AuthScope(
      service: widget.auth,
      child: AppDataScope(
        data: data,
        child: ListenableBuilder(
          listenable: data,
          builder: (context, _) => SessionScope(
            repository: data.sessions,
            child: TaskScope(
              repository: data.tasks,
              child: MaterialApp(
                title: 'Floria',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: kDarkModeReady ? ThemeMode.system : ThemeMode.light,
                home: _home,
                // Tocar fuera de un campo de texto cierra el teclado
                builder: (context, child) => GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
