import 'package:flutter/material.dart';
import '../data/blockable_apps.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';

class AppPickerScreen extends StatefulWidget {
  final List<InstalledApp> apps;
  final Set<String> initialSelection;

  const AppPickerScreen(
      {super.key, required this.apps, required this.initialSelection});

  @override
  State<AppPickerScreen> createState() => _AppPickerScreenState();
}

class _AppPickerScreenState extends State<AppPickerScreen> {
  late final Set<String> _selected = {...widget.initialSelection};
  String _query = '';

  List<InstalledApp> get _visible {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.apps;
    return widget.apps.where((a) => a.name.toLowerCase().contains(q)).toList();
  }

  String? _lastPreset;

  void _selectRecommended() => setState(() {
        _lastPreset = 'Recomendadas';
        _selected
          ..clear()
          ..addAll(widget.apps
              .where((a) => a.isRecommended)
              .map((a) => a.packageName));
      });

  void _selectAll() => setState(() {
        _lastPreset = 'Todas';
        _selected
          ..clear()
          ..addAll(
              widget.apps.where((a) => !a.essential).map((a) => a.packageName));
      });

  Set<String> get _recommendedSet => widget.apps
      .where((a) => a.isRecommended)
      .map((a) => a.packageName)
      .toSet();
  Set<String> get _allSet =>
      widget.apps.where((a) => !a.essential).map((a) => a.packageName).toSet();

  String? get _activePreset {
    bool same(Set<String> other) =>
        _selected.length == other.length && _selected.containsAll(other);
    if (_lastPreset == 'Todas' && same(_allSet)) return 'Todas';
    if (same(_recommendedSet)) return 'Recomendadas';
    if (same(_allSet)) return 'Todas';
    return null;
  }

  Widget _presetChip(
      String label, IconData icon, VoidCallback onTap, AppPalette p) {
    final active = _activePreset == label;
    return ChoiceChip(
      selected: active,
      showCheckmark: false,
      avatar: Icon(icon,
          size: 18, color: active ? p.onPrimary : p.onSurfaceVariant),
      label: Text(label),
      labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: active ? p.onPrimary : p.onSurface),
      onSelected: (_) => onTap(),
    );
  }

  void _toggle(InstalledApp app) => setState(() {
        if (!_selected.remove(app.packageName)) _selected.add(app.packageName);
      });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final visible = _visible;

    return Scaffold(
      appBar: AppBar(title: const Text('Apps a bloquear')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar app',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _presetChip('Recomendadas', Icons.auto_awesome_outlined,
                        _selectRecommended, p),
                    _presetChip('Todas', Icons.done_all, _selectAll, p),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Ajustes y Teléfono nunca se bloquean. "Todas" tampoco marca las apps esenciales '
                  'como Mensajes y Reloj, pero puedes marcarlas a mano.',
                  style: t.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: Text('No hay apps con ese nombre',
                        style:
                            t.bodyMedium!.copyWith(color: p.onSurfaceVariant)),
                  )
                : ListView.builder(
                    itemCount: visible.length,
                    itemBuilder: (context, i) {
                      final app = visible[i];
                      return CheckboxListTile(
                        value: _selected.contains(app.packageName),
                        onChanged: (_) => _toggle(app),
                        secondary: app.icon != null
                            ? Image.memory(app.icon!,
                                width: 36,
                                height: 36,
                                gaplessPlayback: true,
                                excludeFromSemantics: true)
                            : CircleAvatar(
                                radius: 18,
                                backgroundColor: p.surfaceContainerHigh,
                                child: Text(
                                    app.name.isEmpty
                                        ? '?'
                                        : app.name.characters.first,
                                    style: t.titleSmall),
                              ),
                        title: Text(app.name),
                        subtitle: app.essential ? const Text('Esencial') : null,
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm,
              AppSpacing.screen, AppSpacing.md),
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(_selected),
            child: Text(_selected.isEmpty
                ? 'Listo (ninguna)'
                : 'Listo (${_selected.length})'),
          ),
        ),
      ),
    );
  }
}
