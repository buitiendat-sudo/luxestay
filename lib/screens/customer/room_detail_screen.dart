import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/property.dart';
import '../../models/room.dart';
import 'booking_screen.dart';

class RoomDetailScreen extends StatefulWidget {
  const RoomDetailScreen({
    super.key,
    required this.property,
    required this.room,
  });

  final Property property;
  final Room room;

  @override
  State<RoomDetailScreen> createState() =>
      _RoomDetailScreenState();
}

class _RoomDetailScreenState
    extends State<RoomDetailScreen> {
  final PageController _pageController =
      PageController();

  int _currentImageIndex = 0;

  Room get room => widget.room;
  Property get property => widget.property;

  // ============================================================
  // FORMAT PRICE
  // ============================================================

  String _formatPrice(int price) {
    return NumberFormat(
      '#,###',
      'vi_VN',
    ).format(price);
  }

  // ============================================================
  // GET ROOM IMAGES
  // ============================================================

  List<String> get _roomImages {
    final List<String> images = [];

    // Ảnh chính
    if (room.image.trim().isNotEmpty) {
      images.add(room.image.trim());
    }

    // Các ảnh phụ
    for (final image in room.images) {
      final cleanImage = image.trim();

      if (cleanImage.isNotEmpty &&
          !images.contains(cleanImage)) {
        images.add(cleanImage);
      }
    }

    return images;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FC),

      appBar: AppBar(
        title: const Text(
          'Chi tiết phòng',
        ),
        centerTitle: true,
        backgroundColor:
            const Color(0xFFFFF9FC),
        surfaceTintColor:
            Colors.transparent,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          120,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ==================================================
            // IMAGE GALLERY
            // ==================================================

            _buildImageGallery(),

            const SizedBox(height: 20),

            // ==================================================
            // RESORT NAME
            // ==================================================

            Text(
              property.name,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),

            const SizedBox(height: 7),

            // ==================================================
            // ROOM NAME
            // ==================================================

            Text(
              room.name,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // ROOM INFORMATION
            // ==================================================

            Card(
              elevation: 0,
              color: const Color(0xFFF9F4FA),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(16),
                side: BorderSide(
                  color: Colors.grey.shade200,
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _InfoRow(
                      icon:
                          Icons.visibility_outlined,
                      title: 'View',
                      value: room.view.isEmpty
                          ? 'Đang cập nhật'
                          : room.view,
                    ),

                    const Divider(
                      height: 24,
                    ),

                    _InfoRow(
                      icon:
                          Icons.square_foot_outlined,
                      title: 'Diện tích',
                      value:
                          '${room.area} m²',
                    ),

                    const Divider(
                      height: 24,
                    ),

                    _InfoRow(
                      icon: Icons.bed_outlined,
                      title: 'Loại giường',
                      value: room.bedType,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ==================================================
            // AMENITIES
            // ==================================================

            Text(
              'Tiện nghi phòng',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 12),

            if (room.amenities.isEmpty)
              Text(
                'Chưa có thông tin tiện nghi.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: room.amenities
                    .map(
                      (amenity) {
                        return Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                              0xFFF8FAFC,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(12),
                            border: Border.all(
                              color: Colors
                                  .grey.shade200,
                            ),
                          ),
                          child: Row(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons
                                    .check_circle_outline,
                                size: 18,
                                color:
                                    Color(
                                  0xFFD97706,
                                ),
                              ),
                              const SizedBox(
                                width: 6,
                              ),
                              Text(amenity),
                            ],
                          ),
                        );
                      },
                    )
                    .toList(),
              ),

            const SizedBox(height: 28),

            // ==================================================
            // BOOKING INFORMATION
            // ==================================================

            Text(
              'Thông tin đặt phòng',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 12),

            const _PolicyItem(
              icon: Icons.login,
              text: 'Nhận phòng từ 14:00',
            ),

            const _PolicyItem(
              icon: Icons.logout,
              text: 'Trả phòng trước 12:00',
            ),

            const _PolicyItem(
              icon: Icons.cancel_outlined,
              text:
                  'Chính sách hủy sẽ được hiển thị khi đặt phòng',
            ),

            const SizedBox(height: 24),

            // ==================================================
            // PRICE
            // ==================================================

            Card(
              elevation: 0,
              color:
                  const Color(0xFFFFF7ED),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(16),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.all(18),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                  children: [
                    const Text(
                      'Giá phòng / đêm',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),

                    Text(
                      '${_formatPrice(room.pricePerNight)} đ',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ========================================================
      // BOOKING BUTTON
      // ========================================================

      bottomSheet: SafeArea(
        child: Container(
          padding:
              const EdgeInsets.fromLTRB(
            16,
            12,
            16,
            12,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.08,
                ),
                blurRadius: 12,
                offset:
                    const Offset(0, -3),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        BookingScreen(
                      property: property,
                      room: room,
                    ),
                  ),
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF0F172A),
                foregroundColor:
                    Colors.white,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),
              child: const Text(
                'Đặt phòng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // IMAGE GALLERY
  // ============================================================

  Widget _buildImageGallery() {
    final images = _roomImages;

    // Không có ảnh
    if (images.isEmpty) {
      return _buildEmptyImage();
    }

    return Column(
      children: [
        // ------------------------------------------------------
        // IMAGE VIEW
        // ------------------------------------------------------

        ClipRRect(
          borderRadius:
              BorderRadius.circular(22),
          child: SizedBox(
            width: double.infinity,
            height: 240,
            child: Stack(
              children: [
                PageView.builder(
                  controller:
                      _pageController,
                  itemCount: images.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex =
                          index;
                    });
                  },
                  itemBuilder:
                      (context, index) {
                    return _RoomImage(
                      imageUrl:
                          images[index],
                    );
                  },
                ),

                // ------------------------------------------------
                // IMAGE COUNTER
                // ------------------------------------------------

                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration:
                        BoxDecoration(
                      color: Colors.black
                          .withValues(
                        alpha: 0.55,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        20,
                      ),
                    ),
                    child: Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons
                              .photo_library_outlined,
                          color:
                              Colors.white,
                          size: 15,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(
                          '${_currentImageIndex + 1}/${images.length}',
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontSize: 12,
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ------------------------------------------------
                // LEFT ARROW
                // ------------------------------------------------

                if (_currentImageIndex >
                    0)
                  Positioned(
                    left: 10,
                    top: 0,
                    bottom: 0,
                    child:
                        _GalleryButton(
                      icon: Icons
                          .chevron_left,
                      onTap: () {
                        _pageController
                            .previousPage(
                          duration:
                              const Duration(
                            milliseconds:
                                250,
                          ),
                          curve:
                              Curves.easeOut,
                        );
                      },
                    ),
                  ),

                // ------------------------------------------------
                // RIGHT ARROW
                // ------------------------------------------------

                if (_currentImageIndex <
                    images.length - 1)
                  Positioned(
                    right: 10,
                    top: 0,
                    bottom: 0,
                    child:
                        _GalleryButton(
                      icon: Icons
                          .chevron_right,
                      onTap: () {
                        _pageController
                            .nextPage(
                          duration:
                              const Duration(
                            milliseconds:
                                250,
                          ),
                          curve:
                              Curves.easeOut,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // ------------------------------------------------------
        // DOT INDICATOR
        // ------------------------------------------------------

        if (images.length > 1)
          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: List.generate(
              images.length,
              (index) {
                final selected =
                    index ==
                        _currentImageIndex;

                return AnimatedContainer(
                  duration:
                      const Duration(
                    milliseconds: 200,
                  ),
                  margin:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 3,
                  ),
                  width:
                      selected ? 20 : 7,
                  height: 7,
                  decoration:
                      BoxDecoration(
                    color: selected
                        ? const Color(
                            0xFFD97706,
                          )
                        : Colors
                            .grey.shade300,
                    borderRadius:
                        BorderRadius
                            .circular(
                      10,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // ============================================================
  // EMPTY IMAGE
  // ============================================================

  Widget _buildEmptyImage() {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius:
            BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            Icons
                .image_not_supported_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 10),
          Text(
            'Chưa có hình ảnh phòng',
            style: TextStyle(
              color:
                  Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// ROOM IMAGE
// ================================================================

class _RoomImage extends StatelessWidget {
  const _RoomImage({
    required this.imageUrl,
  });

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,

      // Loading
      placeholder:
          (context, url) {
        return Container(
          color:
              const Color(0xFFF1F5F9),
          child: const Center(
            child:
                CircularProgressIndicator(
              strokeWidth: 2,
              color:
                  Color(0xFFD97706),
            ),
          ),
        );
      },

      // Error
      errorWidget:
          (context, url, error) {
        return Container(
          color:
              const Color(0xFFF1F5F9),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                Icons
                    .broken_image_outlined,
                size: 42,
                color:
                    Colors.grey.shade400,
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                'Không tải được hình ảnh',
                style: TextStyle(
                  color:
                      Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ================================================================
// GALLERY BUTTON
// ================================================================

class _GalleryButton
    extends StatelessWidget {
  const _GalleryButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.black.withValues(
          alpha: 0.45,
        ),
        shape:
            const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder:
              const CircleBorder(),
          child: Padding(
            padding:
                const EdgeInsets.all(6),
            child: Icon(
              icon,
              color: Colors.white,
              size: 27,
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// INFO ROW
// ================================================================

class _InfoRow
    extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration:
              BoxDecoration(
            color:
                const Color(0xFFFFF7ED),
            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),
          child: Icon(
            icon,
            color:
                const Color(0xFFD97706),
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color:
                      Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                value,
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ================================================================
// POLICY ITEM
// ================================================================

class _PolicyItem
    extends StatelessWidget {
  const _PolicyItem({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color:
                Colors.grey.shade700,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }
}