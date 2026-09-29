import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../services/firestore_service.dart';
import '../../widgets/admin_chrome.dart';
import 'admin_bookings_screen.dart';
import 'admin_hotels_screen.dart';
import 'admin_users_screen.dart';

class AdminRoomsScreen
    extends StatefulWidget {
  const AdminRoomsScreen({
    super.key,
  });

  @override
  State<AdminRoomsScreen>
      createState() =>
          _AdminRoomsScreenState();
}

class _AdminRoomsScreenState
    extends State<AdminRoomsScreen> {
  String? _propertyId;

  @override
  Widget build(BuildContext context) {
    final firestore =
        context.read<FirestoreService>();

    return Scaffold(
      backgroundColor:
          const Color(0xFFF6F7FB),
      appBar: const AdminHeader(
        title: 'Phòng & Tình trạng',
      ),
      bottomNavigationBar:
          AdminBottomNavigation(
        selectedIndex: 1,
        onSelected: (index) {
          if (index == 1) return;

          final page = switch (index) {
            0 =>
              const AdminHotelsScreen(),
            2 =>
              const AdminBookingsScreen(),
            _ =>
              const AdminUsersScreen(),
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
        stream:
            firestore.watchProperties(),
        builder: (
          context,
          propertySnapshot,
        ) {
          if (!propertySnapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final properties =
              propertySnapshot.data!;

          if (properties.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có Resort.',
              ),
            );
          }

          final selectedId =
              _resolveProperty(
            properties,
          );

          return StreamBuilder<
              List<Map<String, dynamic>>>(
            stream: firestore
                .watchRoomsByProperty(
              selectedId,
            ),
            builder: (
              context,
              roomSnapshot,
            ) {
              if (!roomSnapshot.hasData) {
                return const Center(
                  child:
                      CircularProgressIndicator(),
                );
              }

              final rooms =
                  roomSnapshot.data!;

              return ListView(
                padding:
                    const EdgeInsets.all(
                  14,
                ),
                children: [
                  _PropertySelector(
                    properties:
                        properties,
                    selectedId:
                        selectedId,
                    onChanged: (value) {
                      setState(() {
                        _propertyId =
                            value;
                      });
                    },
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  _RoomOverview(
                    rooms: rooms,
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  Text(
                    'Hạng phòng (${rooms.length})',
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

                  ...rooms.map(
                    (room) =>
                        _RoomCard(
                      room: room,
                    ),
                  ),

                  const _OtaCard(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _resolveProperty(
    List<Map<String, dynamic>>
        properties,
  ) {
    final current = _propertyId;

    if (current != null &&
        properties.any(
          (property) =>
              property['id'] ==
              current,
        )) {
      return current;
    }

    return properties.first['id']
        .toString();
  }
}

class _PropertySelector
    extends StatelessWidget {
  const _PropertySelector({
    required this.properties,
    required this.selectedId,
    required this.onChanged,
  });

  final List<Map<String, dynamic>>
      properties;

  final String selectedId;

  final ValueChanged<String>
      onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color:
              const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.apartment,
            color:
                Color(0xFFEA580C),
          ),
          const SizedBox(width: 9),
          Expanded(
            child:
                DropdownButtonHideUnderline(
              child:
                  DropdownButton<String>(
                value: selectedId,
                isExpanded: true,
                items: properties.map(
                  (property) {
                    return DropdownMenuItem(
                      value:
                          property['id']
                              .toString(),
                      child: Text(
                        property['name']
                                ?.toString() ??
                            'Resort',
                        overflow:
                            TextOverflow
                                .ellipsis,
                      ),
                    );
                  },
                ).toList(),
                onChanged: (value) {
                  if (value != null) {
                    onChanged(value);
                  }
                },
              ),
            ),
          ),
          const _SyncBadge(),
        ],
      ),
    );
  }
}

class _SyncBadge extends StatelessWidget {
  const _SyncBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color:
            const Color(0xFFECFDF5),
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: const Text(
        '● PMS',
        style: TextStyle(
          color:
              Color(0xFF059669),
          fontSize: 9,
          fontWeight:
              FontWeight.w700,
        ),
      ),
    );
  }
}

class _RoomOverview
    extends StatelessWidget {
  const _RoomOverview({
    required this.rooms,
  });

  final List<Map<String, dynamic>>
      rooms;

  @override
  Widget build(BuildContext context) {
    final total = rooms.fold<int>(
      0,
      (sum, room) =>
          sum +
          _int(
            room['availableCount'],
          ),
    );

    final active = rooms
        .where(
          (room) =>
              room['isOnSale'] != false,
        )
        .length;

    final percent = rooms.isEmpty
        ? 0.0
        : active / rooms.length * 100;

    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            const Color(0xFF111827),
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Công suất phòng',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${percent.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 29,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: percent / 100,
            minHeight: 7,
            borderRadius:
                BorderRadius.circular(10),
            backgroundColor:
                Colors.white24,
            color:
                const Color(0xFFFF8A1F),
          ),
          const SizedBox(height: 11),
          Text(
            '$total phòng trống sẵn sàng đón khách',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  static int _int(dynamic value) {
    return (value as num?)
            ?.toInt() ??
        0;
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.room,
  });

  final Map<String, dynamic> room;

  @override
  Widget build(BuildContext context) {
    final firestore =
        context.read<FirestoreService>();

    final id =
        room['id'].toString();

    final propertyId =
        room['propertyId'].toString();

    final available =
        (room['availableCount']
                    as num?)
                ?.toInt() ??
            0;

    final active =
        room['isOnSale'] != false;

    final price =
        (room['pricePerNight']
                    as num?)
                ?.toInt() ??
            0;

    final image =
        room['image']?.toString() ??
            '';

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(15),
        border: Border.all(
          color:
              const Color(0xFFE5E7EB),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 160,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (image.isNotEmpty)
                  Image.network(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, _, _) =>
                            _fallback(),
                  )
                else
                  _fallback(),

                if (available <= 1)
                  Positioned(
                    top: 9,
                    right: 9,
                    child: Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFDC2626,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          20,
                        ),
                      ),
                      child: Text(
                        available == 0
                            ? 'Hết phòng!'
                            : 'Chỉ còn 1 phòng!',
                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize: 9,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding:
                const EdgeInsets.all(
              12,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  room['name']
                          ?.toString() ??
                      'Hạng phòng',
                  style:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  '${room['area'] ?? 0} m² • ${room['bedType'] ?? ''} • ${room['view'] ?? ''}',
                  style:
                      const TextStyle(
                    color:
                        Color(0xFF64748B),
                    fontSize: 10,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          const Text(
                            'Giá / đêm',
                            style:
                                TextStyle(
                              color:
                                  Color(
                                0xFF94A3B8,
                              ),
                              fontSize: 9,
                            ),
                          ),
                          Text(
                            '${NumberFormat('#,###', 'vi_VN').format(price)} ₫',
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight
                                      .w900,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Switch(
                      value: active,
                      onChanged:
                          (value) {
                        firestore
                            .setRoomSaleStatus(
                          id,
                          value,
                          propertyId:
                              propertyId,
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(
                  height: 7,
                ),

                Row(
                  children: [
                    Expanded(
                      child:
                          OutlinedButton.icon(
                        onPressed: () {
                          _changePrice(
                            context,
                            room,
                          );
                        },
                        icon: const Icon(
                          Icons
                              .payments_outlined,
                          size: 15,
                        ),
                        label:
                            const Text(
                          'Chỉnh giá',
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 7,
                    ),
                    Expanded(
                      child:
                          OutlinedButton.icon(
                        onPressed: () {
                          _changeInventory(
                            context,
                            room,
                          );
                        },
                        icon: const Icon(
                          Icons
                              .inventory_2_outlined,
                          size: 15,
                        ),
                        label:
                            const Text(
                          'Kho phòng',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _changePrice(
    BuildContext context,
    Map<String, dynamic> room,
  ) {
    final controller =
        TextEditingController(
      text:
          '${room['pricePerNight'] ?? 0}',
    );

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
              const Text('Chỉnh giá'),
          content: TextField(
            controller: controller,
            keyboardType:
                TextInputType.number,
            decoration:
                const InputDecoration(
              labelText: 'Giá / đêm',
              suffixText: '₫',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
              ),
              child:
                  const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () async {
                final price =
                    int.tryParse(
                  controller.text,
                );

                if (price == null ||
                    price <= 0) {
                  return;
                }

                await context
                    .read<
                        FirestoreService>()
                    .updateRoomPrice(
                      propertyId:
                          room[
                                  'propertyId']
                              .toString(),
                      roomId:
                          room['id']
                              .toString(),
                      price: price,
                    );

                if (dialogContext
                    .mounted) {
                  Navigator.pop(
                    dialogContext,
                  );
                }
              },
              child:
                  const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  void _changeInventory(
    BuildContext context,
    Map<String, dynamic> room,
  ) {
    final controller =
        TextEditingController(
      text:
          '${room['availableCount'] ?? 0}',
    );

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
              const Text('Kho phòng'),
          content: TextField(
            controller: controller,
            keyboardType:
                TextInputType.number,
            decoration:
                const InputDecoration(
              labelText:
                  'Số phòng còn trống',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
              ),
              child:
                  const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () async {
                final count =
                    int.tryParse(
                  controller.text,
                );

                if (count == null ||
                    count < 0) {
                  return;
                }

                await context
                    .read<
                        FirestoreService>()
                    .updateRoomInventory(
                      propertyId:
                          room[
                                  'propertyId']
                              .toString(),
                      roomId:
                          room['id']
                              .toString(),
                      availableCount:
                          count,
                    );

                if (dialogContext
                    .mounted) {
                  Navigator.pop(
                    dialogContext,
                  );
                }
              },
              child:
                  const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  static Widget _fallback() {
    return Container(
      color:
          const Color(0xFFE2E8F0),
      child: const Icon(
        Icons.bed,
        size: 50,
      ),
    );
  }
}

class _OtaCard extends StatelessWidget {
  const _OtaCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(15),
        border: Border.all(
          color:
              const Color(0xFFE5E7EB),
        ),
      ),
      child: const Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Kết nối OTA API',
            style: TextStyle(
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          SizedBox(height: 12),
          _OtaRow(
            name: 'Booking.com',
          ),
          _OtaRow(
            name: 'Agoda YCS',
          ),
          _OtaRow(
            name:
                'LuxeStay Direct',
          ),
          SizedBox(height: 8),
          Text(
            'OTA đang hiển thị ở chế độ demo, chưa kết nối API bên thứ ba.',
            style: TextStyle(
              color:
                  Color(0xFF94A3B8),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _OtaRow extends StatelessWidget {
  const _OtaRow({
    required this.name,
  });

  final String name;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(
        Icons.hub_outlined,
        size: 18,
      ),
      title: Text(name),
      trailing: const Icon(
        Icons.check_circle,
        color:
            Color(0xFF10B981),
        size: 17,
      ),
    );
  }
}