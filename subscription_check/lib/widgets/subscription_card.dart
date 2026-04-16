import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/subscription.dart';
import '../providers/subscription_provider.dart';

final _currencyFormat =
    NumberFormat.currency(locale: 'ko_KR', symbol: '₩', decimalDigits: 0);

String _freqLabel(UseFrequency f) {
  switch (f) {
    case UseFrequency.rare:
      return '드물게';
    case UseFrequency.monthly:
      return '월';
    case UseFrequency.weekly:
      return '주';
    case UseFrequency.frequent:
      return '자주';
  }
}

String _recencyLabel(LastUseRecency r) {
  switch (r) {
    case LastUseRecency.over30d:
      return '30일+';
    case LastUseRecency.between7and30d:
      return '7-30일';
    case LastUseRecency.between1and7d:
      return '1-7일';
    case LastUseRecency.under1d:
      return '1일 이내';
  }
}

class SubscriptionCard extends StatelessWidget {
  final Subscription subscription;
  final ChurnResult? result;
  final VoidCallback onDelete;

  const SubscriptionCard({
    super.key,
    required this.subscription,
    this.result,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    subscription.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (result != null) _buildBadge(result!),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '월 ${_currencyFormat.format(subscription.effectiveMonthlyCost)}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (subscription.discountAmount > 0)
              Text(
                '(정가 ${_currencyFormat.format(subscription.monthlyCost)}, 할인 ${_currencyFormat.format(subscription.discountAmount)})',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            const SizedBox(height: 4),
            Text(
              '빈도: ${_freqLabel(subscription.useFrequency)} / 최근: ${_recencyLabel(subscription.lastUseRecency)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (result != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('💬 ', style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Text(
                      result!.reason,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: result!.isChurnCandidate
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '모델 확신도 ${(result!.confidence * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: result!.confidence,
                      backgroundColor: Colors.grey.shade200,
                      color: result!.isChurnCandidate
                          ? Colors.red.shade300
                          : Colors.green.shade300,
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(ChurnResult r) {
    final Color bgColor;
    final String label;

    if (r.isChurnCandidate) {
      bgColor = Colors.red;
      label = '해지 고려';
    } else {
      bgColor = Colors.green;
      label = '유지 추천';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
