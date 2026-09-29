import 'package:cloud_firestore/cloud_firestore.dart';

class SeedData {
  static final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  // ============================================================
  // SEED ALL DATA
  // ============================================================

  static Future<void> seed() async {
    await _seedProperties();
    await _seedRooms();
    await _seedUsers();
    await _seedBookings();
    await _seedReviews();
  }

  // ============================================================
  // PROPERTIES
  // ============================================================

  static Future<void> _seedProperties() async {
    final properties =
        <String, Map<String, dynamic>>{
      'vinpearl-phu-quoc': {
        'name': 'Vinpearl Resort Phú Quốc',
        'brand': 'Vinpearl',
        'location': 'Phú Quốc',
        'address': 'Bãi Dài, Phú Quốc',
        'rating': 4.8,
        'reviewCount': 1250,
        'pricePerNight': 2500000,
        'category': 'Resort',
        'occupancyRate': 78,
        'image':
            'https://images.unsplash.com/photo-1566073771259-6a8506099945',
        'amenities': [
          'Hồ bơi',
          'WiFi',
          'Spa',
          'Nhà hàng',
          'Bãi biển riêng',
        ],
      },

      'intercontinental-phu-quoc': {
        'name': 'InterContinental Phú Quốc',
        'brand': 'InterContinental',
        'location': 'Phú Quốc',
        'address': 'Bãi Trường, Phú Quốc',
        'rating': 4.9,
        'reviewCount': 980,
        'pricePerNight': 4200000,
        'category': 'Luxury',
        'occupancyRate': 85,
        'image':
            'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b',
        'amenities': [
          'Hồ bơi',
          'WiFi',
          'Spa',
          'Nhà hàng',
          'Gym',
          'Bãi biển riêng',
        ],
      },

      'premier-village-phu-quoc': {
        'name': 'Premier Village Phú Quốc',
        'brand': 'Premier',
        'location': 'Phú Quốc',
        'address': 'Mũi Ông Đội, Phú Quốc',
        'rating': 4.8,
        'reviewCount': 870,
        'pricePerNight': 5200000,
        'category': 'Villa',
        'occupancyRate': 72,
        'image':
            'https://images.unsplash.com/photo-1601918774946-25832a4be0d6',
        'amenities': [
          'Private Pool',
          'WiFi',
          'Spa',
          'Nhà hàng',
          'Bãi biển riêng',
        ],
      },

      'fusion-resort-phu-quoc': {
        'name': 'Fusion Resort Phú Quốc',
        'brand': 'Fusion',
        'location': 'Phú Quốc',
        'address': 'Cửa Cạn, Phú Quốc',
        'rating': 4.7,
        'reviewCount': 760,
        'pricePerNight': 3900000,
        'category': 'Resort',
        'occupancyRate': 69,
        'image':
            'https://images.unsplash.com/photo-1540541338287-41700207dee6',
        'amenities': [
          'Hồ bơi',
          'WiFi',
          'Spa',
          'Yoga',
          'Nhà hàng',
        ],
      },

      'salinda-resort-phu-quoc': {
        'name': 'Salinda Resort Phú Quốc',
        'brand': 'Salinda',
        'location': 'Phú Quốc',
        'address': 'Cửa Lấp, Phú Quốc',
        'rating': 4.7,
        'reviewCount': 620,
        'pricePerNight': 3100000,
        'category': 'Resort',
        'occupancyRate': 65,
        'image':
            'https://images.unsplash.com/photo-1564501049412-61c2a3083791',
        'amenities': [
          'Hồ bơi',
          'WiFi',
          'Spa',
          'Nhà hàng',
          'Gym',
        ],
      },

      'la-mer-resort-phu-quoc': {
        'name': 'La Mer Resort Phú Quốc',
        'brand': 'La Mer',
        'location': 'Phú Quốc',
        'address': 'Dương Đông, Phú Quốc',
        'rating': 4.5,
        'reviewCount': 410,
        'pricePerNight': 1800000,
        'category': 'Resort',
        'occupancyRate': 61,
        'image':
            'https://images.unsplash.com/photo-1566665797739-1674de7a421a',
        'amenities': [
          'Hồ bơi',
          'WiFi',
          'Nhà hàng',
          'Vườn',
        ],
      },

      'novotel-phu-quoc': {
        'name': 'Novotel Phú Quốc Resort',
        'brand': 'Novotel',
        'location': 'Phú Quốc',
        'address': 'Bãi Trường, Phú Quốc',
        'rating': 4.6,
        'reviewCount': 540,
        'pricePerNight': 2700000,
        'category': 'Resort',
        'occupancyRate': 74,
        'image':
            'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa',
        'amenities': [
          'Hồ bơi',
          'WiFi',
          'Spa',
          'Nhà hàng',
          'Gym',
        ],
      },

      'dusit-princess-phu-quoc': {
        'name':
            'Dusit Princess Moonrise Beach Resort',
        'brand': 'Dusit Princess',
        'location': 'Phú Quốc',
        'address': 'Cửa Lấp, Phú Quốc',
        'rating': 4.6,
        'reviewCount': 690,
        'pricePerNight': 2900000,
        'category': 'Beach Resort',
        'occupancyRate': 71,
        'image':
            'https://images.unsplash.com/photo-1571896349842-33c89424de2d',
        'amenities': [
          'Hồ bơi',
          'WiFi',
          'Spa',
          'Nhà hàng',
          'Bãi biển riêng',
        ],
      },
    };

    for (final entry in properties.entries) {
      await _db
          .collection('properties')
          .doc(entry.key)
          .set(entry.value);
    }
  }

