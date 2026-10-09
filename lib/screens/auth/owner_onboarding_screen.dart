import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/image_storage_service.dart';

const _ownerAgreementVersion = 'owner-partnership-draft-v1';
const _ownerAgreementText = '''
ĐIỀU KHOẢN HỢP TÁC CHỦ KHÁCH SẠN — BẢN MẪU

1. Chủ khách sạn cam kết cung cấp thông tin cơ sở, hạng phòng, giá và tình
trạng phòng chính xác; chủ động cập nhật khi có thay đổi.

2. Chủ khách sạn chịu trách nhiệm về chất lượng lưu trú, an toàn, dịch vụ và
việc thực hiện các đặt phòng đã xác nhận với khách.

3. Chủ khách sạn chỉ sử dụng dữ liệu khách hàng để xử lý đặt phòng và chăm sóc
dịch vụ; không chia sẻ hoặc sử dụng sai mục đích.

4. LuxeStay có thể tạm ẩn cơ sở khi phát hiện thông tin sai lệch, khiếu nại
nghiêm trọng hoặc dấu hiệu vi phạm chính sách; các bên trao đổi để xử lý trước
khi chấm dứt hợp tác.

5. Phí dịch vụ, chu kỳ đối soát, nghĩa vụ thuế, bồi thường và các điều khoản
pháp lý khác cần được thống nhất trong hợp đồng chính thức trước khi vận hành
thương mại.

Đây là nội dung mẫu để thử quy trình ký điện tử trong ứng dụng, không thay thế
hợp đồng pháp lý chính thức. Vui lòng cập nhật nội dung đã được phê duyệt trước
khi đưa vào sử dụng thật.
''';

const _navy = Color(0xFF0F172A);
const _gold = Color(0xFFD97706);

class OwnerOnboardingScreen extends StatefulWidget {
  const OwnerOnboardingScreen({super.key});

  @override
  State<OwnerOnboardingScreen> createState() => _OwnerOnboardingScreenState();
}

class _OwnerOnboardingScreenState extends State<OwnerOnboardingScreen> {
  final _hotelFormKey = GlobalKey<FormState>();
  final _propertyNameController = TextEditingController();
  final _propertyLocationController = TextEditingController();
  final _propertyAddressController = TextEditingController();
  final _propertyDescriptionController = TextEditingController();
  final _propertyPhoneController = TextEditingController();
  final _signedNameController = TextEditingController();
  final _imagePicker = ImagePicker();

  int _step = 0;
  bool _acceptedTerms = false;
  bool _isUploadingImage = false;
  String? _onboardingError;
  XFile? _propertyImage;
  Uint8List? _propertyImageBytes;

  @override
  void initState() {
    super.initState();
    _signedNameController.text =
        context.read<AuthProvider>().user?.displayName?.trim() ?? '';
  }

