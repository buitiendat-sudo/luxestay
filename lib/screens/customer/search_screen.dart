import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/property.dart';
import '../../services/firestore_service.dart';
import 'hotel_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: StreamBuilder<List<Property>>(
          stream: context.read<FirestoreService>().getProperties(),
          builder: (context, snapshot) {
            final all = snapshot.data ?? const <Property>[];

            final items = all.where((item) {
              return _query.isEmpty ||
                  '${item.name} ${item.location}'
                      .toLowerCase()
                      .contains(_query.toLowerCase());
            }).toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _header(),
                ),
                SliverToBoxAdapter(
                  child: _summary(),
                ),
                SliverToBoxAdapter(
                  child: _filters(),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      17,
                      20,
                      12,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Tìm thấy ${items.length} khu nghỉ dưỡng cao cấp',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.verified_outlined,
                          color: Color(0xFFD97706),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Cam kết giá tốt',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (snapshot.connectionState ==
                    ConnectionState.waiting)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (items.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'Không tìm thấy nơi lưu trú phù hợp.',
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      0,
                      20,
                      30,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: 20,
                            ),
                            child: _resultCard(
                              items[index],
                              index,
                            ),
                          );
                        },
                        childCount: items.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        8,
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.home_outlined,
              color: Color(0xFFF59E0B),
              size: 19,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LuxeStay',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                Text(
                  'Tìm Kiếm',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.notifications_none_rounded,
          ),
          const SizedBox(width: 16),
          const CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage(
              'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
            ),
          ),
        ],
      ),
    );
  }

  Widget _summary() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        20,
        8,
        20,
        13,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F172A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFE5EEFF),
            child: Icon(
              Icons.travel_explore,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đà Nẵng · 3 đêm',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '15 Th04 – 18 Th04 · 2 khách',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(
              Icons.edit_outlined,
              size: 15,
            ),
            label: const Text('Đổi'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE5EEFF),
              foregroundColor: const Color(0xFF0F172A),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filters() {
    return SizedBox(
      height: 40,
      child: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        scrollDirection: Axis.horizontal,
        children: [
          _filter(
            Icons.tune,
            'Bộ lọc',
            true,
          ),
          const SizedBox(width: 8),
          _filter(
            Icons.savings_outlined,
            'Giá tốt nhất',
            false,
          ),
          const SizedBox(width: 8),
          _filter(
            Icons.star_rounded,
            'Đánh giá cao (4.5+)',
            false,
          ),
        ],
      ),
    );
  }

  Widget _filter(
    IconData icon,
    String text,
    bool selected,
  ) {
    return InkWell(
      onTap: selected ? _showFilterSheet : null,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF0F172A)
              : Colors.white,
          border: Border.all(
            color: const Color(0xFFE2E8F0),
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: selected
                  ? Colors.white
                  : const Color(0xFF904D00),
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected
                    ? Colors.white
                    : const Color(0xFF0F172A),
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              Container(
                width: 17,
                height: 17,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFD97706),
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  '3',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _resultCard(
    Property property,
    int index,
  ) {
    final price = NumberFormat.decimalPattern(
      'vi_VN',
    ).format(property.pricePerNight);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => PropertyDetailScreen(
              property: property,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFFE2E8F0),
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C0F172A),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.65,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  property.image.isEmpty
                      ? const ColoredBox(
                          color: Color(0xFFE2E8F0),
                        )
                      : Image.network(
                          property.image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const ColoredBox(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),

                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                        colors: [
                          Colors.black.withValues(
                            alpha: .65,
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  Positioned(
                    left: 12,
                    top: 12,
                    child: _tag(
                      index == 0
                          ? 'Chỉ còn 2 phòng trống!'
                          : 'Còn ${index + 3} phòng trống',
                      index == 0
                          ? const Color(0xFFFFE3E0)
                          : Colors.white,
                    ),
                  ),

                  const Positioned(
                    right: 12,
                    top: 12,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.favorite_border,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),

                  Positioned(
                    left: 12,
                    bottom: 11,
                    child: Text(
                      '★ ${property.rating.toStringAsFixed(1)} '
                      '(${property.reviewCount}) · Xuất sắc',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),

                  Positioned(
                    right: 12,
                    bottom: 11,
                    child: _tag(
                      property.category.isEmpty
                          ? 'Resort & Spa'
                          : property.category,
                      Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      height: 1.25,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 15,
                        color: Color(0xFF904D00),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          property.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 9),

                  Wrap(
                    spacing: 5,
                    children: property.amenities
                        .take(2)
                        .map(
                          (amenity) => _tag(
                            '✦ $amenity',
                            const Color(0xFFE9F0FF),
                          ),
                        )
                        .toList(),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$price đ',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Text(
                              'Tổng 3 đêm đã gồm thuế',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  PropertyDetailScreen(
                                property: property,
                              ),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF131B2E),
                          minimumSize: const Size(
                            108,
                            48,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(11),
                          ),
                        ),
                        child: const Text(
                          'Xem\nphòng  ›',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
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
      ),
    );
  }

  Widget _tag(
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: .93,
        ),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bộ lọc tìm kiếm',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                onChanged: (value) {
                  setState(() {
                    _query = value;
                  });
                },
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Tên resort hoặc địa điểm',
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}