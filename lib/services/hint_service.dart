import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:numbering/utils/kst_clock.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HintService extends GetxService {
  static const String _keyHints = 'user_hint_count';
  static const String _keyLastAttendanceDate = 'hint_last_attendance_date';
  static const int initialHints = 20;
  static const int dailyBonus = 3;

  late SharedPreferences _prefs;
  SupabaseClient? _supabase;
  StreamSubscription<AuthState>? _authSubscription;

  final RxInt hints = initialHints.obs;
  final RxBool justReceivedAttendanceBonus = false.obs;

  Future<HintService> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadGuestState();
    return this;
  }

  Future<void> connect(SupabaseClient? supabase) async {
    await _authSubscription?.cancel();
    _supabase = supabase;
    if (supabase == null) return;

    await _syncForCurrentSession();
    _authSubscription = supabase.auth.onAuthStateChange.listen((_) {
      unawaited(_syncForCurrentSession());
    });
  }

  Future<void> _syncForCurrentSession() async {
    final client = _supabase;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      await _loadGuestState();
      return;
    }

    try {
      final localCount = _prefs.getInt(_keyHints) ?? initialHints;
      final localDate = _prefs.getString(_keyLastAttendanceDate);
      final response = await client.rpc(
        'sync_my_numbering_hints',
        params: <String, Object?>{
          'p_local_hint_count': localCount,
          'p_local_last_attendance_date': localDate,
        },
      );
      if (client.auth.currentUser?.id != user.id) return;

      final state = _asMap(response);
      hints.value = _asInt(state['hint_count']) ?? initialHints;
      await _cacheCloudCount(user.id, hints.value);
      if (state['attendance_awarded'] == true) {
        justReceivedAttendanceBonus.value = true;
      }
    } catch (error, stackTrace) {
      debugPrint('Hint balance sync failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      hints.value = _prefs.getInt(_cloudHintKey(user.id)) ?? hints.value;
    }
  }

  Future<void> _loadGuestState() async {
    if (!_prefs.containsKey(_keyHints)) {
      await _prefs.setInt(_keyHints, initialHints);
      await _prefs.setString(
        _keyLastAttendanceDate,
        KstClock.currentDateKey(),
      );
      hints.value = initialHints;
      return;
    }

    hints.value = _prefs.getInt(_keyHints) ?? initialHints;
    await checkDailyAttendance();
  }

  Future<void> checkDailyAttendance() async {
    final client = _supabase;
    final user = client?.auth.currentUser;
    if (client != null && user != null) {
      await _syncForCurrentSession();
      return;
    }

    final todayStr = KstClock.currentDateKey();
    final lastDate = _prefs.getString(_keyLastAttendanceDate);
    if (lastDate == todayStr) return;

    final newCount = hints.value + dailyBonus;
    hints.value = newCount;
    await _prefs.setInt(_keyHints, newCount);
    await _prefs.setString(_keyLastAttendanceDate, todayStr);
    justReceivedAttendanceBonus.value = true;
  }

  bool get hasHints => hints.value > 0;

  Future<bool> useHint() async {
    final client = _supabase;
    final user = client?.auth.currentUser;
    if (client != null && user != null) {
      try {
        final response = await client.rpc('consume_my_numbering_hint');
        final state = _asMap(response);
        final used = state['used'] == true;
        hints.value = _asInt(state['hint_count']) ?? hints.value;
        await _cacheCloudCount(user.id, hints.value);
        return used;
      } catch (error) {
        debugPrint('Hint consumption failed: $error');
        return false;
      }
    }

    if (hints.value <= 0) return false;
    hints.value -= 1;
    await _prefs.setInt(_keyHints, hints.value);
    return true;
  }

  Future<void> addHints(int amount) async {
    if (amount <= 0) return;
    final client = _supabase;
    final user = client?.auth.currentUser;
    if (client != null && user != null) {
      // Authenticated grants must originate from a trusted server-side reward
      // flow. Refresh the authoritative balance instead of exposing a client
      // RPC that could mint hints repeatedly.
      await _syncForCurrentSession();
      return;
    }

    hints.value += amount;
    await _prefs.setInt(_keyHints, hints.value);
  }

  Future<void> refreshFromServer() => _syncForCurrentSession();

  Future<void> applyVerifiedBalance(int count) async {
    final client = _supabase;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return;
    hints.value = count.clamp(0, 1000000);
    await _cacheCloudCount(user.id, hints.value);
  }

  Future<void> _cacheCloudCount(String userId, int count) {
    return _prefs.setInt(_cloudHintKey(userId), count);
  }

  String _cloudHintKey(String userId) => '$_keyHints:$userId';

  @override
  void onClose() {
    _authSubscription?.cancel();
    super.onClose();
  }
}

Map<String, Object?> _asMap(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const {};
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
