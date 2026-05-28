import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:dont_forget_sleep/core/api_client.dart';

class DailyInsightData {
  final String insightTitle;
  final String insightBody;
  final String trendTag;
  final String recommendation;
  final int dataPointsUsed;

  const DailyInsightData({
    required this.insightTitle,
    required this.insightBody,
    required this.trendTag,
    required this.recommendation,
    required this.dataPointsUsed,
  });
}

class DailyInsightService extends ChangeNotifier {
  DailyInsightData? _insight;
  bool _isLoading = false;
  String? _errorCode;

  DailyInsightData? get insight => _insight;
  bool get isLoading => _isLoading;
  String? get errorCode => _errorCode;

  Future<void> fetchTodayInsight() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _insight = null;
      _errorCode = null;
      notifyListeners();
      return;
    }

    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    _isLoading = true;
    _errorCode = null;
    notifyListeners();

    try {
      final response = await ApiClient.postDailyInsight({
        'userId': uid,
        'date': today,
      });

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>?;
        if (data != null) {
          _insight = DailyInsightData(
            insightTitle: data['insightTitle']?.toString() ?? 'Today\'s Sleep Insight',
            insightBody: data['insightBody']?.toString() ?? '',
            trendTag: data['trendTag']?.toString() ?? 'stable',
            recommendation: data['recommendation']?.toString() ?? '',
            dataPointsUsed: (data['dataPointsUsed'] as num?)?.round() ?? 0,
          );
          _errorCode = null;
        } else {
          _insight = null;
          _errorCode = 'EMPTY_DATA';
        }
      } else {
        _insight = null;
        _errorCode = response['code']?.toString() ?? 'UNKNOWN_ERROR';
      }
    } on ApiException catch (e) {
      _insight = null;
      _errorCode = _extractCodeFromBody(e.body) ?? 'API_ERROR';
    } catch (_) {
      _insight = null;
      _errorCode = 'NETWORK_ERROR';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String? _extractCodeFromBody(String body) {
    final match = RegExp(r'"code"\s*:\s*"([A-Z_]+)"').firstMatch(body);
    return match?.group(1);
  }
}

final dailyInsightService = DailyInsightService();
