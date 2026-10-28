/// Frase motivacional del día para la pantalla de inicio.
///
/// Son frases cortas y propias de Floria, una por día de la semana.
/// Todo está en la app: funciona sin internet.
class DailyPhrases {
  DailyPhrases._();

  /// De lunes (índice 0) a domingo (índice 6).
  static const List<String> byWeekday = [
    'Un paso pequeño hoy vale más que un plan perfecto.',
    'Tu enfoque es un músculo: cada sesión lo fortalece.',
    'No tienes que hacerlo todo, solo lo siguiente.',
    'Lo que siembras hoy, florece mañana.',
    'Cierra la semana con una sesión más.',
    'Avanzar despacio también es avanzar.',
    'Una semana tranquila empieza con un plan sencillo.',
  ];

  /// Frase para el día de [date].
  static String forDate(DateTime date) => byWeekday[date.weekday - 1];
}
