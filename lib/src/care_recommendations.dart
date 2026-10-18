import 'models.dart';

class CropCareProfile {
  final String watering;
  final String care;
  final String fertilizer;
  final int defaultCheckIntervalDays;

  const CropCareProfile({
    required this.watering,
    required this.care,
    required this.fertilizer,
    required this.defaultCheckIntervalDays,
  });
}

class CropMaturityEstimate {
  final int earliestDays;
  final int latestDays;
  final int selectedDays;
  final String dateBasisLabel;
  final String ruleVersion;

  const CropMaturityEstimate({
    required this.earliestDays,
    required this.latestDays,
    required this.selectedDays,
    required this.dateBasisLabel,
    this.ruleVersion = 'legacy-text-v1',
  });
}

/// Converts the catalog's human-readable maturity range into dates that can
/// power reminders. For seedlings we prefer a range counted from transplant;
/// for direct-sown crops we prefer one counted from sowing.
CropMaturityEstimate? maturityEstimateFor(
  Crop crop, {
  Iterable<SeedMaturityGroup> maturityGroups = const [],
  PlantingEventType? plantingEventType,
  AgroclimaticZone agroclimaticZone = AgroclimaticZone.unknown,
}) {
  final structured = _structuredMaturityEstimate(
    crop,
    maturityGroups: maturityGroups,
    plantingEventType: plantingEventType,
    agroclimaticZone: agroclimaticZone,
  );
  if (structured != null) return structured;

  final maturity = crop.maturity.trim();
  if (maturity.isEmpty) return null;

  final segments = maturity
      .split(';')
      .map((segment) => segment.trim())
      .where((segment) => segment.isNotEmpty)
      .toList();
  if (segments.isEmpty) return null;

  final usesTransplantDate = _isUsefulCatalogFact(crop.transplantingUkraine);
  String selectedSegment = segments.first;
  if (usesTransplantDate) {
    selectedSegment = segments.firstWhere(
      (segment) => segment.toLowerCase().contains('висад'),
      orElse: () => segments.first,
    );
  } else {
    selectedSegment = segments.firstWhere(
      (segment) => segment.toLowerCase().contains('посів'),
      orElse: () => segments.first,
    );
  }

  final match = RegExp(
    r'(\d{1,3})\s*(?:[–—-]\s*(\d{1,3}))?\s*'
    r'(д(?:ень|ні|нів)|місяц(?:ь|і|ів))',
    caseSensitive: false,
  ).firstMatch(selectedSegment);
  if (match == null) return null;

  var earliest = int.parse(match.group(1)!);
  var latest = int.parse(match.group(2) ?? match.group(1)!);
  if (match.group(3)!.toLowerCase().startsWith('місяц')) {
    earliest *= 30;
    latest *= 30;
  }
  if (latest < earliest) {
    final oldEarliest = earliest;
    earliest = latest;
    latest = oldEarliest;
  }

  final groups = maturityGroups
      .where((group) => group != SeedMaturityGroup.unknown)
      .toSet();
  final selectedDays = groups.contains(SeedMaturityGroup.early)
      ? earliest
      : groups.contains(SeedMaturityGroup.midSeason)
          ? ((earliest + latest) / 2).round()
          : groups.contains(SeedMaturityGroup.late)
              ? latest
              : earliest;
  final normalizedSegment = selectedSegment.toLowerCase();
  final dateBasisLabel = normalizedSegment.contains('висад')
      ? 'від висаджування'
      : normalizedSegment.contains('посів')
          ? 'від посіву'
          : usesTransplantDate
              ? 'від висаджування'
              : 'від посіву / посадки';

  return CropMaturityEstimate(
    earliestDays: earliest,
    latestDays: latest,
    selectedDays: selectedDays,
    dateBasisLabel: dateBasisLabel,
  );
}

