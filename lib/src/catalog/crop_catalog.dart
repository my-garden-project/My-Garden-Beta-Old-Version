import '../models.dart';
import 'structured_crop_rules.dart';

enum CatalogReliability { high, medium, low, unknown }

CatalogReliability catalogReliabilityFromString(Object? value) {
  return CatalogReliability.values.firstWhere(
    (item) => item.name == value,
    orElse: () => CatalogReliability.unknown,
  );
}

String catalogReliabilityLabel(CatalogReliability value) => switch (value) {
      CatalogReliability.high => 'Висока',
      CatalogReliability.medium => 'Середня',
      CatalogReliability.low => 'Обмежена',
      CatalogReliability.unknown => 'Не вказано',
    };

enum CatalogSourceTier { official, scientific, practical, reference }

CatalogSourceTier catalogSourceTier(String value) {
  final host = Uri.tryParse(value)?.host.toLowerCase() ?? '';
  if (host == 'wikipedia.org' ||
      host.endsWith('.wikipedia.org') ||
      host == 'wikidata.org' ||
      host.endsWith('.wikidata.org')) {
    return CatalogSourceTier.reference;
  }
  if (host.endsWith('.gov.ua') ||
      host == 'dpss.gov.ua' ||
      host.endsWith('.gov.pl') ||
      host.endsWith('.europa.eu') ||
      host.endsWith('.efsa.europa.eu') ||
      host == 'gd.eppo.int' ||
      host.endsWith('.eppo.int')) {
    return CatalogSourceTier.official;
  }
  if (host == 'ovoch.com' ||
      host.endsWith('.ovoch.com') ||
      host == 'inhort.pl' ||
      host.endsWith('.inhort.pl') ||
      host == 'agrofagi.com.pl' ||
      host.endsWith('.agrofagi.com.pl') ||
      host.endsWith('.cabi.org') ||
      host == 'plantwiseplusknowledgebank.org' ||
      host.endsWith('.plantwiseplusknowledgebank.org') ||
      host == 'powo.science.kew.org' ||
      host.startsWith('extension.') ||
      host.contains('.extension.') ||
      host.endsWith('.ucanr.edu') ||
      host.endsWith('.edu') ||
      host.endsWith('.edu.ua') ||
      host.endsWith('.rhs.org.uk') ||
      host == 'rhs.org.uk') {
    return CatalogSourceTier.scientific;
  }
  return CatalogSourceTier.practical;
}

String catalogSourceTierLabel(CatalogSourceTier tier) => switch (tier) {
      CatalogSourceTier.official => 'Офіційне джерело',
      CatalogSourceTier.scientific => 'Наукове або дорадче джерело',
      CatalogSourceTier.practical => 'Додатковий практичний матеріал',
      CatalogSourceTier.reference => 'Довідкове посилання — не доказ',
    };

String catalogSourceName(String value) {
  final host = Uri.tryParse(value)?.host.toLowerCase() ?? '';
  if (host == 'sops.gov.ua') return 'Державний реєстр сортів України';
  if (host == 'mepr.gov.ua') {
    return 'Реєстр пестицидів і агрохімікатів України';
  }
  if (host == 'dpss.gov.ua') return 'Держпродспоживслужба';
  if (host == 'ovoch.com' || host.endsWith('.ovoch.com')) {
    return 'Інститут овочівництва і баштанництва НААН';
  }
  if (host.endsWith('.coboru.gov.pl')) return 'COBORU — реєстр сортів';
  if (host == 'www.gov.pl' || host == 'gov.pl') {
    return 'Офіційний портал Польщі';
  }
  if (host == 'agrofagi.com.pl' || host.endsWith('.agrofagi.com.pl')) {
    return 'Platforma Sygnalizacji Agrofagów';
  }
  if (host == 'inhort.pl' || host.endsWith('.inhort.pl')) {
    return 'Instytut Ogrodnictwa — PIB';
  }
  if (host == 'gd.eppo.int' || host.endsWith('.eppo.int')) {
    return 'EPPO Global Database';
  }
  if (host.endsWith('.europa.eu')) return 'Європейська комісія';
  if (host.endsWith('.cabi.org') || host == 'plantwiseplusknowledgebank.org') {
    return 'CABI PlantwisePlus';
  }
  if (host == 'powo.science.kew.org') {
    return 'Kew Plants of the World Online';
  }
  if (host.endsWith('.ucanr.edu')) return 'University of California IPM';
  if (host.endsWith('.umn.edu')) return 'University of Minnesota Extension';
  if (host.endsWith('.usu.edu')) return 'Utah State University Extension';
  if (host.endsWith('.rhs.org.uk') || host == 'rhs.org.uk') {
    return 'Royal Horticultural Society';
  }
  if (host == 'wikipedia.org' || host.endsWith('.wikipedia.org')) {
    return 'Wikipedia';
  }
  if (host == 'wikidata.org' || host.endsWith('.wikidata.org')) {
    return 'Wikidata';
  }
  return host.replaceFirst('www.', '').isEmpty
      ? value
      : host.replaceFirst('www.', '');
}

