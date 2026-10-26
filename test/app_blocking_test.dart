import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enfoque_app/screens/app_picker_screen.dart';
import 'package:enfoque_app/theme/app_theme.dart';
import 'package:enfoque_app/data/blockable_apps.dart';
import 'package:enfoque_app/services/app_blocker.dart';

/// Pruebas de la parte Flutter del bloqueo de apps.
/// (El Servicio de Accesibilidad nativo se prueba en un emulador o teléfono Android.)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Catálogo de apps bloqueables', () {
    test('Traduce los nombres de la tarea a paquetes de Android', () {
      final packages = BlockableApps.packagesFor(['Instagram', 'TikTok']);
      expect(packages, contains('com.instagram.android'));
      // TikTok tiene dos paquetes según el país; se bloquean ambos
      expect(
          packages,
          containsAll(
              ['com.zhiliaoapp.musically', 'com.ss.android.ugc.trill']));
      expect(packages, isNot(contains('com.google.android.youtube')));
    });

    test('Ignora nombres que no están en el catálogo', () {
      expect(BlockableApps.packagesFor(['App inventada']), isEmpty);
    });

    test('Obtiene el nombre visible a partir del paquete', () {
      expect(BlockableApps.nameForPackage('com.google.android.youtube'),
          'YouTube');
      expect(
          BlockableApps.nameForPackage('com.ss.android.ugc.trill'), 'TikTok');
      expect(BlockableApps.nameForPackage('com.desconocida'), 'Esta app');
    });

    test('Las apps marcadas por defecto existen en el catálogo', () {
      final names = BlockableApps.all.map((a) => a.name);
      expect(names, containsAll(BlockableApps.defaultSelection));
    });
  });

  group('AppBlocker fuera de Android', () {
    test('No está disponible y sus llamadas no fallan', () async {
      final blocker = AppBlocker.instance;
      // Las pruebas corren en la computadora (no Android)
      expect(blocker.isSupported, isFalse);
      expect(await blocker.isEnabled(), isFalse);
      await blocker.start(['com.instagram.android'],
          until: DateTime.now().add(const Duration(minutes: 25)));
      expect(await blocker.consumePendingBlockedApp(), isNull);
      await blocker.stop();
      await blocker.openSettings();
    });
  });

  group('Pantalla de apps a bloquear', () {
    const apps = [
      InstalledApp(name: 'Instagram', packageName: 'com.instagram.android'),
      InstalledApp(
          name: 'Calculadora', packageName: 'com.google.android.calculator'),
      InstalledApp(
          name: 'Teléfono',
          packageName: 'com.google.android.dialer',
          essential: true),
    ];

    Future<Set<String>?> openPicker(
        WidgetTester tester, Future<void> Function() actions) async {
      Set<String>? result;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await Navigator.of(context).push<Set<String>>(
                MaterialPageRoute(
                    builder: (_) => const AppPickerScreen(
                        apps: apps, initialSelection: {})),
              );
            },
            child: const Text('abrir'),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await actions();
      await tester.tap(find.textContaining('Listo'));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('"Recomendadas" marca solo las redes sociales instaladas',
        (tester) async {
      final result = await openPicker(tester, () async {
        await tester.tap(find.text('Recomendadas'));
        await tester.pumpAndSettle();
      });
      expect(result, {'com.instagram.android'});
    });

    testWidgets('"Todas" marca todo menos las apps esenciales', (tester) async {
      final result = await openPicker(tester, () async {
        await tester.tap(find.text('Todas'));
        await tester.pumpAndSettle();
      });
      expect(
          result, {'com.instagram.android', 'com.google.android.calculator'});
    });

    testWidgets('El buscador filtra la lista y se puede marcar a mano',
        (tester) async {
      final result = await openPicker(tester, () async {
        await tester.enterText(find.byType(TextField), 'telé');
        await tester.pumpAndSettle();
        expect(find.text('Instagram'), findsNothing);
        await tester.tap(find.text('Teléfono'));
        await tester.pumpAndSettle();
      });
      expect(result, {'com.google.android.dialer'});
    });
  });
}
