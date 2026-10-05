import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _destinationController = TextEditingController();

  final TextEditingController _budgetController = TextEditingController();

  final TextEditingController _chatController = TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  int _days = 3;
  int _guests = 2;

  bool _isGenerating = false;
  bool _isChatLoading = false;

  AiTravelPlan? _plan;

  String? _errorMessage;

  final NumberFormat _currencyFormat = NumberFormat('#,###', 'vi_VN');

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _destinationController.dispose();
    _budgetController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  // ============================================================
  // CURRENCY
  // ============================================================

  String _formatMoney(int value) {
    return '${_currencyFormat.format(value)} đ';
  }

  Future<void> _openHotelBooking(
    AiHotelRecommendation recommendation,
  ) async {
    try {
      final properties = await context
          .read<FirestoreService>()
          .getProperties()
          .first;

      Property? property;
      for (final candidate in properties) {
        if (candidate.id == recommendation.propertyId) {
          property = candidate;
          break;
        }
      }

      if (!mounted) return;

      if (property == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Khách sạn được đề xuất hiện không còn khả dụng.'),
          ),
        );
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PropertyDetailScreen(property: property!),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể mở trang đặt phòng: $error'),
        ),
      );
    }
  }

  String _buildShareText(AiTravelPlan plan) {
    final text = StringBuffer(
      'LỊCH TRÌNH DU LỊCH ${plan.destination.toUpperCase()}\n',
    );

    if (plan.summary.isNotEmpty) {
      text.writeln(plan.summary);
    }

    if (plan.hotels.isNotEmpty) {
      text.writeln('\nKHÁCH SẠN LUXESTAY GỢI Ý');
      for (final hotel in plan.hotels) {
        text.writeln(
          '• Phòng ${hotel.roomId}: ${hotel.reason} '
          '(${_formatMoney(hotel.estimatedTotal)})',
        );
      }
    }

    text.writeln('\nLỊCH TRÌNH');
    for (final day in plan.itinerary) {
      text.writeln('Ngày ${day.day}: ${day.title}');

      if (day.schedule.isNotEmpty) {
        for (final item in day.schedule) {
          final place = item.place.isEmpty ? '' : ' · ${item.place}';
          text.writeln('• ${item.time} — ${item.activity}$place');
        }
      } else {
        for (final activity in day.activities) {
          text.writeln('• $activity');
        }
      }
    }

    text.writeln('\nNgân sách dự kiến: ${_formatMoney(plan.budget.total)}');
    text.writeln('\nCùng mình xem và lên kế hoạch cho chuyến đi này nhé!');

    return text.toString();
  }

  Future<void> _copyPlanToClipboard(AiTravelPlan plan) async {
    await Clipboard.setData(ClipboardData(text: _buildShareText(plan)));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép lịch trình. Hãy dán vào Zalo hoặc Messenger.'),
      ),
    );
  }

  Future<void> _launchShareUri(Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy ứng dụng phù hợp để chia sẻ.')),
      );
    }
  }

  void _showSharePlanSheet(AiTravelPlan plan) {
    final shareText = _buildShareText(plan);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chia sẻ lịch trình',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Mời bạn bè cùng xem và thảo luận về chuyến đi.',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.copy_all_outlined),
                  title: const Text('Sao chép lịch trình'),
                  subtitle: const Text('Dán vào Zalo, Messenger hoặc mạng xã hội'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _copyPlanToClipboard(plan);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Gửi qua email'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _launchShareUri(
                      Uri(
                        scheme: 'mailto',
                        queryParameters: {
                          'subject': 'Lịch trình du lịch ${plan.destination}',
                          'body': shareText,
                        },
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.sms_outlined),
                  title: const Text('Gửi qua tin nhắn'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _launchShareUri(
                      Uri(
                        scheme: 'sms',
                        queryParameters: {'body': shareText},
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // GENERATE PLAN
  // ============================================================

  Future<void> _generatePlan() async {
    FocusScope.of(context).unfocus();

    final destination = _destinationController.text.trim();

    final budgetText = _budgetController.text
        .replaceAll('.', '')
        .replaceAll(',', '')
        .trim();

    final budget = int.tryParse(budgetText) ?? 0;

    if (destination.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập điểm đến.';
      });
      return;
    }

    if (budget <= 0) {
      setState(() {
        _errorMessage = 'Vui lòng nhập ngân sách hợp lệ.';
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final firestore = context.read<FirestoreService>();

      final service = AiTravelService(firestore);

      final plan = await service.generateTravelPlan(
        destination: destination,
        days: _days,
        guests: _guests,
        budget: budget,
      );

      if (!mounted) return;

      setState(() {
        _plan = plan;
        _isGenerating = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isGenerating = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ============================================================
  // CHAT - REVISE PLAN
  // ============================================================

  Future<void> _sendChatMessage() async {
    final message = _chatController.text.trim();

    if (message.isEmpty) {
      return;
    }

    if (_plan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy tạo kế hoạch trước khi chỉnh sửa.')),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isChatLoading = true;
    });

    try {
      final firestore = context.read<FirestoreService>();

      final service = AiTravelService(firestore);

      final updatedPlan = await service.reviseTravelPlan(
        currentPlan: _plan!,
        userRequest: message,
      );

      if (!mounted) return;

      setState(() {
        _plan = updatedPlan;
        _chatController.clear();
        _isChatLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã cập nhật kế hoạch.')));
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isChatLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  // ============================================================
  // CHAT SUGGESTION
  // ============================================================

  void _useChatSuggestion(String text) {
    setState(() {
      _chatController.text = text;
      _chatController.selection = TextSelection.fromPosition(
        TextPosition(offset: _chatController.text.length),
      );
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),

      appBar: AppBar(
        title: const Text('AI Travel Planner'),
        backgroundColor: const Color(0xFFF7F8FC),
        elevation: 0,
        actions: [
          if (_plan != null)
            IconButton(
              tooltip: 'Chia sẻ lịch trình',
              onPressed: () => _showSharePlanSheet(_plan!),
              icon: const Icon(Icons.share_outlined),
            ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(height: 20),

              _buildInputCard(),

              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                _buildError(),
              ],

              if (_isGenerating) ...[
                const SizedBox(height: 20),
                _buildLoading(),
              ],

              if (_plan != null && !_isGenerating) ...[
                const SizedBox(height: 24),
                _buildPlan(_plan!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Text(
                'LUXESTAY AI',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const Text(
            'Lập kế hoạch\nchuyến đi của bạn',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'Nhập điểm đến, số ngày, số khách '
            'và ngân sách. AI sẽ tạo lịch trình '
            'chi tiết kèm khách sạn LuxeStay.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INPUT CARD
  // ============================================================

  Widget _buildInputCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin chuyến đi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: 16),

          // DESTINATION
          _buildTextField(
            controller: _destinationController,
            label: 'Điểm đến',
            hint: 'Ví dụ: Đà Nẵng',
            icon: Icons.location_on_outlined,
          ),

          const SizedBox(height: 14),

          // DAYS + GUESTS
          Row(
            children: [
              Expanded(
                child: _buildNumberSelector(
                  label: 'Số ngày',
                  value: _days,
                  min: 1,
                  max: 14,
                  icon: Icons.calendar_month_outlined,
                  onChanged: (value) {
                    setState(() {
                      _days = value;
                    });
                  },
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _buildNumberSelector(
                  label: 'Số khách',
                  value: _guests,
                  min: 1,
                  max: 20,
                  icon: Icons.people_outline,
                  onChanged: (value) {
                    setState(() {
                      _guests = value;
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // BUDGET
          _buildTextField(
            controller: _budgetController,
            label: 'Ngân sách',
            hint: 'Ví dụ: 10000000',
            icon: Icons.account_balance_wallet_outlined,
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generatePlan,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                _isGenerating ? 'Đang tạo kế hoạch...' : 'Tạo kế hoạch với AI',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),

        const SizedBox(height: 7),

        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            filled: true,
            fillColor: const Color(0xFFF7F8FC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: Color(0xFF0F172A)),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // NUMBER SELECTOR
  // ============================================================

  Widget _buildNumberSelector({
    required String label,
    required int value,
    required int min,
    required int max,
    required IconData icon,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          Row(
            children: [
              _smallButton(
                icon: Icons.remove,
                onTap: value > min
                    ? () {
                        onChanged(value - 1);
                      }
                    : null,
              ),

              Expanded(
                child: Center(
                  child: Text(
                    '$value',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              _smallButton(
                icon: Icons.add,
                onTap: value < max
                    ? () {
                        onChanged(value + 1);
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SMALL BUTTON
  // ============================================================

  Widget _smallButton({required IconData icon, required VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Icon(icon, size: 17),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 14),
          Text(
            'AI đang xây dựng kế hoạch...',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 5),
          Text(
            'Đang tìm khách sạn và phòng phù hợp trong LuxeStay.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FULL PLAN
  // ============================================================

  Widget _buildPlan(AiTravelPlan plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPlanHeader(plan),

        const SizedBox(height: 22),

        _sectionTitle(Icons.hotel_outlined, 'Khách sạn AI đề xuất'),

        const SizedBox(height: 10),

        _buildHotels(plan),

        const SizedBox(height: 22),

        _sectionTitle(Icons.calendar_month_outlined, 'Lịch trình'),

        const SizedBox(height: 10),

        ...plan.itinerary.map(_buildDayPlan),

        const SizedBox(height: 8),

        _sectionTitle(
          Icons.account_balance_wallet_outlined,
          'Ngân sách dự kiến',
        ),

        const SizedBox(height: 10),

        _buildBudget(plan),

        const SizedBox(height: 22),

        _sectionTitle(Icons.restaurant_outlined, 'Nhà hàng gợi ý'),

        const SizedBox(height: 10),

        _buildRestaurants(plan),

        const SizedBox(height: 22),

        _sectionTitle(Icons.place_outlined, 'Địa điểm nên ghé'),

        const SizedBox(height: 10),

        _buildPlaces(plan),

        const SizedBox(height: 24),

        _buildAiChatBox(),
      ],
    );
  }

  // ============================================================
  // PLAN HEADER
  // ============================================================

  Widget _buildPlanHeader(AiTravelPlan plan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Color(0xFFFBBF24),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'KẾ HOẠCH CỦA BẠN',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            plan.destination,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            plan.summary,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 13,
              height: 1.55,
            ),
          ),

          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: () => _showSharePlanSheet(plan),
            icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
            label: const Text('Mời bạn bè cùng xem'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 21, color: const Color(0xFF0F172A)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  // ============================================================
  // HOTELS
  // ============================================================

  Widget _buildHotels(AiTravelPlan plan) {
    if (plan.hotels.isEmpty) {
      return _emptyCard('AI chưa tìm thấy phòng phù hợp.');
    }

    return Column(
      children: plan.hotels.map((hotel) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.hotel, color: Color(0xFFD97706)),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'LuxeStay Hotel',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Phòng: ${hotel.roomId}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Text(
                    _formatMoney(hotel.estimatedTotal),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                hotel.reason,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: Color(0xFF475569),
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openHotelBooking(hotel),
                  icon: const Icon(Icons.calendar_month_outlined, size: 18),
                  label: const Text('Xem phòng và đặt ngay'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFF0F172A)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // DAY PLAN
  // ============================================================

  Widget _buildDayPlan(AiDayPlan day) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    '${day.day}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    'NGÀY ${day.day} — ${day.title}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          _buildScheduleTable(day),
        ],
      ),
    );
  }

  // ============================================================
  // SCHEDULE TABLE
  // ============================================================

  Widget _buildScheduleTable(AiDayPlan day) {
    if (day.schedule.isEmpty) {
      return _buildActivitiesFallback(day);
    }

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFD20A0A)),

          headingTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),

          dataTextStyle: const TextStyle(
            color: Color(0xFF172033),
            fontSize: 12,
            height: 1.35,
          ),

          columnSpacing: 18,
          horizontalMargin: 12,

          columns: const [
            DataColumn(label: Text('Thời gian')),
            DataColumn(label: Text('Hoạt động')),
            DataColumn(label: Text('Địa điểm')),
            DataColumn(label: Text('Phương tiện')),
            DataColumn(label: Text('Chi phí')),
            DataColumn(label: Text('Ghi chú')),
          ],

          rows: day.schedule.map((item) {
            return DataRow(
              cells: [
                DataCell(SizedBox(width: 80, child: Text(item.time))),

                DataCell(SizedBox(width: 125, child: Text(item.activity))),

                DataCell(SizedBox(width: 125, child: Text(item.place))),

                DataCell(
                  SizedBox(
                    width: 90,
                    child: Text(item.transport.isEmpty ? '—' : item.transport),
                  ),
                ),

                DataCell(
                  SizedBox(
                    width: 85,
                    child: Text(item.cost <= 0 ? '—' : _formatMoney(item.cost)),
                  ),
                ),

                DataCell(
                  SizedBox(
                    width: 155,
                    child: Text(item.note.isEmpty ? '—' : item.note),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ============================================================
  // FALLBACK ACTIVITIES
  // ============================================================

  Widget _buildActivitiesFallback(AiDayPlan day) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: day.activities.map((activity) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.circle, size: 7, color: Color(0xFFD20A0A)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    activity,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // BUDGET
  // ============================================================

  Widget _buildBudget(AiTravelPlan plan) {
    final budget = plan.budget;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _budgetRow('Khách sạn', budget.hotel, Icons.hotel_outlined),
          _budgetRow('Ăn uống', budget.food, Icons.restaurant_outlined),
          _budgetRow(
            'Di chuyển',
            budget.transport,
            Icons.directions_car_outlined,
          ),
          _budgetRow(
            'Hoạt động',
            budget.activities,
            Icons.local_activity_outlined,
          ),
          _budgetRow('Khác', budget.other, Icons.more_horiz),

          const Divider(height: 24),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'TỔNG DỰ KIẾN',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
              Text(
                _formatMoney(budget.total),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFD97706),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUDGET ROW
  // ============================================================

  Widget _budgetRow(String title, int value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 19, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 13))),
          Text(
            _formatMoney(value),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESTAURANTS
  // ============================================================

  Widget _buildRestaurants(AiTravelPlan plan) {
    if (plan.restaurants.isEmpty) {
      return _emptyCard('Chưa có nhà hàng được đề xuất.');
    }

    return Column(
      children: plan.restaurants.map((restaurant) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.restaurant, color: Color(0xFFD97706)),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      restaurant.description,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      _formatMoney(restaurant.estimatedCost),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // PLACES
  // ============================================================

  Widget _buildPlaces(AiTravelPlan plan) {
    if (plan.places.isEmpty) {
      return _emptyCard('Chưa có địa điểm được đề xuất.');
    }

    return Column(
      children: plan.places.map((place) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.place, color: Color(0xFF2563EB)),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      place.description,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      _formatMoney(place.estimatedCost),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // AI CHAT BOX
  // ============================================================

  Widget _buildAiChatBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trợ lý AI LuxeStay',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Yêu cầu AI chỉnh sửa kế hoạch',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _chatController,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) {
              if (!_isChatLoading) {
                _sendChatMessage();
              }
            },
            decoration: InputDecoration(
              hintText: 'Ví dụ: Đổi ngày 2 thành đi Bà Nà Hills...',
              filled: true,
              fillColor: const Color(0xFFF7F8FC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(14),
              suffixIcon: IconButton(
                onPressed: _isChatLoading ? null : _sendChatMessage,
                icon: _isChatLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chatSuggestion('Đổi lịch ngày 2'),
              _chatSuggestion('Giảm chi phí'),
              _chatSuggestion('Thêm địa điểm tham quan'),
              _chatSuggestion('Thêm nhà hàng'),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CHAT SUGGESTION
  // ============================================================

  Widget _chatSuggestion(String text) {
    return InkWell(
      onTap: () {
        _useChatSuggestion(text);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY CARD
  // ============================================================

  Widget _emptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.grey, fontSize: 13),
      ),
    );
  }
}