  @override
  void dispose() {
    _propertyNameController.dispose();
    _propertyLocationController.dispose();
    _propertyAddressController.dispose();
    _propertyDescriptionController.dispose();
    _propertyPhoneController.dispose();
    _signedNameController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    final auth = context.read<AuthProvider>();
    setState(() {
      _isUploadingImage = true;
      _onboardingError = null;
    });
    var imageUrl = '';
    try {
      if (_propertyImage case final image?) {
        imageUrl = await context
            .read<ImageStorageService>()
            .uploadOwnerPropertyImage(ownerId: auth.user!.uid, image: image);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isUploadingImage = false;
        _onboardingError = 'Không thể tải ảnh khách sạn lên: $error';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải ảnh khách sạn lên: $error')),
      );
      return;
    }
    if (!mounted) return;

    final success = await auth.completeOwnerOnboarding(
      propertyName: _propertyNameController.text,
      propertyLocation: _propertyLocationController.text,
      propertyAddress: _propertyAddressController.text,
      propertyDescription: _propertyDescriptionController.text,
      propertyPhone: _propertyPhoneController.text,
      propertyImageUrl: imageUrl,
      signedName: _signedNameController.text,
      agreementVersion: _ownerAgreementVersion,
      agreementText: _ownerAgreementText,
    );
    if (mounted) {
      setState(() {
        _isUploadingImage = false;
        if (!success) {
          _onboardingError = auth.errorMessage ?? 'Không thể hoàn tất hồ sơ.';
        }
      });
    }
    if (!mounted || success) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(auth.errorMessage ?? 'Không thể hoàn tất hồ sơ.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F3),
      appBar: AppBar(
        title: Text(_step == 0 ? 'Thông tin khách sạn' : 'Điều khoản hợp tác'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton.icon(
            onPressed: auth.isLoading ? null : auth.logout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Đăng xuất'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      _StepIndicator(
                        number: 1,
                        label: 'Thông tin cơ sở',
                        active: _step == 0,
                        complete: _step > 0,
                      ),
                      const Expanded(child: Divider(height: 1)),
                      _StepIndicator(
                        number: 2,
                        label: 'Ký điều khoản',
                        active: _step == 1,
                        complete: false,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _step == 0
                        ? _buildPropertyForm()
                        : _buildAgreement(auth),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyForm() {
    return Form(
      key: _hotelFormKey,
      child: ListView(
        key: const ValueKey('owner-property-form'),
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.apartment_rounded, size: 42, color: _gold),
          const SizedBox(height: 12),
          const Text(
            'Hoàn tất hồ sơ khách sạn',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _navy,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tài khoản chủ khách sạn đã được tạo. Hãy nhập thông tin cơ sở để tiếp tục đến bước xem và ký điều khoản hợp tác.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), height: 1.5),
          ),
          const SizedBox(height: 24),
          _input(
            controller: _propertyNameController,
            label: 'Tên khách sạn',
            hint: 'Ví dụ: LuxeStay Riverside',
            icon: Icons.apartment_outlined,
          ),
          const SizedBox(height: 14),
          _input(
            controller: _propertyLocationController,
            label: 'Tỉnh / thành phố',
            hint: 'Ví dụ: Đà Nẵng',
            icon: Icons.location_city_outlined,
          ),
          const SizedBox(height: 14),
          _input(
            controller: _propertyAddressController,
            label: 'Địa chỉ khách sạn',
            hint: 'Số nhà, đường, phường/xã',
            icon: Icons.place_outlined,
            maxLines: 2,
          ),
          const SizedBox(height: 14),
          _input(
            controller: _propertyPhoneController,
            label: 'Số điện thoại khách sạn',
            hint: 'Ví dụ: 0236 123 4567',
            icon: Icons.phone_outlined,
          ),
          const SizedBox(height: 14),
          _input(
            controller: _propertyDescriptionController,
            label: 'Mô tả khách sạn',
            hint: 'Giới thiệu ngắn về cơ sở lưu trú',
            icon: Icons.notes_rounded,
            maxLines: 3,
            isRequired: false,
          ),
          const SizedBox(height: 14),
          _propertyImagePicker(),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              if (_hotelFormKey.currentState!.validate()) {
                setState(() => _step = 1);
              }
            },
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Xem điều khoản hợp tác'),
            style: _buttonStyle,
          ),
        ],
      ),
    );
  }

  Widget _propertyImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ảnh khách sạn',
          style: TextStyle(color: _navy, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (_propertyImageBytes case final bytes?)
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.memory(
              bytes,
              height: 190,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          )
        else
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  color: _gold,
                  size: 34,
                ),
                SizedBox(height: 6),
                Text('Chưa chọn ảnh'),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _isUploadingImage ? null : _pickPropertyImage,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(_propertyImage == null ? 'Chọn ảnh' : 'Đổi ảnh'),
            ),
            if (_propertyImage != null) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _isUploadingImage
                    ? null
                    : () => setState(() {
                        _propertyImage = null;
                        _propertyImageBytes = null;
                      }),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Xóa'),
              ),
            ],
          ],
        ),
        const Text(
          'Có thể bỏ qua, dung lượng tối đa 10 MB.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
        ),
      ],
    );
  }

  Future<void> _pickPropertyImage() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final bytes = await image.readAsBytes();
    if (bytes.length > 10 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ảnh khách sạn phải nhỏ hơn 10 MB.')),
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      _propertyImage = image;
      _propertyImageBytes = bytes;
    });
  }

  Widget _buildAgreement(AuthProvider auth) {
    final isSubmitting = _isUploadingImage || auth.isLoading;
    return ListView(
      key: const ValueKey('owner-agreement'),
      padding: const EdgeInsets.all(20),
      children: [
        const Icon(Icons.assignment_outlined, size: 40, color: _gold),
        const SizedBox(height: 12),
        const Text(
          'Điều khoản hợp tác',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _navy,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Áp dụng cho ${_propertyNameController.text.trim()}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const SelectableText(
            _ownerAgreementText,
            style: TextStyle(color: _navy, height: 1.55),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _signedNameController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Họ tên người ký',
            hintText: 'Nhập họ tên để xác nhận chữ ký điện tử',
            prefixIcon: const Icon(Icons.draw_outlined),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onChanged: (_) => setState(() {}),
        ),
        CheckboxListTile(
          value: _acceptedTerms,
          onChanged: isSubmitting
              ? null
              : (value) => setState(() {
                  _acceptedTerms = value ?? false;
                  _onboardingError = null;
                }),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text(
            'Tôi đã đọc, hiểu và đồng ý với điều khoản hợp tác mẫu ở trên.',
            style: TextStyle(color: _navy, fontSize: 14, height: 1.4),
          ),
        ),
        const SizedBox(height: 8),
        if (_onboardingError case final error?) ...[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Text(
              error,
              style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12),
            ),
          ),
        ],
        Row(
          children: [
            OutlinedButton(
              onPressed: isSubmitting
                  ? null
                  : () => setState(() {
                      _step = 0;
                      _onboardingError = null;
                    }),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(100, 52),
                foregroundColor: _navy,
              ),
              child: const Text('Quay lại'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed:
                    isSubmitting ||
                        !_acceptedTerms ||
                        _signedNameController.text.trim().isEmpty
                    ? null
                    : _finishOnboarding,
                icon: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.draw_rounded),
                label: Text(
                  isSubmitting ? 'Đang lưu hồ sơ...' : 'Ký và hoàn tất',
                ),
                style: _buttonStyle,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      maxLines: maxLines,
      validator: (value) =>
          isRequired && (value == null || value.trim().isEmpty)
          ? 'Vui lòng nhập $label'.toLowerCase()
          : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

const _buttonStyle = ButtonStyle(
  minimumSize: WidgetStatePropertyAll(Size.fromHeight(52)),
  backgroundColor: WidgetStatePropertyAll(_navy),
  foregroundColor: WidgetStatePropertyAll(Colors.white),
);

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.number,
    required this.label,
    required this.active,
    required this.complete,
  });

  final int number;
  final String label;
  final bool active;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final color = active || complete ? _gold : const Color(0xFF94A3B8);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: color,
            child: complete
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '$number',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: active ? _navy : const Color(0xFF64748B),
              fontSize: 12,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
