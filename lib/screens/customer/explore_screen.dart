import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/property.dart';
import '../../services/firestore_service.dart';
import 'hotel_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color _navy = Color(0xFF0F172A);
  static const Color _background = Color(0xFFF8F7F3);

  // ============================================================
  // SEARCH / FILTER
  // ============================================================

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

  // ============================================================
  // FAVORITES
  // ============================================================

  final Set<String> _favoriteIds = <String>{};

  StreamSubscription<Set<String>>? _favoriteSubscription;

  // ============================================================
  // DATA
  // ============================================================

  final List<String> _destinations = const [
    'Tất cả điểm đến',
    'Phú Quốc',
    'Đà Nẵng',
    'Nha Trang',
    'Đà Lạt',
    'Hạ Long',
    'Hà Nội',
    'TP. Hồ Chí Minh',
  ];

  final List<String> _categories = const [
    'Tất cả',
    'Resort',
    'Khách sạn',
    'Villa',
    'Homestay',
  ];

  final List<String> _sortOptions = const [
    'Đề xuất',
    'Giá thấp nhất',
    'Giá cao nhất',
    'Đánh giá cao nhất',
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenToFavorites();
    });
  }

  void _listenToFavorites() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || !mounted) {
      return;
    }

    final firestoreService = context.read<FirestoreService>();

    _favoriteSubscription = firestoreService
        .getFavoriteIds(user.uid)
        .listen(
      (favoriteIds) {
        if (!mounted) {
          return;
        }

        setState(() {
          _favoriteIds
            ..clear()
            ..addAll(favoriteIds);
        });
      },
      onError: (error) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Không thể tải danh sách yêu thích: $error',
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _favoriteSubscription?.cancel();
    super.dispose();
  }

  // ============================================================
  // FAVORITE
  // ============================================================

  Future<void> _toggleFavorite(String propertyId) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng đăng nhập để sử dụng yêu thích.',
          ),
        ),
      );
      return;
    }

    final firestoreService = context.read<FirestoreService>();

    try {
      final isFavorite = _favoriteIds.contains(propertyId);

      if (isFavorite) {
        await firestoreService.removeFavorite(
          userId: user.uid,
          propertyId: propertyId,
        );
      } else {
        await firestoreService.addFavorite(
          userId: user.uid,
          propertyId: propertyId,
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không thể cập nhật yêu thích: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<Property> _filterProperties(
    List<Property> properties,
  ) {
    var result = List<Property>.from(properties);

    // SEARCH
    final query = _searchQuery.trim().toLowerCase();

    if (query.isNotEmpty) {
      result = result.where((property) {
        final name = property.name.toLowerCase();
        final location = property.location.toLowerCase();
        final category = property.category.toLowerCase();

        return name.contains(query) ||
            location.contains(query) ||
            category.contains(query);
      }).toList();
    }

    // DESTINATION
    if (_selectedDestination != 'Tất cả điểm đến') {
      result = result.where((property) {
        return property.location
            .toLowerCase()
            .contains(
              _selectedDestination.toLowerCase(),
            );
      }).toList();
    }

    // CATEGORY
    if (_selectedCategory != 'Tất cả') {
      result = result.where((property) {
        return property.category.toLowerCase() ==
            _selectedCategory.toLowerCase();
      }).toList();
    }

    // BUSINESS TRIP
    if (_businessTrip) {
      result = result.where((property) {
        return property.amenities.any(
          (amenity) =>
              amenity.toLowerCase().contains('wifi') ||
              amenity.toLowerCase().contains('business'),
        );
      }).toList();
    }

    // FAMILY TRIP
    if (_familyTrip) {
      result = result.where((property) {
        return property.amenities.any(
          (amenity) =>
              amenity.toLowerCase().contains('hồ bơi') ||
              amenity.toLowerCase().contains('pool') ||
              amenity.toLowerCase().contains('family'),
        );
      }).toList();
    }

    // SORT
    switch (_sortOption) {
      case 'Giá thấp nhất':
        result.sort(
          (a, b) => a.pricePerNight.compareTo(
            b.pricePerNight,
          ),
        );
        break;

      case 'Giá cao nhất':
        result.sort(
          (a, b) => b.pricePerNight.compareTo(
            a.pricePerNight,
          ),
        );
        break;

      case 'Đánh giá cao nhất':
        result.sort(
          (a, b) => b.rating.compareTo(a.rating),
        );
        break;

      case 'Đề xuất':
      default:
        result.sort(
          (a, b) => b.rating.compareTo(a.rating),
        );
        break;
    }

    return result;
  }

  // ============================================================
  // DATE
  // ============================================================

  Future<void> _selectDateRange() async {
    final now = DateTime.now();

    final selected = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(
        const Duration(days: 365),
      ),
      initialDateRange: _selectedDateRange,
      helpText: 'Chọn ngày nhận và trả phòng',
      saveText: 'Xong',
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _selectedDateRange = selected;
    });
  }

  // ============================================================
  // GUESTS
  // ============================================================

  Future<void> _showGuestPicker() async {
    int adults = _adults;
    int children = _children;
    int rooms = _rooms;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Khách và phòng',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    _GuestRow(
                      title: 'Người lớn',
                      subtitle: 'Từ 13 tuổi trở lên',
                      value: adults,
                      min: 1,
                      onChanged: (value) {
                        setModalState(() {
                          adults = value;
                        });
                      },
                    ),

                    _GuestRow(
                      title: 'Trẻ em',
                      subtitle: 'Từ 0 - 12 tuổi',
                      value: children,
                      min: 0,
                      onChanged: (value) {
                        setModalState(() {
                          children = value;
                        });
                      },
                    ),

                    _GuestRow(
                      title: 'Phòng',
                      subtitle: 'Số phòng cần đặt',
                      value: rooms,
                      min: 1,
                      onChanged: (value) {
                        setModalState(() {
                          rooms = value;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          setState(() {
                            _adults = adults;
                            _children = children;
                            _rooms = rooms;
                          });

                          Navigator.pop(context);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _navy,
                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                        child: const Text(
                          'Xong',
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final firestoreService =
        context.read<FirestoreService>();

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: StreamBuilder<List<Property>>(
          stream: firestoreService.getProperties(),
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Không thể tải dữ liệu resort.\n\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final properties =
                snapshot.data ?? const <Property>[];

            final filteredProperties =
                _filterProperties(properties);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeader(),
                ),

                SliverToBoxAdapter(
                  child: _buildSearchBox(),
                ),

                SliverToBoxAdapter(
                  child: _buildFilterSection(),
                ),

                SliverToBoxAdapter(
                  child: _buildResultHeader(
                    filteredProperties.length,
                  ),
                ),

                if (filteredProperties.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptySearchResult(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      30,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final property =
                              filteredProperties[index];

                          return Padding(
                            padding:
                                const EdgeInsets.only(
                              bottom: 18,
                            ),
                            child: _buildPropertyCard(
                              property,
                            ),
                          );
                        },
                        childCount:
                            filteredProperties.length,
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

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'LuxeStay',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tìm nơi nghỉ dưỡng lý tưởng',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: _navy,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH BOX
  // ============================================================

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        10,
      ),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText:
                'Tìm resort, khách sạn, địa điểm...',
            prefixIcon: const Icon(
              Icons.search,
              color: _navy,
            ),
            suffixIcon: _searchQuery.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    icon: const Icon(Icons.clear),
                  ),
            border: InputBorder.none,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FILTER SECTION
  // ============================================================

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        8,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _FilterButton(
                  icon: Icons.location_on_outlined,
                  title: _selectedDestination,
                  onTap: _showDestinationPicker,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FilterButton(
                  icon: Icons.category_outlined,
                  title: _selectedCategory,
                  onTap: _showCategoryPicker,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _FilterButton(
                  icon: Icons.calendar_month_outlined,
                  title: _selectedDateRange == null
                      ? 'Ngày'
                      : _formatDateRange(
                          _selectedDateRange!,
                        ),
                  onTap: _selectDateRange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FilterButton(
                  icon: Icons.people_outline,
                  title:
                      '$_adults người · $_rooms phòng',
                  onTap: _showGuestPicker,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _TripChip(
                  label: 'Công tác',
                  icon: Icons.business_center_outlined,
                  selected: _businessTrip,
                  onSelected: (selected) {
                    setState(() {
                      _businessTrip = selected;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _TripChip(
                  label: 'Gia đình',
                  icon: Icons.family_restroom_outlined,
                  selected: _familyTrip,
                  onSelected: (selected) {
                    setState(() {
                      _familyTrip = selected;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _SortChip(
                  title: _sortOption,
                  onTap: _showSortPicker,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESULT HEADER
  // ============================================================

  Widget _buildResultHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        14,
        20,
        12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$count nơi lưu trú',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _navy,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty ||
              _selectedDestination !=
                  'Tất cả điểm đến' ||
              _selectedCategory != 'Tất cả' ||
              _businessTrip ||
              _familyTrip)
            TextButton(
              onPressed: _resetFilters,
              child: const Text('Xóa bộ lọc'),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // PROPERTY CARD
  // ============================================================

  Widget _buildPropertyCard(Property property) {
    final isFavorite =
        _favoriteIds.contains(property.id);

    final formatter = NumberFormat(
      '#,###',
      'vi_VN',
    );

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PropertyDetailScreen(
                property: property,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.55,
                  child: property.image.isEmpty
                      ? Container(
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.hotel,
                            size: 48,
                            color: Colors.grey,
                          ),
                        )
                      : Image.network(
                          property.image,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) {
                            return Container(
                              color:
                                  Colors.grey.shade200,
                              child: const Icon(
                                Icons.hotel,
                                size: 48,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                ),

                // CATEGORY
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _navy.withValues(
                        alpha: 0.9,
                      ),
                      borderRadius:
                          BorderRadius.circular(9),
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

                // FAVORITE
                Positioned(
                  right: 12,
                  top: 12,
                  child: Material(
                    color: Colors.white.withValues(
                      alpha: 0.95,
                    ),
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: isFavorite
                          ? 'Bỏ yêu thích'
                          : 'Thêm vào yêu thích',
                      onPressed: () {
                        _toggleFavorite(
                          property.id,
                        );
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
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          property.name,
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: _navy,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFFFF7ED),
                          borderRadius:
                              BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color:
                                  Color(0xFFD97706),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              property.rating
                                  .toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                                fontSize: 12,
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
                          overflow:
                              TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  if (property.amenities.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: property.amenities
                          .take(3)
                          .map(
                            (amenity) => Container(
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
                                  0xFFF8FAFC,
                                ),
                                borderRadius:
                                    BorderRadius.circular(
                                  7,
                                ),
                              ),
                              child: Text(
                                amenity,
                                style: TextStyle(
                                  color: Colors
                                      .grey.shade700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),

                  const SizedBox(height: 14),

                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Từ',
                              style: TextStyle(
                                color:
                                    Colors.grey.shade600,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${formatter.format(property.pricePerNight)} đ',
                              style: const TextStyle(
                                color: _navy,
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            Text(
                              '/ đêm',
                              style: TextStyle(
                                color:
                                    Colors.grey.shade600,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PropertyDetailScreen(
                                property: property,
                              ),
                            ),
                          );
                        },
                        style:
                            FilledButton.styleFrom(
                          backgroundColor: _navy,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 11,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              11,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Xem phòng',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                FontWeight.bold,
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

  // ============================================================
  // DESTINATION PICKER
  // ============================================================

  Future<void> _showDestinationPicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(
              vertical: 12,
            ),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  14,
                ),
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
                  return ListTile(
                    leading: Icon(
                      destination ==
                              _selectedDestination
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: destination ==
                              _selectedDestination
                          ? _navy
                          : Colors.grey,
                    ),
                    title: Text(destination),
                    onTap: () {
                      Navigator.pop(
                        context,
                        destination,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _selectedDestination = selected;
    });
  }

  // ============================================================
  // CATEGORY PICKER
  // ============================================================

  Future<void> _showCategoryPicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(
              vertical: 12,
            ),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  14,
                ),
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
                  return ListTile(
                    leading: Icon(
                      category == _selectedCategory
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: category ==
                              _selectedCategory
                          ? _navy
                          : Colors.grey,
                    ),
                    title: Text(category),
                    onTap: () {
                      Navigator.pop(
                        context,
                        category,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _selectedCategory = selected;
    });
  }

  // ============================================================
  // SORT PICKER
  // ============================================================

  Future<void> _showSortPicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(
              vertical: 12,
            ),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  14,
                ),
                child: Text(
                  'Sắp xếp',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ..._sortOptions.map(
                (option) {
                  return ListTile(
                    leading: Icon(
                      option == _sortOption
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: option == _sortOption
                          ? _navy
                          : Colors.grey,
                    ),
                    title: Text(option),
                    onTap: () {
                      Navigator.pop(
                        context,
                        option,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _sortOption = selected;
    });
  }

  // ============================================================
  // RESET
  // ============================================================

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _selectedDestination = 'Tất cả điểm đến';
      _selectedCategory = 'Tất cả';
      _sortOption = 'Đề xuất';
      _businessTrip = false;
      _familyTrip = false;
      _selectedDateRange = null;
    });
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDateRange(
    DateTimeRange range,
  ) {
    final formatter = DateFormat(
      'dd/MM',
      'vi_VN',
    );

    return '${formatter.format(range.start)} - '
        '${formatter.format(range.end)}';
  }
}

// ============================================================
// GUEST ROW
// ============================================================

class _GuestRow extends StatelessWidget {
  const _GuestRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final int value;
  final int min;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: value <= min
                ? null
                : () {
                    onChanged(value - 1);
                  },
            icon: const Icon(
              Icons.remove_circle_outline,
            ),
          ),
          SizedBox(
            width: 25,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              onChanged(value + 1);
            },
            icon: const Icon(
              Icons.add_circle_outline,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FILTER BUTTON
// ============================================================

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 19,
                color: _ExploreScreenState._navy,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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
      ),
    );
  }
}

// ============================================================
// TRIP CHIP
// ============================================================

class _TripChip extends StatelessWidget {
  const _TripChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      onSelected: onSelected,
      avatar: Icon(
        icon,
        size: 16,
        color: selected
            ? Colors.white
            : _ExploreScreenState._navy,
      ),
      label: Text(label),
      selectedColor: _ExploreScreenState._navy,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: selected
            ? Colors.white
            : _ExploreScreenState._navy,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: Colors.grey.shade200,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

// ============================================================
// SORT CHIP
// ============================================================

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.title,
    required this.onTap,
  });

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      avatar: const Icon(
        Icons.swap_vert,
        size: 16,
      ),
      label: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: Colors.grey.shade200,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

// ============================================================
// EMPTY SEARCH
// ============================================================

class _EmptySearchResult extends StatelessWidget {
  const _EmptySearchResult();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Không tìm thấy nơi lưu trú',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy thử thay đổi từ khóa hoặc bộ lọc.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}