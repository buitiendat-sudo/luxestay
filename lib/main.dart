import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'services/firestore_service.dart';
import 'screens/customer/explore_screen.dart';
import 'screens/admin/admin_rooms_screen.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/customer/trips_screen.dart';
import 'screens/customer/favorites_screen.dart';
import 'screens/customer/account_screen.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const LuxeStayApp());
}

class LuxeStayApp extends StatelessWidget {
  const LuxeStayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
  providers: [
    Provider<FirestoreService>(
      create: (_) => FirestoreService(),
    ),
    ChangeNotifierProvider<AuthProvider>(
      create: (_) => AuthProvider(),
    ),
  ],
  child: MaterialApp(
    title: 'LuxeStay',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      // ...
    ),
    home: const AuthGate(),
  ),
);
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final bool _isAdminMode = false;

  final List<Widget> _customerScreens = const [
      ExploreScreen(),
      TripsScreen(),
      FavoritesScreen(),
      AccountScreen(),
    ];

  @override
  Widget build(BuildContext context) {
    if (_isAdminMode) {
      return const AdminRoomsScreen();
    }

    return Scaffold(
      body: _customerScreens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Khám phá',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            label: 'Chuyến đi',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            label: 'Yêu thích',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}