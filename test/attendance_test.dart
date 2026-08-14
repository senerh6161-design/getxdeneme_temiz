import 'package:flutter_test/flutter_test.dart';
import 'package:getxdeneme/app/modules/geofence/controllers/geofence_controller.dart';

void main() {
  group('shouldCountAttendance', () {
    test('ilk kontrol (lastCountedDate null) → sayılmalı', () {
      expect(
        shouldCountAttendance(lastCountedDate: null, todayKey: '2026-08-14'),
        isTrue,
      );
    });

    test('bugün zaten sayılmışsa → tekrar sayılmamalı', () {
      expect(
        shouldCountAttendance(lastCountedDate: '2026-08-14', todayKey: '2026-08-14'),
        isFalse,
      );
    });

    test('farklı bir günse → sayılmalı', () {
      expect(
        shouldCountAttendance(lastCountedDate: '2026-08-13', todayKey: '2026-08-14'),
        isTrue,
      );
    });
  });
}
