import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/property.dart';
import '../../models/room.dart';
import '../../services/firestore_service.dart';

class RoomListScreen extends StatelessWidget {
  const RoomListScreen({super.key, required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(title: Text(property.name)),
      body: StreamBuilder<List<Room>>(
        stream: firestoreService.getRooms(property.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Không thể tải danh sách phòng:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final rooms = snapshot.data ?? const <Room>[];
          if (rooms.isEmpty) {
            return const Center(child: Text('Resort này chưa có phòng.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rooms.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _RoomCard(room: rooms[index]),
          );
        },
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room});

  final Room room;

  @override
  Widget build(BuildContext context) {
    final amenities = <String>[
      if (room.view.isNotEmpty) room.view,
      ...room.amenities,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              room.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _RoomDetail(icon: Icons.square_foot, text: '${room.area} m²'),
                _RoomDetail(icon: Icons.bed_outlined, text: room.bedType),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${_formatPrice(room.pricePerNight)} đ / đêm',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (amenities.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: amenities
                    .map((amenity) => Chip(label: Text(amenity)))
                    .toList(growable: false),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatPrice(int price) => price.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => '.',
      );
}

class _RoomDetail extends StatelessWidget {
  const _RoomDetail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }
}
