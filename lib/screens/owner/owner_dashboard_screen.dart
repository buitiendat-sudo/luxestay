import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/admin_chrome.dart';
import '../../widgets/revenue_chart.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  String? _requestedPropertyId;
  RevenuePeriod _period = RevenuePeriod.month;
  Future<RevenueReport>? _reportFuture;

  @override
  void initState() {
    super.initState();
    final showOnboardingSuccess = context
        .read<AuthProvider>()
        .consumeOwnerOnboardingSuccess();
    if (showOnboardingSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Đăng ký chủ khách sạn thành công. Chào mừng bạn đến dashboard!',
            ),
          ),
        );
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final propertyId = context.read<AuthProvider>().propertyId;
    if (_requestedPropertyId != propertyId) {
      _requestedPropertyId = propertyId;
      _reportFuture = propertyId == null || propertyId.isEmpty
          ? null
          : context.read<FirestoreService>().getRevenueReport(
              propertyId: propertyId,
              period: _period,
            );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final propertyId = auth.propertyId;

    return Scaffold(
      backgroundColor: adminCanvas,
      appBar: AdminHeader(
        title: 'Tổng quan khách sạn',
        actions: [
          IconButton(
            tooltip: 'Làm mới doanh thu',
            onPressed: propertyId == null || propertyId.isEmpty
                ? null
                : () => setState(() {
                    _reportFuture = context
                        .read<FirestoreService>()
                        .getRevenueReport(
                          propertyId: propertyId,
                          period: _period,
                        );
                  }),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      bottomNavigationBar: const AdminBottomNavigation(selectedIndex: 0),
      body: propertyId == null || propertyId.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Tài khoản chủ khách sạn chưa được liên kết với cơ sở. Vui lòng liên hệ quản trị viên.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Xin chào, ${auth.user?.displayName ?? 'Chủ khách sạn'}',
                  style: const TextStyle(
                    color: adminInk,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Số liệu chỉ bao gồm khách sạn được liên kết với tài khoản này.',
                  style: TextStyle(color: adminMuted, fontSize: 12),
                ),
                const SizedBox(height: 16),
                RevenuePeriodFilter(
                  value: _period,
                  onChanged: (period) => setState(() {
                    _period = period;
                    _reportFuture = context
                        .read<FirestoreService>()
                        .getRevenueReport(
                          propertyId: propertyId,
                          period: _period,
                        );
                  }),
                ),
                const SizedBox(height: 12),
                FutureBuilder<RevenueReport>(
                  future: _reportFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _ReportError(
                        message: snapshot.error.toString(),
                        onRetry: () => setState(() {
                          _reportFuture = context
                              .read<FirestoreService>()
                              .getRevenueReport(
                                propertyId: propertyId,
                                period: _period,
                              );
                        }),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(30),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final report = snapshot.data!;
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                title: 'Doanh thu đã thu',
                                value: _money(report.totalRevenue),
                                icon: Icons.payments_outlined,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MetricCard(
                                title: 'Đơn đã thanh toán',
                                value: '${report.paidBookingCount}',
                                icon: Icons.receipt_long_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        RevenueTrendChart(report: report),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 22),
                const AdminSectionTitle(
                  title: 'Nhân sự khách sạn',
                  subtitle: 'Nhân viên được quản trị viên gán cho cơ sở này',
                ),
                const SizedBox(height: 10),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: context.read<FirestoreService>().watchStaffByProperty(
                    propertyId,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _ReportError(
                        message: 'Không thể tải nhân sự: ${snapshot.error}',
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final staff = snapshot.data!;
                    if (staff.isEmpty) {
                      return const AdminEmptyState(
                        icon: Icons.groups_outlined,
                        title: 'Chưa có nhân viên được phân công',
                        description:
                            'Quản trị viên có thể gán nhân sự cho khách sạn.',
                      );
                    }
                    return Column(
                      children: staff.map((person) {
                        final name =
                            person['displayName']?.toString() ??
                            person['name']?.toString() ??
                            'Nhân viên';
                        return Card(
                          color: Colors.white,
                          elevation: 0,
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person_outline),
                            ),
                            title: Text(name),
                            subtitle: Text(person['email']?.toString() ?? ''),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: adminBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: adminOrange),
        const SizedBox(height: 10),
        Text(title, style: const TextStyle(color: adminMuted, fontSize: 11)),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: adminInk,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _ReportError extends StatelessWidget {
  const _ReportError({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    ),
  );
}

String _money(int value) => '${NumberFormat('#,###', 'vi_VN').format(value)} ₫';
