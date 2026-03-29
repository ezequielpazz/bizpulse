import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_settings.dart';
import '../../views/dashboard/dashboard_screen.dart';
import '../../views/agenda/agenda_screen.dart';
import '../../views/inventory/inventory_screen.dart';
import '../../views/products/products_screen.dart';
import '../../views/finance/finance_screen.dart';
import '../../views/account/account_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardScreen(onNavigate: (i) => setState(() => _index = i)),
      const AgendaScreen(),
      const InventoryScreen(),
      const ProductsScreen(),
      const FinanceScreen(),
      const AccountScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final primary = context.watch<AppSettingsProvider>().primaryColor;
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Agenda'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Insumos'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Productos'),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Ganancias'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cuenta'),
        ],
      ),
    );
  }
}
