import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../onboarding/onboarding_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose(); _pass.dispose(); _pass2.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecor(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    border: const OutlineInputBorder(),
  );

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService().signUp(_email.text.trim(), _pass.text.trim());
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      final msg = e.message ?? 'No se pudo crear la cuenta';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error inesperado')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(children: [
              TextFormField(controller: _email, keyboardType: TextInputType.emailAddress,
                decoration: _fieldDecor('Email'),
                validator: (v) => (v==null || v.trim().isEmpty) ? 'Ingresá tu email' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _pass, obscureText: true,
                decoration: _fieldDecor('Contraseña'),
                validator: (v) => (v==null || v.length<6) ? 'Mínimo 6 caracteres' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _pass2, obscureText: true,
                decoration: _fieldDecor('Repetir contraseña'),
                validator: (v) => (v != _pass.text) ? 'Las contraseñas no coinciden' : null),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _signUp,
                  child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Crear cuenta'),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
