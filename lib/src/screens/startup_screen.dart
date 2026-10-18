import 'package:flutter/material.dart';

import '../app_theme.dart';

class StartupScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const StartupScreen({super.key, required this.onFinished});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );
    _scale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.72, curve: Curves.easeOutBack),
    );
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.68, curve: Curves.easeOut),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        widget.onFinished();
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7FBF4), AppColors.softGreen],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _opacity,
            child: ScaleTransition(
              scale: _scale,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _AnimatedLogoMark(),
                  SizedBox(height: 20),
                  Text(
                    'Мій город',
                    style: TextStyle(
                      color: AppColors.darkGreen,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'Від насінини до врожаю',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedLogoMark extends StatelessWidget {
  const _AnimatedLogoMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(
            left: 24,
            top: 25,
            child: Icon(
              Icons.eco_rounded,
              color: AppColors.primaryBright,
              size: 46,
            ),
          ),
          const Positioned(
            right: 23,
            bottom: 25,
            child: Icon(
              Icons.eco_rounded,
              color: AppColors.darkGreen,
              size: 49,
            ),
          ),
        ],
      ),
    );
  }
}
