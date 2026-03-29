import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/user_service.dart';
import '../shell/main_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _svc = UserService();

  String? _rubro;
  File? _logoFile;
  Color _primaryColor = const Color(0xFFE53935);
  String _fontStyle = 'moderna';
  bool _saving = false;

  static const _rubros = [
    'Barbería',
    'Peluquería',
    'Estética/Spa',
    'Uñas/Lash/Cejas',
    'Tatuajes',
    'Kinesiología',
    'Nutrición',
    'Entrenador personal',
    'Otro',
  ];

  static const _colors = [
    Color(0xFFE53935),
    Color(0xFFE91E63),
    Color(0xFF8E24AA),
    Color(0xFF3949AB),
    Color(0xFF1E88E5),
    Color(0xFF00897B),
    Color(0xFF43A047),
    Color(0xFFFFB300),
    Color(0xFFE64A19),
    Color(0xFF6D4C41),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── Logo picker ─────────────────────────────────────────────────────────────

  Future<void> _pickLogo() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      setState(() => _logoFile = File(picked.path));
    }
  }

  // ── Upload & save ───────────────────────────────────────────────────────────

  Future<String?> _uploadLogo(String uid) async {
    if (_logoFile == null) return null;
    final ref = FirebaseStorage.instance.ref('users/$uid/logo');
    await ref.putFile(_logoFile!);
    return ref.getDownloadURL();
  }

  String _colorToHex(Color c) {
    final hex = c.toARGB32().toRadixString(16).padLeft(8, '0');
    return '#${hex.substring(2).toUpperCase()}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final logoUrl = await _uploadLogo(uid);
      await _svc.saveOnboarding(
        uid: uid,
        businessName: _nameCtrl.text.trim(),
        rubro: _rubro!,
        logoUrl: logoUrl,
        primaryColor: _colorToHex(_primaryColor),
        fontStyle: _fontStyle,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (_) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurá tu negocio'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Estos datos aparecerán en tu perfil y personalizarán la app.',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 24),

              // ── Logo ───────────────────────────────────────────────────────
              _sectionLabel('Logo del negocio'),
              Center(
                child: GestureDetector(
                  onTap: _pickLogo,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundColor: const Color(0xFF2A2A2A),
                        backgroundImage: _logoFile != null
                            ? FileImage(_logoFile!)
                            : null,
                        child: _logoFile == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo,
                                    size: 28,
                                    color: Colors.white54,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Elegir',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                      if (_logoFile != null)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: _primaryColor,
                            child: const Icon(
                              Icons.edit,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Nombre del negocio ─────────────────────────────────────────
              _sectionLabel('Nombre del negocio *'),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'Ej: Barbería El Caudillo',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingresá el nombre del negocio'
                    : null,
              ),
              const SizedBox(height: 20),

              // ── Rubro ──────────────────────────────────────────────────────
              _sectionLabel('Rubro *'),
              DropdownButtonFormField<String>(
                initialValue: _rubro,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                hint: const Text('Seleccioná tu rubro'),
                isExpanded: true,
                items: _rubros
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => _rubro = v),
                validator: (v) => v == null ? 'Seleccioná un rubro' : null,
              ),
              const SizedBox(height: 24),

              // ── Color primario ─────────────────────────────────────────────
              _sectionLabel('Color principal'),
              SizedBox(
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _colors.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final c = _colors[i];
                    final selected = c.toARGB32() == _primaryColor.toARGB32();
                    return GestureDetector(
                      onTap: () => setState(() => _primaryColor = c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: selected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: c.withValues(alpha: 0.6),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                        child: selected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // ── Tipografía ─────────────────────────────────────────────────
              _sectionLabel('Tipografía'),
              Row(
                children: [
                  _fontCard('moderna', 'Moderna', FontWeight.w400, null),
                  const SizedBox(width: 10),
                  _fontCard('clasica', 'Clásica', FontWeight.w400, 'serif'),
                  const SizedBox(width: 10),
                  _fontCard('negrita', 'Negrita', FontWeight.w900, null),
                ],
              ),
              const SizedBox(height: 36),

              // ── Guardar ────────────────────────────────────────────────────
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Guardar y comenzar',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Colors.white70,
      ),
    ),
  );

  Widget _fontCard(
    String value,
    String label,
    FontWeight weight,
    String? fontFamily,
  ) {
    final selected = _fontStyle == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _fontStyle = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? _primaryColor.withValues(alpha: 0.15)
                : const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? _primaryColor : Colors.white12,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                'Aa',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: weight,
                  fontFamily: fontFamily,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