CropMaturityEstimate? _structuredMaturityEstimate(
  Crop crop, {
  required Iterable<SeedMaturityGroup> maturityGroups,
  required PlantingEventType? plantingEventType,
  required AgroclimaticZone agroclimaticZone,
}) {
  final timings = crop.stageTimings
      .where((timing) => timing.stage == RecommendationStage.maturity)
      .toList();
  if (timings.isEmpty) return null;
  final reference = switch (plantingEventType) {
    PlantingEventType.sowing => TimingReferencePoint.sowing,
    PlantingEventType.transplanting => TimingReferencePoint.transplanting,
    PlantingEventType.planting => TimingReferencePoint.planting,
    null => null,
  };
  final candidates = reference == null
      ? timings
      : timings.where((timing) => timing.referencePoint == reference).toList();
  final timing = candidates.isNotEmpty ? candidates.first : timings.first;
  final adjustment = timing.regionalAdjustmentDays[agroclimaticZone] ?? 0;
  final earliest = (timing.daysMin + adjustment).clamp(1, 1000);
  final latest = (timing.daysMax + adjustment).clamp(earliest, 1000);
  final groups = maturityGroups
      .where((group) => group != SeedMaturityGroup.unknown)
      .toSet();
  final selected = groups.contains(SeedMaturityGroup.early)
      ? earliest
      : groups.contains(SeedMaturityGroup.midSeason)
          ? ((earliest + latest) / 2).round()
          : groups.contains(SeedMaturityGroup.late)
              ? latest
              : earliest;
  final basis = switch (timing.referencePoint) {
    TimingReferencePoint.sowing => 'від посіву',
    TimingReferencePoint.planting => 'від посадки',
    TimingReferencePoint.transplanting => 'від висаджування',
  };
  return CropMaturityEstimate(
    earliestDays: earliest,
    latestDays: latest,
    selectedDays: selected,
    dateBasisLabel: basis,
    ruleVersion: timing.formulaVersion,
  );
}

bool _isUsefulCatalogFact(String value) {
  final normalized = value.trim().toLowerCase();
  return normalized.isNotEmpty &&
      normalized != 'не вказано' &&
      normalized != 'не застосовується' &&
      normalized != 'not applicable';
}

