# Plan de rediseño: paleta Salvia, minimalismo y accesibilidad

**Proyecto:** App de enfoque para estudiantes (Grupo 6)
**Fecha:** 22 de octubre de 2026
**Objetivo:** que la app se sienta tranquila y fácil de usar, que cumpla pautas de accesibilidad y que cada pantalla respete el alcance declarado en la ficha del proyecto.

---

## 1. Principios de diseño

Estas reglas guían todas las decisiones del plan. Si una pantalla las rompe, se corrige.

1. **Una acción principal por pantalla.** Solo un botón lleno (color primario). Lo demás va como botón secundario o de texto.
2. **Menos tarjetas, más aire.** Máximo 3 o 4 bloques visibles sin hacer scroll. Separar con espacio, no con bordes y sombras.
3. **El color comunica, no decora.** El verde es para acciones y progreso, el terracota solo para alertas y bloqueo. Nada de colores "porque sí".
4. **Calma durante la sesión.** La pantalla de sesión activa muestra solo el tiempo, el objetivo y las salidas. Sin métricas, badges ni animaciones que distraigan.
5. **Solo lo que está en alcance.** Si una función está declarada fuera de alcance, no aparece en la interfaz, ni siquiera como "próximamente".
6. **Accesible por defecto.** Contraste AA, áreas táctiles de 48 dp, textos que crecen sin romperse y etiquetas para lectores de pantalla.

---

## 2. Paleta Salvia Floria (ajustada para accesibilidad)

Medimos el contraste de la paleta original con la fórmula de WCAG 2.1. Dos colores no pasan como texto, así que se ajustan sus usos:

| Rol | Color | Uso | Contraste | Resultado |
| :--- | :--- | :--- | :--- | :--- |
| Primario | `#2F6B4F` | Botones, temporizador, ítem activo | 6.29:1 con blanco · 5.77:1 sobre fondo | ✅ AA |
| Primario contenedor | `#DCEBE0` | Chips y fondos suaves, con texto `#1F4A35` | 8.14:1 | ✅ AA |
| Salvia claro | `#8DB39A` | **Solo** fondos y decoración | 2.13:1 sobre fondo | ❌ Nunca para texto ni íconos |
| Alerta (terracota) | `#9A4A24` | Bloqueo, abandonar sesión, prioridad alta | 6.21:1 con blanco · 5.70:1 sobre fondo · 4.86:1 sobre su contenedor | ✅ AA |
| Terracota original | `#C8693A` | Solo decoración | 3.79:1 con blanco | ❌ No usar en texto ni botones |
| Alerta contenedor | `#F7DFD0` | Fondo de avisos, con texto `#7A3A18` | 6.71:1 | ✅ AA |
| Error | `#B3261E` | Errores de validación del formulario | 6.00:1 | ✅ AA |
| Fondo | `#F7F5EF` | Fondo general (crema) | — | — |
| Superficie | `#FFFFFF` | Tarjetas | — | — |
| Texto principal | `#1C2620` | Títulos y cuerpo | 14.30:1 | ✅ AAA |
| Texto secundario | `#4E5953` | Descripciones y metadatos | 6.69:1 sobre fondo · 5.61:1 sobre contenedores | ✅ AA |
| Secundario | `#46705A` | Íconos de apoyo y gráficas | 5.17:1 sobre fondo | ✅ AA |
| Deshabilitado | `#8A938E` | Solo estados deshabilitados | 2.90:1 | ⚠️ Permitido solo en deshabilitados |

**Modo oscuro:** fondo `#121614`, tarjetas `#1A1F1C`, primario `#8FCBA8`, alerta `#F0A27A`, texto `#E4E8E3` y secundario `#B4BEB7`. Todos los pares de texto superan 6.8:1. Definido en `lib/theme/app_palette.dart`.

**Regla:** la prioridad de una tarea nunca se comunica solo con color. Siempre lleva texto ("Alta", "Media", "Baja") y, si se quiere, un ícono.

---

## 3. Ajustes por alcance

Cosas que hoy aparecen en la app y que la ficha declara **fuera de alcance**:

