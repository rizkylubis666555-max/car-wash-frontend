import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/transaksi_provider.dart';
import 'main_scaffold.dart';
import 'kasir_profil_tab.dart';
import 'operator_home_tab.dart';
import 'operator_task_tab.dart';

class OperatorDashboard extends StatefulWidget {
  const OperatorDashboard({super.key});

  @override
  State<OperatorDashboard> createState() => _OperatorDashboardState();
}

class _OperatorDashboardState extends State<OperatorDashboard> {
  Timer? _queueSyncTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TransaksiProvider>().loadTransaksi(role: 'operator');
      }
    });
    _queueSyncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        context.read<TransaksiProvider>().refreshTransaksiSilently();
      }
    });
  }

  @override
  void dispose() {
    _queueSyncTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshQueue() async {
    final provider = context.read<TransaksiProvider>();
    await provider.loadTransaksi(role: 'operator');
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(provider.errorMessage ?? 'Antrean berhasil diperbarui.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      role: 'operator',
      pages: [
        OperatorHomeTab(onRefresh: _refreshQueue),
        const OperatorTaskTab(mode: OperatorTaskMode.waiting),
        const OperatorTaskTab(mode: OperatorTaskMode.washing),
        const OperatorTaskTab(mode: OperatorTaskMode.completed),
        const KasirProfilTab(),
      ],
      navItems: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.hourglass_bottom),
          activeIcon: Icon(Icons.hourglass_full),
          label: 'Menunggu',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_car_wash_outlined),
          activeIcon: Icon(Icons.local_car_wash),
          label: 'Dicuci',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.check_circle_outline),
          activeIcon: Icon(Icons.check_circle),
          label: 'Selesai',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    );
  }
}
