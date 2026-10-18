import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:garden_mii/main.dart';
import 'package:garden_mii/src/app_state.dart';
import 'package:garden_mii/src/care_recommendations.dart';
import 'package:garden_mii/src/calendar/lunar_phase.dart';
import 'package:garden_mii/src/catalog/crop_catalog_repository.dart';
import 'package:garden_mii/src/catalog/crop_photo_catalog.dart';
import 'package:garden_mii/src/feedback/feedback_mailer.dart';
import 'package:garden_mii/src/models.dart';
import 'package:garden_mii/src/storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('creates a garden from the empty screen', (tester) async {
    final setup = await _createApp();

    await tester.pumpWidget(setup.app);
    await tester.pumpAndSettle();

    expect(find.text('Почнімо з першої ділянки'), findsOneWidget);
    expect(find.text('Як це працює'), findsOneWidget);
    expect(find.text('Створіть сітку'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Натисніть на клітинку'), 120);
    expect(find.text('Натисніть на клітинку'), findsOneWidget);

    await tester.tap(find.text('Нова ділянка'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Створити'));
    await tester.pumpAndSettle();

    expect(setup.state.gardens, hasLength(1));
    expect(setup.state.gardens.single.name, 'Ділянка 1');
    expect(find.text('Ділянка 1'), findsOneWidget);
  });

  testWidgets('opens the built-in usage guide', (tester) async {
    final setup = await _createApp();

    await tester.pumpWidget(setup.app);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Більше дій'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Як користуватися'));
    await tester.pumpAndSettle();

    expect(find.text('Як користуватися'), findsOneWidget);
    expect(find.text('Створіть ділянку'), findsOneWidget);
    expect(find.text('Додайте посадку'), findsOneWidget);
    expect(find.text('Не забудьте про догляд'), findsOneWidget);

    await tester.ensureVisible(find.text('Зрозуміло'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Зрозуміло'));
    await tester.pumpAndSettle();
    expect(find.text('Як користуватися'), findsNothing);
  });

  testWidgets('shows onboarding once and stores completion', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final storage = PrefsStorage(prefs);
    final state = await AppState.load(storage);
    final app = GardenApp(
      state: state,
      storage: storage,
      initialOnboardingCompleted: false,
    );

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    expect(find.text('Ваш город завжди з вами'), findsOneWidget);
    await tester.tap(find.text('Пропустити'));
    await tester.pumpAndSettle();

    expect(storage.onboardingCompleted, isTrue);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Городи'), findsOneWidget);
  });

  testWidgets('garden dashboard reflows cleanly at 150 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final setup = await _createApp();
    await setup.state.setTextScale(1.5);
    final garden = Garden.createFromArea(
      name: 'Ділянка 1',
      rows: 6,
      cols: 8,
      areaValue: 0.25,
      areaUnit: AreaUnit.hectares,
    );
    await setup.state.addGarden(garden);
    await setup.state.setPlanting(
      gardenId: garden.id,
      row: 0,
      col: 0,
      planting: Planting(
        id: 'dashboard-planting',
        gardenId: garden.id,
        cropId: setup.state.crops.first.id,
        plantedAt: DateTime(2026, 8, 16),
      ),
    );

    await tester.pumpWidget(setup.app);
    await tester.pumpAndSettle();

    expect(find.text('Мої городи'), findsOneWidget);
    expect(
      find.text('Найближчих запланованих робіт немає'),
      findsOneWidget,
    );
    expect(find.text('Мої ділянки'), findsOneWidget);
    expect(find.text('Город • 6×8'), findsOneWidget);
    expect(find.text('0,25 га'), findsOneWidget);
    expect(find.text('Посаджено 1 з 48'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Нова ділянка'),
      260,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('garden-dashboard-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(FilledButton, 'Нова ділянка'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('requires rules but keeps research and photo consent optional', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final storage = PrefsStorage(prefs);
    final state = await AppState.load(storage);
    final app = GardenApp(
      state: state,
      storage: storage,
      initialTermsAccepted: false,
    );

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    expect(find.text('Перед початком'), findsOneWidget);
    expect(storage.termsAccepted, isFalse);

    await tester.tap(find.byKey(const Key('accept-required-terms')));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const Key('continue-after-consent')),
      240,
    );
    await tester.tap(find.byKey(const Key('continue-after-consent')));
    await tester.pumpAndSettle();

    expect(storage.termsAccepted, isTrue);
    expect(storage.researchConsent, isFalse);
    expect(storage.catalogPhotoLicense, isFalse);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('stores the registration name and shows it in the profile', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'guided_tour_completed_v1': true,
    });
    final prefs = await SharedPreferences.getInstance();
    final storage = PrefsStorage(prefs);
    final state = await AppState.load(storage);
    final app = GardenApp(
      state: state,
      storage: storage,
      initialProfileConfigured: false,
    );

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    expect(find.text('Як до вас звертатися у застосунку?'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('profile-name-field')),
      'Олена Городниця',
    );
    await tester.tap(find.byKey(const Key('create-local-profile')));
    await tester.pumpAndSettle();

    expect(storage.profileName, 'Олена Городниця');
    final navigation = tester.widget<NavigationBar>(find.byType(NavigationBar));
    navigation.onDestinationSelected!(3);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile-display-name')), findsOneWidget);
    expect(find.text('Олена Городниця'), findsOneWidget);

    final editButton = tester.widget<IconButton>(
      find.byKey(const Key('edit-profile-name')),
    );
    editButton.onPressed!();
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('edit-profile-name-field')),
      'Наталя',
    );
    await tester.tap(find.byKey(const Key('save-profile-name')));
    await tester.pumpAndSettle();

    expect(state.profileName, 'Наталя');
    expect(storage.profileName, 'Наталя');
    expect(find.text('Наталя'), findsOneWidget);
  });

  testWidgets('switches between the four persistent navigation tabs', (
    tester,
  ) async {
    final setup = await _createApp();
    await tester.pumpWidget(setup.app);
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.tap(find.text('Календар'));
    await tester.pumpAndSettle();
    expect(find.text('Найближчі події'), findsOneWidget);
    expect(find.byKey(const Key('lunar-phase-card')), findsOneWidget);
    expect(
      find.textContaining('Довідково, не рекомендація для посіву.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Поради').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('open-supplies')), findsOneWidget);

    await tester.tap(find.text('Профіль').last);
    await tester.pumpAndSettle();
    expect(find.text('Локальний профіль • без авторизації'), findsOneWidget);

    await tester.tap(find.text('Городи'));
    await tester.pumpAndSettle();
    expect(find.text('Почнімо з першої ділянки'), findsOneWidget);
  });

  test('calculates approximate lunar phases for known dates', () {
    expect(
      LunarPhase.forDate(DateTime(2000, 1, 6)).type,
      LunarPhaseType.newMoon,
    );
    expect(
      LunarPhase.forDate(DateTime(2000, 1, 21)).type,
      LunarPhaseType.fullMoon,
    );
    expect(
      LunarPhase.forDate(DateTime(2000, 1, 21)).illuminationPercent,
      greaterThan(95),
    );
  });

  test('loads and validates the first UA/PL crop catalog batch', () async {
    final catalog = await CropCatalogRepository.load();

    expect(catalog.records, hasLength(50));
    expect(catalog.declaredRecordCount, 50);
    expect(
        catalog.records.map((entry) => entry.catalogId).toSet(), hasLength(50));
    expect(catalog.records.map((entry) => entry.slug).toSet(), hasLength(50));
    expect(catalog.qaStatus, 'pass_structural_validation');

    final tomato =
        catalog.records.firstWhere((entry) => entry.slug == 'tomato');
    expect(tomato.nameUk.text, 'помідор');
    expect(tomato.namePl.text, 'pomidor');
    expect(tomato.watering.sourceUrls.length, greaterThanOrEqualTo(5));
    expect(tomato.officialScientificSourceCount, greaterThanOrEqualTo(2));
    expect(tomato.primaryWikiUrl, startsWith('https://'));
    expect(tomato.typicalDiseases.stringList, contains('фітофтороз'));
  });

  test('merges catalog crops without breaking legacy crop ids', () async {
    final catalog = await CropCatalogRepository.load();
    final data = AppData.initial().withBuiltInCrops(catalog.toCrops());

    expect(data.crops, hasLength(50));
    expect(data.crops.map((crop) => crop.id).toSet(), hasLength(50));
    final tomato = data.crops.firstWhere((crop) => crop.id == 'crop_tomato');
    expect(tomato.name, 'Томат');
    expect(tomato.catalogId, 'UA-PL-001');
    expect(tomato.namePl, 'pomidor');
    expect(tomato.familyLatin, 'Solanaceae');
    final tomatoEntry =
        catalog.records.firstWhere((entry) => entry.slug == 'tomato');
    expect(careProfileFor(tomato).watering, tomatoEntry.watering.text);

    final restored = Crop.fromJson(tomato.toJson());
    expect(restored.catalogId, tomato.catalogId);
    expect(restored.wikiUrl, tomato.wikiUrl);
    expect(restored.minimumRotationYears, 3);
  });

  test('calculates maturity reminders from planting date and variety group',
      () async {
    final catalog = await CropCatalogRepository.load();
    final crops = catalog.toCrops();
    final tomato = crops.firstWhere((crop) => crop.slug == 'tomato');
    final carrot = crops.firstWhere((crop) => crop.slug == 'carrot');

    final earlyTomato = maturityEstimateFor(
      tomato,
      maturityGroups: const [SeedMaturityGroup.early],
    );
    final lateTomato = maturityEstimateFor(
      tomato,
      maturityGroups: const [SeedMaturityGroup.late],
    );
    final directSownCarrot = maturityEstimateFor(carrot);

    expect(earlyTomato?.earliestDays, 50);
    expect(earlyTomato?.latestDays, 100);
    expect(earlyTomato?.selectedDays, 50);
    expect(earlyTomato?.dateBasisLabel, 'від висаджування');
    expect(lateTomato?.selectedDays, 100);
    expect(directSownCarrot?.earliestDays, 70);
    expect(directSownCarrot?.latestDays, 130);
    expect(directSownCarrot?.dateBasisLabel, 'від посіву');
  });

  test('serializes harvest diary entries with crop and grid placement', () {
    final garden = Garden.create(
      name: 'Щоденник',
      rows: 2,
      cols: 3,
      widthMeters: 3,
      heightMeters: 2,
    );
    final crop = builtInCrops().first;
    final entry = GardenDiaryEntry(
      id: 'harvest-photo-1',
      gardenId: garden.id,
      capturedAt: DateTime(2026, 7, 17),
      type: DiaryEntryType.harvest,
      note: 'Перший кошик',
      cropId: crop.id,
      row: 1,
      col: 2,
      photoPath: '/local/harvest.jpg',
      shareForResearch: true,
      shareForCatalog: true,
    );
    final restored = decodeAppData(
      encodeAppData(
        AppData(
          gardens: [garden],
          crops: [crop],
          reminders: const [],
          diaryEntries: [entry],
        ),
      ),
    );

    expect(restored.diaryEntries, hasLength(1));
    expect(restored.diaryEntries.single.type, DiaryEntryType.harvest);
    expect(restored.diaryEntries.single.cropId, crop.id);
    expect(restored.diaryEntries.single.row, 1);
    expect(restored.diaryEntries.single.col, 2);
    expect(restored.diaryEntries.single.shareForCatalog, isTrue);
  });

  testWidgets('adds a harvest note to the garden diary', (tester) async {
    final setup = await _createApp();
    final garden = Garden.create(
      name: 'Щоденник тест',
      rows: 2,
      cols: 2,
      widthMeters: 2,
      heightMeters: 2,
    );
    await setup.state.addGarden(garden);

    await tester.pumpWidget(setup.app);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Щоденник тест'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-garden-diary')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-diary-entry')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('diary-entry-type')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Врожай').last);
    await tester.enterText(
      find.byKey(const Key('diary-entry-note')),
      'Зібрано перший врожай',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('save-diary-entry')),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('save-diary-entry')));
    await tester.pumpAndSettle();

    expect(setup.state.diaryEntries, hasLength(1));
    expect(setup.state.diaryEntries.single.type, DiaryEntryType.harvest);
    expect(setup.state.diaryEntries.single.note, 'Зібрано перший врожай');
    expect(find.text('Зібрано перший врожай'), findsOneWidget);
  });

  testWidgets('stores the preferred text size from profile', (tester) async {
    final setup = await _createApp();
    await tester.pumpWidget(setup.app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Профіль').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Закрити на цей сеанс'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('125%'),
      120,
    );
    final scaleControl = tester.widget<SegmentedButton<double>>(
      find.byType(SegmentedButton<double>),
    );
    scaleControl.onSelectionChanged!({1.25});
    await tester.pumpAndSettle();

    expect(setup.state.textScale, 1.25);
  });

  test('every catalog crop has two attributed internet photos', () async {
    final crops = await CropCatalogRepository.load();
    final photos = await CropPhotoRepository.load();

    expect(photos.source, 'Wikimedia Commons');
    expect(photos.records, hasLength(crops.records.length));
    expect(photos.records.keys.toSet(),
        crops.records.map((item) => item.slug).toSet());

    for (final pair in photos.records.values) {
      for (final photo in [pair.growing, pair.harvested]) {
        expect(photo.sourceUrl, startsWith('https://commons.wikimedia.org/'));
        expect(photo.author, isNotEmpty);
        expect(photo.license, isNotEmpty);
        final asset = await rootBundle.load(photo.assetPath);
        expect(asset.lengthInBytes, greaterThan(1000));
      }
    }
  });

  testWidgets('searches the UA/PL crop catalog and opens crop guidance', (
    tester,
  ) async {
    final setup = await _createApp();
    await tester.pumpWidget(setup.app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Поради').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-crop-catalog')));
    await tester.pumpAndSettle();

    expect(find.text('Каталог культур'), findsOneWidget);
    expect(find.text('Знайдено: 50'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('crop-catalog-search')),
      'pomidor',
    );
    await tester.pumpAndSettle();

    expect(find.text('Знайдено: 1'), findsOneWidget);
    expect(find.text('помідор'), findsOneWidget);
    await tester.tap(find.text('помідор'));
    await tester.pumpAndSettle();

    expect(find.text('Solanum lycopersicum'), findsOneWidget);
    await tester.drag(
      find.byKey(const Key('crop-detail-scroll')),
      const Offset(0, -220),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('crop-photo-unavailable')), findsNothing);
    expect(find.text('Як виглядає культура'), findsOneWidget);
    expect(find.byKey(const Key('crop-photo-growing')), findsOneWidget);
    expect(find.byKey(const Key('crop-photo-harvested')), findsOneWidget);
    expect(find.text('У ґрунті'), findsOneWidget);
    expect(find.text('Урожай / їстівна частина'), findsOneWidget);
    await tester.drag(
      find.byKey(const Key('crop-detail-scroll')),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    expect(find.text('Польською'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Покроковий план вирощування'),
      220,
    );
    await tester.pumpAndSettle();
    expect(find.text('Покроковий план вирощування'), findsOneWidget);
    expect(find.text('1. Підготуйте ґрунт і грядку'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('concrete-rotation-guide')),
      320,
    );
    await tester.pumpAndSettle();
    expect(find.text('Добрі попередники (до посадки)'), findsOneWidget);
    expect(find.text('Після яких культур не садити'), findsOneWidget);
    expect(find.textContaining('Картопля'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('2. Посійте або висадіть'), 240);
    await tester.pumpAndSettle();
    await tester.tap(find.text('2. Посійте або висадіть'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Строки об’єднані'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('5. Заплануйте наступну посадку'),
      320,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('5. Заплануйте наступну посадку'));
    await tester.pumpAndSettle();
    expect(find.text('Що посадити після цієї культури'), findsOneWidget);
    expect(find.byKey(const Key('recommended-after-harvest')), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Додатково'), 320);
    await tester.pumpAndSettle();
    expect(find.text('Добрива'), findsOneWidget);
    expect(find.text('Захист і безпека'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Перевірені джерела'), 350);
    await tester.pumpAndSettle();
    expect(find.text('Перевірені джерела'), findsOneWidget);
    expect(find.byKey(const Key('trusted-crop-sources')), findsOneWidget);
    await tester.drag(
      find.byKey(const Key('crop-detail-scroll')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('reference-only-crop-sources')),
      findsOneWidget,
    );
    expect(find.text('Wikipedia'), findsNothing);
  });

  testWidgets('adds a scanned-product record to local seed inventory', (
    tester,
  ) async {
    final setup = await _createApp();
    await tester.pumpWidget(setup.app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Поради').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-supplies')));
    await tester.pumpAndSettle();

    expect(find.text('Мої запаси'), findsOneWidget);
    expect(find.text('Що зараз посаджено'), findsOneWidget);
    await tester.tap(find.byTooltip('Додати вручну'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('inventory-product-name')),
      'Томати Чері — пакет',
    );
    await tester.tap(find.byKey(const Key('inventory-crop')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Томат').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('save-inventory-item')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-inventory-item')));
    await tester.pumpAndSettle();

    expect(setup.state.inventory, hasLength(1));
    expect(setup.state.inventory.single.type, InventoryItemType.seeds);
    expect(setup.state.inventory.single.cropId, 'crop_tomato');
    expect(find.text('Томати Чері — пакет'), findsOneWidget);
    expect(find.text('Є в запасі'), findsOneWidget);
  });

  testWidgets('labels partner fertilizer ads and adds one to inventory', (
    tester,
  ) async {
    final setup = await _createApp();
    await tester.pumpWidget(setup.app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Поради').last);
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const PageStorageKey('recommendations-list')),
      const Offset(0, -260),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-partner-fertilizers')));
    await tester.pumpAndSettle();

    expect(find.text('Добрива та партнери'), findsOneWidget);
    expect(find.text('Реклама • Партнерський матеріал'), findsWidgets);
    await tester.tap(find.text('У мої запаси').first);
    await tester.pumpAndSettle();

    expect(setup.state.inventory, hasLength(1));
    expect(setup.state.inventory.single.type, InventoryItemType.fertilizer);
  });

  testWidgets('opens plant protection supplies from recommendations', (
    tester,
  ) async {
    final setup = await _createApp();
    await tester.pumpWidget(setup.app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Поради').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('open-plant-protection')));
    await tester.tap(find.byKey(const Key('open-plant-protection')));
    await tester.pumpAndSettle();

    expect(find.text('Мої запаси'), findsOneWidget);
    final protectionChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Захист рослин'),
    );
    expect(protectionChip.selected, isTrue);
  });

  testWidgets('opens the email feedback form from profile', (tester) async {
    final setup = await _createApp();
    await tester.pumpWidget(setup.app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Профіль').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('open-feedback-appbar')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('open-general-feedback')),
      180,
    );
    await tester.tap(find.byKey(const Key('open-general-feedback')));
    await tester.pumpAndSettle();

    expect(find.text('Надіслати відгук'), findsOneWidget);
    expect(find.byKey(const Key('feedback-message')), findsOneWidget);
    expect(find.byKey(const Key('send-feedback-email')), findsOneWidget);
  });

  testWidgets('demo premium removes the mini partner banner', (tester) async {
    final setup = await _createApp();
    await tester.pumpWidget(setup.app);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mini-partner-banner')), findsOneWidget);
    await tester.tap(find.byTooltip('Прибрати рекламу'));
    await tester.pumpAndSettle();
    expect(find.text('Версія без мінібанера'), findsOneWidget);
    await tester.tap(find.text('Спробувати без банера'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mini-partner-banner')), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(PrefsStorage(prefs).adsRemoved, isTrue);
  });

  testWidgets('rejects invalid grid dimensions on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final setup = await _createApp();
    await tester.pumpWidget(setup.app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Нова ділянка'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), '0');
    await tester.tap(find.widgetWithText(FilledButton, 'Створити'));
    await tester.pump();

    expect(find.text('Від 1 до 50'), findsOneWidget);
    expect(setup.state.gardens, isEmpty);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Скасувати'));
    await tester.pumpAndSettle();
  });

  testWidgets('requires confirmation before deleting a garden', (
    tester,
  ) async {
    final setup = await _createApp();
    await setup.state.addGarden(
      Garden.create(
        name: 'Ділянка для видалення',
        rows: 1,
        cols: 1,
        widthMeters: 2,
        heightMeters: 2,
      ),
    );
    await tester.pumpWidget(setup.app);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Меню ділянки'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Видалити'));
    await tester.pumpAndSettle();

    expect(find.text('Видалити ділянку?'), findsOneWidget);
    expect(setup.state.gardens, hasLength(1));

    await tester.tap(find.text('Скасувати'));
    await tester.pumpAndSettle();
    expect(setup.state.gardens, hasLength(1));

    await tester.tap(find.byTooltip('Меню ділянки'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Видалити'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Видалити'));
    await tester.pumpAndSettle();

    expect(setup.state.gardens, isEmpty);
    expect(find.text('Почнімо з першої ділянки'), findsOneWidget);
  });

  testWidgets('edits garden details from the garden card menu', (
    tester,
  ) async {
    final setup = await _createApp();
    await setup.state.addGarden(
      Garden.create(
        name: 'Стара назва',
        rows: 2,
        cols: 2,
        widthMeters: 4,
        heightMeters: 6,
      ),
    );
    await tester.pumpWidget(setup.app);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Меню ділянки'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Редагувати'));
    await tester.pumpAndSettle();
    expect(find.text('Редагувати ділянку'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Поле біля дому');
    await tester.tap(find.widgetWithText(FilledButton, 'Зберегти'));
    await tester.pumpAndSettle();

    expect(setup.state.gardens.single.name, 'Поле біля дому');
    expect(find.text('Поле біля дому'), findsOneWidget);
  });

  testWidgets('creates and renames a grid segment', (tester) async {
    final setup = await _createApp();
    await setup.state.addGarden(
      Garden.create(
        name: 'Сегментована ділянка',
        rows: 2,
        cols: 2,
        widthMeters: 4,
        heightMeters: 4,
      ),
    );
    await tester.pumpWidget(setup.app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Сегментована ділянка'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-garden-zones')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-garden-zone')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Грядка А');
    await tester.tap(find.widgetWithText(FilledButton, 'Зберегти'));
    await tester.pumpAndSettle();

    expect(setup.state.gardens.single.zones, hasLength(1));
    expect(setup.state.gardens.single.zones.single.name, 'Грядка А');

    await tester.tap(find.widgetWithText(ListTile, 'Грядка А'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Томати');
    await tester.tap(find.widgetWithText(FilledButton, 'Зберегти'));
    await tester.pumpAndSettle();

    expect(setup.state.gardens.single.zones.single.name, 'Томати');
  });

  testWidgets('garden grid fills the screen and its hint disappears', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final setup = await _createApp();
    final garden = Garden.create(
      name: 'Повноекранна сітка',
      rows: 3,
      cols: 3,
      widthMeters: 3,
      heightMeters: 3,
    );
    await setup.state.addGarden(garden);
    final tomato = setup.state.crops.firstWhere(
      (crop) => crop.id == 'crop_tomato',
    );
    await setup.state.setPlanting(
      gardenId: garden.id,
      row: 1,
      col: 1,
      planting: Planting(
        id: 'full-screen-tomato',
        gardenId: garden.id,
        cropId: tomato.id,
        plantedAt: DateTime(2026, 8, 10),
      ),
    );

    await tester.pumpWidget(setup.app);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Повноекранна сітка'));
    await tester.pumpAndSettle();

    final canvasSize = tester.getSize(
      find.byKey(const ValueKey('garden-grid-canvas')),
    );
    expect(canvasSize.height, greaterThan(650));
    expect(find.text('🍅'), findsOneWidget);
    expect(find.byKey(const ValueKey('garden-grid-hint')), findsOneWidget);

    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('garden-grid-hint')), findsNothing);
  });

  testWidgets('creates, edits, and deletes a structured planting', (
    tester,
  ) async {
    final setup = await _createApp();
    await setup.state.addGarden(
      Garden.create(
        name: 'Посадки',
        rows: 1,
        cols: 1,
        widthMeters: 2,
        heightMeters: 2,
      ),
    );
    final tomato = setup.state.crops.firstWhere(
      (crop) => crop.id == 'crop_tomato',
    );
    await setup.state.saveInventoryItem(
      InventoryItem(
        id: 'widget-seed-package',
        type: InventoryItemType.seeds,
        productName: 'Томат Чері — тестовий пакет',
        cropId: tomato.id,
        varietyName: 'Чері червоний',
        createdAt: DateTime(2026, 7, 16),
      ),
    );
    await tester.pumpWidget(setup.app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Посадки'));
    await tester.pumpAndSettle();
    expect(find.text('Додайте першу посадку'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('garden-cell-0-0')));
    await tester.pumpAndSettle();

    expect(find.text('Нова посадка'), findsOneWidget);
    await tester.tap(find.byKey(const Key('planting-crop')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Томат').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('planting-inventory-item')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Томат Чері — тестовий пакет').last);
    await tester.pumpAndSettle();
    final varietyField = tester.widget<TextFormField>(
      find.byType(TextFormField).at(0),
    );
    expect(varietyField.controller?.text, 'Чері червоний');
    await tester.enterText(
        find.byType(TextFormField).at(1), 'Розсада з теплиці');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Зберегти'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Зберегти'));
    await tester.pumpAndSettle();

    expect(setup.state.plantings, hasLength(1));
    expect(setup.state.plantings.single.variety, 'Чері червоний');
    expect(setup.state.plantings.single.note, 'Розсада з теплиці');
    expect(
      setup.state.plantings.single.inventoryItemId,
      'widget-seed-package',
    );
    expect(setup.state.plantings.single.plantedAt, isNull);
    expect(setup.state.plantings.single.status, PlantingStatus.planned);
    expect(
      setup.state.gardens.single.cellAt(0, 0).plantingId,
      setup.state.plantings.single.id,
    );
    expect(find.text('Додайте першу посадку'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('garden-cell-0-0')));
    await tester.pumpAndSettle();
    expect(find.text('Редагувати посадку'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Чері жовтий');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Зберегти'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Зберегти'));
    await tester.pumpAndSettle();

    expect(setup.state.plantings, hasLength(1));
    expect(setup.state.plantings.single.variety, 'Чері жовтий');

    await tester.tap(find.byKey(const ValueKey('garden-cell-0-0')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Видалити посадку'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Видалити посадку'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Видалити'));
    await tester.pumpAndSettle();

    expect(setup.state.plantings, isEmpty);
    expect(setup.state.gardens.single.cellAt(0, 0).plantingId, isNull);
  });

  testWidgets('long-press drag extends a planting on the grid', (
    tester,
  ) async {
    final setup = await _createApp();
    final garden = Garden.create(
      name: 'Протягування на сітці',
      rows: 1,
      cols: 3,
      widthMeters: 3,
      heightMeters: 1,
    );
    await setup.state.addGarden(garden);
    await setup.state.setPlanting(
      gardenId: garden.id,
      row: 0,
      col: 0,
      planting: Planting(
        id: 'widget-drag-source',
        gardenId: garden.id,
        cropId: setup.state.crops.first.id,
        plantedAt: DateTime(2026, 7, 16),
      ),
    );
    await tester.pumpWidget(setup.app);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Протягування на сітці'));
    await tester.pumpAndSettle();

    final source = find.byKey(const ValueKey('garden-cell-0-0'));
    final target = find.byKey(const ValueKey('garden-cell-0-2'));
    final gesture = await tester.startGesture(tester.getCenter(source));
    await tester.pump(const Duration(milliseconds: 700));
    await gesture.moveTo(tester.getCenter(target));
    await tester.pump(const Duration(milliseconds: 150));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(setup.state.gardens.single.cellAt(0, 1).plantingId, isNotNull);
    expect(setup.state.gardens.single.cellAt(0, 2).plantingId, isNotNull);
    expect(find.text('Культуру додано ще на 2 кліт.'), findsOneWidget);
  });

  test('validates garden geometry before allocating cells', () {
    Garden createGarden({
      int rows = 2,
      int cols = 3,
      double width = 8,
      double height = 10,
    }) {
      return Garden.create(
        name: 'Тестова ділянка',
        rows: rows,
        cols: cols,
        widthMeters: width,
        heightMeters: height,
      );
    }

    expect(() => createGarden(rows: 0), throwsRangeError);
    expect(() => createGarden(rows: 51), throwsRangeError);
    expect(() => createGarden(width: 0), throwsArgumentError);
    expect(() => createGarden(height: 10001), throwsArgumentError);
    expect(createGarden().cells, hasLength(6));
  });

  test('converts and preserves hectares, sotkas, and square meters', () {
    expect(areaToSquareMeters(0.25, AreaUnit.hectares), 2500);
    expect(areaFromSquareMeters(2500, AreaUnit.sotkas), 25);
    expect(formatArea(2500, AreaUnit.hectares), '0,25 га');

    final garden = Garden.createFromArea(
      name: 'Поле',
      rows: 10,
      cols: 10,
      areaValue: 0.25,
      areaUnit: AreaUnit.hectares,
    );
    final restored = Garden.fromJson(garden.toJson());

    expect(garden.areaSquareMeters, closeTo(2500, 0.001));
    expect(restored.sizeMode, GardenSizeMode.area);
    expect(restored.areaUnit, AreaUnit.hectares);
    expect(restored.areaSquareMeters, closeTo(2500, 0.001));
  });

  test('legacy garden dimensions retain square meter display defaults', () {
    final garden = Garden.fromJson({
      'id': 'legacy-garden',
      'name': 'Стара ділянка',
      'rows': 1,
      'cols': 1,
      'widthMeters': 10,
      'heightMeters': 20,
      'cells': [
        {'row': 0, 'col': 0, 'plantingId': null},
      ],
    });

    expect(garden.sizeMode, GardenSizeMode.dimensions);
    expect(garden.areaUnit, AreaUnit.squareMeters);
    expect(garden.areaSquareMeters, 200);
  });

  test('creates physical zones from grid ranges and serializes them', () {
    final garden = Garden.create(
      name: 'Зони',
      rows: 4,
      cols: 4,
      widthMeters: 8,
      heightMeters: 8,
    );
    final zone = garden.zoneFromGridRange(
      id: 'zone-1',
      name: 'Північна грядка',
      type: GardenZoneType.bed,
      startRow: 0,
      endRow: 1,
      startCol: 0,
      endCol: 1,
      colorValue: 0xFFB7D8A8,
      canPlant: true,
    );
    final zonedGarden = garden.copyWith(zones: [zone]);
    final restored = Garden.fromJson(zonedGarden.toJson());

    expect(zone.widthMeters, 4);
    expect(zone.heightMeters, 4);
    expect(zonedGarden.zoneAtCell(0, 0)?.id, 'zone-1');
    expect(zonedGarden.zoneAtCell(3, 3), isNull);
    expect(restored.zones.single.name, 'Північна грядка');
  });

  test('reconfiguring a garden scales zones without changing their names', () {
    final garden = Garden.create(
      name: 'Масштаб',
      rows: 2,
      cols: 2,
      widthMeters: 4,
      heightMeters: 4,
    );
    final zone = garden.zoneFromGridRange(
      id: 'zone-scale',
      name: 'Теплиця',
      type: GardenZoneType.greenhouse,
      startRow: 0,
      endRow: 0,
      startCol: 0,
      endCol: 1,
      colorValue: 0xFFBFE0EE,
      canPlant: true,
    );
    final resized = garden.copyWith(zones: [zone]).reconfigure(
      name: 'Масштаб',
      rows: 4,
      cols: 4,
      widthMeters: 8,
      heightMeters: 12,
      sizeMode: GardenSizeMode.dimensions,
      areaUnit: AreaUnit.squareMeters,
      type: GardenType.greenhouse,
      soilType: SoilType.loam,
      region: 'Київщина',
      note: 'Оновлено',
    );

    expect(resized.zones.single.name, 'Теплиця');
    expect(resized.zones.single.widthMeters, 8);
    expect(resized.zones.single.heightMeters, 6);
    expect(resized.type, GardenType.greenhouse);
    expect(resized.region, 'Київщина');
  });

  test('rotation suggestions exclude the harvested crop family', () {
    final catalog = builtInCrops();
    final tomato = catalog.firstWhere((crop) => crop.name == 'Томат');
    final suggestions = rotationSuggestionsFor(tomato, catalog);

    expect(suggestions, hasLength(3));
    expect(
      suggestions.every((crop) => crop.family != CropFamily.nightshade),
      isTrue,
    );
    expect(suggestions.first.family, CropFamily.legume);
  });

  test('rotation suggestions rank the next seasonal window', () {
    final catalog = builtInCrops();
    final tomato = catalog.firstWhere((crop) => crop.name == 'Томат');
    final suggestions = rotationSuggestionsFor(
      tomato,
      catalog,
      afterHarvest: DateTime(2026, 9, 15),
    );

    expect(suggestions.first.name, 'Горох');
    expect(suggestions.every((crop) => crop.season == Season.spring), isTrue);
  });

  test('shows concrete crops before, avoided, and after garlic', () async {
    final catalog = await CropCatalogRepository.load();
    final crops = catalog.toCrops();
    final garlic = crops.firstWhere((crop) => crop.slug == 'garlic');

    final before = predecessorSuggestionsFor(garlic, crops);
    final avoided = sameFamilyCropsFor(garlic, crops);
    final after = rotationSuggestionsFor(garlic, crops, limit: 6);

    expect(before.map((crop) => crop.name), contains('Горох'));
    expect(before.every((crop) => crop.family != CropFamily.allium), isTrue);
    expect(
        avoided.map((crop) => crop.name),
        containsAll([
          'Часник',
          'Цибуля',
          'Цибуля-порей',
          'Цибуля-шніт',
        ]));
    expect(after.every((crop) => crop.family != CropFamily.allium), isTrue);
  });

  test('builds a stage-based late blight plan that accounts for variety',
      () async {
    final catalog = await CropCatalogRepository.load();
    final tomato =
        catalog.toCrops().firstWhere((crop) => crop.slug == 'tomato');

    final plan = plantProtectionPlanFor(
      tomato,
      resistanceClaims: const ['фітофтороз — середня стійкість'],
      maturityGroups: const [SeedMaturityGroup.late],
    );

    expect(plan.risks, contains('фітофтороз'));
    expect(plan.checkIntervalDays, 3);
    expect(plan.varietyNote, contains('середня стійкість'));
    expect(plan.varietyNote, contains('Пізній сорт'));
    final sowingStep = plan.steps.firstWhere(
      (step) => step.stage == ProtectionStage.sowingOrPlanting,
    );
    expect(sowingStep.title, contains('обробка при посіві'));
    expect(sowingStep.action, contains('не замінює'));
    expect(
      plan.steps.map((step) => step.stage),
      contains(ProtectionStage.elevatedRisk),
    );
  });

  test('serializes and restores gardens, cells, crops, and reminders', () {
    const crop = Crop(id: 'crop-1', name: 'Томат', variety: 'Чері');
    final inventoryItem = InventoryItem(
      id: 'seed-package-1',
      type: InventoryItemType.seeds,
      barcode: '5901234123457',
      productName: 'Томат Чері',
      brand: 'Тестове насіння',
      cropId: crop.id,
      varietyName: 'Чері червоний F1',
      varietyType: SeedVarietyType.hybrid,
      maturityGroup: SeedMaturityGroup.early,
      resistanceClaims: 'фітофтороз — середня стійкість',
      quantity: 2,
      instructions: 'Посіяти на розсаду.',
      createdAt: DateTime(2026, 7, 13),
    );
    final garden = Garden.create(
      name: 'Біля дому',
      rows: 2,
      cols: 2,
      widthMeters: 4,
      heightMeters: 6,
    );
    final planting = Planting(
      id: 'planting-1',
      gardenId: garden.id,
      cropId: crop.id,
      inventoryItemId: inventoryItem.id,
      variety: 'Чері червоний',
      plantedAt: DateTime(2026, 7, 14),
      note: 'Посаджено після дощу',
    );
    final plantedCell = garden.cellAt(0, 1).copyWith(
          plantingId: planting.id,
        );
    final plantedGarden = garden.setCell(plantedCell);
    final reminder = Reminder(
      id: 'reminder-1',
      title: 'Полив',
      date: DateTime(2026, 7, 15, 8),
      gardenId: garden.id,
      cropId: crop.id,
    );
    final data = AppData(
      gardens: [plantedGarden],
      crops: [crop],
      plantings: [planting],
      inventory: [inventoryItem],
      reminders: [reminder],
    );

    final restored = decodeAppData(encodeAppData(data));

    expect(restored.gardens.single.name, 'Біля дому');
    expect(restored.gardens.single.cellAt(0, 1).plantingId, planting.id);
    expect(restored.plantings.single.cropId, crop.id);
    expect(restored.plantings.single.inventoryItemId, inventoryItem.id);
    expect(restored.plantings.single.variety, 'Чері червоний');
    expect(restored.plantings.single.note, 'Посаджено після дощу');
    expect(restored.plantings.single.plantedAt, DateTime(2026, 7, 14));
    expect(restored.crops.single.variety, 'Чері');
    expect(restored.inventory.single.barcode, '5901234123457');
    expect(restored.inventory.single.instructions, 'Посіяти на розсаду.');
    expect(restored.inventory.single.varietyName, 'Чері червоний F1');
    expect(restored.inventory.single.varietyType, SeedVarietyType.hybrid);
    expect(restored.inventory.single.maturityGroup, SeedMaturityGroup.early);
    expect(restored.inventory.single.resistanceClaims, contains('фітофтороз'));
    expect(restored.reminders.single.date, DateTime(2026, 7, 15, 8));
  });

  test('PlotCell copyWith preserves fields that were not supplied', () {
    const cell = PlotCell(row: 0, col: 0, plantingId: 'planting-1');

    expect(cell.copyWith().plantingId, 'planting-1');
    expect(cell.copyWith(plantingId: null).plantingId, isNull);
  });

  test('migrates legacy crop and note fields into a planting', () {
    final legacyJson = jsonEncode({
      'gardens': [
        {
          'id': 'garden-1',
          'name': 'Стара ділянка',
          'rows': 1,
          'cols': 1,
          'widthMeters': 2,
          'heightMeters': 3,
          'cells': [
            {
              'row': 0,
              'col': 0,
              'cropId': 'crop-1',
              'note': 'Стара нотатка',
            },
          ],
        },
      ],
      'crops': [
        {
          'id': 'crop-1',
          'name': 'Томат',
          'variety': 'Старий сорт',
          'season': 'summer',
          'recommendation': '',
        },
      ],
      'reminders': [],
    });

    final migrated = decodeAppData(legacyJson);

    expect(migrated.plantings, hasLength(1));
    expect(migrated.plantings.single.gardenId, 'garden-1');
    expect(migrated.plantings.single.cropId, 'crop-1');
    expect(migrated.plantings.single.variety, 'Старий сорт');
    expect(migrated.plantings.single.note, 'Стара нотатка');
    expect(migrated.plantings.single.plantedAt, isNull);
    expect(migrated.inventory, isEmpty);
    expect(
      migrated.gardens.single.cellAt(0, 0).plantingId,
      migrated.plantings.single.id,
    );
    expect(
      jsonDecode(encodeAppData(migrated))['schemaVersion'],
      AppData.currentSchemaVersion,
    );
  });

  test('sets, edits, removes, and persists a planting atomically', () async {
    final prefs = await SharedPreferences.getInstance();
    final storage = PrefsStorage(prefs);
    final state = await AppState.load(storage);
    final garden = Garden.create(
      name: 'Посадки',
      rows: 1,
      cols: 1,
      widthMeters: 2,
      heightMeters: 2,
    );
    await state.addGarden(garden);
    final crop = state.crops.first;
    final planting = Planting(
      id: 'planting-1',
      gardenId: garden.id,
      cropId: crop.id,
      variety: 'Перший сорт',
      plantedAt: DateTime(2026, 7, 14),
    );

    await state.setPlanting(
      gardenId: garden.id,
      row: 0,
      col: 0,
      planting: planting,
    );
    await state.setPlanting(
      gardenId: garden.id,
      row: 0,
      col: 0,
      planting: planting.copyWith(
        variety: 'Оновлений сорт',
        note: 'Оновлена нотатка',
      ),
    );
    var restored = await storage.load();

    expect(state.plantings, hasLength(1));
    expect(state.plantings.single.variety, 'Оновлений сорт');
    expect(restored.data.plantings.single.note, 'Оновлена нотатка');
    expect(restored.data.gardens.single.cellAt(0, 0).plantingId, planting.id);

    await state.removePlanting(gardenId: garden.id, row: 0, col: 0);
    restored = await storage.load();

    expect(state.plantings, isEmpty);
    expect(state.gardens.single.cellAt(0, 0).plantingId, isNull);
    expect(restored.data.plantings, isEmpty);
  });

  test('extends one planting across free cells without overwriting', () async {
    final prefs = await SharedPreferences.getInstance();
    final storage = PrefsStorage(prefs);
    final state = await AppState.load(storage);
    final crop = state.crops.first;
    final otherCrop = state.crops[1];
    final garden = Garden.create(
      name: 'Протягування',
      rows: 2,
      cols: 3,
      widthMeters: 3,
      heightMeters: 2,
    ).copyWith(
      zones: [
        GardenZone(
          id: 'path-zone',
          name: 'Доріжка',
          type: GardenZoneType.path,
          xMeters: 1,
          yMeters: 1,
          widthMeters: 1,
          heightMeters: 1,
          canPlant: false,
        ),
      ],
    );
    await state.addGarden(garden);
    await state.setPlanting(
      gardenId: garden.id,
      row: 0,
      col: 0,
      planting: Planting(
        id: 'drag-source',
        gardenId: garden.id,
        cropId: crop.id,
        variety: 'Сорт для копіювання',
        plantedAt: DateTime(2026, 7, 16),
      ),
    );
    await state.setPlanting(
      gardenId: garden.id,
      row: 0,
      col: 1,
      planting: Planting(
        id: 'existing-planting',
        gardenId: garden.id,
        cropId: otherCrop.id,
      ),
    );

    final added = await state.extendPlantingToArea(
      gardenId: garden.id,
      sourceRow: 0,
      sourceCol: 0,
      targetRow: 1,
      targetCol: 2,
    );

    expect(added, 3);
    expect(state.gardens.single.cellAt(0, 1).plantingId, 'existing-planting');
    expect(state.gardens.single.cellAt(1, 1).plantingId, isNull);
    expect(state.gardens.single.cellAt(1, 2).plantingId, isNotNull);
    final copies = state.plantings.where(
      (planting) => planting.id.startsWith('drag-source-copy-'),
    );
    expect(copies, hasLength(3));
    expect(copies.every((planting) => planting.cropId == crop.id), isTrue);
    expect(
      copies.every((planting) => planting.variety == 'Сорт для копіювання'),
      isTrue,
    );
  });

  test('builds an attributed crop correction email', () {
    const draft = FeedbackDraft(
      kind: FeedbackKind.cropCorrection,
      cropName: 'часник',
      cropSlug: 'garlic',
      section: 'Сівозміна та попередники',
      replyEmail: 'user@example.com',
      message: 'Покажіть конкретні культури замість латинської родини.',
    );

    final uri = draft.toMailUri(recipient: 'team@example.com');
    expect(uri.scheme, 'mailto');
    expect(uri.path, 'team@example.com');
    expect(uri.queryParameters['subject'], contains('часник'));
    expect(uri.queryParameters['body'], contains('garlic'));
    expect(uri.queryParameters['body'], contains('Сівозміна'));
    expect(draft.toMailUri().path, 'marynnnaa01@gmail.com');
  });

  test('serializes plant protection inventory items', () {
    final item = InventoryItem(
      id: 'protection-1',
      type: InventoryItemType.plantProtection,
      barcode: '5900000000000',
      productName: 'Біологічний засіб захисту',
      instructions: 'Застосовувати лише за етикеткою.',
      createdAt: DateTime(2026, 7, 16),
    );

    final restored = InventoryItem.fromJson(item.toJson());
    expect(restored.type, InventoryItemType.plantProtection);
    expect(restored.instructions, contains('етикеткою'));
  });

  test('links a seed package to a planting and safely removes the package',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final storage = PrefsStorage(prefs);
    final state = await AppState.load(storage);
    final garden = Garden.create(
      name: 'Запаси й посадки',
      rows: 1,
      cols: 1,
      widthMeters: 2,
      heightMeters: 2,
    );
    await state.addGarden(garden);
    final tomato = state.crops.firstWhere((crop) => crop.id == 'crop_tomato');
    final seedPackage = InventoryItem(
      id: 'seed-package-link',
      type: InventoryItemType.seeds,
      barcode: '4820000000001',
      productName: 'Томат Чері',
      cropId: tomato.id,
      createdAt: DateTime(2026, 7, 16),
    );
    await state.saveInventoryItem(seedPackage);

    expect(state.inventoryByBarcode('4820000000001')?.id, seedPackage.id);
    await state.setPlanting(
      gardenId: garden.id,
      row: 0,
      col: 0,
      planting: Planting(
        id: 'linked-planting',
        gardenId: garden.id,
        cropId: tomato.id,
        inventoryItemId: seedPackage.id,
        plantedAt: DateTime(2026, 7, 16),
      ),
    );

    expect(state.activePlantingCountForInventory(seedPackage.id), 1);
    await state.deleteInventoryItem(seedPackage.id);
    final restored = await storage.load();

    expect(state.inventory, isEmpty);
    expect(state.plantings.single.inventoryItemId, isNull);
    expect(restored.data.plantings.single.inventoryItemId, isNull);
  });

  test('rejects linking fertilizer as a planted seed package', () {
    const crop = Crop(id: 'crop-test', name: 'Тестова культура');
    final garden = Garden.create(
      name: 'Перевірка',
      rows: 1,
      cols: 1,
      widthMeters: 1,
      heightMeters: 1,
    );
    final fertilizer = InventoryItem(
      id: 'fertilizer-1',
      type: InventoryItemType.fertilizer,
      productName: 'Добриво',
      createdAt: DateTime(2026, 7, 16),
    );

    expect(
      () => AppData(
        gardens: [garden],
        crops: const [crop],
        plantings: [
          Planting(
            id: 'invalid-link',
            gardenId: garden.id,
            cropId: crop.id,
            inventoryItemId: fertilizer.id,
          ),
        ],
        inventory: [fertilizer],
        reminders: const [],
      ),
      throwsArgumentError,
    );
  });

  test('harvesting clears the cell but keeps planting history', () async {
    final prefs = await SharedPreferences.getInstance();
    final storage = PrefsStorage(prefs);
    final state = await AppState.load(storage);
    final garden = Garden.create(
      name: 'Сівозміна',
      rows: 1,
      cols: 1,
      widthMeters: 2,
      heightMeters: 2,
    );
    await state.addGarden(garden);
    final tomato = state.crops.firstWhere((crop) => crop.name == 'Томат');
    await state.setPlanting(
      gardenId: garden.id,
      row: 0,
      col: 0,
      planting: Planting(
        id: 'tomato-harvest',
        gardenId: garden.id,
        cropId: tomato.id,
        plantedAt: DateTime(2026, 5, 1),
      ),
    );

    final harvested = await state.harvestPlanting(
      gardenId: garden.id,
      row: 0,
      col: 0,
      harvestedAt: DateTime(2026, 7, 15),
    );
    final restored = await storage.load();

    expect(harvested?.isHarvested, isTrue);
    expect(state.gardens.single.cellAt(0, 0).plantingId, isNull);
    expect(state.plantings, hasLength(1));
    expect(state.plantings.single.row, 0);
    expect(state.plantings.single.col, 0);
    expect(
      state.plantingHistoryForCell(gardenId: garden.id, row: 0, col: 0),
      hasLength(1),
    );
    expect(restored.data.plantings.single.harvestedAt, DateTime(2026, 7, 15));
  });

  testWidgets('shows care guidance for crops planted in the garden', (
    tester,
  ) async {
    final setup = await _createApp(withCatalog: true);
    final garden = Garden.create(
      name: 'Догляд',
      rows: 1,
      cols: 1,
      widthMeters: 2,
      heightMeters: 2,
    );
    await setup.state.addGarden(garden);
    final tomato = setup.state.crops.firstWhere((crop) => crop.name == 'Томат');
    final seedPackage = InventoryItem(
      id: 'care-seed-package',
      type: InventoryItemType.seeds,
      productName: 'Томат Стійкий F1',
      cropId: tomato.id,
      varietyName: 'Стійкий F1',
      varietyType: SeedVarietyType.hybrid,
      maturityGroup: SeedMaturityGroup.early,
      resistanceClaims: 'фітофтороз — середня стійкість',
      createdAt: DateTime(2026, 7, 1),
    );
    await setup.state.saveInventoryItem(seedPackage);
    await setup.state.setPlanting(
      gardenId: garden.id,
      row: 0,
      col: 0,
      planting: Planting(
        id: 'care-planting',
        gardenId: garden.id,
        cropId: tomato.id,
        inventoryItemId: seedPackage.id,
        variety: 'Стійкий F1',
        plantedAt: DateTime(2026, 7, 1),
      ),
    );

    await tester.pumpWidget(setup.app);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Догляд'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-care-recommendations')));
    await tester.pumpAndSettle();

    expect(find.text('Догляд за ділянкою'), findsOneWidget);
    expect(find.text('Покроковий догляд: Томат'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('1. Підготовка розсади'), 180);
    await tester.pumpAndSettle();
    expect(find.text('1. Підготовка розсади'), findsOneWidget);
    expect(find.text('2. Підготовка ґрунту'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('4. Догляд і полив'), 240);
    await tester.pumpAndSettle();
    await tester.tap(find.text('4. Догляд і полив'));
    await tester.pumpAndSettle();
    expect(find.text('Полив'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('5. Дозрівання'), 240);
    await tester.pumpAndSettle();
    await tester.tap(find.text('5. Дозрівання'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Записана дата: 01.07.2026'),
      findsOneWidget,
    );
    final maturityButton = find.textContaining(
      'Нагадати про наближення дозрівання',
    );
    await tester.scrollUntilVisible(maturityButton, 180);
    await tester.pumpAndSettle();
    await tester.tap(maturityButton);
    await tester.pumpAndSettle();
    expect(
      setup.state.reminders.any(
        (reminder) => reminder.title == 'Наближається дозрівання: Томат',
      ),
      isTrue,
    );
    await tester.scrollUntilVisible(find.text('Захист рослин'), 240);
    await tester.pumpAndSettle();
    expect(find.text('Добрива'), findsOneWidget);
    await tester.tap(find.text('Захист рослин'));
    await tester.pumpAndSettle();
    expect(find.text('План захисту за етапами'), findsOneWidget);
    expect(find.text('Чи потрібна обробка при посіві'), findsOneWidget);
    expect(find.text('Враховано сорт із ринку'), findsOneWidget);
    expect(
        find.textContaining('Запланувати огляд через 3 дн.'), findsOneWidget);
  });

  test('saves and restores app data through shared preferences', () async {
    final prefs = await SharedPreferences.getInstance();
    final storage = PrefsStorage(prefs);
    final garden = Garden.create(
      name: 'Збережена ділянка',
      rows: 1,
      cols: 1,
      widthMeters: 2,
      heightMeters: 3,
    );

    await storage.save(
      AppData(gardens: [garden], crops: const [], reminders: const []),
    );
    final restored = await storage.load();

    expect(restored.recoveredCorruptedData, isFalse);
    expect(restored.data.gardens.single.name, 'Збережена ділянка');
  });

  test('backs up corrupted data instead of silently discarding it', () async {
    const corruptedJson = '{not-valid-json';
    SharedPreferences.setMockInitialValues({
      'app_data_v1': corruptedJson,
    });
    final prefs = await SharedPreferences.getInstance();
    final storage = PrefsStorage(prefs);

    final result = await storage.load();

    expect(result.recoveredCorruptedData, isTrue);
    expect(result.backupSaved, isTrue);
    expect(result.data.gardens, isEmpty);
    expect(
      prefs.getString('app_data_corrupted_backup_v1'),
      corruptedJson,
    );
  });

  test('deleting a garden also deletes only its reminders', () async {
    final prefs = await SharedPreferences.getInstance();
    final storage = PrefsStorage(prefs);
    final state = await AppState.load(storage);
    final garden = Garden.create(
      name: 'Ділянка',
      rows: 1,
      cols: 1,
      widthMeters: 1,
      heightMeters: 1,
    );
    await state.addGarden(garden);
    await state.setPlanting(
      gardenId: garden.id,
      row: 0,
      col: 0,
      planting: Planting(
        id: 'planting-linked',
        gardenId: garden.id,
        cropId: state.crops.first.id,
        plantedAt: DateTime(2026, 7, 14),
      ),
    );
    await state.addReminder(
      Reminder(
        id: 'linked',
        title: 'Пов’язане',
        date: DateTime(2026, 7, 15),
        gardenId: garden.id,
      ),
    );
    await state.addReminder(
      Reminder(
        id: 'independent',
        title: 'Окреме',
        date: DateTime(2026, 7, 16),
      ),
    );

    await state.deleteGarden(garden.id);
    final restored = await storage.load();

    expect(state.gardens, isEmpty);
    expect(state.plantings, isEmpty);
    expect(state.reminders.map((item) => item.id), ['independent']);
    expect(restored.data.gardens, isEmpty);
    expect(restored.data.plantings, isEmpty);
    expect(restored.data.reminders.map((item) => item.id), ['independent']);
  });
}

Future<({GardenApp app, AppState state})> _createApp({
  bool withCatalog = false,
}) async {
  SharedPreferences.setMockInitialValues({
    'guided_tour_completed_v1': true,
  });
  final prefs = await SharedPreferences.getInstance();
  final storage = PrefsStorage(prefs);
  final catalog = withCatalog ? await CropCatalogRepository.load() : null;
  final state = await AppState.load(
    storage,
    catalogCrops: catalog?.toCrops() ?? const [],
  );
  return (
    app: GardenApp(state: state, storage: storage),
    state: state,
  );
}
