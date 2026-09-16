import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/property.dart';
import '../../services/firestore_service.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  static const Color _navy = Color(0xFF0F172A);
  static const Color _gold = Color(0xFFD97706);
  static const Color _background = Color(0xFFF8F7F3);

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedDestination = 'Tất cả điểm đến';
  String _selectedCategory = 'Tất cả';
  String _sortOption = 'Đề xuất';

  bool _businessTrip = false;
  bool _familyTrip = false;

  DateTimeRange? _selectedDateRange;

  int _adults = 2;
  int _children = 0;
  int _rooms = 1;

  final Set<String> _favoriteIds = {};

  final List<String> _destinations = const [
    'Tất cả điểm đến',
    'Đà Nẵng',
    'Hội An',
    'Phú Quốc',
    'Nha Trang',
    'Hạ Long',
    'Đà Lạt',
    'Hà Nội',
  ];

  final List<String> _categories = const [
    'Tất cả',
    'Resort',
    'Villa',
    'Khách sạn',
    'Bao gồm bữa sáng',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Property> _filterProperties(List<Property> properties) {
    final query = _searchQuery.trim().toLowerCase();

    final result = properties.where((property) {
      final matchesSearch =
          query.isEmpty ||
          property.name.toLowerCase().contains(query) ||
          property.location.toLowerCase().contains(query);

      final matchesDestination =
          _selectedDestination == 'Tất cả điểm đến' ||
          property.location.toLowerCase().contains(
                _selectedDestination.toLowerCase(),
              );

      final matchesCategory =
          _selectedCategory == 'Tất cả' ||
          property.category.toLowerCase().contains(
                _selectedCategory.toLowerCase(),
              );

      return matchesSearch && matchesDestination && matchesCategory;
    }).toList();

    switch (_sortOption) {
      case 'Giá thấp đến cao':
        result.sort(
          (a, b) => a.pricePerNight.compareTo(b.pricePerNight),
        );
        break;

      case 'Giá cao đến thấp':
        result.sort(
          (a, b) => b.pricePerNight.compareTo(a.pricePerNight),
        );
        break;

      case 'Đánh giá cao nhất':
        result.sort(
          (a, b) => b.rating.compareTo(a.rating),
        );
        break;

      default:
        break;
    }

    return result;
  }

  int get _numberOfNights {
    if (_selectedDateRange == null) {
      return 1;
    }

    final difference =
        _selectedDateRange!.end.difference(_selectedDateRange!.start).inDays;

    return difference <= 0 ? 1 : difference;
  }

  String get _dateLabel {
    if (_selectedDateRange == null) {
      return 'Chọn ngày';
    }

    final formatter = DateFormat('dd/MM');

    return '${formatter.format(_selectedDateRange!.start)} - '
        '${formatter.format(_selectedDateRange!.end)}';
  }

  String get _guestLabel {
    final totalGuests = _adults + _children;

    return '$totalGuests khách · $_rooms phòng';
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();

    final initialStart = _selectedDateRange?.start ?? now;
    final initialEnd =
        _selectedDateRange?.end ?? now.add(const Duration(days: 1));

    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: initialStart,
        end: initialEnd,
      ),
      helpText: 'Chọn ngày nhận và trả phòng',
      cancelText: 'HỦY',
      confirmText: 'XÁC NHẬN',
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  void _showDestinationPicker() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Text(
                  'Chọn điểm đến',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ..._destinations.map(
                (destination) {
                  final selected =
                      destination == _selectedDestination;

                  return ListTile(
                    title: Text(destination),
                    trailing: selected
                        ? const Icon(
                            Icons.check,
                            color: _gold,
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedDestination = destination;
                      });

                      Navigator.pop(context);
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Text(
                  'Loại hình lưu trú',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ..._categories.map(
                (category) {
                  final selected = category == _selectedCategory;

                  return ListTile(
                    title: Text(category),
                    trailing: selected
                        ? const Icon(
                            Icons.check,
                            color: _gold,
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });

                      Navigator.pop(context);
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showSortPicker() {
    final options = [
      'Đề xuất',
      'Giá thấp đến cao',
      'Giá cao đến thấp',
      'Đánh giá cao nhất',
    ];

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Text(
                  'Sắp xếp',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...options.map(
                (option) {
                  final selected = option == _sortOption;

                  return ListTile(
                    title: Text(option),
                    trailing: selected
                        ? const Icon(
                            Icons.check,
                            color: _gold,
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _sortOption = option;
                      });

                      Navigator.pop(context);
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showGuestPicker() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Khách & phòng',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _guestCounter(
                      title: 'Người lớn',
                      subtitle: 'Từ 13 tuổi trở lên',
                      value: _adults,
                      minValue: 1,
                      onChanged: (value) {
                        setModalState(() {
                          _adults = value;
                        });
                      },
                    ),

                    const Divider(),

                    _guestCounter(
                      title: 'Trẻ em',
                      subtitle: 'Từ 0 - 12 tuổi',
                      value: _children,
                      minValue: 0,
                      onChanged: (value) {
                        setModalState(() {
                          _children = value;
                        });
                      },
                    ),

                    const Divider(),

                    _guestCounter(
                      title: 'Phòng',
                      subtitle: 'Số phòng cần đặt',
                      value: _rooms,
                      minValue: 1,
                      onChanged: (value) {
                        setModalState(() {
                          _rooms = value;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: () {
                          setState(() {});
                          Navigator.pop(context);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _navy,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Xác nhận',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _guestCounter({
    required String title,
    required String subtitle,
    required int value,
    required int minValue,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: value > minValue
                ? () => onChanged(value - 1)
                : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 30,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => onChanged(value + 1),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedDestination = 'Tất cả điểm đến';
      _selectedCategory = 'Tất cả';
      _sortOption = 'Đề xuất';
      _businessTrip = false;
      _familyTrip = false;
    });
  }

  void _toggleFavorite(String propertyId) {
    setState(() {
      if (_favoriteIds.contains(propertyId)) {
        _favoriteIds.remove(propertyId);
      } else {
        _favoriteIds.add(propertyId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: StreamBuilder<List<Property>>(
          stream: firestoreService.getProperties(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildErrorState(
                snapshot.error.toString(),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final properties = snapshot.data ?? [];
            final filteredProperties =
                _filterProperties(properties);

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildHeader(),
                  ),

                  SliverToBoxAdapter(
                    child: _buildSearchBox(),
                  ),

                  SliverToBoxAdapter(
                    child: _buildQuickFilters(),
                  ),

                  SliverToBoxAdapter(
                    child: _buildTripOptions(),
                  ),

                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      filteredProperties.length,
                    ),
                  ),

                  if (filteredProperties.isEmpty)
                    SliverToBoxAdapter(
                      child: _buildEmptyState(),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final property =
                              filteredProperties[index];

                          return Padding(
                            padding: EdgeInsets.fromLTRB(
                              20,
                              index == 0 ? 4 : 8,
                              20,
                              8,
                            ),
                            child: _buildPropertyCard(property),
                          );
                        },
                        childCount: filteredProperties.length,
                      ),
                    ),

                  SliverToBoxAdapter(
                    child: _buildConciergeBanner(),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 24),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _navy,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.diamond_outlined,
              color: _gold,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LuxeStay',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Luxury stays, unforgettable moments',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: _navy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              offset: const Offset(0, 8),
              color: Colors.black.withValues(alpha: 0.06),
            ),
          ],
        ),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Bạn muốn đi đâu?',
                prefixIcon: const Icon(
                  Icons.search,
                  color: _gold,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.close),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF7F7F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _searchAction(
                    icon: Icons.location_on_outlined,
                    title: _selectedDestination,
                    onTap: _showDestinationPicker,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _searchAction(
                    icon: Icons.calendar_month_outlined,
                    title: _dateLabel,
                    onTap: _selectDateRange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            _searchAction(
              icon: Icons.people_outline,
              title: _guestLabel,
              onTap: _showGuestPicker,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchAction({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: _navy,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilters() {
    return SizedBox(
      height: 52,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        children: [
          _filterChip(
            icon: Icons.tune,
            label: _selectedCategory,
            onTap: _showCategoryPicker,
          ),
          const SizedBox(width: 8),
          _filterChip(
            icon: Icons.sort,
            label: _sortOption,
            onTap: _showSortPicker,
          ),
          const SizedBox(width: 8),
          _filterChip(
            icon: Icons.clear_all,
            label: 'Xóa lọc',
            onTap: _resetFilters,
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(
        icon,
        size: 17,
        color: _navy,
      ),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: Colors.grey.shade300,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildTripOptions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: _tripOption(
              icon: Icons.business_center_outlined,
              title: 'Công tác',
              selected: _businessTrip,
              onTap: () {
                setState(() {
                  _businessTrip = !_businessTrip;
                });
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _tripOption(
              icon: Icons.family_restroom_outlined,
              title: 'Gia đình',
              selected: _familyTrip,
              onTap: () {
                setState(() {
                  _familyTrip = !_familyTrip;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tripOption({
    required IconData icon,
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: selected
              ? _navy
              : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected
                ? _navy
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected
                  ? Colors.white
                  : _navy,
            ),
            const SizedBox(width: 7),
            Text(
              title,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : _navy,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Nơi lưu trú dành cho bạn',
              style: TextStyle(
                color: _navy,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            '$count kết quả',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(Property property) {
    final isFavorite = _favoriteIds.contains(property.id);

    final totalPrice =
        property.pricePerNight * _numberOfNights * _rooms;

    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 7),
            color: Colors.black.withValues(alpha: 0.05),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.65,
                child: property.image.isEmpty
                    ? Container(
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.hotel,
                          size: 50,
                        ),
                      )
                    : Image.network(
                        property.image,
                        fit: BoxFit.cover,
                        errorBuilder: (
                          context,
                          error,
                          stackTrace,
                        ) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.hotel,
                              size: 50,
                            ),
                          );
                        },
                        loadingBuilder: (
                          context,
                          child,
                          loadingProgress,
                        ) {
                          if (loadingProgress == null) {
                            return child;
                          }

                          return Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                      ),
              ),

              Positioned(
                top: 12,
                right: 12,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.92),
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: () {
                      _toggleFavorite(property.id);
                    },
                    icon: Icon(
                      isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: isFavorite
                          ? Colors.red
                          : _navy,
                    ),
                  ),
                ),
              ),

              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _navy.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    property.category.isEmpty
                        ? 'Lưu trú'
                        : property.category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        property.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _navy,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 15,
                            color: _gold,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            property.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: _navy,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 7),

                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 17,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        property.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 7),

                Row(
                  children: [
                    const Icon(
                      Icons.rate_review_outlined,
                      size: 16,
                      color: _gold,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${property.reviewCount} đánh giá',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Được yêu thích',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: property.amenities
                      .take(4)
                      .map(
                        (amenity) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            amenity,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),

                const SizedBox(height: 16),

                const Divider(),

                const SizedBox(height: 8),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Giá từ',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatter.format(
                              property.pricePerNight,
                            ),
                            style: const TextStyle(
                              color: _navy,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Text(
                            '/ đêm',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_selectedDateRange != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Text(
                          formatter.format(totalPrice),
                          style: const TextStyle(
                            color: _gold,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    FilledButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          SnackBar(
                            content: Text(
                              'Đã chọn ${property.name}',
                            ),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _navy,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Xem phòng',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
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

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 50, 30, 60),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 38,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Không tìm thấy nơi lưu trú',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _navy,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy thử thay đổi từ khóa hoặc bộ lọc tìm kiếm.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: _resetFilters,
            child: const Text('Xóa bộ lọc'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 50,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            const Text(
              'Không thể tải dữ liệu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () {
                setState(() {});
              },
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConciergeBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _navy,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: _gold.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: _gold,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LuxeStay Concierge',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Cần hỗ trợ tìm phòng? Chúng tôi luôn sẵn sàng.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}