  // ============================================================
  // ROOMS
  // ============================================================

  static Future<void> _seedRooms() async {
    final rooms =
        <String, List<Map<String, dynamic>>>{
      // ========================================================
      // VINPEARL
      // ========================================================

      'vinpearl-phu-quoc': [
        {
          'id': 'deluxe-ocean',
          'name': 'Deluxe Ocean View',
          'area': 45,
          'bedType': 'King',
          'pricePerNight': 2500000,
          'view': 'Hướng biển',
          'image':
              'https://images.unsplash.com/photo-1611892440504-42a792eec9d3',
          'images': [
            'https://images.unsplash.com/photo-1611892440504-42a792eec9d3',
            'https://images.unsplash.com/photo-1590490360182-c33d57733427',
            'https://images.unsplash.com/photo-1595576508898-0ad5c879a061',
            'https://images.unsplash.com/photo-1584132967334-10e028bd69f7',
            'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c',
          ],
          'amenities': [
            'Ocean View',
            'WiFi',
            'Breakfast',
            'TV',
            'Minibar',
          ],
          'availableCount': 5,
        },

        {
          'id': 'deluxe-garden',
          'name': 'Deluxe Garden View',
          'area': 40,
          'bedType': 'King',
          'pricePerNight': 2200000,
          'view': 'Hướng vườn',
          'image':
              'https://images.unsplash.com/photo-1586023492125-27b2c045efd7',
          'images': [
            'https://images.unsplash.com/photo-1586023492125-27b2c045efd7',
            'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace',
            'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6',
            'https://images.unsplash.com/photo-1617104678098-de229db51175',
          ],
          'amenities': [
            'Garden View',
            'WiFi',
            'Breakfast',
            'TV',
          ],
          'availableCount': 8,
        },

        {
          'id': 'executive-suite',
          'name': 'Executive Suite',
          'area': 70,
          'bedType': 'King',
          'pricePerNight': 4200000,
          'view': 'Hướng biển',
          'image':
              'https://images.unsplash.com/photo-1600607687920-4e2a09cf159d',
          'images': [
            'https://images.unsplash.com/photo-1600607687920-4e2a09cf159d',
            'https://images.unsplash.com/photo-1600607688969-a5bfcd646154',
            'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3',
            'https://images.unsplash.com/photo-1600566753086-00f18fb6b3ea',
          ],
          'amenities': [
            'Ocean View',
            'WiFi',
            'Breakfast',
            'Living Room',
            'Bathtub',
          ],
          'availableCount': 3,
        },
      ],

      // ========================================================
      // INTERCONTINENTAL
      // ========================================================

      'intercontinental-phu-quoc': [
        {
          'id': 'classic-room',
          'name': 'Classic Ocean Room',
          'area': 49,
          'bedType': 'King',
          'pricePerNight': 4200000,
          'view': 'Hướng biển',
          'image':
              'https://images.unsplash.com/photo-1566665797739-1674de7a421a',
          'images': [
            'https://images.unsplash.com/photo-1566665797739-1674de7a421a',
            'https://images.unsplash.com/photo-1590490359683-658d3d23f972',
            'https://images.unsplash.com/photo-1591088398332-8a7791972843',
            'https://images.unsplash.com/photo-1590490360182-c33d57733427',
          ],
          'amenities': [
            'Ocean View',
            'WiFi',
            'Breakfast',
            'Bathtub',
          ],
          'availableCount': 4,
        },

        {
          'id': 'ocean-suite',
          'name': 'Ocean Suite',
          'area': 80,
          'bedType': 'King',
          'pricePerNight': 6500000,
          'view': 'Toàn cảnh biển',
          'image':
              'https://images.unsplash.com/photo-1600607688969-a5bfcd646154',
          'images': [
            'https://images.unsplash.com/photo-1600607688969-a5bfcd646154',
            'https://images.unsplash.com/photo-1600566753086-00f18fb6b3ea',
            'https://images.unsplash.com/photo-1600566753051-8c2b0e9c5d1f',
            'https://images.unsplash.com/photo-1600607687920-4e2a09cf159d',
            'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3',
          ],
          'amenities': [
            'Ocean View',
            'WiFi',
            'Breakfast',
            'Living Room',
            'Bathtub',
          ],
          'availableCount': 2,
        },

        {
          'id': 'club-room',
          'name': 'Club InterContinental Room',
          'area': 55,
          'bedType': 'King',
          'pricePerNight': 5200000,
          'view': 'Hướng biển',
          'image':
              'https://images.unsplash.com/photo-1591088398332-8a7791972843',
          'images': [
            'https://images.unsplash.com/photo-1591088398332-8a7791972843',
            'https://images.unsplash.com/photo-1611892440504-42a792eec9d3',
            'https://images.unsplash.com/photo-1584132967334-10e028bd69f7',
            'https://images.unsplash.com/photo-1595576508898-0ad5c879a061',
          ],
          'amenities': [
            'Ocean View',
            'Club Lounge',
            'Breakfast',
            'WiFi',
          ],
          'availableCount': 3,
        },
      ],

      // ========================================================
      // PREMIER VILLAGE
      // ========================================================

      'premier-village-phu-quoc': [
        {
          'id': 'garden-villa',
          'name': 'Garden Villa',
          'area': 150,
          'bedType': 'King',
          'pricePerNight': 5200000,
          'view': 'Hướng vườn',
          'image':
              'https://images.unsplash.com/photo-1601918774946-25832a4be0d6',
          'images': [
            'https://images.unsplash.com/photo-1601918774946-25832a4be0d6',
            'https://images.unsplash.com/photo-1600607687920-4e2a09cf159d',
            'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3',
            'https://images.unsplash.com/photo-1600566753086-00f18fb6b3ea',
          ],
          'amenities': [
            'Private Pool',
            'Garden',
            'WiFi',
            'Breakfast',
          ],
          'availableCount': 3,
        },

        {
          'id': 'ocean-villa',
          'name': 'Ocean Villa',
          'area': 180,
          'bedType': 'King',
          'pricePerNight': 6800000,
          'view': 'Hướng biển',
          'image':
              'https://images.unsplash.com/photo-1600607688969-a5bfcd646154',
          'images': [
            'https://images.unsplash.com/photo-1600607688969-a5bfcd646154',
            'https://images.unsplash.com/photo-1601918774946-25832a4be0d6',
            'https://images.unsplash.com/photo-1540541338287-41700207dee6',
            'https://images.unsplash.com/photo-1566073771259-6a8506099945',
            'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b',
          ],
          'amenities': [
            'Private Pool',
            'Ocean View',
            'WiFi',
            'Breakfast',
          ],
          'availableCount': 2,
        },
      ],

      // ========================================================
      // FUSION
      // ========================================================

      'fusion-resort-phu-quoc': [
        {
          'id': 'pool-villa',
          'name': 'Pool Villa',
          'area': 130,
          'bedType': 'King',
          'pricePerNight': 3900000,
          'view': 'Hướng vườn',
          'image':
              'https://images.unsplash.com/photo-1540541338287-41700207dee6',
          'images': [
            'https://images.unsplash.com/photo-1540541338287-41700207dee6',
            'https://images.unsplash.com/photo-1601918774946-25832a4be0d6',
            'https://images.unsplash.com/photo-1564501049412-61c2a3083791',
            'https://images.unsplash.com/photo-1571896349842-33c89424de2d',
          ],
          'amenities': [
            'Private Pool',
            'WiFi',
            'Breakfast',
            'Spa',
          ],
          'availableCount': 4,
        },

        {
          'id': 'garden-villa',
          'name': 'Garden Pool Villa',
          'area': 150,
          'bedType': 'King',
          'pricePerNight': 4500000,
          'view': 'Hướng vườn',
          'image':
              'https://images.unsplash.com/photo-1564501049412-61c2a3083791',
          'images': [
            'https://images.unsplash.com/photo-1564501049412-61c2a3083791',
            'https://images.unsplash.com/photo-1601918774946-25832a4be0d6',
            'https://images.unsplash.com/photo-1571896349842-33c89424de2d',
            'https://images.unsplash.com/photo-1540541338287-41700207dee6',
          ],
          'amenities': [
            'Private Pool',
            'Garden',
            'WiFi',
            'Breakfast',
          ],
          'availableCount': 3,
        },
      ],

      // ========================================================
      // SALINDA
      // ========================================================

      'salinda-resort-phu-quoc': [
        {
          'id': 'deluxe-room',
          'name': 'Deluxe Room',
          'area': 42,
          'bedType': 'King',
          'pricePerNight': 3100000,
          'view': 'Hướng vườn',
          'image':
              'https://images.unsplash.com/photo-1590490360182-c33d57733427',
          'images': [
            'https://images.unsplash.com/photo-1590490360182-c33d57733427',
            'https://images.unsplash.com/photo-1611892440504-42a792eec9d3',
            'https://images.unsplash.com/photo-1586023492125-27b2c045efd7',
            'https://images.unsplash.com/photo-1595576508898-0ad5c879a061',
          ],
          'amenities': [
            'WiFi',
            'Breakfast',
            'TV',
            'Minibar',
          ],
          'availableCount': 6,
        },

        {
          'id': 'pool-villa',
          'name': 'Salinda Pool Villa',
          'area': 90,
          'bedType': 'King',
          'pricePerNight': 4800000,
          'view': 'Hướng vườn',
          'image':
              'https://images.unsplash.com/photo-1571896349842-33c89424de2d',
          'images': [
            'https://images.unsplash.com/photo-1571896349842-33c89424de2d',
            'https://images.unsplash.com/photo-1540541338287-41700207dee6',
            'https://images.unsplash.com/photo-1601918774946-25832a4be0d6',
            'https://images.unsplash.com/photo-1564501049412-61c2a3083791',
          ],
          'amenities': [
            'Private Pool',
            'WiFi',
            'Breakfast',
            'Bathtub',
          ],
          'availableCount': 2,
        },
      ],

      // ========================================================
      // LA MER
      // ========================================================

      'la-mer-resort-phu-quoc': [
        {
          'id': 'standard-room',
          'name': 'Standard Garden Room',
          'area': 32,
          'bedType': 'Queen',
          'pricePerNight': 1800000,
          'view': 'Hướng vườn',
          'image':
              'https://images.unsplash.com/photo-1586023492125-27b2c045efd7',
          'images': [
            'https://images.unsplash.com/photo-1586023492125-27b2c045efd7',
            'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace',
            'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6',
            'https://images.unsplash.com/photo-1617104678098-de229db51175',
          ],
          'amenities': [
            'WiFi',
            'Breakfast',
            'TV',
          ],
          'availableCount': 10,
        },

        {
          'id': 'superior-room',
          'name': 'Superior Pool View',
          'area': 38,
          'bedType': 'King',
          'pricePerNight': 2100000,
          'view': 'Hướng hồ bơi',
          'image':
              'https://images.unsplash.com/photo-1591088398332-8a7791972843',
          'images': [
            'https://images.unsplash.com/photo-1591088398332-8a7791972843',
            'https://images.unsplash.com/photo-1590490359683-658d3d23f972',
            'https://images.unsplash.com/photo-1590490360182-c33d57733427',
            'https://images.unsplash.com/photo-1611892440504-42a792eec9d3',
          ],
          'amenities': [
            'Pool View',
            'WiFi',
            'Breakfast',
          ],
          'availableCount': 6,
        },
      ],

      // ========================================================
      // NOVOTEL
      // ========================================================

      'novotel-phu-quoc': [
        {
          'id': 'superior-room',
          'name': 'Superior Room',
          'area': 35,
          'bedType': 'King',
          'pricePerNight': 2700000,
          'view': 'Hướng vườn',
          'image':
              'https://images.unsplash.com/photo-1595576508898-0ad5c879a061',
          'images': [
            'https://images.unsplash.com/photo-1595576508898-0ad5c879a061',
            'https://images.unsplash.com/photo-1590490360182-c33d57733427',
            'https://images.unsplash.com/photo-1584132967334-10e028bd69f7',
            'https://images.unsplash.com/photo-1611892440504-42a792eec9d3',
          ],
          'amenities': [
            'WiFi',
            'Breakfast',
            'TV',
            'Minibar',
          ],
          'availableCount': 7,
        },

        {
          'id': 'deluxe-ocean',
          'name': 'Deluxe Ocean View',
          'area': 45,
          'bedType': 'King',
          'pricePerNight': 3300000,
          'view': 'Hướng biển',
          'image':
              'https://images.unsplash.com/photo-1611892440504-42a792eec9d3',
          'images': [
            'https://images.unsplash.com/photo-1611892440504-42a792eec9d3',
            'https://images.unsplash.com/photo-1595576508898-0ad5c879a061',
            'https://images.unsplash.com/photo-1590490360182-c33d57733427',
            'https://images.unsplash.com/photo-1584132967334-10e028bd69f7',
            'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c',
          ],
          'amenities': [
            'Ocean View',
            'WiFi',
            'Breakfast',
            'Bathtub',
          ],
          'availableCount': 4,
        },
      ],

      // ========================================================
      // DUSIT PRINCESS
      // ========================================================

      'dusit-princess-phu-quoc': [
        {
          'id': 'deluxe-room',
          'name': 'Deluxe Room',
          'area': 40,
          'bedType': 'King',
          'pricePerNight': 2900000,
          'view': 'Hướng vườn',
          'image':
              'https://images.unsplash.com/photo-1564501049412-61c2a3083791',
          'images': [
            'https://images.unsplash.com/photo-1564501049412-61c2a3083791',
            'https://images.unsplash.com/photo-1586023492125-27b2c045efd7',
            'https://images.unsplash.com/photo-1590490360182-c33d57733427',
            'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace',
          ],
          'amenities': [
            'WiFi',
            'Breakfast',
            'TV',
          ],
          'availableCount': 8,
        },

        {
          'id': 'sea-view-room',
          'name': 'Sea View Room',
          'area': 45,
          'bedType': 'King',
          'pricePerNight': 3500000,
          'view': 'Hướng biển',
          'image':
              'https://images.unsplash.com/photo-1566073771259-6a8506099945',
          'images': [
            'https://images.unsplash.com/photo-1566073771259-6a8506099945',
            'https://images.unsplash.com/photo-1611892440504-42a792eec9d3',
            'https://images.unsplash.com/photo-1595576508898-0ad5c879a061',
            'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c',
          ],
          'amenities': [
            'Ocean View',
            'WiFi',
            'Breakfast',
            'Minibar',
          ],
          'availableCount': 4,
        },
      ],
    };

    for (final propertyEntry in rooms.entries) {
      final propertyId = propertyEntry.key;

      for (final room in propertyEntry.value) {
        final roomId = room['id'] as String;

        final data =
            Map<String, dynamic>.from(room)
              ..remove('id');

        await _db
            .collection('properties')
            .doc(propertyId)
            .collection('rooms')
            .doc(roomId)
            .set(data);
      }
    }
  }

