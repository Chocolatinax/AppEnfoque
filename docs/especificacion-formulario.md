# Especificación de diseño: refactorización de un formulario con `Form` en Flutter
Alejandra Arriola, Alisson Quijano, Gabriel Martínez, Christian Renderos y Melisa Rivas

**Proyecto:** App de enfoque y productividad para estudiantes  
**Actividad:** Refactoriza un formulario con Form  
**Fecha:** 6 de octubre de 2026  
**Tecnología:** Flutter (Dart)  

---

## 1. Contexto del proyecto y por qué elegimos este formulario

### 1.1 Alcance
Es *"Una aplicación Android desarrollada en Flutter, de uso individual y sin registro, que no depende de la conexión a internet..."*
* Y en lo que queda **fuera de alcance** aparece *"Cuenta de usuario con login social, sincronización multidispositivo..."*

O sea, la app funciona completamente offline y no maneja cuentas de usuario.

### 1.2 El formulario que elegimos
En su lugar trabajamos con el formulario que está en el centro de todo el flujo de la app: el **formulario para crear una tarea con bloqueo de aplicaciones**.

Este formulario toca dos módulos del proyecto:
* Tareas y persistencia local 
* Bloqueo de apps y permisos nativos 

---

## 2. Paso 1: el formulario base (antes de refactorizar)

Así se vería una versión básica del formulario, sin ninguna estructura. Son `TextField` sueltos que leen el texto con controladores, pero no hay nada que valide los datos antes de guardarlos:

```dart
// Estado inicial típico (con huecos y sin validación centralizada):
Column(
  children: [
    TextField(
      controller: _titleController,
      decoration: InputDecoration(labelText: 'Título de la tarea'),
    ),
    TextField(
      controller: _goalController,
      decoration: InputDecoration(labelText: '¿Qué quieres lograr?'),
    ),
    TextField(
      controller: _durationController,
      decoration: InputDecoration(labelText: 'Duración (minutos)'),
    ),
    ElevatedButton(
      onPressed: () {
        // Guarda directamente sin verificar si los datos son válidos
        guardarTarea();
      },
      child: Text('Guardar Tarea'),
    ),
  ],
)
```

---

## 3. Paso 2: los huecos que encontramos

Estas son las entradas inválidas que el formulario debería rechazar antes de guardar la tarea.

### Campo 1: título de la tarea
* **Hueco 1.1, vacío o solo espacios:** el usuario deja el campo en blanco o escribe nada más espacios (`"   "`).
* **Hueco 1.2, muy corto:** títulos de menos de 3 caracteres (como `"a"` o `"x1"`), que no dicen claramente de qué se trata la tarea.
* **Hueco 1.3, muy largo:** títulos de más de 50 caracteres, que se ven mal en las listas y en el resto de la interfaz.

### Campo 2: el objetivo ("¿Qué quieres lograr?")
* **Hueco 2.1, vacío o de una sola palabra:** el usuario no pone nada o solo escribe `"estudiar"`. Eso va en contra de la idea misma de la app, porque cada tarea necesita una meta concreta para que el estudiante no se disperse.
* **Hueco 2.2, muy corto:** metas de menos de 10 caracteres, que no alcanzan a describir un entregable claro.

### Campo 3: duración estimada de la sesión (en minutos)
* **Hueco 3.1, no es un número:** cosas como `"veinticinco"`, `"25 min"` o caracteres especiales.
* **Hueco 3.2, cero o negativo:** valores como `0` o `-15`.
* **Hueco 3.3, duraciones poco realistas:** menos de 5 minutos no alcanza para un bloque de estudio, y más de 180 minutos son tres horas seguidas sin descanso, lo cual choca con la metodología de estudio que sigue la app.
* **Hueco 3.4, decimales:** valores como `25.5`, cuando el temporizador trabaja con minutos enteros.

### Componente extra: selector de apps a bloquear
* **Hueco 4.1, ninguna app seleccionada:** si se guarda la tarea sin elegir qué apps bloquear, se pierde el propósito principal del sistema de bloqueo.

---

## 4. Paso 4: comparación de reglas alternativas

Comparamos tres opciones:

