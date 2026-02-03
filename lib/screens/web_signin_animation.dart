import 'package:flutter/material.dart';

/// Web sign-in hero animation: car drives in, passes behind logo, transitions to dollar.
class WebSigninAnimation extends StatefulWidget {
  final double height;

  const WebSigninAnimation({super.key, this.height = 200});

  @override
  State<WebSigninAnimation> createState() => _WebSigninAnimationState();
}

class _WebSigninAnimationState extends State<WebSigninAnimation>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 4200);
  static const _phase1End = 0.32;
  static const _phase2End = 0.62;
  static const _carWidth = 160.0;

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration)
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          double carOffset;
          if (t <= _phase1End) {
            carOffset = -3.0 + (3.0 * (t / _phase1End));
          } else if (t <= _phase2End) {
            final phase2T = (t - _phase1End) / (_phase2End - _phase1End);
            carOffset = phase2T * 2.0;
          } else {
            carOffset = 2.0;
          }
          final phase3T =
              t <= _phase2End ? 0.0 : (t - _phase2End) / (1.0 - _phase2End);
          final carOpacity = (1.0 - phase3T).clamp(0.0, 1.0);
          final carScale = 1.0 - (0.5 * phase3T);
          final dollarOpacity = phase3T.clamp(0.0, 1.0);
          final dollarScale = 0.5 + (0.5 * phase3T);

          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Center(
                child: FractionalTranslation(
                  translation: Offset(carOffset, 0),
                  child: Opacity(
                    opacity: carOpacity,
                    child: Transform.scale(
                      scale: carScale,
                      child: Image.asset(
                        'rwacar.png',
                        fit: BoxFit.contain,
                        height: 120,
                        width: _carWidth,
                        errorBuilder: (_, __, ___) =>
                            const SizedBox(height: 120, width: 160),
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: Image.asset(
                  'RWAlogo.png',
                  fit: BoxFit.contain,
                  height: 100,
                  errorBuilder: (_, __, ___) =>
                      const SizedBox(height: 100, width: 140),
                ),
              ),
              Center(
                child: Transform.translate(
                  offset: Offset(2 * _carWidth, 0),
                  child: Opacity(
                    opacity: dollarOpacity,
                    child: Transform.scale(
                      scale: dollarScale,
                      child: Image.asset(
                        'dollarsign.png',
                        fit: BoxFit.contain,
                        height: 80,
                        errorBuilder: (_, __, ___) =>
                            const SizedBox(height: 80, width: 60),
                      ),
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