List<String> sortedCatalogSourceUrls(Iterable<String> values) {
  final result = values
      .where((url) => url.startsWith('https://') || url.startsWith('http://'))
      .toSet()
      .toList();
  result.sort((first, second) {
    final tierResult = catalogSourceTier(first)
        .index
        .compareTo(catalogSourceTier(second).index);
    if (tierResult != 0) return tierResult;
    return catalogSourceName(first).compareTo(catalogSourceName(second));
  });
  return result;
}

class CropSpecificSource {
  final String providerId;
  final String publisher;
  final String url;
  final String evidenceTier;
  final List<String> regions;
  final Set<String> covers;

  const CropSpecificSource({
    required this.providerId,
    required this.publisher,
    required this.url,
    required this.evidenceTier,
    required this.regions,
    required this.covers,
  });

  bool get isRegional =>
      regions.any((region) => region == 'UA' || region == 'PL');

  bool supports(String fact) => covers.contains(fact);
}

class CropSpecificSourceIndex {
  final String checkedOn;
  final Map<String, List<CropSpecificSource>> records;

  const CropSpecificSourceIndex({
    required this.checkedOn,
    required this.records,
  });

  factory CropSpecificSourceIndex.fromJson(Map<String, dynamic> json) {
    final providerJson = Map<String, dynamic>.from(
      json['providers'] as Map? ?? const {},
    );
    final providers = <String, Map<String, dynamic>>{
      for (final entry in providerJson.entries)
        entry.key: Map<String, dynamic>.from(entry.value as Map? ?? const {}),
    };
    final recordJson = Map<String, dynamic>.from(
      json['records'] as Map? ?? const {},
    );
    final records = <String, List<CropSpecificSource>>{};

    for (final record in recordJson.entries) {
      final value = Map<String, dynamic>.from(
        record.value as Map? ?? const {},
      );
      final sources = <CropSpecificSource>[];
      for (final rawSource in (value['sources'] as List? ?? const [])) {
        if (rawSource is! Map) continue;
        final source = Map<String, dynamic>.from(rawSource);
        final providerId = source['provider'] as String? ?? '';
        final provider = providers[providerId];
        if (provider == null) {
          throw FormatException(
            'Unknown crop source provider "$providerId" for ${record.key}',
          );
        }
        final baseUrl = provider['base_url'] as String? ?? '';
        final path = source['path'] as String? ?? '';
        final url = Uri.tryParse(baseUrl)?.resolve(path).toString() ?? '';
        final tier = provider['evidence_tier'] as String? ?? '';
        final covers = (source['covers'] as List? ??
                provider['default_covers'] as List? ??
                const [])
            .whereType<String>()
            .toSet();
        if (!url.startsWith('https://') ||
            !{'A', 'B'}.contains(tier) ||
            covers.isEmpty) {
          throw FormatException(
            'Invalid crop-specific source for ${record.key}: $url',
          );
        }
        sources.add(
          CropSpecificSource(
            providerId: providerId,
            publisher: provider['publisher'] as String? ?? providerId,
            url: url,
            evidenceTier: tier,
            regions: (provider['regions'] as List? ?? const [])
                .whereType<String>()
                .toList(growable: false),
            covers: covers,
          ),
        );
      }
      if (sources.isEmpty) {
        throw FormatException(
          'Crop-specific sources are missing for ${record.key}',
        );
      }
      records[record.key] = List.unmodifiable(sources);
    }

    return CropSpecificSourceIndex(
      checkedOn: json['checked_on'] as String? ?? '',
      records: Map.unmodifiable(records),
    );
  }

