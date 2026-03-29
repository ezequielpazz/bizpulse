import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../providers/app_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _notifCtrl;
  late TextEditingController _msgCtrl;
  late TextEditingController _symbolCtrl;
  late TextEditingController _pinCtrl;

  // ── Google Fonts (deduplicados y ordenados alfabéticamente) ──────────────
  static final _fonts = <String>{
    'Anton', 'Arvo', 'Bebas Neue', 'Bitter', 'Black Han Sans',
    'Caveat', 'Cinzel', 'Comfortaa', 'Cormorant Garamond', 'Courier Prime',
    'Crimson Text', 'Dancing Script', 'DM Sans', 'EB Garamond',
    'Great Vibes', 'IM Fell English', 'Inter', 'Josefin Sans', 'Karla',
    'Lato', 'Lexend', 'Libre Baskerville', 'Lobster', 'Manrope',
    'Merriweather', 'Montserrat', 'Nunito', 'Open Sans', 'Oswald',
    'Pacifico', 'Patrick Hand', 'Permanent Marker', 'Playfair Display',
    'Poppins', 'Quicksand', 'Raleway', 'Righteous', 'Roboto', 'Rubik',
    'Russo One', 'Sacramento', 'Satisfy', 'Shadows Into Light',
    'Space Grotesk', 'Special Elite', 'Syne', 'Ubuntu', 'Zilla Slab',
  }.toList()..sort();

  static const _currencies = [
    'ARS', 'MXN', 'CLP', 'COP', 'USD', 'BRL', 'PEN', 'UYU',
  ];
  static const _currencySymbols = <String, String>{
    'ARS': r'$',  'MXN': r'$',  'CLP': r'$',  'COP': r'$',
    'USD': r'US$', 'BRL': r'R$', 'PEN': 'S/',  'UYU': r'$U',
  };

  // DateTime.weekday: 1=Lun … 7=Dom
  static const _dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  // ── Ciclo de vida ──────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    final s = context.read<AppSettingsProvider>();
    _notifCtrl  = TextEditingController(text: s.notifMinutesBefore.toString());
    _msgCtrl    = TextEditingController(text: s.whatsappMsg);
    _symbolCtrl = TextEditingController(text: s.currencySymbol);
    _pinCtrl    = TextEditingController(text: s.pinCode);
  }

  @override
  void dispose() {
    _notifCtrl.dispose();
    _msgCtrl.dispose();
    _symbolCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<void> _pickColor(
    Color current,
    Future<void> Function(Color) onPick,
  ) async {
    Color temp = current;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elegir color'),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (_, setSt) => ColorPicker(
              pickerColor: temp,
              onColorChanged: (c) => setSt(() => temp = c),
              pickerAreaHeightPercent: 0.75,
              enableAlpha: false,
              labelTypes: const [],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await onPick(temp);
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(AppSettingsProvider s) async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final dir  = await getApplicationDocumentsDirectory();
    final dest = '${dir.path}/bg_image.jpg';
    await File(file.path).copy(dest);
    await s.setBgImagePath(dest);
  }

  Future<String?> _pickTime(String current) async {
    final parts = current.split(':');
    final h = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 9) : 9;
    final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    if (!mounted) return null;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: h, minute: m),
    );
    if (picked == null) return null;
    return '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}';
  }

  Widget _colorRow(String label, Color color, VoidCallback onPick, VoidCallback onReset) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          _colorDot(color, onPick),
          const SizedBox(width: 4),
          InkWell(
            onTap: onReset,
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.refresh, size: 16, color: Colors.white38),
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorDot(Color color, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white30, width: 2),
          ),
        ),
      );

  TextStyle _previewStyle(String font) {
    if (font == 'Roboto') return const TextStyle(fontSize: 20);
    try {
      return GoogleFonts.getFont(font, fontSize: 20);
    } catch (_) {
      return const TextStyle(fontSize: 20);
    }
  }

  // ── Bloque de sección reutilizable ────────────────────────────────────────

  Widget _section({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ExpansionTile(
        leading: Icon(icon, size: 22),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  // Etiqueta de sub-campo dentro de una sección
  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: Colors.white60),
        ),
      );

  // ── Build principal ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettingsProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 40),
        children: [
          _aparienciaSection(s),
          _negocioSection(s),
          _finanzasSection(s),
          _notifSection(s),
          _privacidadSection(s),
          _datosSection(s),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 1. APARIENCIA
  // ══════════════════════════════════════════════════════════════════════════

  Widget _aparienciaSection(AppSettingsProvider s) {
    return _section(
      icon: Icons.palette_outlined,
      title: 'Apariencia',
      children: [
        // ── Color primario ─────────────────────────────────────────────────
        _label('Color primario'),
        Row(
          children: [
            const Expanded(
              child: Text('Color de acento de la app',
                  style: TextStyle(fontSize: 13)),
            ),
            _colorDot(s.primaryColor,
                () => _pickColor(s.primaryColor, s.setPrimaryColor)),
          ],
        ),

        // ── Colores personalizados ──────────────────────────────────────────
        _label('Colores personalizados'),
        _colorRow('Color de botones', s.buttonColor,
            () => _pickColor(s.buttonColor, s.setButtonColor),
            s.resetButtonColor),
        _colorRow('Texto de botones', s.buttonTextColor,
            () => _pickColor(s.buttonTextColor, s.setButtonTextColor),
            () => s.setButtonTextColor(Colors.white)),
        _colorRow('Fondo de pantalla', s.backgroundColor,
            () => _pickColor(s.backgroundColor, s.setBackgroundColor),
            () => s.setBackgroundColor(const Color(0xFF121212))),
        _colorRow('Color de texto', s.textColor,
            () => _pickColor(s.textColor, s.setTextColor),
            () => s.setTextColor(Colors.white)),
        _colorRow('Color de tarjetas', s.cardColor,
            () => _pickColor(s.cardColor, s.setCardColor),
            () => s.setCardColor(const Color(0xFF1E1E1E))),

        // ── Tamaño de texto ────────────────────────────────────────────────
        _label('Tamaño de texto  ·  ${s.textScale.toStringAsFixed(1)}×'),
        Slider(
          value: s.textScale,
          min: 0.8,
          max: 1.4,
          divisions: 6,
          label: '${s.textScale.toStringAsFixed(1)}×',
          onChanged: (v) =>
              s.setTextScale(double.parse(v.toStringAsFixed(1))),
        ),

        // ── Idioma ────────────────────────────────────────────────────────
        const ListTile(
          contentPadding: EdgeInsets.zero,
          enabled: false,
          title: Text('Idioma'),
          subtitle: Text(
            'Próximamente — Español, English, Português',
            style: TextStyle(fontSize: 12),
          ),
          trailing: Icon(Icons.lock_outline, color: Colors.grey),
        ),

        // ── Fondo de pantalla ─────────────────────────────────────────────
        _label('Fondo de pantalla'),
        SegmentedButton<BgType>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: BgType.solid,
              label: Text('Sólido'),
              icon: Icon(Icons.square_rounded, size: 16),
            ),
            ButtonSegment(
              value: BgType.gradient,
              label: Text('Degradado'),
              icon: Icon(Icons.gradient, size: 16),
            ),
            ButtonSegment(
              value: BgType.image,
              label: Text('Imagen'),
              icon: Icon(Icons.image_outlined, size: 16),
            ),
          ],
          selected: {s.bgType},
          onSelectionChanged: (v) => s.setBgType(v.first),
        ),
        const SizedBox(height: 14),
        _bgControls(s),

        // ── Fuente ────────────────────────────────────────────────────────
        _label('Fuente  (${_fonts.length} disponibles)'),
        ..._fonts.map((f) => _fontTile(f, s)),

        // ── Estilo de botones ─────────────────────────────────────────────
        _label('Estilo de botones'),
        ..._buttonStyleCards(s),
      ],
    );
  }

  // Controles de fondo según bgType ─────────────────────────────────────────

  Widget _bgControls(AppSettingsProvider s) {
    switch (s.bgType) {
      case BgType.solid:
        return Row(
          children: [
            const Text('Color:'),
            const SizedBox(width: 10),
            _colorDot(
                s.bgColor1, () => _pickColor(s.bgColor1, s.setBgColor1)),
          ],
        );

      case BgType.gradient:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Color 1:'),
                const SizedBox(width: 8),
                _colorDot(
                    s.bgColor1, () => _pickColor(s.bgColor1, s.setBgColor1)),
                const SizedBox(width: 20),
                const Text('Color 2:'),
                const SizedBox(width: 8),
                _colorDot(
                    s.bgColor2, () => _pickColor(s.bgColor2, s.setBgColor2)),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              height: 36,
              decoration: BoxDecoration(
                gradient:
                    LinearGradient(colors: [s.bgColor1, s.bgColor2]),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        );

      case BgType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Elegir imagen'),
              onPressed: () => _pickImage(s),
            ),
            if (s.bgImagePath != null &&
                File(s.bgImagePath!).existsSync()) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(s.bgImagePath!),
                  height: 90,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Quitar imagen'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  padding: EdgeInsets.zero,
                ),
                onPressed: () => s.setBgImagePath(null),
              ),
            ],
            const SizedBox(height: 6),
            _label(
              'Opacidad del overlay  ·  '
              '${(s.backgroundOverlayOpacity * 100).round()}%',
            ),
            Slider(
              value: s.backgroundOverlayOpacity,
              min: 0.0,
              max: 0.8,
              divisions: 16,
              label: '${(s.backgroundOverlayOpacity * 100).round()}%',
              onChanged: (v) => s.setBackgroundOverlayOpacity(
                  double.parse(v.toStringAsFixed(2))),
            ),
          ],
        );
    }
  }

  // Tile de fuente individual ───────────────────────────────────────────────

  Widget _fontTile(String font, AppSettingsProvider s) {
    final selected = s.fontFamily == font;
    final primary  = s.primaryColor;
    // Sin key explícita: evita conflictos de GlobalKey en listas largas.
    return InkWell(
      onTap: () => s.setFontFamily(font),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: selected ? primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    font,
                    style: const TextStyle(fontSize: 11, color: Colors.white54),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text('BizPulse', style: _previewStyle(font)),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: primary, size: 18),
          ],
        ),
      ),
    );
  }

  // 4 tarjetas de estilo de botón ───────────────────────────────────────────

  List<Widget> _buttonStyleCards(AppSettingsProvider s) {
    const names = ['Clásico', 'Moderno', 'Minimal', 'Bold'];
    const descs = [
      'Bordes redondeados · relleno sólido · sombra',
      'Forma de pastilla · degradado con color primario',
      'Plano · sin sombra · solo borde fino',
      'Esquinas rectas · contraste alto · texto en mayúsculas',
    ];
    return List.generate(4, (idx) {
      final selected = s.buttonStyle == idx;
      final primary  = s.primaryColor;
      return GestureDetector(
        onTap: () => s.setButtonStyle(idx),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? primary : Colors.white12,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(names[idx],
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (selected) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.check_circle, color: primary, size: 15),
                      ],
                    ]),
                    const SizedBox(height: 2),
                    Text(descs[idx],
                        style: const TextStyle(
                            fontSize: 11, color: Colors.white54)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buttonPreview(idx, primary),
            ],
          ),
        ),
      );
    });
  }

  Widget _buttonPreview(int idx, Color primary) {
    // Tema aislado: resetea elevatedButtonTheme y outlinedButtonTheme para
    // evitar que el textStyle global del tema cause fallos de lerp al
    // reconstruir la lista durante cambios de tema.
    final base = Theme.of(context).copyWith(
      elevatedButtonTheme: const ElevatedButtonThemeData(),
      outlinedButtonTheme: const OutlinedButtonThemeData(),
    );

    const pad = EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    const target = MaterialTapTargetSize.shrinkWrap;

    switch (idx) {
      case 0: // Clásico — bordes redondeados, sombra
        return Theme(
          data: base,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 4,
              padding: pad,
              tapTargetSize: target,
            ),
            child: const Text(
              'Guardar',
              style: TextStyle(color: Colors.white, inherit: true),
            ),
          ),
        );

      case 1: // Moderno — degradado, pastilla (no usa ElevatedButton)
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primary,
                Color.lerp(primary, Colors.purpleAccent, 0.45)!,
              ],
            ),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(50),
              onTap: null,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                child: Text(
                  'Guardar',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    inherit: true,
                  ),
                ),
              ),
            ),
          ),
        );

      case 2: // Minimal — plano, solo borde
        return Theme(
          data: base,
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: primary),
              foregroundColor: primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: pad,
              tapTargetSize: target,
            ),
            child: Text(
              'Guardar',
              style: TextStyle(color: primary, inherit: true),
            ),
          ),
        );

      case 3: // Bold — esquinas rectas, contraste alto
        return Theme(
          data: base,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(),
              elevation: 0,
              padding: pad,
              tapTargetSize: target,
            ),
            child: const Text(
              'GUARDAR',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                inherit: true,
              ),
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 2. NEGOCIO
  // ══════════════════════════════════════════════════════════════════════════

  Widget _negocioSection(AppSettingsProvider s) {
    return _section(
      icon: Icons.store_outlined,
      title: 'Negocio',
      children: [
        // ── Días de trabajo ────────────────────────────────────────────────
        _label('Días de trabajo'),
        Wrap(
          spacing: 6,
          children: List.generate(7, (i) {
            final day = i + 1; // 1=Lun … 7=Dom
            return FilterChip(
              label: Text(_dayNames[i]),
              selected: s.workDays.contains(day),
              onSelected: (on) {
                final list = List<int>.from(s.workDays);
                if (on) {
                  list.add(day);
                } else {
                  list.remove(day);
                }
                list.sort();
                s.setWorkDays(list);
              },
            );
          }),
        ),

        // ── Horario de atención ────────────────────────────────────────────
        _label('Horario de atención'),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.access_time, size: 16),
                label: Text('Desde ${s.workStart}'),
                onPressed: () async {
                  final t = await _pickTime(s.workStart);
                  if (t != null) s.setWorkStart(t);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.access_time, size: 16),
                label: Text('Hasta ${s.workEnd}'),
                onPressed: () async {
                  final t = await _pickTime(s.workEnd);
                  if (t != null) s.setWorkEnd(t);
                },
              ),
            ),
          ],
        ),

        // ── Duración por defecto del turno ─────────────────────────────────
        _label('Duración por defecto del turno'),
        Wrap(
          spacing: 8,
          children: [15, 30, 45, 60].map((min) {
            return ChoiceChip(
              label: Text('$min min'),
              selected: s.defaultApptDuration == min,
              onSelected: (_) => s.setDefaultApptDuration(min),
            );
          }).toList(),
        ),

        // ── Mensaje de WhatsApp automático ─────────────────────────────────
        _label('Mensaje de recordatorio por WhatsApp'),
        TextField(
          controller: _msgCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            helperText:
                'Variables: {nombre}  {hora}  {servicio}',
            helperMaxLines: 2,
            isDense: true,
          ),
          onChanged: (v) => s.setWhatsappMsg(v),
        ),

        // ── Días bloqueados ────────────────────────────────────────────────
        _label('Días bloqueados (feriados / vacaciones)'),
        ElevatedButton.icon(
          icon: const Icon(Icons.event_busy_outlined, size: 16),
          label: const Text('Agregar día bloqueado'),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 1)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked == null) return;
            final iso =
                '${picked.year}-${picked.month.toString().padLeft(2, '0')}'
                '-${picked.day.toString().padLeft(2, '0')}';
            if (!s.blockedDays.contains(iso)) {
              s.setBlockedDays([...s.blockedDays, iso]..sort());
            }
          },
        ),
        if (s.blockedDays.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: s.blockedDays.map((d) {
              return Chip(
                label: Text(d, style: const TextStyle(fontSize: 12)),
                deleteIcon: const Icon(Icons.close, size: 14),
                onDeleted: () {
                  final list = List<String>.from(s.blockedDays)
                    ..remove(d);
                  s.setBlockedDays(list);
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 3. FINANZAS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _finanzasSection(AppSettingsProvider s) {
    return _section(
      icon: Icons.attach_money_outlined,
      title: 'Finanzas',
      children: [
        // ── Moneda ─────────────────────────────────────────────────────────
        _label('Moneda'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _currencies.map((code) {
            return ChoiceChip(
              label: Text(code),
              selected: s.currencyCode == code,
              onSelected: (_) {
                final sym = _currencySymbols[code] ?? r'$';
                s.setCurrencyCode(code);
                s.setCurrencySymbol(sym);
                _symbolCtrl.text = sym;
              },
            );
          }).toList(),
        ),

        // ── Símbolo personalizable ─────────────────────────────────────────
        _label('Símbolo de moneda (editable)'),
        SizedBox(
          width: 130,
          child: TextField(
            controller: _symbolCtrl,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
            onChanged: (v) => s.setCurrencySymbol(v),
          ),
        ),

        // ── Redondeo de precios ────────────────────────────────────────────
        _label('Redondeo de precios'),
        Wrap(
          spacing: 8,
          children: [0, 10, 50, 100].map((r) {
            return ChoiceChip(
              label: Text(r == 0 ? 'Sin redondeo' : 'al \$$r'),
              selected: s.priceRounding == r,
              onSelected: (_) => s.setPriceRounding(r),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 4. NOTIFICACIONES
  // ══════════════════════════════════════════════════════════════════════════

  Widget _notifSection(AppSettingsProvider s) {
    return _section(
      icon: Icons.notifications_outlined,
      title: 'Notificaciones',
      children: [
        // ── Minutos antes del turno ────────────────────────────────────────
        _label('Avisar antes del turno'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 90,
              child: TextField(
                controller: _notifCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  suffixText: 'min',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                onChanged: (v) {
                  final n = int.tryParse(v);
                  if (n != null && n >= 1 && n <= 1440) s.setNotifMinutes(n);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 6,
                children: [15, 30, 60].map((m) {
                  return ChoiceChip(
                    label: Text('$m min'),
                    selected: s.notifMinutesBefore == m,
                    onSelected: (_) {
                      _notifCtrl.text = m.toString();
                      s.setNotifMinutes(m);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),

        // ── Alerta de stock bajo ───────────────────────────────────────────
        _label('Alerta de stock bajo  ·  ${s.stockAlertQty} unidades'),
        Slider(
          value: s.stockAlertQty.toDouble(),
          min: 1,
          max: 50,
          divisions: 49,
          label: '${s.stockAlertQty} uds',
          onChanged: (v) => s.setStockAlertQty(v.round()),
        ),

        // ── Cierre de caja ─────────────────────────────────────────────────
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Recordatorio de cierre de caja'),
          subtitle: const Text(
            'Notificación al final del día laboral',
            style: TextStyle(fontSize: 11),
          ),
          value: s.cashCloseEnabled,
          onChanged: s.setCashCloseEnabled,
        ),
        if (s.cashCloseEnabled) ...[
          OutlinedButton.icon(
            icon: const Icon(Icons.access_time, size: 16),
            label: Text('Hora de cierre: ${s.cashCloseTime}'),
            onPressed: () async {
              final t = await _pickTime(s.cashCloseTime);
              if (t != null) s.setCashCloseTime(t);
            },
          ),
          const SizedBox(height: 4),
        ],

        // ── Recordatorio WhatsApp ──────────────────────────────────────────
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Recordatorio al cliente por WhatsApp'),
          subtitle: const Text(
            'Enviar el mensaje configurado antes del turno',
            style: TextStyle(fontSize: 11),
          ),
          value: s.whatsappReminderEnabled,
          onChanged: s.setWhatsappReminderEnabled,
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 5. PRIVACIDAD Y SEGURIDAD
  // ══════════════════════════════════════════════════════════════════════════

  Widget _privacidadSection(AppSettingsProvider s) {
    return _section(
      icon: Icons.security_outlined,
      title: 'Privacidad y Seguridad',
      children: [
        // ── PIN de acceso ──────────────────────────────────────────────────
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('PIN de acceso'),
          subtitle: const Text(
            'Proteger la app con contraseña de 4 dígitos',
            style: TextStyle(fontSize: 11),
          ),
          value: s.pinEnabled,
          onChanged: s.setPinEnabled,
        ),
        if (s.pinEnabled) ...[
          const SizedBox(height: 4),
          SizedBox(
            width: 160,
            child: TextField(
              controller: _pinCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'PIN (4 dígitos)',
                border: OutlineInputBorder(),
                isDense: true,
                counterText: '',
              ),
              onChanged: (v) {
                if (v.length == 4) s.setPinCode(v);
              },
            ),
          ),
          _label('Bloqueo automático por inactividad'),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Nunca'),
                selected: s.autoLockMinutes == 0,
                onSelected: (_) => s.setAutoLockMinutes(0),
              ),
              ChoiceChip(
                label: const Text('1 min'),
                selected: s.autoLockMinutes == 1,
                onSelected: (_) => s.setAutoLockMinutes(1),
              ),
              ChoiceChip(
                label: const Text('5 min'),
                selected: s.autoLockMinutes == 5,
                onSelected: (_) => s.setAutoLockMinutes(5),
              ),
              ChoiceChip(
                label: const Text('10 min'),
                selected: s.autoLockMinutes == 10,
                onSelected: (_) => s.setAutoLockMinutes(10),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],

        // ── Modo discreto ──────────────────────────────────────────────────
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Modo discreto'),
          subtitle: const Text(
            'Ocultar montos en la pantalla de Ganancias',
            style: TextStyle(fontSize: 11),
          ),
          value: s.stealthMode,
          onChanged: s.setStealthMode,
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 6. DATOS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _datosSection(AppSettingsProvider s) {
    return _section(
      icon: Icons.storage_outlined,
      title: 'Datos',
      children: [
        // ── Backup automático ──────────────────────────────────────────────
        _label('Frecuencia de respaldo automático'),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Manual'),
              selected: s.backupFrequency == 'manual',
              onSelected: (_) => s.setBackupFrequency('manual'),
            ),
            ChoiceChip(
              label: const Text('Semanal'),
              selected: s.backupFrequency == 'weekly',
              onSelected: (_) => s.setBackupFrequency('weekly'),
            ),
            ChoiceChip(
              label: const Text('Diario'),
              selected: s.backupFrequency == 'daily',
              onSelected: (_) => s.setBackupFrequency('daily'),
            ),
          ],
        ),

        // ── Formato de exportación ─────────────────────────────────────────
        _label('Formato de exportación'),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('JSON'),
              selected: s.exportFormat == 'json',
              onSelected: (_) => s.setExportFormat('json'),
            ),
            ChoiceChip(
              label: const Text('CSV'),
              selected: s.exportFormat == 'csv',
              onSelected: (_) => s.setExportFormat('csv'),
            ),
          ],
        ),

        // ── Retención del historial ────────────────────────────────────────
        _label('Eliminar historial antiguo'),
        DropdownButton<int>(
          value: s.historyRetentionMonths,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 0,  child: Text('Guardar siempre')),
            DropdownMenuItem(value: 6,  child: Text('Eliminar al pasar 6 meses')),
            DropdownMenuItem(value: 12, child: Text('Eliminar al pasar 1 año')),
            DropdownMenuItem(value: 24, child: Text('Eliminar al pasar 2 años')),
          ],
          onChanged: (v) {
            if (v != null) s.setHistoryRetentionMonths(v);
          },
        ),
      ],
    );
  }
}
