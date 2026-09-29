import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

// ============================================================
// ADMIN HEADER
// ============================================================

class AdminHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const AdminHeader({
    super.key,
    required this.title,
    this.onLogout,
  });

  final String title;
  final VoidCallback? onLogout;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final logout = onLogout ??
        () => context.read<AuthProvider>().logout();

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 16,

      // ========================================================
      // LOGO + TITLE
      // ========================================================
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.apartment_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'LUXESTAY ADMIN',
                  style: TextStyle(
                    color: Color(0xFFEA580C),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // ========================================================
      // ACTIONS
      // ========================================================
      actions: [
        // Notification
        IconButton(
          tooltip: 'Thông báo',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Bạn chưa có thông báo mới.',
                ),
              ),
            );
          },
          icon: const Badge(
            smallSize: 7,
            child: Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF334155),
            ),
          ),
        ),

        // Admin account / logout
        PopupMenuButton<String>(
            tooltip: 'Tài khoản Admin',
            offset: const Offset(0, 45),
            icon: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFF111827),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog(context, logout);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LuxeStay Admin',
                      style: TextStyle(
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Quản trị hệ thống',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      size: 19,
                      color: Color(0xFFDC2626),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Đăng xuất',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

        const SizedBox(width: 8),
      ],

      // ========================================================
      // BORDER BOTTOM
      // ========================================================
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: const Color(0xFFE5E7EB),
        ),
      ),
    );
  }

  void _showLogoutDialog(
    BuildContext context,
    VoidCallback logout,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: Color(0xFFDC2626),
              ),
              SizedBox(width: 10),
              Text(
                'Đăng xuất',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          content: const Text(
            'Bạn có chắc chắn muốn đăng xuất khỏi LuxeStay Admin?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Hủy'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                logout();
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(
                Icons.logout_rounded,
                size: 18,
              ),
              label: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================
// ADMIN BOTTOM NAVIGATION
// ============================================================

class AdminBottomNavigation extends StatelessWidget {
  const AdminBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onSelected,
          height: 70,
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          indicatorColor: const Color(0xFFFFE8D2),
          labelBehavior:
              NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(
                Icons.apartment_outlined,
                color: Color(0xFF64748B),
              ),
              selectedIcon: Icon(
                Icons.apartment_rounded,
                color: Color(0xFFEA580C),
              ),
              label: 'Khách sạn',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.bed_outlined,
                color: Color(0xFF64748B),
              ),
              selectedIcon: Icon(
                Icons.bed_rounded,
                color: Color(0xFFEA580C),
              ),
              label: 'Phòng',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.calendar_month_outlined,
                color: Color(0xFF64748B),
              ),
              selectedIcon: Icon(
                Icons.calendar_month_rounded,
                color: Color(0xFFEA580C),
              ),
              label: 'Đặt phòng',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.people_outline_rounded,
                color: Color(0xFF64748B),
              ),
              selectedIcon: Icon(
                Icons.people_rounded,
                color: Color(0xFFEA580C),
              ),
              label: 'Người dùng',
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ADMIN KPI CARD
// ============================================================

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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.025,
            ),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1E6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 19,
              color: const Color(0xFFEA580C),
            ),
          ),

          const Spacer(),

          // Value
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 2),

          // Title
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),

          // Subtitle
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF059669),
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// ADMIN SECTION TITLE
// ============================================================

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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Dart null-aware collection element
        if (trailing != null) ...[
          const SizedBox(width: 10),
          trailing!,
        ],
      ],
    );
  }
}

// ============================================================
// ADMIN STATUS BADGE
// ============================================================

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
    final backgroundColor = switch (type) {
      AdminStatusType.success => const Color(0xFFDCFCE7),
      AdminStatusType.warning => const Color(0xFFFFEDD5),
      AdminStatusType.danger => const Color(0xFFFEE2E2),
      AdminStatusType.info => const Color(0xFFDBEAFE),
      AdminStatusType.neutral => const Color(0xFFF1F5F9),
    };

    final foregroundColor = switch (type) {
      AdminStatusType.success => const Color(0xFF15803D),
      AdminStatusType.warning => const Color(0xFFEA580C),
      AdminStatusType.danger => const Color(0xFFDC2626),
      AdminStatusType.info => const Color(0xFF2563EB),
      AdminStatusType.neutral => const Color(0xFF475569),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ============================================================
// ADMIN STATUS TYPE
// ============================================================

enum AdminStatusType {
  success,
  warning,
  danger,
  info,
  neutral,
}

// ============================================================
// ADMIN EMPTY STATE
// ============================================================

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
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 40,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 28,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: 5),
            Text(
              description!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}