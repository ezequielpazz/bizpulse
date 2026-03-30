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
    return CircleAvatar(
      radius: radius,
      child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?'),
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
                    ? Center(
                        child: Text(
                          _searchCtrl.text.isEmpty
                              ? 'Sin clientes aún.\nPresioná + para agregar uno.'
                              : 'Sin resultados.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white54),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 88),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final c = _filtered[i];
                            return Dismissible(
                              key: ValueKey(c.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                color: Colors.red,
                                child: const Icon(Icons.delete_outline, color: Colors.white),
                              ),
                              confirmDismiss: (_) async {
                                return await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Eliminar cliente'),
                                    content: Text('¿Eliminar a ${c.name}?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                );
                              },
                              onDismissed: (_) => _delete(c),
                              child: ListTile(
                                leading: _clientAvatar(c, radius: 20),
                                title: Text(c.name),
                                subtitle: Text(c.phone.isEmpty ? 'Sin teléfono' : c.phone),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('${c.totalVisits} visitas', style: const TextStyle(fontSize: 12)),
                                    if (c.lastVisit != null)
                                      Text(
                                        DateFormat('dd/MM/yy').format(c.lastVisit!),
                                        style: const TextStyle(fontSize: 11, color: Colors.white54),
                                      ),
                                  ],
                                ),
                                onTap: () => _showDetail(c),
                              ),
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
    final fmt = DateFormat('dd/MM/yyyy');
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatar(client, radius: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(client.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    if (client.phone.isNotEmpty) Text(client.phone, style: const TextStyle(color: Colors.white70)),
                    if (client.email != null && client.email!.isNotEmpty) Text(client.email!, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => _EditSheet(svc: svc, existing: client, onSaved: onSaved),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          _infoRow('Visitas totales', '${client.totalVisits}'),
          _infoRow('Total gastado', '\$${client.totalSpent.toStringAsFixed(0)}'),
          if (client.lastVisit != null) _infoRow('Última visita', fmt.format(client.lastVisit!)),
          if (client.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Notas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            Text(client.notes, style: const TextStyle(color: Colors.white70)),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white54)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
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
