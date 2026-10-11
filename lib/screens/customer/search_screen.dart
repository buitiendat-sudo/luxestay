import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/property.dart';
import '../../services/firestore_service.dart';
import '../../widgets/notification_center_button.dart';
import 'rooms_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';
  RangeValues? _priceRange;
  String? _selectedLocation;
  final Set<String> _selectedAmenities = {};
  double? _minimumRating;
  String _sortOption = 'Đề xuất';
  List<Property> _allProperties = const [];
  StreamSubscription<Map<String, PropertyReviewSummary>>? _reviewSubscription;
  Map<String, PropertyReviewSummary> _reviewSummaries = {};

  @override
  void initState() {
    super.initState();
    _reviewSubscription = context
        .read<FirestoreService>()
        .watchReviewSummaries()
        .listen((summaries) {
          if (!mounted) return;
          setState(() => _reviewSummaries = summaries);
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    _reviewSubscription?.cancel();
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
            _allProperties = all;

            final items = _applyFilters(all);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _header()),
                SliverToBoxAdapter(child: _summary()),
                SliverToBoxAdapter(child: _filters(all)),
                SliverToBoxAdapter(child: _priceRangePanel(all)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 17, 20, 12),
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
                if (snapshot.connectionState == ConnectionState.waiting)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (items.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Text('Không tìm thấy nơi lưu trú phù hợp.'),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _resultCard(items[index], index),
                        );
                      }, childCount: items.length),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Property> _applyFilters(List<Property> properties) {
    final query = _query.trim().toLowerCase();
    final filtered = properties.where((property) {
      final summary = _reviewSummaries[property.id];
      final rating = summary?.rating ?? property.rating;
      final matchesQuery =
          query.isEmpty ||
          '${property.name} ${property.location} ${property.address}'
              .toLowerCase()
              .contains(query);
      final matchesPrice =
          _priceRange == null ||
          (property.pricePerNight >= _priceRange!.start &&
              property.pricePerNight <= _priceRange!.end);
      final matchesLocation =
          _selectedLocation == null ||
          property.location.toLowerCase() == _selectedLocation!.toLowerCase();
      final matchesAmenities = _selectedAmenities.every(
        (amenity) => property.amenities.any(
          (item) => item.toLowerCase() == amenity.toLowerCase(),
        ),
      );
      final matchesRating = _minimumRating == null || rating >= _minimumRating!;

      return matchesQuery &&
          matchesPrice &&
          matchesLocation &&
          matchesAmenities &&
          matchesRating;
    }).toList();

    switch (_sortOption) {
      case 'Giá thấp nhất':
        filtered.sort((a, b) => a.pricePerNight.compareTo(b.pricePerNight));
      case 'Đánh giá cao nhất':
        filtered.sort(
          (a, b) => (_reviewSummaries[b.id]?.rating ?? b.rating).compareTo(
            _reviewSummaries[a.id]?.rating ?? a.rating,
          ),
        );
      case 'Đề xuất':
        filtered.sort(
          (a, b) => (_reviewSummaries[b.id]?.rating ?? b.rating).compareTo(
            _reviewSummaries[a.id]?.rating ?? a.rating,
          ),
        );
    }
    return filtered;
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LuxeStay',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                ),
                Text(
                  'Tìm Kiếm',
                  style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const NotificationCenterButton(),
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
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 13),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
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
            child: Icon(Icons.travel_explore, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedLocation ??
                      (_query.trim().isEmpty
                          ? 'Đà Nẵng · 3 đêm'
                          : _query.trim()),
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                Text(
                  '15 Th04 – 18 Th04 · 2 khách',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () => _showFilterSheet(_allProperties),
            icon: const Icon(Icons.edit_outlined, size: 15),
            label: const Text('Đổi'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE5EEFF),
              foregroundColor: const Color(0xFF0F172A),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filters(List<Property> properties) {
    final activeCount = _activeFilterCount;
    return SizedBox(
      height: 40,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        children: [
          _filter(
            Icons.tune,
            activeCount == 0 ? 'Bộ lọc' : 'Bộ lọc ($activeCount)',
            activeCount > 0,
            () => _showFilterSheet(properties),
          ),
          const SizedBox(width: 8),
          _filter(
            Icons.place_outlined,
            _selectedLocation ?? 'Khu vực',
            _selectedLocation != null,
            () => _showFilterSheet(properties),
          ),
          const SizedBox(width: 8),
          _filter(
            Icons.pool_outlined,
            _selectedAmenities.isEmpty
                ? 'Tiện nghi'
                : 'Tiện nghi (${_selectedAmenities.length})',
            _selectedAmenities.isNotEmpty,
            () => _showFilterSheet(properties),
          ),
          const SizedBox(width: 8),
          _filter(
            Icons.star_rounded,
            _minimumRating == null ? 'Đánh giá' : '$_minimumRating + sao',
            _minimumRating != null,
            () => _showFilterSheet(properties),
          ),
          const SizedBox(width: 8),
          _filter(
            Icons.swap_vert_rounded,
            _sortOption,
            _sortOption != 'Đề xuất',
            () => _showFilterSheet(properties),
          ),
          if (activeCount > 0) ...[
            const SizedBox(width: 8),
            _filter(Icons.close_rounded, 'Xóa', false, _clearFilters),
          ],
        ],
      ),
    );
  }

  Widget _filter(
    IconData icon,
    String text,
    bool selected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0F172A) : Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? Colors.white : const Color(0xFF904D00),
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : const Color(0xFF0F172A),
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
                  style: TextStyle(fontSize: 9, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  int get _activeFilterCount =>
      (_query.trim().isNotEmpty ? 1 : 0) +
      (_priceRange != null ? 1 : 0) +
      (_selectedLocation != null ? 1 : 0) +
      (_selectedAmenities.isNotEmpty ? 1 : 0) +
      (_minimumRating != null ? 1 : 0) +
      (_sortOption != 'Đề xuất' ? 1 : 0);

  RangeValues _priceBounds(List<Property> properties) {
    final prices = properties
        .map((property) => property.pricePerNight.toDouble())
        .where((price) => price >= 0)
        .toList();
    if (prices.isEmpty) return const RangeValues(0, 24000000);
    final minimum = prices.reduce(math.min);
    final maximum = prices.reduce(math.max);
    return RangeValues(minimum, maximum <= minimum ? minimum + 1 : maximum);
  }

  RangeValues _effectivePriceRange(List<Property> properties) {
    final bounds = _priceBounds(properties);
    if (_priceRange == null) return bounds;
    final start = _priceRange!.start.clamp(bounds.start, bounds.end).toDouble();
    final end = _priceRange!.end.clamp(start, bounds.end).toDouble();
    return RangeValues(start, end);
  }

  Widget _priceRangePanel(List<Property> properties) {
    final bounds = _priceBounds(properties);
    final values = _effectivePriceRange(properties);
    final formatter = NumberFormat.decimalPattern('vi_VN');

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Khoảng giá mỗi đêm',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
              if (_priceRange != null)
                TextButton(
                  onPressed: () => setState(() => _priceRange = null),
                  child: const Text('Đặt lại'),
                ),
            ],
          ),
          RangeSlider(
            values: values,
            min: bounds.start,
            max: bounds.end,
            divisions: 48,
            labels: RangeLabels(
              formatter.format(values.start.round()),
              formatter.format(values.end.round()),
            ),
            onChanged: (range) => setState(() => _priceRange = range),
          ),
          Row(
            children: [
              Expanded(
                child: _priceValue(formatter.format(values.start.round())),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _priceValue(formatter.format(values.end.round())),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceValue(String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFCBD5E1)),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text('$value VND', style: const TextStyle(fontSize: 11)),
  );

  Widget _resultCard(Property property, int index) {
    final rating = _reviewSummaries[property.id]?.rating ?? property.rating;
    final price = NumberFormat.decimalPattern('vi_VN')
        .format(property.pricePerNight);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => PropertyDetailScreen(property: property),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
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
                      ? const ColoredBox(color: Color(0xFFE2E8F0))
                      : Image.network(
                          property.image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const ColoredBox(color: Color(0xFFE2E8F0)),
                        ),

                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                        colors: [
                          Colors.black.withValues(alpha: .65),
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
                      index == 0 ? const Color(0xFFFFE3E0) : Colors.white,
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
                      '★ ${rating.toStringAsFixed(1)} '
                      '(${_reviewSummaries[property.id]?.count ?? property.reviewCount}) · Xuất sắc',
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
                          (amenity) =>
                              _tag('✦ $amenity', const Color(0xFFE9F0FF)),
                        )
                        .toList(),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                  PropertyDetailScreen(property: property),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF131B2E),
                          minimumSize: const Size(108, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
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

  Widget _tag(String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .93),
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

  void _showFilterSheet(List<Property> properties) {
    final locations =
        properties
            .map((property) => property.location.trim())
            .where((location) => location.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final amenities =
        properties
            .expand((property) => property.amenities)
            .map((amenity) => amenity.trim())
            .where((amenity) => amenity.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          void update(VoidCallback change) {
            setState(change);
            setSheetState(() {});
          }

          final matchingCount = _applyFilters(properties).length;
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.82,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Text(
                      'Bộ lọc tìm kiếm',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        TextField(
                          controller: _controller,
                          onChanged: (value) => update(() => _query = value),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Tên khách sạn hoặc địa điểm',
                            filled: true,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Khu vực',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedLocation ?? 'Tất cả khu vực',
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          items: ['Tất cả khu vực', ...locations].map((
                            location,
                          ) {
                            return DropdownMenuItem(
                              value: location,
                              child: Text(location),
                            );
                          }).toList(),
                          onChanged: (location) => update(
                            () => _selectedLocation =
                                location == 'Tất cả khu vực' ? null : location,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Đánh giá tối thiểu',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          children:
                              [
                                (label: 'Bất kỳ', value: null),
                                (label: '3+ sao', value: 3.0),
                                (label: '4+ sao', value: 4.0),
                                (label: '4.5+ sao', value: 4.5),
                              ].map((option) {
                                return ChoiceChip(
                                  label: Text(option.label),
                                  selected: _minimumRating == option.value,
                                  onSelected: (_) => update(
                                    () => _minimumRating = option.value,
                                  ),
                                );
                              }).toList(),
                        ),
                        if (amenities.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          const Text(
                            'Tiện nghi',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: amenities.map((amenity) {
                              return FilterChip(
                                label: Text(amenity),
                                selected: _selectedAmenities.contains(amenity),
                                onSelected: (selected) => update(() {
                                  if (selected) {
                                    _selectedAmenities.add(amenity);
                                  } else {
                                    _selectedAmenities.remove(amenity);
                                  }
                                }),
                              );
                            }).toList(),
                          ),
                        ],
                        const SizedBox(height: 18),
                        const Text(
                          'Sắp xếp',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: _sortOption,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          items:
                              const [
                                'Đề xuất',
                                'Giá thấp nhất',
                                'Đánh giá cao nhất',
                              ].map((option) {
                                return DropdownMenuItem(
                                  value: option,
                                  child: Text(option),
                                );
                              }).toList(),
                          onChanged: (option) =>
                              update(() => _sortOption = option ?? 'Đề xuất'),
                        ),
                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: () => update(_clearFilters),
                          child: const Text('Xóa bộ lọc'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            child: Text('Xem $matchingCount kết quả'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _controller.clear();
      _query = '';
      _priceRange = null;
      _selectedLocation = null;
      _selectedAmenities.clear();
      _minimumRating = null;
      _sortOption = 'Đề xuất';
    });
  }
}
