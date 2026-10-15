import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../utils/form_validators.dart';
import 'common/enfoque_app_bar.dart';
import '../screens/active_session_screen.dart';

class TaskFormScreen extends StatefulWidget {
  /// Si es `false`, la barra inferior la dibuja el contenedor principal (MainShell).
  final bool showBottomNav;

  /// Acción al presionar el avatar del encabezado (abrir el perfil).
  final VoidCallback? onOpenProfile;

  const TaskFormScreen({
    super.key,
    this.showBottomNav = true,
    this.onOpenProfile,
  });

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  // Clave global para identificar y validar el Formulario
  final _formKey = GlobalKey<FormState>();

  // Controladores para los campos de texto
  late final TextEditingController _titleController;
  late final TextEditingController _goalController;
  late final TextEditingController _durationController;

  // Estados del formulario
  double _durationSliderValue = 45;
  String _selectedPriority = 'Alta';
  final List<String> _tags = ['Trabajo', 'Informe', 'Urgente'];
  bool _blockDistractions = true;
  String? _appsErrorMessage;

  // Lista de apps distractoras disponibles
  final List<BlockedAppItem> _availableApps = [
    BlockedAppItem(
        name: 'Instagram',
        packageName: 'com.instagram.android',
        isBlocked: true),
    BlockedAppItem(
        name: 'TikTok',
        packageName: 'com.zhiliaoapp.musically',
        isBlocked: true),
    BlockedAppItem(
        name: 'Twitter / X',
        packageName: 'com.twitter.android',
        isBlocked: true),
    BlockedAppItem(
        name: 'YouTube',
        packageName: 'com.google.android.youtube',
        isBlocked: true),
  ];

  // Presets rápidos de duración
  final List<int> _presetDurations = [15, 25, 45, 60];