| Pantalla | Elemento | Acción |
| :--- | :--- | :--- |
| Bienvenida | Botón "Continuar con Google" y divisor "o continúa sin cuenta" | **Quitar.** La bienvenida pasa a ser una sola explicación con un botón "Empezar". |
| Tareas | Tarjeta "Planta árboles mientras estudias" (12 árboles, 6.5 h) | **Quitar.** La gamificación y la plantación real están fuera de alcance. |
| Perfil | Tarjeta "¿Quieres sincronizar o hacer respaldo?" y diálogo "Vincular cuenta" | **Quitar.** No hay sincronización multidispositivo. |
| Perfil | Campana de notificaciones en el encabezado | **Quitar.** Las notificaciones son del sistema, no hay bandeja dentro de la app. |
| Perfil | "ID efímero #LOC-8821" | **Quitar.** No aporta nada al usuario. |
| Sesión activa | Texto "tu árbol en crecimiento se marchitará" | **Cambiar** a "Esta sesión se registrará como abandonada". |

Cosas que **están en alcance** y todavía faltan o están incompletas:

| Requerimiento de la ficha | Qué falta en la interfaz |
| :--- | :--- |
| R1. Pantalla de recordatorio en menos de 2 s si abre una app bloqueada | Diseñar la pantalla de recordatorio (la que mostrará el módulo de Kotlin). Debe ser muy simple: app bloqueada, tiempo restante, objetivo y un solo botón "Volver a mi sesión". |
| R2. El historial registra si la sesión se completó o se abandonó | Al terminar el tiempo: pantalla "¿Cumpliste tu objetivo?" con "Sí" / "En parte" / "No". En Historial, cada sesión muestra su estado con texto e ícono. |
| R4. Iniciar sesión en menos de 5 toques desde la pantalla principal | El botón ▶ de cada tarea abre directamente la Sesión Activa (hoy lleva a la pestaña Enfoque, que es un marcador). Ruta: Tareas → ▶ → (confirmar) = 2 toques. |
| Notificaciones locales de inicio y fin | Pantalla o paso para pedir el permiso de notificaciones, con explicación previa. |
| Bloqueo de apps (permisos nativos) | Pantalla de permisos que explique, en lenguaje simple, por qué se necesita "Acceso a uso" y "Mostrar sobre otras apps", con un botón por permiso y su estado. |

**Pomodoro rápido en Tareas:** hoy permite una sesión sin tarea, pero la ficha dice que cada sesión va ligada a una tarea. Se reemplaza por una tarjeta "Tu siguiente tarea" con un solo botón "Iniciar enfoque".

---

## 4. Rediseño por pantalla

### 4.1 Navegación

- **Hoy:** 4 pestañas (Tareas, Nueva, Enfoque, Historial) y además un botón flotante "+" que hace lo mismo que la pestaña Nueva.
- **Propuesta:** 3 pestañas: **Tareas · Enfoque · Historial**.
  - "Nueva" deja de ser pestaña y se abre con el botón flotante "+" en Tareas.
  - "Enfoque" muestra la sesión activa si hay una corriendo. Si no hay ninguna, muestra la lista corta de tareas para iniciar.
- Íconos con texto siempre visible y área táctil de al menos 48 × 48 dp.

### 4.2 Bienvenida

- Logo, nombre, una frase y tres beneficios en una lista simple, sin tarjetas.
- Un solo botón: "Empezar".
- Quitar Google, el divisor y el badge "Recomendado".

### 4.3 Tareas (inicio)

Orden propuesto, de arriba hacia abajo:
1. Saludo corto y fecha.
2. Tarjeta **"Tu siguiente tarea"**: título, objetivo y botón principal "Iniciar enfoque".
3. Lista de tareas de hoy con filtros por prioridad.
4. Botón flotante "+" para crear una tarea.

Se quitan: Pomodoro sin tarea, árboles, frase motivacional y tarjeta de bloqueo duplicada. El estado del bloqueo se ve en la sesión, no en el inicio.

### 4.4 Nueva tarea (formulario)

