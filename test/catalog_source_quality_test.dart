import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garden_mii/src/catalog/crop_catalog.dart';
import 'package:garden_mii/src/catalog/crop_catalog_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('trusted source registry is complete and machine-readable', () async {
    final raw = await rootBundle.loadString(
      'assets/data/crop_catalog/trusted_source_registry.json',
    );
    final registry = jsonDecode(raw) as Map<String, dynamic>;
    final sources = (registry['sources'] as List).cast<Map>();
    final ids = sources.map((source) => source['id']).toSet();

    expect(registry['checked_on'], '2026-07-30');
    expect(sources.length, greaterThanOrEqualTo(15));
    expect(ids.length, sources.length);
    expect(
      sources.every(
        (source) =>
            (source['url'] as String).startsWith('https://') &&
            {'A', 'B'}.contains(source['evidence_tier']),
      ),
      isTrue,
    );
  });

  test('encyclopaedias are reference-only, not agronomic evidence', () {
    expect(
      catalogSourceTier('https://en.wikipedia.org/wiki/Tomato'),
      CatalogSourceTier.reference,
    );
    expect(
      catalogSourceTier('https://www.wikidata.org/wiki/Q23501'),
      CatalogSourceTier.reference,
    );
    expect(
      catalogSourceTier('https://dpss.gov.ua/diyalnist/fitosanitariya'),
      CatalogSourceTier.official,
    );
    expect(
      catalogSourceTier('https://extension.umn.edu/vegetables'),
      CatalogSourceTier.scientific,
    );
  });

  test('every catalog crop has a page-level authoritative source', () async {
    final sourceRaw = await rootBundle.loadString(
      CropCatalogRepository.cropSpecificSourcesAsset,
    );
    final catalogRaw = await rootBundle.loadString(
      CropCatalogRepository.dataAsset,
    );
    final sourceJson = jsonDecode(sourceRaw) as Map<String, dynamic>;
    final catalogJson = jsonDecode(catalogRaw) as Map<String, dynamic>;
    final index = CropSpecificSourceIndex.fromJson(sourceJson);
    final catalogSlugs = (catalogJson['records'] as List)
        .cast<Map>()
        .map((record) => record['slug'])
        .toSet();

    expect(index.checkedOn, '2026-07-30');
    expect(index.records, hasLength(50));
    expect(index.records.keys.toSet(), catalogSlugs);
    for (final entry in index.records.entries) {
      expect(entry.value, isNotEmpty, reason: entry.key);
      for (final source in entry.value) {
        expect(source.url, startsWith('https://'), reason: entry.key);
        expect({'A', 'B'}, contains(source.evidenceTier), reason: entry.key);
        expect(source.covers, isNotEmpty, reason: entry.key);
        expect(
          source.url,
          isNot(anyOf(contains('wikipedia.org'), contains('wikidata.org'))),
          reason: entry.key,
        );
      }
    }
  });

  test('page-level sources are attached to the facts they cover', () async {
    final catalog = await CropCatalogRepository.load();

    expect(
      catalog.records.every((entry) => entry.cropSpecificSourceCount > 0),
      isTrue,
    );
    for (final entry in catalog.records) {
      final attachedUrls = <String>{
        ...entry.sowingUkraine.sourceUrls,
        ...entry.transplantingUkraine.sourceUrls,
        ...entry.sowingPoland.sourceUrls,
        ...entry.transplantingPoland.sourceUrls,
        ...entry.spacing.sourceUrls,
        ...entry.soilAndPh.sourceUrls,
        ...entry.watering.sourceUrls,
        ...entry.fertilization.sourceUrls,
        ...entry.maturity.sourceUrls,
        ...entry.harvest.sourceUrls,
        ...entry.minimumRotationYears.sourceUrls,
        ...entry.recommendedPreviousCrops.sourceUrls,
        ...entry.avoidPreviousCrops.sourceUrls,
        ...entry.typicalDiseases.sourceUrls,
      };
      expect(
        attachedUrls,
        containsAll(entry.cropSpecificSources.map((source) => source.url)),
        reason: entry.slug,
      );
    }

    final tomato =
        catalog.records.firstWhere((entry) => entry.slug == 'tomato');
    expect(tomato.cropSpecificSourceCount, 4);
    expect(tomato.regionalCropSpecificSourceCount, 3);
    expect(
      tomato.watering.sourceUrls,
      contains('https://www.rhs.org.uk/vegetables/tomatoes/grow-your-own'),
    );
    expect(
      tomato.fertilization.sourceUrls,
      contains(
        'https://ovoch.com/assets/files/naykovi_rozrobku/zaversheni/kuc-pomidor.pdf',
      ),
    );
  });

  test('source sorting puts official evidence before references', () {
    final sorted = sortedCatalogSourceUrls([
      'https://en.wikipedia.org/wiki/Tomato',
      'https://extension.umn.edu/vegetables/growing-tomatoes',
      'https://dpss.gov.ua/diyalnist/fitosanitariya',
    ]);

    expect(catalogSourceTier(sorted.first), CatalogSourceTier.official);
    expect(catalogSourceTier(sorted.last), CatalogSourceTier.reference);
  });

  test('repeated source URLs are displayed once per fact', () {
    final fact = CatalogFact.fromJson({
      'value': 'лютий–березень',
      'source_urls': [
        'https://example.com/tomato',
        'https://example.com/tomato',
      ],
    });

    expect(fact.sourceUrls, ['https://example.com/tomato']);
  });
}
