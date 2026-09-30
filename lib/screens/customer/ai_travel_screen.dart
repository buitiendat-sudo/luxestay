
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/ai_travel_plan.dart';
import '../../models/property.dart';
import '../../services/ai_travel_service.dart';
import '../../services/firestore_service.dart';
import 'hotel_detail_screen.dart';

class AiTravelScreen extends StatefulWidget {
  const AiTravelScreen({super.key});

  @override
  State<AiTravelScreen> createState() => _AiTravelScreenState();
}

class _AiTravelScreenState extends State<AiTravelScreen> {
  static const Color _navy = Color(0xFF0F172A);
  static const Color _blue = Color(0xFF2563EB);
  static const Color _background = Color(0xFFF8F9FF);

  final TextEditingController _budgetController =
      TextEditingController(text: '5000000');

  final List<String> _destinations = const [
    'Đà Nẵng',
    'Phú Quốc',
    'Nha Trang',
    'Đà Lạt',
    'Hạ Long',
    'Hà Nội',
    'TP. Hồ Chí Minh',
  ];

  String _destination = 'Đà Nẵng';
  int _days = 3;
  int _guests = 2;

  bool _loading = false;
  AiTravelPlan? _plan;

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  int get _budget {
    final value =
        int.tryParse(_budgetController.text.replaceAll('.', ''));
    return value ?? 0;
  }

