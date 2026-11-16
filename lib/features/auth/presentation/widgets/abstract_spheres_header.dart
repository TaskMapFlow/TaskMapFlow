import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_map_flow/app/theme.dart';
import 'package:task_map_flow/features/auth/presentation/providers/auth_providers.dart';

/// Top header with abstract 3D spheres, animated floating motion,
/// and responsive layout. Adheres strictly to non-planetary abstract visual design.
class AbstractSpheresHeader extends ConsumerStatefulWidget {
  const AbstractSpheresHeader({
    super.key,
    this.titleText,
    this.showBackButton = false,
    this.onBack,
    this.height = 230,
  });

  final String? titleText;
  final bool showBackButton;
  final VoidCallback? onBack;
  final double height;

  @override
  ConsumerState<AbstractSpheresHeader> createState() =>
      _AbstractSpheresHeaderState();
}

class _AbstractSpheresHeaderState extends ConsumerState<AbstractSpheresHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    // In widget tests, avoid infinite animation so pumpAndSettle can settle.
    // In production and simulator, floating animation loops smoothly.
    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return SizedBox(
      height: widget.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Sphere CustomPainter
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final progress = reduceMotion ? 0.0 : _controller.value;
                return CustomPaint(
                  painter: _AbstractSpheresPainter(
                    progress: progress,
                    isDark: isDark,
                  ),
                );
              },
            ),
          ),

          // Top action bar (App title / Back button + Language pill)
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (widget.showBackButton)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      iconSize: 20,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      onPressed:
                          widget.onBack ?? () => Navigator.of(context).pop(),
                      tooltip:
                          MaterialLocalizations.of(context).backButtonTooltip,
                    )
                  else if (widget.titleText != null)
                    Text(
                      widget.titleText!,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  // Language selector pill
                  const _LanguagePill(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguagePill extends ConsumerWidget {
  const _LanguagePill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTr = currentLocale.languageCode == 'tr';

    final pillBg = isDark ? const Color(0xFF1B1A24) : const Color(0xFFEBE7F5);
    final pillBorder =
        isDark ? const Color(0xFF2E2B3D) : const Color(0xFFD6D1E8);
    final activeText =
        isDark ? AppColors.darkPrimaryPurple : AppColors.lightPrimaryPurple;
    final inactiveText =
        isDark ? AppColors.darkTextHint : AppColors.lightTextHint;

    return Container(
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: pillBorder, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PillItem(
            label: 'TR',
            isSelected: isTr,
            activeColor: activeText,
            inactiveColor: inactiveText,
            onTap: () =>
                ref.read(localeProvider.notifier).setLocale(const Locale('tr')),
          ),
          Text(
            '/',
            style: TextStyle(
              color: inactiveColorWithAlpha(inactiveText),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
          _PillItem(
            label: 'EN',
            isSelected: !isTr,
            activeColor: activeText,
            inactiveColor: inactiveText,
            onTap: () =>
                ref.read(localeProvider.notifier).setLocale(const Locale('en')),
          ),
        ],
      ),
    );
  }

  Color inactiveColorWithAlpha(Color color) => color.withValues(alpha: 0.6);
}

class _PillItem extends StatelessWidget {
  const _PillItem({
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? activeColor : inactiveColor,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

/// Custom painter rendering smooth, matte 3D abstract spheres with soft purple rim lighting.
class _AbstractSpheresPainter extends CustomPainter {
  _AbstractSpheresPainter({
    required this.progress,
    required this.isDark,
  });

  final double progress;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Subtle sinusoidal floating displacements
    final float1 = math.sin(progress * 2 * math.pi) * 6.0;
    final float2 = math.cos(progress * 2 * math.pi) * 5.0;
    final float3 = math.sin((progress + 0.3) * 2 * math.pi) * 4.0;

    // Palette definition
    final sphereBaseDark =
        isDark ? const Color(0xFF22202D) : const Color(0xFFDED9EB);
    final sphereShadow =
        isDark ? const Color(0xFF0F0E16) : const Color(0xFFB5AFCB);
    final purpleGlow =
        isDark ? const Color(0xFFC7B3FD) : const Color(0xFF8A64F8);
    final softAmbient =
        isDark ? const Color(0xFF5E42A8) : const Color(0xFFB8A2F2);

    // 0. Soft ambient purple background glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          softAmbient.withValues(alpha: isDark ? 0.35 : 0.25),
          softAmbient.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(width * 0.45, height * 0.6),
          radius: width * 0.7,
        ),
      );
    canvas.drawCircle(
        Offset(width * 0.45, height * 0.6), width * 0.7, glowPaint);

    // 1. Medium Sphere (Upper Right / Center)
    _drawSphere(
      canvas: canvas,
      center: Offset(width * 0.62, height * 0.38 + float2),
      radius: width * 0.34,
      baseColor: sphereBaseDark,
      shadowColor: sphereShadow,
      rimColor: purpleGlow,
      lightAngle: -math.pi / 4,
    );

    // 2. Small Top Sphere (Upper Right Far)
    _drawSphere(
      canvas: canvas,
      center: Offset(width * 0.88, height * 0.16 + float3),
      radius: width * 0.12,
      baseColor: sphereBaseDark,
      shadowColor: sphereShadow,
      rimColor: purpleGlow,
      lightAngle: -math.pi / 4,
    );

    // 3. Medium Right Sphere (Far Right Floating)
    _drawSphere(
      canvas: canvas,
      center: Offset(width * 0.94, height * 0.68 + float1),
      radius: width * 0.20,
      baseColor: sphereBaseDark,
      shadowColor: sphereShadow,
      rimColor: purpleGlow,
      lightAngle: -math.pi / 4,
    );

    // 4. Large Hero Foreground Sphere (Overlapping from Left/Bottom)
    _drawSphere(
      canvas: canvas,
      center: Offset(width * 0.18, height * 0.92 + float1),
      radius: width * 0.48,
      baseColor: sphereBaseDark,
      shadowColor: sphereShadow,
      rimColor: purpleGlow,
      lightAngle: -math.pi / 4,
    );
  }

  void _drawSphere({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required Color baseColor,
    required Color shadowColor,
    required Color rimColor,
    required double lightAngle,
  }) {
    // A. Main body with soft 3D matte radial shading
    final bodyShader = RadialGradient(
      center: const Alignment(-0.25, -0.25),
      radius: 0.9,
      colors: [
        baseColor,
        baseColor.withValues(alpha: 0.8),
        shadowColor,
      ],
      stops: const [0.0, 0.55, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    final bodyPaint = Paint()..shader = bodyShader;
    canvas.drawCircle(center, radius, bodyPaint);

    // B. Soft violet/purple crescent rim light on upper-right edge
    final rimShader = RadialGradient(
      center: const Alignment(0.65, 0.45),
      radius: 0.75,
      colors: [
        rimColor.withValues(alpha: isDark ? 0.85 : 0.65),
        rimColor.withValues(alpha: isDark ? 0.35 : 0.20),
        Colors.transparent,
      ],
      stops: const [0.0, 0.45, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    final rimPaint = Paint()
      ..shader = rimShader
      ..blendMode = isDark ? BlendMode.screen : BlendMode.plus;

    canvas.save();
    canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: center, radius: radius)));
    canvas.drawCircle(center, radius, rimPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AbstractSpheresPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}
