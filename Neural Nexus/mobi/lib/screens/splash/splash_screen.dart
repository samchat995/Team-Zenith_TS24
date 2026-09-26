import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../database/database_helper.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _textFade;

  Timer? _maxSplashTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    // 1. Initialize 2-second smooth visual animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.10, 0.65, curve: Curves.easeIn)),
    );

    _logoScale = Tween<double>(begin: 0.88, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.20, 0.85, curve: Curves.easeOutCubic)),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.55, 1.0, curve: Curves.easeIn)),
    );

    _controller.forward();

    // 2. Perform safe, non-blocking asynchronous startup initialization
    _runStartupSequence();

    // 3. Absolute timeout safety guard: strictly navigate after ~2050ms
    _maxSplashTimer = Timer(const Duration(milliseconds: 2050), () {
      _navigateToLogin('timeout_timer');
    });
  }

  Future<void> _runStartupSequence() async {
    debugPrint('[Startup] START: Beginning Neural Nexus initialization sequence...');

    try {
      // Step A: Storage / Database check with timeout
      debugPrint('[Startup] TRY: Verifying local persistence layer...');
      await Future.any([
        DatabaseHelper.instance.database,
        Future.delayed(const Duration(milliseconds: 800)),
      ]).catchError((e) {
        debugPrint('[Startup] FALLBACK: Persistence check error handled: $e');
        return null;
      });
      debugPrint('[Startup] SUCCESS: Local persistence ready.');

      // Step B: Backend health check with short 1.2s timeout (offline-first design)
      final backendUrl = kIsWeb ? 'http://127.0.0.1:8000/' : 'http://10.0.2.2:8000/';
      debugPrint('[Startup] TRY: Checking backend connectivity at $backendUrl...');
      try {
        final res = await http.get(Uri.parse(backendUrl)).timeout(
          const Duration(milliseconds: 1200),
          onTimeout: () => http.Response('timeout', 408),
        );
        if (res.statusCode == 200) {
          debugPrint('[Startup] SUCCESS: Backend is ONLINE.');
        } else {
          debugPrint('[Startup] FALLBACK: Backend returned ${res.statusCode}. Continuing in offline/demo mode.');
        }
      } catch (netErr) {
        debugPrint('[Startup] FALLBACK: Backend unavailable ($netErr). Continuing in offline/demo mode.');
      }
    } catch (startupErr) {
      debugPrint('[Startup] ERROR HANDLING: Handled startup exception safely: $startupErr');
    } finally {
      debugPrint('[Startup] CONTINUE: Startup sequence complete.');
    }
  }

  void _navigateToLogin(String source) {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _maxSplashTimer?.cancel();
    debugPrint('[Startup] Navigating to LoginScreen (source: $source)');

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }

  @override
  void dispose() {
    _maxSplashTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F2), // Warm soothing backdrop matching logo canvas
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Official Neural Nexus Logo Asset with Fade + Subtle Scale
                    FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: Container(
                          width: 220,
                          height: 220,
                          alignment: Alignment.center,
                          child: Image.asset(
                            'assets/images/neural_nexus_logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              // Elderly-friendly fallback in case asset load has platform issues
                              return const Center(
                                child: Icon(
                                  Icons.favorite_rounded,
                                  size: 72,
                                  color: Color(0xFF0D9488),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Elegant Tagline with Fade
                    FadeTransition(
                      opacity: _textFade,
                      child: Column(
                        children: const [
                          Text(
                            'NEURAL NEXUS',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Small Steps. Stronger Memories.',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0D9488),
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(height: 16),
                          SizedBox(
                            width: 32,
                            height: 3,
                            child: LinearProgressIndicator(
                              backgroundColor: Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
