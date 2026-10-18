import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../app_theme.dart';
import '../diary/photo_storage.dart';
import '../models.dart';
import '../regions.dart';
import '../storage.dart';
import '../widgets/app_guide_sheet.dart';
import 'garden_screen.dart';
import 'reminders_screen.dart';

class GardenListScreen extends StatelessWidget {
  final Key? tourBrandKey;
  final Key? tourHelpKey;
  final Key? tourCreateKey;

  const GardenListScreen({
    super.key,
    this.tourBrandKey,
    this.tourHelpKey,
    this.tourCreateKey,
  });

  @override
  Widget build(BuildContext context) {
    final state = InheritedAppState.of(context).state;

    return AnimatedBuilder(
      animation: state,
      builder: (_, __) {
        final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
        final upcomingReminders = state.reminders
            .where((reminder) => !reminder.date.isBefore(DateTime.now()))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
        final nextReminder =
            upcomingReminders.isEmpty ? null : upcomingReminders.first;
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: textScale >= 1.25 ? 82 : 70,
            leadingWidth: 62,
            leading: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
              child: ClipOval(
                child: Image.asset(
                  'assets/branding/app_icon_master.png',
                  fit: BoxFit.cover,
                  semanticLabel: 'Логотип Город Мій',
                ),
              ),
            ),
            title: KeyedSubtree(
              key: tourBrandKey,
              child: Text(
                'Мої городи',
                maxLines: 1,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
              ),
            ),
            backgroundColor: AppColors.surface,
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.12),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            actions: [
              _HeaderActionFrame(
                child: IconButton(
                  tooltip: 'Нагадування',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RemindersScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
              ),
              _HeaderActionFrame(
                key: tourHelpKey,
                margin: const EdgeInsets.only(left: 6, right: 10),
                child: PopupMenuButton<String>(
                  tooltip: 'Більше дій',
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (value) {
                    if (value == 'guide') showAppGuide(context);
                    if (value == 'create') {
                      _showGardenDialog(context, state);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'guide',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.help_outline_rounded),
                        title: Text('Як користуватися'),
                      ),
                    ),
                    if (state.gardens.isNotEmpty)
                      const PopupMenuItem(
                        value: 'create',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.add_rounded),
                          title: Text('Нова ділянка'),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          body: state.gardens.isEmpty
              ? _EmptyGardenState(
                  onCreate: () => _showGardenDialog(context, state),
                  onShowGuide: () => showAppGuide(context),
                  createButtonKey: tourCreateKey,
                )
              : ListView(
                  key: const ValueKey('garden-dashboard-list'),
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                  children: [
                    _GardenOverviewCard(
                      nextReminder: nextReminder,
                    ),
                    const SizedBox(height: 26),
                    const _GardenListHeader(),
                    const SizedBox(height: 16),
                    for (final garden in state.gardens) ...[
                      _GardenCard(
                        garden: garden,
                        onEdit: () => _showGardenDialog(
                          context,
                          state,
                          existing: garden,
                        ),
                        onDelete: () =>
                            _confirmDeleteGarden(context, state, garden),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GardenScreen(
                                gardenId: garden.id,
                                onEdit: () => _showGardenDialog(
                                  context,
                                  state,
                                  existing: state.gardens.firstWhere(
                                    (item) => item.id == garden.id,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: tourCreateKey,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(62),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        onPressed: () => _showGardenDialog(context, state),
                        icon: const Icon(Icons.add_rounded, size: 28),
                        label: const Text('Нова ділянка'),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Future<void> _showGardenDialog(
    BuildContext context,
    AppState state, {
    Garden? existing,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(
      text: existing?.name ?? 'Ділянка ${state.gardens.length + 1}',
    );
    final rowsCtrl = TextEditingController(text: '${existing?.rows ?? 6}');
    final colsCtrl = TextEditingController(text: '${existing?.cols ?? 8}');
    var areaUnit = existing?.areaUnit ?? AreaUnit.squareMeters;
    final areaCtrl = TextEditingController(
      text: existing == null
          ? '0,25'
          : _formatInput(
              areaFromSquareMeters(existing.areaSquareMeters, areaUnit),
            ),
    );
    final wCtrl = TextEditingController(
      text: _formatInput(existing?.widthMeters ?? 8),
    );
    final hCtrl = TextEditingController(
      text: _formatInput(existing?.heightMeters ?? 4),
    );
    final settlementCtrl = TextEditingController(
      text: existing?.settlement ?? '',
    );
    final noteCtrl = TextEditingController(text: existing?.note ?? '');
    var sizeMode = existing?.sizeMode ?? GardenSizeMode.dimensions;
    var gardenType = existing?.type ?? GardenType.vegetableGarden;
    var soilType = existing?.soilType ?? SoilType.unknown;
    Region? selectedRegion = existing == null
        ? null
        : regionByCode(existing.oblastCode) ??
            regionByLegacyName(existing.oblast);
    var weatherSource = existing?.weatherSource ?? WeatherSource.none;

    Widget rowsField() => TextFormField(
          controller: rowsCtrl,
          decoration: const InputDecoration(labelText: 'Рядів'),
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) => _validateGridCount(
            value,
            min: Garden.minRowCount,
            max: Garden.maxRowCount,
          ),
        );

    Widget columnsField() => TextFormField(
          controller: colsCtrl,
          decoration: const InputDecoration(labelText: 'Стовпців'),
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            final countError = _validateGridCount(
              value,
              min: Garden.minColumnCount,
              max: Garden.maxColumnCount,
            );
            if (countError != null) return countError;

            final rows = int.tryParse(rowsCtrl.text);
            final cols = int.tryParse(value ?? '');
            if (rows != null &&
                cols != null &&
                !Garden.isValidCellCount(rows, cols)) {
              return 'Не більше ${Garden.maxCellCount} клітинок';
            }
            return null;
          },
        );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          title: Row(
            children: [
              const Icon(Icons.grid_view_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  existing == null ? 'Створити ділянку' : 'Редагувати ділянку',
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.softGreen,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ряди та стовпці утворять сітку, на якій ви розмістите культури.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Назва',
                      hintText: 'Наприклад, Біля дому',
                      prefixIcon: Icon(Icons.edit_outlined),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: _validateName,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<GardenType>(
                    initialValue: gardenType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Тип ділянки',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: GardenType.values
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(gardenTypeLabel(type)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => gardenType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  if (MediaQuery.sizeOf(dialogContext).width < 360) ...[
                    rowsField(),
                    const SizedBox(height: 12),
                    columnsField(),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: rowsField()),
                        const SizedBox(width: 12),
                        Expanded(child: columnsField()),
                      ],
                    ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Як вказати розмір?',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: MediaQuery.sizeOf(dialogContext).width < 360
                        ? DropdownButtonFormField<GardenSizeMode>(
                            initialValue: sizeMode,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Спосіб вимірювання',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: GardenSizeMode.area,
                                child: Text('Площа'),
                              ),
                              DropdownMenuItem(
                                value: GardenSizeMode.dimensions,
                                child: Text('Сторони'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() => sizeMode = value);
                              }
                            },
                          )
                        : SegmentedButton<GardenSizeMode>(
                            segments: const [
                              ButtonSegment(
                                value: GardenSizeMode.area,
                                icon: Icon(Icons.square_foot_rounded),
                                label: Text('Площа'),
                              ),
                              ButtonSegment(
                                value: GardenSizeMode.dimensions,
                                icon: Icon(Icons.straighten_rounded),
                                label: Text('Сторони'),
                              ),
                            ],
                            selected: {sizeMode},
                            onSelectionChanged: (selection) {
                              setDialogState(() => sizeMode = selection.single);
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  if (sizeMode == GardenSizeMode.area) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: areaCtrl,
                            decoration: InputDecoration(
                              labelText: 'Площа ділянки',
                              prefixIcon: const Icon(Icons.landscape_outlined),
                              suffixText: areaUnitLabel(areaUnit),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [_dimensionFormatter],
                            validator: (value) =>
                                _validateArea(value, areaUnit),
                            onChanged: (_) => setDialogState(() {}),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<AreaUnit>(
                            initialValue: areaUnit,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Одиниця',
                            ),
                            items: AreaUnit.values
                                .map(
                                  (unit) => DropdownMenuItem(
                                    value: unit,
                                    child: Text(areaUnitLabel(unit)),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() => areaUnit = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.softGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _areaConversionHint(areaCtrl.text, areaUnit),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Площа не задає форму ділянки, тому сітка буде умовно квадратною. Для точної форми оберіть «Сторони».',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: wCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Ширина (м)'),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.next,
                            inputFormatters: [_dimensionFormatter],
                            validator: _validateDimension,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: hCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Довжина (м)'),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [_dimensionFormatter],
                            validator: _validateDimension,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<SoilType>(
                    initialValue: soilType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Тип ґрунту',
                      prefixIcon: Icon(Icons.grass_outlined),
                    ),
                    items: SoilType.values
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(soilTypeLabel(type)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => soilType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: const Key('garden-oblast-field'),
                    initialValue: selectedRegion?.oblastCode,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Область',
                      prefixIcon: Icon(Icons.map_outlined),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('Не вказувати'),
                      ),
                      ...ukrainianRegions.map(
                        (region) => DropdownMenuItem<String>(
                          value: region.oblastCode,
                          child: Text(region.oblastName),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedRegion = value == null || value.isEmpty
                            ? null
                            : regionByCode(value);
                      });
                    },
                  ),
                  if (selectedRegion != null) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Агрокліматична зона: '
                        '${agroclimaticZoneLabel(selectedRegion!.agroclimaticZone)}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('garden-settlement-field'),
                    controller: settlementCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Населений пункт (необов’язково)',
                      prefixIcon: Icon(Icons.place_outlined),
                      helperText: 'Потрібен для локального прогнозу погоди.',
                    ),
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(Garden.maxRegionLength),
                    ],
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<WeatherSource>(
                    initialValue: weatherSource,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Джерело прогнозу',
                      prefixIcon: Icon(Icons.cloud_outlined),
                    ),
                    items: WeatherSource.values
                        .map(
                          (source) => DropdownMenuItem(
                            value: source,
                            child: Text(weatherSourceLabel(source)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => weatherSource = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Опис або нотатка',
                      prefixIcon: Icon(Icons.notes_rounded),
                      alignLabelWithHint: true,
                    ),
                    minLines: 2,
                    maxLines: 3,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(Garden.maxNoteLength),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Скасувати'),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState?.validate() != true) return;
                final rows = int.parse(rowsCtrl.text);
                final cols = int.parse(colsCtrl.text);
                if (existing != null) {
                  final removedPlantingCount = existing.cells
                      .where(
                        (cell) =>
                            cell.plantingId != null &&
                            (cell.row >= rows || cell.col >= cols),
                      )
                      .length;
                  if (removedPlantingCount > 0) {
                    final confirmed = await showDialog<bool>(
                      context: dialogContext,
                      builder: (confirmationContext) => AlertDialog(
                        title: const Text('Зменшити сітку?'),
                        content: Text(
                          'За новими межами залишиться посадок: '
                          '$removedPlantingCount. Їх буде видалено.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(confirmationContext, false),
                            child: const Text('Скасувати'),
                          ),
                          FilledButton(
                            onPressed: () =>
                                Navigator.pop(confirmationContext, true),
                            child: const Text('Продовжити'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true || !dialogContext.mounted) return;
                  }
                }

                final widthMeters = sizeMode == GardenSizeMode.area
                    ? math.sqrt(
                        areaToSquareMeters(
                          _parseDimension(areaCtrl.text),
                          areaUnit,
                        ),
                      )
                    : _parseDimension(wCtrl.text);
                final heightMeters = sizeMode == GardenSizeMode.area
                    ? widthMeters
                    : _parseDimension(hCtrl.text);
                final garden = existing == null
                    ? Garden.create(
                        name: nameCtrl.text,
                        rows: rows,
                        cols: cols,
                        widthMeters: widthMeters,
                        heightMeters: heightMeters,
                        sizeMode: sizeMode,
                        areaUnit: areaUnit,
                        type: gardenType,
                        soilType: soilType,
                        countryCode: selectedRegion?.countryCode ?? 'UA',
                        oblastCode: selectedRegion?.oblastCode ?? '',
                        oblast: selectedRegion?.oblastName ?? '',
                        agroclimaticZone: selectedRegion?.agroclimaticZone ??
                            AgroclimaticZone.unknown,
                        settlement: settlementCtrl.text.trim(),
                        weatherSource: weatherSource,
                        note: noteCtrl.text,
                      )
                    : existing.reconfigure(
                        name: nameCtrl.text,
                        rows: rows,
                        cols: cols,
                        widthMeters: widthMeters,
                        heightMeters: heightMeters,
                        sizeMode: sizeMode,
                        areaUnit: areaUnit,
                        type: gardenType,
                        soilType: soilType,
                        region: selectedRegion?.oblastName ?? '',
                        countryCode: selectedRegion?.countryCode ?? 'UA',
                        oblastCode: selectedRegion?.oblastCode ?? '',
                        oblast: selectedRegion?.oblastName ?? '',
                        agroclimaticZone: selectedRegion?.agroclimaticZone ??
                            AgroclimaticZone.unknown,
                        settlement: settlementCtrl.text.trim(),
                        weatherSource: weatherSource,
                        note: noteCtrl.text,
                        photoPlaceholder: existing.photoPlaceholder,
                      );

                try {
                  if (existing == null) {
                    await state.addGarden(garden);
                  } else {
                    await state.updateGarden(garden);
                  }
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                } on StorageWriteException {
                  if (dialogContext.mounted) {
                    _showStorageError(dialogContext);
                  }
                }
              },
              child: Text(existing == null ? 'Створити' : 'Зберегти'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteGarden(
    BuildContext context,
    AppState state,
    Garden garden,
  ) async {
    final linkedReminderCount = state.reminders
        .where((reminder) => reminder.gardenId == garden.id)
        .length;
    final diaryEntries = state.diaryEntries
        .where((entry) => entry.gardenId == garden.id)
        .toList();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Видалити ділянку?'),
        content: Text(
          '«${garden.name}» буде видалено без можливості скасування.'
          '${linkedReminderCount == 0 ? '' : '\nТакож буде видалено нагадувань: $linkedReminderCount.'}'
          '${diaryEntries.isEmpty ? '' : '\nЗаписи щоденника та їхні локальні фото: ${diaryEntries.length}.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Скасувати'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Видалити'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await state.deleteGarden(garden.id);
      final photos = DiaryPhotoStorage();
      for (final entry in diaryEntries) {
        try {
          await photos.delete(entry.photoPath);
        } catch (_) {
          // The garden data is already deleted; a stale local file is safer
          // than reporting that the whole operation failed.
        }
      }
    } on StorageWriteException {
      if (context.mounted) _showStorageError(context);
    }
  }
}

class _HeaderActionFrame extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;

  const _HeaderActionFrame({
    super.key,
    required this.child,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      margin: margin,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _EmptyGardenState extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onShowGuide;
  final Key? createButtonKey;

  const _EmptyGardenState({
    required this.onCreate,
    required this.onShowGuide,
    this.createButtonKey,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(
                color: Color(0x242E7D32),
                blurRadius: 22,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.yard_rounded,
                    color: Colors.white, size: 30),
              ),
              const SizedBox(height: 20),
              Text(
                'Почнімо з першої ділянки',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Створіть свій город, додайте культури та не забувайте про догляд.',
                style: TextStyle(color: Colors.white, height: 1.4),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: createButtonKey,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: onCreate,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Нова ділянка'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Text(
                'Як це працює',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            TextButton(
              onPressed: onShowGuide,
              child: const Text('Детальніше'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const _QuickStartStep(
          number: 1,
          icon: Icons.grid_view_rounded,
          title: 'Створіть сітку',
          description: 'Вкажіть форму і розміри ділянки.',
        ),
        const SizedBox(height: 10),
        const _QuickStartStep(
          number: 2,
          icon: Icons.touch_app_outlined,
          title: 'Натисніть на клітинку',
          description: 'Оберіть культуру, сорт та дату посадки.',
        ),
        const SizedBox(height: 10),
        const _QuickStartStep(
          number: 3,
          icon: Icons.notifications_active_outlined,
          title: 'Додайте нагадування',
          description: 'Заплануйте полив та інші роботи.',
        ),
        const SizedBox(height: 18),
        const Center(
          child: Text(
            'Поки немає ділянок. Додайте першу!',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _QuickStartStep extends StatelessWidget {
  final int number;
  final IconData icon;
  final String title;
  final String description;

  const _QuickStartStep({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.softGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              Positioned(
                right: -5,
                top: -7,
                child: Container(
                  width: 21,
                  height: 21,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$number',
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
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GardenListHeader extends StatelessWidget {
  const _GardenListHeader();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        'Мої ділянки',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
      ),
    );
  }
}

class _GardenOverviewCard extends StatelessWidget {
  final Reminder? nextReminder;

  const _GardenOverviewCard({
    required this.nextReminder,
  });

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Доброго ранку!'
        : hour < 18
            ? 'Добрий день!'
            : 'Добрий вечір!';
    final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stackContent =
                  textScale > 1.55 || constraints.maxWidth < 300;
              final greetingContent = Row(
                children: [
                  const Icon(
                    Icons.wb_sunny_outlined,
                    size: 36,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      greeting,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              );
              final weather = Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.softGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_outlined,
                      size: 22,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 6),
                    Text(
                      '+22°C',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
              if (stackContent) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    greetingContent,
                    const SizedBox(height: 14),
                    Align(alignment: Alignment.centerLeft, child: weather),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: greetingContent),
                  const SizedBox(width: 10),
                  weather,
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.softGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.assignment_turned_in_outlined,
                  size: 28,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  nextReminder == null
                      ? 'Найближчих запланованих робіт немає'
                      : '${nextReminder!.title} • '
                          '${_formatShortDate(nextReminder!.date)}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GardenCard extends StatelessWidget {
  final Garden garden;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GardenCard({
    required this.garden,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final plantedCount =
        garden.cells.where((cell) => cell.plantingId != null).length;
    final totalCount = garden.cells.length;

    final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
    return Semantics(
      button: true,
      label: 'Відкрити ${garden.name}',
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stackContent =
                    textScale >= 1.8 || constraints.maxWidth < 300;
                final preview = _GardenPreview(
                  rows: garden.rows,
                  cols: garden.cols,
                  plantedCount: plantedCount,
                  totalCount: totalCount,
                  width:
                      stackContent ? math.min(180, constraints.maxWidth) : 116,
                  height: 148,
                );
                final details = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            garden.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Меню ділянки',
                          onSelected: (value) {
                            if (value == 'edit') onEdit();
                            if (value == 'delete') onDelete();
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.edit_outlined),
                                title: Text('Редагувати'),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.delete_outline),
                                title: Text('Видалити'),
                              ),
                            ),
                          ],
                          icon: const Icon(Icons.more_vert_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _GardenMetaItem(
                      icon: Icons.local_florist_outlined,
                      text:
                          '${gardenTypeLabel(garden.type)} • ${garden.rows}×${garden.cols}',
                    ),
                    const SizedBox(height: 10),
                    _GardenMetaItem(
                      icon: Icons.straighten_rounded,
                      text: formatArea(
                        garden.areaSquareMeters,
                        garden.areaUnit,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _GardenMetaItem(
                      icon: Icons.spa_outlined,
                      text: 'Посаджено $plantedCount з $totalCount',
                    ),
                  ],
                );
                if (stackContent) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      preview,
                      const SizedBox(height: 16),
                      details,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    preview,
                    const SizedBox(width: 16),
                    Expanded(child: details),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _GardenPreview extends StatelessWidget {
  final int rows;
  final int cols;
  final int plantedCount;
  final int totalCount;
  final double width;
  final double height;

  const _GardenPreview({
    required this.rows,
    required this.cols,
    required this.plantedCount,
    required this.totalCount,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _GardenPreviewPainter(
          rows: rows,
          cols: cols,
          plantedCount: plantedCount,
          totalCount: totalCount,
        ),
      ),
    );
  }
}

class _GardenPreviewPainter extends CustomPainter {
  final int rows;
  final int cols;
  final int plantedCount;
  final int totalCount;

  const _GardenPreviewPainter({
    required this.rows,
    required this.cols,
    required this.plantedCount,
    required this.totalCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final background = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(17),
    );
    canvas.drawRRect(background, Paint()..color = AppColors.softGreen);

    final plot = RRect.fromRectAndRadius(
      Rect.fromLTWH(7, 7, size.width - 14, size.height - 14),
      const Radius.circular(10),
    );
    canvas.drawRRect(plot, Paint()..color = const Color(0xFFF7FBF5));

    final shownRows = math.min(rows, 8);
    final shownCols = math.min(cols, 8);
    final cellWidth = plot.width / shownCols;
    final cellHeight = plot.height / shownRows;
    final shownTotal = shownRows * shownCols;
    final fillCount =
        totalCount == 0 ? 0 : (shownTotal * plantedCount / totalCount).round();

    final fillPaint = Paint()..color = const Color(0xFFDDF0D8);
    for (var index = 0; index < fillCount; index++) {
      final row = index ~/ shownCols;
      final col = index % shownCols;
      canvas.drawRect(
        Rect.fromLTWH(
          plot.left + col * cellWidth + 1,
          plot.top + row * cellHeight + 1,
          cellWidth - 2,
          cellHeight - 2,
        ),
        fillPaint,
      );
      final leafIcon = Icons.spa_outlined;
      final iconPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(leafIcon.codePoint),
          style: TextStyle(
            color: AppColors.primary,
            fontSize: math.min(cellWidth, cellHeight) * 0.68,
            fontFamily: leafIcon.fontFamily,
            package: leafIcon.fontPackage,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      iconPainter.paint(
        canvas,
        Offset(
          plot.left + col * cellWidth + (cellWidth - iconPainter.width) / 2,
          plot.top + row * cellHeight + (cellHeight - iconPainter.height) / 2,
        ),
      );
    }

    final linePaint = Paint()
      ..color = const Color(0xFFACC2A5)
      ..strokeWidth = 1;
    for (var row = 1; row < shownRows; row++) {
      final y = plot.top + row * cellHeight;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), linePaint);
    }
    for (var col = 1; col < shownCols; col++) {
      final x = plot.left + col * cellWidth;
      canvas.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GardenPreviewPainter oldDelegate) {
    return rows != oldDelegate.rows ||
        cols != oldDelegate.cols ||
        plantedCount != oldDelegate.plantedCount ||
        totalCount != oldDelegate.totalCount;
  }
}

class _GardenMetaItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _GardenMetaItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 23, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

final _dimensionFormatter = FilteringTextInputFormatter.allow(
  RegExp(r'[0-9,.]'),
);

String? _validateName(String? value) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) return 'Вкажіть назву';
  if (name.length > Garden.maxNameLength) {
    return 'Не більше ${Garden.maxNameLength} символів';
  }
  return null;
}

String? _validateGridCount(String? value,
    {required int min, required int max}) {
  final number = int.tryParse(value ?? '');
  if (number == null) return 'Введіть число';
  if (number < min || number > max) return 'Від $min до $max';
  return null;
}

double _parseDimension(String value) =>
    double.parse(value.trim().replaceAll(',', '.'));

String _formatInput(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2).replaceAll('.', ',').replaceFirst(
          RegExp(r',?0+$'),
          '',
        );

String? _validateDimension(String? value) {
  final number = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
  if (number == null) return 'Введіть число';
  if (!Garden.isValidDimension(number)) {
    return 'Від 0,1 до ${Garden.maxDimensionMeters.toInt()}';
  }
  return null;
}

String? _validateArea(String? value, AreaUnit unit) {
  final number = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
  if (number == null) return 'Введіть число';
  final squareMeters = areaToSquareMeters(number, unit);
  if (!Garden.isValidArea(squareMeters)) return 'Перевірте площу';
  return null;
}

String _areaConversionHint(String value, AreaUnit unit) {
  final number = double.tryParse(value.trim().replaceAll(',', '.'));
  if (number == null || number <= 0) {
    return '1 га = 100 соток = 10 000 м²';
  }
  final squareMeters = areaToSquareMeters(number, unit);
  return '${formatArea(squareMeters, AreaUnit.squareMeters)} • '
      '${formatArea(squareMeters, AreaUnit.sotkas)} • '
      '${formatArea(squareMeters, AreaUnit.hectares)}';
}

String _formatShortDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day.$month • '
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}

void _showStorageError(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Не вдалося зберегти зміни. Спробуйте ще раз.'),
    ),
  );
}
