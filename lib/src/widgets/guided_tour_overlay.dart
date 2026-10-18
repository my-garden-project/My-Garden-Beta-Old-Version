import 'package:flutter/material.dart';

import '../app_theme.dart';

class GuidedTourStep {
  final GlobalKey targetKey;
  final IconData icon;
  final String title;
  final String description;

  const GuidedTourStep({
    required this.targetKey,
    required this.icon,
    required this.title,
    required this.description,
  });
}

Future<void> showGuidedTour(
  BuildContext context, {
  required List<GuidedTourStep> steps,
}) {
  if (steps.isEmpty) return Future.value();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 220),
    transitionBuilder: (context, animation, _, child) => FadeTransition(
      opacity: animation,
      child: child,
    ),
    pageBuilder: (_, __, ___) => _GuidedTourOverlay(steps: steps),
  );
}

class _GuidedTourOverlay extends StatefulWidget {
  final List<GuidedTourStep> steps;

  const _GuidedTourOverlay({required this.steps});

  @override
  State<_GuidedTourOverlay> createState() => _GuidedTourOverlayState();
}

class _GuidedTourOverlayState extends State<_GuidedTourOverlay> {
  int _index = 0;

  Rect _targetRect(BuildContext context) {
    final targetContext = widget.steps[_index].targetKey.currentContext;
    final box = targetContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      final size = MediaQuery.sizeOf(context);
      return Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: 96,
        height: 96,
      );
    }
    final offset = box.localToGlobal(Offset.zero);
    return (offset & box.size).inflate(7);
  }

  void _next() {
    if (_index == widget.steps.length - 1) {
      Navigator.pop(context);
      return;
    }
    setState(() => _index += 1);
  }

  @override
  Widget build(BuildContext context) {
    final target = _targetRect(context);
    final screen = MediaQuery.sizeOf(context);
    final step = widget.steps[_index];
    final targetNearBottom = target.center.dy > screen.height * 0.58;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _SpotlightPainter(target),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: targetNearBottom ? 32 : null,
            bottom: targetNearBottom ? null : 32,
            child: SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.08),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _TourCard(
                  key: ValueKey(_index),
                  step: step,
                  current: _index + 1,
                  total: widget.steps.length,
                  onSkip: () => Navigator.pop(context),
                  onNext: _next,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TourCard extends StatelessWidget {
  final GuidedTourStep step;
  final int current;
  final int total;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  const _TourCard({
    super.key,
    required this.step,
    required this.current,
    required this.total,
    required this.onSkip,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 14,
      margin: EdgeInsets.zero,
      shadowColor: Colors.black45,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.softGreen,
                  child: Icon(step.icon, color: AppColors.primary),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    step.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '$current / $total',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(step.description, style: const TextStyle(height: 1.45)),
            const SizedBox(height: 14),
            Row(
              children: [
                TextButton(onPressed: onSkip, child: const Text('Пропустити')),
                const Spacer(),
                FilledButton.icon(
                  key: const Key('guided-tour-next'),
                  onPressed: onNext,
                  icon: Icon(
                    current == total
                        ? Icons.check_rounded
                        : Icons.arrow_forward_rounded,
                  ),
                  label: Text(current == total ? 'Готово' : 'Далі'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect target;

  const _SpotlightPainter(this.target);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xC9000000),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(target, const Radius.circular(18)),
      Paint()..blendMode = BlendMode.clear,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      oldDelegate.target != target;
}
