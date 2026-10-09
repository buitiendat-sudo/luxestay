import 'package:flutter_test/flutter_test.dart';
import 'package:luxestay/screens/admin/admin_operations_screen.dart';

void main() {
  group('booking lifecycle status helpers', () {
    test('check-in transitions are consistent with the admin workflow', () {
      expect(checkInStatusTransition('pending'), 'confirmed');
      expect(checkInStatusTransition('waiting'), 'confirmed');
      expect(checkInStatusTransition('confirmed'), 'checked_in');
    });

    test('check-out transitions complete the stay lifecycle', () {
      expect(checkOutStatusTransition('checked_in'), 'checked_out');
      expect(checkOutStatusTransition('checked_out'), 'completed');
      expect(checkOutStatusTransition('completed'), 'completed');
    });
  });
}
