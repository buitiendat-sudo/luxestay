import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/firestore_service.dart';
import '../../widgets/admin_chrome.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: const AdminHeader(title: 'Quản lý nhân sự'),
      bottomNavigationBar: const AdminBottomNavigation(
        selectedIndex: 2,
        popToParentOnReselect: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: firestore.watchUsers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!;

          final customers = users.where((user) => _role(user) == 'CUSTOMER');

          final owners = users.where((user) => _role(user) == 'OWNER');
          final staffCount = users
              .where((user) => user['isStaff'] == true)
              .length;

          final filtered = users
              .where((user) => _role(user) == 'CUSTOMER')
              .toList(growable: false);

          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
            children: [
              const Text(
                'Nhân sự và tài khoản',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
              ),

              const SizedBox(height: 14),

              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    SizedBox(
                      width: 145,
                      child: AdminKpiCard(
                        title: 'Tổng tài khoản',
                        value: '${users.length}',
                        icon: Icons.people_outline,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 145,
                      child: AdminKpiCard(
                        title: 'Khách hàng',
                        value: '${customers.length}',
                        icon: Icons.person_outline,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 145,
                      child: AdminKpiCard(
                        title: 'Chủ khách sạn',
                        value: '${owners.length}',
                        icon: Icons.business_center_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 145,
                      child: AdminKpiCard(
                        title: 'Nhân sự',
                        value: '$staffCount',
                        icon: Icons.groups_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Text(
                'Tài khoản khách hàng có thể phân công (${filtered.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 10),

              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: Text('Không có tài khoản.')),
                )
              else
                ...filtered.map((user) => _UserCard(user: user)),
            ],
          );
        },
      ),
    );
  }

  static String _role(Map<String, dynamic> user) {
    return user['role']?.toString().toUpperCase() ?? 'CUSTOMER';
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});

  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFFFEDD5),
                child: Text(
                  _initials(user['displayName']?.toString() ?? 'User'),
                  style: const TextStyle(
                    color: Color(0xFFEA580C),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['displayName']?.toString() ?? 'LuxeStay User',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user['email']?.toString() ?? '',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

            ],
          ),

          const SizedBox(height: 10),

          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => _assignStaff(context, user),
              icon: const Icon(Icons.badge_outlined),
              label: Text(
                user['isStaff'] == true ? 'Sửa phân công' : 'Gán nhân sự',
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _assignStaff(BuildContext context, Map<String, dynamic> user) {
    final userId = user['id']?.toString() ?? '';
    var selectedPropertyId = user['propertyId']?.toString() ?? '';
    var isStaff = user['isStaff'] == true;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Phân công nhân sự'),
          content: StreamBuilder<List<Map<String, dynamic>>>(
            stream: context.read<FirestoreService>().watchProperties(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Không thể tải khách sạn: ${snapshot.error}');
              }
              if (!snapshot.hasData) {
                return const SizedBox(
                  height: 70,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final properties = snapshot.data!;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Đánh dấu là nhân sự khách sạn'),
                    value: isStaff,
                    onChanged: (value) => setDialogState(() => isStaff = value),
                  ),
                  if (isStaff)
                    DropdownButtonFormField<String>(
                      initialValue:
                          properties.any(
                            (property) => property['id'] == selectedPropertyId,
                          )
                          ? selectedPropertyId
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Khách sạn được phân công',
                      ),
                      items: properties
                          .map(
                            (property) => DropdownMenuItem<String>(
                              value: property['id'].toString(),
                              child: Text(
                                property['name']?.toString() ?? 'Khách sạn',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedPropertyId = value);
                        }
                      },
                    ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () async {
                if (userId.isEmpty || (isStaff && selectedPropertyId.isEmpty)) {
                  return;
                }
                try {
                  await context.read<FirestoreService>().setUser(
                    userId,
                    isStaff
                        ? {'isStaff': true, 'propertyId': selectedPropertyId}
                        : {'isStaff': false, 'propertyId': FieldValue.delete()},
                  );
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } on FirebaseException catch (error) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Không thể lưu phân công: ${error.message}',
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));

    if (parts.isEmpty) return 'U';

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