- Mantener las validaciones (ya cumplen la entrega del formulario).
- Agrupar en dos bloques: **"¿Qué vas a hacer?"** (título, objetivo, duración) y **"Opciones"** (prioridad, etiquetas, apps a bloquear), con las opciones avanzadas plegadas por defecto.
- Un solo botón principal: "Guardar e iniciar enfoque". "Solo guardar" pasa a ser botón de texto.
- Migrar los colores escritos a mano (`Color(0xFF3227C9)` y otros) al tema central.

### 4.5 Sesión activa

- Temporizador grande al centro, objetivo debajo y nada más en primer plano.
- Botones: "Pausa de 2 minutos" (secundario) y "Abandonar sesión" (texto, color de alerta, con confirmación).
- Quitar: badge "Pomodoro #1", tarjeta de tarea vinculada duplicada y aura animada si el sistema tiene activado "reducir movimiento".
- Al terminar, abrir la pantalla "¿Cumpliste tu objetivo?" (R2).

### 4.6 Historial

- Arriba: selector de semana y **3 métricas** (tiempo total, sesiones completadas, racha). Se quita "Cumplimiento 92%" o se fusiona con sesiones.
- Gráfica de barras más simple: sin etiquetas flotantes, con la meta como línea y un resumen en texto para lectores de pantalla.
- Lista de sesiones con estado claro: ✓ Completada / ✕ Abandonada, en texto y con ícono.
- Se quita "Tiempo por área de enfoque" de la primera vista (pasa a una sección plegable o a una versión posterior).

### 4.7 Perfil y ajustes

- Lista simple: Permisos de bloqueo · Notificaciones · Acerca de · Reiniciar datos. (Se descartó "Exportar datos": los datos son solo locales y no aporta al usuario.)
- Sin tarjetas de sincronización ni campana.

### 4.8 Pantallas nuevas (en alcance)

- **Recordatorio de app bloqueada** (R1).
- **Cierre de sesión: "¿Cumpliste tu objetivo?"** (R2).
- **Permisos** (bloqueo y notificaciones), con explicación previa.

---

## 5. Accesibilidad

| Área | Regla | Cómo se implementa |
| :--- | :--- | :--- |
| Contraste | Texto 4.5:1 y componentes 3:1 (WCAG AA) | Paleta de la sección 2, sin excepciones |
| Tamaño de texto | Mínimo 12 sp y nada de tamaños fijos de 10 u 11 sp | Usar `TextTheme` del tema en vez de `fontSize` sueltos |
| Texto agrandado | La app funciona con texto al 200 % | Evitar alturas fijas (`SizedBox(height: 52)`) en botones con texto. Probar con `textScaler` 1.3, 1.5 y 2.0 |
| Áreas táctiles | Mínimo 48 × 48 dp | Checkbox de tareas (hoy 20 px), chips de filtro y botones de ícono de 32 px |
| Lector de pantalla | Todo botón de solo ícono tiene etiqueta | `Semantics` o `tooltip` en avatar, ▶, editar, calendario y flechas de semana |
| Temporizador | No anunciar cada segundo | `Semantics(liveRegion: true)` actualizado por minuto, y el valor exacto al enfocar |
| Movimiento | Respetar "reducir movimiento" | Desactivar el aura que respira si `MediaQuery.disableAnimations` es verdadero |
| Color | No depender solo del color | La prioridad y el estado de la sesión siempre llevan texto |
| Idioma | Fechas y lectura en español | Configurar `Locale('es')` y `flutter_localizations` |
| Orden de foco | Orden lógico de arriba hacia abajo | Revisar con TalkBack (Android) y VoiceOver (iOS) |

---

## 6. Plan de implementación

Cada fase termina con `flutter analyze` y `flutter test` limpios, y se prueba en Android e iOS.

### Fase 1: base del tema
- [x] Reescribir `lib/theme/app_colors.dart` con la paleta Salvia de la sección 2.
- [x] Crear `lib/theme/app_theme.dart` (claro y oscuro) con `ThemeData`: `ColorScheme`, `TextTheme` (mínimo 12 sp), botones, chips, campos de texto y tarjetas.
- [x] Crear tokens de espaciado y radios (`AppSpacing`, `AppRadius`).
- [x] Crear `lib/theme/app_palette.dart`: paleta clara y oscura accesible con `context.palette`.
- [x] Migrar los colores escritos a mano de todas las pantallas, incluido `task_form_screen.dart`, a la paleta Salvia.
- [x] Cambiar `AppColors.x` por `context.palette.x` en cada pantalla y activar `kDarkModeReady` en `main.dart`.
- [x] Unificar el nombre de la app: **Floria** (también en Android e iOS).

