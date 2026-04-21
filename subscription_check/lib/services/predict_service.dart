import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../config/server_config.dart';
import '../models/subscription.dart';
import '../providers/subscription_provider.dart';
import 'device_id_service.dart';

String get _baseUrl {
  if (kIsWeb) return 'http://localhost:5050';
  return 'https://$serverHost';
}

Future<Map<String, String>> _jsonHeaders() async {
  final deviceId = await getOrCreateDeviceId();
  return {
    'Content-Type': 'application/json',
    'X-Device-Id': deviceId,
  };
}

// ─── Subscription CRUD ─────────────────────────────────────────────────────

Future<List<Subscription>> fetchSubscriptions() async {
  final response = await http.get(
    Uri.parse('$_baseUrl/subscriptions'),
    headers: await _jsonHeaders(),
  );
  if (response.statusCode != 200) {
    throw Exception('구독 목록 조회 실패: ${response.statusCode}');
  }
  final list = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
  return list
      .map((e) => Subscription.fromServerJson(e as Map<String, dynamic>))
      .toList();
}

Future<Subscription> createSubscription(Subscription s) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/subscriptions'),
    headers: await _jsonHeaders(),
    body: jsonEncode(s.toPersistenceJson()),
  );
  if (response.statusCode != 201) {
    throw Exception('구독 생성 실패: ${response.statusCode}');
  }
  return Subscription.fromServerJson(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
}

Future<Subscription> patchSubscription(Subscription s) async {
  final response = await http.patch(
    Uri.parse('$_baseUrl/subscriptions/${s.id}'),
    headers: await _jsonHeaders(),
    body: jsonEncode(s.toPersistenceJson()),
  );
  if (response.statusCode != 200) {
    throw Exception('구독 수정 실패: ${response.statusCode}');
  }
  return Subscription.fromServerJson(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
}

Future<void> deleteSubscription(String id) async {
  final response = await http.delete(
    Uri.parse('$_baseUrl/subscriptions/$id'),
    headers: await _jsonHeaders(),
  );
  if (response.statusCode != 200) {
    throw Exception('구독 삭제 실패: ${response.statusCode}');
  }
}

// ─── Prediction ────────────────────────────────────────────────────────────

Future<Map<String, ChurnResult>> predictBatch(
    List<Subscription> subscriptions) async {
  final body = subscriptions.map((s) => s.toApiJson()).toList();

  final response = await http.post(
    Uri.parse('$_baseUrl/predict_batch'),
    headers: await _jsonHeaders(),
    body: jsonEncode(body),
  );

  if (response.statusCode != 200) {
    throw Exception('서버 응답 오류: ${response.statusCode}');
  }

  final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
  final results = <String, ChurnResult>{};

  for (final entry in data.entries) {
    final r = entry.value as Map<String, dynamic>;
    results[entry.key] = ChurnResult(
      predictionId: (r['prediction_id'] as num).toInt(),
      isChurnCandidate: r['is_churn_candidate'] as bool,
      confidence: (r['confidence'] as num).toDouble(),
      reason: r['reason'] as String,
    );
  }
  return results;
}

Future<void> submitFeedback({
  required int predictionId,
  required bool actualKept,
  String? subscriptionId,
}) async {
  final body = <String, dynamic>{
    'prediction_id': predictionId,
    'actual_kept': actualKept,
  };
  if (subscriptionId != null) {
    body['subscription_id'] = int.tryParse(subscriptionId) ?? subscriptionId;
  }

  final response = await http.post(
    Uri.parse('$_baseUrl/feedback'),
    headers: await _jsonHeaders(),
    body: jsonEncode(body),
  );

  if (response.statusCode != 200) {
    throw Exception('피드백 전송 실패: ${response.statusCode}');
  }
}

// ─── Savings (절감액 트래커) ──────────────────────────────────────────────

class SavingsHistoryItem {
  final int predictionId;
  final String subscriptionType;
  final int effectiveMonthlyCost;
  final DateTime? feedbackAt;

  SavingsHistoryItem({
    required this.predictionId,
    required this.subscriptionType,
    required this.effectiveMonthlyCost,
    required this.feedbackAt,
  });

  factory SavingsHistoryItem.fromJson(Map<String, dynamic> json) {
    final fb = json['feedback_at'] as String?;
    return SavingsHistoryItem(
      predictionId: (json['prediction_id'] as num).toInt(),
      subscriptionType: json['subscription_type'] as String? ?? '',
      effectiveMonthlyCost: (json['effective_monthly'] as num?)?.toInt() ?? 0,
      feedbackAt: fb != null ? DateTime.tryParse(fb) : null,
    );
  }
}

class SavingsSummary {
  final int cancelledCount;
  final int keptCount;
  final int monthlySavings;
  final int cumulativeSavings;
  final List<SavingsHistoryItem> history;

  SavingsSummary({
    required this.cancelledCount,
    required this.keptCount,
    required this.monthlySavings,
    required this.cumulativeSavings,
    required this.history,
  });

  factory SavingsSummary.fromJson(Map<String, dynamic> json) {
    return SavingsSummary(
      cancelledCount: (json['cancelled_count'] as num?)?.toInt() ?? 0,
      keptCount: (json['kept_count'] as num?)?.toInt() ?? 0,
      monthlySavings: (json['monthly_savings'] as num?)?.toInt() ?? 0,
      cumulativeSavings: (json['cumulative_savings'] as num?)?.toInt() ?? 0,
      history: ((json['history'] as List<dynamic>?) ?? [])
          .map((e) => SavingsHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

Future<SavingsSummary> fetchSavings() async {
  final response = await http.get(
    Uri.parse('$_baseUrl/savings'),
    headers: await _jsonHeaders(),
  );
  if (response.statusCode != 200) {
    throw Exception('절감액 조회 실패: ${response.statusCode}');
  }
  return SavingsSummary.fromJson(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
}

Future<bool> checkServerHealth() async {
  try {
    final response = await http
        .get(Uri.parse('$_baseUrl/health'))
        .timeout(const Duration(seconds: 3));
    return response.statusCode == 200;
  } catch (_) {
    return false;
  }
}
