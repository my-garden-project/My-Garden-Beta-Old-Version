import 'dart:convert';
import 'dart:math' as math;

String generateId() => DateTime.now().microsecondsSinceEpoch.toString();

enum Season { spring, summer, autumn, winter }

enum AreaUnit { squareMeters, sotkas, hectares }

enum GardenSizeMode { area, dimensions }

enum GardenType { vegetableGarden, orchard, greenhouse, field }

enum SoilType {
  chernozem,
  sandy,
  sandyLoam,
  clay,
  loam,
  peat,
  other,
  unknown,
}

enum AgroclimaticZone {
  polissia,
  forestSteppe,
  steppe,
  carpathian,
  crimeanMountains,
  unknown,
}

enum WeatherSource { none, openMeteo }

enum GardenZoneType { bed, row, area, greenhouse, path, other }

enum InventoryItemType { seeds, fertilizer, plantProtection }

enum SeedVarietyType { unknown, variety, hybrid }

enum SeedMaturityGroup { unknown, early, midSeason, late }

/// How a crop entered the garden.  Kept separately from the date so a
/// potato planting is not presented to the user as a seed sowing.
enum PlantingEventType { sowing, planting, transplanting }

/// A user-visible lifecycle state.  Historical records without this field are
/// migrated from their dates in [Planting.fromJson].
enum PlantingStatus { planned, planted, maturing, harvested }

enum ReminderType {
  watering,
  inspection,
  maturity,
  harvest,
  protection,
  fertilization,
  general,
}

enum ReminderStatus { scheduled, completed, skipped }

enum ReminderSource { user, careRule, plantingForecast, system }

enum RecommendationStage {
  soilPreparation,
  sowing,
  planting,
  transplanting,
  care,
  maturity,
  harvest,
  protection,
  fertilization,
}

enum TimingReferencePoint { sowing, planting, transplanting }

enum ProtectionRiskType { disease, pest, weed }

enum PlantProtectionCategory {
  fungicide,
  insecticide,
  herbicide,
  otherPlantProtection,
}

enum CropFamily {
  nightshade,
  cucurbit,
  apiaceae,
  legume,
  brassica,
  allium,
  leafy,
  grass,
  other,
}

AreaUnit areaUnitFromString(String value) => AreaUnit.values.firstWhere(
      (unit) => unit.name == value,
      orElse: () => AreaUnit.squareMeters,
    );

GardenSizeMode gardenSizeModeFromString(String value) =>
    GardenSizeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => GardenSizeMode.dimensions,
    );

CropFamily cropFamilyFromString(String value) => CropFamily.values.firstWhere(
      (family) => family.name == value,
      orElse: () => CropFamily.other,
    );

GardenType gardenTypeFromString(String value) => GardenType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => GardenType.vegetableGarden,
    );

SoilType soilTypeFromString(String value) => SoilType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => SoilType.unknown,
    );

GardenZoneType gardenZoneTypeFromString(String value) =>
    GardenZoneType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => GardenZoneType.area,
    );

String gardenTypeLabel(GardenType type) => switch (type) {
      GardenType.vegetableGarden => 'Город',
      GardenType.orchard => 'Сад',
      GardenType.greenhouse => 'Теплиця',
      GardenType.field => 'Поле',
    };

String soilTypeLabel(SoilType type) => switch (type) {
      SoilType.chernozem => 'Чорнозем',
      SoilType.sandy => 'Піщаний',
      SoilType.sandyLoam => 'Супіщаний',
      SoilType.clay => 'Глинистий',
      SoilType.loam => 'Суглинок',
      SoilType.peat => 'Торф’яний',
      SoilType.other => 'Інший',
      SoilType.unknown => 'Не знаю',
    };

String agroclimaticZoneLabel(AgroclimaticZone zone) => switch (zone) {
      AgroclimaticZone.polissia => 'Полісся',
      AgroclimaticZone.forestSteppe => 'Лісостеп',
      AgroclimaticZone.steppe => 'Степ',
      AgroclimaticZone.carpathian => 'Карпатська',
      AgroclimaticZone.crimeanMountains => 'Кримська гірська',
      AgroclimaticZone.unknown => 'Не визначено',
    };

AgroclimaticZone agroclimaticZoneFromString(String value) =>
    AgroclimaticZone.values.firstWhere(
      (zone) => zone.name == value,
      orElse: () => AgroclimaticZone.unknown,
    );

String weatherSourceLabel(WeatherSource source) => switch (source) {
      WeatherSource.none => 'Не підключено',
      WeatherSource.openMeteo => 'Open-Meteo',
    };

String plantProtectionCategoryLabel(PlantProtectionCategory category) =>
    switch (category) {
      PlantProtectionCategory.fungicide => 'Фунгіцид',
      PlantProtectionCategory.insecticide => 'Інсектицид',
      PlantProtectionCategory.herbicide => 'Гербіцид',
      PlantProtectionCategory.otherPlantProtection => 'Інший засіб захисту',
    };

WeatherSource weatherSourceFromString(String value) =>
    WeatherSource.values.firstWhere(
      (source) => source.name == value,
      orElse: () => WeatherSource.none,
    );

String gardenZoneTypeLabel(GardenZoneType type) => switch (type) {
      GardenZoneType.bed => 'Грядка',
      GardenZoneType.row => 'Ряд',
      GardenZoneType.area => 'Зона',
      GardenZoneType.greenhouse => 'Теплиця',
      GardenZoneType.path => 'Доріжка',
      GardenZoneType.other => 'Інша область',
    };

InventoryItemType inventoryItemTypeFromString(String value) =>
    InventoryItemType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => InventoryItemType.seeds,
    );

String inventoryItemTypeLabel(InventoryItemType type) => switch (type) {
      InventoryItemType.seeds => 'Насіння',
      InventoryItemType.fertilizer => 'Добриво',
      InventoryItemType.plantProtection => 'Захист рослин',
    };

SeedVarietyType seedVarietyTypeFromString(String value) =>
    SeedVarietyType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => SeedVarietyType.unknown,
    );

PlantingEventType plantingEventTypeFromString(String value) =>
    PlantingEventType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => PlantingEventType.planting,
    );

PlantingStatus plantingStatusFromString(String value) =>
    PlantingStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => PlantingStatus.planned,
    );

String plantingEventTypeLabel(PlantingEventType type) => switch (type) {
      PlantingEventType.sowing => 'Посів',
      PlantingEventType.planting => 'Посадка',
      PlantingEventType.transplanting => 'Висаджування розсади',
    };

String plantingStatusLabel(PlantingStatus status) => switch (status) {
      PlantingStatus.planned => 'Заплановано',
      PlantingStatus.planted => 'Посаджено',
      PlantingStatus.maturing => 'Дозріває',
      PlantingStatus.harvested => 'Зібрано',
    };

PlantingEventType defaultPlantingEventTypeFor(Crop crop) {
  if (crop.slug == 'potato' || crop.name.trim().toLowerCase() == 'картопля') {
    return PlantingEventType.planting;
  }
  return crop.transplantingUkraine.trim().isNotEmpty
      ? PlantingEventType.transplanting
      : PlantingEventType.sowing;
}

SeedMaturityGroup seedMaturityGroupFromString(String value) =>
    SeedMaturityGroup.values.firstWhere(
      (group) => group.name == value,
      orElse: () => SeedMaturityGroup.unknown,
    );

String seedVarietyTypeLabel(SeedVarietyType type) => switch (type) {
      SeedVarietyType.unknown => 'Не вказано',
      SeedVarietyType.variety => 'Сорт',
      SeedVarietyType.hybrid => 'Гібрид F1',
    };

String seedMaturityGroupLabel(SeedMaturityGroup group) => switch (group) {
      SeedMaturityGroup.unknown => 'Не вказано',
      SeedMaturityGroup.early => 'Ранній',
      SeedMaturityGroup.midSeason => 'Середній',
      SeedMaturityGroup.late => 'Пізній',
    };

String areaUnitLabel(AreaUnit unit) {
  switch (unit) {
    case AreaUnit.squareMeters:
      return 'м²';
    case AreaUnit.sotkas:
      return 'соток';
    case AreaUnit.hectares:
      return 'га';
  }
}

double areaToSquareMeters(double value, AreaUnit unit) {
  switch (unit) {
    case AreaUnit.squareMeters:
      return value;
    case AreaUnit.sotkas:
      return value * 100;
    case AreaUnit.hectares:
      return value * 10000;
  }
}

double areaFromSquareMeters(double squareMeters, AreaUnit unit) {
  switch (unit) {
    case AreaUnit.squareMeters:
      return squareMeters;
    case AreaUnit.sotkas:
      return squareMeters / 100;
    case AreaUnit.hectares:
      return squareMeters / 10000;
  }
}

String formatArea(double squareMeters, AreaUnit unit) {
  final value = areaFromSquareMeters(squareMeters, unit);
  final precision = switch (unit) {
    AreaUnit.squareMeters => value >= 100 ? 0 : 1,
    AreaUnit.sotkas => value >= 100 ? 0 : 1,
    AreaUnit.hectares => value >= 10 ? 1 : 2,
  };
  var formatted = value.toStringAsFixed(precision);
  formatted = formatted.replaceFirst(RegExp(r'([.,]0+)$'), '');
  return '${formatted.replaceAll('.', ',')} ${areaUnitLabel(unit)}';
}

CropFamily cropFamilyForName(String name) {
  switch (name.trim().toLowerCase()) {
    case 'томат':
    case 'помідор':
    case 'картопля':
    case 'перець':
    case 'баклажан':
      return CropFamily.nightshade;
    case 'огірок':
    case 'гарбуз':
    case 'кабачок':
    case 'диня':
      return CropFamily.cucurbit;
    case 'морква':
    case 'селера':
    case 'пастернак':
      return CropFamily.apiaceae;
    case 'квасоля':
    case 'горох':
    case 'сочевиця':
      return CropFamily.legume;
    case 'капуста':
    case 'броколі':
    case 'редис':
      return CropFamily.brassica;
    case 'цибуля':
    case 'часник':
    case 'порей':
      return CropFamily.allium;
    case 'салат':
    case 'шпинат':
      return CropFamily.leafy;
    case 'кукурудза':
    case 'овес':
    case 'жито':
      return CropFamily.grass;
    default:
      return CropFamily.other;
  }
}

Season seasonFromString(String s) =>
    Season.values.firstWhere((e) => e.name == s, orElse: () => Season.spring);

String seasonName(Season s) {
  switch (s) {
    case Season.spring:
      return 'весна';
    case Season.summer:
      return 'літо';
    case Season.autumn:
      return 'осінь';
    case Season.winter:
      return 'зима';
  }
}

class Region {
  final String countryCode;
  final String oblastCode;
  final String oblastName;
  final AgroclimaticZone agroclimaticZone;

  const Region({
    required this.countryCode,
    required this.oblastCode,
    required this.oblastName,
    required this.agroclimaticZone,
  });
}