  // ============================================================
  // USERS + FAVORITES
  // ============================================================

  static Future<void> _seedUsers() async {
    final users = {
      'demo-customer': {
        'displayName': 'Nguyễn Văn An',
        'email': 'customer@luxestay.vn',
        'phone': '0901234567',
        'role': 'CUSTOMER',
        'avatar': '',
        'createdAt':
            FieldValue.serverTimestamp(),
      },

      'customer-02': {
        'displayName': 'Trần Minh Anh',
        'email': 'minhanh@luxestay.vn',
        'phone': '0912345678',
        'role': 'CUSTOMER',
        'avatar': '',
        'createdAt':
            FieldValue.serverTimestamp(),
      },

      'customer-03': {
        'displayName': 'Lê Hoàng Nam',
        'email': 'hoangnam@luxestay.vn',
        'phone': '0923456789',
        'role': 'CUSTOMER',
        'avatar': '',
        'createdAt':
            FieldValue.serverTimestamp(),
      },

      'demo-admin': {
        'displayName': 'LuxeStay Admin',
        'email': 'admin@luxestay.vn',
        'phone': '0909999999',
        'role': 'ADMIN',
        'avatar': '',
        'createdAt':
            FieldValue.serverTimestamp(),
      },
    };

    for (final entry in users.entries) {
      await _db
          .collection('users')
          .doc(entry.key)
          .set(entry.value);
    }

    // ==========================================================
    // FAVORITES
    // ==========================================================

    final favorites = {
      'demo-customer': [
        'vinpearl-phu-quoc',
        'intercontinental-phu-quoc',
        'premier-village-phu-quoc',
      ],
      'customer-02': [
        'fusion-resort-phu-quoc',
        'salinda-resort-phu-quoc',
      ],
      'customer-03': [
        'novotel-phu-quoc',
        'dusit-princess-phu-quoc',
      ],
    };

    for (final entry in favorites.entries) {
      for (final propertyId in entry.value) {
        await _db
            .collection('users')
            .doc(entry.key)
            .collection('favorites')
            .doc(propertyId)
            .set({
          'propertyId': propertyId,
          'createdAt':
              FieldValue.serverTimestamp(),
        });
      }
    }
  }

