import 'package:flutter/material.dart';

import 'dart:math' as math;

import 'care_recommendations.dart';
import 'models.dart';
import 'storage.dart';

class InheritedAppState extends InheritedWidget {
  final AppState state;
  final PrefsStorage storage;

  const InheritedAppState({
    super.key,
    required this.state,
    required this.storage,
    required super.child,
  });

  static InheritedAppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InheritedAppState>()!;

  @override
  bool updateShouldNotify(covariant InheritedAppState oldWidget) =>
      oldWidget.state != state;
}

class AppState extends ChangeNotifier {
  AppData _data;
  final PrefsStorage _storage;
  double _textScale;
  bool _researchConsent;
  bool _catalogPhotoLicense;
  String _profileName;
  final bool recoveredCorruptedData;
  final bool corruptedBackupSaved;

  AppState._(
    this._data,
    this._storage, {
    required double textScale,
    required bool researchConsent,
    required bool catalogPhotoLicense,
    required String profileName,
    required this.recoveredCorruptedData,
    required this.corruptedBackupSaved,
  })  : _textScale = textScale,
        _researchConsent = researchConsent,
        _catalogPhotoLicense = catalogPhotoLicense,
        _profileName = profileName;

  static Future<AppState> load(
    PrefsStorage storage, {
    Iterable<Crop> catalogCrops = const [],
  }) async {
    final result = await storage.load();
    return AppState._(
      result.data.withBuiltInCrops(catalogCrops),
      storage,
      textScale: storage.textScale,
      researchConsent: storage.researchConsent,
      catalogPhotoLicense: storage.catalogPhotoLicense,
      profileName: storage.profileName,
      recoveredCorruptedData: result.recoveredCorruptedData,
      corruptedBackupSaved: result.backupSaved,
    );
  }

  List<Garden> get gardens => _data.gardens;
  List<Crop> get crops => _data.crops;
  List<Planting> get plantings => _data.plantings;
  List<InventoryItem> get inventory => _data.inventory;
  List<Reminder> get reminders => _data.reminders;
  List<GardenDiaryEntry> get diaryEntries => _data.diaryEntries;
  double get textScale => _textScale;
  bool get researchConsent => _researchConsent;
  bool get catalogPhotoLicense => _catalogPhotoLicense;
  String get profileName => _profileName;

  Future<void> setProfileName(String value) async {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    await _storage.setProfileName(normalized);
    _profileName = normalized;
    notifyListeners();
  }

  Future<void> setTextScale(double value) async {
    final normalized = value.clamp(1.0, 1.5).toDouble();
    await _storage.setTextScale(normalized);
    _textScale = normalized;
    notifyListeners();
  }

  Future<void> setResearchConsent(bool value) async {
    await _storage.setResearchConsent(value);
    _researchConsent = value;
    notifyListeners();
  }

  Future<void> setCatalogPhotoLicense(bool value) async {
    await _storage.setCatalogPhotoLicense(value);
    _catalogPhotoLicense = value;
    notifyListeners();
  }

  void refreshConsentFromStorage() {
    _researchConsent = _storage.researchConsent;
    _catalogPhotoLicense = _storage.catalogPhotoLicense;
    notifyListeners();
  }

  InventoryItem? inventoryByBarcode(String barcode) {
    final normalized = barcode.trim();
    if (normalized.isEmpty) return null;
    return _data.inventory
        .where((item) => item.barcode == normalized)
        .firstOrNull;
  }

  int activePlantingCountForInventory(String inventoryItemId) => _data.plantings
      .where(
        (planting) =>
            planting.inventoryItemId == inventoryItemId &&
            !planting.isHarvested,
      )
      .length;

  Future<void> _persist(AppData nextData) async {
    await _storage.save(nextData);
    _data = nextData;
    notifyListeners();
  }

  Future<void> addGarden(Garden garden) async {
    final nextData = _data.copyWith(gardens: [..._data.gardens, garden]);
    await _persist(nextData);
  }

  Future<void> saveInventoryItem(InventoryItem item) async {
    final duplicateBarcode = item.barcode.isNotEmpty &&
        _data.inventory.any(
          (existing) =>
              existing.id != item.id && existing.barcode == item.barcode,
        );
    if (duplicateBarcode) {
      throw ArgumentError.value(
        item.barcode,
        'barcode',
        'Barcode already exists',
      );
    }
    final items = [..._data.inventory];
    final index = items.indexWhere((existing) => existing.id == item.id);
    if (index == -1) {
      items.add(item);
    } else {
      items[index] = item;
    }
    await _persist(_data.copyWith(inventory: items));
  }