class CropRecommendationRule {
  final String id;
  final String cropId;
  final RecommendationStage stage;
  final Set<GardenType> gardenTypes;
  final Set<SoilType> soilTypes;
  final Set<String> oblastCodes;
  final String weatherCondition;
  final String recommendation;
  final Map<String, num> values;
  final List<String> sourceUrls;
  final String reliability;
  final String checkedOn;
  final int version;

  const CropRecommendationRule({
    required this.id,
    required this.cropId,
    required this.stage,
    this.gardenTypes = const {},
    this.soilTypes = const {},
    this.oblastCodes = const {},
    this.weatherCondition = '',
    required this.recommendation,
    this.values = const {},
    this.sourceUrls = const [],
    this.reliability = 'medium',
    this.checkedOn = '',
    this.version = 1,
  });
}

class CropStageTiming {
  final RecommendationStage stage;
  final int daysMin;
  final int daysMax;
  final TimingReferencePoint referencePoint;
  final SeedMaturityGroup maturityGroup;
  final Map<AgroclimaticZone, int> regionalAdjustmentDays;
  final String formulaVersion;
  final List<String> sourceUrls;

  const CropStageTiming({
    required this.stage,
    required this.daysMin,
    required this.daysMax,
    required this.referencePoint,
    this.maturityGroup = SeedMaturityGroup.unknown,
    this.regionalAdjustmentDays = const {},
    this.formulaVersion = '1',
    this.sourceUrls = const [],
  });

  Map<String, dynamic> toJson() => {
        'stage': stage.name,
        'daysMin': daysMin,
        'daysMax': daysMax,
        'referencePoint': referencePoint.name,
        'maturityGroup': maturityGroup.name,
        'regionalAdjustmentDays': {
          for (final entry in regionalAdjustmentDays.entries)
            entry.key.name: entry.value,
        },
        'formulaVersion': formulaVersion,
        'sourceUrls': sourceUrls,
      };

  factory CropStageTiming.fromJson(Map<String, dynamic> json) =>
      CropStageTiming(
        stage: RecommendationStage.values.firstWhere(
          (stage) => stage.name == json['stage'],
          orElse: () => RecommendationStage.maturity,
        ),
        daysMin: (json['daysMin'] as num).toInt(),
        daysMax: (json['daysMax'] as num).toInt(),
        referencePoint: TimingReferencePoint.values.firstWhere(
          (point) => point.name == json['referencePoint'],
          orElse: () => TimingReferencePoint.planting,
        ),
        maturityGroup: seedMaturityGroupFromString(
          json['maturityGroup'] as String? ?? 'unknown',
        ),
        regionalAdjustmentDays: {
          for (final entry
              in (json['regionalAdjustmentDays'] as Map? ?? {}).entries)
            agroclimaticZoneFromString(entry.key as String):
                (entry.value as num).toInt(),
        },
        formulaVersion: json['formulaVersion'] as String? ?? '1',
        sourceUrls: (json['sourceUrls'] as List? ?? const [])
            .whereType<String>()
            .toList(),
      );
}

class SpacingRule {
  final GardenType gardenType;
  final double plantMinCm;
  final double plantMaxCm;
  final double rowMinCm;
  final double rowMaxCm;
  final String growingMethod;
  final List<String> sourceUrls;
  final int version;

  const SpacingRule({
    required this.gardenType,
    required this.plantMinCm,
    required this.plantMaxCm,
    required this.rowMinCm,
    required this.rowMaxCm,
    this.growingMethod = '',
    this.sourceUrls = const [],
    this.version = 1,
  });

  Map<String, dynamic> toJson() => {
        'gardenType': gardenType.name,
        'plantMinCm': plantMinCm,
        'plantMaxCm': plantMaxCm,
        'rowMinCm': rowMinCm,
        'rowMaxCm': rowMaxCm,
        'growingMethod': growingMethod,
        'sourceUrls': sourceUrls,
        'version': version,
      };

  factory SpacingRule.fromJson(Map<String, dynamic> json) => SpacingRule(
        gardenType: gardenTypeFromString(
          json['gardenType'] as String? ?? 'vegetableGarden',
        ),
        plantMinCm: (json['plantMinCm'] as num).toDouble(),
        plantMaxCm: (json['plantMaxCm'] as num).toDouble(),
        rowMinCm: (json['rowMinCm'] as num).toDouble(),
        rowMaxCm: (json['rowMaxCm'] as num).toDouble(),
        growingMethod: json['growingMethod'] as String? ?? '',
        sourceUrls: (json['sourceUrls'] as List? ?? const [])
            .whereType<String>()
            .toList(),
        version: json['version'] as int? ?? 1,
      );
}

class WateringRule {
  final Set<GardenType> gardenTypes;
  final Set<SoilType> soilTypes;
  final RecommendationStage stage;
  final int checkIntervalDays;
  final String recommendation;
  final List<String> sourceUrls;
  final int version;

  const WateringRule({
    this.gardenTypes = const {},
    this.soilTypes = const {},
    this.stage = RecommendationStage.care,
    required this.checkIntervalDays,
    required this.recommendation,
    this.sourceUrls = const [],
    this.version = 1,
  });

  Map<String, dynamic> toJson() => {
        'gardenTypes': gardenTypes.map((type) => type.name).toList(),
        'soilTypes': soilTypes.map((type) => type.name).toList(),
        'stage': stage.name,
        'checkIntervalDays': checkIntervalDays,
        'recommendation': recommendation,
        'sourceUrls': sourceUrls,
        'version': version,
      };

  factory WateringRule.fromJson(Map<String, dynamic> json) => WateringRule(
        gardenTypes: (json['gardenTypes'] as List? ?? const [])
            .whereType<String>()
            .map(gardenTypeFromString)
            .toSet(),
        soilTypes: (json['soilTypes'] as List? ?? const [])
            .whereType<String>()
            .map(soilTypeFromString)
            .toSet(),
        stage: RecommendationStage.values.firstWhere(
          (stage) => stage.name == json['stage'],
          orElse: () => RecommendationStage.care,
        ),
        checkIntervalDays: json['checkIntervalDays'] as int? ?? 3,
        recommendation: json['recommendation'] as String? ?? '',
        sourceUrls: (json['sourceUrls'] as List? ?? const [])
            .whereType<String>()
            .toList(),
        version: json['version'] as int? ?? 1,
      );
}

class ProtectionAction {
  final String title;
  final String action;
  final PlantProtectionCategory? allowedProductType;
  final List<String> safetyRules;

  const ProtectionAction({
    required this.title,
    required this.action,
    this.allowedProductType,
    this.safetyRules = const [],
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'action': action,
        'allowedProductType': allowedProductType?.name,
        'safetyRules': safetyRules,
      };

  factory ProtectionAction.fromJson(Map<String, dynamic> json) =>
      ProtectionAction(
        title: json['title'] as String? ?? '',
        action: json['action'] as String? ?? '',
        allowedProductType: json['allowedProductType'] == null
            ? null
            : PlantProtectionCategory.values.firstWhere(
                (type) => type.name == json['allowedProductType'],
                orElse: () => PlantProtectionCategory.otherPlantProtection,
              ),
        safetyRules: (json['safetyRules'] as List? ?? const [])
            .whereType<String>()
            .toList(),
      );
}

class ProtectionRisk {
  final String name;
  final ProtectionRiskType type;
  final List<String> signs;
  final List<String> prevention;
  final List<ProtectionAction> actions;
  final List<String> sourceUrls;

  const ProtectionRisk({
    required this.name,
    required this.type,
    this.signs = const [],
    this.prevention = const [],
    this.actions = const [],
    this.sourceUrls = const [],
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type.name,
        'signs': signs,
        'prevention': prevention,
        'actions': actions.map((action) => action.toJson()).toList(),
        'sourceUrls': sourceUrls,
      };

  factory ProtectionRisk.fromJson(Map<String, dynamic> json) => ProtectionRisk(
        name: json['name'] as String? ?? '',
        type: ProtectionRiskType.values.firstWhere(
          (type) => type.name == json['type'],
          orElse: () => ProtectionRiskType.disease,
        ),
        signs:
            (json['signs'] as List? ?? const []).whereType<String>().toList(),
        prevention: (json['prevention'] as List? ?? const [])
            .whereType<String>()
            .toList(),
        actions: (json['actions'] as List? ?? const [])
            .whereType<Map>()
            .map((value) => ProtectionAction.fromJson(
                  Map<String, dynamic>.from(value),
                ))
            .toList(),
        sourceUrls: (json['sourceUrls'] as List? ?? const [])
            .whereType<String>()
            .toList(),
      );
}

class Crop {
  final String id;
  final String name;
  final String variety;
  final Season season;
  final CropFamily family;
  final String recommendation;
  final String catalogId;
  final String slug;
  final String namePl;
  final String nameEn;
  final String latinName;
  final String familyLatin;
  final String sowingUkraine;
  final String sowingPoland;
  final String transplantingUkraine;
  final String transplantingPoland;
  final String spacing;
  final String soilAndPh;
  final String watering;
  final String fertilization;
  final String maturity;
  final String harvest;
  final List<String> typicalDiseases;
  final List<String> diseaseSourceUrls;
  final int? minimumRotationYears;
  final String wikiUrl;
  final String wikidataUrl;
  final String catalogCheckedOn;
  final String catalogReliability;
  final List<CropStageTiming> stageTimings;
  final List<SpacingRule> spacingRules;
  final List<WateringRule> wateringRules;
  final List<ProtectionRisk> protectionRisks;

  const Crop({
    required this.id,
    required this.name,
    this.variety = '',
    this.season = Season.spring,
    this.family = CropFamily.other,
    this.recommendation = '',
    this.catalogId = '',
    this.slug = '',
    this.namePl = '',
    this.nameEn = '',
    this.latinName = '',
    this.familyLatin = '',
    this.sowingUkraine = '',
    this.sowingPoland = '',
    this.transplantingUkraine = '',
    this.transplantingPoland = '',
    this.spacing = '',
    this.soilAndPh = '',
    this.watering = '',
    this.fertilization = '',
    this.maturity = '',
    this.harvest = '',
    this.typicalDiseases = const [],
    this.diseaseSourceUrls = const [],
    this.minimumRotationYears,
    this.wikiUrl = '',
    this.wikidataUrl = '',
    this.catalogCheckedOn = '',
    this.catalogReliability = '',
    this.stageTimings = const [],
    this.spacingRules = const [],
    this.wateringRules = const [],
    this.protectionRisks = const [],
  });