  // ============================================================
  // BOOKINGS
  // ============================================================

  static Future<void> _seedBookings() async {
    final bookings = {
      'booking-demo-01': {
        'userId': 'demo-customer',
        'propertyId':
            'vinpearl-phu-quoc',
        'propertyName':
            'Vinpearl Resort Phú Quốc',
        'roomId': 'deluxe-ocean',
        'roomName':
            'Deluxe Ocean View',
        'checkIn': Timestamp.fromDate(
          DateTime(2026, 10, 10),
        ),
        'checkOut': Timestamp.fromDate(
          DateTime(2026, 10, 13),
        ),
        'guests': 2,
        'rooms': 1,
        'pricePerNight': 2500000,
        'totalNights': 3,
        'totalPrice': 7500000,
        'status': 'confirmed',
        'createdAt':
            FieldValue.serverTimestamp(),
      },

      'booking-demo-02': {
        'userId': 'demo-customer',
        'propertyId':
            'intercontinental-phu-quoc',
        'propertyName':
            'InterContinental Phú Quốc',
        'roomId': 'ocean-suite',
        'roomName': 'Ocean Suite',
        'checkIn': Timestamp.fromDate(
          DateTime(2026, 11, 5),
        ),
        'checkOut': Timestamp.fromDate(
          DateTime(2026, 11, 7),
        ),
        'guests': 2,
        'rooms': 1,
        'pricePerNight': 6500000,
        'totalNights': 2,
        'totalPrice': 13000000,
        'status': 'pending',
        'createdAt':
            FieldValue.serverTimestamp(),
      },

      'booking-demo-03': {
        'userId': 'customer-02',
        'propertyId':
            'fusion-resort-phu-quoc',
        'propertyName':
            'Fusion Resort Phú Quốc',
        'roomId': 'pool-villa',
        'roomName': 'Pool Villa',
        'checkIn': Timestamp.fromDate(
          DateTime(2026, 9, 28),
        ),
        'checkOut': Timestamp.fromDate(
          DateTime(2026, 10, 1),
        ),
        'guests': 2,
        'rooms': 1,
        'pricePerNight': 3900000,
        'totalNights': 3,
        'totalPrice': 11700000,
        'status': 'confirmed',
        'createdAt':
            FieldValue.serverTimestamp(),
      },
    };

    for (final entry in bookings.entries) {
      await _db
          .collection('bookings')
          .doc(entry.key)
          .set(entry.value);
    }
  }