  Future<void> deleteInventoryItem(String id) async {
    if (!_data.inventory.any((item) => item.id == id)) return;
    final items = _data.inventory.where((item) => item.id != id).toList();
    final plantings = _data.plantings
        .map(
          (planting) => planting.inventoryItemId == id
              ? planting.copyWith(inventoryItemId: null)
              : planting,
        )
        .toList();
    await _persist(
      _data.copyWith(inventory: items, plantings: plantings),
    );
  }

  Future<void> updateGarden(Garden garden) async {
    final idx = _data.gardens.indexWhere((g) => g.id == garden.id);
    if (idx == -1) return;
    final list = [..._data.gardens]..[idx] = garden;
    final activePlantingIds =
        garden.cells.map((cell) => cell.plantingId).whereType<String>().toSet();
    final zoneIds = garden.zones.map((zone) => zone.id).toSet();
    final plantings = _data.plantings
        .where(
      (planting) =>
          planting.gardenId != garden.id ||
          planting.isHarvested ||
          activePlantingIds.contains(planting.id),
    )
        .map((planting) {
      if (planting.gardenId != garden.id || planting.isHarvested) {
        return planting;
      }
      final zoneId = planting.row == null || planting.col == null
          ? (zoneIds.contains(planting.zoneId) ? planting.zoneId : null)
          : garden.zoneAtCell(planting.row!, planting.col!)?.id;
      return planting.copyWith(zoneId: zoneId);
    }).toList();
    await _persist(_data.copyWith(gardens: list, plantings: plantings));
  }

  Future<void> saveGardenZone({
    required String gardenId,
    required GardenZone zone,
  }) async {
    final gardenIndex = _data.gardens.indexWhere(
      (garden) => garden.id == gardenId,
    );
    if (gardenIndex == -1) throw StateError('Garden not found');
    final garden = _data.gardens[gardenIndex];
    final zones = [...garden.zones];
    final zoneIndex = zones.indexWhere((item) => item.id == zone.id);
    if (zoneIndex == -1) {
      zones.add(zone);
    } else {
      zones[zoneIndex] = zone;
    }
    await updateGarden(garden.copyWith(zones: zones));
  }

  Future<void> deleteGardenZone({
    required String gardenId,
    required String zoneId,
  }) async {
    final gardenIndex = _data.gardens.indexWhere(
      (garden) => garden.id == gardenId,
    );
    if (gardenIndex == -1) return;
    final garden = _data.gardens[gardenIndex];
    if (!garden.zones.any((zone) => zone.id == zoneId)) return;
    await updateGarden(
      garden.copyWith(
        zones: garden.zones.where((zone) => zone.id != zoneId).toList(),
      ),
    );
  }

  Future<void> setPlanting({
    required String gardenId,
    required int row,
    required int col,
    required Planting planting,
  }) async {
    final gardenIndex = _data.gardens.indexWhere(
      (garden) => garden.id == gardenId,
    );
    if (gardenIndex == -1) {
      throw StateError('Garden not found');
    }
    if (planting.gardenId != gardenId) {
      throw ArgumentError.value(
        planting.gardenId,
        'planting',
        'Planting belongs to another garden',
      );
    }

    final garden = _data.gardens[gardenIndex];
    final cell = garden.cellAt(row, col);
    final previousPlantingId = cell.plantingId;
    if (planting.inventoryItemId != null) {
      final item = _data.inventory
          .where((entry) => entry.id == planting.inventoryItemId)
          .firstOrNull;
      if (item == null || item.type != InventoryItemType.seeds) {
        throw ArgumentError.value(
          planting.inventoryItemId,
          'inventoryItemId',
          'Planting inventory item must be a seed package',
        );
      }
      if (item.cropId != null && item.cropId != planting.cropId) {
        throw ArgumentError.value(
          planting.cropId,
          'cropId',
          'Planting crop must match the seed package',
        );
      }
    }
    final crop = planting.cropId == null
        ? null
        : _data.crops.where((item) => item.id == planting.cropId).firstOrNull;
    final maturityGroup = planting.inventoryItemId == null
        ? SeedMaturityGroup.unknown
        : _data.inventory
                .where((item) => item.id == planting.inventoryItemId)
                .firstOrNull
                ?.maturityGroup ??
            SeedMaturityGroup.unknown;
    final estimate = crop == null || planting.plantedAt == null
        ? null
        : maturityEstimateFor(
            crop,
            maturityGroups: [maturityGroup],
            plantingEventType: planting.eventType,
            agroclimaticZone: garden.agroclimaticZone,
          );
    final normalizedPlanting = planting.copyWith(
      row: row,
      col: col,
      zoneId: garden.zoneAtCell(row, col)?.id,
      harvestedAt: null,
      expectedMaturityAt: estimate == null
          ? null
          : planting.plantedAt!.add(Duration(days: estimate.earliestDays)),
      expectedHarvestAt: estimate == null
          ? null
          : planting.plantedAt!.add(Duration(days: estimate.latestDays)),
      timingRuleVersion: estimate?.ruleVersion ?? '',
      status: planting.status == PlantingStatus.harvested
          ? PlantingStatus.harvested
          : planting.status == PlantingStatus.maturing
              ? PlantingStatus.maturing
              : planting.plantedAt == null
                  ? PlantingStatus.planned
                  : estimate != null &&
                          DateTime.now().isAfter(
                            planting.plantedAt!
                                .add(Duration(days: estimate.earliestDays)),
                          )
                      ? PlantingStatus.maturing
                      : planting.status == PlantingStatus.planned
                          ? PlantingStatus.planted
                          : planting.status,
    );
    final updatedGarden = garden.setCell(
      cell.copyWith(plantingId: normalizedPlanting.id),
    );
    final gardens = [..._data.gardens]..[gardenIndex] = updatedGarden;
    final plantings = [..._data.plantings];
    final plantingIndex = plantings.indexWhere(
      (item) => item.id == normalizedPlanting.id,
    );

    if (plantingIndex == -1) {
      plantings.add(normalizedPlanting);
    } else {
      plantings[plantingIndex] = normalizedPlanting;
    }
    if (previousPlantingId != null &&
        previousPlantingId != normalizedPlanting.id) {
      plantings.removeWhere((item) => item.id == previousPlantingId);
    }

    await _persist(
      _data.copyWith(gardens: gardens, plantings: plantings),
    );
  }

