import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';

import 'screens/admin/admin_bookings_screen.dart';
import 'screens/admin/admin_hotels_screen.dart';
import 'screens/admin/admin_operations_screen.dart';
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
  await initializeDateFormatting('vi_VN');
  Intl.defaultLocale = 'vi_VN';

  // ============================================================
  // FIREBASE
  // ============================================================

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ============================================================
  // FIREBASE APP CHECK
  // ============================================================

  if (kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      webProvider: ReCaptchaV3Provider(
        '6LdHb9ctAAAAAG2quC3rkEuV-FsmPWAlR2nDeVQc',
      ),
    );
  } else {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
  }

  // ============================================================
  // START APP
  // ============================================================

  runApp(const LuxestayApp());
}

class LuxestayApp extends StatelessWidget {
  const LuxestayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        Provider(create: (_) => FirestoreService()),
      ],
      child: MaterialApp(
        title: 'LuxeStay',
        debugShowCheckedModeBanner: false,

        // ======================================================
        // THEME
        // ======================================================
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

// ================================================================
// CUSTOMER MAIN NAVIGATION
// ================================================================

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
      body: IndexedStack(index: _selectedIndex, children: _screens),

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

// ================================================================
// ADMIN DASHBOARD
// ================================================================

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),

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
            1 => const AdminRoomMapScreen(),
            2 => const AdminRoomsScreen(),
            _ => const AdminCheckinScreen(),
          };

          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        },
      ),

      body: AdminOperationsDashboard(
        additionalContent: [
          const SizedBox(height: 16),
          const Text(
            'Quản lý hệ thống',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          _ManagementItem(
            icon: Icons.hotel_outlined,
            title: 'Quản lý Resort',
            subtitle: 'Cập nhật thông tin và trạng thái cơ sở',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminHotelsScreen()),
            ),
          ),
          const SizedBox(height: 8),
          _ManagementItem(
            icon: Icons.calendar_month_outlined,
            title: 'Tất cả booking',
            subtitle: 'Duyệt, cập nhật và theo dõi đặt phòng',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminBookingsScreen()),
            ),
          ),
          const SizedBox(height: 8),
          _ManagementItem(
            icon: Icons.people_outline,
            title: 'Tài khoản khách hàng',
            subtitle: 'Danh sách và phân quyền người dùng',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// MANAGEMENT ITEM
// ================================================================

class _ManagementItem extends StatelessWidget {
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
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(16),

          border: Border.all(color: Colors.grey.shade200),
        ),

        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,

              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),

                borderRadius: BorderRadius.circular(14),
              ),

              child: Icon(icon, color: const Color(0xFFD97706)),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
