import 'package:flutter_test/flutter_test.dart';
import 'package:enfoque_app/utils/plural.dart';

void main() {
  test('Usa singular solo con 1', () {
    expect(plural(1, 'ronda', 'rondas'), '1 ronda');
    expect(plural(2, 'ronda', 'rondas'), '2 rondas');
    expect(plural(0, 'día', 'días'), '0 días');
    expect(plural(1, 'día', 'días'), '1 día');
  });
}