  Future<int> extendPlantingToArea({
    required String gardenId,
    required int sourceRow,
    required int sourceCol,
    required int targetRow,
    required int targetCol,
  }) async {
    final gardenIndex = _data.gardens.indexWhere(
      (garden) => garden.id == gardenId,
    );
    if (gardenIndex == -1) throw StateError('Garden not found');

    final garden = _data.gardens[gardenIndex];
    final sourceCell = garden.cellAt(sourceRow, sourceCol);
    garden.cellAt(targetRow, targetCol);
    final sourcePlantingId = sourceCell.plantingId;
    if (sourcePlantingId == null) return 0;
    final source = _data.plantings
        .where((planting) => planting.id == sourcePlantingId)
        .firstOrNull;
    if (source == null || source.isHarvested || source.gardenId != gardenId) {
      return 0;
    }

    var updatedGarden = garden;
    final plantings = [..._data.plantings];
    final startRow = math.min(sourceRow, targetRow);
    final endRow = math.max(sourceRow, targetRow);
    final startCol = math.min(sourceCol, targetCol);
    final endCol = math.max(sourceCol, targetCol);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    var added = 0;

    for (var row = startRow; row <= endRow; row++) {
      for (var col = startCol; col <= endCol; col++) {
        final cell = updatedGarden.cellAt(row, col);
        final zone = updatedGarden.zoneAtCell(row, col);
        if (cell.plantingId != null || (zone != null && !zone.canPlant)) {
          continue;
        }
        final clone = Planting(
          id: '${source.id}-copy-$stamp-$row-$col',
          gardenId: gardenId,
          cropId: source.cropId,
          inventoryItemId: source.inventoryItemId,
          zoneId: zone?.id,
          row: row,
          col: col,
          variety: source.variety,
          eventType: source.eventType,
          status: source.status,
          plantedAt: source.plantedAt,
          expectedMaturityAt: source.expectedMaturityAt,
          expectedHarvestAt: source.expectedHarvestAt,
          actualMaturityAt: source.actualMaturityAt,
          timingRuleVersion: source.timingRuleVersion,
          note: source.note,
        );
        plantings.add(clone);
        updatedGarden = updatedGarden.setCell(
          cell.copyWith(plantingId: clone.id),
        );
        added++;
      }
    }

    if (added == 0) return 0;
    final gardens = [..._data.gardens]..[gardenIndex] = updatedGarden;
    await _persist(_data.copyWith(gardens: gardens, plantings: plantings));
    return added;
  }

  List<Planting> plantingHistoryForCell({
    required String gardenId,
    required int row,
    required int col,
  }) {
    final history = _data.plantings
        .where(
          (planting) =>
              planting.gardenId == gardenId &&
              planting.row == row &&
              planting.col == col,
        )
        .toList();
    history.sort((a, b) {
      final aDate = a.harvestedAt ?? a.plantedAt ?? DateTime(1970);
      final bDate = b.harvestedAt ?? b.plantedAt ?? DateTime(1970);
      return bDate.compareTo(aDate);
    });
    return history;
  }

