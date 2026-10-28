import 'package:flutter_test/flutter_test.dart';
import 'package:enfoque_app/data/daily_phrases.dart';

void main() {
  test('Hay una frase distinta para cada día de la semana', () {
    expect(DailyPhrases.byWeekday, hasLength(7));
    expect(DailyPhrases.byWeekday.toSet(), hasLength(7));
  });

  test('Elige la frase según el día', () {
    // 26 de octubre de 2026 es lunes y el 1 de noviembre, domingo
    expect(DailyPhrases.forDate(DateTime(2026, 10, 26)),
        DailyPhrases.byWeekday.first);
    expect(DailyPhrases.forDate(DateTime(2026, 11, 1)),
        DailyPhrases.byWeekday.last);
  });

  test('Las frases son cortas (una o dos líneas en el teléfono)', () {
    for (final phrase in DailyPhrases.byWeekday) {
      expect(phrase.length, lessThanOrEqualTo(60), reason: phrase);
    }
  });
}
