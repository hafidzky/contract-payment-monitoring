import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../core/constants/app_colors.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/contract/contract_list.dart';
import '../features/vendor/vendor_list_page.dart';
import '../features/notifications/notification_page.dart';
import '../features/profile/profile_page.dart';
import '../data/providers/contract_provider.dart';
import 'dart:async';
import '../features/contract/contract_list.dart' show ContractListPage;
import '../features/vendor/vendor_list_page.dart' show VendorListPage;

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  bool _isCollapsed  = false;
  int _hoveredIndex  = -1;

  final List<Widget> _pages = [
    const AdminDashboardPage(),
    const ContractListPage(),
    const VendorListPage(),
    const NotificationPage(),
    const ProfilePage(),
  ];

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0: return 'Dashboard';
      case 1: return 'Daftar Kontrak';
      case 2: return 'Manajemen Vendor';
      case 3: return 'Alerts & Monitoring';
      case 4: return 'Profile';
      default: return '';
    }
  }

  // Hitung alert kritis dari provider
  int _getCriticalCount(BuildContext context) {
    final provider = Provider.of<ContractProvider>(context, listen: false);
    int count = 0;
    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);

    for (final contract in provider.allContracts) {
      final terminJson = contract['termin_data'];
      if (terminJson == null) continue;
      try {
        final termins = jsonDecode(terminJson) as List<dynamic>;
        for (final t in termins) {
          final rawIsPaid = t['is_paid'];
          final isPaid = rawIsPaid == true
              || rawIsPaid == 1
              || rawIsPaid?.toString().toLowerCase() == 'true'
              || t['status']?.toString() == 'Terbayar';
          if (isPaid) continue;

          DateTime? date;
          try {
            date = DateFormat('dd MMM yyyy', 'en_US').parse(t['date']);
          } catch (_) {
            try {
              date = DateFormat('d MMM yyyy').parse(t['date']);
            } catch (_) {}
          }
          if (date == null) continue;

          final diff = date.difference(today).inDays;
          if (diff <= 7) count++;
        }
      } catch (_) {}
    }
    return count;
  }

  // ─── BUILD ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 1100;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          if (isDesktop)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _isCollapsed ? 70 : 240,
              child: _buildSidebar(),
            ),
          Expanded(
            child: Column(
              children: [
                if (isDesktop)
                  _buildHeaderBar()
                else
                  _buildMobileHeader(),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _pages,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop ? null : _buildBottomNavBar(),
    );
  }

  // ─── DESKTOP HEADER ───────────────────────────────────────────
  Widget _buildHeaderBar() {
    return Consumer<ContractProvider>(
      builder: (context, provider, _) {
        final criticalCount = _getCriticalCount(context);

        return Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              // Hamburger
              IconButton(
                icon: Icon(
                  _isCollapsed ? Icons.menu_open : Icons.menu,
                  color: const Color(0xFF002753),
                ),
                onPressed: () =>
                    setState(() => _isCollapsed = !_isCollapsed),
              ),
              const SizedBox(width: 8),

              // Judul halaman aktif
              Text(
                _getPageTitle(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF002753),
                ),
              ),
              const Spacer(),

              // Jam
              const RealTimeClock(),
              const SizedBox(width: 16),
              VerticalDivider(
                indent: 15,
                endIndent: 15,
                thickness: 1,
                color: Colors.grey.shade300,
              ),
              const SizedBox(width: 4),

              // Notifikasi
              _buildNotificationButton(criticalCount),
              const SizedBox(width: 4),

              // Profil
              _buildProfileButton(),
              const SizedBox(width: 8),
            ],
          ),
        );
      },
    );
  }

  // ─── MOBILE HEADER ────────────────────────────────────────────
  Widget _buildMobileHeader() {
    return Consumer<ContractProvider>(
      builder: (context, provider, _) {
        final criticalCount = _getCriticalCount(context);
        return Container(
          color: const Color(0xFF002753),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            bottom: 8,
            left: 16,
            right: 8,
          ),
          child: Row(
            children: [
              const Text(
                'PELINDO',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              // Notifikasi mobile
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: Icon(
                      criticalCount > 0
                          ? Icons.notifications_active
                          : Icons.notifications_none,
                      color: Colors.white,
                    ),
                    onPressed: () =>
                        setState(() => _selectedIndex = 3),
                  ),
                  if (criticalCount > 0)
                    Positioned(
                      top: 6, right: 6,
                      child: Container(
                        width: 16, height: 16,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            criticalCount > 9 ? '9+' : '$criticalCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── NOTIFICATION BUTTON ──────────────────────────────────────
  Widget _buildNotificationButton(int criticalCount) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Alerts & Monitoring',
          icon: Icon(
            criticalCount > 0
                ? Icons.notifications_active
                : Icons.notifications_none,
            color: criticalCount > 0
                ? Colors.red.shade600
                : Colors.grey.shade600,
          ),
          onPressed: () => setState(() => _selectedIndex = 3),
        ),
        if (criticalCount > 0)
          Positioned(
            top: 6, right: 6,
            child: Container(
              width: 18, height: 18,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  criticalCount > 9 ? '9+' : '$criticalCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ─── PROFILE BUTTON ───────────────────────────────────────────
  Widget _buildProfileButton() {
    return PopupMenuButton<String>(
      tooltip: 'Profile',
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14)),
      itemBuilder: (_) => [
        // Header — info user
        PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.person,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Administrator',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      )),
                    Text('Admin',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      )),
                  ],
                ),
              ],
            ),
          ),
        ),

        const PopupMenuDivider(),

        // Edit profil
        PopupMenuItem<String>(
          value: 'profile',
          padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 4),
          child: Row(children: [
            Icon(Icons.person_outline,
                size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 10),
            const Text('Edit Profil',
                style: TextStyle(fontSize: 13)),
          ]),
        ),

        // Manajemen vendor
        PopupMenuItem<String>(
          value: 'vendor',
          padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 4),
          child: Row(children: [
            Icon(Icons.business_outlined,
                size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 10),
            const Text('Manajemen Vendor',
                style: TextStyle(fontSize: 13)),
          ]),
        ),

        // Alerts
        PopupMenuItem<String>(
          value: 'alerts',
          padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 4),
          child: Row(children: [
            Icon(Icons.notifications_outlined,
                size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 10),
            const Text('Alerts',
                style: TextStyle(fontSize: 13)),
          ]),
        ),

        const PopupMenuDivider(),

        // Logout
        PopupMenuItem<String>(
          value: 'logout',
          padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 4),
          child: Row(children: [
            Icon(Icons.logout, size: 18,
                color: Colors.red.shade400),
            const SizedBox(width: 10),
            Text('Logout',
              style: TextStyle(
                fontSize: 13,
                color: Colors.red.shade400,
              )),
          ]),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'profile': setState(() => _selectedIndex = 4); break;
          case 'vendor':  setState(() => _selectedIndex = 2); break;
          case 'alerts':  setState(() => _selectedIndex = 3); break;
          case 'logout':  _showLogoutDialog(); break;
        }
      },
      child: CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.person,
            color: Colors.white, size: 18),
      ),
    );
  }

  // ─── SIDEBAR ──────────────────────────────────────────────────
  Widget _buildSidebar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF001529), Color(0xFF002753)],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildSidebarLogo(),
          const SizedBox(height: 30),
          _sidebarItem(0, Icons.dashboard_outlined,     'Dashboard'),
          _sidebarItem(1, Icons.description_outlined,   'Daftar Kontrak'),
          _sidebarItem(2, Icons.business_outlined,      'Vendor'),
          _sidebarItem(3, Icons.notifications_outlined, 'Alerts'),
          _sidebarItem(4, Icons.person_outline,         'Profile'),
          const Spacer(),
          _sidebarItem(99, Icons.logout, 'Logout'),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSidebarLogo() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(
          horizontal: _isCollapsed ? 10 : 20),
      alignment: Alignment.centerLeft,
      child: _isCollapsed
          ? Center(
              child: Image.asset(
                'assets/images/logo_pelindo_kecil.png',
                height: 35,
                errorBuilder: (ctx, err, st) =>
                    const Icon(Icons.anchor, color: Colors.white),
              ),
            )
          : Image.asset(
              'assets/images/logo_pelindo.png',
              height: 90,
              fit: BoxFit.contain,
              errorBuilder: (ctx, err, st) => const Text(
                'PELINDO',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
    );
  }

  Widget _sidebarItem(int index, IconData icon, String label) {
    final isActive = _selectedIndex == index;
    final isHover  = _hoveredIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit:  (_) => setState(() => _hoveredIndex = -1),
      child: InkWell(
        onTap: () {
          if (index == 99) {
            _showLogoutDialog();
          } else {
            setState(() => _selectedIndex = index);
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 4),
          padding: const EdgeInsets.symmetric(
              vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: (isActive || isHover)
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: _isCollapsed
              ? Center(
                  child: Icon(icon,
                    color: (isActive || isHover)
                        ? Colors.white
                        : Colors.white60),
                )
              : Row(
                  children: [
                    if (isActive)
                      Container(
                        width: 4, height: 24,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      )
                    else
                      const SizedBox(width: 14),
                    Icon(icon,
                      color: (isActive || isHover)
                          ? Colors.white
                          : Colors.white60),
                    const SizedBox(width: 12),
                    Text(label,
                      style: TextStyle(
                        color: (isActive || isHover)
                            ? Colors.white
                            : Colors.white60,
                        fontSize: 14,
                      )),
                  ],
                ),
        ),
      ),
    );
  }

  // ─── LOGOUT DIALOG ────────────────────────────────────────────
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.logout,
                      color: Colors.red.shade600, size: 28),
                ),
                const SizedBox(height: 16),
                const Text('Logout',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  'Apakah Anda yakin ingin keluar?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 110,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                          side: BorderSide(
                              color: Colors.grey.shade300),
                        ),
                        child: const Text('Batal',
                          style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 110,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.of(context)
                              .pushNamedAndRemoveUntil(
                                  '/', (route) => false);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: const Text('Logout',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          )),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── BOTTOM NAV (Mobile) ──────────────────────────────────────
  Widget _buildBottomNavBar() {
    return Consumer<ContractProvider>(
      builder: (context, provider, _) {
        final criticalCount = _getCriticalCount(context);
        return BottomNavigationBar(
          currentIndex: _selectedIndex.clamp(0, 4), // ← fix: clamp 0-4
          onTap: (i) => setState(() => _selectedIndex = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.description_outlined),
              activeIcon: Icon(Icons.description),
              label: 'Kontrak',
            ),
            // ← TAMBAHKAN VENDOR DI SINI (index 2, sama dengan _pages)
            const BottomNavigationBarItem(
              icon: Icon(Icons.business_outlined),
              activeIcon: Icon(Icons.business),
              label: 'Vendor',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_outlined),
                  if (criticalCount > 0)
                    Positioned(
                      top: -4, right: -4,
                      child: Container(
                        width: 16, height: 16,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            criticalCount > 9 ? '9+' : '$criticalCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              activeIcon: const Icon(Icons.notifications),
              label: 'Alerts',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        );
      },
    );
  }
}

// ─── REAL TIME CLOCK ──────────────────────────────────────────
class RealTimeClock extends StatelessWidget {
  const RealTimeClock({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, _) {
        final now = DateTime.now();
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              DateFormat('HH:mm:ss').format(now),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF002753),
                fontFamily: 'monospace',
              ),
            ),
            Text(
              DateFormat('EEEE, d MMMM yyyy').format(now),
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }
}