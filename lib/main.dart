import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/admin/admin_bookings_screen.dart';
import 'screens/admin/admin_hotels_screen.dart';
import 'screens/admin/admin_rooms_screen.dart';
import 'screens/admin/admin_users_screen.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/customer/account_screen.dart';
import 'screens/customer/explore_screen.dart';
import 'screens/customer/favorites_screen.dart';
import 'screens/customer/trips_screen.dart';
import 'services/firestore_service.dart';
import 'widgets/admin_chrome.dart';

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
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF0F172A),
            onPrimary: Colors.white,
            secondary: Color(0xFFD97706),
            surface: Color(0xFFFFFFFF),
            onSurface: Color(0xFF0B1C30),
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF8F9FF),
          textTheme: GoogleFonts.plusJakartaSansTextTheme(),
          appBarTheme: AppBarTheme(
            backgroundColor: const Color(0xFFF8F9FF),
            foregroundColor: const Color(0xFF0F172A),
            elevation: 0,
            centerTitle: false,
            titleTextStyle: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF0F172A),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: const Color(0xFFFBFBFF),
            height: 72,
            indicatorColor: Colors.transparent,
            labelTextStyle: WidgetStatePropertyAll(
              GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            iconTheme: const WidgetStatePropertyAll(
              IconThemeData(color: Color(0xFF0F172A)),
            ),
          ),
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
          const Color(0xFFF5F7FF),

      appBar: AdminHeader(
        title: 'Tổng quan',
        onLogout: () {
          context.read<AuthProvider>().logout();
        },
      ),

      bottomNavigationBar: AdminBottomNavigation(
        selectedIndex: 0,
        onSelected: (index) {
          if (index == 0) return;
          final page = switch (index) {
            1 => const AdminRoomsScreen(),
            2 => const AdminBookingsScreen(),
            _ => const AdminUsersScreen(),
          };
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
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

            _DashboardStats(
              firestore: context.read<FirestoreService>(),
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

            _ManagementItem(
              icon:
                  Icons.hotel_outlined,
              title:
                  'Quản lý Resort',
              subtitle:
                  'Thêm, sửa và xóa resort',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminHotelsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(
              height: 12,
            ),

            _ManagementItem(
              icon:
                  Icons.bed_outlined,
              title:
                  'Quản lý phòng',
              subtitle:
                  'Quản lý phòng và tình trạng bán',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminRoomsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(
              height: 12,
            ),

            _ManagementItem(
              icon: Icons
                  .calendar_month_outlined,
              title:
                  'Quản lý Booking',
              subtitle:
                  'Xác nhận và xử lý đặt phòng',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminBookingsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(
              height: 12,
            ),

            _ManagementItem(
              icon:
                  Icons.people_outline,
              title:
                  'Quản lý khách hàng',
              subtitle:
                  'Danh sách người dùng LuxeStay',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminUsersScreen(),
                  ),
                );
              },
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

class _DashboardStats extends StatelessWidget {
  const _DashboardStats({required this.firestore});

  final FirestoreService firestore;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: firestore.watchProperties(),
      builder: (context, propertiesSnapshot) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: firestore.watchRooms(),
          builder: (context, roomsSnapshot) {
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: firestore.watchBookings(),
              builder: (context, bookingsSnapshot) {
                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: firestore.watchUsers(),
                  builder: (context, usersSnapshot) {
                    final customerCount = usersSnapshot.data
                            ?.where(
                              (user) =>
                                  user['role']?.toString().toUpperCase() !=
                                  'ADMIN',
                            )
                            .length ??
                        0;

                    return GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.35,
                      children: [
                        _DashboardCard(
                          title: 'Resort',
                          value: '${propertiesSnapshot.data?.length ?? 0}',
                          icon: Icons.hotel_outlined,
                        ),
                        _DashboardCard(
                          title: 'Phòng',
                          value: '${roomsSnapshot.data?.length ?? 0}',
                          icon: Icons.bed_outlined,
                        ),
                        _DashboardCard(
                          title: 'Booking',
                          value: '${bookingsSnapshot.data?.length ?? 0}',
                          icon: Icons.calendar_month_outlined,
                        ),
                        _DashboardCard(
                          title: 'Khách hàng',
                          value: '$customerCount',
                          icon: Icons.people_outline,
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
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
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
      ),
    );
  }
}