  // Conteo en tiempo real de caracteres para retroalimentación visual
  int _titleLength = 32;
  int _goalLength = 85;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: 'Finalizar informe de métricas Q2');
    _goalController = TextEditingController(
      text:
          'Completar el análisis de retención de usuarios y redactar las 3 conclusiones clave.',
    );
    _durationController = TextEditingController(text: '45');

    _titleLength = _titleController.text.trim().length;
    _goalLength = _goalController.text.trim().length;

    _titleController.addListener(() {
      setState(() {
        _titleLength = _titleController.text.trim().length;
      });
    });

    _goalController.addListener(() {
      setState(() {
        _goalLength = _goalController.text.trim().length;
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _goalController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  // Sincroniza la duración seleccionada
  void _setDuration(int minutes) {
    setState(() {
      _durationSliderValue = minutes.toDouble().clamp(5, 180);
      _durationController.text = minutes.toString();
    });
  }

  // Obtiene nombres de las apps actualmente bloqueadas
  List<String> get _selectedAppNames => _availableApps
      .where((app) => app.isBlocked)
      .map((app) => app.name)
      .toList();

  // Acción de guardar y validar el formulario
  void _submitForm({required bool startFocusMode}) {
    // 1. Validar campos estándar mediante Form y GlobalKey
    final isFormValid = _formKey.currentState!.validate();

    // 2. Validar regla de apps bloqueadas
    final appsError = FormValidators.validateBlockedApps(
      isBlockingEnabled: _blockDistractions,
      apps: _selectedAppNames,
    );

    setState(() {
      _appsErrorMessage = appsError;
    });

    if (!isFormValid || appsError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Datos inválidos: Revisa los campos marcados en rojo antes de guardar.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFBA1A1A),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // Datos válidos: Crear objeto de tarea
    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      goal: _goalController.text.trim(),
      durationMinutes: int.parse(_durationController.text.trim()),
      priority: _selectedPriority,
      tags: List.from(_tags),
      blockDistractions: _blockDistractions,
      blockedApps: _selectedAppNames,
    );

    // "Guardar e Iniciar Enfoque" abre directamente la Sesión Activa;
    // "Solo Guardar en Lista" muestra el resumen de la tarea guardada.
    if (startFocusMode) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ActiveSessionScreen(task: task)),
      );
    } else {
      _showSuccessDialog(task, startFocusMode: false);
    }
  }

  // Muestra diálogo modal con los datos guardados de forma 100% offline
  void _showSuccessDialog(Task task, {required bool startFocusMode}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.check_circle,
                      color: Color(0xFF2E7D32), size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '¡Tarea Guardada Localmente!',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        startFocusMode
                            ? 'Iniciando sesión de enfoque de ${task.durationMinutes} min...'
                            : 'Almacenada con éxito en la lista offline',
                        style: TextStyle(
                            color: Colors.grey.shade700, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            _buildSummaryRow('Título', task.title),
            _buildSummaryRow('Objetivo', task.goal),
            _buildSummaryRow('Duración', '${task.durationMinutes} minutos'),
            _buildSummaryRow('Prioridad', task.priority),
            _buildSummaryRow(
                'Etiquetas', task.tags.map((t) => '#$t').join(', ')),
            _buildSummaryRow(
              'Bloqueo',
              task.blockDistractions
                  ? '${task.blockedApps.length} apps silenciadas (${task.blockedApps.join(', ')})'
                  : 'Desactivado',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3227C9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Entendido',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Color(0xFF5A5D72))),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, color: Color(0xFF1E1E2F))),
          ),
        ],
      ),
    );
  }

  // Diálogo interactivo para añadir etiqueta
  void _showAddTagDialog() {
    final tagCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Agregar Etiqueta',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: tagCtrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Ej. Matemáticas, Proyecto...',
            prefixText: '#',
            filled: true,
            fillColor: const Color(0xFFF6F7FB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final newTag = tagCtrl.text.trim().replaceAll('#', '');
              if (newTag.isNotEmpty && !_tags.contains(newTag)) {
                setState(() => _tags.add(newTag));
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3227C9),
              foregroundColor: Colors.white,
            ),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  // Diálogo para gestionar/seleccionar apps bloqueadas
  void _showManageAppsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.shield_outlined, color: Color(0xFF3227C9)),
                SizedBox(width: 8),
                Text('Apps a Bloquear',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _availableApps.length,
                itemBuilder: (context, index) {
                  final app = _availableApps[index];
                  return CheckboxListTile(
                    value: app.isBlocked,
                    activeColor: const Color(0xFF3227C9),
                    title: Text(app.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(app.packageName,
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey)),
                    onChanged: (val) {
                      setDialogState(() {
                        app.isBlocked = val ?? false;
                      });
                      setState(() {
                        // Sincronizar estado global
                        _appsErrorMessage = null;
                      });
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Listo',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9FE),
        elevation: 0,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nueva',
              style: TextStyle(
                color: Color(0xFF1E1E2F),
                fontWeight: FontWeight.w800,
                fontSize: 24,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF3227C9),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  '100% OFFLINE / LOCAL',
                  style: TextStyle(
                    color: Color(0xFF3227C9),
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: ProfileAvatarButton(onTap: widget.onOpenProfile),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado de la Sección
                _buildHeaderCard(),
                const SizedBox(height: 20),

                // 1. Campo: Título de la tarea
                _buildTitleField(),
                const SizedBox(height: 20),

                // 2. Campo: ¿Qué quieres lograr exactamente?
                _buildGoalField(),
                const SizedBox(height: 20),

                // 3. Campo: Duración de la sesión
                _buildDurationField(),
                const SizedBox(height: 20),

                // 4. Selector de Prioridad
                _buildPrioritySection(),
                const SizedBox(height: 20),

                // 5. Selector de Etiquetas
                _buildTagsSection(),
                const SizedBox(height: 20),

                // 6. Tarjeta: Bloqueo de distracciones
                _buildDistractionBlockCard(),
                const SizedBox(height: 28),

                // Botón Principal: Guardar e Iniciar Enfoque
                _buildPrimaryButton(),
                const SizedBox(height: 12),

                // Botón Secundario: Solo Guardar en Lista
                _buildSecondaryButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar:
          widget.showBottomNav ? _buildBottomNavigationBar() : null,
    );
  }

  // Tarjeta informativa "Crear Nueva Tarea"
  Widget _buildHeaderCard() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Crear Nueva Tarea',
                style: TextStyle(
                  color: Color(0xFF1E1E2F),
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.smartphone_outlined,
                      size: 14, color: Color(0xFF6B6E82)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Tus datos se guardan de forma local en tu dispositivo',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Color(0xFFECEEFD),
            shape: BoxShape.circle,
          ),
          child:
              const Icon(Icons.edit_note, color: Color(0xFF3227C9), size: 22),
        ),
      ],
    );
  }

  // 1. Campo: Título de la tarea con TextFormField y validación
  Widget _buildTitleField() {
    final isValid = _titleLength >= 3 && _titleLength <= 50;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: RichText(
                text: const TextSpan(
                  text: 'Título de la tarea ',
                  style: TextStyle(
                    color: Color(0xFF1E1E2F),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  children: [
                    TextSpan(
                      text: '*',
                      style: TextStyle(
                          color: Color(0xFFBA1A1A),
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const Icon(Icons.edit_note, color: Color(0xFF9E9EAF), size: 20),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          validator: FormValidators.validateTitle,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF1E1E2F),
              fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: 'Ej. Finalizar informe de métricas Q2',
            hintStyle: const TextStyle(color: Color(0xFFA5A7B8)),
            filled: true,
            fillColor: const Color(0xFFF3F4F9),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE9ECF8), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFF3227C9), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFBA1A1A), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              isValid ? Icons.check_circle_outline : Icons.info_outline,
              size: 15,
              color:
                  isValid ? const Color(0xFF3227C9) : const Color(0xFF757588),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                'Mínimo 3 caracteres (Actual: $_titleLength caracteres ${isValid ? '✓' : ''})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isValid
                      ? const Color(0xFF3227C9)
                      : const Color(0xFF757588),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 2. Campo: Objetivo detallado con TextFormField multilínea y validación
  Widget _buildGoalField() {
    final isValid = _goalLength >= 10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: RichText(
                text: const TextSpan(
                  text: '¿Qué quieres lograr exactamente? ',
                  style: TextStyle(
                    color: Color(0xFF1E1E2F),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  children: [
                    TextSpan(
                      text: '*',
                      style: TextStyle(
                          color: Color(0xFFBA1A1A),
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const Icon(Icons.outlined_flag, color: Color(0xFF9E9EAF), size: 18),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFECEEFD),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.place_outlined, size: 13, color: Color(0xFF3227C9)),
              SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Mínimo 10 caracteres para evitar metas vagas',
                  style: TextStyle(
                    color: Color(0xFF3227C9),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _goalController,
          validator: FormValidators.validateGoal,
          minLines: 3,
          maxLines: 4,
          style: const TextStyle(
              fontSize: 14, color: Color(0xFF1E1E2F), height: 1.4),
          decoration: InputDecoration(
            hintText:
                'Ej. Completar el análisis de retención de usuarios y redactar las 3 conclusiones clave.',
            hintStyle: const TextStyle(color: Color(0xFFA5A7B8)),
            filled: true,
            fillColor: const Color(0xFFF3F4F9),
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE9ECF8), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFF3227C9), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFBA1A1A), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              isValid ? Icons.check_circle_outline : Icons.info_outline,
              size: 15,
              color:
                  isValid ? const Color(0xFF3227C9) : const Color(0xFF757588),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                '$_goalLength caracteres ${isValid ? '✓ (Meta clara y definida)' : '(necesitas mínimo 10)'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isValid
                      ? const Color(0xFF3227C9)
                      : const Color(0xFF757588),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 3. Campo: Duración de la sesión con Presets, Slider y TextFormField sincronizado
  Widget _buildDurationField() {
    final currentMinutes =
        int.tryParse(_durationController.text) ?? _durationSliderValue.round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: RichText(
                text: const TextSpan(
                  text: 'Duración de la sesión ',
                  style: TextStyle(
                    color: Color(0xFF1E1E2F),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  children: [
                    TextSpan(
                      text: '*',
                      style: TextStyle(
                          color: Color(0xFFBA1A1A),
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFECEEFD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$currentMinutes minutos',
                style: const TextStyle(
                  color: Color(0xFF3227C9),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Fila de Presets rápidos
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presetDurations.map((mins) {
            final isSelected = currentMinutes == mins;
            final label = mins == 25 ? '25 min Pomodoro' : '$mins min';
            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _setDuration(mins),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF3227C9)
                      : const Color(0xFFF3F4F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF3227C9)
                        : const Color(0xFFE9ECF8),
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF1E1E2F),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),

        // Slider para ajuste fino
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF3227C9),
            inactiveTrackColor: const Color(0xFFE3E6F7),
            thumbColor: const Color(0xFF3227C9),
            overlayColor: const Color(0x223227C9),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
          ),
          child: Slider(
            value: _durationSliderValue,
            min: 5,
            max: 180,
            divisions: 35,
            onChanged: (val) {
              setState(() {
                _durationSliderValue = val;
                _durationController.text = val.round().toString();
              });
            },
          ),
        ),

        // Etiquetas inferiores del slider
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('5 min',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
            const Text(
              'Ajuste fino manual',
              style: TextStyle(
                  color: Color(0xFF1E1E2F),
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
            Text('180 min (3h)',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 10),

        // Entrada manual TextFormField vinculada para validación estricta
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined, size: 16, color: Color(0xFF5A5D72)),
                SizedBox(width: 6),
                Text(
                  'Entrada directa en minutos:',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF5A5D72)),
                ),
              ],
            ),
            SizedBox(
              width: 90,
              child: TextFormField(
                controller: _durationController,
                validator: FormValidators.validateDuration,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  filled: true,
                  fillColor: const Color(0xFFF3F4F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
                  ),
                ),
                onChanged: (val) {
                  final parsed = double.tryParse(val);
                  if (parsed != null && parsed >= 5 && parsed <= 180) {
                    setState(() {
                      _durationSliderValue = parsed;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 4. Selector de Prioridad (Alta, Media, Baja)
  Widget _buildPrioritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Prioridad',
              style: TextStyle(
                color: Color(0xFF1E1E2F),
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            Text(
              'Opcional',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildPriorityChip('Alta', const Color(0xFFBA1A1A), isDot: false),
            const SizedBox(width: 10),
            _buildPriorityChip('Media', const Color(0xFFF59E0B), isDot: true),
            const SizedBox(width: 10),
            _buildPriorityChip('Baja', const Color(0xFF10B981), isDot: true),
          ],
        ),
      ],
    );
  }

  Widget _buildPriorityChip(String label, Color color, {required bool isDot}) {
    final isSelected = _selectedPriority == label;
    final isAltaSelected = isSelected && label == 'Alta';

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _selectedPriority = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isAltaSelected
                ? const Color(0xFFBA1A1A)
                : isSelected
                    ? const Color(0xFFECEEFD)
                    : const Color(0xFFF3F4F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? (isAltaSelected
                      ? const Color(0xFFBA1A1A)
                      : const Color(0xFF3227C9))
                  : const Color(0xFFE9ECF8),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isDot) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color:
                      isAltaSelected ? Colors.white : const Color(0xFF1E1E2F),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 5. Selector de Etiquetas interactivas
  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Etiquetas',
          style: TextStyle(
            color: Color(0xFF1E1E2F),
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._tags.map(
              (tag) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFECEEFD),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD6DBF8)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '#$tag',
                      style: const TextStyle(
                        color: Color(0xFF3227C9),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => setState(() => _tags.remove(tag)),
                      child: const Icon(Icons.close,
                          size: 14, color: Color(0xFF3227C9)),
                    ),
                  ],
                ),
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _showAddTagDialog,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFFD6DBF8), style: BorderStyle.solid),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 14, color: Color(0xFF3227C9)),
                    SizedBox(width: 4),
                    Text(
                      'Agregar Tag',
                      style: TextStyle(
                        color: Color(0xFF3227C9),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 6. Tarjeta: Bloqueo de distracciones y selector de apps
  Widget _buildDistractionBlockCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _appsErrorMessage != null
              ? const Color(0xFFBA1A1A)
              : const Color(0xFFE9ECF8),
          width: _appsErrorMessage != null ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFECEEFD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.do_not_disturb_on_outlined,
                    color: Color(0xFF3227C9), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bloqueo de distracciones',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFF1E1E2F),
                      ),
                    ),
                    Text(
                      'Activar bloqueo estricto (Android Accessibility)',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _blockDistractions,
                activeThumbColor: const Color(0xFF3227C9),
                onChanged: (val) {
                  setState(() {
                    _blockDistractions = val;
                    if (!val) _appsErrorMessage = null;
                  });
                },
              ),
            ],
          ),
          if (_blockDistractions) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'APLICACIONES SILENCIADAS (${_selectedAppNames.length})',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Color(0xFF888B9E),
                  ),
                ),
                InkWell(
                  onTap: _showManageAppsDialog,
                  child: const Text(
                    'Gestionar',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3227C9),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.8,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: _availableApps.map((app) {
                return _buildAppItemTile(app);
              }).toList(),
            ),
            if (_appsErrorMessage != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.error_outline,
                      size: 14, color: Color(0xFFBA1A1A)),
                  const SizedBox(width: 6),
                  Text(
                    _appsErrorMessage!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFBA1A1A),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildAppItemTile(BlockedAppItem app) {
    IconData icon;
    Color iconColor;

    switch (app.name) {
      case 'Instagram':
        icon = Icons.camera_alt_outlined;
        iconColor = const Color(0xFFE1306C);
        break;
      case 'TikTok':
        icon = Icons.music_note_outlined;
        iconColor = const Color(0xFF25F4EE);
        break;
      case 'Twitter / X':
        icon = Icons.chat_bubble_outline;
        iconColor = const Color(0xFF1DA1F2);
        break;
      case 'YouTube':
        icon = Icons.play_arrow_outlined;
        iconColor = const Color(0xFFFF0000);
        break;
      default:
        icon = Icons.apps;
        iconColor = const Color(0xFF3227C9);
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() {
          app.isBlocked = !app.isBlocked;
          _appsErrorMessage = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: app.isBlocked ? const Color(0xFFF3F4F9) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: app.isBlocked
                ? const Color(0xFFD6DBF8)
                : const Color(0xFFE9ECF8),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 15, color: iconColor),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                app.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: app.isBlocked
                      ? const Color(0xFF1E1E2F)
                      : Colors.grey.shade500,
                ),
              ),
            ),
            Icon(
              app.isBlocked ? Icons.check_circle : Icons.circle_outlined,
              size: 14,
              color: app.isBlocked
                  ? const Color(0xFF3227C9)
                  : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  // Botón Principal: Guardar e Iniciar Enfoque
  Widget _buildPrimaryButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () => _submitForm(startFocusMode: true),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3227C9),
          foregroundColor: Colors.white,
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_outline, size: 20),
            SizedBox(width: 8),
            Text(
              'Guardar e Iniciar Enfoque',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // Botón Secundario: Solo Guardar en Lista
  Widget _buildSecondaryButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () => _submitForm(startFocusMode: false),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFECEEFD),
          foregroundColor: const Color(0xFF3227C9),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border_outlined, size: 19),
            SizedBox(width: 8),
            Text(
              'Solo Guardar en Lista',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // Barra de navegación inferior idéntica al diseño
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0F1F7), width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
              icon: Icons.check_circle_outline,
              label: 'Tareas',
              isSelected: false),
          _buildNavItem(
              icon: Icons.add_circle_outline, label: 'Nueva', isSelected: true),
          _buildNavItem(
              icon: Icons.adjust_outlined, label: 'Enfoque', isSelected: false),
          _buildNavItem(
              icon: Icons.show_chart_outlined,
              label: 'Historial',
              isSelected: false),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      {required IconData icon,
      required String label,
      required bool isSelected}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isSelected)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFECEEFD),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: const Color(0xFF3227C9), size: 22),
          )
        else
          Icon(icon, color: Colors.grey.shade500, size: 22),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFF3227C9) : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