  Future<void> _generatePlan() async {
    FocusScope.of(context).unfocus();

    if (_budget < 100000) {
      _showError('Ngân sách phải lớn hơn 100.000đ.');
      return;
    }

    setState(() {
      _loading = true;
      _plan = null;
    });

    try {
      final firestoreService = context.read<FirestoreService>();
      final service = AiTravelService(firestoreService);

      final plan = await service.generateTravelPlan(
        destination: _destination,
        days: _days,
        guests: _guests,
        budget: _budget,
      );

      if (!mounted) return;

      setState(() {
        _plan = plan;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showError('Không thể tạo kế hoạch: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _money(int value) {
    return NumberFormat('#,###', 'vi_VN').format(value);
  }

  Property? _findProperty(
    AiTravelPlan plan,
    String propertyId,
    List<Property> properties,
  ) {
    for (final property in properties) {
      if (property.id == propertyId) {
        return property;
      }
    }

    return null;
  }

  Future<void> _openHotel(
    AiHotelRecommendation recommendation,
  ) async {
    final properties =
        await context.read<FirestoreService>().getProperties().first;

    if (!mounted) return;

    final property = _findProperty(
      _plan!,
      recommendation.propertyId,
      properties,
    );

    if (property == null) {
      _showError('Không tìm thấy khách sạn trong LuxeStay.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PropertyDetailScreen(
          property: property,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'AI Travel Planner',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        elevation: 0,
      ),
      body: SafeArea(
        child: _loading
            ? _buildLoading()
            : _plan == null
                ? _buildForm()
                : _buildPlan(),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHero(),

          const SizedBox(height: 24),

          const Text(
            'Bạn muốn đi đâu?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _navy,
            ),
          ),

          const SizedBox(height: 10),

          _buildDestinationPicker(),

          const SizedBox(height: 18),

          const Text(
            'Số ngày',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          _buildCounter(
            value: _days,
            suffix: 'ngày',
            min: 1,
            max: 30,
            onChanged: (value) {
              setState(() => _days = value);
            },
          ),

          const SizedBox(height: 18),

          const Text(
            'Số người',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          _buildCounter(
            value: _guests,
            suffix: 'người',
            min: 1,
            max: 20,
            onChanged: (value) {
              setState(() => _guests = value);
            },
          ),

          const SizedBox(height: 18),

          const Text(
            'Ngân sách',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            controller: _budgetController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              suffixText: 'VNĐ',
              prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: _generatePlan,
              icon: const Icon(Icons.auto_awesome),
              label: const Text(
                'Lập kế hoạch với AI',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _navy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          _buildInfoCard(),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1D4ED8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: 34,
          ),
          SizedBox(height: 14),
          Text(
            'AI TRAVEL PLANNER',
            style: TextStyle(
              color: Color(0xFFBFDBFE),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Lên kế hoạch chuyến đi\ncùng LuxeStay',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'AI sẽ gợi ý địa điểm, nhà hàng, chi phí, lịch trình và khách sạn phù hợp.',
            style: TextStyle(
              color: Color(0xFFE0F2FE),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationPicker() {
    return InkWell(
      onTap: () async {
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
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 10, 20, 14),
                    child: Text(
                      'Chọn điểm đến',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ..._destinations.map(
                    (destination) => ListTile(
                      leading: Icon(
                        destination == _destination
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: destination == _destination
                            ? _blue
                            : Colors.grey,
                      ),
                      title: Text(destination),
                      onTap: () {
                        Navigator.pop(context, destination);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );

        if (selected != null) {
          setState(() {
            _destination = selected;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: _blue,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _destination,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down),
          ],
        ),
      ),
    );
  }

  Widget _buildCounter({
    required int value,
    required String suffix,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: value <= min
                ? null
                : () => onChanged(value - 1),
            icon: const Icon(
              Icons.remove_circle_outline,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                '$value $suffix',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: value >= max
                ? null
                : () => onChanged(value + 1),
            icon: const Icon(
              Icons.add_circle_outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.hotel_outlined,
            color: _blue,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'AI sẽ ưu tiên các khách sạn và phòng đang có trong dữ liệu LuxeStay, phù hợp với điểm đến và ngân sách của bạn.',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: Color(0xFF1E3A8A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            const Text(
              'AI đang lập kế hoạch...',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Đang tìm khách sạn, địa điểm và xây dựng lịch trình cho $_destination.',
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

  Widget _buildPlan() {
    final plan = _plan!;

    return StreamBuilder<List<Property>>(
      stream: context.read<FirestoreService>().getProperties(),
      builder: (context, snapshot) {
        final properties =
            snapshot.data ?? const <Property>[];

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPlanHeader(plan),

              const SizedBox(height: 18),

              _sectionTitle(
                Icons.hotel_outlined,
                'Khách sạn AI đề xuất',
              ),

              const SizedBox(height: 10),

              ...plan.hotels.map(
                (hotel) => _buildHotelCard(
                  hotel,
                  properties,
                ),
              ),

              const SizedBox(height: 20),

              _sectionTitle(
                Icons.route_outlined,
                'Lịch trình ${plan.itinerary.length} ngày',
              ),

              const SizedBox(height: 10),

              ...plan.itinerary.map(
                _buildDayCard,
              ),

              const SizedBox(height: 20),

              _sectionTitle(
                Icons.place_outlined,
                'Địa điểm nên ghé',
              ),

              const SizedBox(height: 10),

              ...plan.places.map(
                _buildPlaceCard,
              ),

              const SizedBox(height: 20),

              _sectionTitle(
                Icons.restaurant_outlined,
                'Nhà hàng gợi ý',
              ),

              const SizedBox(height: 10),

              ...plan.restaurants.map(
                _buildRestaurantCard,
              ),

              const SizedBox(height: 20),

              _sectionTitle(
                Icons.account_balance_wallet_outlined,
                'Dự toán chi phí',
              ),

              const SizedBox(height: 10),

              _buildBudgetCard(plan.budget),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _plan = null;
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text(
                    'Lập kế hoạch khác',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlanHeader(AiTravelPlan plan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: Color(0xFFFBBF24),
              ),
              SizedBox(width: 8),
              Text(
                'KẾ HOẠCH CỦA BẠN',
                style: TextStyle(
                  color: Color(0xFFBFDBFE),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            plan.destination,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            plan.summary,
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(
          icon,
          size: 21,
          color: _navy,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: _navy,
          ),
        ),
      ],
    );
  }

  Widget _buildHotelCard(
    AiHotelRecommendation recommendation,
    List<Property> properties,
  ) {
    final property = _findProperty(
      _plan!,
      recommendation.propertyId,
      properties,
    );

    if (property == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        onTap: () => _openHotel(recommendation),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (property.image.isNotEmpty)
              SizedBox(
                height: 150,
                width: double.infinity,
                child: Image.network(
                  property.image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.hotel),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          property.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.star,
                        size: 16,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        property.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Text(
                    property.location,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    recommendation.reason,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Ước tính: ${_money(recommendation.estimatedTotal)}đ',
                          style: const TextStyle(
                            color: _navy,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      FilledButton(
                        onPressed: () => _openHotel(
                          recommendation,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: _navy,
                        ),
                        child: const Text('Xem phòng'),
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

  Widget _buildDayCard(AiDayPlan day) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ngày ${day.day} · ${day.title}',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            ...day.activities.map(
              (activity) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(
                        color: _blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        activity,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Chi phí dự kiến: ${_money(day.estimatedCost)}đ',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceCard(AiPlace place) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFEFF6FF),
          child: Icon(
            Icons.place,
            color: _blue,
          ),
        ),
        title: Text(
          place.name,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          '${place.description}\n~${_money(place.estimatedCost)}đ',
        ),
      ),
    );
  }

  Widget _buildRestaurantCard(AiRestaurant restaurant) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFFFF7ED),
          child: Icon(
            Icons.restaurant,
            color: Color(0xFFD97706),
          ),
        ),
        title: Text(
          restaurant.name,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          '${restaurant.description}\n~${_money(restaurant.estimatedCost)}đ/người',
        ),
      ),
    );
  }

  Widget _buildBudgetCard(AiBudget budget) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _budgetRow('Khách sạn', budget.hotel),
            _budgetRow('Ăn uống', budget.food),
            _budgetRow('Di chuyển', budget.transport),
            _budgetRow('Tham quan', budget.activities),
            _budgetRow('Khác', budget.other),
            const Divider(),
            _budgetRow(
              'Tổng cộng',
              budget.total,
              bold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _budgetRow(
    String label,
    int value, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight:
                    bold ? FontWeight.w900 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${_money(value)}đ',
            style: TextStyle(
              fontWeight:
                  bold ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

