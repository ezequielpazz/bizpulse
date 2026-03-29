import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../providers/app_settings.dart';
import '../../services/service_catalog_service.dart';
import '../../models/service_model.dart';
import '../shell/main_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Step 2: Business Type
  String? _selectedBusinessType;
  final List<String> _businessTypes = [
    'Peluquería', 'Barbería', 'Estética', 'Tatuaje', 'Uñas', 'Masajes',
    'Clínica', 'Psicología', 'Veterinaria', 'Abogado', 'Contador', 'Otro',
  ];

  // Step 3: Currency
  String? _selectedCurrency;
  final List<Map<String, String>> _currencies = [
    {'code': 'ARS', 'symbol': r'$'},
    {'code': 'MXN', 'symbol': r'$'},
    {'code': 'CLP', 'symbol': r'$'},
    {'code': 'COP', 'symbol': r'$'},
    {'code': 'USD', 'symbol': r'$'},
    {'code': 'BRL', 'symbol': r'R$'},
    {'code': 'PEN', 'symbol': 'S/'},
    {'code': 'UYU', 'symbol': r'$U'},
  ];

  // Step 4: First Service
  final _serviceNameCtrl = TextEditingController();
  final _serviceDurationCtrl = TextEditingController(text: '30');
  final _servicePriceCtrl = TextEditingController();

  // Step 5: Primary Color
  Color _selectedColor = Colors.redAccent;
  final List<Color> _presetColors = [
    Colors.redAccent,
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.purpleAccent,
    Colors.tealAccent,
  ];

  static const Map<String, List<Map<String, dynamic>>> _templates = {
    'Peluquería': [
      {'name': 'Corte de cabello', 'duration': 30, 'price': 0, 'category': 'Corte'},
      {'name': 'Coloración', 'duration': 90, 'price': 0, 'category': 'Color'},
      {'name': 'Brushing', 'duration': 45, 'price': 0, 'category': 'Styling'},
      {'name': 'Keratina', 'duration': 120, 'price': 0, 'category': 'Tratamiento'},
    ],
    'Barbería': [
      {'name': 'Corte clásico', 'duration': 30, 'price': 0, 'category': 'Corte'},
      {'name': 'Afeitado con navaja', 'duration': 30, 'price': 0, 'category': 'Afeitado'},
      {'name': 'Perfilado de barba', 'duration': 20, 'price': 0, 'category': 'Barba'},
      {'name': 'Corte + Barba', 'duration': 45, 'price': 0, 'category': 'Combo'},
    ],
    'Estética': [
      {'name': 'Limpieza facial', 'duration': 60, 'price': 0, 'category': 'Facial'},
      {'name': 'Depilación cejas', 'duration': 15, 'price': 0, 'category': 'Depilación'},
      {'name': 'Masaje relajante', 'duration': 60, 'price': 0, 'category': 'Masajes'},
      {'name': 'Hidratación profunda', 'duration': 45, 'price': 0, 'category': 'Tratamiento'},
    ],
    'Tatuaje': [
      {'name': 'Consulta y diseño', 'duration': 60, 'price': 0, 'category': 'Consulta'},
      {'name': 'Sesión pequeña', 'duration': 120, 'price': 0, 'category': 'Tatuaje'},
      {'name': 'Sesión media', 'duration': 240, 'price': 0, 'category': 'Tatuaje'},
      {'name': 'Sesión completa', 'duration': 480, 'price': 0, 'category': 'Tatuaje'},
    ],
    'Uñas': [
      {'name': 'Esmaltado simple', 'duration': 30, 'price': 0, 'category': 'Esmaltado'},
      {'name': 'Esmaltado semipermanente', 'duration': 45, 'price': 0, 'category': 'Esmaltado'},
      {'name': 'Acrílico completo', 'duration': 90, 'price': 0, 'category': 'Acrílico'},
      {'name': 'Nail art', 'duration': 60, 'price': 0, 'category': 'Arte'},
    ],
    'Masajes': [
      {'name': 'Masaje relajante', 'duration': 60, 'price': 0, 'category': 'Relajación'},
      {'name': 'Masaje descontracturante', 'duration': 60, 'price': 0, 'category': 'Terapéutico'},
      {'name': 'Masaje con piedras', 'duration': 75, 'price': 0, 'category': 'Premium'},
      {'name': 'Reflexología', 'duration': 45, 'price': 0, 'category': 'Terapéutico'},
    ],
    'Clínica': [
      {'name': 'Consulta general', 'duration': 30, 'price': 0, 'category': 'Consulta'},
      {'name': 'Control', 'duration': 20, 'price': 0, 'category': 'Control'},
      {'name': 'Urgencia', 'duration': 45, 'price': 0, 'category': 'Urgencia'},
    ],
    'Psicología': [
      {'name': 'Sesión individual', 'duration': 50, 'price': 0, 'category': 'Terapia'},
      {'name': 'Sesión de pareja', 'duration': 80, 'price': 0, 'category': 'Terapia'},
      {'name': 'Evaluación', 'duration': 90, 'price': 0, 'category': 'Evaluación'},
    ],
    'Veterinaria': [
      {'name': 'Consulta general', 'duration': 30, 'price': 0, 'category': 'Consulta'},
      {'name': 'Vacunación', 'duration': 15, 'price': 0, 'category': 'Preventivo'},
      {'name': 'Cirugía menor', 'duration': 60, 'price': 0, 'category': 'Cirugía'},
    ],
  };

  @override
  void dispose() {
    _pageController.dispose();
    _serviceNameCtrl.dispose();
    _serviceDurationCtrl.dispose();
    _servicePriceCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final settings = context.read<AppSettingsProvider>();
    
    // Save Step 2
    if (_selectedBusinessType != null) {
      await settings.setBusinessType(_selectedBusinessType!);
    }

    // Save Step 3
    if (_selectedCurrency != null) {
      final curr = _currencies.firstWhere((c) => c['code'] == _selectedCurrency);
      await settings.setCurrencyCode(curr['code']!);
      await settings.setCurrencySymbol(curr['symbol']!);
    }

    // Auto-crear plantillas de servicios si el catálogo está vacío
    if (_selectedBusinessType != null) {
      final svc = ServiceCatalogService();
      final existing = await svc.getAll();
      if (existing.isEmpty) {
        final templates = _templates[_selectedBusinessType!] ?? [];
        for (int i = 0; i < templates.length; i++) {
          final t = templates[i];
          await svc.create(ServiceModel(
            id: 'tpl_${_selectedBusinessType}_$i',
            name: t['name'] as String,
            durationMinutes: t['duration'] as int,
            price: (t['price'] as num).toDouble(),
            category: t['category'] as String,
            isActive: true,
          ));
        }
      }
    }

    // Save Step 4 (Optional)
    if (_serviceNameCtrl.text.isNotEmpty && _servicePriceCtrl.text.isNotEmpty) {
      final svc = ServiceCatalogService();
      await svc.create(ServiceModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _serviceNameCtrl.text.trim(),
        durationMinutes: int.tryParse(_serviceDurationCtrl.text) ?? 30,
        price: double.tryParse(_servicePriceCtrl.text.replaceAll(',', '.')) ?? 0.0,
        category: 'Favoritos',
        isActive: true,
      ));
    }

    // Save Step 5
    await settings.setPrimaryColor(_selectedColor);

    // Done
    await settings.setOnboardingDone(true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (v) => setState(() => _currentPage = v),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _step1Welcome(),
                  _step2BusinessType(),
                  _step3Currency(),
                  _step4FirstService(),
                  _step5PrimaryColor(),
                ],
              ),
            ),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(5, (index) => _buildDot(index)),
          ),
          ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text(_currentPage == 4 ? '¡EMPEZAR!' : 'SIGUIENTE'),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? Theme.of(context).colorScheme.primary : Colors.grey.shade600,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  // ── STEPS ──────────────────────────────────────────────────────────────────

  Widget _step1Welcome() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/icon/app_icon.png', height: 120),
          const SizedBox(height: 32),
          const Text(
            'Bienvenido a BizPulse',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'El pulso de tu negocio',
            style: TextStyle(fontSize: 18, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _step2BusinessType() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '¿Qué tipo de negocio tenés?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _businessTypes.map((type) {
              final selected = _selectedBusinessType == type;
              return ChoiceChip(
                label: Text(type),
                selected: selected,
                onSelected: (val) {
                  if (val) setState(() => _selectedBusinessType = type);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _step3Currency() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '¿Con qué moneda trabajás?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _currencies.map((curr) {
              final code = curr['code']!;
              final selected = _selectedCurrency == code;
              return ChoiceChip(
                label: Text('$code (${curr['symbol']})'),
                selected: selected,
                onSelected: (val) {
                  if (val) setState(() => _selectedCurrency = code);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _step4FirstService() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 60),
          const Text(
            'Agregá tu primer servicio',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            '(Opcional)',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _serviceNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre del servicio',
              border: OutlineInputBorder(),
              hintText: 'Ej: Corte de cabello',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _serviceDurationCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duración',
                    suffixText: 'min',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _servicePriceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Precio',
                    prefixText: r'$ ',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {
              _serviceNameCtrl.clear();
              _servicePriceCtrl.clear();
              _nextPage();
            },
            child: const Text('Omitir este paso'),
          ),
        ],
      ),
    );
  }

  Widget _step5PrimaryColor() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Elegí el color de tu app',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              ..._presetColors.map((color) => GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedColor == color ? Colors.white : Colors.transparent,
                      width: 4,
                    ),
                    boxShadow: [
                      if (_selectedColor == color)
                        BoxShadow(color: color.withOpacity(0.4), blurRadius: 10, spreadRadius: 2)
                    ],
                  ),
                ),
              )),
            ],
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _openColorPicker,
            icon: const Icon(Icons.colorize),
            label: const Text('Personalizar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade800,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _openColorPicker() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elegí un color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (c) => setState(() => _selectedColor = c),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
