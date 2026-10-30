class DailyPhrases {
  DailyPhrases._();

  static const List<String> byWeekday = [
    'Un paso pequeño hoy vale más que un plan perfecto.',
    'Tu enfoque es un músculo: cada sesión lo fortalece.',
    'No tienes que hacerlo todo, solo lo siguiente.',
    'Lo que siembras hoy, florece mañana.',
    'Cierra la semana con una sesión más.',
    'Avanzar despacio también es avanzar.',
    'Una semana tranquila empieza con un plan sencillo.',
  ];

  static String forDate(DateTime date) => byWeekday[date.weekday - 1];
}