  Crop withCatalogFrom(Crop catalogCrop) => Crop(
        id: id,
        name: name,
        variety: variety,
        season: season,
        family: catalogCrop.family,
        recommendation: recommendation.isNotEmpty
            ? recommendation
            : catalogCrop.recommendation,
        catalogId: catalogCrop.catalogId,
        slug: catalogCrop.slug,
        namePl: catalogCrop.namePl,
        nameEn: catalogCrop.nameEn,
        latinName: catalogCrop.latinName,
        familyLatin: catalogCrop.familyLatin,
        sowingUkraine: catalogCrop.sowingUkraine,
        sowingPoland: catalogCrop.sowingPoland,
        transplantingUkraine: catalogCrop.transplantingUkraine,
        transplantingPoland: catalogCrop.transplantingPoland,
        spacing: catalogCrop.spacing,
        soilAndPh: catalogCrop.soilAndPh,
        watering: catalogCrop.watering,
        fertilization: catalogCrop.fertilization,
        maturity: catalogCrop.maturity,
        harvest: catalogCrop.harvest,
        typicalDiseases: catalogCrop.typicalDiseases,
        diseaseSourceUrls: catalogCrop.diseaseSourceUrls,
        minimumRotationYears: catalogCrop.minimumRotationYears,
        wikiUrl: catalogCrop.wikiUrl,
        wikidataUrl: catalogCrop.wikidataUrl,
        catalogCheckedOn: catalogCrop.catalogCheckedOn,
        catalogReliability: catalogCrop.catalogReliability,
        stageTimings: catalogCrop.stageTimings,
        spacingRules: catalogCrop.spacingRules,
        wateringRules: catalogCrop.wateringRules,
        protectionRisks: catalogCrop.protectionRisks,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'variety': variety,
        'season': season.name,
        'family': family.name,
        'recommendation': recommendation,
        'catalogId': catalogId,
        'slug': slug,
        'namePl': namePl,
        'nameEn': nameEn,
        'latinName': latinName,
        'familyLatin': familyLatin,
        'sowingUkraine': sowingUkraine,
        'sowingPoland': sowingPoland,
        'transplantingUkraine': transplantingUkraine,
        'transplantingPoland': transplantingPoland,
        'spacing': spacing,
        'soilAndPh': soilAndPh,
        'watering': watering,
        'fertilization': fertilization,
        'maturity': maturity,
        'harvest': harvest,
        'typicalDiseases': typicalDiseases,
        'diseaseSourceUrls': diseaseSourceUrls,
        'minimumRotationYears': minimumRotationYears,
        'wikiUrl': wikiUrl,
        'wikidataUrl': wikidataUrl,
        'catalogCheckedOn': catalogCheckedOn,
        'catalogReliability': catalogReliability,
        'stageTimings': stageTimings.map((rule) => rule.toJson()).toList(),
        'spacingRules': spacingRules.map((rule) => rule.toJson()).toList(),
        'wateringRules': wateringRules.map((rule) => rule.toJson()).toList(),
        'protectionRisks':
            protectionRisks.map((risk) => risk.toJson()).toList(),
      };

  factory Crop.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String;
    return Crop(
      id: json['id'] as String,
      name: name,
      variety: (json['variety'] ?? '') as String,
      season: seasonFromString((json['season'] ?? 'spring') as String),
      family: json['family'] == null
          ? cropFamilyForName(name)
          : cropFamilyFromString(json['family'] as String),
      recommendation: (json['recommendation'] ?? '') as String,
      catalogId: (json['catalogId'] ?? '') as String,
      slug: (json['slug'] ?? '') as String,
      namePl: (json['namePl'] ?? '') as String,
      nameEn: (json['nameEn'] ?? '') as String,
      latinName: (json['latinName'] ?? '') as String,
      familyLatin: (json['familyLatin'] ?? '') as String,
      sowingUkraine: (json['sowingUkraine'] ?? '') as String,
      sowingPoland: (json['sowingPoland'] ?? '') as String,
      transplantingUkraine: (json['transplantingUkraine'] ?? '') as String,
      transplantingPoland: (json['transplantingPoland'] ?? '') as String,
      spacing: (json['spacing'] ?? '') as String,
      soilAndPh: (json['soilAndPh'] ?? '') as String,
      watering: (json['watering'] ?? '') as String,
      fertilization: (json['fertilization'] ?? '') as String,
      maturity: (json['maturity'] ?? '') as String,
      harvest: (json['harvest'] ?? '') as String,
      typicalDiseases: (json['typicalDiseases'] as List? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      diseaseSourceUrls: (json['diseaseSourceUrls'] as List? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      minimumRotationYears: json['minimumRotationYears'] as int?,
      wikiUrl: (json['wikiUrl'] ?? '') as String,
      wikidataUrl: (json['wikidataUrl'] ?? '') as String,
      catalogCheckedOn: (json['catalogCheckedOn'] ?? '') as String,
      catalogReliability: (json['catalogReliability'] ?? '') as String,
      stageTimings: (json['stageTimings'] as List? ?? const [])
          .whereType<Map>()
          .map((value) => CropStageTiming.fromJson(
                Map<String, dynamic>.from(value),
              ))
          .toList(),
      spacingRules: (json['spacingRules'] as List? ?? const [])
          .whereType<Map>()
          .map((value) => SpacingRule.fromJson(
                Map<String, dynamic>.from(value),
              ))
          .toList(),
      wateringRules: (json['wateringRules'] as List? ?? const [])
          .whereType<Map>()
          .map((value) => WateringRule.fromJson(
                Map<String, dynamic>.from(value),
              ))
          .toList(),
      protectionRisks: (json['protectionRisks'] as List? ?? const [])
          .whereType<Map>()
          .map((value) => ProtectionRisk.fromJson(
                Map<String, dynamic>.from(value),
              ))
          .toList(),
    );
  }
}

List<Crop> builtInCrops() => const [
      Crop(
        id: 'crop_tomato',
        name: 'Томат',
        variety: 'Детермінантний',
        season: Season.summer,
        family: CropFamily.nightshade,
        recommendation: 'Рівномірна волога, мульча та підв’язування.',
      ),
      Crop(
        id: 'crop_cucumber',
        name: 'Огірок',
        variety: 'Партенокарпічний',
        season: Season.summer,
        family: CropFamily.cucurbit,
        recommendation: 'Стабільна волога, мульча та регулярний збір.',
      ),
      Crop(
        id: 'crop_carrot',
        name: 'Морква',
        variety: 'Нантська',
        season: Season.spring,
        family: CropFamily.apiaceae,
        recommendation:
            'Вологий верхній шар до сходів і своєчасне проріджування.',
      ),
      Crop(
        id: 'crop_bean',
        name: 'Квасоля',
        season: Season.summer,
        family: CropFamily.legume,
        recommendation: 'Полив під час цвітіння та формування стручків.',
      ),
      Crop(
        id: 'crop_pea',
        name: 'Горох',
        season: Season.spring,
        family: CropFamily.legume,
        recommendation: 'Опора, рівномірна волога й частий збір.',
      ),
      Crop(
        id: 'crop_cabbage',
        name: 'Капуста',
        season: Season.spring,
        family: CropFamily.brassica,
        recommendation: 'Стабільна волога під час формування головки.',
      ),
      Crop(
        id: 'crop_onion',
        name: 'Цибуля',
        season: Season.spring,
        family: CropFamily.allium,
        recommendation: 'Неглибокий, але регулярний полив до дозрівання.',
      ),
      Crop(
        id: 'crop_lettuce',
        name: 'Салат',
        season: Season.spring,
        family: CropFamily.leafy,
        recommendation: 'Прохолода, рівномірна волога та своєчасний збір.',
      ),
    ];

class Planting {
  static const Object _unset = Object();
  static const int maxVarietyLength = 80;
  static const int maxNoteLength = 500;

  final String id;
  final String gardenId;
  final String? cropId;
  final String? inventoryItemId;
  final String? zoneId;
  final int? row;
  final int? col;
  final String variety;
  final PlantingEventType eventType;
  final PlantingStatus status;
  final DateTime? plantedAt;
  final DateTime? expectedMaturityAt;
  final DateTime? expectedHarvestAt;
  final DateTime? actualMaturityAt;
  final DateTime? harvestedAt;
  final String timingRuleVersion;
  final String note;

  Planting({
    required this.id,
    required this.gardenId,
    this.cropId,
    this.inventoryItemId,
    this.zoneId,
    this.row,
    this.col,
    this.variety = '',
    this.eventType = PlantingEventType.planting,
    PlantingStatus? status,
    this.plantedAt,
    this.expectedMaturityAt,
    this.expectedHarvestAt,
    this.actualMaturityAt,
    this.harvestedAt,
    this.timingRuleVersion = '',
    this.note = '',
  }) : status = status ??
            (harvestedAt != null
                ? PlantingStatus.harvested
                : plantedAt == null
                    ? PlantingStatus.planned
                    : PlantingStatus.planted) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Planting id cannot be empty');
    }
    if (gardenId.trim().isEmpty) {
      throw ArgumentError.value(
        gardenId,
        'gardenId',
        'Garden id cannot be empty',
      );
    }
    if (cropId != null && cropId!.trim().isEmpty) {
      throw ArgumentError.value(cropId, 'cropId', 'Crop id cannot be empty');
    }
    if (inventoryItemId != null && inventoryItemId!.trim().isEmpty) {
      throw ArgumentError.value(
        inventoryItemId,
        'inventoryItemId',
        'Inventory item id cannot be empty',
      );
    }
    if (zoneId != null && zoneId!.trim().isEmpty) {
      throw ArgumentError.value(zoneId, 'zoneId', 'Zone id cannot be empty');
    }
    if ((row == null) != (col == null)) {
      throw ArgumentError('Planting row and column must be set together');
    }
    if (row != null && row! < 0) {
      throw RangeError.value(row!, 'row', 'Must be non-negative');
    }
    if (col != null && col! < 0) {
      throw RangeError.value(col!, 'col', 'Must be non-negative');
    }
    if (plantedAt != null &&
        actualMaturityAt != null &&
        actualMaturityAt!.isBefore(plantedAt!)) {
      throw ArgumentError.value(
        actualMaturityAt,
        'actualMaturityAt',
        'Actual maturity cannot be before planting',
      );
    }
    if (plantedAt != null &&
        harvestedAt != null &&
        harvestedAt!.isBefore(plantedAt!)) {
      throw ArgumentError.value(
        harvestedAt,
        'harvestedAt',
        'Harvest cannot be before planting',
      );
    }
    if (plantedAt != null &&
        expectedMaturityAt != null &&
        expectedMaturityAt!.isBefore(plantedAt!)) {
      throw ArgumentError.value(
        expectedMaturityAt,
        'expectedMaturityAt',
        'Expected maturity cannot be before planting',
      );
    }
    if (expectedMaturityAt != null &&
        expectedHarvestAt != null &&
        expectedHarvestAt!.isBefore(expectedMaturityAt!)) {
      throw ArgumentError.value(
        expectedHarvestAt,
        'expectedHarvestAt',
        'Expected harvest cannot be before maturity',
      );
    }
    if (variety.length > maxVarietyLength) {
      throw ArgumentError.value(variety, 'variety', 'Variety is too long');
    }
    if (note.length > maxNoteLength) {
      throw ArgumentError.value(note, 'note', 'Note is too long');
    }
  }

