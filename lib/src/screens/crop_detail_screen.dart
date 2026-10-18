import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_theme.dart';
import '../care_recommendations.dart';
import '../catalog/crop_catalog.dart';
import '../catalog/crop_catalog_repository.dart';
import '../catalog/crop_photo_catalog.dart';
import '../feedback/feedback_mailer.dart';
import 'feedback_screen.dart';

class CropDetailScreen extends StatefulWidget {
  final CropCatalogEntry entry;

  const CropDetailScreen({super.key, required this.entry});

  @override
  State<CropDetailScreen> createState() => _CropDetailScreenState();
}

class _CropDetailScreenState extends State<CropDetailScreen> {
  CropCatalogEntry get entry => widget.entry;
  late Future<CropPhotoPair?> _photoPair;
  late Future<_ConcreteRotationGuide> _rotationGuide;

  @override
  void initState() {
    super.initState();
    _photoPair = _loadPhotoPair();
    _rotationGuide = _loadRotationGuide();
  }

  @override
  void didUpdateWidget(covariant CropDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.slug != widget.entry.slug) {
      _photoPair = _loadPhotoPair();
      _rotationGuide = _loadRotationGuide();
    }
  }

  Future<CropPhotoPair?> _loadPhotoPair() async {
    final catalog = await CropPhotoRepository.load();
    return catalog.records[entry.slug];
  }

  Future<_ConcreteRotationGuide> _loadRotationGuide() async {
    final catalog = await CropCatalogRepository.load();
    final crops = catalog.toCrops();
    final planned = crops.where((crop) => crop.slug == entry.slug).firstOrNull;
    if (planned == null) {
      return _ConcreteRotationGuide(
        recommendedBefore: entry.recommendedPreviousCrops,
        avoidBefore: entry.avoidPreviousCrops,
        recommendedAfter: entry.recommendedPreviousCrops,
      );
    }
    final before = predecessorSuggestionsFor(planned, crops);
    final avoid = sameFamilyCropsFor(planned, crops);
    final after = rotationSuggestionsFor(planned, crops, limit: 6);
    final afterSources = {
      ...entry.recommendedPreviousCrops.sourceUrls,
      ...entry.avoidPreviousCrops.sourceUrls,
      ...entry.minimumRotationYears.sourceUrls,
    }.toList();

    return _ConcreteRotationGuide(
      recommendedBefore: CatalogFact(
        value: before.map((crop) => crop.name).toList(),
        sourceUrls: entry.recommendedPreviousCrops.sourceUrls,
        checkedOn: entry.recommendedPreviousCrops.checkedOn,
        reliability: entry.recommendedPreviousCrops.reliability,
        note:
            'Конкретні приклади з каталогу. Обирайте культури з іншої родини та враховуйте історію саме цієї грядки.',
      ),
      avoidBefore: CatalogFact(
        value: avoid.map((crop) => crop.name).toList(),
        sourceUrls: entry.avoidPreviousCrops.sourceUrls,
        checkedOn: entry.avoidPreviousCrops.checkedOn,
        reliability: entry.avoidPreviousCrops.reliability,
        note:
            'Ці культури належать до тієї самої родини й можуть накопичувати спільні хвороби та шкідників.',
      ),
      recommendedAfter: CatalogFact(
        value: after.map((crop) => crop.name).toList(),
        sourceUrls: afterSources,
        checkedOn: entry.recommendedPreviousCrops.checkedOn,
        reliability: entry.recommendedPreviousCrops.reliability,
        note:
            'Варіанти для наступної посадки після збору. Остаточний вибір залежить від сезону, ґрунту й місцевого клімату.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sowing = _combineRegionalFacts(
      entry.sowingUkraine,
      entry.sowingPoland,
    );
    final transplanting = _combineRegionalFacts(
      entry.transplantingUkraine,
      entry.transplantingPoland,
    );
    final selectedFacts = [
      sowing,
      transplanting,
      entry.spacing,
      entry.soilAndPh,
      entry.watering,
      entry.fertilization,
      entry.maturity,
      entry.harvest,
      entry.minimumRotationYears,
      entry.recommendedPreviousCrops,
      entry.avoidPreviousCrops,
      entry.compatibleCompanions,
      entry.undesirableCompanions,
      entry.typicalDiseases,
    ];
    final sourceUrls = sortedCatalogSourceUrls(
      [
        ...selectedFacts.expand((fact) => fact.sourceUrls),
        if (entry.primaryWikiUrl.isNotEmpty) entry.primaryWikiUrl,
        if (entry.wikidataUrl.text.startsWith('http')) entry.wikidataUrl.text,
      ],
    );
    final evidenceSourceUrls = sourceUrls
        .where(
          (url) => {
            CatalogSourceTier.official,
            CatalogSourceTier.scientific,
          }.contains(catalogSourceTier(url)),
        )
        .toList(growable: false);
    final practicalSourceUrls = sourceUrls
        .where(
          (url) => catalogSourceTier(url) == CatalogSourceTier.practical,
        )
        .toList(growable: false);
    final referenceSourceUrls = sourceUrls
        .where(
          (url) => catalogSourceTier(url) == CatalogSourceTier.reference,
        )
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          entry.nameUk.text,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Запропонувати виправлення',
            onPressed: _openFeedback,
            icon: const Icon(Icons.rate_review_outlined),
          ),
          IconButton(
            tooltip: 'Перевірені джерела',
            onPressed: evidenceSourceUrls.isEmpty
                ? null
                : () => _showSources(evidenceSourceUrls),
            icon: const Icon(Icons.verified_outlined),
          ),
        ],
      ),
      body: ListView(
        key: const Key('crop-detail-scroll'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
        children: [
          _IdentityCard(entry: entry),
          const SizedBox(height: 12),
          FutureBuilder<CropPhotoPair?>(
            future: _photoPair,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library_outlined),
                      SizedBox(width: 8),
                      Text('Завантажуємо фото…'),
                    ],
                  ),
                );
              }
              final photos = snapshot.data;
              if (snapshot.hasError || photos == null) {
                return const _CropPhotoUnavailable();
              }
              return _CropPhotoGallery(
                cropName: entry.nameUk.text,
                cropSlug: entry.slug,
                photos: photos,
                onOpen: _showPhoto,
              );
            },
          ),
          const SizedBox(height: 12),
          _EvidenceNotice(entry: entry),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            key: const Key('open-crop-feedback'),
            onPressed: _openFeedback,
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('Запропонувати виправлення'),
          ),
          const SizedBox(height: 20),
          const _PlanIntroduction(),
          const SizedBox(height: 12),
          _StageSection(
            key: const Key('crop-stage-soil'),
            step: 1,
            icon: Icons.landscape_outlined,
            title: 'Підготуйте ґрунт і грядку',
            subtitle: 'Ґрунт, pH та сівозміна до посадки',
            initiallyExpanded: true,
            children: [
              _FactCard(
                icon: Icons.landscape_outlined,
                title: 'Ґрунт і pH',
                fact: entry.soilAndPh,
              ),
              FutureBuilder<_ConcreteRotationGuide>(
                future: _rotationGuide,
                builder: (context, snapshot) {
                  final guide = snapshot.data;
                  return Column(
                    key: const Key('concrete-rotation-guide'),
                    children: [
                      _FactCard(
                        icon: Icons.check_circle_outline_rounded,
                        title: 'Добрі попередники (до посадки)',
                        fact: guide?.recommendedBefore ??
                            entry.recommendedPreviousCrops,
                      ),
                      _FactCard(
                        icon: Icons.block_rounded,
                        title: 'Після яких культур не садити',
                        fact: guide?.avoidBefore ?? entry.avoidPreviousCrops,
                      ),
                    ],
                  );
                },
              ),
              _FactCard(
                icon: Icons.history_toggle_off_rounded,
                title: 'Коли можна повернути цю родину',
                fact: entry.minimumRotationYears,
                valueSuffix: ' роки',
              ),
            ],
          ),
          _StageSection(
            key: const Key('crop-stage-planting'),
            step: 2,
            icon: Icons.grass_rounded,
            title: 'Посійте або висадіть',
            subtitle: 'Строки, спосіб і відстань між рослинами',
            children: [
              const _RegionalNotice(),
              const SizedBox(height: 9),
              _FactCard(
                icon: Icons.calendar_month_outlined,
                title: 'Посів',
                fact: sowing,
              ),
              _FactCard(
                icon: Icons.move_down_rounded,
                title: 'Висаджування',
                fact: transplanting,
              ),
              _FactCard(
                icon: Icons.straighten_rounded,
                title: 'Відстань',
                fact: entry.spacing,
              ),
            ],
          ),
          _StageSection(
            key: const Key('crop-stage-care'),
            step: 3,
            icon: Icons.water_drop_outlined,
            title: 'Доглядайте під час росту',
            subtitle: 'Полив і регулярна перевірка рослини',
            children: [
              _FactCard(
                icon: Icons.water_drop_outlined,
                title: 'Полив',
                fact: entry.watering,
              ),
            ],
          ),
          _StageSection(
            key: const Key('crop-stage-harvest'),
            step: 4,
            icon: Icons.shopping_basket_outlined,
            title: 'Дочекайтеся стиглості та зберіть',
            subtitle: 'Ознаки дозрівання і строки збору',
            children: [
              _FactCard(
                icon: Icons.timelapse_rounded,
                title: 'Дозрівання',
                fact: entry.maturity,
              ),
              _FactCard(
                icon: Icons.shopping_basket_outlined,
                title: 'Збір урожаю',
                fact: entry.harvest,
              ),
            ],
          ),
          _StageSection(
            key: const Key('crop-stage-next'),
            step: 5,
            icon: Icons.change_circle_outlined,
            title: 'Заплануйте наступну посадку',
            subtitle: 'Конкретні культури, які можна посадити після збору',
            children: [
              FutureBuilder<_ConcreteRotationGuide>(
                future: _rotationGuide,
                builder: (context, snapshot) {
                  final guide = snapshot.data;
                  return _FactCard(
                    key: const Key('recommended-after-harvest'),
                    icon: Icons.change_circle_outlined,
                    title: 'Що посадити після цієї культури',
                    fact: guide?.recommendedAfter ??
                        entry.recommendedPreviousCrops,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _SectionTitle('Додатково'),
          _ExtraSection(
            key: const Key('crop-extra-neighbours'),
            icon: Icons.group_work_outlined,
            title: 'Сусідство культур',
            subtitle: 'Що можна і небажано вирощувати поруч',
            children: [
              _FactCard(
                icon: Icons.group_work_outlined,
                title: 'Сумісні культури',
                fact: entry.compatibleCompanions,
              ),
              _FactCard(
                icon: Icons.remove_circle_outline_rounded,
                title: 'Небажане сусідство',
                fact: entry.undesirableCompanions,
              ),
            ],
          ),
          _ExtraSection(
            key: const Key('crop-extra-fertilizers'),
            icon: Icons.science_outlined,
            title: 'Добрива',
            subtitle: 'Додаткове підживлення за потреби',
            children: [
              _FactCard(
                icon: Icons.science_outlined,
                title: 'Рекомендації щодо добрив',
                fact: entry.fertilization,
              ),
            ],
          ),
          _ExtraSection(
            key: const Key('crop-extra-safety'),
            icon: Icons.health_and_safety_outlined,
            title: 'Захист і безпека',
            subtitle: 'Хвороби, огляд рослин і безпечна обробка',
            children: [
              _FactCard(
                icon: Icons.bug_report_outlined,
                title: 'Типові хвороби',
                fact: entry.typicalDiseases,
              ),
              const _SafetyNotice(),
            ],
          ),
          const SizedBox(height: 18),
          const _SectionTitle('Перевірені джерела'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.softGreen,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_user_outlined, color: AppColors.primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Офіційні, наукові та дорадчі матеріали показані першими. '
                    'Wikipedia і Wikidata залишені лише як довідкові переходи '
                    'та не підтверджують агрономічні поради.',
                    style: TextStyle(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ExpansionTile(
            key: const Key('trusted-crop-sources'),
            tilePadding: const EdgeInsets.symmetric(horizontal: 4),
            title: Text(
              'Надійні джерела (${evidenceSourceUrls.length})',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            children: [
              for (final url in evidenceSourceUrls)
                _SourceLinkTile(url: url, onOpen: _openUrl),
            ],
          ),
          if (practicalSourceUrls.isNotEmpty)
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 4),
              title: Text(
                'Додаткові практичні матеріали '
                '(${practicalSourceUrls.length})',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              children: [
                for (final url in practicalSourceUrls)
                  _SourceLinkTile(url: url, onOpen: _openUrl),
              ],
            ),
          if (referenceSourceUrls.isNotEmpty)
            ExpansionTile(
              key: const Key('reference-only-crop-sources'),
              tilePadding: const EdgeInsets.symmetric(horizontal: 4),
              title: Text(
                'Довідкові переходи — не докази '
                '(${referenceSourceUrls.length})',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              children: [
                for (final url in referenceSourceUrls)
                  _SourceLinkTile(url: url, onOpen: _openUrl),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _openUrl(String value) async {
    final uri = Uri.tryParse(value);
    final opened = uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не вдалося відкрити посилання.')),
      );
    }
  }

  Future<void> _showSources(List<String> sourceUrls) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.76,
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                child: Text(
                  'Перевірені джерела',
                  style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 0, 18, 10),
                child: Text(
                  'Спочатку відкриваються офіційні та наукові матеріали. '
                  'Для засобів захисту завжди звіряйте чинний реєстр і етикетку.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                  children: [
                    for (final url in sourceUrls)
                      _SourceLinkTile(url: url, onOpen: _openUrl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFeedback() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FeedbackScreen(
          initialKind: FeedbackKind.cropCorrection,
          cropName: entry.nameUk.text,
          cropSlug: entry.slug,
        ),
      ),
    );
  }

  void _showPhoto(CropPhoto photo, String label) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.82,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label • ${entry.nameUk.text}',
                  style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: ColoredBox(
                      color: AppColors.background,
                      child: InteractiveViewer(
                        minScale: 1,
                        maxScale: 4,
                        child: Center(
                          child: Image.asset(
                            photo.assetPath,
                            fit: BoxFit.contain,
                            semanticLabel: '$label: ${entry.nameUk.text}',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  photo.author.isEmpty
                      ? 'Автор вказаний у джерелі'
                      : photo.author,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  photo.license.isEmpty
                      ? 'Ліцензія на сторінці файлу'
                      : photo.license,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: () => _openUrl(photo.sourceUrl),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Автор, ліцензія та оригінал'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

CatalogFact _combineRegionalFacts(CatalogFact first, CatalogFact second) {
  final firstText = first.text;
  final secondText = second.text;
  final values = [firstText, secondText]
      .where((value) => value != 'Не вказано')
      .toSet()
      .toList();
  final text = values.isEmpty
      ? 'Не вказано'
      : values.length == 1
          ? values.first
          : 'Регіональний діапазон: ${values.join('; ')}';
  final reliability = first.reliability.index >= second.reliability.index
      ? first.reliability
      : second.reliability;
  final notes = [first.note, second.note]
      .where((value) => value.trim().isNotEmpty)
      .toSet()
      .join(' ');
  final checkedDates = [first.checkedOn, second.checkedOn]..sort();
  return CatalogFact(
    value: text,
    sourceUrls: {...first.sourceUrls, ...second.sourceUrls}.toList(),
    checkedOn: checkedDates.last,
    reliability: reliability,
    note: notes,
  );
}

class _ConcreteRotationGuide {
  final CatalogFact recommendedBefore;
  final CatalogFact avoidBefore;
  final CatalogFact recommendedAfter;

  const _ConcreteRotationGuide({
    required this.recommendedBefore,
    required this.avoidBefore,
    required this.recommendedAfter,
  });
}

class _CropPhotoGallery extends StatelessWidget {
  final String cropName;
  final String cropSlug;
  final CropPhotoPair photos;
  final void Function(CropPhoto photo, String label) onOpen;

  const _CropPhotoGallery({
    required this.cropName,
    required this.cropSlug,
    required this.photos,
    required this.onOpen,
  });

  static const _pulledCrops = {
    'potato',
    'carrot',
    'beetroot',
    'radish',
    'turnip',
    'parsnip',
    'root_parsley',
    'celeriac',
    'onion',
    'garlic',
    'leek',
  };

  @override
  Widget build(BuildContext context) {
    final harvestedLabel = _pulledCrops.contains(cropSlug)
        ? 'Витягнуто / зібрано'
        : 'Урожай / їстівна частина';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Як виглядає культура',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Реальні фото з Wikimedia Commons. Вигляд сорту, стадія росту й форма врожаю можуть відрізнятися.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 11),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _CropPhotoCard(
                key: const Key('crop-photo-growing'),
                cropName: cropName,
                label: 'У ґрунті',
                photo: photos.growing,
                onTap: () => onOpen(photos.growing, 'У ґрунті'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CropPhotoCard(
                key: const Key('crop-photo-harvested'),
                cropName: cropName,
                label: harvestedLabel,
                photo: photos.harvested,
                onTap: () => onOpen(photos.harvested, harvestedLabel),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CropPhotoUnavailable extends StatelessWidget {
  const _CropPhotoUnavailable();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('crop-photo-unavailable'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.image_not_supported_outlined),
          SizedBox(width: 10),
          Expanded(child: Text('Фото цієї культури поки недоступні.')),
        ],
      ),
    );
  }
}

class _CropPhotoCard extends StatelessWidget {
  final String cropName;
  final String label;
  final CropPhoto photo;
  final VoidCallback onTap;

  const _CropPhotoCard({
    super.key,
    required this.cropName,
    required this.label,
    required this.photo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final author = photo.author.isEmpty ? 'Автор у джерелі' : photo.author;
    final license =
        photo.license.isEmpty ? 'Ліцензія у джерелі' : photo.license;
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.15,
                  child: Image.asset(
                    photo.assetPath,
                    fit: BoxFit.cover,
                    semanticLabel: '$label: $cropName',
                    errorBuilder: (context, error, stackTrace) =>
                        const ColoredBox(
                      color: AppColors.background,
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
              child: Text(
                '$author • $license',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegionalNotice extends StatelessWidget {
  const _RegionalNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on_outlined, color: AppColors.primary),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Строки об’єднані в регіональний діапазон. Уточнюйте їх за місцевими заморозками, температурою ґрунту та сортом.',
              style: TextStyle(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final CropCatalogEntry entry;

  const _IdentityCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.softGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white,
                child: Icon(Icons.eco_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.nameUk.text,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 21,
                      ),
                    ),
                    Text(
                      entry.latinName.text,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _IdentityLine(
            label: 'Інші назви',
            value: [entry.namePl.text, entry.nameEn.text]
                .where((value) => value != 'Не вказано')
                .toSet()
                .join(' • '),
          ),
          _IdentityLine(
            label: 'Родина',
            value: '${entry.familyUk.text} • ${entry.familyLatin.text}',
          ),
          _IdentityLine(
            label: 'Категорія',
            value: cropCategoryLabel(entry.category.text),
          ),
        ],
      ),
    );
  }
}

class _IdentityLine extends StatelessWidget {
  final String label;
  final String value;

  const _IdentityLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _EvidenceNotice extends StatelessWidget {
  final CropCatalogEntry entry;

  const _EvidenceNotice({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        border: Border.all(color: const Color(0xFFFFE0A3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.fact_check_outlined, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${entry.cropSpecificSourceCount} перевірених сторінок саме про '
              'цю культуру'
              '${entry.regionalCropSpecificSourceCount > 0 ? ', з них ${entry.regionalCropSpecificSourceCount} для Польщі або України' : ''}. '
              '${entry.independentAgronomySourceCount} незалежних ресурсів, '
              '${entry.officialScientificSourceCount} офіційних або наукових. '
              'Перевірка виконана на рівні ресурсів; локальні умови, сорт і аналіз ґрунту мають пріоритет.',
              style: const TextStyle(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanIntroduction extends StatelessWidget {
  const _PlanIntroduction();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('crop-step-by-step-plan'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.softGreen,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.route_rounded, color: AppColors.primary, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Покроковий план вирощування',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
                SizedBox(height: 5),
                Text(
                  'Проходьте етапи від підготовки ґрунту до наступної '
                  'посадки. Натисніть на етап, щоб розгорнути або згорнути його.',
                  style: TextStyle(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StageSection extends StatelessWidget {
  final int step;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool initiallyExpanded;
  final List<Widget> children;

  const _StageSection({
    super.key,
    required this.step,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        leading: Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: AppColors.softGreen,
            shape: BoxShape.circle,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: 23),
              Positioned(
                right: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: 17,
                    height: 17,
                    child: Center(
                      child: Text(
                        '$step',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        title: Text(
          '$step. $title',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        children: children,
      ),
    );
  }
}

class _ExtraSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _ExtraSection({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 9),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        children: children,
      ),
    );
  }
}

class _SafetyNotice extends StatelessWidget {
  const _SafetyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        border: Border.all(color: const Color(0xFFFFE0A3)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: AppColors.warning),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Спочатку визначте проблему. Засоби захисту застосовуйте лише '
              'коли вони дозволені для цієї культури: дотримуйтеся етикетки, '
              'дози, засобів індивідуального захисту та строку очікування до збору.',
              style: TextStyle(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _SourceLinkTile extends StatelessWidget {
  final String url;
  final ValueChanged<String> onOpen;

  const _SourceLinkTile({required this.url, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final tier = catalogSourceTier(url);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(
        tier == CatalogSourceTier.official
            ? Icons.account_balance_outlined
            : tier == CatalogSourceTier.scientific
                ? Icons.science_outlined
                : tier == CatalogSourceTier.reference
                    ? Icons.info_outline_rounded
                    : Icons.forum_outlined,
        color: tier == CatalogSourceTier.reference
            ? AppColors.textSecondary
            : AppColors.primary,
      ),
      title: Text(
        catalogSourceName(url),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${catalogSourceTierLabel(tier)}\n$url',
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.open_in_new_rounded, size: 20),
      onTap: () => onOpen(url),
    );
  }
}

class _FactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final CatalogFact fact;
  final String valueSuffix;

  const _FactCard({
    super.key,
    required this.icon,
    required this.title,
    required this.fact,
    this.valueSuffix = '',
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (fact.reliability) {
      CatalogReliability.high => AppColors.primary,
      CatalogReliability.medium => AppColors.info,
      CatalogReliability.low => AppColors.warning,
      CatalogReliability.unknown => AppColors.textSecondary,
    };
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 9),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          catalogReliabilityLabel(fact.reliability),
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text('${fact.text}$valueSuffix',
                      style: const TextStyle(height: 1.4)),
                  if (fact.note.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      fact.note,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 7),
                  Text(
                    '${fact.sourceUrls.length} джерел • ${fact.checkedOn}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