  Future<Planting?> harvestPlanting({
    required String gardenId,
    required int row,
    required int col,
    DateTime? harvestedAt,
  }) async {
    final gardenIndex = _data.gardens.indexWhere(
      (garden) => garden.id == gardenId,
    );
    if (gardenIndex == -1) return null;

    final garden = _data.gardens[gardenIndex];
    final cell = garden.cellAt(row, col);
    final plantingId = cell.plantingId;
    if (plantingId == null) return null;

    final plantingIndex = _data.plantings.indexWhere(
      (planting) => planting.id == plantingId,
    );
    if (plantingIndex == -1) return null;

    final current = _data.plantings[plantingIndex];
    var date = harvestedAt ?? DateTime.now();
    if (current.plantedAt != null && date.isBefore(current.plantedAt!)) {
      date = current.plantedAt!;
    }
    final harvested = current.copyWith(
      row: row,
      col: col,
      harvestedAt: date,
      status: PlantingStatus.harvested,
    );
    final updatedGarden = garden.setCell(cell.copyWith(plantingId: null));
    final gardens = [..._data.gardens]..[gardenIndex] = updatedGarden;
    final plantings = [..._data.plantings]..[plantingIndex] = harvested;

    await _persist(_data.copyWith(gardens: gardens, plantings: plantings));
    return harvested;
  }

  Future<void> removePlanting({
    required String gardenId,
    required int row,
    required int col,
  }) async {
    final gardenIndex = _data.gardens.indexWhere(
      (garden) => garden.id == gardenId,
    );
    if (gardenIndex == -1) return;

    final garden = _data.gardens[gardenIndex];
    final cell = garden.cellAt(row, col);
    final plantingId = cell.plantingId;
    if (plantingId == null) return;

    final updatedGarden = garden.setCell(cell.copyWith(plantingId: null));
    final gardens = [..._data.gardens]..[gardenIndex] = updatedGarden;
    final plantings =
        _data.plantings.where((planting) => planting.id != plantingId).toList();
    await _persist(
      _data.copyWith(gardens: gardens, plantings: plantings),
    );
  }

  Future<void> deleteGarden(String id) async {
    if (!_data.gardens.any((garden) => garden.id == id)) return;

    final nextData = _data.copyWith(
      gardens: _data.gardens.where((garden) => garden.id != id).toList(),
      plantings:
          _data.plantings.where((planting) => planting.gardenId != id).toList(),
      reminders:
          _data.reminders.where((reminder) => reminder.gardenId != id).toList(),
      diaryEntries:
          _data.diaryEntries.where((entry) => entry.gardenId != id).toList(),
    );
    await _persist(nextData);
  }

  Future<void> addReminder(Reminder r) async {
    final nextData = _data.copyWith(reminders: [..._data.reminders, r]);
    await _persist(nextData);
  }

  Future<void> updateReminder(Reminder reminder) async {
    final reminders = [..._data.reminders];
    final index = reminders.indexWhere((item) => item.id == reminder.id);
    if (index == -1) return;
    reminders[index] = reminder;
    await _persist(_data.copyWith(reminders: reminders));
  }

  Future<void> deleteReminder(String id) async {
    if (!_data.reminders.any((reminder) => reminder.id == id)) return;

    final nextData = _data.copyWith(
      reminders: _data.reminders.where((e) => e.id != id).toList(),
    );
    await _persist(nextData);
  }

  Future<void> saveDiaryEntry(GardenDiaryEntry entry) async {
    if (!_data.gardens.any((garden) => garden.id == entry.gardenId)) {
      throw ArgumentError.value(entry.gardenId, 'gardenId', 'Unknown garden');
    }
    if (entry.shareForResearch && !_researchConsent) {
      throw StateError('Research consent is not active');
    }
    if (entry.shareForCatalog && !_catalogPhotoLicense) {
      throw StateError('Catalog photo license is not active');
    }
    final entries = [..._data.diaryEntries];
    final index = entries.indexWhere((item) => item.id == entry.id);
    if (index == -1) {
      entries.add(entry);
    } else {
      entries[index] = entry;
    }
    await _persist(_data.copyWith(diaryEntries: entries));
  }

  Future<void> deleteDiaryEntry(String id) async {
    if (!_data.diaryEntries.any((entry) => entry.id == id)) return;
    await _persist(
      _data.copyWith(
        diaryEntries:
            _data.diaryEntries.where((entry) => entry.id != id).toList(),
      ),
    );
  }
}
