import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_tokens.dart';

/// The app's cold-open animation. Per product spec §32: not a static
/// "logo → 3s → Home", but a short, self-advancing sequence where the
/// mark scales in, a ring of accent dots settles into place around it,
/// and the wordmark fades up beneath — then it hands off to the setup
/// wizard on its own. Total runtime ~1.4s, well under a second of
/// perceived "waiting".
class OnboardingSplash extends StatefulWidget {
  final VoidCallback onFinished;
  const OnboardingSplash({super.key, required this.onFinished});

  @override
  State<OnboardingSplash> createState() => _OnboardingSplashState();
}

class _OnboardingSplashState extends State<OnboardingSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _markScale;
  late final Animation<double> _markOpacity;
  late final Animation<double> _ringProgress;
  late final Animation<double> _wordmarkOpacity;
  late final Animation<Offset> _wordmarkSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _markScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );
    _markOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );
    _ringProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 0.7, curve: Curves.easeOutCubic),
    );
    _wordmarkOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 0.85, curve: Curves.easeOut),
      ),
    );
    _wordmarkSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 220), () {
          if (mounted) widget.onFinished();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      key: const ValueKey('splash-content'),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Orbiting accent dots that settle into a ring —
                    // representing the app's many study surfaces
                    // (homework, notes, materials...) converging around
                    // the AI mark.
                    ...List.generate(6, (i) {
                      final angle = (i / 6) * 2 * math.pi;
                      final radius = 58.0 * _ringProgress.value;
                      return Transform.translate(
                        offset: Offset(
                          radius * math.cos(angle),
                          radius * math.sin(angle),
                        ),
                        child: Opacity(
                          opacity: _ringProgress.value,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i.isEven ? scheme.primary : scheme.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
                    }),
                    Opacity(
                      opacity: _markOpacity.value,
                      child: Transform.scale(
                        scale: _markScale.value,
                        child: Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: AppRadii.xlRadius,
                          ),
                          child: Icon(
                            PhosphorIconsFill.sparkle,
                            color: scheme.onPrimary,
                            size: AppIconSize.xl,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Opacity(
                opacity: _wordmarkOpacity.value,
                child: Transform.translate(
                  offset: Offset(0, _wordmarkSlide.value.dy * 20),
                  child: Text(
                    'StudAI',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: scheme.onSurface,
                        ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