  List<CropSpecificSource> forSlug(String slug) => records[slug] ?? const [];
}

class CatalogFact {
  final Object? value;
  final List<String> sourceUrls;
  final String checkedOn;
  final CatalogReliability reliability;
  final String note;

  const CatalogFact({
    required this.value,
    this.sourceUrls = const [],
    this.checkedOn = '',
    this.reliability = CatalogReliability.unknown,
    this.note = '',
  });

  factory CatalogFact.fromJson(Object? source) {
    if (source is! Map) return CatalogFact(value: source);
    final json = Map<String, dynamic>.from(source);
    return CatalogFact(
      value: json['value'],
      sourceUrls: sortedCatalogSourceUrls(
        (json['source_urls'] as List? ?? const [])
            .whereType<String>()
            .where((url) => url.trim().isNotEmpty),
      ),
      checkedOn: json['checked_on'] as String? ?? '',
      reliability: catalogReliabilityFromString(json['reliability']),
      note: json['note'] as String? ?? '',
    );
  }

  String get text {
    final current = value;
    if (current == null) return 'Не вказано';
    if (current is List) return current.join(', ');
    if (current is Map) return current.values.join(', ');
    return current.toString();
  }

  List<String> get stringList =>
      value is List ? (value as List).whereType<String>().toList() : const [];

  String? mapString(String key) {
    final current = value;
    if (current is! Map) return null;
    final result = current[key];
    return result is String && result.trim().isNotEmpty ? result : null;
  }

  CatalogFact withAddedSources(
    Iterable<String> values, {
    String sourceCheckedOn = '',
  }) {
    final added = values.where((value) => value.trim().isNotEmpty).toList();
    if (added.isEmpty) return this;
    final updatedCheckedOn =
        sourceCheckedOn.compareTo(checkedOn) > 0 ? sourceCheckedOn : checkedOn;
    return CatalogFact(
      value: value,
      sourceUrls: sortedCatalogSourceUrls([...sourceUrls, ...added]),
      checkedOn: updatedCheckedOn,
      reliability: reliability,
      note: note,
    );
  }
}

class CropCatalogEntry {
  final String catalogId;
  final String slug;
  final CatalogFact nameUk;
  final CatalogFact namePl;
  final CatalogFact nameEn;
  final CatalogFact latinName;
  final CatalogFact familyLatin;
  final CatalogFact familyUk;
  final CatalogFact familyPl;
  final CatalogFact category;
  final CatalogFact marketUkraine;
  final CatalogFact marketPoland;
  final CatalogFact sowingUkraine;
  final CatalogFact transplantingUkraine;
  final CatalogFact sowingPoland;
  final CatalogFact transplantingPoland;
  final CatalogFact spacing;
  final CatalogFact soilAndPh;
  final CatalogFact watering;
  final CatalogFact fertilization;
  final CatalogFact maturity;
  final CatalogFact harvest;
  final CatalogFact minimumRotationYears;
  final CatalogFact recommendedPreviousCrops;
  final CatalogFact avoidPreviousCrops;
  final CatalogFact compatibleCompanions;
  final CatalogFact undesirableCompanions;
  final CatalogFact typicalDiseases;
  final CatalogFact wikipedia;
  final CatalogFact wikidataId;
  final CatalogFact wikidataUrl;
  final int independentAgronomySourceCount;
  final int officialScientificSourceCount;
  final String verificationStatus;
  final String verificationCheckedOn;
  final List<CropSpecificSource> cropSpecificSources;
  final String cropSpecificSourcesCheckedOn;

  const CropCatalogEntry({
    required this.catalogId,
    required this.slug,
    required this.nameUk,
    required this.namePl,
    required this.nameEn,
    required this.latinName,
    required this.familyLatin,
    required this.familyUk,
    required this.familyPl,
    required this.category,
    required this.marketUkraine,
    required this.marketPoland,
    required this.sowingUkraine,
    required this.transplantingUkraine,
    required this.sowingPoland,
    required this.transplantingPoland,
    required this.spacing,
    required this.soilAndPh,
    required this.watering,
    required this.fertilization,
    required this.maturity,
    required this.harvest,
    required this.minimumRotationYears,
    required this.recommendedPreviousCrops,
    required this.avoidPreviousCrops,
    required this.compatibleCompanions,
    required this.undesirableCompanions,
    required this.typicalDiseases,
    required this.wikipedia,
    required this.wikidataId,
    required this.wikidataUrl,
    required this.independentAgronomySourceCount,
    required this.officialScientificSourceCount,
    required this.verificationStatus,
    required this.verificationCheckedOn,
    this.cropSpecificSources = const [],
    this.cropSpecificSourcesCheckedOn = '',
  });

