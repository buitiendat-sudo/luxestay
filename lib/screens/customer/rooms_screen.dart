import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/property.dart';
import '../../models/room.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import 'booking_screen.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key, required this.property});

  final Property property;

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  static const Color _navy = Color(0xFF0F172A);
  static const Color _gold = Color(0xFFD97706);
  static const Color _background = Color(0xFFF8F9FF);

  int _selected = 0;
  bool _isUpdatingFavorite = false;

  String _formatPrice(int value) {
    return NumberFormat.decimalPattern('vi_VN').format(value);
  }

  Future<void> _copyPropertyInfo() async {
    final property = widget.property;
    final details = <String>[
      'Khách sạn: ${property.name}',
      'Địa điểm: ${property.location}',
      if (property.address.trim().isNotEmpty) 'Địa chỉ: ${property.address}',
      'Đánh giá: ${property.rating.toStringAsFixed(1)} (${property.reviewCount} nhận xét)',
      'Giá từ: ${_formatPrice(property.pricePerNight)} đ/đêm',
    ];

    await Clipboard.setData(ClipboardData(text: details.join('\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép thông tin khách sạn.')),
    );
  }

  Future<void> _toggleFavorite(bool isFavorite) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để lưu khách sạn yêu thích.')),
      );
      return;
    }
    if (_isUpdatingFavorite) return;

    setState(() => _isUpdatingFavorite = true);
    try {
      final firestoreService = context.read<FirestoreService>();
      if (isFavorite) {
        await firestoreService.removeFavorite(
          userId: user.uid,
          propertyId: widget.property.id,
        );
      } else {
        await firestoreService.addFavorite(
          userId: user.uid,
          propertyId: widget.property.id,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFavorite ? 'Đã bỏ khách sạn khỏi yêu thích.' : 'Đã lưu khách sạn yêu thích.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể cập nhật yêu thích: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingFavorite = false);
    }
  }

  Widget _favoriteButton() {
    final user = context.watch<AuthProvider>().user;
    final firestoreService = context.read<FirestoreService>();

    Widget button(bool isFavorite) => CircleAvatar(
      backgroundColor: Colors.white,
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: isFavorite ? 'Bỏ yêu thích' : 'Thêm vào yêu thích',
        onPressed: _isUpdatingFavorite ? null : () => _toggleFavorite(isFavorite),
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          size: 19,
          color: isFavorite ? Colors.red : _navy,
        ),
      ),
    );

    if (user == null) return button(false);
    return StreamBuilder<Set<String>>(
      stream: firestoreService.getFavoriteIds(user.uid),
      builder: (context, snapshot) =>
          button(snapshot.data?.contains(widget.property.id) ?? false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: StreamBuilder<List<Room>>(
          stream: context.read<FirestoreService>().getRooms(widget.property.id),
          builder: (context, snapshot) {
            final rooms = snapshot.data ?? const <Room>[];

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _toolbar()),
                SliverToBoxAdapter(child: _hero()),
                SliverToBoxAdapter(child: _propertyInfo()),
                SliverToBoxAdapter(child: _descriptionSection()),
                SliverToBoxAdapter(child: _locationSection()),
                SliverToBoxAdapter(child: _reviewsSection()),
                SliverToBoxAdapter(child: _dates()),
                SliverToBoxAdapter(child: _sectionHeading()),

                if (snapshot.connectionState == ConnectionState.waiting)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                else if (snapshot.hasError)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 40,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Không thể tải danh sách phòng',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (rooms.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.bed_outlined,
                              size: 45,
                              color: Color(0xFF94A3B8),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Hiện chưa có phòng phù hợp.',
                              style: TextStyle(color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _room(rooms[index], index),
                        );
                      }, childCount: rooms.length),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  // ============================================================
  // TOOLBAR
  // ============================================================

  Widget _toolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.maybePop(context);
            },
            icon: const Icon(Icons.arrow_back, size: 21),
          ),
          _brand(),
          const SizedBox(width: 7),
          const Expanded(
            child: Text(
              'Chi Tiết Khách Sạn',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            tooltip: 'Chia sẻ',
            onPressed: _copyPropertyInfo,
            icon: const Icon(Icons.share_outlined, size: 20),
          ),
          const CircleAvatar(
            radius: 15,
            backgroundImage: NetworkImage(
              'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
            ),
          ),
        ],
      ),
    );
  }

  Widget _brand() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(7),
      ),
      child: const Icon(
        Icons.home_outlined,
        color: Color(0xFFF59E0B),
        size: 18,
      ),
    );
  }

  // ============================================================
  // HERO
  // ============================================================

  Widget _hero() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          height: 220,
          width: double.infinity,
          child: _image(widget.property.image),
        ),

        Positioned(top: 12, left: 18, child: _chip('▣ Ảnh khách sạn')),

        Positioned(
          top: 12,
          right: 18,
          child: Row(
            children: [
              _favoriteButton(),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: IconButton(
                  padding: EdgeInsets.zero,
                    onPressed: _copyPropertyInfo,
                  icon: const Icon(Icons.ios_share_outlined, size: 19),
                ),
              ),
            ],
          ),
        ),

        Positioned(
          bottom: -16,
          left: 20,
          right: 20,
          child: Row(
            children: [
              Expanded(child: _chip('✓ Resort cao cấp')),
              const SizedBox(width: 8),
              Expanded(child: _chip('✦ Ưu đãi LuxeStay')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 5),
        ],
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _image(String url) {
    if (url.isEmpty) {
      return const ColoredBox(
        color: Color(0xFFD8E4F4),
        child: Center(
          child: Icon(Icons.hotel, size: 45, color: Color(0xFF94A3B8)),
        ),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const ColoredBox(
          color: Color(0xFFD8E4F4),
          child: Center(
            child: Icon(Icons.hotel, size: 45, color: Color(0xFF94A3B8)),
          ),
        );
      },
    );
  }

  // ============================================================
  // PROPERTY INFO
  // ============================================================

  Widget _propertyInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(
                5,
                (index) =>
                    const Icon(Icons.star_rounded, size: 15, color: _gold),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '${widget.property.rating.toStringAsFixed(1)}/5'
                  '  (${widget.property.reviewCount} nhận xét)',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            widget.property.name,
            style: const TextStyle(
              fontSize: 21,
              height: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 15,
                color: Color(0xFF904D00),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.property.location,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),

          if (widget.property.amenities.isNotEmpty) ...[
            const SizedBox(height: 13),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.property.amenities
                  .take(4)
                  .map((amenity) => _detail('✓ $amenity'))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _descriptionSection() {
    final description = widget.property.description.trim().isNotEmpty
        ? widget.property.description.trim()
        : '${widget.property.name} mang đến không gian nghỉ dưỡng '
              'thoải mái tại ${widget.property.location}. '
              'Khám phá các tiện nghi và lựa chọn phòng phù hợp cho chuyến đi.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mô tả',
            style: TextStyle(
              color: _navy,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationSection() {
    final property = widget.property;
    final address = property.address.trim().isNotEmpty
        ? property.address.trim()
        : property.location;
    final hasCoordinates =
        property.latitude != null && property.longitude != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vị trí',
            style: TextStyle(
              color: _navy,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          _mapPreview(address),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.place_outlined, color: _gold, size: 18),
              const SizedBox(width: 5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address,
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (hasCoordinates)
                      Text(
                        '${property.latitude!.toStringAsFixed(6)}, '
                        '${property.longitude!.toStringAsFixed(6)}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
              TextButton(onPressed: _openMap, child: const Text('Mở bản đồ')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mapPreview(String address) {
    final property = widget.property;
    final center = _mapCenter(property, address);
    const zoom = 13;
    final tileCount = 1 << zoom;
    final worldSize = tileCount * 256.0;
    final latitudeRadians =
        center.latitude.clamp(-85.0511, 85.0511) * math.pi / 180;
    final centerX = (center.longitude + 180) / 360 * worldSize;
    final centerY =
        (1 -
            math.log(
                  math.tan(latitudeRadians) + 1 / math.cos(latitudeRadians),
                ) /
                math.pi) /
        2 *
        worldSize;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 150,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalOffset = constraints.maxWidth / 2 - centerX;
            final verticalOffset = 75 - centerY;
            final firstTileX = ((-horizontalOffset) / 256).floor();
            final lastTileX = ((constraints.maxWidth - horizontalOffset) / 256)
                .floor();
            final firstTileY = ((-verticalOffset) / 256).floor();
            final lastTileY = ((150 - verticalOffset) / 256).floor();
            final tiles = <Widget>[];

            for (var x = firstTileX; x <= lastTileX; x++) {
              for (var y = firstTileY; y <= lastTileY; y++) {
                final wrappedX = ((x % tileCount) + tileCount) % tileCount;
                final tileY = y.clamp(0, tileCount - 1);
                final tileUri = Uri.https(
                  'tile.openstreetmap.org',
                  '/$zoom/$wrappedX/$tileY.png',
                );
                tiles.add(
                  Positioned(
                    left: x * 256.0 + horizontalOffset,
                    top: y * 256.0 + verticalOffset,
                    width: 256,
                    height: 256,
                    child: Image.network(
                      tileUri.toString(),
                      fit: BoxFit.fill,
                      errorBuilder: (_, _, _) =>
                          const ColoredBox(color: Color(0xFFEAF1F7)),
                    ),
                  ),
                );
              }
            }

            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                const Positioned.fill(
                  child: ColoredBox(color: Color(0xFFEAF1F7)),
                ),
                ...tiles,
                if (center.isExact)
                  const Center(
                    child: Icon(
                      Icons.location_on,
                      color: Color(0xFFDC2626),
                      size: 34,
                    ),
                  ),
                Positioned(
                  left: 7,
                  bottom: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 3,
                      ),
                      child: Text(
                        center.isExact
                            ? '© OpenStreetMap contributors'
                            : 'Bản đồ khu vực gần ${center.label} · © OpenStreetMap',
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 9,
                        ),
                      ),
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

  _MapCenter _mapCenter(Property property, String address) {
    final latitude = property.latitude;
    final longitude = property.longitude;
    if (latitude != null &&
        longitude != null &&
        latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180) {
      return _MapCenter(latitude, longitude, property.name, isExact: true);
    }

    final searchText = '$address ${property.location}'.toLowerCase();
    if (searchText.contains('mộc châu')) {
      return const _MapCenter(20.841, 104.63, 'Mộc Châu');
    }
    if (searchText.contains('phú quốc') || searchText.contains('phu quoc')) {
      return const _MapCenter(10.227, 103.967, 'Phú Quốc');
    }

    return const _MapCenter(16.0, 108.0, 'Việt Nam');
  }

  Future<void> _openMap() async {
    final property = widget.property;
    final query = property.latitude != null && property.longitude != null
        ? '${property.latitude},${property.longitude}'
        : '${property.address}, ${property.location}';
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': query,
    });

    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on PlatformException {
      opened = false;
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể mở Google Maps. Vui lòng thử lại.'),
        ),
      );
    }
  }

  Widget _reviewsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đánh giá & nhận xét',
            style: TextStyle(
              color: _navy,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showReviewSheet,
              icon: const Icon(Icons.rate_review_outlined, size: 18),
              label: const Text('Viết đánh giá của bạn'),
            ),
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: context.read<FirestoreService>().watchReviewsByProperty(
              widget.property.id,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text(
                  'Chưa thể tải nhận xét lúc này.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                );
              }

              final reviews = [...?snapshot.data];
              reviews.sort(
                (a, b) =>
                    _reviewDate(b['createdAt'])
                        .compareTo(_reviewDate(a['createdAt'])),
              );
              final average = reviews.isEmpty
                  ? widget.property.rating
                  : reviews.fold<double>(
                          0,
                          (total, review) =>
                              total + (review['rating'] as num? ?? 0),
                        ) /
                        reviews.length;
              final reviewCount = reviews.isEmpty
                  ? widget.property.reviewCount
                  : reviews.length;
              final recommendAnswers = reviews
                  .where((review) => review.containsKey('recommends'))
                  .toList(growable: false);
              final recommendRate = recommendAnswers.isEmpty
                  ? null
                  : 100 *
                        recommendAnswers
                            .where((review) => review['recommends'] == true)
                            .length /
                        recommendAnswers.length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        average.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _stars(average, size: 15),
                          Text(
                            '$reviewCount nhận xét'
                            '${recommendRate == null ? '' : ' · ${recommendRate.round()}% recommend'}',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (reviews.isEmpty)
                    const Text(
                      'Chưa có nhận xét công khai. Hãy là người đầu tiên chia sẻ trải nghiệm.',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    )
                  else
                    ...reviews.take(3).map(_reviewCard),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showReviewSheet() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final comment = TextEditingController();
    final reason = TextEditingController();
    final highlights = TextEditingController();
    var rating = 5;
    var recommends = true;
    var saving = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chia sẻ trải nghiệm',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                Row(
                  children: List.generate(
                    5,
                    (index) => IconButton(
                      onPressed: () => setSheetState(() => rating = index + 1),
                      icon: Icon(
                        index < rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: const Color(0xFFF59E0B),
                        size: 30,
                      ),
                    ),
                  ),
                ),
                TextField(
                  controller: comment,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Nhận xét',
                    hintText: 'Phòng, dịch vụ, vị trí, vệ sinh',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(child: Text('Bạn có recommend resort này?')),
                    Switch(
                      value: recommends,
                      onChanged: (value) =>
                          setSheetState(() => recommends = value),
                    ),
                  ],
                ),
                TextField(
                  controller: reason,
                  decoration: const InputDecoration(
                    labelText: 'Lý do recommend',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: highlights,
                  decoration: const InputDecoration(
                    labelText: 'Ưu điểm nổi bật',
                    hintText: 'VD: Phòng sạch, view đẹp',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (comment.text.trim().isEmpty) return;

                            final navigator = Navigator.of(sheetContext);
                            final messenger = ScaffoldMessenger.maybeOf(
                              this.context,
                            );

                            setSheetState(() => saving = true);
                            try {
                              await context
                                  .read<FirestoreService>()
                                  .submitPropertyReview(
                                    userId: user.uid,
                                    userName:
                                        user.displayName ??
                                        user.email ??
                                        'Khách hàng',
                                    propertyId: widget.property.id,
                                    propertyName: widget.property.name,
                                    rating: rating,
                                    comment: comment.text,
                                    recommends: recommends,
                                    recommendReason: reason.text,
                                    highlights: highlights.text
                                        .split(',')
                                        .map((item) => item.trim())
                                        .where((item) => item.isNotEmpty)
                                        .toList(),
                                  );
                              if (!mounted || !sheetContext.mounted) return;
                              navigator.pop();
                              messenger?.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Đã đăng đánh giá. Cảm ơn bạn!',
                                  ),
                                ),
                              );
                            } catch (_) {
                              if (!mounted || !sheetContext.mounted) return;
                              setSheetState(() => saving = false);
                              messenger?.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Chưa thể đăng đánh giá. Vui lòng thử lại.',
                                  ),
                                ),
                              );
                            }
                          },
                    child: saving
                        ? const CircularProgressIndicator()
                        : const Text('Đăng đánh giá'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    comment.dispose();
    reason.dispose();
    highlights.dispose();
  }

  Widget _reviewCard(Map<String, dynamic> review) {
    final rating = (review['rating'] as num?)?.toDouble() ?? 0;
    final name = review['userName']?.toString().trim();
    final comment = review['comment']?.toString().trim() ?? '';
    final date = _reviewDate(review['createdAt']);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE8ECF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name == null || name.isEmpty ? 'Khách hàng' : name,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _stars(rating, size: 12),
              const SizedBox(width: 4),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            comment.isEmpty ? 'Không có nội dung nhận xét.' : comment,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            DateFormat('dd/MM/yyyy').format(date),
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _stars(double rating, {required double size}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final difference = rating - index;
        final icon = difference >= 1
            ? Icons.star_rounded
            : difference >= 0.5
            ? Icons.star_half_rounded
            : Icons.star_outline_rounded;
        return Icon(icon, size: size, color: const Color(0xFFF59E0B));
      }),
    );
  }

  DateTime _reviewDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime(2000);
    if (value is Timestamp) return value.toDate();
    return DateTime(2000);
  }

  // ============================================================
  // DATE
  // ============================================================

  Widget _dates() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 2, 20, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFE6EEFF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_outlined, size: 19),
          const SizedBox(width: 9),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chọn ngày lưu trú',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Ngày nhận và trả phòng chọn ở bước đặt phòng',
                  style: TextStyle(fontSize: 9, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bạn sẽ chọn ngày ở bước đặt phòng.'),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(64, 32),
              side: BorderSide.none,
              backgroundColor: Colors.white,
            ),
            child: const Text(
              'Chọn ngày',
              style: TextStyle(fontSize: 10, color: _navy),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION HEADING
  // ============================================================

  Widget _sectionHeading() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chọn hạng phòng phù hợp',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                SizedBox(height: 3),
                Text(
                  'Giá phòng được lấy từ hệ thống LuxeStay',
                  style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Text(
              '● Trực tuyến',
              style: TextStyle(
                fontSize: 9,
                color: Color(0xFF047857),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ROOM
  // ============================================================

  Widget _room(Room room, int index) {
    final selected = _selected == index;

    final total = room.pricePerNight * 3;

    final roomImage = room.image.isNotEmpty
        ? room.image
        : widget.property.image;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        setState(() {
          _selected = index;
        });
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: selected ? _navy : const Color(0xFFE2E8F0),
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 155,
                  width: double.infinity,
                  child: _image(roomImage),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: _chip(
                    room.view.isNotEmpty ? room.view : 'Phòng LuxeStay',
                  ),
                ),
                const Positioned(right: 8, top: 8, child: _SaleBadge()),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          room.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Icon(
                        selected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: selected
                            ? const Color(0xFF10B981)
                            : const Color(0xFF94A3B8),
                        size: 22,
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    room.view.isEmpty ? 'Hạng phòng cao cấp' : room.view,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF64748B),
                    ),
                  ),

                  const SizedBox(height: 9),

                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: [
                      _detail('${room.area} m²'),
                      _detail(
                        room.bedType.isEmpty
                            ? 'Giường tiêu chuẩn'
                            : room.bedType,
                      ),
                      _detail('Tối đa 2 khách'),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (room.amenities.isNotEmpty)
                    ...room.amenities
                        .take(4)
                        .map((amenity) => _benefit(amenity))
                  else ...[
                    _benefit('Wi-Fi tốc độ cao'),
                    _benefit('Điều hòa'),
                    _benefit('Dịch vụ phòng'),
                  ],

                  const SizedBox(height: 7),

                  _availabilityText(room),

                  const SizedBox(height: 12),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tạm tính 3 đêm',
                              style: TextStyle(
                                fontSize: 9,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              '${_formatPrice(total)} ₫',
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${_formatPrice(room.pricePerNight)} ₫\n/ đêm',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),

                  if (!selected) ...[
                    const SizedBox(height: 11),
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: FilledButton(
                        onPressed: () {
                          setState(() {
                            _selected = index;
                          });
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE5EEFF),
                          foregroundColor: _navy,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Chọn phòng này',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 11),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Color(0xFF047857),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Đã chọn phòng này',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF047857),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _availabilityText(Room room) {
    final count = room.availableCount;

    if (count <= 0) {
      return const Row(
        children: [
          Icon(Icons.error_outline, size: 14, color: Color(0xFFDC2626)),
          SizedBox(width: 4),
          Text(
            'Hiện chưa còn phòng trống',
            style: TextStyle(
              fontSize: 9,
              color: Color(0xFFDC2626),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    if (count <= 2) {
      return Row(
        children: [
          const Icon(
            Icons.local_fire_department,
            size: 14,
            color: Color(0xFFEA580C),
          ),
          const SizedBox(width: 4),
          Text(
            'Chỉ còn $count phòng!',
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFFEA580C),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 14,
          color: Color(0xFF059669),
        ),
        const SizedBox(width: 4),
        Text(
          'Còn $count phòng trống',
          style: const TextStyle(
            fontSize: 9,
            color: Color(0xFF059669),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _detail(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FF),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 8, color: Color(0xFF475569)),
      ),
    );
  }

  Widget _benefit(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check, size: 13, color: Color(0xFF10B981)),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 9, color: Color(0xFF475569)),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM BAR
  // ============================================================

  Widget _bottomBar() {
    return StreamBuilder<List<Room>>(
      stream: context.read<FirestoreService>().getRooms(widget.property.id),
      builder: (context, snapshot) {
        final rooms = snapshot.data ?? const <Room>[];

        Room? selectedRoom;

        if (rooms.isNotEmpty) {
          final safeIndex = _selected.clamp(0, rooms.length - 1);

          selectedRoom = rooms[safeIndex];
        }

        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 9, 20, 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x160F172A),
                  blurRadius: 14,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'GIÁ PHÒNG ĐÃ CHỌN',
                        style: TextStyle(fontSize: 9, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedRoom == null
                            ? '--'
                            : '${_formatPrice(selectedRoom.pricePerNight)} ₫',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'Giá / đêm',
                        style: TextStyle(fontSize: 8, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 43,
                  child: FilledButton(
                    onPressed:
                        selectedRoom == null || selectedRoom.availableCount <= 0
                        ? null
                        : () {
                            _continueBooking(selectedRoom!);
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black,
                      disabledBackgroundColor: const Color(0xFFCBD5E1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Tiến hành đặt phòng →',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
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
  }

  void _continueBooking(Room room) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) {
          return BookingScreen(property: widget.property, room: room);
        },
      ),
    );
  }
}

class _SaleBadge extends StatelessWidget {
  const _SaleBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'Ưu đãi độc quyền',
        style: TextStyle(
          fontSize: 8,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MapCenter {
  const _MapCenter(
    this.latitude,
    this.longitude,
    this.label, {
    this.isExact = false,
  });

  final double latitude;
  final double longitude;
  final String label;
  final bool isExact;
}
