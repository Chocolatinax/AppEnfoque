# Enfoque — App de productividad para estudiantes

Aplicación móvil desarrollada en **Flutter** que ayuda a estudiantes a mantener sesiones de estudio concentradas, ligando cada sesión a una tarea concreta y bloqueando las apps que los distraen.

**Equipo (Grupo 6):** Alejandra Arriola · Alisson Quijano · Gabriel Martínez · Christian Renderos · Melisa Rivas

---

## ¿Qué problema resuelve?

Los estudiantes que estudian solos suelen carecer de una rutina sostenida de organización y concentración. Muchos ya probaron técnicas como Pomodoro, pero fallan porque **nada les impide abrir la app que los distrae**.

Enfoque está pensada para estudiantes de bachillerato y universidad (aprox. 15 a 25 años) y funciona **100% offline**: no requiere cuenta ni conexión a internet, y todos los datos viven en el dispositivo.

### Flujo principal

1. El usuario elige o crea una tarea.
2. Declara qué quiere lograr en esa sesión.
3. Inicia una sesión de enfoque con las apps distractoras bloqueadas.
4. Al terminar, la sesión queda registrada en el historial (completada o abandonada).

---

## Pantallas actuales

| Pantalla | Descripción |
| :--- | :--- |
| **Bienvenida** | Entrada a la app en Modo Invitado (offline). |
| **Tareas** | Inicio: saludo, Pomodoro rápido, estado del bloqueo y lista de tareas con filtros por prioridad. |
| **Nueva** | Formulario para crear una tarea con validaciones (título, objetivo, duración, prioridad, etiquetas y apps a bloquear). |
| **Sesión Activa** | Se abre con "Guardar e Iniciar Enfoque": temporizador real, compromiso de la tarea, pausa de emergencia de 2 minutos y opción de abandonar. |
| **Enfoque** | Pestaña en construcción. |
| **Historial** | Resumen semanal: métricas, actividad diaria, tiempo por área y sesiones recientes. |
| **Perfil de invitado** | Almacenamiento local, ajustes y reinicio de datos. |

> **Estado:** las pantallas son navegables y sus botones responden, pero por ahora usan datos de ejemplo. La persistencia local (SQLite), el bloqueo nativo de apps (Kotlin) y las notificaciones locales se integrarán en las siguientes etapas.

---

## Requisitos

| Herramienta | Versión |
| :--- | :--- |
| Flutter | **3.47.7** o más reciente (canal `stable`) |
| Dart | Incluido con Flutter |
| Android | Android Studio con Android SDK (el proyecto usa Gradle 9.3.1 y Java 17+) |
| iOS (solo macOS) | Xcode y CocoaPods; iOS 15.0 o superior |

Verifica tu entorno con:

```bash
flutter --version
flutter doctor
```

> **Importante:** todo el equipo debe usar la misma versión de Flutter. Si tienes una más antigua, actualízala con `flutter upgrade`.

---

## Cómo correr el proyecto

### 1. Clonar e instalar dependencias

```bash
git clone https://github.com/Chocolatinax/AppEnfoque.git
cd AppEnfoque
flutter pub get
```

### 2a. Correr en Android

1. Abre **Android Studio → Device Manager** e inicia un emulador (o conecta un teléfono Android con *Depuración USB* activada).
2. Verifica que Flutter lo detecte:
   ```bash
   flutter devices
   ```
3. Corre la app:
   ```bash
   flutter run
   ```
   Si hay varios dispositivos conectados, elige uno con `flutter run -d <id-del-dispositivo>`.

Para generar un APK de prueba:

```bash
flutter build apk --debug
```

El archivo queda en `build/app/outputs/flutter-apk/app-debug.apk`.

### 2b. Correr en iOS (solo macOS)

1. Instala las dependencias nativas:
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

Para correr en un iPhone físico, abre `ios/Runner.xcworkspace` en Xcode, selecciona tu equipo en *Signing & Capabilities* y luego ejecuta `flutter run`.

---

## Pruebas y análisis

```bash
flutter analyze   # Revisa errores y advertencias del código
flutter test      # Corre las pruebas unitarias y de widgets
dart format lib   # Da formato al código
```

---

## Solución de problemas

| Problema | Solución |
| :--- | :--- |
| `Unsupported class file major version 69` en Android | Tu copia del proyecto tiene la configuración vieja de Android. Haz `git pull` y luego `flutter clean`. |
| Errores raros después de actualizar Flutter o hacer `git pull` | `flutter clean && flutter pub get` |
| Errores de CocoaPods en iOS | `cd ios && pod install --repo-update && cd ..` |
| `flutter run` no encuentra dispositivos | Abre el emulador o simulador primero y revisa con `flutter devices`. |

---

## Estructura del proyecto

```
lib/
├── main.dart                     # Punto de entrada (inicia en la Bienvenida)
├── models/                       # Modelos de datos (Task, BlockedAppItem)
├── screens/                      # Pantallas de la app
│   ├── welcome_screen.dart
│   ├── main_shell.dart           # Contenedor con la barra de navegación inferior
│   ├── tasks_screen.dart
│   ├── focus_screen.dart
│   ├── history_screen.dart
│   ├── profile_screen.dart
│   └── active_session_screen.dart
├── theme/app_colors.dart         # Paleta de colores centralizada
├── utils/                        # Validadores del formulario y avisos (SnackBars)
└── widgets/                      # Formulario "Nueva" y componentes compartidos
test/                             # Pruebas unitarias y de widgets
docs/                             # Documentación de entregas
```

---

## Stack tecnológico

- **Flutter (Dart):** interfaz y lógica de la app.
- **Kotlin (Platform Channels):** bloqueo de apps con APIs nativas de Android *(próximamente)*.
- **SQLite:** persistencia local de tareas y sesiones *(próximamente)*.
- **flutter_local_notifications:** avisos de inicio y fin de sesión *(próximamente)*.
- **Sin backend:** la app es de uso individual, sin registro y sin sincronización en la nube.

---

## Documentación

- [Especificación: refactorización del formulario con `Form`](docs/especificacion-formulario.md)
