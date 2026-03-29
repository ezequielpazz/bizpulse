import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth/login_screen.dart';
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
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Mini delay para que se vea el splash (branding)
    await Future<void>.delayed(const Duration(milliseconds: 800));

    final user = FirebaseAuth.instance.currentUser;

    // Si hay usuario logueado, nos aseguramos que tenga perfil en Firestore
    if (user != null) {
      try {
        final ref = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);

        final snap = await ref.get();
        if (!snap.exists) {
          await ref.set({
            'email': user.email,
            'displayName': user.displayName ?? '',
            'photoURL': user.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        // si falla no rompemos el flujo, lo podemos loguear en el futuro
        // print('error creando user profile: $e');
      }
    }

    if (!mounted) return;

    // Redirigir según login
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => user == null ? const LoginScreen() : const MainShell(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Pantalla de inicio BizPulse
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D0D0D), Color(0xFF1A1A1A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Fondo con imagen (si falta el asset no crashea)
          Positioned.fill(
            child: Image.asset(
              'assets/images/wall_bg.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          // Capa oscura encima
          Container(color: Colors.black54),
          // Logo + spinner
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 150,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.design_services,
                    size: 96,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 20),
                const CircularProgressIndicator(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
