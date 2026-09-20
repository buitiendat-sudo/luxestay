import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/property.dart';
import '../../services/firestore_service.dart';
import 'hotel_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Vui lòng đăng nhập để xem danh sách yêu thích.',
          ),
        ),
      );
    }

    final firestoreService = context.read<FirestoreService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F7F3),
        elevation: 0,
        title: const Text(
          'Yêu thích',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<Set<String>>(
        stream: firestoreService.getFavoriteIds(user.uid),
        builder: (context, favoriteSnapshot) {
          if (favoriteSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (favoriteSnapshot.hasError) {
            return _ErrorState(
              message:
                  'Không thể tải danh sách yêu thích.\n${favoriteSnapshot.error}',
            );
          }

          final favoriteIds =
              favoriteSnapshot.data ?? <String>{};

          if (favoriteIds.isEmpty) {
            return const _EmptyFavorites();
          }

          return StreamBuilder<List<Property>>(
            stream: firestoreService.getProperties(),
            builder: (context, propertySnapshot) {
              if (propertySnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (propertySnapshot.hasError) {
                return _ErrorState(
                  message:
                      'Không thể tải danh sách resort.\n${propertySnapshot.error}',
                );
              }

              final properties =
                  propertySnapshot.data ?? const <Property>[];

              final favoriteProperties = properties
                  .where(
                    (property) =>
                        favoriteIds.contains(property.id),
                  )
                  .toList(growable: false);

              if (favoriteProperties.isEmpty) {
                return const _EmptyFavorites();
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  24,
                ),
                itemCount: favoriteProperties.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return _FavoriteCard(
                    property: favoriteProperties[index],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================
// FAVORITE CARD
// ============================================================

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.property,
  });

  final Property property;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final firestoreService = context.read<FirestoreService>();

    final formatter = NumberFormat(
      '#,###',
      'vi_VN',
    );

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================================================
          // IMAGE
          // ==================================================

          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.7,
                child: property.image.isEmpty
                    ? Container(
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.hotel,
                          size: 50,
                          color: Colors.grey,
                        ),
                      )
                    : Image.network(
                        property.image,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.hotel,
                              size: 50,
                              color: Colors.grey,
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
                              child:
                                  CircularProgressIndicator(),
                            ),
                          );
                        },
                      ),
              ),

              // Category
              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A)
                        .withValues(alpha: 0.9),
                    borderRadius:
                        BorderRadius.circular(10),
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

              // Favorite button
              Positioned(
                right: 12,
                top: 12,
                child: Material(
                  color: Colors.white.withValues(
                    alpha: 0.95,
                  ),
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Bỏ yêu thích',
                    onPressed: user == null
                        ? null
                        : () async {
                            try {
                              await firestoreService
                                  .removeFavorite(
                                userId: user.uid,
                                propertyId: property.id,
                              );
                            } catch (e) {
                              if (!context.mounted) {
                                return;
                              }

                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Không thể bỏ yêu thích: $e',
                                  ),
                                ),
                              );
                            }
                          },
                    icon: const Icon(
                      Icons.favorite,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ==================================================
          // CONTENT
          // ==================================================

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // Tên + rating
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        property.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius:
                            BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            size: 15,
                            color: Color(0xFFD97706),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            property.rating
                                .toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Location
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        property.location,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Reviews
                Row(
                  children: [
                    const Icon(
                      Icons.rate_review_outlined,
                      size: 17,
                      color: Color(0xFFD97706),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${property.reviewCount} đánh giá',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Amenities
                if (property.amenities.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: property.amenities
                        .take(4)
                        .map(
                          (amenity) => Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFFF8FAFC),
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: Text(
                              amenity,
                              style: TextStyle(
                                color:
                                    Colors.grey.shade700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),

                const SizedBox(height: 16),

                const Divider(),

                const SizedBox(height: 10),

                // Price + button
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
                            'Giá từ',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${formatter.format(property.pricePerNight)} đ',
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
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

                    const SizedBox(width: 12),

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
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(
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
}

// ============================================================
// EMPTY
// ============================================================

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.favorite_border,
                size: 48,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chưa có nơi yêu thích',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Những resort bạn yêu thích sẽ xuất hiện ở đây.',
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

// ============================================================
// ERROR
// ============================================================

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 52,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            const Text(
              'Có lỗi xảy ra',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
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