  Planting copyWith({
    Object? cropId = _unset,
    Object? inventoryItemId = _unset,
    Object? zoneId = _unset,
    Object? row = _unset,
    Object? col = _unset,
    String? variety,
    PlantingEventType? eventType,
    PlantingStatus? status,
    Object? plantedAt = _unset,
    Object? expectedMaturityAt = _unset,
    Object? expectedHarvestAt = _unset,
    Object? actualMaturityAt = _unset,
    Object? harvestedAt = _unset,
    String? timingRuleVersion,
    String? note,
  }) {
    return Planting(
      id: id,
      gardenId: gardenId,
      cropId: identical(cropId, _unset) ? this.cropId : cropId as String?,
      inventoryItemId: identical(inventoryItemId, _unset)
          ? this.inventoryItemId
          : inventoryItemId as String?,
      zoneId: identical(zoneId, _unset) ? this.zoneId : zoneId as String?,
      row: identical(row, _unset) ? this.row : row as int?,
      col: identical(col, _unset) ? this.col : col as int?,
      variety: variety ?? this.variety,
      eventType: eventType ?? this.eventType,
      status: status ?? this.status,
      plantedAt: identical(plantedAt, _unset)
          ? this.plantedAt
          : plantedAt as DateTime?,
      expectedMaturityAt: identical(expectedMaturityAt, _unset)
          ? this.expectedMaturityAt
          : expectedMaturityAt as DateTime?,
      expectedHarvestAt: identical(expectedHarvestAt, _unset)
          ? this.expectedHarvestAt
          : expectedHarvestAt as DateTime?,
      actualMaturityAt: identical(actualMaturityAt, _unset)
          ? this.actualMaturityAt
          : actualMaturityAt as DateTime?,
      harvestedAt: identical(harvestedAt, _unset)
          ? this.harvestedAt
          : harvestedAt as DateTime?,
      timingRuleVersion: timingRuleVersion ?? this.timingRuleVersion,
      note: note ?? this.note,
    );
  }

  bool get isHarvested =>
      status == PlantingStatus.harvested || harvestedAt != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'gardenId': gardenId,
        'cropId': cropId,
        'inventoryItemId': inventoryItemId,
        'zoneId': zoneId,
        'row': row,
        'col': col,
        'variety': variety,
        'eventType': eventType.name,
        'status': status.name,
        'plantedAt': plantedAt?.toIso8601String(),
        'expectedMaturityAt': expectedMaturityAt?.toIso8601String(),
        'expectedHarvestAt': expectedHarvestAt?.toIso8601String(),
        'actualMaturityAt': actualMaturityAt?.toIso8601String(),
        'harvestedAt': harvestedAt?.toIso8601String(),
        'timingRuleVersion': timingRuleVersion,
        'note': note,
      };

  factory Planting.fromJson(Map<String, dynamic> json) {
    final plantedAtValue = json['plantedAt'] as String?;
    final expectedMaturityAtValue = json['expectedMaturityAt'] as String?;
    final expectedHarvestAtValue = json['expectedHarvestAt'] as String?;
    final actualMaturityAtValue = json['actualMaturityAt'] as String?;
    final harvestedAtValue = json['harvestedAt'] as String?;
    return Planting(
      id: json['id'] as String,
      gardenId: json['gardenId'] as String,
      cropId: json['cropId'] as String?,
      inventoryItemId: json['inventoryItemId'] as String?,
      zoneId: json['zoneId'] as String?,
      row: json['row'] as int?,
      col: json['col'] as int?,
      variety: (json['variety'] ?? '') as String,
      eventType: plantingEventTypeFromString(
        json['eventType'] as String? ?? 'planting',
      ),
      status: json['status'] == null
          ? (harvestedAtValue != null
              ? PlantingStatus.harvested
              : plantedAtValue == null
                  ? PlantingStatus.planned
                  : PlantingStatus.planted)
          : plantingStatusFromString(json['status'] as String),
      plantedAt: plantedAtValue == null ? null : DateTime.parse(plantedAtValue),
      expectedMaturityAt: expectedMaturityAtValue == null
          ? null
          : DateTime.parse(expectedMaturityAtValue),
      expectedHarvestAt: expectedHarvestAtValue == null
          ? null
          : DateTime.parse(expectedHarvestAtValue),
      actualMaturityAt: actualMaturityAtValue == null
          ? null
          : DateTime.parse(actualMaturityAtValue),
      harvestedAt:
          harvestedAtValue == null ? null : DateTime.parse(harvestedAtValue),
      timingRuleVersion: json['timingRuleVersion'] as String? ?? '',
      note: (json['note'] ?? '') as String,
    );
  }
}

class InventoryItem {
  static const Object _unset = Object();
  static const int maxProductNameLength = 120;
  static const int maxBrandLength = 80;
  static const int maxInstructionsLength = 1000;
  static const int maxVarietyNameLength = 120;
  static const int maxResistanceClaimsLength = 300;

  final String id;
  final InventoryItemType type;
  final String barcode;
  final String productName;
  final String brand;
  final String? cropId;
  final String varietyName;
  final SeedVarietyType varietyType;
  final SeedMaturityGroup maturityGroup;
  final String resistanceClaims;
  final PlantProtectionCategory? protectionCategory;
  final List<String> allowedCropIds;
  final String activeIngredient;
  final int? waitingPeriodDays;
  final int? maxApplications;
  final double? minimumTemperatureC;
  final double? maximumTemperatureC;
  final DateTime? informationValidUntil;
  final double quantity;
  final String unit;
  final String instructions;
  final DateTime createdAt;