  factory CropCatalogEntry.fromJson(
    Map<String, dynamic> json, {
    List<CropSpecificSource> cropSpecificSources = const [],
    String cropSpecificSourcesCheckedOn = '',
  }) {
    Map<String, dynamic> section(String key) =>
        Map<String, dynamic>.from(json[key] as Map? ?? const {});
    Map<String, dynamic> child(Map<String, dynamic> parent, String key) =>
        Map<String, dynamic>.from(parent[key] as Map? ?? const {});

    final names = section('names');
    final taxonomy = section('taxonomy');
    final markets = section('market_availability');
    final cultivation = section('cultivation');
    final cultivationUkraine = child(cultivation, 'ukraine');
    final cultivationPoland = child(cultivation, 'poland');
    final rotation = section('rotation');
    final companions = section('companions');
    final knowledge = section('knowledge_links');
    final verification = section('verification');
    CatalogFact sourced(Object? value, String coverage) =>
        CatalogFact.fromJson(value).withAddedSources(
          cropSpecificSources
              .where((source) => source.supports(coverage))
              .map((source) => source.url),
          sourceCheckedOn: cropSpecificSourcesCheckedOn,
        );

    return CropCatalogEntry(
      catalogId: json['catalog_id'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      nameUk: CatalogFact.fromJson(names['uk']),
      namePl: CatalogFact.fromJson(names['pl']),
      nameEn: CatalogFact.fromJson(names['en']),
      latinName: CatalogFact.fromJson(names['latin']),
      familyLatin: CatalogFact.fromJson(taxonomy['family_latin']),
      familyUk: CatalogFact.fromJson(taxonomy['family_uk']),
      familyPl: CatalogFact.fromJson(taxonomy['family_pl']),
      category: CatalogFact.fromJson(taxonomy['category']),
      marketUkraine: CatalogFact.fromJson(markets['ukraine']),
      marketPoland: CatalogFact.fromJson(markets['poland']),
      sowingUkraine: sourced(cultivationUkraine['sowing'], 'sowing'),
      transplantingUkraine:
          sourced(cultivationUkraine['transplanting'], 'transplanting'),
      sowingPoland: sourced(cultivationPoland['sowing'], 'sowing'),
      transplantingPoland:
          sourced(cultivationPoland['transplanting'], 'transplanting'),
      spacing: sourced(cultivation['spacing'], 'spacing'),
      soilAndPh: sourced(cultivation['soil_and_pH'], 'soil'),
      watering: sourced(cultivation['watering'], 'watering'),
      fertilization: sourced(cultivation['fertilization'], 'fertilization'),
      maturity: sourced(cultivation['maturity'], 'maturity'),
      harvest: sourced(cultivation['harvest'], 'harvest'),
      minimumRotationYears:
          sourced(rotation['minimum_years_before_same_family'], 'rotation'),
      recommendedPreviousCrops:
          sourced(rotation['recommended_previous_crops'], 'rotation'),
      avoidPreviousCrops: sourced(rotation['avoid_previous_crops'], 'rotation'),
      compatibleCompanions: CatalogFact.fromJson(companions['compatible']),
      undesirableCompanions: CatalogFact.fromJson(companions['undesirable']),
      typicalDiseases: sourced(json['typical_diseases'], 'diseases'),
      wikipedia: CatalogFact.fromJson(knowledge['wikipedia']),
      wikidataId: CatalogFact.fromJson(knowledge['wikidata_id']),
      wikidataUrl: CatalogFact.fromJson(knowledge['wikidata_url']),
      independentAgronomySourceCount:
          verification['independent_agronomy_source_count'] as int? ?? 0,
      officialScientificSourceCount:
          verification['official_scientific_source_count'] as int? ?? 0,
      verificationStatus: verification['status'] as String? ?? '',
      verificationCheckedOn: verification['checked_on'] as String? ?? '',
      cropSpecificSources: List.unmodifiable(cropSpecificSources),
      cropSpecificSourcesCheckedOn: cropSpecificSourcesCheckedOn,
    );
  }

  int get cropSpecificSourceCount => cropSpecificSources.length;

  int get regionalCropSpecificSourceCount =>
      cropSpecificSources.where((source) => source.isRegional).length;

  String get searchableText => [
        catalogId,
        slug,
        nameUk.text,
        namePl.text,
        nameEn.text,
        latinName.text,
        familyLatin.text,
        familyUk.text,
        familyPl.text,
        category.text,
      ].join(' ').toLowerCase();

  String get primaryWikiUrl => wikipedia.text.startsWith('http')
      ? wikipedia.text
      : (wikidataUrl.text.startsWith('http') ? wikidataUrl.text : '');

  String get marketUkraineUrl =>
      marketUkraine.mapString('market_search_url') ?? '';

  String get marketPolandUrl =>
      marketPoland.mapString('market_search_url') ?? '';

  Crop toCrop() {
    final legacy = _legacyCropIdentity[slug];
    final family = _cropFamilyForLatin(familyLatin.text);
    return Crop(
      id: legacy?.$1 ?? 'crop_catalog_$slug',
      name: legacy?.$2 ?? _capitalized(nameUk.text),
      season: _seasonFromSowing(sowingUkraine.text),
      family: family,
      recommendation: watering.text,
      catalogId: catalogId,
      slug: slug,
      namePl: namePl.text,
      nameEn: nameEn.text,
      latinName: latinName.text,
      familyLatin: familyLatin.text,
      sowingUkraine: sowingUkraine.text,
      sowingPoland: sowingPoland.text,
      transplantingUkraine: transplantingUkraine.text,
      transplantingPoland: transplantingPoland.text,
      spacing: spacing.text,
      soilAndPh: soilAndPh.text,
      watering: watering.text,
      fertilization: fertilization.text,
      maturity: maturity.text,
      harvest: harvest.text,
      typicalDiseases: typicalDiseases.stringList,
      diseaseSourceUrls: typicalDiseases.sourceUrls,
      minimumRotationYears: minimumRotationYears.value is num
          ? (minimumRotationYears.value as num).toInt()
          : null,
      wikiUrl: primaryWikiUrl,
      wikidataUrl: wikidataUrl.text.startsWith('http') ? wikidataUrl.text : '',
      catalogCheckedOn: verificationCheckedOn,
      catalogReliability: watering.reliability.name,
      stageTimings: structuredStageTimingsFor(
        slug,
        maturity.sourceUrls,
      ),
      spacingRules: structuredSpacingRulesFor(
        slug,
        spacing.sourceUrls,
      ),
      wateringRules: structuredWateringRulesFor(
        watering.text,
        watering.sourceUrls,
      ),
      protectionRisks: structuredProtectionRisksFor(
        slug: slug,
        family: family,
        diseases: typicalDiseases.stringList,
        sourceUrls: typicalDiseases.sourceUrls,
      ),
    );
  }
}

class CropCatalog {
  final String dataset;
  final String version;
  final int batch;
  final int declaredRecordCount;
  final String checkedOn;
  final String scope;
  final String auditStatus;
  final String verificationRule;
  final List<String> limitations;
  final String qaStatus;
  final String qaImportantLimit;
  final List<CropCatalogEntry> records;

