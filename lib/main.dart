import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/customer/account_screen.dart';
import 'screens/customer/explore_screen.dart';
import 'screens/customer/favorites_screen.dart';
import 'screens/customer/trips_screen.dart';
import 'services/firestore_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const LuxestayApp());
}

class LuxestayApp extends StatelessWidget {
  const LuxestayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        Provider(
          create: (_) => FirestoreService(),
        ),
      ],
      child: MaterialApp(
        title: 'LuxeStay',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFD97706),
          ),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  static const _screens = [
    ExploreScreen(),
    FavoritesScreen(),
    TripsScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Khám phá',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Yêu thích',
          ),
          NavigationDestination(
            icon: Icon(Icons.luggage_outlined),
            selectedIcon: Icon(Icons.luggage),
            label: 'Chuyến đi',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}

class AdminDashboardScreen
    extends StatelessWidget {
  const AdminDashboardScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final auth =
        context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor:
          const Color(0xFFF8FAFC),

      appBar: AppBar(
        automaticallyImplyLeading:
            false,

        title: const Text(
          'LuxeStay Admin',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: () async {
              await context
                  .read<AuthProvider>()
                  .logout();
            },
            icon: const Icon(
              Icons.logout,
            ),
          ),

          const SizedBox(
            width: 8,
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ==================================================
            // HEADER
            // ==================================================

            const Text(
              'Xin chào Admin 👋',
              style: TextStyle(
                fontSize: 26,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              auth.user?.email ?? '',
              style: TextStyle(
                color:
                    Colors.grey.shade600,
              ),
            ),

            const SizedBox(
              height: 28,
            ),

            // ==================================================
            // DASHBOARD TITLE
            // ==================================================

            const Text(
              'Tổng quan',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            // ==================================================
            // STATISTICS
            // ==================================================

            GridView.count(
              crossAxisCount: 2,

              shrinkWrap: true,

              physics:
                  const NeverScrollableScrollPhysics(),

              crossAxisSpacing: 14,

              mainAxisSpacing: 14,

              childAspectRatio: 1.35,

              children: const [
                _DashboardCard(
                  title: 'Resort',
                  value: '8',
                  icon:
                      Icons.hotel_outlined,
                ),

                _DashboardCard(
                  title: 'Phòng',
                  value: '20',
                  icon:
                      Icons.bed_outlined,
                ),

                _DashboardCard(
                  title: 'Booking',
                  value: '3',
                  icon: Icons
                      .calendar_month_outlined,
                ),

                _DashboardCard(
                  title: 'Khách hàng',
                  value: '3',
                  icon:
                      Icons.people_outline,
                ),
              ],
            ),

            const SizedBox(
              height: 30,
            ),

            // ==================================================
            // MANAGEMENT
            // ==================================================

            const Text(
              'Quản lý',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            const _ManagementItem(
              icon:
                  Icons.hotel_outlined,
              title:
                  'Quản lý Resort',
              subtitle:
                  'Thêm, sửa và xóa resort',
            ),

            const SizedBox(
              height: 12,
            ),

            const _ManagementItem(
              icon:
                  Icons.bed_outlined,
              title:
                  'Quản lý phòng',
              subtitle:
                  'Quản lý phòng và tình trạng bán',
            ),

            const SizedBox(
              height: 12,
            ),

            const _ManagementItem(
              icon: Icons
                  .calendar_month_outlined,
              title:
                  'Quản lý Booking',
              subtitle:
                  'Xác nhận và xử lý đặt phòng',
            ),

            const SizedBox(
              height: 12,
            ),

            const _ManagementItem(
              icon:
                  Icons.people_outline,
              title:
                  'Quản lý khách hàng',
              subtitle:
                  'Danh sách người dùng LuxeStay',
            ),

            const SizedBox(
              height: 12,
            ),

            const _ManagementItem(
              icon:
                  Icons.star_outline,
              title:
                  'Quản lý đánh giá',
              subtitle:
                  'Xem đánh giá của khách hàng',
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// DASHBOARD CARD
// ================================================================

class _DashboardCard
    extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color:
              Colors.grey.shade200,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,
        children: [
          Container(
            width: 42,
            height: 42,

            decoration: BoxDecoration(
              color:
                  const Color(
                0xFFFFF7ED,
              ),

              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),

            child: Icon(
              icon,
              color:
                  const Color(
                0xFFD97706,
              ),
            ),
          ),

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style:
                    const TextStyle(
                  fontSize: 24,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              Text(
                title,
                style: TextStyle(
                  color: Colors
                      .grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ================================================================
// MANAGEMENT ITEM
// ================================================================

class _ManagementItem
    extends StatelessWidget {
  const _ManagementItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(16),

        border: Border.all(
          color:
              Colors.grey.shade200,
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,

            decoration: BoxDecoration(
              color:
                  const Color(
                0xFFFFF7ED,
              ),

              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),

            child: Icon(
              icon,
              color:
                  const Color(
                0xFFD97706,
              ),
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors
                        .grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.chevron_right,
          ),
        ],
      ),
    );
  }
}