import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiEndpoints {
  // Production endpoints from DATA_CONTRACT.md
  static const String rescuePlan = 'https://rescueplan-v4gtcfan5q-uc.a.run.app';
  static const String dailyInsight = 'https://dailyinsight-v4gtcfan5q-uc.a.run.app';
  static const String syncCalendar = 'https://synccalendar-v4gtcfan5q-uc.a.run.app';
  static const String oauthCallback = 'https://oauthcallback-v4gtcfan5q-uc.a.run.app';
  static const String sleepHistory = 'https://sleephistory-v4gtcfan5q-uc.a.run.app';
  static const String scheduleItemCreate = 'https://scheduleitemcreate-v4gtcfan5q-uc.a.run.app';
  static const String scheduleItemList = 'https://scheduleitemlist-v4gtcfan5q-uc.a.run.app';
  static const String goalItemCreate = 'https://goalitemcreate-v4gtcfan5q-uc.a.run.app';
  static const String goalItemList = 'https://goalitemlist-v4gtcfan5q-uc.a.run.app';
  static const String generateSchedulePlan = 'https://generatescheduleplan-v4gtcfan5q-uc.a.run.app';
}

class ApiClient {
  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
  };

  static Future<Map<String, dynamic>> post(String url, Map<String, dynamic> body) async {
    final uri = Uri.parse(url);
    final res = await http.post(uri, headers: _jsonHeaders, body: jsonEncode(body));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }

    throw ApiException(res.statusCode, res.body);
  }

  // Convenience wrappers
  static Future<Map<String, dynamic>> postRescuePlan(Map<String, dynamic> body) async {
    return post(ApiEndpoints.rescuePlan, body);
  }

  static Future<Map<String, dynamic>> postDailyInsight(Map<String, dynamic> body) async {
    return post(ApiEndpoints.dailyInsight, body);
  }

  static Future<Map<String, dynamic>> postSyncCalendar(Map<String, dynamic> body) async {
    return post(ApiEndpoints.syncCalendar, body);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);

  @override
  String toString() => 'ApiException: HTTP $statusCode - $body';
}
