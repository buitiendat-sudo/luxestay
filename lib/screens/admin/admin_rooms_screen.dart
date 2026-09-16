import 'package:flutter/material.dart';

class AdminRoomsScreen extends StatelessWidget {
  const AdminRoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý phòng')),
      body: const Center(child: Text('Admin - Quản lý phòng')),
    );
  }
}