  InventoryItem({
    required this.id,
    required this.type,
    required this.productName,
    required this.createdAt,
    this.barcode = '',
    this.brand = '',
    this.cropId,
    this.varietyName = '',
    this.varietyType = SeedVarietyType.unknown,
    this.maturityGroup = SeedMaturityGroup.unknown,
    this.resistanceClaims = '',
    this.protectionCategory,
    this.allowedCropIds = const [],
    this.activeIngredient = '',
    this.waitingPeriodDays,
    this.maxApplications,
    this.minimumTemperatureC,
    this.maximumTemperatureC,
    this.informationValidUntil,
    this.quantity = 1,
    this.unit = 'пак.',
    this.instructions = '',
  }) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Inventory id cannot be empty');
    }
    if (productName.trim().isEmpty ||
        productName.length > maxProductNameLength) {
      throw ArgumentError.value(
        productName,
        'productName',
        'Invalid product name',
      );
    }
    if (brand.length > maxBrandLength) {
      throw ArgumentError.value(brand, 'brand', 'Brand is too long');
    }
    if (barcode.trim().length > 64) {
      throw ArgumentError.value(barcode, 'barcode', 'Barcode is too long');
    }
    if (cropId != null && cropId!.trim().isEmpty) {
      throw ArgumentError.value(cropId, 'cropId', 'Crop id cannot be empty');
    }
    if (varietyName.length > maxVarietyNameLength) {
      throw ArgumentError.value(
        varietyName,
        'varietyName',
        'Variety name is too long',
      );
    }
    if (resistanceClaims.length > maxResistanceClaimsLength) {
      throw ArgumentError.value(
        resistanceClaims,
        'resistanceClaims',
        'Resistance claims are too long',
      );
    }
    if (waitingPeriodDays != null && waitingPeriodDays! < 0) {
      throw RangeError.value(waitingPeriodDays!, 'waitingPeriodDays');
    }
    if (maxApplications != null && maxApplications! < 1) {
      throw RangeError.value(maxApplications!, 'maxApplications');
    }
    if (!quantity.isFinite || quantity < 0 || quantity > 1000000) {
      throw RangeError.value(quantity, 'quantity', 'Invalid quantity');
    }
    if (unit.trim().isEmpty || unit.length > 24) {
      throw ArgumentError.value(unit, 'unit', 'Invalid unit');
    }
    if (instructions.length > maxInstructionsLength) {
      throw ArgumentError.value(
        instructions,
        'instructions',
        'Instructions are too long',
      );
    }
  }

  InventoryItem copyWith({
    InventoryItemType? type,
    String? barcode,
    String? productName,
    String? brand,
    Object? cropId = _unset,
    String? varietyName,
    SeedVarietyType? varietyType,
    SeedMaturityGroup? maturityGroup,
    String? resistanceClaims,
    PlantProtectionCategory? protectionCategory,
    List<String>? allowedCropIds,
    String? activeIngredient,
    Object? waitingPeriodDays = _unset,
    Object? maxApplications = _unset,
    Object? minimumTemperatureC = _unset,
    Object? maximumTemperatureC = _unset,
    Object? informationValidUntil = _unset,
    double? quantity,
    String? unit,
    String? instructions,
  }) {
    return InventoryItem(
      id: id,
      type: type ?? this.type,
      barcode: barcode ?? this.barcode,
      productName: productName ?? this.productName,
      brand: brand ?? this.brand,
      cropId: identical(cropId, _unset) ? this.cropId : cropId as String?,
      varietyName: varietyName ?? this.varietyName,
      varietyType: varietyType ?? this.varietyType,
      maturityGroup: maturityGroup ?? this.maturityGroup,
      resistanceClaims: resistanceClaims ?? this.resistanceClaims,
      protectionCategory: protectionCategory ?? this.protectionCategory,
      allowedCropIds: allowedCropIds ?? this.allowedCropIds,
      activeIngredient: activeIngredient ?? this.activeIngredient,
      waitingPeriodDays: identical(waitingPeriodDays, _unset)
          ? this.waitingPeriodDays
          : waitingPeriodDays as int?,
      maxApplications: identical(maxApplications, _unset)
          ? this.maxApplications
          : maxApplications as int?,
      minimumTemperatureC: identical(minimumTemperatureC, _unset)
          ? this.minimumTemperatureC
          : minimumTemperatureC as double?,
      maximumTemperatureC: identical(maximumTemperatureC, _unset)
          ? this.maximumTemperatureC
          : maximumTemperatureC as double?,
      informationValidUntil: identical(informationValidUntil, _unset)
          ? this.informationValidUntil
          : informationValidUntil as DateTime?,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      instructions: instructions ?? this.instructions,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'barcode': barcode,
        'productName': productName,
        'brand': brand,
        'cropId': cropId,
        'varietyName': varietyName,
        'varietyType': varietyType.name,
        'maturityGroup': maturityGroup.name,
        'resistanceClaims': resistanceClaims,
        'protectionCategory': protectionCategory?.name,
        'allowedCropIds': allowedCropIds,
        'activeIngredient': activeIngredient,
        'waitingPeriodDays': waitingPeriodDays,
        'maxApplications': maxApplications,
        'minimumTemperatureC': minimumTemperatureC,
        'maximumTemperatureC': maximumTemperatureC,
        'informationValidUntil': informationValidUntil?.toIso8601String(),
        'quantity': quantity,
        'unit': unit,
        'instructions': instructions,
        'createdAt': createdAt.toIso8601String(),
      };

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
        id: json['id'] as String,
        type: inventoryItemTypeFromString(json['type'] as String? ?? 'seeds'),
        barcode: json['barcode'] as String? ?? '',
        productName: json['productName'] as String,
        brand: json['brand'] as String? ?? '',
        cropId: json['cropId'] as String?,
        varietyName: json['varietyName'] as String? ?? '',
        varietyType: seedVarietyTypeFromString(
          json['varietyType'] as String? ?? 'unknown',
        ),
        maturityGroup: seedMaturityGroupFromString(
          json['maturityGroup'] as String? ?? 'unknown',
        ),
        resistanceClaims: json['resistanceClaims'] as String? ?? '',
        protectionCategory: json['protectionCategory'] == null
            ? null
            : PlantProtectionCategory.values.firstWhere(
                (category) => category.name == json['protectionCategory'],
                orElse: () => PlantProtectionCategory.otherPlantProtection,
              ),
        allowedCropIds: (json['allowedCropIds'] as List? ?? const [])
            .whereType<String>()
            .toList(),
        activeIngredient: json['activeIngredient'] as String? ?? '',
        waitingPeriodDays: json['waitingPeriodDays'] as int?,
        maxApplications: json['maxApplications'] as int?,
        minimumTemperatureC: (json['minimumTemperatureC'] as num?)?.toDouble(),
        maximumTemperatureC: (json['maximumTemperatureC'] as num?)?.toDouble(),
        informationValidUntil: json['informationValidUntil'] == null
            ? null
            : DateTime.parse(json['informationValidUntil'] as String),
        quantity: (json['quantity'] as num? ?? 1).toDouble(),
        unit: json['unit'] as String? ?? 'пак.',
        instructions: json['instructions'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class PlotCell {
  static const Object _unset = Object();

  final int row;
  final int col;
  final String? plantingId;

  const PlotCell({
    required this.row,
    required this.col,
    this.plantingId,
  });

  PlotCell copyWith({Object? plantingId = _unset}) => PlotCell(
        row: row,
        col: col,
        plantingId: identical(plantingId, _unset)
            ? this.plantingId
            : plantingId as String?,
      );

  Map<String, dynamic> toJson() => {
        'row': row,
        'col': col,
        'plantingId': plantingId,
      };

  factory PlotCell.fromJson(Map<String, dynamic> json) => PlotCell(
        row: json['row'] as int,
        col: json['col'] as int,
        plantingId: json['plantingId'] as String?,
      );
}

class GardenZone {
  static const int maxNameLength = 80;
  static const int maxNoteLength = 500;

  final String id;
  final String name;
  final GardenZoneType type;
  final double xMeters;
  final double yMeters;
  final double widthMeters;
  final double heightMeters;
  final int colorValue;
  final String note;
  final bool canPlant;

  GardenZone({
    required this.id,
    required this.name,
    required this.type,
    required this.xMeters,
    required this.yMeters,
    required this.widthMeters,
    required this.heightMeters,
    this.colorValue = 0xFFB7D8A8,
    this.note = '',
    this.canPlant = true,
  }) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Zone id cannot be empty');
    }
    final normalizedName = name.trim();
    if (normalizedName.isEmpty || normalizedName.length > maxNameLength) {
      throw ArgumentError.value(name, 'name', 'Invalid zone name');
    }
    if (!xMeters.isFinite || xMeters < 0) {
      throw ArgumentError.value(xMeters, 'xMeters', 'Must be non-negative');
    }
    if (!yMeters.isFinite || yMeters < 0) {
      throw ArgumentError.value(yMeters, 'yMeters', 'Must be non-negative');
    }
    if (!widthMeters.isFinite || widthMeters <= 0) {
      throw ArgumentError.value(widthMeters, 'widthMeters', 'Must be positive');
    }
    if (!heightMeters.isFinite || heightMeters <= 0) {
      throw ArgumentError.value(
        heightMeters,
        'heightMeters',
        'Must be positive',
      );
    }
    if (note.length > maxNoteLength) {
      throw ArgumentError.value(note, 'note', 'Zone note is too long');
    }
  }

  bool containsPoint(double x, double y) =>
      x >= xMeters &&
      x < xMeters + widthMeters &&
      y >= yMeters &&
      y < yMeters + heightMeters;

  bool overlaps(GardenZone other) {
    const tolerance = 0.000001;
    return xMeters < other.xMeters + other.widthMeters - tolerance &&
        xMeters + widthMeters > other.xMeters + tolerance &&
        yMeters < other.yMeters + other.heightMeters - tolerance &&
        yMeters + heightMeters > other.yMeters + tolerance;
  }

  GardenZone copyWith({
    String? name,
    GardenZoneType? type,
    double? xMeters,
    double? yMeters,
    double? widthMeters,
    double? heightMeters,
    int? colorValue,
    String? note,
    bool? canPlant,
  }) =>
      GardenZone(
        id: id,
        name: name ?? this.name,
        type: type ?? this.type,
        xMeters: xMeters ?? this.xMeters,
        yMeters: yMeters ?? this.yMeters,
        widthMeters: widthMeters ?? this.widthMeters,
        heightMeters: heightMeters ?? this.heightMeters,
        colorValue: colorValue ?? this.colorValue,
        note: note ?? this.note,
        canPlant: canPlant ?? this.canPlant,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'xMeters': xMeters,
        'yMeters': yMeters,
        'widthMeters': widthMeters,
        'heightMeters': heightMeters,
        'colorValue': colorValue,
        'note': note,
        'canPlant': canPlant,
      };

  factory GardenZone.fromJson(Map<String, dynamic> json) => GardenZone(
        id: json['id'] as String,
        name: json['name'] as String,
        type: gardenZoneTypeFromString((json['type'] ?? 'area') as String),
        xMeters: (json['xMeters'] as num).toDouble(),
        yMeters: (json['yMeters'] as num).toDouble(),
        widthMeters: (json['widthMeters'] as num).toDouble(),
        heightMeters: (json['heightMeters'] as num).toDouble(),
        colorValue: (json['colorValue'] ?? 0xFFB7D8A8) as int,
        note: (json['note'] ?? '') as String,
        canPlant: (json['canPlant'] ?? true) as bool,
      );
}

class Garden {
  static const Object _unset = Object();
  static const int minRowCount = 1;
  static const int maxRowCount = 50;
  static const int minColumnCount = 1;
  static const int maxColumnCount = 50;
  static const int maxCellCount = 2500;
  static const double minDimensionMeters = 0.1;
  static const double maxDimensionMeters = 10000;
  static const double minAreaSquareMeters = 0.01;
  static const double maxAreaSquareMeters = 100000000;
  static const int maxNameLength = 80;
  static const int maxRegionLength = 100;
  static const int maxNoteLength = 500;
  static const int maxZoneCount = 200;

  final String id;
  final String name;
  final int rows;
  final int cols;
  final double widthMeters;
  final double heightMeters;
  final GardenSizeMode sizeMode;
  final AreaUnit areaUnit;
  final GardenType type;
  final SoilType soilType;
  final String countryCode;
  final String oblastCode;
  final String oblast;
  final AgroclimaticZone agroclimaticZone;
  final String settlement;
  final double? latitude;
  final double? longitude;
  final WeatherSource weatherSource;
  final String note;
  final String? photoPlaceholder;
  final List<PlotCell> cells;
  final List<GardenZone> zones;

  Garden({
    required this.id,
    required this.name,
    required this.rows,
    required this.cols,
    required this.widthMeters,
    required this.heightMeters,
    this.sizeMode = GardenSizeMode.dimensions,
    this.areaUnit = AreaUnit.squareMeters,
    this.type = GardenType.vegetableGarden,
    this.soilType = SoilType.unknown,
    this.countryCode = 'UA',
    this.oblastCode = '',
    String oblast = '',
    String region = '',
    this.agroclimaticZone = AgroclimaticZone.unknown,
    this.settlement = '',
    this.latitude,
    this.longitude,
    this.weatherSource = WeatherSource.none,
    this.note = '',
    this.photoPlaceholder,
    required List<PlotCell> cells,
    List<GardenZone> zones = const [],
  })  : oblast = oblast.trim().isNotEmpty ? oblast.trim() : region.trim(),
        cells = List.unmodifiable(cells),
        zones = List.unmodifiable(zones) {
    validateGeometry(
      name: name,
      rows: rows,
      cols: cols,
      widthMeters: widthMeters,
      heightMeters: heightMeters,
    );
    _validateCells(cells, rows: rows, cols: cols);
    _validateMetadata(oblast: this.oblast, settlement: settlement, note: note);
    _validateZones(
      zones,
      widthMeters: widthMeters,
      heightMeters: heightMeters,
    );
  }

  String get region => oblast;

  static void _validateMetadata({
    required String oblast,
    required String settlement,
    required String note,
  }) {
    if (oblast.length > maxRegionLength) {
      throw ArgumentError.value(oblast, 'oblast', 'Oblast is too long');
    }
    if (settlement.length > maxRegionLength) {
      throw ArgumentError.value(
        settlement,
        'settlement',
        'Settlement is too long',
      );
    }
    if (note.length > maxNoteLength) {
      throw ArgumentError.value(note, 'note', 'Garden note is too long');
    }
  }

  static void _validateZones(
    List<GardenZone> zones, {
    required double widthMeters,
    required double heightMeters,
  }) {
    if (zones.length > maxZoneCount) {
      throw ArgumentError.value(zones.length, 'zones', 'Too many zones');
    }
    final ids = <String>{};
    const tolerance = 0.000001;
    for (var index = 0; index < zones.length; index++) {
      final zone = zones[index];
      if (!ids.add(zone.id)) {
        throw ArgumentError.value(zone.id, 'zones', 'Duplicate zone id');
      }
      if (zone.xMeters + zone.widthMeters > widthMeters + tolerance ||
          zone.yMeters + zone.heightMeters > heightMeters + tolerance) {
        throw ArgumentError.value(zone.name, 'zones', 'Zone is outside garden');
      }
      for (var otherIndex = index + 1;
          otherIndex < zones.length;
          otherIndex++) {
        if (zone.overlaps(zones[otherIndex])) {
          throw ArgumentError.value(
            zone.name,
            'zones',
            'Garden zones cannot overlap',
          );
        }
      }
    }
  }

  static bool isValidRowCount(int value) =>
      value >= minRowCount && value <= maxRowCount;

  static bool isValidColumnCount(int value) =>
      value >= minColumnCount && value <= maxColumnCount;

  static bool isValidCellCount(int rows, int cols) =>
      rows > 0 && cols > 0 && rows * cols <= maxCellCount;

  static bool isValidDimension(double value) =>
      value.isFinite &&
      value >= minDimensionMeters &&
      value <= maxDimensionMeters;

  static bool isValidArea(double squareMeters) =>
      squareMeters.isFinite &&
      squareMeters >= minAreaSquareMeters &&
      squareMeters <= maxAreaSquareMeters;