  // ============================================================
  // REVIEWS
  // ============================================================

  static Future<void> _seedReviews() async {
    final reviews = {
      'review-001': {
        'userId': 'demo-customer',
        'userName': 'Nguyễn Văn An',
        'propertyId':
            'vinpearl-phu-quoc',
        'propertyName':
            'Vinpearl Resort Phú Quốc',
        'rating': 5,
        'comment':
            'Resort rất đẹp, phòng sạch sẽ và nhân viên phục vụ nhiệt tình.',
        'createdAt': Timestamp.fromDate(
          DateTime(2026, 8, 15),
        ),
      },

      'review-002': {
        'userId': 'customer-02',
        'userName': 'Trần Minh Anh',
        'propertyId':
            'vinpearl-phu-quoc',
        'propertyName':
            'Vinpearl Resort Phú Quốc',
        'rating': 4,
        'comment':
            'Không gian đẹp, view biển rất ấn tượng. Bữa sáng khá ngon.',
        'createdAt': Timestamp.fromDate(
          DateTime(2026, 8, 20),
        ),
      },

      'review-003': {
        'userId': 'customer-03',
        'userName': 'Lê Hoàng Nam',
        'propertyId':
            'intercontinental-phu-quoc',
        'propertyName':
            'InterContinental Phú Quốc',
        'rating': 5,
        'comment':
            'Phòng rộng và sang trọng. Dịch vụ rất tốt.',
        'createdAt': Timestamp.fromDate(
          DateTime(2026, 8, 25),
        ),
      },

      'review-004': {
        'userId': 'demo-customer',
        'userName': 'Nguyễn Văn An',
        'propertyId':
            'premier-village-phu-quoc',
        'propertyName':
            'Premier Village Phú Quốc',
        'rating': 5,
        'comment':
            'Villa riêng tư, hồ bơi đẹp và không gian rất yên tĩnh.',
        'createdAt': Timestamp.fromDate(
          DateTime(2026, 8, 28),
        ),
      },

      'review-005': {
        'userId': 'customer-02',
        'userName': 'Trần Minh Anh',
        'propertyId':
            'fusion-resort-phu-quoc',
        'propertyName':
            'Fusion Resort Phú Quốc',
        'rating': 4,
        'comment':
            'Resort đẹp, nhiều cây xanh và không gian thư giãn.',
        'createdAt': Timestamp.fromDate(
          DateTime(2026, 9, 2),
        ),
      },

      'review-006': {
        'userId': 'customer-03',
        'userName': 'Lê Hoàng Nam',
        'propertyId':
            'salinda-resort-phu-quoc',
        'propertyName':
            'Salinda Resort Phú Quốc',
        'rating': 5,
        'comment':
            'Nhân viên thân thiện, phòng đẹp và rất sạch.',
        'createdAt': Timestamp.fromDate(
          DateTime(2026, 9, 5),
        ),
      },

      'review-007': {
        'userId': 'demo-customer',
        'userName': 'Nguyễn Văn An',
        'propertyId':
            'novotel-phu-quoc',
        'propertyName':
            'Novotel Phú Quốc Resort',
        'rating': 4,
        'comment':
            'Vị trí thuận tiện, phòng thoải mái và có view đẹp.',
        'createdAt': Timestamp.fromDate(
          DateTime(2026, 9, 8),
        ),
      },

      'review-008': {
        'userId': 'customer-02',
        'userName': 'Trần Minh Anh',
        'propertyId':
            'dusit-princess-phu-quoc',
        'propertyName':
            'Dusit Princess Moonrise Beach Resort',
        'rating': 5,
        'comment':
            'Bãi biển đẹp, hồ bơi sạch và dịch vụ chuyên nghiệp.',
        'createdAt': Timestamp.fromDate(
          DateTime(2026, 9, 10),
        ),
      },
    };

    for (final entry in reviews.entries) {
      await _db
          .collection('reviews')
          .doc(entry.key)
          .set(entry.value);
    }
  }
}