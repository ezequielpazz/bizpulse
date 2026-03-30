import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../models/user_plan.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import '../../services/subscription_service.dart';
import '../auth/login_screen.dart';
import '../plans/plans_screen.dart';
import 'backup_screen.dart';
import 'settings_screen.dart';
import '../legal/privacy_policy_screen.dart';
import '../clients/clients_screen.dart';
import '../services/service_catalog_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _nameCtrl = TextEditingController();
  final _userSvc = UserService();

  bool _loading = true;
  String _email = '';
  String _photoURL = '';
  String _uid = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // No hay sesión -> ir a login
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
      return;
    }

    _uid = user.uid;
    _email = user.email ?? '';

    final appUser = await _userSvc.fetchUser(_uid);
    _nameCtrl.text = appUser?.displayName ?? '';
    _photoURL = appUser?.photoURL ?? '';

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    final newName = _nameCtrl.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Poné un nombre público')),
      );
      return;
    }

    setState(() => _loading = true);
    await _userSvc.updateProfile(
      uid: _uid,
      displayName: newName,
      // photoURL más adelante
    );
    if (!mounted) return;
    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil actualizado')),
    );
  }

  Future<void> _logout() async {
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Widget _avatar() {
    final initials = _nameCtrl.text.isNotEmpty
        ? _nameCtrl.text.trim()[0].toUpperCase()
        : 'U';

    return CircleAvatar(
      radius: 36,
      backgroundColor: Colors.redAccent,
      backgroundImage: _photoURL.isNotEmpty ? NetworkImage(_photoURL) : null,
      child: _photoURL.isEmpty
          ? Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _avatar(),
                const SizedBox(height: 12),
                Text(
                  _email.isEmpty ? 'sin email' : _email,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre público / Nombre de la barbería',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Botón guardar perfil
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    onPressed: _loading ? null : _saveProfile,
                    label: const Text('Guardar perfil'),
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),

                // Mis clientes
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.people_outline, color: Colors.purpleAccent),
                  title: const Text('Mis clientes'),
                  subtitle: const Text('Fichas, historial y visitas',
                      style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ClientsScreen()),
                  ),
                ),

                // Catálogo de servicios
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.cut_outlined, color: Colors.blueAccent),
                  title: const Text('Catálogo de servicios'),
                  subtitle: const Text('Administrá tus servicios y precios',
                      style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ServiceCatalogScreen()),
                  ),
                ),

                // Configuración
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.settings_outlined, color: Colors.redAccent),
                  title: const Text('Configuración'),
                  subtitle: const Text('Notificaciones, colores, fuente',
                      style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),

                // Respaldo de datos
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.backup_outlined, color: Colors.green),
                  title: const Text('Respaldo de datos'),
                  subtitle: const Text('Exportar / importar tus datos',
                      style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BackupScreen()),
                  ),
                ),

                // Plan / Suscripción
                Consumer<SubscriptionService>(
                  builder: (_, sub, __) {
                    final plan = sub.currentPlan;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        plan == AppPlan.enterprise
                            ? Icons.diamond_rounded
                            : plan == AppPlan.pro
                                ? Icons.star_rounded
                                : Icons.rocket_launch_outlined,
                        color: plan.isPaid ? Colors.amber : Colors.orangeAccent,
                      ),
                      title: const Text('Plan / Suscripción'),
                      subtitle: Text(
                        'Plan actual: ${plan.label} (${plan.priceLabel})',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: plan.isPaid
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                plan.label,
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PlansScreen()),
                      ),
                    );
                  },
                ),

                // Política de privacidad
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.policy_outlined, color: Colors.white54),
                  title: const Text('Política de privacidad'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                  ),
                ),

                const Divider(),
                const SizedBox(height: 8),

                // Botón cerrar sesión
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.logout),
                    onPressed: _loading ? null : _logout,
                    label: const Text('Cerrar sesión'),
                  ),
                ),
              ],
            ),
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuenta'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configuración',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: body,
    );
  }
}