CropCareProfile careProfileFor(Crop crop) {
  if (crop.catalogId.isNotEmpty &&
      (crop.watering.isNotEmpty || crop.fertilization.isNotEmpty)) {
    final careParts = <String>[
      if (crop.sowingUkraine.isNotEmpty)
        'Посів в Україні: ${crop.sowingUkraine}.',
      if (crop.transplantingUkraine.isNotEmpty)
        'Висаджування: ${crop.transplantingUkraine}.',
      if (crop.spacing.isNotEmpty) 'Відстань: ${crop.spacing}.',
      if (crop.soilAndPh.isNotEmpty) 'Ґрунт: ${crop.soilAndPh}.',
      if (crop.maturity.isNotEmpty) 'Дозрівання: ${crop.maturity}.',
      if (crop.harvest.isNotEmpty) 'Збір: ${crop.harvest}.',
    ];
    return CropCareProfile(
      watering: crop.watering.isNotEmpty
          ? crop.watering
          : 'Перевіряйте вологість кореневої зони та враховуйте опади.',
      care: careParts.isEmpty ? crop.recommendation : careParts.join(' '),
      fertilizer: crop.fertilization.isNotEmpty
          ? '${crop.fertilization}. Дозу визначайте за аналізом ґрунту та етикеткою продукту.'
          : 'Підживлюйте лише за результатом аналізу ґрунту та етикеткою продукту.',
      defaultCheckIntervalDays: _catalogWateringInterval(crop),
    );
  }
  switch (crop.name.trim().toLowerCase()) {
    case 'томат':
    case 'помідор':
      return const CropCareProfile(
        watering:
            'Перевіряйте ґрунт кожні 2–3 дні. Поливайте під корінь, коли верхні 3–5 см підсохли; у спеку перевіряйте частіше. Уникайте різких змін вологості та мокрого листя.',
        care:
            'Замульчуйте ґрунт, підв’яжіть рослину й забезпечте рух повітря. Регулярно оглядайте нижнє листя та плоди.',
        fertilizer:
            'До підживлення перевірте ґрунт. Надлишок азоту дає багато листя й менше плодів; під час цвітіння та плодоношення обирайте добриво за результатом аналізу і вносьте лише за етикеткою.',
        defaultCheckIntervalDays: 2,
      );
    case 'огірок':
      return const CropCareProfile(
        watering:
            'Підтримуйте рівномірно вологий ґрунт, особливо під час цвітіння й наливу плодів. Перевіряйте кожні 1–2 дні у спеку, поливайте біля основи рослини.',
        care:
            'Мульчуйте, дайте опору та збирайте плоди регулярно. Не працюйте з мокрим листям і залишайте достатньо повітря між рослинами.',
        fertilizer:
            'Орієнтуйтеся на аналіз ґрунту. Не додавайте азот автоматично: оберіть склад за потребою культури й дотримуйтеся етикетки продукту.',
        defaultCheckIntervalDays: 2,
      );
    case 'морква':
      return const CropCareProfile(
        watering:
            'До сходів тримайте верхній шар ґрунту постійно вологим. Під час росту коренеплоду поливайте рівномірно й глибше, без перезволоження та довгих пересушувань.',
        care:
            'Обережно прорідіть сходи, розпушуйте поверхню й контролюйте бур’яни, щоб коренеплоди мали простір.',
        fertilizer:
            'Свіжий гній і надлишок азоту можуть погіршити форму коренеплодів. Вносьте лише зрілий компост або добриво, підібране за аналізом ґрунту та етикеткою.',
        defaultCheckIntervalDays: 3,
      );
    case 'квасоля':
    case 'горох':
      return const CropCareProfile(
        watering:
            'Перевіряйте вологість кожні 2–3 дні. Особливо важлива рівномірна волога під час цвітіння та формування стручків.',
        care:
            'Додайте опору витким сортам, мульчуйте та збирайте молоді стручки регулярно. Не торкайтеся рослин, коли листя мокре.',
        fertilizer:
            'Бобові зазвичай не потребують надлишку азоту. Спочатку зробіть аналіз ґрунту; фосфор, калій або інші елементи додавайте лише за потребою та етикеткою.',
        defaultCheckIntervalDays: 3,
      );
    case 'капуста':
      return const CropCareProfile(
        watering:
            'Підтримуйте стабільну вологість, особливо коли формується головка. Перевіряйте ґрунт кожні 2–3 дні та поливайте під корінь.',
        care:
            'Мульчуйте, прибирайте бур’яни та оглядайте нижній бік листків на шкідників. Не залишайте рослинні рештки з ознаками хвороб.',
        fertilizer:
            'Капуста потребує поживного ґрунту, але точний склад визначайте аналізом. Розділяйте підживлення за етапами росту та дотримуйтеся етикетки.',
        defaultCheckIntervalDays: 3,
      );
    case 'цибуля':
      return const CropCareProfile(
        watering:
            'Поливайте неглибоко, але рівномірно, коли ґрунт підсихає. Коли бадилля починає природно вилягати перед збором, полив скоротіть.',
        care:
            'Тримайте грядку без бур’янів і не засипайте цибулини товстим шаром ґрунту. Регулярно оглядайте листя.',
        fertilizer:
            'Уникайте пізнього надлишку азоту — він затримує визрівання. Склад і час підживлення обирайте після аналізу ґрунту та за етикеткою.',
        defaultCheckIntervalDays: 3,
      );
    case 'салат':
      return const CropCareProfile(
        watering:
            'Підтримуйте прохолодний, рівномірно вологий ґрунт. У теплу погоду перевіряйте вологість щодня, не допускаючи застою води.',
        care:
            'Збирайте зовнішнє листя вчасно, мульчуйте й за потреби притіняйте у спеку, щоб рослина повільніше стрілкувалася.',
        fertilizer:
            'Для листових культур не перевищуйте азотні норми. Використовуйте аналіз ґрунту й інструкцію виробника, не підживлюйте «про запас».',
        defaultCheckIntervalDays: 2,
      );
    default:
      return const CropCareProfile(
        watering:
            'Перевіряйте вологість пальцем на глибині 3–5 см і поливайте під корінь лише за потреби. Після дощу або в прохолоду інтервал збільшуйте.',
        care:
            'Мульчуйте ґрунт, контролюйте бур’яни й регулярно оглядайте рослину на ознаки стресу, шкідників або хвороб.',
        fertilizer:
            'Спочатку зробіть аналіз ґрунту. Обирайте правильне джерело, дозу, час і місце внесення; завжди дотримуйтеся етикетки добрива.',
        defaultCheckIntervalDays: 3,
      );
  }
}

int _catalogWateringInterval(Crop crop) {
  if (crop.family == CropFamily.cucurbit || crop.family == CropFamily.leafy) {
    return 2;
  }
  return 3;
}

