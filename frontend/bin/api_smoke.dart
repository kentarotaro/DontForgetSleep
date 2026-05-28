import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiEndpoints {
  static const String rescuePlan = 'https://rescueplan-v4gtcfan5q-uc.a.run.app';
  static const String dailyInsight = 'https://dailyinsight-v4gtcfan5q-uc.a.run.app';
  static const String syncCalendar = 'https://synccalendar-v4gtcfan5q-uc.a.run.app';
  static const String sleepHistory = 'https://sleephistory-v4gtcfan5q-uc.a.run.app';
  static const String scheduleItemCreate = 'https://scheduleitemcreate-v4gtcfan5q-uc.a.run.app';
  static const String scheduleItemList = 'https://scheduleitemlist-v4gtcfan5q-uc.a.run.app';
  static const String goalItemCreate = 'https://goalitemcreate-v4gtcfan5q-uc.a.run.app';
  static const String goalItemList = 'https://goalitemlist-v4gtcfan5q-uc.a.run.app';
  static const String generateSchedulePlan = 'https://generatescheduleplan-v4gtcfan5q-uc.a.run.app';
}

Future<void> main(List<String> args) async {
  final withWrite = args.contains('--with-write');
  final userId = _valueAfter(args, '--userId') ?? 'smoke_test_user';
  final now = DateTime.now();
  final date = _valueAfter(args, '--date') ?? _formatDate(now);
  final endDate = _formatDate(now.add(const Duration(days: 7)));

  final checks = <_Check>[
    _Check.post(
      name: 'rescuePlan',
      url: ApiEndpoints.rescuePlan,
      body: {
        'userId': userId,
        'currentDate': date,
        'currentEnergyLevel': 3,
        'currentSleepDebtMinutes': 60,
      },
    ),
    _Check.post(
      name: 'dailyInsight',
      url: ApiEndpoints.dailyInsight,
      body: {
        'userId': userId,
        'date': date,
      },
    ),
    _Check.post(
      name: 'syncCalendar',
      url: ApiEndpoints.syncCalendar,
      body: {
        'userId': userId,
        'dateRange': {'start': date, 'end': endDate},
      },
    ),
    _Check.post(
      name: 'generateSchedulePlan',
      url: ApiEndpoints.generateSchedulePlan,
      body: {
        'userId': userId,
        'date': date,
      },
    ),
    _Check.get(
      name: 'sleepHistory',
      url: ApiEndpoints.sleepHistory,
      query: {'userId': userId, 'days': '7'},
    ),
    _Check.get(
      name: 'scheduleItemList',
      url: ApiEndpoints.scheduleItemList,
      query: {'userId': userId, 'date': date},
    ),
    _Check.get(
      name: 'goalItemList',
      url: ApiEndpoints.goalItemList,
      query: {'userId': userId},
    ),
  ];

  if (withWrite) {
    final token = now.millisecondsSinceEpoch;
    checks.add(
      _Check.post(
        name: 'scheduleItemCreate',
        url: ApiEndpoints.scheduleItemCreate,
        body: {
          'userId': userId,
          'title': 'SmokeCommit-$token',
          'startTime': '${date}T09:00:00Z',
          'endTime': '${date}T10:00:00Z',
          'date': date,
        },
      ),
    );
    checks.add(
      _Check.post(
        name: 'goalItemCreate',
        url: ApiEndpoints.goalItemCreate,
        body: {
          'userId': userId,
          'title': 'SmokeGoal-$token',
          'estimatedMinutes': 30,
          'priority': 'medium',
        },
      ),
    );
  }

  print('Running API smoke checks for userId=$userId date=$date');
  print('Write checks: ${withWrite ? 'ON' : 'OFF'}');

  var passed = 0;
  for (final check in checks) {
    final result = await _runCheck(check);
    if (result.ok) {
      passed++;
    }
    print(result.render());
  }

  print('---');
  print('Passed $passed/${checks.length} checks');
  if (passed != checks.length) {
    print('Some checks failed. Review status/code/message above.');
  }
}

Future<_CheckResult> _runCheck(_Check check) async {
  try {
    http.Response response;
    final uri = Uri.parse(check.url).replace(queryParameters: check.query);

    if (check.method == 'POST') {
      response = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(check.body ?? <String, dynamic>{}),
          )
          .timeout(const Duration(seconds: 25));
    } else {
      response = await http.get(uri).timeout(const Duration(seconds: 25));
    }

    String? code;
    String? message;
    bool? success;
    final bodyText = response.body;

    if (bodyText.trim().startsWith('{')) {
      try {
        final json = jsonDecode(bodyText);
        if (json is Map<String, dynamic>) {
          code = json['code']?.toString();
          message = json['message']?.toString();
          if (json['success'] is bool) {
            success = json['success'] as bool;
          }
        }
      } catch (_) {
        // Ignore parse errors and keep raw body snippet.
      }
    }

    final statusOk = response.statusCode >= 200 && response.statusCode < 500;
    final ok = statusOk && (success != false || code != null || response.statusCode < 300);

    return _CheckResult(
      name: check.name,
      method: check.method,
      statusCode: response.statusCode,
      ok: ok,
      code: code,
      message: message,
      bodyPreview: _preview(bodyText),
    );
  } catch (e) {
    return _CheckResult(
      name: check.name,
      method: check.method,
      statusCode: null,
      ok: false,
      code: 'REQUEST_FAILED',
      message: e.toString(),
      bodyPreview: '',
    );
  }
}

String _preview(String input) {
  final normalized = input.replaceAll('\n', ' ').trim();
  if (normalized.length <= 180) {
    return normalized;
  }
  return '${normalized.substring(0, 180)}...';
}

String? _valueAfter(List<String> args, String flag) {
  final index = args.indexOf(flag);
  if (index == -1 || index + 1 >= args.length) {
    return null;
  }
  return args[index + 1];
}

String _formatDate(DateTime value) {
  return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

class _Check {
  final String name;
  final String method;
  final String url;
  final Map<String, dynamic>? body;
  final Map<String, String>? query;

  const _Check._({
    required this.name,
    required this.method,
    required this.url,
    this.body,
    this.query,
  });

  factory _Check.post({
    required String name,
    required String url,
    required Map<String, dynamic> body,
  }) {
    return _Check._(name: name, method: 'POST', url: url, body: body);
  }

  factory _Check.get({
    required String name,
    required String url,
    required Map<String, String> query,
  }) {
    return _Check._(name: name, method: 'GET', url: url, query: query);
  }
}

class _CheckResult {
  final String name;
  final String method;
  final int? statusCode;
  final bool ok;
  final String? code;
  final String? message;
  final String bodyPreview;

  const _CheckResult({
    required this.name,
    required this.method,
    required this.statusCode,
    required this.ok,
    required this.code,
    required this.message,
    required this.bodyPreview,
  });

  String render() {
    final mark = ok ? 'PASS' : 'FAIL';
    final status = statusCode?.toString() ?? 'no-http-status';
    final c = code == null ? '' : ' code=$code';
    final m = message == null ? '' : ' message="$message"';
    return '[$mark] $method $name -> HTTP $status$c$m body="$bodyPreview"';
  }
}
