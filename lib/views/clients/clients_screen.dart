import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/client_model.dart';
import '../../widgets/ad_banner.dart';
import '../../services/client_service.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final _svc = ClientService();
  final _searchCtrl = TextEditingController();
  List<ClientModel> _all = [];
  List<ClientModel> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final list = await _svc.getAll();
    if (!mounted) return;
    setState(() {
      _all = list;
      _filtered = list;
      _loading = false;
    });
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _all
          : _all.where((c) => c.name.toLowerCase().contains(q) || c.phone.contains(q)).toList();
    });
  }

  void _showDetail(ClientModel client) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _DetailSheet(
        client: client,
        svc: _svc,
        onSaved: _load,
      ),
    );
  }

  void _showAdd() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EditSheet(svc: _svc, onSaved: _load),
    );
  }

  Future<void> _delete(ClientModel client) async {
    try {
      await _svc.delete(client.id);
      if (!mounted) return;
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: $e')),
      );
      _load(); // recargar para revertir el swipe en la UI
    }
  }

  Widget _clientAvatar(ClientModel c, {double radius = 24}) {
    if (c.photoPath != null && c.photoPath!.isNotEmpty) {
      final file = File(c.photoPath!);
      if (file.existsSync()) {
        return CircleAvatar(
          radius: radius,
          backgroundImage: FileImage(file),
        );
      }
    }
    final colors = [
      Colors.blue, Colors.purple, Colors.pink, Colors.orange,
      Colors.green, Colors.teal, Colors.indigo, Colors.deepPurple,
    ];
    final color = colors[c.name.hashCode.abs() % colors.length];
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.15),
      child: Text(
        c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }

  /// Empty state vacío con ilustración + CTA
  Widget _emptyState() {
    final isSearch = _searchCtrl.text.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearch ? Icons.search_off_rounded : Icons.people_outline_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSearch ? 'Sin resultados' : 'Sin clientes todavía',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearch
                  ? 'Probá con otro nombre o teléfono'
                  : 'Tocá el botón + para agregar tu primer cliente y empezar a llevar el historial de visitas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).hintColor,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Card moderno para cliente (con avatar, info, stats)
  Widget _clientCard(ClientModel c) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: isDark
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showDetail(c),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _clientAvatar(c, radius: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (c.phone.isNotEmpty) ...[
                            Icon(Icons.phone_rounded,
                                size: 12,
                                color: Theme.of(context).hintColor),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                c.phone,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).hintColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ] else
                            Text(
                              'Sin teléfono',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).hintColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${c.totalVisits} visita${c.totalVisits == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    if (c.lastVisit != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM/yy').format(c.lastVisit!),
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis clientes')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAdd,
        child: const Icon(Icons.person_add_outlined),
      ),
      body: Column(
        children: [
          const AdBannerWidget(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o teléfono...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final c = _filtered[i];
                            return Dismissible(
                              key: ValueKey(c.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 24),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.error,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.delete_outline_rounded,
                                    color: Colors.white),
                              ),
                              confirmDismiss: (_) async {
                                return await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    title: const Text('Eliminar cliente'),
                                    content: Text('¿Eliminar a ${c.name}?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: Text(
                                          'Eliminar',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              onDismissed: (_) => _delete(c),
                              child: _clientCard(c),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Detail / Edit sheet ─────────────────────────────────────────────────────

Widget _buildAvatar(ClientModel c, {double radius = 28}) {
  if (c.photoPath != null && c.photoPath!.isNotEmpty) {
    final file = File(c.photoPath!);
    if (file.existsSync()) {
      return CircleAvatar(radius: radius, backgroundImage: FileImage(file));
    }
  }
  return CircleAvatar(
    radius: radius,
    child: Text(
      c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
      style: TextStyle(fontSize: radius * 0.75),
    ),
  );
}

class _DetailSheet extends StatelessWidget {
  final ClientModel client;
  final ClientService svc;
  final VoidCallback onSaved;

  const _DetailSheet({required this.client, required this.svc, required this.onSaved});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMMM yyyy', 'es');
    final hint = Theme.of(context).hintColor;
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: hint.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              _buildAvatar(client, radius: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (client.phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.phone_rounded, size: 13, color: hint),
                          const SizedBox(width: 4),
                          Text(client.phone,
                              style: TextStyle(color: hint, fontSize: 13)),
                        ],
                      ),
                    ],
                    if (client.email != null && client.email!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.email_outlined, size: 13, color: hint),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              client.email!,
                              style: TextStyle(color: hint, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.edit_rounded, size: 18),
                tooltip: 'Editar',
                onPressed: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => _EditSheet(
                        svc: svc, existing: client, onSaved: onSaved),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Stats cards (visitas + gastado)
          Row(
            children: [
              Expanded(
                child: _statCard(
                  context,
                  icon: Icons.event_repeat_rounded,
                  label: 'Visitas',
                  value: '${client.totalVisits}',
                  color: primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  context,
                  icon: Icons.attach_money_rounded,
                  label: 'Gastado',
                  value: '\$${client.totalSpent.toStringAsFixed(0)}',
                  color: Colors.green,
                ),
              ),
            ],
          ),

          if (client.lastVisit != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hint.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 16, color: hint),
                  const SizedBox(width: 8),
                  Text(
                    'Última visita: ${fmt.format(client.lastVisit!)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],

          if (client.birthday != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.pink.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cake_rounded,
                      size: 16, color: Colors.pink),
                  const SizedBox(width: 8),
                  Text(
                    'Cumpleaños: ${DateFormat('dd MMMM', 'es').format(client.birthday!)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],

          if (client.notes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.notes_rounded, size: 16, color: hint),
                const SizedBox(width: 6),
                const Text(
                  'Notas',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hint.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                client.notes,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditSheet extends StatefulWidget {
  final ClientService svc;
  final ClientModel? existing;
  final VoidCallback onSaved;

  const _EditSheet({required this.svc, this.existing, required this.onSaved});

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _notes;
  bool _saving = false;
  String? _photoPath;
  DateTime? _birthday;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _phone = TextEditingController(text: widget.existing?.phone ?? '');
    _email = TextEditingController(text: widget.existing?.email ?? '');
    _notes = TextEditingController(text: widget.existing?.notes ?? '');
    _photoPath = widget.existing?.photoPath;
    _birthday = widget.existing?.birthday;
  }

  @override
  void dispose() {
    _name.dispose(); _phone.dispose(); _email.dispose(); _notes.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70, maxWidth: 400);
    if (picked == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final id = widget.existing?.id.isNotEmpty == true
        ? widget.existing!.id
        : DateTime.now().millisecondsSinceEpoch.toString();
    final dest = '${dir.path}/client_$id.jpg';
    await File(picked.path).copy(dest);
    if (mounted) setState(() => _photoPath = dest);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final c = ClientModel(
      id: widget.existing?.id ?? '',
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      notes: _notes.text.trim(),
      lastVisit: widget.existing?.lastVisit,
      totalVisits: widget.existing?.totalVisits ?? 0,
      totalSpent: widget.existing?.totalSpent ?? 0,
      photoPath: _photoPath,
      birthday: _birthday,
    );
    try {
      if (widget.existing == null) {
        await widget.svc.create(c);
      } else {
        await widget.svc.update(c);
      }
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.existing == null ? 'Nuevo cliente' : 'Editar cliente',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // Foto de perfil
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Stack(
                  children: [
                    _photoPath != null && File(_photoPath!).existsSync()
                        ? CircleAvatar(
                            radius: 40,
                            backgroundImage: FileImage(File(_photoPath!)),
                          )
                        : const CircleAvatar(
                            radius: 40,
                            child: Icon(Icons.person, size: 40),
                          ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nombre *', border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? 'Obligatorio' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notas', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _birthday ?? DateTime(1990, 1, 1),
                  firstDate: DateTime(1940),
                  lastDate: DateTime.now(),
                  helpText: 'Cumpleaños del cliente',
                );
                if (picked != null) setState(() => _birthday = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Cumpleaños',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.cake_outlined),
                ),
                child: Text(
                  _birthday != null
                      ? '${_birthday!.day}/${_birthday!.month}/${_birthday!.year}'
                      : 'Sin definir',
                  style: TextStyle(
                    color: _birthday != null ? null : Theme.of(context).hintColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