### Fase 2: limpieza por alcance
- [x] Quitar Google, árboles, sincronización, campana e ID efímero (sección 3).
- [x] "Perfil de invitado" pasa a ser **Ajustes** (no hay cuentas). Lo que está fuera de alcance se muestra solo como visión en **Ajustes → Acerca de Floria → Próximamente en Floria**.
- [x] Cambiar los textos que mencionan árboles o funciones fuera de alcance.
- [x] Reemplazar el Pomodoro sin tarea por "Tu siguiente tarea".

### Fase 3: navegación y pantallas
- [x] Pasar a 3 pestañas y mover "Nueva" al botón flotante.
- [ ] Rediseñar Bienvenida, Tareas, Sesión activa, Historial y Perfil según la sección 4.
- [x] Conectar el botón ▶ de cada tarea con la Sesión activa (R4).
- [x] Crear componentes compartidos `AppCard` y `PriorityChip`.
- [x] Bienvenida, Tareas, Ajustes y Acerca de ya usan colores adaptables (listas para modo oscuro).
- [x] Persistencia local con SQLite (`lib/data/`): tareas y sesiones, con migración de versión 1 a 2.
- [x] Nueva tarea simplificada: sin etiquetas; modo **Tiempo libre** o **Pomodoro** (25 min + 5 min de descanso, 25 min cada 3 rondas).
- [x] Sesión activa con fases de Pomodoro, pregunta "¿Cumpliste tu objetivo?" y registro en el historial (R2).
- [x] Historial con datos reales: 3 métricas, enfoque por día, tiempo por tarea y lista de sesiones.
- [x] Rediseñar la pestaña Enfoque y migrarla a colores adaptables; **modo oscuro activado** (`kDarkModeReady = true`).
- [x] Pomodoro estándar: 25 min + 5 min de descanso por ronda (también después de la última); descanso largo de 25 min después de la 4.ª ronda. Botón "¿Cómo funciona?" en el formulario.
- [x] Logo de Floria (`assets/branding/`) en Bienvenida, Acerca de, README e ícono de la app (`flutter_launcher_icons`).

### Fase 4: pantallas nuevas en alcance
- [x] Cierre de sesión "¿Cumpliste tu objetivo?" (R2).
- [x] Recordatorio de app bloqueada (R1): Servicio de Accesibilidad en Kotlin + canal `floria/app_blocker` + pantalla de recordatorio.
- [x] Permisos de bloqueo (Ajustes → Permisos de bloqueo, y aviso al iniciar una sesión).
- [ ] Permiso y notificaciones locales de inicio y fin de sesión.

### Fase 5: accesibilidad
- [ ] Aplicar la tabla de la sección 5.
- [ ] Agregar pruebas automáticas con las guías de `flutter_test`: `androidTapTargetGuideline`, `iOSTapTargetGuideline`, `labeledTapTargetGuideline` y `textContrastGuideline`.
- [ ] Prueba manual con TalkBack, VoiceOver y texto al 200 %.

### Fase 6: revisión final
- [ ] Recorrido completo: crear tarea → iniciar sesión → pausar → terminar → registrar objetivo → ver historial.
- [ ] Verificar que iniciar una sesión desde el inicio toma menos de 5 toques (R4).
- [ ] Actualizar el README con capturas nuevas.

---

## 7. Decisiones del equipo (22 de octubre de 2026)

1. **Nombre:** la app se llama **Floria**.
2. **Navegación:** se aprueban 3 pestañas (Tareas, Enfoque, Historial) con "Nueva" como botón flotante, siempre que se mantenga todo lo que está en alcance.
3. **Modo oscuro:** entra en esta etapa.
4. **Gráficos del Historial:** se mantienen. Los gráficos del progreso propio están en alcance (solo quedan fuera los comparativos entre usuarios). Se quedan en Historial, debajo de las métricas principales.