class WeatherSnapshot {
  final double? precipitationMm24h;
  final double? temperatureC;
  final String source;

  const WeatherSnapshot({
    this.precipitationMm24h,
    this.temperatureC,
    this.source = '',
  });
}

CropCareProfile recommendationsFor({
  required Crop crop,
  required Planting planting,
  required Garden garden,
  WeatherSnapshot? weather,
}) {
  final base = careProfileFor(crop);
  final candidates = crop.wateringRules.where((rule) {
    final gardenMatches = rule.gardenTypes.isEmpty ||
        rule.gardenTypes.contains(garden.type) ||
        (garden.type == GardenType.orchard &&
            rule.gardenTypes.contains(GardenType.vegetableGarden));
    final soilMatches =
        rule.soilTypes.isEmpty || rule.soilTypes.contains(garden.soilType);
    return gardenMatches && soilMatches;
  }).toList();
  candidates.sort((a, b) {
    int specificity(WateringRule rule) =>
        (rule.gardenTypes.isEmpty ? 0 : 1) + (rule.soilTypes.isEmpty ? 0 : 2);
    return specificity(b).compareTo(specificity(a));
  });
  final selected = candidates.firstOrNull;
  var watering = selected?.recommendation ?? base.watering;
  var interval = selected?.checkIntervalDays ?? base.defaultCheckIntervalDays;

  if (selected == null) {
    if (garden.soilType == SoilType.sandy ||
        garden.soilType == SoilType.sandyLoam) {
      interval = 1;
      watering = '$watering ${soilTypeLabel(garden.soilType)} ґрунт '
          'просихає швидше, тому перевіряйте вологість щодня.';
    } else if (garden.soilType == SoilType.clay ||
        garden.soilType == SoilType.peat) {
      interval += 1;
      watering = '$watering ${soilTypeLabel(garden.soilType)} ґрунт '
          'утримує воду довше: перевіряйте нижчий шар і не допускайте застою.';
    }
    if (garden.type == GardenType.field) {
      interval = interval < 3 ? 3 : interval;
      watering = '$watering На полі перевіряйте вологість у кількох точках '
          'й обов’язково враховуйте опади.';
    }
  }

  final rain = weather?.precipitationMm24h;
  if (rain != null && rain >= 5) {
    interval += 1;
    watering = '$watering За останню добу випало '
        '${rain.toStringAsFixed(0)} мм опадів — перевірте ґрунт перед поливом.';
  }
  final location = garden.settlement.isNotEmpty
      ? garden.settlement
      : garden.oblast.isNotEmpty
          ? garden.oblast
          : agroclimaticZoneLabel(garden.agroclimaticZone);
  final context = 'Контекст: ${gardenTypeLabel(garden.type)}, '
      '${soilTypeLabel(garden.soilType)} ґрунт'
      '${location == 'Не визначено' ? '' : ', $location'}.';

  return CropCareProfile(
    watering: '$context $watering',
    care: base.care,
    fertilizer: base.fertilizer,
    defaultCheckIntervalDays: interval.clamp(1, 14),
  );
}

SpacingRule? spacingRuleFor(Crop crop, GardenType gardenType) {
  final exact = crop.spacingRules
      .where((rule) => rule.gardenType == gardenType)
      .firstOrNull;
  if (exact != null) return exact;
  if (gardenType == GardenType.orchard) {
    return crop.spacingRules
        .where((rule) => rule.gardenType == GardenType.vegetableGarden)
        .firstOrNull;
  }
  return null;
}