  const CropCatalog({
    required this.dataset,
    required this.version,
    required this.batch,
    required this.declaredRecordCount,
    required this.checkedOn,
    required this.scope,
    required this.auditStatus,
    required this.verificationRule,
    required this.limitations,
    required this.qaStatus,
    required this.qaImportantLimit,
    required this.records,
  });

  factory CropCatalog.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic> qa = const {},
    CropSpecificSourceIndex? cropSpecificSources,
  }) {
    final records =
        (json['records'] as List? ?? const []).whereType<Map>().map((item) {
      final record = Map<String, dynamic>.from(item);
      final slug = record['slug'] as String? ?? '';
      return CropCatalogEntry.fromJson(
        record,
        cropSpecificSources: cropSpecificSources?.forSlug(slug) ?? const [],
        cropSpecificSourcesCheckedOn: cropSpecificSources?.checkedOn ?? '',
      );
    }).toList(growable: false);
    final declaredCount = json['record_count'] as int? ?? records.length;
    if (declaredCount != records.length) {
      throw FormatException(
        'Catalog record count mismatch: $declaredCount != ${records.length}',
      );
    }
    final ids = records.map((item) => item.catalogId).toSet();
    final slugs = records.map((item) => item.slug).toSet();
    if (ids.length != records.length || slugs.length != records.length) {
      throw const FormatException('Catalog ids and slugs must be unique');
    }
    if (cropSpecificSources != null &&
        (cropSpecificSources.records.keys
                .toSet()
                .difference(slugs)
                .isNotEmpty ||
            slugs
                .difference(cropSpecificSources.records.keys.toSet())
                .isNotEmpty)) {
      throw const FormatException(
        'Crop-specific source slugs must match catalog slugs',
      );
    }
    if (records.any((item) =>
        item.catalogId.isEmpty ||
        item.slug.isEmpty ||
        item.nameUk.text == 'Не вказано' ||
        item.namePl.text == 'Не вказано')) {
      throw const FormatException('Catalog contains incomplete core fields');
    }
    return CropCatalog(
      dataset: json['dataset'] as String? ?? '',
      version: json['dataset_version'] as String? ?? '',
      batch: json['batch'] as int? ?? 0,
      declaredRecordCount: declaredCount,
      checkedOn: json['checked_on'] as String? ?? '',
      scope: json['scope'] as String? ?? '',
      auditStatus: json['audit_status'] as String? ?? '',
      verificationRule: json['verification_rule'] as String? ?? '',
      limitations: (json['limitations'] as List? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      qaStatus: qa['overall_status'] as String? ?? '',
      qaImportantLimit: qa['important_limit'] as String? ?? '',
      records: records,
    );
  }

  List<Crop> toCrops() =>
      records.map((record) => record.toCrop()).toList(growable: false);

  List<String> get categories =>
      records.map((record) => record.category.text).toSet().toList()..sort();
}

