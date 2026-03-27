import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class NotificationHistoryService {
  static const String _keyDate = 'notification_history_date';
  static const String _keyItems = 'notification_history_items';

  static Future<void> _resetIfNeeded(SharedPreferences store) async {
    final today = _todayKey();
    final savedDate = store.getString(_keyDate);
    if (savedDate == today) return;

    await store.setString(_keyDate, today);
    await store.setString(_keyItems, jsonEncode(<Map<String, dynamic>>[]));
  }

  static Future<void> recordNotification({
    required String title,
    required String body,
  }) async {
    final store = await SharedPreferences.getInstance();
    await _resetIfNeeded(store);

    final items = _decodeItems(store);
    items.insert(0, {
      'title': title,
      'body': body,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'isRead': false,
    });

    await store.setString(_keyItems, jsonEncode(items));
  }

  static Future<List<Map<String, dynamic>>> loadTodayNotifications() async {
    final store = await SharedPreferences.getInstance();
    await _resetIfNeeded(store);
    return _decodeItems(store);
  }

  static Future<int> loadUnreadCount() async {
    final items = await loadTodayNotifications();
    return items.where((item) => item['isRead'] != true).length;
  }

  static Future<void> markAllAsRead() async {
    final store = await SharedPreferences.getInstance();
    await _resetIfNeeded(store);

    final items = _decodeItems(
      store,
    ).map((item) => {...item, 'isRead': true}).toList();
    await store.setString(_keyItems, jsonEncode(items));
  }

  static List<Map<String, dynamic>> _decodeItems(SharedPreferences store) {
    final raw = store.getString(_keyItems);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  static String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }
}