String spacingRuleText(SpacingRule rule) {
  String number(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
  return 'Між рослинами ${number(rule.plantMinCm)}–'
      '${number(rule.plantMaxCm)} см; між рядами '
      '${number(rule.rowMinCm)}–${number(rule.rowMaxCm)} см'
      '${rule.growingMethod.isEmpty ? '' : '. ${rule.growingMethod}'}.';
}

enum ProtectionStage {
  beforeSowing,
  sowingOrPlanting,
  afterEmergence,
  elevatedRisk,
  symptoms,
  beforeHarvest,
}

String protectionStageLabel(ProtectionStage stage) => switch (stage) {
      ProtectionStage.beforeSowing => 'До посіву',
      ProtectionStage.sowingOrPlanting => 'Посів / висаджування',
      ProtectionStage.afterEmergence => 'Після сходів',
      ProtectionStage.elevatedRisk => 'Коли зростає ризик',
      ProtectionStage.symptoms => 'Якщо є симптоми',
      ProtectionStage.beforeHarvest => 'Перед збором',
    };

class ProtectionStep {
  final ProtectionStage stage;
  final String title;
  final String action;

  const ProtectionStep({
    required this.stage,
    required this.title,
    required this.action,
  });
}

class PlantProtectionPlan {
  final List<String> risks;
  final List<String> diseases;
  final List<String> pests;
  final List<String> signs;
  final List<String> prevention;
  final List<PlantProtectionCategory> allowedProductTypes;
  final List<String> safetyRules;
  final List<ProtectionStep> steps;
  final List<String> sourceUrls;
  final int checkIntervalDays;
  final String varietyNote;

  const PlantProtectionPlan({
    required this.risks,
    this.diseases = const [],
    this.pests = const [],
    this.signs = const [],
    this.prevention = const [],
    this.allowedProductTypes = const [],
    this.safetyRules = const [],
    required this.steps,
    this.sourceUrls = const [],
    required this.checkIntervalDays,
    this.varietyNote = '',
  });
}

PlantProtectionPlan plantProtectionPlanFor(
  Crop crop, {
  Iterable<String> resistanceClaims = const [],
  Iterable<SeedMaturityGroup> maturityGroups = const [],
}) {
  final normalizedName = crop.name.trim().toLowerCase();
  final isTomato = crop.slug == 'tomato' ||
      normalizedName == 'томат' ||
      normalizedName == 'помідор';
  final isPotato = crop.slug == 'potato' || normalizedName == 'картопля';
  final hasLateBlightRisk = isTomato ||
      isPotato ||
      crop.typicalDiseases.any(
        (disease) => disease.toLowerCase().contains('фітофтор'),
      );
  final risks = crop.typicalDiseases.isNotEmpty
      ? crop.typicalDiseases
      : _fallbackDiseaseRisks(crop.family);
  final structuredRisks = crop.protectionRisks;
  final diseases = <String>{
    ...structuredRisks
        .where((risk) => risk.type == ProtectionRiskType.disease)
        .map((risk) => risk.name),
    ...risks,
  }.where((value) => value.trim().isNotEmpty).toList();
  final pests = structuredRisks
      .where((risk) => risk.type == ProtectionRiskType.pest)
      .map((risk) => risk.name)
      .where((value) => value.trim().isNotEmpty)
      .toSet()
      .toList();
  final signs = structuredRisks
      .expand((risk) => risk.signs)
      .where((value) => value.trim().isNotEmpty)
      .toSet()
      .toList();
  final prevention = structuredRisks
      .expand((risk) => risk.prevention)
      .where((value) => value.trim().isNotEmpty)
      .toSet()
      .toList();
  final allowedProductTypes = structuredRisks
      .expand((risk) => risk.actions)
      .map((action) => action.allowedProductType)
      .whereType<PlantProtectionCategory>()
      .toSet()
      .toList();
  final safetyRules = structuredRisks
      .expand((risk) => risk.actions)
      .expand((action) => action.safetyRules)
      .where((value) => value.trim().isNotEmpty)
      .toSet()
      .toList();
  final claims = resistanceClaims
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList();
  final maturity = maturityGroups
      .where((value) => value != SeedMaturityGroup.unknown)
      .toSet()
      .toList();
  final varietyNotes = <String>[
    if (claims.isNotEmpty)
      'Враховано заяву з пакування про стійкість: ${claims.join('; ')}. '
          'Це може зменшувати ризик лише для названої хвороби, але не '
          'означає повного імунітету.',
    if (maturity.contains(SeedMaturityGroup.late))
      'Пізній сорт довше залишається на ділянці, тому наприкінці сезону '
          'не припиняйте огляди завчасно.',
    if (maturity.contains(SeedMaturityGroup.early))
      'Ранній строк достигання скорочує сезон, але сам по собі не захищає '
          'від інфекції.',
  ];

  final materialGuidance = isPotato
      ? 'Використайте сертифіковані здорові бульби, відбракуйте бульби з '
          'плямами або гниллю та приберіть торішню картоплю-самосів.'
      : 'Використайте здорове насіння або розсаду без плям, в’янення та '
          'пошкоджень. Продезінфікуйте багаторазові касети й інструмент.';
  final plantingGuidance = hasLateBlightRisk
      ? '${isPotato ? 'Обробка бульб' : 'Протруювання насіння'} допустима '
          'лише засобом, етикетка якого прямо називає «${crop.name}», '
          'цільову хворобу та цей спосіб застосування. Така обробка не '
          'замінює подальший захист листя від фітофторозу.'
      : 'Протруюйте насіння або садивний матеріал лише тоді, коли етикетка '
          'засобу прямо називає «${crop.name}», цільову хворобу та спосіб '
          'обробки. Не застосовуйте препарат профілактично «про всяк випадок».';
  final monitoringGuidance = hasLateBlightRisk
      ? 'Під час прохолодної вологої погоди, тривалого намокання листя або '
          'повідомлень про фітофтороз поблизу оглядайте рослини кожні 2–3 '
          'дні. Особливо перевіряйте нижнє листя та стебла.'
      : '${plantProtectionGuidanceFor(crop)} Занотуйте дату огляду й те, що '
          'саме побачили.';
  final preventiveGuidance = hasLateBlightRisk
      ? 'За підтвердженого погодного або місцевого ризику захисний засіб '
          'застосовують до масового розвитку симптомів. Оберіть лише '
          'зареєстрований для «${crop.name}» продукт і виконайте інтервал, '
          'максимальну кількість обробок та чергування груп діючих речовин '
          'саме за його етикеткою.'
      : 'Спочатку визначте шкідника або хворобу. Механічні, санітарні й '
          'біологічні заходи мають пріоритет; препарат додавайте лише за '
          'підтвердженої потреби та відповідно до етикетки.';

  return PlantProtectionPlan(
    risks: {...diseases, ...pests}.toList(),
    diseases: diseases,
    pests: pests,
    signs: signs,
    prevention: prevention,
    allowedProductTypes: allowedProductTypes,
    safetyRules: safetyRules,
    sourceUrls: crop.diseaseSourceUrls,
    checkIntervalDays: hasLateBlightRisk ? 3 : 7,
    varietyNote: varietyNotes.join(' '),
    steps: [
      ProtectionStep(
        stage: ProtectionStage.beforeSowing,
        title: 'Здоровий матеріал і чиста ділянка',
        action: '$materialGuidance Не висаджуйте після тієї самої родини '
            'раніше рекомендованої перерви сівозміни.',
      ),
      ProtectionStep(
        stage: ProtectionStage.sowingOrPlanting,
        title: 'Чи потрібна обробка при посіві',
        action: plantingGuidance,
      ),
      ProtectionStep(
        stage: ProtectionStage.afterEmergence,
        title: 'Зменшити умови для зараження',
        action: 'Залиште рекомендовану відстань між рослинами, забезпечте '
            'рух повітря, поливайте ґрунт біля основи й не залишайте листя '
            'мокрим на ніч.',
      ),
      ProtectionStep(
        stage: ProtectionStage.elevatedRisk,
        title: 'Огляд і профілактика за ризиком',
        action: '$monitoringGuidance $preventiveGuidance',
      ),
      ProtectionStep(
        stage: ProtectionStage.elevatedRisk,
        title: 'Захист від шкідників',
        action: '${_pestMonitoringGuidanceFor(crop)} Спершу застосуйте '
            'механічне збирання, бар’єри або біологічні методи, якщо вони '
            'доречні. Інсектицид використовуйте лише за підтвердженого '
            'шкідника і тільки якщо етикетка дозволяє його для цієї культури.',
      ),
      const ProtectionStep(
        stage: ProtectionStage.symptoms,
        title: 'Спочатку підтвердити причину',
        action: 'Ізолюйте сильно уражене листя або рослину, не переносіть '
            'її між грядками та не кладіть хворі рештки у звичайний компост. '
            'Не змішуйте препарати й не збільшуйте дозу без прямої вказівки '
            'на етикетці.',
      ),
      const ProtectionStep(
        stage: ProtectionStage.beforeHarvest,
        title: 'Перевірити строк очікування',
        action: 'Перед кожною обробкою звірте строк до безпечного збору, '
            'дозволену кількість застосувань і засоби індивідуального '
            'захисту на оригінальній етикетці.',
      ),
    ],
  );
}

String _pestMonitoringGuidanceFor(Crop crop) {
  if (crop.slug == 'potato' || crop.name.trim().toLowerCase() == 'картопля') {
    return 'Оглядайте картоплю на колорадського жука, яйця та личинок.';
  }
  if (crop.family == CropFamily.brassica) {
    return 'Оглядайте нижній бік листків на яйця, гусінь, попелицю та білокрилку.';
  }
  if (crop.family == CropFamily.nightshade) {
    return 'Оглядайте листя, пагони й плоди на попелицю, кліща, совок та інших шкідників.';
  }
  return 'Оглядайте рослини на пошкодження, яйця, личинки та сисних шкідників.';
}

List<String> _fallbackDiseaseRisks(CropFamily family) => switch (family) {
      CropFamily.nightshade => const [
          'фітофтороз',
          'альтернаріоз',
          'бактеріальні плямистості',
        ],
      CropFamily.cucurbit => const [
          'борошниста роса',
          'несправжня борошниста роса',
          'кореневі гнилі',
        ],
      CropFamily.brassica => const [
          'кила капусти',
          'несправжня борошниста роса',
          'чорна гниль',
        ],
      CropFamily.allium => const [
          'несправжня борошниста роса',
          'фузаріозна гниль',
          'шийкова гниль',
        ],
      CropFamily.apiaceae => const [
          'плямистості листя',
          'кореневі гнилі',
        ],
      CropFamily.legume => const [
          'антракноз',
          'іржа',
          'кореневі гнилі',
        ],
      CropFamily.leafy => const [
          'несправжня борошниста роса',
          'плямистості листя',
          'кореневі гнилі',
        ],
      CropFamily.grass => const [
          'сажкові хвороби',
          'фузаріоз',
          'плямистості листя',
        ],
      CropFamily.other => const [
          'кореневі гнилі',
          'плямистості листя',
        ],
    };

String plantProtectionGuidanceFor(Crop crop) {
  final watchFor = switch (crop.family) {
    CropFamily.nightshade =>
      'Оглядайте листя й плоди на плями, попелиць та пошкодження комахами.',
    CropFamily.cucurbit =>
      'Перевіряйте нижній бік листків, наліт, плями та ознаки сисних шкідників.',
    CropFamily.brassica =>
      'Оглядайте нижній бік листків на яйця, гусінь і дрібні отвори.',
    CropFamily.allium =>
      'Стежте за пожовтінням, деформацією листя, трипсами та ознаками гнилі.',
    CropFamily.apiaceae =>
      'Оглядайте листя й кореневу шийку на плями, личинки та в’янення.',
    _ =>
      'Регулярно оглядайте листя, стебла й ґрунт на шкідників або ознаки хвороб.',
  };
  return '$watchFor Спочатку визначте причину й застосуйте механічні або біологічні методи, де це можливо. Хімічний засіб використовуйте лише якщо він дозволений для цієї культури: точно за етикеткою, у захисному одязі та з дотриманням строку очікування до збору.';
}

String cropFamilyLabel(CropFamily family) {
  switch (family) {
    case CropFamily.nightshade:
      return 'пасльонові';
    case CropFamily.cucurbit:
      return 'гарбузові';
    case CropFamily.apiaceae:
      return 'зонтичні';
    case CropFamily.legume:
      return 'бобові';
    case CropFamily.brassica:
      return 'капустяні';
    case CropFamily.allium:
      return 'цибулеві';
    case CropFamily.leafy:
      return 'листові';
    case CropFamily.grass:
      return 'злакові';
    case CropFamily.other:
      return 'інша родина';
  }
}

bool cropsBelongToSameFamily(Crop first, Crop second) {
  if (first.familyLatin.isNotEmpty && second.familyLatin.isNotEmpty) {
    return first.familyLatin.toLowerCase() == second.familyLatin.toLowerCase();
  }
  return first.family == second.family;
}

List<Crop> predecessorSuggestionsFor(
  Crop planned,
  List<Crop> catalog, {
  int limit = 6,
}) {
  const priorities = <CropFamily, List<CropFamily>>{
    CropFamily.nightshade: [
      CropFamily.legume,
      CropFamily.allium,
      CropFamily.leafy,
    ],
    CropFamily.cucurbit: [
      CropFamily.legume,
      CropFamily.leafy,
      CropFamily.allium,
    ],
    CropFamily.apiaceae: [
      CropFamily.legume,
      CropFamily.brassica,
      CropFamily.leafy,
    ],
    CropFamily.legume: [
      CropFamily.brassica,
      CropFamily.allium,
      CropFamily.leafy,
    ],
    CropFamily.brassica: [
      CropFamily.legume,
      CropFamily.allium,
      CropFamily.nightshade,
    ],
    CropFamily.allium: [
      CropFamily.legume,
      CropFamily.cucurbit,
      CropFamily.leafy,
    ],
    CropFamily.leafy: [
      CropFamily.legume,
      CropFamily.apiaceae,
      CropFamily.allium,
    ],
    CropFamily.grass: [
      CropFamily.legume,
      CropFamily.brassica,
      CropFamily.allium,
    ],
    CropFamily.other: [
      CropFamily.legume,
      CropFamily.allium,
      CropFamily.leafy,
    ],
  };
  final preferred = priorities[planned.family] ?? const <CropFamily>[];
  final candidates =
      catalog.where((crop) => !cropsBelongToSameFamily(crop, planned)).toList();
  candidates.sort((a, b) {
    int rank(Crop crop) {
      final index = preferred.indexOf(crop.family);
      return index == -1 ? preferred.length + 1 : index;
    }

    final rankCompare = rank(a).compareTo(rank(b));
    return rankCompare != 0 ? rankCompare : a.name.compareTo(b.name);
  });
  return candidates.take(limit).toList();
}

List<Crop> sameFamilyCropsFor(Crop crop, List<Crop> catalog) {
  final matches = catalog
      .where((candidate) => cropsBelongToSameFamily(candidate, crop))
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));
  return matches;
}

