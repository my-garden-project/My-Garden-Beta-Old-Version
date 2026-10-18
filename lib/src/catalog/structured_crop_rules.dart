import '../models.dart';

typedef _TimingSeed = ({
  int min,
  int max,
  TimingReferencePoint reference,
});

const _timings = <String, _TimingSeed>{
  'tomato': (min: 50, max: 100, reference: TimingReferencePoint.transplanting),
  'cucumber': (min: 45, max: 70, reference: TimingReferencePoint.sowing),
  'sweet_pepper': (
    min: 70,
    max: 120,
    reference: TimingReferencePoint.transplanting
  ),
  'eggplant': (
    min: 75,
    max: 120,
    reference: TimingReferencePoint.transplanting
  ),
  'potato': (min: 60, max: 130, reference: TimingReferencePoint.planting),
  'carrot': (min: 70, max: 130, reference: TimingReferencePoint.sowing),
  'beetroot': (min: 55, max: 100, reference: TimingReferencePoint.sowing),
  'radish': (min: 22, max: 50, reference: TimingReferencePoint.sowing),
  'turnip': (min: 40, max: 70, reference: TimingReferencePoint.sowing),
  'parsnip': (min: 110, max: 150, reference: TimingReferencePoint.sowing),
  'root_parsley': (min: 100, max: 160, reference: TimingReferencePoint.sowing),
  'celeriac': (
    min: 120,
    max: 180,
    reference: TimingReferencePoint.transplanting
  ),
  'celery': (min: 100, max: 150, reference: TimingReferencePoint.transplanting),
  'onion': (min: 120, max: 180, reference: TimingReferencePoint.planting),
  'garlic': (min: 120, max: 300, reference: TimingReferencePoint.planting),
  'leek': (min: 120, max: 180, reference: TimingReferencePoint.transplanting),
  'chives': (min: 60, max: 90, reference: TimingReferencePoint.sowing),
  'white_cabbage': (
    min: 60,
    max: 150,
    reference: TimingReferencePoint.transplanting
  ),
  'red_cabbage': (
    min: 80,
    max: 150,
    reference: TimingReferencePoint.transplanting
  ),
  'savoy_cabbage': (
    min: 70,
    max: 140,
    reference: TimingReferencePoint.transplanting
  ),
  'cauliflower': (
    min: 55,
    max: 120,
    reference: TimingReferencePoint.transplanting
  ),
  'broccoli': (
    min: 55,
    max: 100,
    reference: TimingReferencePoint.transplanting
  ),
  'brussels_sprouts': (
    min: 120,
    max: 180,
    reference: TimingReferencePoint.transplanting
  ),
  'kale': (min: 55, max: 100, reference: TimingReferencePoint.transplanting),
  'kohlrabi': (min: 45, max: 80, reference: TimingReferencePoint.transplanting),
  'chinese_cabbage': (min: 55, max: 90, reference: TimingReferencePoint.sowing),
  'bok_choy': (min: 35, max: 60, reference: TimingReferencePoint.sowing),
  'lettuce': (min: 65, max: 130, reference: TimingReferencePoint.sowing),
  'spinach': (min: 35, max: 60, reference: TimingReferencePoint.sowing),
  'swiss_chard': (min: 50, max: 80, reference: TimingReferencePoint.sowing),
  'arugula': (min: 25, max: 50, reference: TimingReferencePoint.sowing),
  'sorrel': (min: 60, max: 90, reference: TimingReferencePoint.sowing),
  'dill': (min: 35, max: 70, reference: TimingReferencePoint.sowing),
  'leaf_parsley': (min: 70, max: 100, reference: TimingReferencePoint.sowing),
  'coriander': (min: 30, max: 60, reference: TimingReferencePoint.sowing),
  'basil': (min: 50, max: 90, reference: TimingReferencePoint.transplanting),
  'thyme': (min: 90, max: 120, reference: TimingReferencePoint.sowing),
  'oregano': (min: 90, max: 120, reference: TimingReferencePoint.sowing),
  'marjoram': (min: 90, max: 120, reference: TimingReferencePoint.sowing),
  'rosemary': (
    min: 120,
    max: 180,
    reference: TimingReferencePoint.transplanting
  ),
  'peppermint': (min: 60, max: 90, reference: TimingReferencePoint.planting),
  'sage': (min: 90, max: 120, reference: TimingReferencePoint.sowing),
  'pea': (min: 55, max: 90, reference: TimingReferencePoint.sowing),
  'common_bean': (min: 45, max: 75, reference: TimingReferencePoint.sowing),
  'fava_bean': (min: 80, max: 120, reference: TimingReferencePoint.sowing),
  'zucchini': (min: 45, max: 70, reference: TimingReferencePoint.sowing),
  'pumpkin': (min: 90, max: 140, reference: TimingReferencePoint.sowing),
  'butternut_squash': (
    min: 100,
    max: 150,
    reference: TimingReferencePoint.sowing
  ),
  'watermelon': (
    min: 75,
    max: 120,
    reference: TimingReferencePoint.transplanting
  ),
  'melon': (min: 70, max: 110, reference: TimingReferencePoint.transplanting),
};

