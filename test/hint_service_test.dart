import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:numbering/services/hint_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(Get.reset);

  test('starts with 20 initial hints on fresh install', () async {
    final service = await HintService().init();
    expect(service.hints.value, equals(20));
    expect(service.hasHints, isTrue);
  });

  test('deducts hints when used', () async {
    final service = await HintService().init();
    expect(service.hints.value, equals(20));

    final success = await service.useHint();
    expect(success, isTrue);
    expect(service.hints.value, equals(19));
  });

  test('cannot use hint when count is 0', () async {
    final service = await HintService().init();
    service.hints.value = 0;

    final success = await service.useHint();
    expect(success, isFalse);
    expect(service.hints.value, equals(0));
    expect(service.hasHints, isFalse);
  });

  test('adds 3 hints on daily attendance check on a new day', () async {
    final service = await HintService().init();
    expect(service.hints.value, equals(20));

    // Simulate previous attendance was yesterday
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hint_last_attendance_date', '2020-01-01');
    service.justReceivedAttendanceBonus.value = false;

    await service.checkDailyAttendance();
    expect(service.hints.value, equals(23));
    expect(service.justReceivedAttendanceBonus.value, isTrue);
  });
}
