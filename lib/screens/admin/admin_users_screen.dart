import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../services/firestore_service.dart';
import '../../widgets/admin_chrome.dart';
import 'admin_bookings_screen.dart';
import 'admin_hotels_screen.dart';
import 'admin_rooms_screen.dart';

class AdminUsersScreen
    extends StatefulWidget {
  const AdminUsersScreen({
    super.key,
  });

  @override
  State<AdminUsersScreen>
      createState() =>
          _AdminUsersScreenState();
}

class _AdminUsersScreenState
    extends State<AdminUsersScreen> {
  String _filter = 'CUSTOMER';

  @override
  Widget build(BuildContext context) {
    final firestore =
        context.read<FirestoreService>();

    return Scaffold(
      backgroundColor:
          const Color(0xFFF6F7FB),
      appBar: const AdminHeader(
        title: 'Người dùng & Phân quyền',
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                'Tạo tài khoản Firebase Auth cần triển khai qua backend/Admin SDK để không đăng xuất Admin hiện tại.',
              ),
            ),
          );
        },
        icon:
            const Icon(Icons.add),
        label: const Text(
          'Thêm tài khoản',
        ),
      ),
      bottomNavigationBar:
          AdminBottomNavigation(
        selectedIndex: 3,
        onSelected: (index) {
          if (index == 3) return;

          final page = switch (index) {
            0 =>
              const AdminHotelsScreen(),
            1 =>
              const AdminRoomsScreen(),
            _ =>
              const AdminBookingsScreen(),
          };

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => page,
            ),
          );
        },
      ),
      body: StreamBuilder<
          List<Map<String, dynamic>>>(
        stream: firestore.watchUsers(),
        builder: (
          context,
          snapshot,
        ) {
          if (!snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final users =
              snapshot.data!;

          final customers =
              users.where(
            (user) =>
                _role(user) ==
                'CUSTOMER',
          );

          final admins =
              users.where(
            (user) =>
                _role(user) == 'ADMIN',
          );

          final owners =
              users.where(
            (user) =>
                _role(user) == 'OWNER',
          );

          final filtered =
              users.where(
            (user) =>
                _role(user) == _filter,
          ).toList();

          return ListView(
            padding:
                const EdgeInsets.fromLTRB(
              14,
              14,
              14,
              90,
            ),
            children: [
              const Text(
                'Tổng quan tài khoản',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection:
                      Axis.horizontal,
                  children: [
                    SizedBox(
                      width: 145,
                      child: AdminKpiCard(
                        title:
                            'Tổng tài khoản',
                        value:
                            '${users.length}',
                        icon: Icons
                            .people_outline,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 145,
                      child: AdminKpiCard(
                        title:
                            'Khách hàng',
                        value:
                            '${customers.length}',
                        icon: Icons
                            .person_outline,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 145,
                      child: AdminKpiCard(
                        title:
                            'Chủ khách sạn',
                        value:
                            '${owners.length}',
                        icon: Icons
                            .business_center_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 145,
                      child: AdminKpiCard(
                        title:
                            'Ban quản trị',
                        value:
                            '${admins.length}',
                        icon: Icons
                            .admin_panel_settings_outlined,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              SingleChildScrollView(
                scrollDirection:
                    Axis.horizontal,
                child: SegmentedButton<
                    String>(
                  segments: const [
                    ButtonSegment(
                      value: 'CUSTOMER',
                      label: Text(
                        'Khách hàng',
                      ),
                    ),
                    ButtonSegment(
                      value: 'OWNER',
                      label: Text(
                        'Chủ khách sạn',
                      ),
                    ),
                    ButtonSegment(
                      value: 'ADMIN',
                      label: Text(
                        'Quản trị',
                      ),
                    ),
                  ],
                  selected: {
                    _filter,
                  },
                  onSelectionChanged:
                      (selection) {
                    setState(() {
                      _filter =
                          selection.first;
                    });
                  },
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              Text(
                'Danh sách (${filtered.length})',
                style:
                    const TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              if (filtered.isEmpty)
                const Padding(
                  padding:
                      EdgeInsets.all(
                    40,
                  ),
                  child: Center(
                    child: Text(
                      'Không có tài khoản.',
                    ),
                  ),
                )
              else
                ...filtered.map(
                  (user) =>
                      _UserCard(
                    user: user,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static String _role(
    Map<String, dynamic> user,
  ) {
    return user['role']
            ?.toString()
            .toUpperCase() ??
        'CUSTOMER';
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
  });

  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context) {
    final id =
        user['id'].toString();

    final role =
        user['role']
                ?.toString()
                .toUpperCase() ??
            'CUSTOMER';

    final spending =
        (user['totalSpending']
                    as num?)
                ?.toInt() ??
            0;

    final tier =
        user['membershipTier']
                ?.toString() ??
            _tierFromSpending(
              spending,
            );

    final twoFactor =
        user['twoFactorEnabled'] ==
            true;

    final active =
        user['isActive'] != false;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 11,
      ),
      padding:
          const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(15),
        border: Border.all(
          color:
              const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    const Color(
                  0xFFFFEDD5,
                ),
                child: Text(
                  _initials(
                    user['displayName']
                            ?.toString() ??
                        'User',
                  ),
                  style:
                      const TextStyle(
                    color:
                        Color(0xFFEA580C),
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),

              const SizedBox(
                width: 11,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      user['displayName']
                              ?.toString() ??
                          'LuxeStay User',
                      style:
                          const TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      user['email']
                              ?.toString() ??
                          '',
                      style:
                          const TextStyle(
                        color:
                            Color(
                          0xFF64748B,
                        ),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              _TierBadge(
                tier: tier,
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _UserInfo(
                  label:
                      'Tổng chi tiêu',
                  value:
                      '${NumberFormat('#,###', 'vi_VN').format(spending)}đ',
                ),
              ),
              Expanded(
                child: _UserInfo(
                  label: '2FA',
                  value: twoFactor
                      ? 'Đã bật'
                      : 'Chưa bật',
                ),
              ),
              Expanded(
                child: _UserInfo(
                  label:
                      'Phân quyền',
                  value: role,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child:
                    OutlinedButton(
                  onPressed: () {
                    _changeRole(
                      context,
                      id,
                      role,
                    );
                  },
                  child: const Text(
                    'Phân quyền',
                  ),
                ),
              ),

              const SizedBox(width: 7),

              Expanded(
                child:
                    OutlinedButton(
                  onPressed: () {
                    context
                        .read<
                            FirestoreService>()
                        .updateUserStatus(
                          userId: id,
                          active:
                              !active,
                        );
                  },
                  child: Text(
                    active
                        ? 'Tạm khóa'
                        : 'Mở khóa',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void _changeRole(
    BuildContext context,
    String userId,
    String currentRole,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Padding(
                padding:
                    EdgeInsets.all(
                  14,
                ),
                child: Text(
                  'Thay đổi phân quyền',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),
              ...[
                'CUSTOMER',
                'OWNER',
                'ADMIN',
              ].map(
                (role) =>
                    ListTile(
                  leading: Icon(
                    currentRole == role
                        ? Icons
                            .radio_button_checked
                        : Icons
                            .radio_button_off,
                  ),
                  title: Text(role),
                  onTap: () async {
                    await context
                        .read<
                            FirestoreService>()
                        .updateUserRole(
                          userId:
                              userId,
                          role: role,
                        );

                    if (sheetContext
                        .mounted) {
                      Navigator.pop(
                        sheetContext,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _tierFromSpending(
    int spending,
  ) {
    if (spending >= 100000000) {
      return 'BLACK';
    }

    if (spending >= 50000000) {
      return 'DIAMOND';
    }

    return 'SILVER';
  }

  static String _initials(
    String name,
  ) {
    final parts = name
        .trim()
        .split(
          RegExp(r'\s+'),
        );

    if (parts.isEmpty) return 'U';

    if (parts.length == 1) {
      return parts.first
          .substring(0, 1)
          .toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'
        .toUpperCase();
  }
}

class _UserInfo extends StatelessWidget {
  const _UserInfo({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color:
                Color(0xFF94A3B8),
            fontSize: 8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TierBadge extends StatelessWidget {
  const _TierBadge({
    required this.tier,
  });

  final String tier;

  @override
  Widget build(BuildContext context) {
    final normalized =
        tier.toUpperCase();

    final label = switch (normalized) {
      'BLACK' => 'Black',
      'DIAMOND' => 'Diamond',
      _ => 'Bạc',
    };

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: normalized == 'BLACK'
            ? const Color(0xFF111827)
            : normalized == 'DIAMOND'
                ? const Color(
                    0xFFDBEAFE,
                  )
                : const Color(
                    0xFFF1F5F9,
                  ),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: normalized == 'BLACK'
              ? Colors.white
              : const Color(
                  0xFF334155,
                ),
          fontSize: 8,
          fontWeight:
              FontWeight.w800,
        ),
      ),
    );
  }
}