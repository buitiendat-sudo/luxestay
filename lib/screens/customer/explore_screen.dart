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
  static const Color _background = Color(0xFFF8F9FF);

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
  final PageController _promotionController = PageController(
    viewportFraction: 0.93,
  );
  Timer? _promotionTimer;
  int _promotionIndex = 0;

  static const List<_PromotionCampaign> _promotionCampaigns = [
    _PromotionCampaign(
      eyebrow: 'LUXESTAY PICKS',
      title: 'Kỳ nghỉ đáng nhớ',
      subtitle: 'Khám phá những điểm nghỉ dưỡng được yêu thích',
      icon: Icons.waves_rounded,
    ),
    _PromotionCampaign(
      eyebrow: 'TRỐN ĐẾN BIỂN XANH',
      title: 'Chạm vào bình yên',
      subtitle: 'Tìm không gian thư giãn cho chuyến đi tiếp theo',
      icon: Icons.beach_access_rounded,
    ),
    _PromotionCampaign(
      eyebrow: 'GỢI Ý CHO BẠN',
      title: 'Lên lịch nghỉ dưỡng',
      subtitle: 'Chọn nơi lưu trú phù hợp với kỳ nghỉ của bạn',
      icon: Icons.luggage_rounded,
    ),
  ];

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

    _promotionTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_promotionController.hasClients) return;
      final nextPage = (_promotionIndex + 1) % _promotionCampaigns.length;
      _promotionController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });

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
                content: Text('Không thể tải danh sách yêu thích: $error'),
              ),
            );
          },
        );
  }

  @override
  void dispose() {
    _favoriteSubscription?.cancel();
    _promotionTimer?.cancel();
    _promotionController.dispose();
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
          content: Text('Vui lòng đăng nhập để sử dụng yêu thích.'),
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
        SnackBar(content: Text('Không thể cập nhật yêu thích: $e')),
      );
    }
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<Property> _filterProperties(List<Property> properties) {
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
        return property.location.toLowerCase().contains(
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
        result.sort((a, b) => a.pricePerNight.compareTo(b.pricePerNight));
        break;

      case 'Giá cao nhất':
        result.sort((a, b) => b.pricePerNight.compareTo(a.pricePerNight));
        break;

      case 'Đánh giá cao nhất':
        result.sort((a, b) => b.rating.compareTo(a.rating));
        break;

      case 'Đề xuất':
      default:
        result.sort((a, b) => b.rating.compareTo(a.rating));
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
      lastDate: now.add(const Duration(days: 365)),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Xong',
                          style: TextStyle(fontWeight: FontWeight.bold),
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
    final firestoreService = context.read<FirestoreService>();

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: StreamBuilder<List<Property>>(
          stream: firestoreService.getProperties(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
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

            final properties = snapshot.data ?? const <Property>[];

            final filteredProperties = _filterProperties(properties);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),

                SliverToBoxAdapter(child: _buildPromotionalBanners(properties)),

                SliverToBoxAdapter(child: _buildSearchBox()),

                SliverToBoxAdapter(child: _buildFilterSection()),

                SliverToBoxAdapter(
                  child: _buildResultHeader(filteredProperties.length),
                ),

                if (filteredProperties.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptySearchResult(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final property = filteredProperties[index];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: _buildPropertyCard(property),
                        );
                      }, childCount: filteredProperties.length),
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _navy,
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
                child: Text(
                  'LuxeStay',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(Icons.notifications_none_rounded, color: _navy),
              const SizedBox(width: 16),
              const CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(
                  'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Text(
            'KỲ NGHỈ THƯỜNG LƯU',
            style: TextStyle(
              fontSize: 9,
              letterSpacing: .7,
              color: Color(0xFF904D00),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Text(
                'Xin chào, Quý khách',
                style: TextStyle(
                  color: _navy,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EEF9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '💎 Thành viên Black',
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
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
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            _searchLine(
              Icons.location_on_rounded,
              'ĐIỂM ĐẾN',
              _selectedDestination == 'Tất cả điểm đến'
                  ? 'Đà Nẵng, Việt Nam'
                  : _selectedDestination,
              _showDestinationPicker,
            ),
            const SizedBox(height: 8),
            _searchLine(
              Icons.calendar_month_outlined,
              'THỜI GIAN LƯU TRÚ',
              _selectedDateRange == null
                  ? '15 Th04 – 18 Th04, 2025   3 đêm'
                  : _formatDateRange(_selectedDateRange!),
              _selectDateRange,
            ),
            const SizedBox(height: 8),
            _searchLine(
              Icons.group_outlined,
              'SỐ LƯỢNG KHÁCH & PHÒNG',
              '$_adults người lớn, $_rooms phòng',
              _showGuestPicker,
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: Container(
                    alignment: Alignment.center,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '🔵 Tôi đi công tác',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    alignment: Alignment.center,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '🟤 Ưu đãi gia đình',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: () => setState(() {}),
                icon: const Icon(Icons.search),
                label: const Text(
                  'Tìm kiếm khách sạn (120+ chỗ nghỉ)',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchLine(
    IconData icon,
    String label,
    String value,
    VoidCallback onTap,
  ) => InkWell(
    onTap: onTap,
    child: Container(
      height: 53,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: const Color(0xFFDDEBFF),
            child: Icon(icon, size: 17, color: _navy),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 8,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: Color(0xFF64748B),
          ),
        ],
      ),
    ),
  );

  // ============================================================
  // FILTER SECTION
  // ============================================================

  Widget _buildFilterSection() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _TripChip(
            label: 'Tất cả',
            icon: Icons.visibility,
            selected: true,
            onSelected: (_) {},
          ),
          const SizedBox(width: 8),
          _TripChip(
            label: 'Resort ven biển',
            icon: Icons.beach_access_outlined,
            selected: _selectedCategory == 'Resort',
            onSelected: (_) => _showCategoryPicker(),
          ),
          const SizedBox(width: 8),
          _TripChip(
            label: 'Villa riêng tư',
            icon: Icons.villa_outlined,
            selected: false,
            onSelected: (_) => _showCategoryPicker(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESULT HEADER
  // ============================================================

  Widget _buildPromotionalBanners(List<Property> properties) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 9),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Ưu đãi dành riêng cho bạn',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Row(
                children: List.generate(
                  _promotionCampaigns.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: _promotionIndex == index ? 17 : 6,
                    height: 6,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: _promotionIndex == index
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 168,
          child: PageView.builder(
            controller: _promotionController,
            itemCount: _promotionCampaigns.length,
            onPageChanged: (index) {
              if (_promotionIndex != index) {
                setState(() => _promotionIndex = index);
              }
            },
            itemBuilder: (context, index) {
              final campaign = _promotionCampaigns[index];
              final property = properties.isEmpty
                  ? null
                  : properties[index % properties.length];

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _PromotionBanner(
                  campaign: campaign,
                  property: property,
                  onTap: property == null
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PropertyDetailScreen(property: property),
                            ),
                          );
                        },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultHeader(int count) {
    final hasFilter =
        _searchQuery.isNotEmpty ||
        _selectedDestination != 'Tất cả điểm đến' ||
        _selectedCategory != 'Tất cả' ||
        _businessTrip ||
        _familyTrip;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Chỗ nghỉ nổi bật',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _navy,
                  ),
                ),
              ),

              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _showSortPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.swap_vert, size: 15, color: _navy),
                      const SizedBox(width: 4),
                      Text(
                        _sortOption,
                        style: const TextStyle(
                          fontSize: 9,
                          color: _navy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          Row(
            children: [
              Text(
                '$count chỗ nghỉ phù hợp',
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              ),

              const Spacer(),

              if (hasFilter)
                TextButton(
                  onPressed: _resetFilters,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Xóa bộ lọc',
                    style: TextStyle(
                      fontSize: 9,
                      color: Color(0xFFD97706),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROPERTY CARD
  // ============================================================

  Widget _buildPropertyCard(Property property) {
    final isFavorite = _favoriteIds.contains(property.id);

    final formatter = NumberFormat('#,###', 'vi_VN');

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PropertyDetailScreen(property: property),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _navy.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      property.category.isEmpty ? 'Lưu trú' : property.category,
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
                    color: Colors.white.withValues(alpha: 0.95),
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: isFavorite
                          ? 'Bỏ yêu thích'
                          : 'Thêm vào yêu thích',
                      onPressed: () {
                        _toggleFavorite(property.id);
                      },
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : _navy,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          property.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: _navy,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: Color(0xFFD97706),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              property.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
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
                          overflow: TextOverflow.ellipsis,
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
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),

                  const SizedBox(height: 14),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Từ',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${formatter.format(property.pricePerNight)} đ',
                              style: const TextStyle(
                                color: _navy,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '/ đêm',
                              style: TextStyle(
                                color: Colors.grey.shade600,
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
                                  PropertyDetailScreen(property: property),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _navy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 11,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                        child: const Text(
                          'Xem chi tiết',
                          style: TextStyle(
                            fontSize: 12,
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 14),
                child: Text(
                  'Chọn điểm đến',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              ..._destinations.map((destination) {
                return ListTile(
                  leading: Icon(
                    destination == _selectedDestination
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: destination == _selectedDestination
                        ? _navy
                        : Colors.grey,
                  ),
                  title: Text(destination),
                  onTap: () {
                    Navigator.pop(context, destination);
                  },
                );
              }),
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
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 10, 20, 14),
                  child: Text(
                    'Loại hình lưu trú',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                ..._categories.map((category) {
                  return ListTile(
                    leading: Icon(
                      category == _selectedCategory
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: category == _selectedCategory
                          ? _navy
                          : Colors.grey,
                    ),
                    title: Text(category),
                    onTap: () {
                      Navigator.pop(context, category);
                    },
                  );
                }),
              ],
            );
          },
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 14),
                child: Text(
                  'Sắp xếp',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              ..._sortOptions.map((option) {
                return ListTile(
                  leading: Icon(
                    option == _sortOption
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: option == _sortOption ? _navy : Colors.grey,
                  ),
                  title: Text(option),
                  onTap: () {
                    Navigator.pop(context, option);
                  },
                );
              }),
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

  String _formatDateRange(DateTimeRange range) {
    final formatter = DateFormat('dd/MM');

    return '${formatter.format(range.start)} - '
        '${formatter.format(range.end)}';
  }
}

class _PromotionCampaign {
  const _PromotionCampaign({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
}

class _PromotionBanner extends StatelessWidget {
  const _PromotionBanner({
    required this.campaign,
    required this.property,
    required this.onTap,
  });

  final _PromotionCampaign campaign;
  final Property? property;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF075985),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (property != null && property!.image.isNotEmpty)
              Image.network(
                property!.image,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xF20B3554),
                    Color(0xCC075985),
                    Color(0x883B82A0),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                  ),
                  child: Icon(campaign.icon, color: Colors.white, size: 38),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 13, 96, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      campaign.eyebrow,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    campaign.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    campaign.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFE0F2FE),
                      fontSize: 9,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Khám phá ngay',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                      if (property != null) ...[
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            property!.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFBAE6FD),
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ],
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
            icon: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 25,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            onPressed: () {
              onChanged(value + 1);
            },
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FILTER BUTTON
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
        color: selected ? Colors.white : _ExploreScreenState._navy,
      ),
      label: Text(label),
      selectedColor: _ExploreScreenState._navy,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : _ExploreScreenState._navy,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey.shade200),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

// ============================================================
// SORT CHIP
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
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy thử thay đổi từ khóa hoặc bộ lọc.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