String cropCategoryLabel(String value) => switch (value) {
      'fruiting vegetable' => 'Плодові овочі',
      'root vegetable' => 'Коренеплоди',
      'leaf vegetable' || 'perennial leaf vegetable' => 'Листові',
      'legume' => 'Бобові',
      'bulb vegetable' || 'stem and bulb vegetable' => 'Цибулеві',
      'head brassica' ||
      'leaf brassica' ||
      'leaf and head brassica' ||
      'flower vegetable' ||
      'bud vegetable' =>
        'Капустяні',
      'annual herb' ||
      'biennial herb' ||
      'perennial herb' ||
      'tender perennial herb' ||
      'annual or tender perennial herb' =>
        'Пряні трави',
      'tuber crop' => 'Бульбоплоди',
      'stem vegetable' || 'leaf and stem vegetable' => 'Стеблові',
      _ => 'Інші',
    };

const _legacyCropIdentity = <String, (String, String)>{
  'tomato': ('crop_tomato', 'Томат'),
  'cucumber': ('crop_cucumber', 'Огірок'),
  'carrot': ('crop_carrot', 'Морква'),
  'common_bean': ('crop_bean', 'Квасоля'),
  'pea': ('crop_pea', 'Горох'),
  'white_cabbage': ('crop_cabbage', 'Капуста'),
  'onion': ('crop_onion', 'Цибуля'),
  'lettuce': ('crop_lettuce', 'Салат'),
};

String _capitalized(String value) {
  if (value.isEmpty) return value;
  return '${value[0].toUpperCase()}${value.substring(1)}';
}

Season _seasonFromSowing(String value) {
  final text = value.toLowerCase();
  if (text.contains('верес') ||
      text.contains('жовт') ||
      text.contains('листоп')) {
    return Season.autumn;
  }
  if (text.contains('черв') || text.contains('лип') || text.contains('серп')) {
    return Season.summer;
  }
  if (text.contains('груд') || text.contains('січ')) return Season.winter;
  return Season.spring;
}

CropFamily _cropFamilyForLatin(String value) => switch (value) {
      'Solanaceae' => CropFamily.nightshade,
      'Cucurbitaceae' => CropFamily.cucurbit,
      'Apiaceae' => CropFamily.apiaceae,
      'Fabaceae' => CropFamily.legume,
      'Brassicaceae' => CropFamily.brassica,
      'Amaryllidaceae' => CropFamily.allium,
      'Asteraceae' || 'Amaranthaceae' => CropFamily.leafy,
      'Poaceae' => CropFamily.grass,
      _ => CropFamily.other,
    };
