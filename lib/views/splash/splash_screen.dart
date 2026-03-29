import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/app_settings.dart';
import '../auth/login_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../shell/main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _goNext();
  }

  Future<void> _goNext() async {
    try {
      // Auth y timer corren en paralelo — pantalla visible mínimo 2 segundos
      final authFuture = FirebaseAuth.instance.authStateChanges().first;
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      final user = await authFuture;
      if (!mounted) return;

      if (user == null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return;
      }

      final done = context.read<AppSettingsProvider>().onboardingDone;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => done ? const MainShell() : const OnboardingScreen(),
        ),
      );
    } catch (e, st) {
      debugPrint('[Splash] Error en _goNext: $e\n$st');
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icon/app_icon.png', width: 180),
            const SizedBox(height: 24),
            const Text(
              'BizPulse',
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'El pulso de tu negocio',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
