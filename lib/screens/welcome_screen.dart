import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/ui_feedback.dart';
import 'main_shell.dart';

/// Pantalla 1 del flujo: Bienvenida / acceso.
/// El usuario elige entrar con Google (pendiente) o en Modo Invitado (offline).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _enterAsGuest(BuildContext context) {
    showAppSnackBar(context, 'Iniciando en almacenamiento local seguro...');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  void _continueWithGoogle(BuildContext context) {
    // Fuera del alcance actual (la app es 100% offline). Solo se avisa.
    showAppSnackBar(
      context,
      'Conectando con Google... (disponible próximamente)',
      icon: Icons.cloud_outlined,
    );
  }

  void _showLegalSheet(BuildContext context, String title) {
    showModalBottomSheet(
      context: context,
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Floria funciona sin cuenta y sin conexión. Tus tareas, sesiones y '
              'rachas se guardan únicamente en este dispositivo. El texto legal '
              'completo se agregará más adelante.',
              style: TextStyle(color: AppColors.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Entendido',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 448),
              child: Column(
                children: [
                  _buildPrivacyBadge(),
                  const SizedBox(height: 24),
                  _buildHero(),
                  const SizedBox(height: 24),
                  const _ValuePill(
                    icon: Icons.verified_outlined,
                    title: 'Sin anuncios ni rastreadores',
                    subtitle: 'Tu concentración es el único objetivo',
                  ),
                  const SizedBox(height: 10),
                  const _ValuePill(
                    icon: Icons.wifi_off_rounded,
                    title: 'Funciona 100% sin internet',
                    subtitle: 'Acceso ilimitado en modo avión o viaje',
                  ),
                  const SizedBox(height: 10),
                  const _ValuePill(
                    icon: Icons.schedule_rounded,
                    title: 'Pomodoro & Sesiones locales',
                    subtitle:
                        'Métricas guardadas directamente en el dispositivo',
                  ),
                  const SizedBox(height: 32),
                  _buildGoogleButton(context),
                  const SizedBox(height: 6),
                  const Text(
                    'Sincroniza tus estadísticas y rachas en la nube si lo deseas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                  _buildDivider(),
                  const SizedBox(height: 24),
                  _buildGuestButton(context),
                  const SizedBox(height: 6),
                  const Text(
                    'Tus tareas, sesiones y rachas se guardan solo en la memoria de este teléfono.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 36),
                  _buildFooter(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_outlined,
              size: 14, color: AppColors.primary),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              'PRIVACIDAD Y MODO OFFLINE GARANTIZADOS',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [
                AppColors.primary,
                AppColors.primaryContainer,
                AppColors.secondaryContainer,
              ],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x333525CD),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.track_changes_rounded,
              color: Colors.white, size: 40),
        ),
        const SizedBox(height: 16),
        const Text(
          'Floria',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        const SizedBox(
          width: 300,
          child: Text(
            'Tu espacio de productividad profunda sin distracciones ni conexión obligatoria.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleButton(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: const Color(0x331E1B4B),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _continueWithGoogle(context),
        borderRadius: BorderRadius.circular(12),
        child: const SizedBox(
          height: 52,
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _GoogleLogo(),
              SizedBox(width: 12),
              Text(
                'Continuar con Google',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.surfaceVariant, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'o continúa sin cuenta',
            style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
        ),
        Expanded(child: Divider(color: AppColors.surfaceVariant, thickness: 1)),
      ],
    );
  }

  Widget _buildGuestButton(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => _enterAsGuest(context),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primaryFixed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.smartphone_outlined,
                        size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Modo Invitado (100% Offline)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          'Sin registros ni correos',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.primary),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -10,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Recomendado',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    const linkStyle =
        TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => _showLegalSheet(context, 'Términos de servicio'),
              child: const Text('Términos de servicio', style: linkStyle),
            ),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.outlineVariant,
                shape: BoxShape.circle,
              ),
            ),
            TextButton(
              onPressed: () =>
                  _showLegalSheet(context, 'Política de privacidad'),
              child: const Text('Política de privacidad', style: linkStyle),
            ),
          ],
        ),
        const Text(
          'Floria v1.0 • Offline Architecture',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
            color: AppColors.outline,
          ),
        ),
      ],
    );
  }
}

/// Tarjeta pequeña con un beneficio de la app.
class _ValuePill extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ValuePill({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "G" de Google dibujada con texto (evita agregar imágenes al proyecto).
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: Color(0xFF4285F4),
          height: 1.1,
        ),
      ),
    );
  }
}
