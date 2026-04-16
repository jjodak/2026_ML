class ServicePreset {
  final String name;
  final String type;
  final int monthlyCost;
  final bool isAnnual;
  final int discountAmount;
  final String emoji;

  const ServicePreset({
    required this.name,
    required this.type,
    required this.monthlyCost,
    this.isAnnual = false,
    this.discountAmount = 0,
    required this.emoji,
  });
}

const servicePresets = [
  ServicePreset(
    name: 'Netflix',
    type: 'Video',
    monthlyCost: 17000,
    emoji: '🎬',
  ),
  ServicePreset(
    name: 'YouTube Premium',
    type: 'Video',
    monthlyCost: 14900,
    emoji: '▶️',
  ),
  ServicePreset(
    name: 'Spotify',
    type: 'Music',
    monthlyCost: 10900,
    emoji: '🎵',
  ),
  ServicePreset(
    name: 'Apple Music',
    type: 'Music',
    monthlyCost: 11000,
    emoji: '🍎',
  ),
  ServicePreset(
    name: 'ChatGPT Plus',
    type: 'Cloud',
    monthlyCost: 30000,
    emoji: '🤖',
  ),
  ServicePreset(
    name: '쿠팡 로켓와우',
    type: 'Cloud',
    monthlyCost: 7890,
    emoji: '🚀',
  ),
  ServicePreset(
    name: '밀리의 서재',
    type: 'Education',
    monthlyCost: 9900,
    emoji: '📚',
  ),
  ServicePreset(
    name: '네이버 플러스',
    type: 'Cloud',
    monthlyCost: 4900,
    emoji: '🟢',
  ),
  ServicePreset(
    name: '디즈니+',
    type: 'Video',
    monthlyCost: 9900,
    emoji: '🏰',
  ),
  ServicePreset(
    name: '웨이브',
    type: 'Video',
    monthlyCost: 7900,
    emoji: '🌊',
  ),
  ServicePreset(
    name: 'Microsoft 365',
    type: 'Cloud',
    monthlyCost: 8900,
    isAnnual: true,
    emoji: '💼',
  ),
  ServicePreset(
    name: 'Nintendo Online',
    type: 'Game',
    monthlyCost: 4900,
    isAnnual: true,
    emoji: '🎮',
  ),
  ServicePreset(
    name: '클래스101',
    type: 'Education',
    monthlyCost: 19900,
    emoji: '🎓',
  ),
  ServicePreset(
    name: '헬스장/PT',
    type: 'Fitness',
    monthlyCost: 50000,
    emoji: '💪',
  ),
];