List<Crop> rotationSuggestionsFor(
  Crop harvested,
  List<Crop> catalog, {
  int limit = 3,
  DateTime? afterHarvest,
}) {
  const priorities = <CropFamily, List<CropFamily>>{
    CropFamily.nightshade: [
      CropFamily.legume,
      CropFamily.leafy,
      CropFamily.allium,
    ],
    CropFamily.cucurbit: [
      CropFamily.legume,
      CropFamily.allium,
      CropFamily.leafy,
    ],
    CropFamily.apiaceae: [
      CropFamily.legume,
      CropFamily.brassica,
      CropFamily.leafy,
    ],
    CropFamily.legume: [
      CropFamily.brassica,
      CropFamily.nightshade,
      CropFamily.cucurbit,
    ],
    CropFamily.brassica: [
      CropFamily.legume,
      CropFamily.allium,
      CropFamily.nightshade,
    ],
    CropFamily.allium: [
      CropFamily.legume,
      CropFamily.cucurbit,
      CropFamily.leafy,
    ],
    CropFamily.leafy: [
      CropFamily.legume,
      CropFamily.apiaceae,
      CropFamily.allium,
    ],
  };

  final preferred = priorities[harvested.family] ?? const <CropFamily>[];
  final candidates = catalog
      .where((crop) => !cropsBelongToSameFamily(crop, harvested))
      .toList();
  candidates.sort((a, b) {
    int seasonRank(Crop crop) {
      if (afterHarvest == null) return 0;
      final order = switch (afterHarvest.month) {
        >= 3 && <= 5 => const [
            Season.spring,
            Season.summer,
            Season.autumn,
            Season.winter,
          ],
        >= 6 && <= 7 => const [
            Season.summer,
            Season.autumn,
            Season.spring,
            Season.winter,
          ],
        >= 8 && <= 11 => const [
            Season.autumn,
            Season.spring,
            Season.summer,
            Season.winter,
          ],
        _ => const [
            Season.spring,
            Season.winter,
            Season.summer,
            Season.autumn,
          ],
      };
      return order.indexOf(crop.season);
    }

    int rank(Crop crop) {
      final index = preferred.indexOf(crop.family);
      return index == -1 ? preferred.length + 1 : index;
    }

    final seasonCompare = seasonRank(a).compareTo(seasonRank(b));
    if (seasonCompare != 0) return seasonCompare;
    final rankCompare = rank(a).compareTo(rank(b));
    return rankCompare != 0 ? rankCompare : a.name.compareTo(b.name);
  });
  return candidates.take(limit).toList();
}
