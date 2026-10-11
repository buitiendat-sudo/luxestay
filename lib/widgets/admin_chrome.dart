import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'notification_center_button.dart';

const adminInk = Color(0xFF171717);
const adminMuted = Color(0xFF8A8A8A);
const adminCanvas = Color(0xFFF7F7F7);
const adminOrange = Color(0xFFFF8A24);
const adminBorder = Color(0xFFEEEEEE);

class AdminHeader extends StatelessWidget implements PreferredSizeWidget {
  const AdminHeader({
    super.key,
    required this.title,
    this.onLogout,
    this.actions = const [],
  });

  final String title;
  final VoidCallback? onLogout;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(62);

  @override
  Widget build(BuildContext context) {
    final isOwner = context.watch<AuthProvider>().isOwner;
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: adminInk,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.home_work_outlined,
              color: adminOrange,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isOwner ? 'LUXESTAY OWNER' : 'LUXESTAY ADMIN',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1,
                    color: adminOrange,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: adminInk,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          ...actions,
          const NotificationCenterButton(iconColor: adminInk),
          PopupMenuButton<String>(
            tooltip: 'Tài khoản',
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: adminInk,
              child: Icon(Icons.person_outline, color: Colors.white, size: 19),
            ),
            onSelected: (value) {
              if (value != 'logout') return;

              showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Đăng xuất'),
                  content: const Text(
                    'Bạn có chắc muốn đăng xuất khỏi LuxeStay Admin?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Hủy'),
                    ),
                    FilledButton(
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        if (onLogout != null) {
                          onLogout!();
                        } else {
                          await context.read<AuthProvider>().logout();
                        }
                        if (context.mounted) {
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        }
                      },
                      child: const Text('Đăng xuất'),
                    ),
                  ],
                ),
              );
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18),
                    SizedBox(width: 8),
                    Text('Đăng xuất'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: adminBorder),
      ),
    );
  }
}

class AdminBottomNavigation extends StatelessWidget {
  const AdminBottomNavigation({
    super.key,
    required this.selectedIndex,
    this.popToParentOnReselect = false,
  });

  final int selectedIndex;
  final bool popToParentOnReselect;

  static const _routes = ['/admin/dashboard', '/admin/hotels', '/admin/users'];

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard_rounded),
      label: 'Tổng quan',
    ),
    NavigationDestination(
      icon: Icon(Icons.receipt_long_outlined),
      selectedIcon: Icon(Icons.receipt_long_rounded),
      label: 'Khách sạn',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings_rounded),
      label: 'Nhân sự',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isOwner = context.watch<AuthProvider>().isOwner;
    final routes = isOwner
        ? const ['/owner/dashboard', '/owner/rooms', '/owner/bookings']
        : _routes;
    final destinations = isOwner
        ? const [
            NavigationDestination(
              icon: Icon(Icons.payments_outlined),
              selectedIcon: Icon(Icons.payments_rounded),
              label: 'Doanh thu',
            ),
            NavigationDestination(
              icon: Icon(Icons.bed_outlined),
              selectedIcon: Icon(Icons.bed_rounded),
              label: 'Phòng',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Đặt phòng',
            ),
          ]
        : _destinations;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: adminBorder)),
      ),
      child: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            if (index == selectedIndex) {
              final route = ModalRoute.of(context);
              if (popToParentOnReselect &&
                  route?.settings.name == null &&
                  Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
              return;
            }
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(routes[index], (route) => route.isFirst);
          },
          height: 64,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          indicatorColor: const Color(0xFFFFE9D5),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: destinations,
        ),
      ),
    );
  }
}

class AdminKpiCard extends StatelessWidget {
  const AdminKpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
  });

  final String title;
  final String value;
  final IconData icon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: adminBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1E5),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: adminOrange, size: 17),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              color: adminInk,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: adminMuted, fontSize: 10),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF16865C),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AdminSectionTitle extends StatelessWidget {
  const AdminSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: adminInk,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (subtitle case final String subtitleText) ...[
                const SizedBox(height: 3),
                Text(
                  subtitleText,
                  style: const TextStyle(color: adminMuted, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

enum AdminStatusType { success, warning, danger, info, neutral }

class AdminStatusBadge extends StatelessWidget {
  const AdminStatusBadge({
    super.key,
    required this.label,
    this.type = AdminStatusType.success,
  });

  final String label;
  final AdminStatusType type;

  @override
  Widget build(BuildContext context) {
    final colors = switch (type) {
      AdminStatusType.success => (
        const Color(0xFFE1F7E9),
        const Color(0xFF16834A),
      ),
      AdminStatusType.warning => (
        const Color(0xFFFFEEDB),
        const Color(0xFFB45309),
      ),
      AdminStatusType.danger => (
        const Color(0xFFFFE4E6),
        const Color(0xFFBE123C),
      ),
      AdminStatusType.info => (
        const Color(0xFFE0F2FE),
        const Color(0xFF0369A1),
      ),
      AdminStatusType.neutral => (
        const Color(0xFFF1F5F9),
        const Color(0xFF475569),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.$2,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
  });

  final IconData icon;
  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 35),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: adminBorder),
      ),
      child: Column(
        children: [
          Icon(icon, size: 35, color: const Color(0xFF9CA3AF)),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          if (description != null) ...[
            const SizedBox(height: 5),
            Text(
              description!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: adminMuted, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}
