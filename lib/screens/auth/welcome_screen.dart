import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.onGetStarted,
  });

  final VoidCallback onGetStarted;

  static const _gold = Color(0xFFFFD129);
  static const _imageUrl =
      'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=1800&q=85';

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              _imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const ColoredBox(
                  color: Color(0xFF18343A),
                  child: Icon(
                    Icons.villa_outlined,
                    color: Colors.white24,
                    size: 100,
                  ),
                );
              },
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x33071215),
                    Color(0x22202A28),
                    Color(0xE600090B),
                  ],
                  stops: [0, 0.42, 1],
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(26, 18, 26, 22),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.hotel_class_rounded,
                              color: _gold,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'LUXESTAY',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.6,
                                  ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: const Color(0xA6192527),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.white24,
                            ),
                          ),
                          child: const Icon(
                            Icons.bed_rounded,
                            color: _gold,
                            size: 38,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'LuxeStay',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'KỲ NGHỈ ĐẸP BẮT ĐẦU TỪ ĐÂY',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                color: _gold,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          'Khám phá những chốn nghỉ dưỡng được tuyển chọn dành riêng cho bạn.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.88),
                                height: 1.5,
                              ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton.icon(
                            onPressed: onGetStarted,
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: const Text('Bắt đầu khám phá'),
                            style: FilledButton.styleFrom(
                              backgroundColor: _gold,
                              foregroundColor: const Color(0xFF171710),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}