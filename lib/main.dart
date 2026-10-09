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

import 'screens/admin/admin_operations_screen.dart';
import 'screens/admin/admin_hotels_screen.dart';
import 'screens/admin/admin_users_screen.dart';

import 'screens/auth/auth_gate.dart';
import 'screens/owner/owner_bookings_screen.dart';
import 'screens/owner/owner_dashboard_screen.dart';
import 'screens/owner/owner_rooms_screen.dart';

import 'screens/customer/account_screen.dart';
import 'screens/customer/explore_screen.dart';
import 'screens/customer/favorites_screen.dart';
import 'screens/customer/trips_screen.dart';

import 'services/firestore_service.dart';
import 'services/image_storage_service.dart';

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
        Provider(create: (_) => ImageStorageService()),
      ],
      child: MaterialApp(
        title: 'LuxeStay',
        debugShowCheckedModeBanner: false,
        routes: {
          '/admin/dashboard': (_) => const AdminDashboardScreen(),
          '/admin/hotels': (_) => const AdminHotelsScreen(),
          '/admin/users': (_) => const AdminUsersScreen(),
          '/owner/dashboard': (_) => const OwnerDashboardScreen(),
          '/owner/rooms': (_) => const OwnerRoomsScreen(),
          '/owner/bookings': (_) => const OwnerBookingsScreen(),
        },

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

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Tổng quan',
          style: TextStyle(
            color: adminInk,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Tài khoản',
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: adminInk,
              child: Icon(Icons.person_outline, color: Colors.white, size: 19),
            ),
            onSelected: (value) {
              if (value == 'logout') context.read<AuthProvider>().logout();
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
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: const AdminBottomNavigation(selectedIndex: 0),
      body: const AdminOperationsDashboard(),
    );
  }
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
