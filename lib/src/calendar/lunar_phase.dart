import 'dart:math' as math;

enum LunarPhaseType {
  newMoon,
  waxingCrescent,
  firstQuarter,
  waxingGibbous,
  fullMoon,
  waningGibbous,
  lastQuarter,
  waningCrescent,
}

extension LunarPhaseTypePresentation on LunarPhaseType {
  String get label => switch (this) {
        LunarPhaseType.newMoon => 'Молодик',
        LunarPhaseType.waxingCrescent => 'Зростаючий серп',
        LunarPhaseType.firstQuarter => 'Перша чверть',
        LunarPhaseType.waxingGibbous => 'Зростаючий Місяць',
        LunarPhaseType.fullMoon => 'Повня',
        LunarPhaseType.waningGibbous => 'Спадний Місяць',
        LunarPhaseType.lastQuarter => 'Остання чверть',
        LunarPhaseType.waningCrescent => 'Спадний серп',
      };

  String get symbol => switch (this) {
        LunarPhaseType.newMoon => '🌑',
        LunarPhaseType.waxingCrescent => '🌒',
        LunarPhaseType.firstQuarter => '🌓',
        LunarPhaseType.waxingGibbous => '🌔',
        LunarPhaseType.fullMoon => '🌕',
        LunarPhaseType.waningGibbous => '🌖',
        LunarPhaseType.lastQuarter => '🌗',
        LunarPhaseType.waningCrescent => '🌘',
      };
}

class LunarPhase {
  static const _synodicMonthDays = 29.530588853;
  static final _knownNewMoon = DateTime.utc(2000, 1, 6, 18, 14);

  final LunarPhaseType type;
  final double ageDays;
  final double illumination;

  const LunarPhase({
    required this.type,
    required this.ageDays,
    required this.illumination,
  });

  int get illuminationPercent => (illumination * 100).round();

  /// Returns an approximate visual phase for the middle of the selected day.
  /// This is intentionally not used to calculate planting or care dates.
  factory LunarPhase.forDate(DateTime value) {
    final middleOfDay = DateTime.utc(value.year, value.month, value.day, 12);
    final elapsedDays = middleOfDay.difference(_knownNewMoon).inSeconds /
        Duration.secondsPerDay;
    final age = ((elapsedDays % _synodicMonthDays) + _synodicMonthDays) %
        _synodicMonthDays;
    final phaseIndex = ((age / _synodicMonthDays * 8) + 0.5).floor() % 8;
    final illumination =
        (1 - math.cos(2 * math.pi * age / _synodicMonthDays)) / 2;

    return LunarPhase(
      type: LunarPhaseType.values[phaseIndex],
      ageDays: age,
      illumination: illumination,
    );
  }
}
