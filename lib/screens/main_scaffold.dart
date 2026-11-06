import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/transaksi_provider.dart';

class MainScaffold extends StatefulWidget {
  final String role;
  // Menerima daftar halaman sesuai hak akses
  final List<Widget> pages;
  final List<BottomNavigationBarItem> navItems;

  const MainScaffold({
    super.key,
    required this.role,
    required this.pages,
    required this.navItems,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileIndex = widget.navItems.indexWhere(
      (item) => (item.label ?? '').toLowerCase() == 'profil',
    );

    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              child: _FloatingDashboardHeader(
                role: widget.role,
                onProfileTap: profileIndex < 0
                    ? null
                    : () => _onItemTapped(profileIndex),
                onRefresh: () => context
                    .read<TransaksiProvider>()
                    .loadTransaksi(role: widget.role),
              ),
            ),
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: widget.pages[_selectedIndex],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9FBFE).withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF526B8A).withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              const BoxShadow(
                color: Colors.white,
                blurRadius: 8,
                offset: Offset(-3, -3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              destinations: widget.navItems
                  .map(
                    (item) => NavigationDestination(
                      icon: item.icon,
                      selectedIcon: item.activeIcon,
                      label: item.label ?? '',
                      tooltip: item.label ?? '',
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingDashboardHeader extends StatelessWidget {
  const _FloatingDashboardHeader({
    required this.role,
    required this.onProfileTap,
    required this.onRefresh,
  });

  final String role;
  final VoidCallback? onProfileTap;
  final VoidCallback onRefresh;

  String get _roleLabel => switch (role) {
    'owner' => 'Owner',
    'kasir' => 'Kasir',
    'operator' => 'Operator',
    'member' => 'Member',
    _ => role,
  };

  @override
  Widget build(BuildContext context) {
    final userName =
        context.watch<AuthProvider>().user?['name'] as String? ?? _roleLabel;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFE).withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF526B8A).withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          const BoxShadow(
            color: Colors.white,
            blurRadius: 8,
            offset: Offset(-3, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, $userName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF172B4D),
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Panel $_roleLabel • Semoga hari ini lancar',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Muat ulang data',
            onPressed: onRefresh,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF0F4F9),
              foregroundColor: const Color(0xFF52657D),
              fixedSize: const Size(42, 42),
              elevation: 2,
              shadowColor: const Color(0xFF526B8A).withValues(alpha: 0.18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 22),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Notifikasi',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Belum ada notifikasi baru.')),
            ),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF0F4F9),
              foregroundColor: const Color(0xFF52657D),
              fixedSize: const Size(42, 42),
              elevation: 2,
              shadowColor: const Color(0xFF526B8A).withValues(alpha: 0.18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.notifications_none_rounded, size: 22),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onProfileTap,
              customBorder: const CircleBorder(),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF58A8F5), Color(0xFF2369C8)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2369C8).withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
