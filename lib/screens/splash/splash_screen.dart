import 'dart:async';
import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../services/firebase_auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Color?> _colorAnim;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _colorAnim = TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ColorTween(begin: const Color(0xFFDA3BFF), end: const Color(0xFF00D9FF)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: const Color(0xFF00D9FF), end: const Color(0xFF00FF88)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: const Color(0xFF00FF88), end: const Color(0xFFDA3BFF)),
        weight: 20,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // After the animation delay, wait for FirebaseAuth to restore the persisted
    // user from disk by observing the first event from authStateChanges.
    // This is more reliable than checking `currentUser` synchronously.
    _navTimer = Timer(const Duration(seconds: 3), () async {
      if (!mounted) return;

      final auth = AuthService();

      try {
        // Wait for the first auth state event (restores persisted user if any).
        final user = await auth.authStateChanges.first.timeout(const Duration(seconds: 2));
        if (!mounted) return;
        if (user != null) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      } catch (e) {
        // If the stream times out or errors, fallback to checking currentUser.
        final fallbackUser = auth.currentUser;
        if (!mounted) return;
        if (fallbackUser != null) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      }
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0011),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final color = _colorAnim.value ?? const Color(0xFFDA3BFF);

            // gradient for shader fill
            final gradient = LinearGradient(
              colors: [color.withValues(alpha: 0.95), color.withValues(alpha: 0.6), Colors.white.withValues(alpha: 0.9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            );

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ensure 'Rizzume' renders on a single line on all devices by
                // constraining width and using FittedBox to scale down as needed.
                LayoutBuilder(builder: (context, constraints) {
                  final maxWidth = constraints.maxWidth * 0.92; // leave small side padding
                  return SizedBox(
                    width: maxWidth,
                    // allow the Stack to scale down to fit the available width
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 0, maxWidth: 1000),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Soft glow behind (bigger, blurred-like shadow)
                            Text(
                              'Rizzume',
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.visible,
                              style: TextStyle(
                                fontSize: 96,
                                fontWeight: FontWeight.w900,
                                color: color.withValues(alpha: 0.12),
                                shadows: [
                                  Shadow(color: color.withValues(alpha: 0.25), blurRadius: 40),
                                ],
                              ),
                            ),

                            // Tube stroke
                            Text(
                              'Rizzume',
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.visible,
                              style: TextStyle(
                                fontSize: 96,
                                fontWeight: FontWeight.w900,
                                foreground: Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = 6
                                  ..color = Colors.white.withValues(alpha: 0.12),
                                shadows: [
                                  Shadow(color: color.withValues(alpha: 0.35), blurRadius: 20),
                                ],
                              ),
                            ),

                            // Animated colored fill using ShaderMask
                            ShaderMask(
                              shaderCallback: (bounds) => gradient.createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                              blendMode: BlendMode.srcIn,
                              child: Text(
                                'Rizzume',
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.visible,
                                style: const TextStyle(
                                  fontSize: 96,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                            // Inner bright core to simulate neon tube
                            Text(
                              'Rizzume',
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.visible,
                              style: TextStyle(
                                fontSize: 96,
                                fontWeight: FontWeight.w900,
                                color: Colors.white.withValues(alpha: 0.05),
                                shadows: [
                                  Shadow(color: Colors.white.withValues(alpha: 0.9), blurRadius: 8),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 36),
                Text(
                  'Find your next opportunity or your next co-founder.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 16),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