List<CropStageTiming> structuredStageTimingsFor(
  String slug,
  List<String> sourceUrls,
) {
  final value = _timings[slug];
  if (value == null) return const [];
  final result = <CropStageTiming>[
    CropStageTiming(
      stage: RecommendationStage.maturity,
      daysMin: value.min,
      daysMax: value.max,
      referencePoint: value.reference,
      regionalAdjustmentDays: const {
        AgroclimaticZone.polissia: 5,
        AgroclimaticZone.carpathian: 7,
        AgroclimaticZone.steppe: -3,
      },
      formulaVersion: 'catalog-2026.08-v1',
      sourceUrls: sourceUrls,
    ),
  ];
  if (slug == 'tomato') {
    result.add(
      CropStageTiming(
        stage: RecommendationStage.maturity,
        daysMin: 100,
        daysMax: 120,
        referencePoint: TimingReferencePoint.sowing,
        regionalAdjustmentDays: const {
          AgroclimaticZone.polissia: 5,
          AgroclimaticZone.carpathian: 7,
          AgroclimaticZone.steppe: -3,
        },
        formulaVersion: 'catalog-2026.08-v1',
        sourceUrls: sourceUrls,
      ),
    );
  }
  return result;
}

List<SpacingRule> structuredSpacingRulesFor(
  String slug,
  List<String> sourceUrls,
) =>
    switch (slug) {
      'tomato' => [
          SpacingRule(
            gardenType: GardenType.vegetableGarden,
            plantMinCm: 45,
            plantMaxCm: 60,
            rowMinCm: 90,
            rowMaxCm: 120,
            growingMethod: 'Відкритий ґрунт, ручний догляд',
            sourceUrls: sourceUrls,
          ),
          SpacingRule(
            gardenType: GardenType.field,
            plantMinCm: 45,
            plantMaxCm: 60,
            rowMinCm: 120,
            rowMaxCm: 185,
            growingMethod: 'Поле з технологічним проходом',
            sourceUrls: sourceUrls,
          ),
        ],
      'potato' => [
          SpacingRule(
            gardenType: GardenType.vegetableGarden,
            plantMinCm: 25,
            plantMaxCm: 35,
            rowMinCm: 50,
            rowMaxCm: 60,
            growingMethod: 'Город, ручне підгортання',
            sourceUrls: sourceUrls,
          ),
          SpacingRule(
            gardenType: GardenType.field,
            plantMinCm: 25,
            plantMaxCm: 35,
            rowMinCm: 70,
            rowMaxCm: 90,
            growingMethod: 'Поле; остаточне міжряддя визначає техніка',
            sourceUrls: sourceUrls,
          ),
        ],
      'white_cabbage' => [
          SpacingRule(
            gardenType: GardenType.vegetableGarden,
            plantMinCm: 40,
            plantMaxCm: 60,
            rowMinCm: 50,
            rowMaxCm: 75,
            growingMethod: 'Город',
            sourceUrls: sourceUrls,
          ),
          SpacingRule(
            gardenType: GardenType.field,
            plantMinCm: 40,
            plantMaxCm: 60,
            rowMinCm: 70,
            rowMaxCm: 90,
            growingMethod: 'Поле; з урахуванням технологічного проходу',
            sourceUrls: sourceUrls,
          ),
        ],
      _ => const [],
    };