| Criterio | Opción A: equilibrada (la que elegimos) | Opción B: estricta | Opción C: permisiva |
| :--- | :--- | :--- | :--- |
| **Título** | Entre 3 y 50 caracteres, con `trim()`. | Entre 5 y 40 caracteres y la primera letra en mayúscula. | Solo `trim().isNotEmpty`. |
| **Objetivo** | Mínimo 10 caracteres (`trim().length >= 10`). | Mínimo 20 caracteres y al menos 3 palabras. | Solo `trim().isNotEmpty`. |
| **Duración** | Entero entre 5 y 180 minutos. | Múltiplos de 5 o bloques fijos (25, 50, 90). | Cualquier entero mayor que 0. |
| **Apps bloqueadas** | Al menos 1 app. | Mínimo 2 apps. | Puede ser 0 (es opcional). |
| **¿Aplica?** | **Sí.** Evita datos erróneos sin volver lento el uso de la app, que es lo que buscan estudiantes de universidad y bachillerato. | **No, es demasiado rígida.** Exigir reglas de ortografía o limitar las duraciones puede frustrar al estudiante. | **No, se queda corta.** Deja pasar datos basura como `"a"`, sesiones de `1` minuto o de `9999` minutos. |

---

## 5. Paso 3: la refactorización con `Form`, `GlobalKey`, `TextFormField` y `validator`

### 5.1 Cómo está armada la solución
1. **`GlobalKey<FormState> _formKey = GlobalKey<FormState>();`**: es la llave que nos da acceso al estado del formulario y nos permite validar todos sus campos de una sola vez.
2. **`Form(key: _formKey, child: ...)`**: es el widget que agrupa los campos y se encarga de manejar la validación.
3. **`TextFormField`**: reemplaza al `TextField` y trae la propiedad `validator: (String? value) -> String?`. Si el dato está bien, devuelve `null`; si no, devuelve el mensaje de error que se le muestra al usuario.
4. **Validación al tocar "Guardar"**:
   ```dart
   if (_formKey.currentState!.validate()) {
     // Datos válidos en todos los campos, proceder a guardar
   }
   ```

### 5.2 Las reglas de validación (`validator`)

```dart
// 1. Validador para Título
String? validateTitle(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return 'Por favor ingresa el título de la tarea';
  }
  if (trimmed.length < 3) {
    return 'El título debe tener al menos 3 caracteres';
  }
  if (trimmed.length > 50) {
    return 'El título no puede superar los 50 caracteres';
  }
  return null;
}

// 2. Validador para Declaración de Objetivo
String? validateGoal(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return 'Declara qué quieres lograr en esta sesión';
  }
  if (trimmed.length < 10) {
    return 'Sé más específico: escribe al menos 10 caracteres';
  }
  return null;
}

// 3. Validador para Duración (minutos)
String? validateDuration(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return 'Ingresa la duración estimada';
  }
  final number = int.tryParse(trimmed);
  if (number == null) {
    return 'Ingresa un número entero válido (sin letras ni decimales)';
  }
  if (number < 5 || number > 180) {
    return 'La duración debe estar entre 5 y 180 minutos';
  }
  return null;
}
```

---

## 6. Casos de prueba

*"Comprueba que al menos tres campos rechacen datos inválidos antes de guardar."* Estos son los casos con los que lo comprobamos:

| Caso | Campo | Lo que escribimos | Lo que debería pasar | ¿Lo rechaza antes de guardar? |
| :--- | :--- | :--- | :--- | :--- |
| **TC-1** | Título | `"   "` (solo espacios) | Error: `"Por favor ingresa el título de la tarea"` | Sí |
| **TC-2** | Título | `"AB"` (2 caracteres) | Error: `"El título debe tener al menos 3 caracteres"` | Sí |
| **TC-3** | Objetivo | `""` (vacío) | Error: `"Declara qué quieres lograr en esta sesión"` | Sí |
| **TC-4** | Objetivo | `"leer"` (4 caracteres) | Error: `"Sé más específico: escribe al menos 10 caracteres"` | Sí |
| **TC-5** | Duración | `"veinticinco"` | Error: `"Ingresa un número entero válido (sin letras ni decimales)"` | Sí |
| **TC-6** | Duración | `"-10"` o `"3"` | Error: `"La duración debe estar entre 5 y 180 minutos"` | Sí |
| **TC-7** | Duración | `"200"` | Error: `"La duración debe estar entre 5 y 180 minutos"` | Sí |
| **TC-8** | Apps bloqueadas | 0 apps seleccionadas | Error o aviso: `"Debes seleccionar al menos una app para bloquear"` | Sí |
| **TC-9** | Todos | Título: `"Estudiar Cálculo III"`<br>Objetivo: `"Resolver los 5 ejercicios de integrales triples"`<br>Duración: `"45"`<br>Apps: `["Instagram", "TikTok"]` | El formulario es válido (`validate() == true`) y la tarea se guarda. | No, se guarda sin problema |
