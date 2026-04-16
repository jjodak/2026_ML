import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/service_presets.dart';
import '../models/subscription.dart';
import '../providers/subscription_provider.dart';

const _types = [
  'Music',
  'Video',
  'Education',
  'Fitness',
  'Game',
  'News',
  'Cloud'
];
const _freqLabels = ['드물게', '월', '주', '자주'];
const _recencyLabels = ['30일+', '7-30일', '1-7일', '1일 이내'];

void showAddSubscriptionDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => const _AddSubscriptionDialog(),
  );
}

class _AddSubscriptionDialog extends StatefulWidget {
  const _AddSubscriptionDialog();

  @override
  State<_AddSubscriptionDialog> createState() => _AddSubscriptionDialogState();
}

class _AddSubscriptionDialogState extends State<_AddSubscriptionDialog> {
  final _nameCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  final _remainingCtrl = TextEditingController(text: '0');

  String _type = _types[0];
  int _freqIndex = 0;
  int _recencyIndex = 3;
  double _necessity = 3;
  bool _replacementAvailable = false;

  // 상세 설정 (nullable — 미입력 시 서버가 자동 추정)
  double? _costBurden;
  double? _wouldRebuy;
  bool _isAnnual = false;

  // 프리셋 선택 상태 (-1 = 직접 입력)
  int _selectedPresetIndex = -1;
  bool get _isPresetMode => _selectedPresetIndex >= 0;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _costCtrl.dispose();
    _discountCtrl.dispose();
    _remainingCtrl.dispose();
    super.dispose();
  }

  void _selectPreset(int index) {
    final preset = servicePresets[index];
    setState(() {
      _selectedPresetIndex = index;
      _nameCtrl.text = preset.name;
      _costCtrl.text = preset.monthlyCost.toString();
      _type = preset.type;
      _isAnnual = preset.isAnnual;
      _discountCtrl.text =
          preset.discountAmount > 0 ? preset.discountAmount.toString() : '';
    });
  }

  void _clearPreset() {
    setState(() {
      _selectedPresetIndex = -1;
      _nameCtrl.clear();
      _costCtrl.clear();
      _type = _types[0];
      _isAnnual = false;
      _discountCtrl.clear();
    });
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final cost = int.tryParse(_costCtrl.text.trim()) ?? 0;
    if (name.isEmpty || cost <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서비스를 선택하거나 이름과 구독료를 입력해주세요')),
      );
      return;
    }

    final provider = context.read<SubscriptionProvider>();
    final discount = int.tryParse(_discountCtrl.text.trim()) ?? 0;
    final remaining = double.tryParse(_remainingCtrl.text.trim()) ?? 0;

    provider.addSubscription(Subscription(
      id: provider.nextId,
      name: name,
      type: _type,
      monthlyCost: cost,
      useFrequency: UseFrequency.values[_freqIndex],
      lastUseRecency: LastUseRecency.values[_recencyIndex],
      perceivedNecessity: _necessity.round(),
      costBurden: _costBurden?.round(),
      wouldRebuy: _wouldRebuy?.round(),
      replacementAvailable: _replacementAvailable,
      isAnnual: _isAnnual,
      remainingMonths: remaining,
      discountAmount: discount,
    ));

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('구독 추가'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            FilledButton(
              onPressed: _submit,
              child: const Text('추가'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 프리셋 선택 영역 ──
              Text('인기 서비스에서 선택',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: servicePresets.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == servicePresets.length) {
                      return ActionChip(
                        avatar: const Icon(Icons.edit, size: 16),
                        label: const Text('직접 입력'),
                        onPressed: _clearPreset,
                        side: _isPresetMode
                            ? null
                            : BorderSide(color: theme.colorScheme.primary),
                        backgroundColor: _isPresetMode
                            ? null
                            : theme.colorScheme.primaryContainer,
                      );
                    }
                    final p = servicePresets[index];
                    final selected = _selectedPresetIndex == index;
                    return ChoiceChip(
                      avatar: Text(p.emoji, style: const TextStyle(fontSize: 16)),
                      label: Text(p.name),
                      selected: selected,
                      onSelected: (_) => _selectPreset(index),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              // ── 서비스 기본 정보 (프리셋이면 읽기전용) ──
              if (!_isPresetMode) ...[
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: '서비스 이름',
                    hintText: '예: Netflix',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: const InputDecoration(
                    labelText: '유형',
                    border: OutlineInputBorder(),
                  ),
                  items: _types
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _type = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _costCtrl,
                  decoration: const InputDecoration(
                    labelText: '월 구독료 (원)',
                    hintText: '예: 9500',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
              ] else ...[
                _presetSummaryCard(),
                const SizedBox(height: 16),
              ],

              // ── 핵심 주관 필드 (항상 표시) ──
              Text('나의 사용 패턴',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              _sectionLabel('얼마나 자주 쓰나요?'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(4, (i) {
                  return ChoiceChip(
                    label: Text(_freqLabels[i]),
                    selected: _freqIndex == i,
                    onSelected: (_) => setState(() => _freqIndex = i),
                  );
                }),
              ),
              const SizedBox(height: 16),

              _sectionLabel('마지막으로 언제 썼나요?'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(4, (i) {
                  return ChoiceChip(
                    label: Text(_recencyLabels[i]),
                    selected: _recencyIndex == i,
                    onSelected: (_) => setState(() => _recencyIndex = i),
                  );
                }),
              ),
              const SizedBox(height: 16),

              _sliderField(
                '이 서비스가 얼마나 필요한가요?',
                _necessity,
                (v) => setState(() => _necessity = v),
                labels: const ['전혀', '', '보통', '', '필수'],
              ),

              SwitchListTile(
                title: const Text('비슷한 대체 서비스가 있나요?'),
                value: _replacementAvailable,
                onChanged: (v) => setState(() => _replacementAvailable = v),
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 8),

              // ── 상세 설정 (접힌 상태 기본) ──
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text('상세 설정',
                    style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600)),
                subtitle: const Text('입력하지 않으면 자동 추정됩니다',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                children: [
                  const SizedBox(height: 8),
                  _optionalSliderField(
                    '비용 부담',
                    _costBurden,
                    (v) => setState(() => _costBurden = v),
                    labels: const ['적음', '', '보통', '', '큼'],
                  ),
                  _optionalSliderField(
                    '재구독 의향',
                    _wouldRebuy,
                    (v) => setState(() => _wouldRebuy = v),
                    labels: const ['없음', '', '보통', '', '높음'],
                  ),
                  if (!_isPresetMode) ...[
                    SwitchListTile(
                      title: const Text('연간 구독'),
                      value: _isAnnual,
                      onChanged: (v) => setState(() => _isAnnual = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                  TextField(
                    controller: _remainingCtrl,
                    decoration: const InputDecoration(
                      labelText: '잔여 개월 수',
                      hintText: '예: 3.5',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _discountCtrl,
                    decoration: const InputDecoration(
                      labelText: '할인/환급액 (원)',
                      hintText: '예: 2000',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _presetSummaryCard() {
    final preset = servicePresets[_selectedPresetIndex];
    return Card(
      child: ListTile(
        leading: Text(preset.emoji, style: const TextStyle(fontSize: 28)),
        title: Text(preset.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            '${preset.type} · 월 ${_formatCost(preset.monthlyCost)}원'
            '${preset.isAnnual ? ' · 연간' : ''}'),
        trailing: TextButton(
          onPressed: _clearPreset,
          child: const Text('변경'),
        ),
      ),
    );
  }

  String _formatCost(int cost) {
    if (cost >= 10000) {
      final man = cost ~/ 10000;
      final rest = cost % 10000;
      if (rest == 0) return '$man만';
      return '$man만${rest.toString().replaceAll(RegExp(r'0+$'), '')}';
    }
    return cost.toString();
  }

  Widget _sectionLabel(String text) {
    return Text(text,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14));
  }

  Widget _sliderField(
    String label,
    double value,
    ValueChanged<double> onChanged, {
    List<String>? labels,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(label),
        Slider(
          value: value,
          min: 1,
          max: 5,
          divisions: 4,
          label: labels != null ? labels[value.round() - 1] : '${value.round()}',
          onChanged: onChanged,
        ),
        if (labels != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: labels
                  .map((l) => Text(l,
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600)))
                  .toList(),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _optionalSliderField(
    String label,
    double? value,
    ValueChanged<double> onChanged, {
    List<String>? labels,
  }) {
    final isActive = value != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: isActive ? null : Colors.grey,
                  )),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  if (isActive) {
                    if (label == '비용 부담') {
                      _costBurden = null;
                    } else {
                      _wouldRebuy = null;
                    }
                  } else {
                    onChanged(3);
                  }
                });
              },
              child: Text(isActive ? '자동으로' : '직접 설정'),
            ),
          ],
        ),
        if (isActive)
          Slider(
            value: value,
            min: 1,
            max: 5,
            divisions: 4,
            label: labels != null
                ? labels[value.round() - 1]
                : '${value.round()}',
            onChanged: onChanged,
          ),
        if (isActive && labels != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: labels
                  .map((l) => Text(l,
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600)))
                  .toList(),
            ),
          ),
        if (!isActive)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('입력 정보 기반으로 자동 추정됩니다',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ),
      ],
    );
  }
}