List<WateringRule> structuredWateringRulesFor(
  String recommendation,
  List<String> sourceUrls,
) =>
    [
      WateringRule(
        gardenTypes: const {
          GardenType.vegetableGarden,
          GardenType.greenhouse,
        },
        soilTypes: const {SoilType.sandy, SoilType.sandyLoam},
        checkIntervalDays: 1,
        recommendation:
            '$recommendation Супіщаний або піщаний ґрунт висихає швидше: '
            'перевіряйте вологість частіше й поливайте меншими порціями.',
        sourceUrls: sourceUrls,
      ),
      WateringRule(
        gardenTypes: const {
          GardenType.vegetableGarden,
          GardenType.greenhouse,
        },
        soilTypes: const {SoilType.clay, SoilType.peat},
        checkIntervalDays: 3,
        recommendation:
            '$recommendation Вологоємний ґрунт просихає повільніше: '
            'перед поливом перевіряйте шар нижче поверхні та не допускайте '
            'застою води.',
        sourceUrls: sourceUrls,
      ),
      WateringRule(
        gardenTypes: const {GardenType.field},
        checkIntervalDays: 3,
        recommendation:
            '$recommendation Для поля оцінюйте вологість у кількох точках, '
            'враховуйте опади та не переносіть норму з однієї грядки на всю '
            'площу без перевірки.',
        sourceUrls: sourceUrls,
      ),
    ];

List<ProtectionRisk> structuredProtectionRisksFor({
  required String slug,
  required CropFamily family,
  required Iterable<String> diseases,
  required List<String> sourceUrls,
}) {
  final uniqueDiseases = <String>{
    for (final disease in diseases)
      if (disease.trim().isNotEmpty) disease.trim(),
  };
  final risks = [
    for (final disease in uniqueDiseases)
      ProtectionRisk(
        name: disease,
        type: ProtectionRiskType.disease,
        signs: const [
          'плями, наліт, в’янення або гниль, яких не було раніше',
        ],
        prevention: const [
          'сівозміна, чистий матеріал, провітрювання та полив під корінь',
        ],
        actions: const [
          ProtectionAction(
            title: 'Підтвердити причину',
            action: 'Ізолюйте уражену частину й уточніть діагноз до обробки.',
            allowedProductType: PlantProtectionCategory.fungicide,
            safetyRules: [
              'Застосовуйте лише засіб, дозволений для культури й ризику.',
              'Дотримуйтеся етикетки та строку очікування.',
            ],
          ),
        ],
        sourceUrls: sourceUrls,
      ),
  ];
  final pest = switch (slug) {
    'potato' => 'Колорадський жук',
    'tomato' => 'Попелиця, совки та кліщі',
    _ when family == CropFamily.brassica => 'Гусінь, попелиця та білокрилка',
    _ when family == CropFamily.allium => 'Трипси та цибулева муха',
    _ => 'Типові сисні та листогризучі шкідники',
  };
  risks.add(
    ProtectionRisk(
      name: pest,
      type: ProtectionRiskType.pest,
      signs: const ['яйця, личинки, липкий наліт, проколи або об’їдене листя'],
      prevention: const [
        'регулярний огляд нижнього боку листків, бар’єри й видалення уражених частин',
      ],
      actions: const [
        ProtectionAction(
          title: 'Почати з безпечнішого методу',
          action: 'Зберіть шкідників механічно або застосуйте доречний '
              'біологічний метод; препарат — лише після підтвердження виду.',
          allowedProductType: PlantProtectionCategory.insecticide,
          safetyRules: [
            'Не обробляйте квітучі рослини під час льоту запилювачів.',
            'Перевірте дозволену культуру, дозу та строк очікування.',
          ],
        ),
      ],
      sourceUrls: sourceUrls,
    ),
  );
  return risks;
}
