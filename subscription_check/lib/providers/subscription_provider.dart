import 'package:flutter/foundation.dart';
import '../models/subscription.dart';
import '../services/predict_service.dart';

class ChurnResult {
  final bool isChurnCandidate;
  final double confidence;
  final String reason;

  ChurnResult({
    required this.isChurnCandidate,
    required this.confidence,
    required this.reason,
  });
}

class SubscriptionProvider extends ChangeNotifier {
  final List<Subscription> _items = [
    Subscription(
      id: '1',
      name: 'Netflix',
      type: 'Video',
      monthlyCost: 17000,
      useFrequency: UseFrequency.rare,
      lastUseRecency: LastUseRecency.over30d,
      perceivedNecessity: 2,
      costBurden: 4,
      wouldRebuy: 2,
      replacementAvailable: true,
      isAnnual: false,
      remainingMonths: 0.0,
      discountAmount: 0,
    ),
    Subscription(
      id: '2',
      name: 'YouTube Premium',
      type: 'Video',
      monthlyCost: 14900,
      useFrequency: UseFrequency.frequent,
      lastUseRecency: LastUseRecency.under1d,
      perceivedNecessity: 5,
      costBurden: 2,
      wouldRebuy: 5,
      replacementAvailable: false,
      isAnnual: false,
      remainingMonths: 0.0,
      discountAmount: 0,
    ),
    Subscription(
      id: '3',
      name: '헬스장 (연간)',
      type: 'Fitness',
      monthlyCost: 50000,
      useFrequency: UseFrequency.monthly,
      lastUseRecency: LastUseRecency.between7and30d,
      perceivedNecessity: 3,
      costBurden: 3,
      wouldRebuy: 3,
      replacementAvailable: true,
      isAnnual: true,
      remainingMonths: 5.0,
      discountAmount: 10000,
    ),
  ];

  int _nextId = 4;
  Map<String, ChurnResult> _results = {};
  bool _isAnalyzing = false;
  String? _errorMessage;

  List<Subscription> get items => List.unmodifiable(_items);
  Map<String, ChurnResult> get results => Map.unmodifiable(_results);
  bool get isAnalyzing => _isAnalyzing;
  String? get errorMessage => _errorMessage;

  void addSubscription(Subscription s) {
    _items.add(s);
    notifyListeners();
  }

  void removeSubscription(String id) {
    _items.removeWhere((s) => s.id == id);
    _results.remove(id);
    notifyListeners();
  }

  String get nextId => (_nextId++).toString();

  Future<void> analyzeAll() async {
    _isAnalyzing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _results = await predictBatch(_items);
    } catch (e) {
      _errorMessage = '추론 서버에 연결할 수 없습니다.\n'
          'python server/predict_server.py 를 먼저 실행해주세요.';
    }

    _isAnalyzing = false;
    notifyListeners();
  }
}
