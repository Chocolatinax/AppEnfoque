class FormValidators {
  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa el título de la tarea';
    }
    final trimmed = value.trim();
    if (trimmed.length < 3) {
      return 'El título debe tener al menos 3 caracteres';
    }
    if (trimmed.length > 50) {
      return 'El título no puede superar los 50 caracteres';
    }
    return null;
  }

  static const int minGoalWords = 4;
  static const int minGoalChars = 15;

  static String? validateGoal(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Declara qué quieres lograr en esta sesión';
    }
    final trimmed = value.trim();
    final words =
        trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    if (words < minGoalWords) {
      return 'Escribe al menos $minGoalWords palabras';
    }
    if (trimmed.length < minGoalChars) {
      return 'Escribe al menos $minGoalChars caracteres';
    }
    if (trimmed.length > 300) {
      return 'El objetivo no puede superar los 300 caracteres';
    }
    return null;
  }

  static String? validateDuration(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa la duración estimada';
    }
    final trimmed = value.trim();
    final number = int.tryParse(trimmed);
    if (number == null) {
      return 'Ingresa un número entero válido (sin letras ni decimales)';
    }
    if (number < 5 || number > 180) {
      return 'La duración debe estar entre 5 y 180 minutos';
    }
    return null;
  }

  static String? validateBlockedApps({
    required bool isBlockingEnabled,
    required List<String> apps,
  }) {
    if (isBlockingEnabled && apps.isEmpty) {
      return 'Debes seleccionar al menos una app para bloquear';
    }
    return null;
  }
}
