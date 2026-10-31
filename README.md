<p align="center">
  <img src="assets/branding/floria_logo_horizontal.png" alt="Floria" width="460">
</p>

# Floria — App de enfoque para estudiantes

App móvil hecha en **Flutter** que ayuda a los estudiantes a sostener sesiones de estudio concentradas. Cada sesión va ligada a una tarea concreta, y durante el enfoque se bloquean las apps que distraen.

**Equipo (Grupo 6, ESEN 2026):** Alejandra Arriola · Alisson Quijano · Gabriel Martínez · Christian Renderos · Melisa Rivas

---

## Contenido

1. [¿Qué problema resuelve?](#qué-problema-resuelve)
2. [Funcionalidades](#funcionalidades)
3. [Requerimientos del proyecto (R1–R5)](#requerimientos-del-proyecto-r1r5)
4. [Requisitos para correrla](#requisitos-para-correrla)
5. [Cómo correrla en Android](#cómo-correrla-en-android)
6. [Cómo correrla en iOS](#cómo-correrla-en-ios)
7. [Bloqueo de apps (solo Android)](#bloqueo-de-apps-solo-android)
8. [Pruebas y análisis](#pruebas-y-análisis)
9. [Estructura del proyecto](#estructura-del-proyecto)
10. [Arquitectura](#arquitectura)
11. [Stack tecnológico](#stack-tecnológico)
12. [Solución de problemas](#solución-de-problemas)

---

## ¿Qué problema resuelve?

Los estudiantes que estudian solos suelen carecer de una rutina sostenida de organización y concentración. Muchos ya probaron técnicas como Pomodoro, pero fallan porque **nada les impide abrir la app que los distrae**.

Floria está pensada para estudiantes de bachillerato y universidad (de 15 a 25 años, aproximadamente) y se puede usar de dos formas:

- **Sin cuenta:** funciona 100 % sin conexión y todos los datos se quedan en el teléfono (SQLite).
- **Con cuenta de Google:** las tareas y el historial se guardan en Firebase (Firestore) para no perderlos y verlos en otro teléfono. También funciona sin conexión y se sincroniza al volver internet.

### Flujo principal

1. El usuario crea o elige una tarea.
2. Declara qué quiere lograr en esa sesión.
3. Inicia la sesión de enfoque con las apps distractoras bloqueadas.
4. Al terminar responde "¿Cumpliste tu objetivo?" y la sesión queda en el historial (completada o abandonada).

---

## Funcionalidades

| Pantalla | Qué hace |
| :--- | :--- |
| **Bienvenida** | Primera pantalla si todavía no hay tareas. Explica la app y lleva a crear la primera tarea. |
| **Tareas** | Inicio. Muestra "Tu siguiente tarea", filtros por prioridad (Todas, Baja, Media, Alta) y la lista de tareas. Cada tarea tiene una casilla para marcarla como hecha, ▶ para iniciar el enfoque y un menú ⋮ con **Editar** y **Eliminar** (este último con opción de deshacer). |
| **Nueva / Editar tarea** | Formulario con validaciones: título, objetivo (mínimo 4 palabras y 15 caracteres), modo **Tiempo libre** o **Pomodoro** (1 a 6 rondas), prioridad y apps a bloquear. |
| **Elegir apps** | Lista de las apps instaladas (Android) con atajos: redes sociales recomendadas o todas (menos las esenciales, como Teléfono, Ajustes y Reloj). |
| **Sesión activa** | Temporizador con las fases de Pomodoro, el objetivo a la vista, una pausa de emergencia de 2 minutos y la opción de abandonar. Al terminar pregunta si se cumplió el objetivo. |
| **Recordatorio** | Aparece cuando se abre una app bloqueada: dice qué app es, cuánto falta y el objetivo, con un solo botón "Volver a mi sesión". |
| **Enfoque** | Resumen del día y tareas pendientes para empezar una sesión. |
| **Historial** | Resumen semanal: minutos de enfoque, racha, actividad por día y sesiones recientes con su estado. |
| **Ajustes** | Permisos de bloqueo, notificaciones, reinicio de datos, "Acerca de Floria", Términos de uso y Política de privacidad. |

Además:

- **La sesión sigue aunque se cierre la app.** Al abrirla de nuevo se retoma con el tiempo real.
- **Notificaciones locales:** una notificación de "Sesión en curso" con la hora de fin, y avisos al terminar cada ronda, cada descanso y la sesión.
- **Modo oscuro** automático según el sistema.
- **Accesibilidad:** contraste AA (WCAG), botones de al menos 48 dp, texto de al menos 12 sp, etiquetas para lectores de pantalla y respeto a "Reducir movimiento".

### Reglas de Pomodoro

- Cada ronda tiene 25 min de enfoque y 5 min de descanso (también después de la última ronda).
- Cada 4 rondas, el descanso es largo: 25 min.
- Se pueden elegir de 1 a 6 rondas.

---

## Requerimientos del proyecto (R1–R5)

| Requerimiento | Cómo se cumple | Dónde está en el código |
| :--- | :--- | :--- |
| **R1.** Si se abre una app bloqueada, aparece un recordatorio en menos de 2 s | Un Servicio de Accesibilidad de Android detecta la app y abre Floria. En modo debug se imprime el tiempo medido: `[R1] Recordatorio de … mostrado en … ms`. | `android/.../BlockerAccessibilityService.kt`, `lib/services/app_blocker.dart`, `lib/screens/blocked_app_reminder_screen.dart` |
| **R2.** El historial registra si la sesión se completó o se abandonó | Al terminar se guarda la sesión con su estado y su resultado (Sí / En parte / No). | `lib/data/session_repository.dart`, `lib/screens/history_screen.dart` |
| **R3.** Funciona sin conexión | Sin cuenta, todo se guarda en SQLite. Con cuenta, Firestore guarda una copia en el teléfono y sincroniza al volver internet. | `lib/data/app_database.dart`, `lib/data/firestore_*_repository.dart` |
| **R4.** Se inicia una sesión en menos de 5 toques desde el inicio | Tareas → ▶ (→ permisos solo la primera vez) = 1–2 toques. | `lib/screens/tasks_screen.dart`, `lib/screens/session_launcher.dart` |
| **R5.** Si la app se cierra durante una sesión, al reabrirla se ve el tiempo real | El reloj guarda la hora de inicio, las pausas y los descansos saltados, y calcula el tiempo con la hora actual. | `lib/models/session_clock.dart`, tabla `active_session` |

---

## Requisitos para correrla

| Herramienta | Versión |
| :--- | :--- |
| Flutter | **3.47.7** o más reciente (canal `stable`) |
| Dart | Viene con Flutter |
| Android | Android Studio con Android SDK y un emulador o teléfono Android (el proyecto usa Gradle 9.3.1 y Java 17+) |
| iOS (solo en Mac) | Xcode y CocoaPods; iOS 15.0 o superior |

Revisa tu entorno con:

```bash
flutter --version
flutter doctor
```

> **Importante:** todo el equipo debe usar la misma versión de Flutter. Si la tuya es más antigua, actualízala con `flutter upgrade`.

### Clonar e instalar dependencias (Android e iOS)

```bash
git clone https://github.com/Chocolatinax/AppEnfoque.git
cd AppEnfoque
flutter pub get
```

### Firebase (inicio de sesión, Firestore y Analytics)

El proyecto de Firebase es **`app-enfoque`** y ya está conectado (`lib/firebase_options.dart`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`).

- **iPhone:** no hace falta nada más.
- **Android:** no hace falta nada más. `flutter run` firma la app con la llave de prueba compartida del repo (`android/app/floria-debug.jks`), cuya huella ya está registrada en Firebase, así que "Continuar con Google" funciona en cualquier computadora.
- **APK final:** se firma con la llave privada de Floria, que **no está en el repo**. Quien la tenga crea `android/key.properties` a partir de `android/key.properties.example` y corre `flutter build apk --release`.
- **Reglas de seguridad de Firestore:** están en `firestore.rules` (cada usuario solo puede leer y escribir lo suyo). Para publicarlas: `firebase deploy --only firestore:rules`.

---

## Cómo correrla en Android

### En un emulador

1. Abre **Android Studio → Device Manager → Create Virtual Device**.
2. Elige un teléfono (por ejemplo, Pixel 8) y una imagen del sistema **con Google Play** (Android 13 o más nuevo). Así ya trae YouTube para probar el bloqueo.
3. Inicia el emulador con ▶.
4. Revisa que Flutter lo detecte y corre la app:
   ```bash
   flutter devices
   flutter run
   ```
   Si hay varios dispositivos, elige uno con `flutter run -d <id>`.

### En un teléfono Android

1. En el teléfono: **Ajustes → Acerca del teléfono** y toca 7 veces **Número de compilación** para activar las opciones de desarrollador.
2. En **Ajustes → Sistema → Opciones de desarrollador**, activa **Depuración USB**.
3. Conecta el teléfono por cable y acepta el aviso "¿Permitir depuración USB?".
4. Corre `flutter devices` y luego `flutter run`.

### Generar un APK de prueba

```bash
flutter build apk --debug
```

El archivo queda en `build/app/outputs/flutter-apk/app-debug.apk` y se puede instalar en cualquier Android.

### Permisos que pide en Android

| Permiso | Cuándo | Para qué |
| :--- | :--- | :--- |
| Notificaciones (Android 13+) | Al iniciar la primera sesión | Mostrar la sesión en curso y los avisos |
| Servicio de Accesibilidad "Floria: bloqueo de distracciones" | Al iniciar una sesión con apps bloqueadas | Detectar qué app se abre (no lee el contenido de las pantallas) |
| Alarmas y recordatorios (alarmas exactas) | Al iniciar la primera sesión (o en Ajustes → Avisos a tiempo) | Que los avisos lleguen a la hora exacta; sin él pueden llegar unos minutos tarde |

---

## Cómo correrla en iOS

> Se necesita una Mac con Xcode. En iOS funciona todo **menos el bloqueo de apps** (ver la sección siguiente).

### En el simulador

1. Instala las dependencias nativas (la primera vez y cada vez que cambien los paquetes):
   ```bash
   cd ios && pod install && cd ..
   ```
2. Abre el simulador:
   ```bash
   open -a Simulator
   ```
3. Corre la app:
   ```bash
   flutter run
   ```

### En un iPhone

1. Conecta el iPhone por cable y toca **Confiar en esta computadora**.
2. Abre `ios/Runner.xcworkspace` en Xcode (el `.xcworkspace`, no el `.xcodeproj`).
3. Selecciona **Runner → Signing & Capabilities** y elige tu **Team** (sirve una cuenta de Apple gratuita). El identificador de la app es `sv.esen.floria`; si Xcode dice que ya está en uso, agrégale algo al final solo en tu copia (por ejemplo `sv.esen.floria.ali`) y no lo subas a git.
4. En el iPhone activa **Ajustes → Privacidad y seguridad → Modo desarrollador** y reinícialo si lo pide.
5. Corre `flutter run` y elige el iPhone.
6. La primera vez, en el iPhone ve a **Ajustes → General → VPN y gestión de dispositivos** y confía en tu certificado de desarrollador.

> Con una cuenta gratuita, la app instalada en el iPhone deja de abrir a los 7 días. Basta con volver a correr `flutter run`.

### Permisos que pide en iOS

- **Notificaciones:** se piden al iniciar la primera sesión, no al abrir la app.

---

## Bloqueo de apps (solo Android)

Durante una sesión, Floria detecta si abres una app bloqueada y te muestra un recordatorio (R1). Funciona con un **Servicio de Accesibilidad** de Android escrito en Kotlin, conectado a Flutter por el canal `floria/app_blocker`.

- El bloqueo está activo durante el enfoque y se libera en los descansos, en la pausa de emergencia y al terminar la sesión.
- El servicio solo lee el nombre del paquete de la app que se abre. No lee el contenido de las pantallas ni envía datos.
- Android guarda el **horario de las rondas de enfoque**: aunque Floria se cierre, cada ronda de Pomodoro bloquea a su hora, los descansos y la pausa de emergencia quedan libres, y el bloqueo se apaga solo al terminar la última ronda.
- **Ajustes y Teléfono nunca se bloquean:** no aparecen en la lista, para que siempre se pueda apagar el servicio y hacer llamadas de emergencia.
- **Ventana flotante (imagen en imagen):** si un video de una app bloqueada queda en ventana flotante, Floria no lo detecta, porque no hay un cambio de app. Ninguna app puede cerrar la ventana flotante de otra, así que la sesión le pide al usuario cerrarla. Quien quiera ver videos en ventana flotante puede no bloquear esa app.
- **En iOS no hay bloqueo:** Apple solo lo permite con la API *Screen Time*, que requiere un permiso especial de Apple. La versión iOS está fuera del alcance del proyecto, pero el resto de la app funciona igual.

### Cómo probarlo

1. Usa un teléfono Android o un emulador **con Google Play**.
2. Corre la app y crea una tarea con **YouTube** marcada en "Bloquear apps".
3. Toca ▶. La primera vez, Floria pide activar el permiso: Ajustes → Accesibilidad → **Floria: bloqueo de distracciones** → activar.
4. Con la sesión corriendo, abre YouTube. Floria debe aparecer en menos de 2 segundos con el recordatorio.
5. En la terminal de `flutter run` aparece la medición: `[R1] Recordatorio de YouTube mostrado en … ms`. Se mide desde que Android registró la apertura de la app, así que incluye el retraso del sistema.

> **Android 13 o más nuevo:** si el permiso aparece como "Ajuste restringido", ve a Ajustes → Apps → Floria → menú ⋮ → **Permitir ajustes restringidos** y vuelve a intentarlo.

---

## Pruebas y análisis

```bash
flutter analyze   # Revisa errores y advertencias del código
flutter test      # Corre todas las pruebas
dart format lib   # Da formato al código
```

| Archivo de prueba | Qué prueba |
| :--- | :--- |
| `test/widget_test.dart` | El formulario: validaciones, totales de Pomodoro, selección de apps y modo editar. |
| `test/form_validators_test.dart` | Las reglas de cada campo del formulario. |
| `test/task_repository_test.dart` | Guardar, editar, completar, eliminar y deshacer tareas, y el orden de la lista. |
| `test/session_repository_test.dart` | El historial de sesiones y la racha de días. |
| `test/session_clock_test.dart` | El reloj de la sesión (R5): tiempo real con la app cerrada, pausas y descansos. |
| `test/notification_plan_test.dart` | Qué avisos se programan y a qué hora. |
| `test/app_blocking_test.dart` | El catálogo de apps bloqueables y la selección. |
| `test/firestore_repository_test.dart` | Tareas e historial en Firestore (simulado): guardar, cargar, separar usuarios y subir datos. |
| `test/legal_screen_test.dart` | Términos y privacidad, con las guías automáticas de accesibilidad (contraste, áreas táctiles y texto al 200 %). |

Las pruebas de base de datos usan `sqflite_common_ffi`, así que corren en la computadora sin emulador.

---

## Estructura del proyecto

```
AppEnfoque/
├── lib/                          # Código de la app en Dart
│   ├── main.dart                 # Punto de entrada: abre la base de datos, carga los datos y decide la primera pantalla
│   ├── models/                   # Datos puros, sin interfaz
│   │   ├── task_model.dart       # Tarea, modo de tiempo y reglas de Pomodoro
│   │   ├── focus_session.dart    # Sesión del historial y su resultado
│   │   └── session_clock.dart    # Reloj de la sesión basado en la hora real (R5)
│   ├── data/                     # Persistencia local
│   │   ├── app_database.dart     # Base SQLite floria.db: tablas y migraciones
│   │   ├── task_repository.dart  # Contrato (clase abstracta) de las tareas + TaskScope
│   │   ├── sqlite_task_repository.dart # Implementación con SQLite
│   │   ├── session_repository.dart # Contrato del historial, racha y sesión en curso + SessionScope
│   │   ├── sqlite_session_repository.dart # Implementación con SQLite
│   │   ├── firestore_task_repository.dart # Implementación con Firestore (con cuenta)
│   │   ├── firestore_session_repository.dart
│   │   ├── app_data.dart         # Cambia entre SQLite y Firestore según la cuenta
│   │   ├── settings_store.dart   # Ajustes guardados (permiso de Analytics)
│   │   └── blockable_apps.dart   # Catálogo de redes sociales recomendadas para bloquear
│   ├── services/                 # Conexión con el sistema operativo
│   │   ├── app_blocker.dart      # Canal hacia el bloqueo de apps en Kotlin
│   │   └── notification_service.dart # Notificaciones locales
│   ├── screens/                  # Una pantalla por archivo
│   │   ├── welcome_screen.dart
│   │   ├── main_shell.dart       # Contenedor con la barra de navegación inferior
│   │   ├── tasks_screen.dart
│   │   ├── focus_screen.dart
│   │   ├── history_screen.dart
│   │   ├── settings_screen.dart
│   │   ├── about_screen.dart
│   │   ├── active_session_screen.dart
│   │   ├── session_launcher.dart # Pide los permisos antes de iniciar una sesión
│   │   ├── blocking_permission_screen.dart
│   │   ├── blocked_app_reminder_screen.dart # Recordatorio de app bloqueada (R1)
│   │   ├── app_picker_screen.dart
│   │   └── legal_screen.dart     # Términos de uso y Política de privacidad
│   ├── theme/                    # Diseño
│   │   ├── app_colors.dart       # Paleta Salvia
│   │   ├── app_palette.dart      # Colores para modo claro y oscuro
│   │   ├── app_theme.dart        # Tema de Material 3
│   │   └── app_spacing.dart      # Espacios estándar
│   ├── utils/
│   │   ├── form_validators.dart  # Reglas del formulario
│   │   └── ui_feedback.dart      # Mensajes cortos (SnackBars)
│   └── widgets/
│       ├── task_form_screen.dart # Formulario para crear o editar una tarea
│       └── common/               # Componentes compartidos: tarjeta, chip de prioridad, barra, eliminar con deshacer
├── android/                      # Proyecto nativo de Android
│   └── app/src/main/
│       ├── kotlin/sv/esen/floria/
│       │   ├── MainActivity.kt   # Canal floria/app_blocker y lista de apps instaladas
│       │   ├── BlockerAccessibilityService.kt # Detecta la app abierta y trae Floria al frente
│       │   └── BlockerState.kt   # Qué apps están bloqueadas y hasta cuándo
│       ├── res/xml/blocker_accessibility_service.xml # Configuración del servicio
│       └── AndroidManifest.xml   # Permisos, servicio y nombre de la app
├── ios/                          # Proyecto nativo de iOS
│   └── Runner/
│       ├── AppDelegate.swift     # Permite mostrar notificaciones con la app abierta
│       └── Info.plist            # Nombre de la app y ajustes de iOS
├── assets/branding/              # Logo, isotipo e ícono de la app
├── test/                         # Pruebas unitarias y de widgets
├── pubspec.yaml                  # Dependencias y recursos
└── analysis_options.yaml         # Reglas del analizador de código
```

---

## Arquitectura

```
Pantallas (screens/, widgets/)
      │  leen y escuchan cambios con TaskScope / SessionScope
      ▼
Repositorios: contratos (data/*_repository.dart)
      │        implementación SQLite (data/sqlite_*_repository.dart)
      │
      ▼
SQLite (data/app_database.dart)        → floria.db en el teléfono

Servicios (services/) ── MethodChannel ──► Kotlin (bloqueo de apps)
                      └─ flutter_local_notifications ──► notificaciones del sistema
```

- **Repository con contratos:** `TaskRepository` y `SessionRepository` son clases abstractas (qué se puede hacer con los datos). `SqliteTaskRepository` y `SqliteSessionRepository` las implementan con SQLite. Las pantallas solo conocen el contrato, así que se podría agregar otra fuente de datos (por ejemplo, la nube) sin tocarlas.
- **Estado con `ChangeNotifier`:** los repositorios guardan los datos en memoria y en SQLite al mismo tiempo, y avisan a las pantallas cuando algo cambia.
- **`InheritedNotifier` (`TaskScope`, `SessionScope`):** reparten los repositorios a toda la app sin paquetes externos. Se usa `.of(context)` para dibujar y `.read(context)` para acciones.
- **Base de datos `floria.db` (versión 4):** tablas `tasks`, `sessions` y `active_session`, con migraciones para no perder datos al actualizar.

---

## Stack tecnológico

| Tecnología | Uso |
| :--- | :--- |
| Flutter (Dart), Material 3 | Interfaz y lógica de la app |
| Kotlin (Platform Channels) | Bloqueo de apps con un Servicio de Accesibilidad de Android |
| SQLite (`sqflite`) | Tareas, historial y sesión en curso |
| `flutter_local_notifications` + `timezone` | Notificaciones locales programadas |
| `sqflite_common_ffi` | Base de datos en las pruebas |
| `flutter_launcher_icons` | Ícono de la app |
| `firebase_auth` | Inicio de sesión con Google (opcional), con el flujo propio de Firebase |
| `cloud_firestore` | Respaldo de tareas e historial para quien tiene cuenta |
| `firebase_analytics` | Datos de uso anónimos, solo si el usuario acepta |
| `fake_cloud_firestore` | Firestore simulado en las pruebas |

**Dos modos:** sin cuenta, la app es 100 % local. Con cuenta, `AppData` cambia los repositorios de SQLite por los de Firestore; las pantallas no se enteran porque solo conocen los contratos.

---

## Solución de problemas

| Problema | Solución |
| :--- | :--- |
| `Unsupported class file major version 69` en Android | Tu copia tiene la configuración vieja de Android. Haz `git pull` y luego `flutter clean`. |
| Errores raros después de actualizar Flutter o hacer `git pull` | `flutter clean && flutter pub get` |
| Errores de CocoaPods en iOS | `cd ios && pod install --repo-update && cd ..` |
| `flutter run` no encuentra dispositivos | Abre el emulador o el simulador primero y revisa con `flutter devices`. |
| iPhone: "Untrusted Developer" | Ajustes → General → VPN y gestión de dispositivos → confiar en tu certificado. |
| iPhone: error de *Signing* | En Xcode elige tu Team y cambia el Bundle Identifier por uno propio. |
| El bloqueo no funciona en Android | Revisa que el servicio "Floria: bloqueo de distracciones" esté activado en Accesibilidad y que la app esté marcada en la tarea. |
| No llegan notificaciones | Revisa que estén permitidas en los ajustes del teléfono para Floria. |
