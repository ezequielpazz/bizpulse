import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/backup_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _svc = BackupService();
  final _dayFmt = DateFormat('dd/MM/yyyy HH:mm');
  DateTime? _lastBackup;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLastBackup();
  }

  Future<void> _loadLastBackup() async {
    final date = await _svc.getLastBackupDate();
    if (mounted) setState(() {
      _lastBackup = date;
      _loading = false;
    });
  }

  // ── Export ──────────────────────────────────────────────────────────────────

  Future<void> _export() async {
    final messages = ValueNotifier<List<String>>([]);

    // Show progress dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ProgressDialog(messages: messages, title: 'Exportando...'),
    );

    String? savedPath;
    String? error;
    try {
      savedPath = await _svc.export(
        onStatus: (msg) =>
            messages.value = [...messages.value, msg],
      );
    } catch (e) {
      error = e.toString();
    }

    if (!mounted) return;
    Navigator.pop(context); // close progress dialog

    if (error != null) {
      _showError(error);
      return;
    }

    await _loadLastBackup();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Exportación exitosa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Archivo guardado en:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                savedPath ?? '',
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Listo'),
          ),
        ],
      ),
    );
  }

  // ── Import ──────────────────────────────────────────────────────────────────

  Future<void> _import() async {
    // Confirm before proceeding
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('¿Confirmar importación?'),
          ],
        ),
        content: const Text(
          'Esta operación REEMPLAZA todos tus datos actuales '
          '(turnos, productos y transacciones).\n\n'
          'Se creará un respaldo automático antes de proceder, '
          'pero asegurate de saber lo que estás haciendo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, importar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // Pick file
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );
    } catch (e) {
      if (mounted) _showError('No se pudo abrir el selector de archivos: $e');
      return;
    }
    if (result == null || result.files.isEmpty) return;

    final filePath = result.files.single.path;
    if (filePath == null) {
      if (mounted) _showError('No se pudo obtener la ruta del archivo.');
      return;
    }

    // Show progress dialog
    if (!mounted) return;
    final messages = ValueNotifier<List<String>>([]);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _ProgressDialog(messages: messages, title: 'Importando...'),
    );

    String? error;
    try {
      await _svc.importFromFile(
        filePath,
        onStatus: (msg) =>
            messages.value = [...messages.value, msg],
      );
    } catch (e) {
      error = e.toString();
    }

    if (!mounted) return;
    Navigator.pop(context); // close progress dialog

    if (error != null) {
      _showError(error);
      return;
    }

    await _loadLastBackup();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Importación exitosa'),
        content: const Text(
            'Tus datos fueron restaurados correctamente.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Listo'),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(msg),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Respaldo de datos')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Last backup info
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _lastBackup != null
                              ? Icons.check_circle_outline
                              : Icons.info_outline,
                          color: _lastBackup != null
                              ? Colors.green
                              : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Último respaldo',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 2),
                              Text(
                                _lastBackup != null
                                    ? _dayFmt.format(_lastBackup!)
                                    : 'Nunca realizado',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Export card
                  _SectionCard(
                    icon: Icons.upload_file,
                    iconColor: Colors.green,
                    title: 'Exportar datos',
                    subtitle:
                        'Guarda una copia de tus turnos, productos y '
                        'transacciones en un archivo JSON en tu dispositivo.',
                    buttonLabel: 'Exportar ahora',
                    buttonColor: Colors.green,
                    onTap: _export,
                  ),

                  const SizedBox(height: 16),

                  // Warning box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.orange, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Importar un archivo REEMPLAZA todos tus datos '
                            'actuales sin excepción. '
                            'Se creará un respaldo automático justo antes '
                            'de proceder, pero solo podrás recuperarlo '
                            'si exportás primero.',
                            style: TextStyle(
                                color: Colors.orange, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Import card
                  _SectionCard(
                    icon: Icons.download_for_offline,
                    iconColor: Colors.redAccent,
                    title: 'Importar datos',
                    subtitle:
                        'Seleccioná un archivo JSON de un respaldo anterior. '
                        'Todos los datos actuales serán reemplazados.',
                    buttonLabel: 'Seleccionar archivo',
                    buttonColor: Colors.redAccent,
                    onTap: _import,
                  ),

                  const SizedBox(height: 32),

                  // Help text
                  const Text(
                    'Los archivos de respaldo se guardan en el almacenamiento '
                    'externo de la app (Android/data/com.impro.app/files/) '
                    'o en Documentos (iOS). '
                    'Podés copiarlos a tu computadora o subirlos a la nube.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }
}

// ── Section card ───────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final Color buttonColor;
  final VoidCallback onTap;

  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.buttonColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: iconColor.withValues(alpha: 0.15),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 12),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),
          Text(subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

// ── Progress dialog ────────────────────────────────────────────────────────────

class _ProgressDialog extends StatelessWidget {
  final ValueNotifier<List<String>> messages;
  final String title;

  const _ProgressDialog({required this.messages, required this.title});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: ValueListenableBuilder<List<String>>(
        valueListenable: messages,
        builder: (_, msgs, __) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: CircularProgressIndicator()),
            if (msgs.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...msgs.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(m,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
