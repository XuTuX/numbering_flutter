import 'package:get/get.dart';
import 'package:numbering/utils/kst_clock.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HintService extends GetxService {
  static const String _keyHints = 'user_hint_count';
  static const String _keyLastAttendanceDate = 'hint_last_attendance_date';
  static const int initialHints = 20;
  static const int dailyBonus = 3;

  late SharedPreferences _prefs;
  final RxInt hints = initialHints.obs;
  final RxBool justReceivedAttendanceBonus = false.obs;

  Future<HintService> init() async {
    _prefs = await SharedPreferences.getInstance();

    if (!_prefs.containsKey(_keyHints)) {
      await _prefs.setInt(_keyHints, initialHints);
      await _prefs.setString(_keyLastAttendanceDate, KstClock.currentDateKey());
      hints.value = initialHints;
    } else {
      hints.value = _prefs.getInt(_keyHints) ?? initialHints;
      await checkDailyAttendance();
    }

    return this;
  }

  Future<void> checkDailyAttendance() async {
    final todayStr = KstClock.currentDateKey();
    final lastDate = _prefs.getString(_keyLastAttendanceDate);

    if (lastDate != todayStr) {
      final newCount = hints.value + dailyBonus;
      hints.value = newCount;
      await _prefs.setInt(_keyHints, newCount);
      await _prefs.setString(_keyLastAttendanceDate, todayStr);
      justReceivedAttendanceBonus.value = true;
    }
  }

  bool get hasHints => hints.value > 0;

  Future<bool> useHint() async {
    if (hints.value <= 0) return false;
    hints.value -= 1;
    await _prefs.setInt(_keyHints, hints.value);
    return true;
  }

  Future<void> addHints(int amount) async {
    hints.value += amount;
    await _prefs.setInt(_keyHints, hints.value);
  }
}
