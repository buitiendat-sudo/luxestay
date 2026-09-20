import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/property.dart';
import 'rooms_screen.dart';

class PropertyDetailScreen extends StatelessWidget {
  const PropertyDetailScreen({
    super.key,
    required this.property,
  });

  final Property property;

  static const Color _navy = Color(0xFF0F172A);
  static const Color _gold = Color(0xFFD97706);
  static const Color _background = Color(0xFFF8F7F3);

  String _formatPrice(int price) {
    return NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    ).format(price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: _navy,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  property.image.isEmpty
                      ? Container(
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.hotel,
                            size: 70,
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
                              color: Colors.grey.shade300,
                              child: const Icon(
                                Icons.hotel,
                                size: 70,
                              ),
                            );
                          },
                        ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.15),
                          Colors.black.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 24,
                    child: Text(
                      property.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.favorite_border,
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.share_outlined,
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                120,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLocation(),

                  const SizedBox(height: 16),

                  _buildRatingCard(),

                  const SizedBox(height: 24),

                  _buildPriceCard(),

                  const SizedBox(height: 28),

                  _buildSectionTitle('Giới thiệu'),

                  const SizedBox(height: 10),

                  Text(
                    'Tận hưởng kỳ nghỉ tuyệt vời tại ${property.name}. '
                    'Không gian nghỉ dưỡng sang trọng, tiện nghi và '
                    'phù hợp cho những chuyến đi thư giãn cùng gia đình '
                    'hoặc bạn bè.',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 28),

                  _buildSectionTitle('Tiện nghi'),

                  const SizedBox(height: 14),

                  _buildAmenities(),

                  const SizedBox(height: 28),

                  _buildSectionTitle('Thông tin lưu trú'),

                  const SizedBox(height: 14),

                  _buildInfoCard(),

                  const SizedBox(height: 28),

                  _buildSectionTitle('Đánh giá'),

                  const SizedBox(height: 14),

                  _buildReviewPreview(),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildLocation() {
    return Row(
      children: [
        const Icon(
          Icons.location_on_outlined,
          color: _gold,
          size: 22,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            property.location,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            property.category.isEmpty
                ? 'Lưu trú'
                : property.category,
            style: const TextStyle(
              color: _gold,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 15,
            offset: const Offset(0, 5),
            color: Colors.black.withValues(alpha: 0.04),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: _navy,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                property.rating.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(
                    5,
                    (index) => const Icon(
                      Icons.star,
                      color: _gold,
                      size: 17,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${property.reviewCount} đánh giá',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.black45,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Giá phòng từ',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 5),
              ],
            ),
          ),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              Text(
                _formatPrice(property.pricePerNight),
                style: const TextStyle(
                  color: _gold,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                '/ đêm',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: _navy,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildAmenities() {
    if (property.amenities.isEmpty) {
      return Text(
        'Chưa có thông tin tiện nghi.',
        style: TextStyle(
          color: Colors.grey.shade600,
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: property.amenities.map(
        (amenity) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 17,
                  color: _gold,
                ),
                const SizedBox(width: 7),
                Text(
                  amenity,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ).toList(),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _infoRow(
            Icons.hotel_outlined,
            'Loại hình',
            property.category.isEmpty
                ? 'Lưu trú'
                : property.category,
          ),
          const Divider(height: 24),
          _infoRow(
            Icons.location_on_outlined,
            'Địa điểm',
            property.location,
          ),
          const Divider(height: 24),
          _infoRow(
            Icons.payments_outlined,
            'Giá từ',
            '${_formatPrice(property.pricePerNight)} / đêm',
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            color: _gold,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: _navy,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewPreview() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _navy,
            child: const Text(
              'KH',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Khách hàng LuxeStay',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Không gian đẹp, dịch vụ tốt và rất đáng trải nghiệm.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.star,
            color: _gold,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              offset: const Offset(0, -5),
              color: Colors.black.withValues(alpha: 0.08),
            ),
          ],
        ),
        child: SizedBox(
          height: 54,
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RoomsScreen(
                    property: property,
                  ),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: _navy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              'Xem phòng & đặt ngay',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}