  static void validateGeometry({
    required String name,
    required int rows,
    required int cols,
    required double widthMeters,
    required double heightMeters,
  }) {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty || normalizedName.length > maxNameLength) {
      throw ArgumentError.value(name, 'name', 'Invalid garden name');
    }
    if (!isValidRowCount(rows)) {
      throw RangeError.range(rows, minRowCount, maxRowCount, 'rows');
    }
    if (!isValidColumnCount(cols)) {
      throw RangeError.range(cols, minColumnCount, maxColumnCount, 'cols');
    }
    if (!isValidCellCount(rows, cols)) {
      throw ArgumentError.value(rows * cols, 'cells', 'Too many cells');
    }
    if (!isValidDimension(widthMeters)) {
      throw ArgumentError.value(
        widthMeters,
        'widthMeters',
        'Must be between $minDimensionMeters and $maxDimensionMeters',
      );
    }
    if (!isValidDimension(heightMeters)) {
      throw ArgumentError.value(
        heightMeters,
        'heightMeters',
        'Must be between $minDimensionMeters and $maxDimensionMeters',
      );
    }
  }

  static void _validateCells(
    List<PlotCell> cells, {
    required int rows,
    required int cols,
  }) {
    final expectedCount = rows * cols;
    if (cells.length != expectedCount) {
      throw ArgumentError.value(
        cells.length,
        'cells',
        'Expected $expectedCount cells',
      );
    }

    for (var index = 0; index < cells.length; index++) {
      final cell = cells[index];
      final expectedRow = index ~/ cols;
      final expectedColumn = index % cols;
      if (cell.row != expectedRow || cell.col != expectedColumn) {
        throw ArgumentError.value(
          '${cell.row}:${cell.col}',
          'cells[$index]',
          'Expected $expectedRow:$expectedColumn',
        );
      }
    }
  }

  factory Garden.create({
    required String name,
    required int rows,
    required int cols,
    required double widthMeters,
    required double heightMeters,
    GardenSizeMode sizeMode = GardenSizeMode.dimensions,
    AreaUnit areaUnit = AreaUnit.squareMeters,
    GardenType type = GardenType.vegetableGarden,
    SoilType soilType = SoilType.unknown,
    String countryCode = 'UA',
    String oblastCode = '',
    String oblast = '',
    AgroclimaticZone agroclimaticZone = AgroclimaticZone.unknown,
    String settlement = '',
    double? latitude,
    double? longitude,
    WeatherSource weatherSource = WeatherSource.none,
    String region = '',
    String note = '',
    String? photoPlaceholder,
  }) {
    final normalizedName = name.trim();
    validateGeometry(
      name: normalizedName,
      rows: rows,
      cols: cols,
      widthMeters: widthMeters,
      heightMeters: heightMeters,
    );
    final id = generateId();
    final cells = List.generate(
      rows * cols,
      (i) => PlotCell(row: i ~/ cols, col: i % cols),
    );
    return Garden(
      id: id,
      name: normalizedName,
      rows: rows,
      cols: cols,
      widthMeters: widthMeters,
      heightMeters: heightMeters,
      sizeMode: sizeMode,
      areaUnit: areaUnit,
      type: type,
      soilType: soilType,
      countryCode: countryCode,
      oblastCode: oblastCode,
      oblast: oblast,
      region: region,
      agroclimaticZone: agroclimaticZone,
      settlement: settlement,
      latitude: latitude,
      longitude: longitude,
      weatherSource: weatherSource,
      note: note.trim(),
      photoPlaceholder: photoPlaceholder,
      cells: cells,
    );
  }

  factory Garden.createFromArea({
    required String name,
    required int rows,
    required int cols,
    required double areaValue,
    required AreaUnit areaUnit,
    GardenType type = GardenType.vegetableGarden,
    SoilType soilType = SoilType.unknown,
    String countryCode = 'UA',
    String oblastCode = '',
    String oblast = '',
    AgroclimaticZone agroclimaticZone = AgroclimaticZone.unknown,
    String settlement = '',
    double? latitude,
    double? longitude,
    WeatherSource weatherSource = WeatherSource.none,
    String region = '',
    String note = '',
    String? photoPlaceholder,
  }) {
    final squareMeters = areaToSquareMeters(areaValue, areaUnit);
    if (!isValidArea(squareMeters)) {
      throw ArgumentError.value(
        areaValue,
        'areaValue',
        'Area must be between $minAreaSquareMeters and $maxAreaSquareMeters m²',
      );
    }

    final side = math.sqrt(squareMeters);
    return Garden.create(
      name: name,
      rows: rows,
      cols: cols,
      widthMeters: side,
      heightMeters: side,
      sizeMode: GardenSizeMode.area,
      areaUnit: areaUnit,
      type: type,
      soilType: soilType,
      countryCode: countryCode,
      oblastCode: oblastCode,
      oblast: oblast,
      agroclimaticZone: agroclimaticZone,
      settlement: settlement,
      latitude: latitude,
      longitude: longitude,
      weatherSource: weatherSource,
      region: region,
      note: note,
      photoPlaceholder: photoPlaceholder,
    );
  }

  double get areaSquareMeters => widthMeters * heightMeters;

  PlotCell cellAt(int r, int c) {
    if (r < 0 || r >= rows) {
      throw RangeError.range(r, 0, rows - 1, 'row');
    }
    if (c < 0 || c >= cols) {
      throw RangeError.range(c, 0, cols - 1, 'column');
    }
    return cells[r * cols + c];
  }

  Garden setCell(PlotCell cell) {
    cellAt(cell.row, cell.col);
    final idx = cell.row * cols + cell.col;
    final newCells = [...cells]..[idx] = cell;
    return copyWith(cells: newCells);
  }

  GardenZone? zoneAtCell(int row, int col) {
    cellAt(row, col);
    final x = (col + 0.5) * widthMeters / cols;
    final y = (row + 0.5) * heightMeters / rows;
    for (final zone in zones) {
      if (zone.containsPoint(x, y)) return zone;
    }
    return null;
  }

  ({int startRow, int endRow, int startCol, int endCol}) zoneGridBounds(
    GardenZone zone,
  ) {
    final startRow =
        (zone.yMeters / heightMeters * rows).floor().clamp(0, rows - 1);
    final endRow =
        ((zone.yMeters + zone.heightMeters) / heightMeters * rows - 0.000001)
            .floor()
            .clamp(0, rows - 1);
    final startCol =
        (zone.xMeters / widthMeters * cols).floor().clamp(0, cols - 1);
    final endCol =
        ((zone.xMeters + zone.widthMeters) / widthMeters * cols - 0.000001)
            .floor()
            .clamp(0, cols - 1);
    return (
      startRow: startRow,
      endRow: endRow,
      startCol: startCol,
      endCol: endCol,
    );
  }

  GardenZone zoneFromGridRange({
    required String id,
    required String name,
    required GardenZoneType type,
    required int startRow,
    required int endRow,
    required int startCol,
    required int endCol,
    required int colorValue,
    required bool canPlant,
    String note = '',
  }) {
    if (startRow < 0 || endRow >= rows || startRow > endRow) {
      throw RangeError('Invalid zone row range');
    }
    if (startCol < 0 || endCol >= cols || startCol > endCol) {
      throw RangeError('Invalid zone column range');
    }
    return GardenZone(
      id: id,
      name: name.trim(),
      type: type,
      xMeters: startCol * widthMeters / cols,
      yMeters: startRow * heightMeters / rows,
      widthMeters: (endCol - startCol + 1) * widthMeters / cols,
      heightMeters: (endRow - startRow + 1) * heightMeters / rows,
      colorValue: colorValue,
      canPlant: canPlant,
      note: note.trim(),
    );
  }

  Garden reconfigure({
    required String name,
    required int rows,
    required int cols,
    required double widthMeters,
    required double heightMeters,
    required GardenSizeMode sizeMode,
    required AreaUnit areaUnit,
    required GardenType type,
    required SoilType soilType,
    required String region,
    required String note,
    String? countryCode,
    String? oblastCode,
    String? oblast,
    AgroclimaticZone? agroclimaticZone,
    String? settlement,
    double? latitude,
    double? longitude,
    WeatherSource? weatherSource,
    String? photoPlaceholder,
  }) {
    final resizedCells = List.generate(rows * cols, (index) {
      final row = index ~/ cols;
      final col = index % cols;
      if (row < this.rows && col < this.cols) return cellAt(row, col);
      return PlotCell(row: row, col: col);
    });
    final scaleX = widthMeters / this.widthMeters;
    final scaleY = heightMeters / this.heightMeters;
    final scaledZones = zones
        .map(
          (zone) => zone.copyWith(
            xMeters: zone.xMeters * scaleX,
            yMeters: zone.yMeters * scaleY,
            widthMeters: zone.widthMeters * scaleX,
            heightMeters: zone.heightMeters * scaleY,
          ),
        )
        .toList();
    return Garden(
      id: id,
      name: name.trim(),
      rows: rows,
      cols: cols,
      widthMeters: widthMeters,
      heightMeters: heightMeters,
      sizeMode: sizeMode,
      areaUnit: areaUnit,
      type: type,
      soilType: soilType,
      countryCode: countryCode ?? this.countryCode,
      oblastCode: oblastCode ?? this.oblastCode,
      oblast: oblast ?? region,
      agroclimaticZone: agroclimaticZone ?? this.agroclimaticZone,
      settlement: settlement ?? this.settlement,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      weatherSource: weatherSource ?? this.weatherSource,
      note: note.trim(),
      photoPlaceholder: photoPlaceholder,
      cells: resizedCells,
      zones: scaledZones,
    );
  }

  Garden copyWith({
    String? name,
    int? rows,
    int? cols,
    double? widthMeters,
    double? heightMeters,
    GardenSizeMode? sizeMode,
    AreaUnit? areaUnit,
    GardenType? type,
    SoilType? soilType,
    String? region,
    String? countryCode,
    String? oblastCode,
    String? oblast,
    AgroclimaticZone? agroclimaticZone,
    String? settlement,
    Object? latitude = _unset,
    Object? longitude = _unset,
    WeatherSource? weatherSource,
    String? note,
    Object? photoPlaceholder = _unset,
    List<PlotCell>? cells,
    List<GardenZone>? zones,
  }) {
    return Garden(
      id: id,
      name: name ?? this.name,
      rows: rows ?? this.rows,
      cols: cols ?? this.cols,
      widthMeters: widthMeters ?? this.widthMeters,
      heightMeters: heightMeters ?? this.heightMeters,
      sizeMode: sizeMode ?? this.sizeMode,
      areaUnit: areaUnit ?? this.areaUnit,
      type: type ?? this.type,
      soilType: soilType ?? this.soilType,
      countryCode: countryCode ?? this.countryCode,
      oblastCode: oblastCode ?? this.oblastCode,
      oblast: oblast ?? region ?? this.oblast,
      agroclimaticZone: agroclimaticZone ?? this.agroclimaticZone,
      settlement: settlement ?? this.settlement,
      latitude:
          identical(latitude, _unset) ? this.latitude : latitude as double?,
      longitude:
          identical(longitude, _unset) ? this.longitude : longitude as double?,
      weatherSource: weatherSource ?? this.weatherSource,
      note: note ?? this.note,
      photoPlaceholder: identical(photoPlaceholder, _unset)
          ? this.photoPlaceholder
          : photoPlaceholder as String?,
      cells: cells ?? this.cells,
      zones: zones ?? this.zones,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rows': rows,
        'cols': cols,
        'widthMeters': widthMeters,
        'heightMeters': heightMeters,
        'sizeMode': sizeMode.name,
        'areaUnit': areaUnit.name,
        'type': type.name,
        'soilType': soilType.name,
        'countryCode': countryCode,
        'oblastCode': oblastCode,
        'oblast': oblast,
        'agroclimaticZone': agroclimaticZone.name,
        'settlement': settlement,
        'latitude': latitude,
        'longitude': longitude,
        'weatherSource': weatherSource.name,
        'note': note,
        'photoPlaceholder': photoPlaceholder,
        'cells': cells.map((e) => e.toJson()).toList(),
        'zones': zones.map((e) => e.toJson()).toList(),
      };

  factory Garden.fromJson(Map<String, dynamic> json) => Garden(
        id: json['id'] as String,
        name: json['name'] as String,
        rows: json['rows'] as int,
        cols: json['cols'] as int,
        widthMeters: (json['widthMeters'] as num).toDouble(),
        heightMeters: (json['heightMeters'] as num).toDouble(),
        sizeMode: gardenSizeModeFromString(
          (json['sizeMode'] ?? 'dimensions') as String,
        ),
        areaUnit: areaUnitFromString(
          (json['areaUnit'] ?? 'squareMeters') as String,
        ),
        type: gardenTypeFromString(
          (json['type'] ?? 'vegetableGarden') as String,
        ),
        soilType: soilTypeFromString((json['soilType'] ?? 'unknown') as String),
        countryCode: (json['countryCode'] ?? 'UA') as String,
        oblastCode: (json['oblastCode'] ?? '') as String,
        oblast: (json['oblast'] ?? json['region'] ?? '') as String,
        agroclimaticZone: agroclimaticZoneFromString(
          (json['agroclimaticZone'] ?? 'unknown') as String,
        ),
        settlement: (json['settlement'] ?? '') as String,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        weatherSource: weatherSourceFromString(
          (json['weatherSource'] ?? 'none') as String,
        ),
        note: (json['note'] ?? '') as String,
        photoPlaceholder: json['photoPlaceholder'] as String?,
        cells: (json['cells'] as List)
            .map((e) => PlotCell.fromJson(e as Map<String, dynamic>))
            .toList(),
        zones: (json['zones'] as List? ?? const [])
            .map((e) => GardenZone.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class Reminder {
  static const Object _unset = Object();
  final String id;
  final String title;
  final DateTime date;
  final String? gardenId;
  final String? cropId;
  final String? plantingId;
  final ReminderType type;
  final ReminderStatus status;
  final ReminderSource source;
  final String ruleVersion;
  final int? repeatEveryDays;
  final DateTime? completedAt;
  final DateTime? skippedAt;

  Reminder({
    required this.id,
    required this.title,
    required this.date,
    this.gardenId,
    this.cropId,
    this.plantingId,
    this.type = ReminderType.general,
    this.status = ReminderStatus.scheduled,
    this.source = ReminderSource.user,
    this.ruleVersion = '',
    this.repeatEveryDays,
    this.completedAt,
    this.skippedAt,
  });

  Reminder copyWith({
    String? title,
    DateTime? date,
    Object? gardenId = _unset,
    Object? cropId = _unset,
    Object? plantingId = _unset,
    ReminderType? type,
    ReminderStatus? status,
    ReminderSource? source,
    String? ruleVersion,
    Object? repeatEveryDays = _unset,
    Object? completedAt = _unset,
    Object? skippedAt = _unset,
  }) =>
      Reminder(
        id: id,
        title: title ?? this.title,
        date: date ?? this.date,
        gardenId:
            identical(gardenId, _unset) ? this.gardenId : gardenId as String?,
        cropId: identical(cropId, _unset) ? this.cropId : cropId as String?,
        plantingId: identical(plantingId, _unset)
            ? this.plantingId
            : plantingId as String?,
        type: type ?? this.type,
        status: status ?? this.status,
        source: source ?? this.source,
        ruleVersion: ruleVersion ?? this.ruleVersion,
        repeatEveryDays: identical(repeatEveryDays, _unset)
            ? this.repeatEveryDays
            : repeatEveryDays as int?,
        completedAt: identical(completedAt, _unset)
            ? this.completedAt
            : completedAt as DateTime?,
        skippedAt: identical(skippedAt, _unset)
            ? this.skippedAt
            : skippedAt as DateTime?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date.toIso8601String(),
        'gardenId': gardenId,
        'cropId': cropId,
        'plantingId': plantingId,
        'type': type.name,
        'status': status.name,
        'source': source.name,
        'ruleVersion': ruleVersion,
        'repeatEveryDays': repeatEveryDays,
        'completedAt': completedAt?.toIso8601String(),
        'skippedAt': skippedAt?.toIso8601String(),
      };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
        id: json['id'] as String,
        title: json['title'] as String,
        date: DateTime.parse(json['date'] as String),
        gardenId: json['gardenId'] as String?,
        cropId: json['cropId'] as String?,
        plantingId: json['plantingId'] as String?,
        type: ReminderType.values.firstWhere(
          (type) => type.name == json['type'],
          orElse: () => ReminderType.general,
        ),
        status: ReminderStatus.values.firstWhere(
          (status) => status.name == json['status'],
          orElse: () => ReminderStatus.scheduled,
        ),
        source: ReminderSource.values.firstWhere(
          (source) => source.name == json['source'],
          orElse: () => ReminderSource.user,
        ),
        ruleVersion: json['ruleVersion'] as String? ?? '',
        repeatEveryDays: json['repeatEveryDays'] as int?,
        completedAt: json['completedAt'] == null
            ? null
            : DateTime.parse(json['completedAt'] as String),
        skippedAt: json['skippedAt'] == null
            ? null
            : DateTime.parse(json['skippedAt'] as String),
      );
}

enum DiaryEntryType { sowing, sprout, growth, issue, treatment, harvest, note }

DiaryEntryType diaryEntryTypeFromString(String value) =>
    DiaryEntryType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => DiaryEntryType.note,
    );

String diaryEntryTypeLabel(DiaryEntryType type) => switch (type) {
      DiaryEntryType.sowing => 'Посів / посадка',
      DiaryEntryType.sprout => 'Сходи',
      DiaryEntryType.growth => 'Ріст',
      DiaryEntryType.issue => 'Хвороба / пошкодження',
      DiaryEntryType.treatment => 'Обробка / догляд',
      DiaryEntryType.harvest => 'Врожай',
      DiaryEntryType.note => 'Нотатка',
    };

class GardenDiaryEntry {
  static const Object _unset = Object();

  final String id;
  final String gardenId;
  final DateTime capturedAt;
  final DiaryEntryType type;
  final String note;
  final String? cropId;
  final int? row;
  final int? col;
  final String? photoPath;
  final bool shareForResearch;
  final bool shareForCatalog;

  const GardenDiaryEntry({
    required this.id,
    required this.gardenId,
    required this.capturedAt,
    required this.type,
    this.note = '',
    this.cropId,
    this.row,
    this.col,
    this.photoPath,
    this.shareForResearch = false,
    this.shareForCatalog = false,
  }) : assert((row == null) == (col == null));

  GardenDiaryEntry copyWith({
    DateTime? capturedAt,
    DiaryEntryType? type,
    String? note,
    Object? cropId = _unset,
    Object? row = _unset,
    Object? col = _unset,
    Object? photoPath = _unset,
    bool? shareForResearch,
    bool? shareForCatalog,
  }) =>
      GardenDiaryEntry(
        id: id,
        gardenId: gardenId,
        capturedAt: capturedAt ?? this.capturedAt,
        type: type ?? this.type,
        note: note ?? this.note,
        cropId: identical(cropId, _unset) ? this.cropId : cropId as String?,
        row: identical(row, _unset) ? this.row : row as int?,
        col: identical(col, _unset) ? this.col : col as int?,
        photoPath: identical(photoPath, _unset)
            ? this.photoPath
            : photoPath as String?,
        shareForResearch: shareForResearch ?? this.shareForResearch,
        shareForCatalog: shareForCatalog ?? this.shareForCatalog,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'gardenId': gardenId,
        'capturedAt': capturedAt.toIso8601String(),
        'type': type.name,
        'note': note,
        'cropId': cropId,
        'row': row,
        'col': col,
        'photoPath': photoPath,
        'shareForResearch': shareForResearch,
        'shareForCatalog': shareForCatalog,
      };

  factory GardenDiaryEntry.fromJson(Map<String, dynamic> json) =>
      GardenDiaryEntry(
        id: json['id'] as String,
        gardenId: json['gardenId'] as String,
        capturedAt: DateTime.parse(json['capturedAt'] as String),
        type: diaryEntryTypeFromString((json['type'] ?? 'note') as String),
        note: (json['note'] ?? '') as String,
        cropId: json['cropId'] as String?,
        row: json['row'] as int?,
        col: json['col'] as int?,
        photoPath: json['photoPath'] as String?,
        shareForResearch: (json['shareForResearch'] ?? false) as bool,
        shareForCatalog: (json['shareForCatalog'] ?? false) as bool,
      );
}

class AppData {
  static const int currentSchemaVersion = 7;

  final List<Garden> gardens;
  final List<Crop> crops;
  final List<Planting> plantings;
  final List<InventoryItem> inventory;
  final List<Reminder> reminders;
  final List<GardenDiaryEntry> diaryEntries;

  AppData({
    required List<Garden> gardens,
    required List<Crop> crops,
    List<Planting> plantings = const [],
    List<InventoryItem> inventory = const [],
    required List<Reminder> reminders,
    List<GardenDiaryEntry> diaryEntries = const [],
  })  : gardens = List.unmodifiable(gardens),
        crops = List.unmodifiable(crops),
        plantings = List.unmodifiable(plantings),
        inventory = List.unmodifiable(inventory),
        reminders = List.unmodifiable(reminders),
        diaryEntries = List.unmodifiable(diaryEntries) {
    _validatePlantingReferences();
  }

  void _validatePlantingReferences() {
    final gardensById = {for (final garden in gardens) garden.id: garden};
    final cropsById = {for (final crop in crops) crop.id: crop};
    final inventoryById = <String, InventoryItem>{};
    final plantingsById = <String, Planting>{};
    final diaryIds = <String>{};

    for (final entry in diaryEntries) {
      if (!diaryIds.add(entry.id)) {
        throw ArgumentError.value(
          entry.id,
          'diaryEntries',
          'Duplicate diary entry id',
        );
      }
      final garden = gardensById[entry.gardenId];
      if (garden == null) {
        throw ArgumentError.value(
          entry.gardenId,
          'diaryEntries',
          'Diary entry references an unknown garden',
        );
      }
      if (entry.cropId != null && !cropsById.containsKey(entry.cropId)) {
        throw ArgumentError.value(
          entry.cropId,
          'diaryEntries',
          'Diary entry references an unknown crop',
        );
      }
      if ((entry.row == null) != (entry.col == null)) {
        throw ArgumentError.value(entry.id, 'diaryEntries', 'Invalid cell');
      }
      if (entry.row != null) garden.cellAt(entry.row!, entry.col!);
      if (entry.shareForCatalog &&
          (entry.photoPath == null || entry.photoPath!.trim().isEmpty)) {
        throw ArgumentError.value(
          entry.id,
          'diaryEntries',
          'Catalog entry requires a photo',
        );
      }
    }

    for (final item in inventory) {
      if (inventoryById.containsKey(item.id)) {
        throw ArgumentError.value(
          item.id,
          'inventory',
          'Duplicate inventory id',
        );
      }
      if (item.cropId != null && !cropsById.containsKey(item.cropId)) {
        throw ArgumentError.value(
          item.cropId,
          'inventory',
          'Inventory item references an unknown crop',
        );
      }
      inventoryById[item.id] = item;
    }

    for (final planting in plantings) {
      if (plantingsById.containsKey(planting.id)) {
        throw ArgumentError.value(
          planting.id,
          'plantings',
          'Duplicate planting id',
        );
      }
      if (!gardensById.containsKey(planting.gardenId)) {
        throw ArgumentError.value(
          planting.gardenId,
          'plantings',
          'Planting references an unknown garden',
        );
      }
      if (planting.cropId != null && !cropsById.containsKey(planting.cropId)) {
        throw ArgumentError.value(
          planting.cropId,
          'plantings',
          'Planting references an unknown crop',
        );
      }
      if (planting.inventoryItemId != null &&
          !inventoryById.containsKey(planting.inventoryItemId)) {
        throw ArgumentError.value(
          planting.inventoryItemId,
          'plantings',
          'Planting references an unknown inventory item',
        );
      }
      final inventoryItem = inventoryById[planting.inventoryItemId];
      if (inventoryItem != null &&
          inventoryItem.type != InventoryItemType.seeds) {
        throw ArgumentError.value(
          planting.inventoryItemId,
          'plantings',
          'Planting can reference only a seed package',
        );
      }
      if (inventoryItem?.cropId != null &&
          inventoryItem!.cropId != planting.cropId) {
        throw ArgumentError.value(
          planting.cropId,
          'plantings',
          'Planting crop must match the seed package',
        );
      }
      plantingsById[planting.id] = planting;
    }

    for (final garden in gardens) {
      for (final cell in garden.cells) {
        final plantingId = cell.plantingId;
        if (plantingId == null) continue;

        final planting = plantingsById[plantingId];
        if (planting == null ||
            planting.gardenId != garden.id ||
            planting.isHarvested) {
          throw ArgumentError.value(
            plantingId,
            'cells',
            'Cell references an invalid planting',
          );
        }
      }
    }
  }

  AppData copyWith({
    List<Garden>? gardens,
    List<Crop>? crops,
    List<Planting>? plantings,
    List<InventoryItem>? inventory,
    List<Reminder>? reminders,
    List<GardenDiaryEntry>? diaryEntries,
  }) =>
      AppData(
        gardens: gardens ?? this.gardens,
        crops: crops ?? this.crops,
        plantings: plantings ?? this.plantings,
        inventory: inventory ?? this.inventory,
        reminders: reminders ?? this.reminders,
        diaryEntries: diaryEntries ?? this.diaryEntries,
      );

  AppData withBuiltInCrops([Iterable<Crop> catalogCrops = const []]) {
    final merged = [...crops];
    for (final candidate in [...builtInCrops(), ...catalogCrops]) {
      final idIndex = merged.indexWhere((crop) => crop.id == candidate.id);
      if (idIndex != -1) {
        if (candidate.catalogId.isNotEmpty) {
          merged[idIndex] = merged[idIndex].withCatalogFrom(candidate);
        }
        continue;
      }
      final normalizedName = candidate.name.trim().toLowerCase();
      final nameIndex = merged.indexWhere(
        (crop) => crop.name.trim().toLowerCase() == normalizedName,
      );
      if (nameIndex != -1) {
        if (candidate.catalogId.isNotEmpty) {
          merged[nameIndex] = merged[nameIndex].withCatalogFrom(candidate);
        }
        continue;
      }
      merged.add(candidate);
    }
    if (merged.length == crops.length &&
        merged.indexed.every((item) => identical(item.$2, crops[item.$1]))) {
      return this;
    }
    return copyWith(crops: merged);
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': currentSchemaVersion,
        'gardens': gardens.map((e) => e.toJson()).toList(),
        'crops': crops.map((e) => e.toJson()).toList(),
        'plantings': plantings.map((e) => e.toJson()).toList(),
        'inventory': inventory.map((e) => e.toJson()).toList(),
        'reminders': reminders.map((e) => e.toJson()).toList(),
        'diaryEntries': diaryEntries.map((e) => e.toJson()).toList(),
      };

  factory AppData.fromJson(Map<String, dynamic> json) {
    final source = _migrateAppDataToV7(json);
    final crops = (source['crops'] as List? ?? [])
        .map((item) => Crop.fromJson(item as Map<String, dynamic>))
        .toList();
    final plantings = (source['plantings'] as List? ?? [])
        .map((item) => Planting.fromJson(item as Map<String, dynamic>))
        .toList();
    final plantingIds = plantings.map((planting) => planting.id).toSet();
    final gardens = <Garden>[];

    for (final rawGarden in source['gardens'] as List? ?? const []) {
      final gardenJson = Map<String, dynamic>.from(
        rawGarden as Map<String, dynamic>,
      );
      final gardenId = gardenJson['id'] as String;
      final migratedCells = <Map<String, dynamic>>[];

      for (final rawCell in gardenJson['cells'] as List) {
        final cellJson = Map<String, dynamic>.from(
          rawCell as Map<String, dynamic>,
        );
        final row = cellJson['row'] as int;
        final col = cellJson['col'] as int;
        var plantingId = cellJson['plantingId'] as String?;
        final legacyCropId = cellJson['cropId'] as String?;
        final legacyNote = cellJson['note'] as String?;
        final hasLegacyData = legacyCropId != null ||
            (legacyNote != null && legacyNote.trim().isNotEmpty);

        if (plantingId == null && hasLegacyData) {
          final baseId = 'legacy_${gardenId}_${row}_$col';
          var migratedPlantingId = baseId;
          var suffix = 1;
          while (plantingIds.contains(migratedPlantingId)) {
            migratedPlantingId = '${baseId}_${suffix++}';
          }
          plantingIds.add(migratedPlantingId);
          plantingId = migratedPlantingId;

          final cropIndex = legacyCropId == null
              ? -1
              : crops.indexWhere((crop) => crop.id == legacyCropId);
          plantings.add(
            Planting(
              id: migratedPlantingId,
              gardenId: gardenId,
              cropId: legacyCropId,
              row: row,
              col: col,
              variety: cropIndex == -1 ? '' : crops[cropIndex].variety,
              note: legacyNote?.trim() ?? '',
            ),
          );
        }

        migratedCells.add({
          'row': row,
          'col': col,
          'plantingId': plantingId,
        });
      }

      gardenJson['cells'] = migratedCells;
      gardens.add(Garden.fromJson(gardenJson));
    }

    return AppData(
      gardens: gardens,
      crops: crops,
      plantings: plantings,
      inventory: (source['inventory'] as List? ?? const [])
          .map(
            (item) => InventoryItem.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
      reminders: (source['reminders'] as List? ?? [])
          .map((item) => Reminder.fromJson(item as Map<String, dynamic>))
          .toList(),
      diaryEntries: (source['diaryEntries'] as List? ?? const [])
          .map(
            (item) => GardenDiaryEntry.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  static AppData initial() => AppData(
        gardens: [],
        crops: builtInCrops(),
        plantings: [],
        inventory: [],
        reminders: [],
        diaryEntries: [],
      );
}

Map<String, dynamic> _migrateAppDataToV7(Map<String, dynamic> json) {
  final version = json['schemaVersion'] as int? ?? 1;
  if (version >= AppData.currentSchemaVersion) {
    return Map<String, dynamic>.from(json);
  }

  final migrated = Map<String, dynamic>.from(json);
  if (version <= 6) {
    migrated['gardens'] = [
      for (final raw in json['gardens'] as List? ?? const [])
        () {
          final garden = Map<String, dynamic>.from(raw as Map);
          final legacyRegion = garden['region'] as String? ?? '';
          garden.putIfAbsent('countryCode', () => 'UA');
          garden.putIfAbsent('oblastCode', () => '');
          garden.putIfAbsent('oblast', () => legacyRegion);
          garden.putIfAbsent('agroclimaticZone', () => 'unknown');
          garden.putIfAbsent('settlement', () => '');
          garden.putIfAbsent('weatherSource', () => 'none');
          return garden;
        }(),
    ];
    migrated['plantings'] = [
      for (final raw in json['plantings'] as List? ?? const [])
        () {
          final planting = Map<String, dynamic>.from(raw as Map);
          planting.putIfAbsent('actualMaturityAt', () => null);
          planting.putIfAbsent(
            'timingRuleVersion',
            () => planting['expectedMaturityAt'] == null ? '' : 'legacy-6',
          );
          return planting;
        }(),
    ];
    migrated['reminders'] = [
      for (final raw in json['reminders'] as List? ?? const [])
        () {
          final reminder = Map<String, dynamic>.from(raw as Map);
          final title = (reminder['title'] as String? ?? '').toLowerCase();
          reminder.putIfAbsent('plantingId', () => null);
          reminder.putIfAbsent(
            'type',
            () => title.contains('полив')
                ? ReminderType.watering.name
                : title.contains('дозрів')
                    ? ReminderType.maturity.name
                    : title.contains('збор')
                        ? ReminderType.harvest.name
                        : title.contains('захист')
                            ? ReminderType.protection.name
                            : ReminderType.general.name,
          );
          reminder.putIfAbsent('status', () => ReminderStatus.scheduled.name);
          reminder.putIfAbsent('source', () => ReminderSource.user.name);
          reminder.putIfAbsent('ruleVersion', () => 'legacy-6');
          return reminder;
        }(),
    ];
  }
  migrated['schemaVersion'] = AppData.currentSchemaVersion;
  return migrated;
}

String encodeAppData(AppData data) => jsonEncode(data.toJson());
AppData decodeAppData(String src) =>
    AppData.fromJson(jsonDecode(src) as Map<String, dynamic>);
