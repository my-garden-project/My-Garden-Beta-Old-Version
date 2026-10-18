import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../app_theme.dart';
import '../care_recommendations.dart';
import '../models.dart';
import '../storage.dart';
import '../widgets/app_guide_sheet.dart';
import '../widgets/garden_zones_sheet.dart';
import 'care_recommendations_screen.dart';
import 'garden_diary_screen.dart';

enum _GardenMenuAction { diary, guide, legend }

class GardenScreen extends StatefulWidget {
  final String gardenId;
  final VoidCallback? onEdit;

  const GardenScreen({
    super.key,
    required this.gardenId,
    this.onEdit,
  });

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> {
  static const _hintLifetime = Duration(seconds: 6);

  Timer? _hintTimer;
  bool _showGridHint = true;

  @override
  void initState() {
    super.initState();
    _hintTimer = Timer(_hintLifetime, _hideGridHint);
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  void _hideGridHint() {
    if (!mounted || !_showGridHint) return;
    setState(() => _showGridHint = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = InheritedAppState.of(context).state;

    return AnimatedBuilder(
      animation: state,
      builder: (_, __) {
        final garden = state.gardens.firstWhere((g) => g.id == widget.gardenId);
        final plantedCount =
            garden.cells.where((cell) => cell.plantingId != null).length;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              garden.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            actions: [
              if (widget.onEdit != null)
                IconButton(
                  tooltip: 'Редагувати ділянку',
                  onPressed: widget.onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
              IconButton(
                tooltip: 'Додати нагадування',
                onPressed: () => _addReminder(context, state, garden),
                icon: const Icon(Icons.add_alert_outlined),
              ),
              PopupMenuButton<_GardenMenuAction>(
                tooltip: 'Більше дій',
                onSelected: (action) {
                  switch (action) {
                    case _GardenMenuAction.diary:
                      _openDiary(context, garden.id);
                    case _GardenMenuAction.guide:
                      showAppGuide(context);
                    case _GardenMenuAction.legend:
                      _showLegend(context, state);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    key: Key('open-garden-diary-appbar'),
                    value: _GardenMenuAction.diary,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.auto_stories_outlined),
                      title: Text('Щоденник росту'),
                    ),
                  ),
                  PopupMenuItem(
                    value: _GardenMenuAction.guide,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.help_outline_rounded),
                      title: Text('Як користуватися'),
                    ),
                  ),
                  PopupMenuItem(
                    value: _GardenMenuAction.legend,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.legend_toggle),
                      title: Text('Легенда культур'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              _GardenGrid(garden: garden),
              Positioned(
                top: 10,
                left: 12,
                right: 12,
                child: IgnorePointer(
                  child: _GridStatusBar(
                    garden: garden,
                    plantedCount: plantedCount,
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: _GardenActionDock(
                  zoneCount: garden.zones.length,
                  diaryEntryCount: state.diaryEntries
                      .where((entry) => entry.gardenId == garden.id)
                      .length,
                  onZones: () => showGardenZonesSheet(
                    context,
                    gardenId: garden.id,
                  ),
                  onCare: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CareRecommendationsScreen(gardenId: garden.id),
                    ),
                  ),
                  onDiary: () => _openDiary(context, garden.id),
                ),
              ),
              Positioned(
                top: 68,
                left: 12,
                right: 12,
                child: IgnorePointer(
                  ignoring: !_showGridHint,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: _showGridHint
                        ? _TransientGridHint(
                            key: const ValueKey('garden-grid-hint'),
                            hasPlantings: plantedCount > 0,
                            onDismiss: _hideGridHint,
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openDiary(BuildContext context, String gardenId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GardenDiaryScreen(gardenId: gardenId),
      ),
    );
  }

  void _showLegend(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        children: state.crops.map((c) {
          final title =
              '${c.name}${c.variety.isEmpty ? '' : ' • ${c.variety}'}';
          return ListTile(
            leading: CircleAvatar(
              radius: 8,
              backgroundColor: _cropColor(c.id),
            ),
            title: Text(title),
            subtitle: Text('Сезон: ${seasonName(c.season)}'),
            onTap: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(c.name),
                content: Text(
                  '${c.variety.isEmpty ? '' : 'Сорт: ${c.variety}\n\n'}'
                  'Рекомендації:\n${c.recommendation}',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  )
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _addReminder(BuildContext context, AppState state, Garden garden) async {
    final titleCtrl = TextEditingController(text: 'Полив / Догляд');
    DateTime selected = DateTime.now().add(const Duration(days: 1));
    String? cropId;

    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          scrollable: true,
          title: const Text('Нове нагадування'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Назва'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Дата: ${selected.toLocal().toString().split(".").first}',
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final now = DateTime.now();
                      final date = await showDatePicker(
                        context: dialogContext,
                        initialDate: selected,
                        firstDate: now.subtract(const Duration(days: 1)),
                        lastDate: DateTime(now.year + 3),
                      );
                      if (date == null || !dialogContext.mounted) return;

                      final time = await showTimePicker(
                        context: dialogContext,
                        initialTime: TimeOfDay.fromDateTime(selected),
                      );
                      if (time == null || !dialogContext.mounted) return;

                      setDialogState(() {
                        selected = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    },
                    child: const Text('Обрати'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                initialValue: cropId,
                isExpanded: true,
                decoration:
                    const InputDecoration(labelText: 'Культура (опційно)'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Без прив’язки'),
                  ),
                  ...state.crops.map(
                    (crop) => DropdownMenuItem(
                      value: crop.id,
                      child: Text(crop.name),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setDialogState(() => cropId = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Скасувати'),
            ),
            FilledButton(
              onPressed: () async {
                final reminder = Reminder(
                  id: generateId(),
                  title: titleCtrl.text.trim().isEmpty
                      ? 'Нагадування'
                      : titleCtrl.text.trim(),
                  date: selected,
                  gardenId: garden.id,
                  cropId: cropId,
                );

                try {
                  await state.addReminder(reminder);
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                } on StorageWriteException {
                  if (dialogContext.mounted) {
                    _showStorageError(dialogContext);
                  }
                }
              },
              child: const Text('Зберегти'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GardenActionDock extends StatelessWidget {
  final int zoneCount;
  final int diaryEntryCount;
  final VoidCallback onZones;
  final VoidCallback onCare;
  final VoidCallback onDiary;

  const _GardenActionDock({
    required this.zoneCount,
    required this.diaryEntryCount,
    required this.onZones,
    required this.onCare,
    required this.onDiary,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      shadowColor: Colors.black26,
      color: AppColors.surface.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: _GridAction(
                key: const ValueKey('open-garden-zones'),
                icon: Icons.grid_view_rounded,
                label: 'Сегменти',
                badge: zoneCount,
                onTap: onZones,
              ),
            ),
            const _DockDivider(),
            Expanded(
              child: _GridAction(
                key: const ValueKey('open-care-recommendations'),
                icon: Icons.water_drop_rounded,
                label: 'Догляд',
                onTap: onCare,
              ),
            ),
            const _DockDivider(),
            Expanded(
              child: _GridAction(
                key: const Key('open-garden-diary'),
                icon: Icons.photo_camera_back_outlined,
                label: 'Щоденник',
                badge: diaryEntryCount,
                onTap: onDiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? badge;
  final VoidCallback onTap;

  const _GridAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: AppColors.primary, size: 23),
                if (badge != null && badge! > 0)
                  Positioned(
                    top: -7,
                    right: -10,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 17),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.darkGreen,
                        borderRadius: BorderRadius.all(Radius.circular(9)),
                      ),
                      child: Text(
                        '$badge',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _DockDivider extends StatelessWidget {
  const _DockDivider();

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 34,
        color: AppColors.border,
      );
}

class _GridStatusBar extends StatelessWidget {
  final Garden garden;
  final int plantedCount;

  const _GridStatusBar({required this.garden, required this.plantedCount});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5,
      shadowColor: Colors.black12,
      color: AppColors.surface.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(18),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  const Icon(
                    Icons.square_foot_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      formatArea(garden.areaSquareMeters, garden.areaUnit),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 26, color: AppColors.border),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  Icon(
                    plantedCount == 0
                        ? Icons.add_circle_outline_rounded
                        : Icons.eco_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '$plantedCount/${garden.cells.length} клітинок',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransientGridHint extends StatelessWidget {
  final bool hasPlantings;
  final VoidCallback onDismiss;

  const _TransientGridHint({
    super.key,
    required this.hasPlantings,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IgnorePointer(
          child: Material(
            elevation: 7,
            shadowColor: Colors.black26,
            color: AppColors.darkGreen.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(17),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(13, 10, 48, 10),
              child: Row(
                children: [
                  Icon(
                    hasPlantings
                        ? Icons.swipe_rounded
                        : Icons.touch_app_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasPlantings
                              ? 'Протягніть посадку'
                              : 'Додайте першу посадку',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasPlantings
                              ? 'Затисніть культуру й потягніть до іншої вільної клітинки.'
                              : 'Натисніть на вільну клітинку та оберіть культуру.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.86),
                            fontSize: 11.5,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 4,
          top: 8,
          child: Semantics(
            button: true,
            label: 'Закрити підказку',
            child: IconButton(
              key: const ValueKey('dismiss-garden-grid-hint'),
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
      ],
    );
  }
}

class _CropPickerSheet extends StatefulWidget {
  final List<Crop> crops;
  final String? selectedCropId;

  const _CropPickerSheet({
    required this.crops,
    required this.selectedCropId,
  });

  @override
  State<_CropPickerSheet> createState() => _CropPickerSheetState();
}

class _CropPickerSheetState extends State<_CropPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _query.trim().toLowerCase();
    final filtered = widget.crops.where((crop) {
      if (normalizedQuery.isEmpty) return true;
      return [
        crop.name,
        crop.variety,
        crop.namePl,
        crop.nameEn,
        crop.latinName,
      ].any((value) => value.toLowerCase().contains(normalizedQuery));
    }).toList(growable: false);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Оберіть культуру',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Шукайте українською, польською або за латинською назвою.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          TextField(
            key: const Key('planting-crop-search'),
            controller: _searchController,
            autofocus: false,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Наприклад, томат або pomidor',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Очистити пошук',
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(Icons.clear_rounded),
                    ),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 10),
          Text(
            'Знайдено: ${filtered.length}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'Нічого не знайдено.\nСпробуйте іншу назву.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  )
                : ListView.separated(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 56),
                    itemBuilder: (context, index) {
                      final crop = filtered[index];
                      final details = [
                        if (crop.namePl.isNotEmpty) crop.namePl,
                        if (crop.latinName.isNotEmpty) crop.latinName,
                      ].join(' • ');
                      final selected = crop.id == widget.selectedCropId;
                      return ListTile(
                        key: ValueKey('planting-crop-option-${crop.id}'),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.softGreen,
                          foregroundColor: AppColors.primary,
                          child: const Icon(Icons.eco_outlined),
                        ),
                        title: Text(
                          crop.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: details.isEmpty ? null : Text(details),
                        trailing: selected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primary,
                              )
                            : null,
                        onTap: () => Navigator.pop(context, crop.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PlantingDateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onChanged;

  const _PlantingDateField({
    super.key,
    required this.label,
    required this.value,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final initial = value ?? lastDate;
        final date = await showDatePicker(
          context: context,
          initialDate: initial.isBefore(firstDate) ? firstDate : initial,
          firstDate: firstDate,
          lastDate: lastDate,
        );
        if (date != null) onChanged(date);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(value == null ? 'Не вказана' : _formatDate(value!)),
      ),
    );
  }
}

class _PlantingDragData {
  final int row;
  final int col;

  const _PlantingDragData({required this.row, required this.col});
}

String _gridCellName(int row, int col) {
  var number = col + 1;
  var column = '';
  while (number > 0) {
    number -= 1;
    column = String.fromCharCode(65 + (number % 26)) + column;
    number ~/= 26;
  }
  return '$column${row + 1}';
}

String _cellSemanticsLabel({
  required String cellName,
  required Crop? crop,
  required bool hasPlanting,
  required GardenZone? zone,
}) {
  if (crop != null) {
    final zoneText = zone == null ? '' : ', зона ${zone.name}';
    return 'Клітинка $cellName, ${crop.name}$zoneText. '
        'Натисніть, щоб редагувати посадку.';
  }
  if (hasPlanting) {
    final zoneText = zone == null ? '' : ', зона ${zone.name}';
    return 'Клітинка $cellName, посадка$zoneText. '
        'Натисніть, щоб редагувати.';
  }
  if (zone != null && !zone.canPlant) {
    return 'Клітинка $cellName, зона ${zone.name}, посадки заборонені.';
  }
  final zoneText = zone == null ? '' : ', зона ${zone.name}';
  return 'Клітинка $cellName, порожня$zoneText. '
      'Натисніть, щоб додати посадку.';
}

class _CropCellContent extends StatelessWidget {
  final Crop? crop;
  final bool compact;

  const _CropCellContent({required this.crop, required this.compact});

  @override
  Widget build(BuildContext context) {
    final current = crop;
    final symbol = current == null ? '🌱' : _cropSymbol(current);
    if (compact) {
      return Text(
        symbol,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18, height: 1),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(symbol, style: const TextStyle(fontSize: 21, height: 1)),
          const SizedBox(height: 3),
          Text(
            current?.name ?? 'Посадка',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              height: 1.05,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

String _cropSymbol(Crop crop) {
  final key = crop.slug.isNotEmpty
      ? crop.slug
      : crop.id.startsWith('crop_')
          ? crop.id.substring(5)
          : crop.id;
  return switch (key) {
    'tomato' => '🍅',
    'cucumber' || 'zucchini' => '🥒',
    'sweet_pepper' => '🫑',
    'eggplant' => '🍆',
    'potato' => '🥔',
    'carrot' || 'parsnip' => '🥕',
    'onion' => '🧅',
    'garlic' => '🧄',
    'white_cabbage' ||
    'red_cabbage' ||
    'savoy_cabbage' ||
    'brussels_sprouts' ||
    'kale' ||
    'kohlrabi' ||
    'chinese_cabbage' ||
    'bok_choy' ||
    'lettuce' ||
    'spinach' ||
    'swiss_chard' =>
      '🥬',
    'cauliflower' || 'broccoli' => '🥦',
    'pea' => '🫛',
    'common_bean' || 'fava_bean' => '🫘',
    'pumpkin' || 'butternut_squash' => '🎃',
    'watermelon' => '🍉',
    'melon' => '🍈',
    'beetroot' ||
    'radish' ||
    'turnip' ||
    'root_parsley' ||
    'celeriac' ||
    'celery' ||
    'leek' ||
    'chives' ||
    'arugula' ||
    'sorrel' ||
    'dill' ||
    'leaf_parsley' ||
    'coriander' ||
    'basil' ||
    'thyme' ||
    'oregano' ||
    'marjoram' ||
    'rosemary' ||
    'peppermint' ||
    'sage' =>
      '🌿',
    _ => '🌱',
  };
}

class _GardenGrid extends StatelessWidget {
  final Garden garden;
  const _GardenGrid({required this.garden});

  @override
  Widget build(BuildContext context) {
    final state = InheritedAppState.of(context).state;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: DecoratedBox(
        key: const ValueKey('garden-grid-canvas'),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              const gridInsets = EdgeInsets.fromLTRB(0, 52, 0, 68);
              final boxW = w;
              final boxH = (h - gridInsets.vertical).clamp(1.0, h).toDouble();
              final showAddIcons = garden.cells.length <= 100;
              final cellWidth = boxW / garden.cols;
              final cellHeight = boxH / garden.rows;
              final compactCropLabels = cellWidth < 52 || cellHeight < 48;

              return Padding(
                padding: gridInsets,
                child: SizedBox(
                  width: boxW,
                  height: boxH,
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: garden.cols,
                      childAspectRatio:
                          (boxW / garden.cols) / (boxH / garden.rows),
                    ),
                    itemCount: garden.rows * garden.cols,
                    itemBuilder: (context, i) {
                      final r = i ~/ garden.cols;
                      final c = i % garden.cols;

                      final cell = garden.cellAt(r, c);
                      final plantingIndex = cell.plantingId == null
                          ? -1
                          : state.plantings.indexWhere(
                              (planting) => planting.id == cell.plantingId,
                            );
                      final planting = plantingIndex == -1
                          ? null
                          : state.plantings[plantingIndex];
                      final cropIndex = planting?.cropId == null
                          ? -1
                          : state.crops.indexWhere(
                              (crop) => crop.id == planting!.cropId,
                            );
                      final crop =
                          cropIndex == -1 ? null : state.crops[cropIndex];
                      final zone = garden.zoneAtCell(r, c);
                      final zoneBounds =
                          zone == null ? null : garden.zoneGridBounds(zone);
                      final isZoneAnchor = zoneBounds != null &&
                          zoneBounds.startRow == r &&
                          zoneBounds.startCol == c;

                      final cellName = _gridCellName(r, c);
                      final semanticsLabel = _cellSemanticsLabel(
                        cellName: cellName,
                        crop: crop,
                        hasPlanting: planting != null,
                        zone: zone,
                      );
                      final tile = Semantics(
                        button: true,
                        label: semanticsLabel,
                        child: ExcludeSemantics(
                          child: InkWell(
                            key: ValueKey('garden-cell-$r-$c'),
                            onTap: () => _editPlanting(context, garden, r, c),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: zone == null
                                      ? AppColors.surface
                                      : AppColors.surface
                                          .withValues(alpha: 0.9),
                                  width: 1.4,
                                ),
                                color: crop != null
                                    ? _cropColor(crop.id)
                                        .withValues(alpha: 0.42)
                                    : planting == null
                                        ? zone == null
                                            ? AppColors.softGreen
                                            : Color(zone.colorValue)
                                        : AppColors.primaryBright
                                            .withValues(alpha: 0.2),
                              ),
                              child: Center(
                                child: crop != null || planting != null
                                    ? _CropCellContent(
                                        crop: crop,
                                        compact: compactCropLabels,
                                      )
                                    : isZoneAnchor
                                        ? Padding(
                                            padding: const EdgeInsets.all(2),
                                            child: Text(
                                              zone!.name,
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          )
                                        : zone != null && !zone.canPlant
                                            ? const Icon(
                                                Icons.more_horiz_rounded,
                                                size: 14,
                                                color: AppColors.earthBrown,
                                              )
                                            : showAddIcons
                                                ? const Icon(
                                                    Icons
                                                        .add_circle_outline_rounded,
                                                    size: 17,
                                                    color: AppColors.primary,
                                                  )
                                                : null,
                              ),
                            ),
                          ),
                        ),
                      );
                      final draggable = planting == null
                          ? tile
                          : LongPressDraggable<_PlantingDragData>(
                              key: ValueKey('planting-drag-$r-$c'),
                              data: _PlantingDragData(row: r, col: c),
                              dragAnchorStrategy: pointerDragAnchorStrategy,
                              feedback: Material(
                                color: Colors.transparent,
                                child: Container(
                                  constraints:
                                      const BoxConstraints(maxWidth: 170),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.darkGreen,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    crop?.name ?? 'Посадка',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.4,
                                child: tile,
                              ),
                              child: tile,
                            );

                      return DragTarget<_PlantingDragData>(
                        onWillAcceptWithDetails: (details) {
                          final source = details.data;
                          final isAnotherCell =
                              source.row != r || source.col != c;
                          return isAnotherCell &&
                              cell.plantingId == null &&
                              (zone == null || zone.canPlant);
                        },
                        onAcceptWithDetails: (details) async {
                          final source = details.data;
                          try {
                            final count = await state.extendPlantingToArea(
                              gardenId: garden.id,
                              sourceRow: source.row,
                              sourceCol: source.col,
                              targetRow: r,
                              targetCol: c,
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  count == 0
                                      ? 'У вибраній області немає вільних клітинок.'
                                      : 'Культуру додано ще на $count кліт.',
                                ),
                              ),
                            );
                          } on StorageWriteException {
                            if (context.mounted) _showStorageError(context);
                          }
                        },
                        builder: (context, candidates, rejected) => Stack(
                          fit: StackFit.expand,
                          children: [
                            draggable,
                            if (candidates.isNotEmpty)
                              IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.12),
                                    border: Border.all(
                                      color: AppColors.primary,
                                      width: 3,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _editPlanting(BuildContext context, Garden garden, int r, int c) async {
    HapticFeedback.selectionClick();

    final state = InheritedAppState.of(context).state;
    final originalCell = garden.cellAt(r, c);
    final zone = garden.zoneAtCell(r, c);
    if (zone != null && !zone.canPlant && originalCell.plantingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '«${zone.name}» позначено як зону без посадок.',
          ),
        ),
      );
      return;
    }
    final plantingIndex = originalCell.plantingId == null
        ? -1
        : state.plantings.indexWhere(
            (planting) => planting.id == originalCell.plantingId,
          );
    final existingPlanting =
        plantingIndex == -1 ? null : state.plantings[plantingIndex];
    final formKey = GlobalKey<FormState>();
    String? selectedCropId = existingPlanting?.cropId;
    String? selectedInventoryItemId = existingPlanting?.inventoryItemId;
    var selectedEventType =
        existingPlanting?.eventType ?? PlantingEventType.sowing;
    var selectedStatus = existingPlanting?.status ?? PlantingStatus.planned;
    DateTime? selectedDate = existingPlanting?.plantedAt;
    DateTime? actualMaturityDate = existingPlanting?.actualMaturityAt;
    final varietyCtrl = TextEditingController(
      text: existingPlanting?.variety ?? '',
    );
    final noteCtrl = TextEditingController(
      text: existingPlanting?.note ?? '',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 12,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      existingPlanting == null
                          ? 'Нова посадка'
                          : 'Редагувати посадку',
                      style: Theme.of(sheetContext).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Клітинка ${_gridCellName(r, c)}'
                      '${zone == null ? '' : ' • ${zone.name}'}',
                      style: Theme.of(sheetContext).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Оберіть культуру та додайте деталі посадки.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    FormField<String>(
                      key: const Key('planting-crop'),
                      initialValue: selectedCropId,
                      validator: (value) =>
                          value == null ? 'Оберіть культуру' : null,
                      builder: (cropField) {
                        final selectedIndex = selectedCropId == null
                            ? -1
                            : state.crops.indexWhere(
                                (crop) => crop.id == selectedCropId,
                              );
                        final selectedCrop = selectedIndex == -1
                            ? null
                            : state.crops[selectedIndex];
                        return Semantics(
                          button: true,
                          label: selectedCrop == null
                              ? 'Обрати культуру. Натисніть, щоб знайти.'
                              : 'Культура: ${selectedCrop.name}. '
                                  'Натисніть, щоб змінити.',
                          child: ExcludeSemantics(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(4),
                              onTap: () async {
                                final value =
                                    await showModalBottomSheet<String>(
                                  context: sheetContext,
                                  isScrollControlled: true,
                                  useSafeArea: true,
                                  showDragHandle: true,
                                  builder: (_) => FractionallySizedBox(
                                    heightFactor: 0.9,
                                    child: _CropPickerSheet(
                                      crops: state.crops,
                                      selectedCropId: selectedCropId,
                                    ),
                                  ),
                                );
                                if (value == null || !sheetContext.mounted) {
                                  return;
                                }
                                setSheetState(() {
                                  selectedCropId = value;
                                  selectedEventType =
                                      defaultPlantingEventTypeFor(
                                    state.crops
                                        .firstWhere((crop) => crop.id == value),
                                  );
                                  final inventoryIndex =
                                      selectedInventoryItemId == null
                                          ? -1
                                          : state.inventory.indexWhere(
                                              (item) =>
                                                  item.id ==
                                                  selectedInventoryItemId,
                                            );
                                  if (inventoryIndex != -1 &&
                                      state.inventory[inventoryIndex].cropId !=
                                          value) {
                                    selectedInventoryItemId = null;
                                  }
                                });
                                cropField.didChange(value);
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Культура',
                                  border: const OutlineInputBorder(),
                                  errorText: cropField.errorText,
                                  prefixIcon: const Icon(Icons.eco_outlined),
                                  suffixIcon: const Icon(Icons.search_rounded),
                                ),
                                child: Text(
                                  selectedCrop?.name ?? 'Натисніть, щоб знайти',
                                  style: TextStyle(
                                    color: selectedCrop == null
                                        ? AppColors.textSecondary
                                        : AppColors.textPrimary,
                                    fontWeight: selectedCrop == null
                                        ? FontWeight.w400
                                        : FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<PlantingEventType>(
                      initialValue: selectedEventType,
                      decoration: const InputDecoration(
                        labelText: 'Тип події',
                        border: OutlineInputBorder(),
                      ),
                      items: PlantingEventType.values
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(plantingEventTypeLabel(type)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() => selectedEventType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<PlantingStatus>(
                      key: const Key('planting-status-field'),
                      initialValue: selectedStatus == PlantingStatus.harvested
                          ? PlantingStatus.maturing
                          : selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Статус посадки',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        PlantingStatus.planned,
                        PlantingStatus.planted,
                        PlantingStatus.maturing,
                      ]
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(plantingStatusLabel(status)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() {
                            selectedStatus = value;
                            if (value != PlantingStatus.maturing) {
                              actualMaturityDate = null;
                            }
                          });
                        }
                      },
                    ),
                    if (selectedStatus == PlantingStatus.maturing) ...[
                      const SizedBox(height: 12),
                      _PlantingDateField(
                        key: const Key('actual-maturity-date'),
                        label: 'Фактичне дозрівання (необов’язково)',
                        value: actualMaturityDate,
                        firstDate: selectedDate ?? DateTime(1900),
                        lastDate: DateTime.now(),
                        onChanged: (date) {
                          setSheetState(() => actualMaturityDate = date);
                        },
                      ),
                    ],
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: const Key('planting-inventory-item'),
                      initialValue: selectedInventoryItemId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Пакет насіння із запасів (необов’язково)',
                        border: OutlineInputBorder(),
                        helperText:
                            'Так застосунок знатиме, що саме вже посаджено.',
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Без прив’язки до пакета'),
                        ),
                        ...state.inventory
                            .where(
                              (item) =>
                                  item.type == InventoryItemType.seeds &&
                                  item.cropId == selectedCropId,
                            )
                            .map(
                              (item) => DropdownMenuItem<String>(
                                value: item.id,
                                child: Text(
                                  item.brand.isEmpty
                                      ? item.productName
                                      : '${item.productName} • ${item.brand}',
                                ),
                              ),
                            ),
                      ],
                      onChanged: (value) {
                        setSheetState(() {
                          selectedInventoryItemId = value;
                          if (value == null) return;
                          final package = state.inventory.firstWhere(
                            (item) => item.id == value,
                          );
                          if (package.varietyName.isNotEmpty) {
                            varietyCtrl.text = package.varietyName;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: varietyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Сорт (необов’язково)',
                        hintText: 'Наприклад, Де Барао або Чері',
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(
                          Planting.maxVarietyLength,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FormField<DateTime>(
                      initialValue: selectedDate,
                      validator: (value) =>
                          selectedStatus != PlantingStatus.planned &&
                                  value == null
                              ? 'Оберіть дату — вона потрібна для прогнозу'
                              : null,
                      builder: (dateField) => InkWell(
                        onTap: () async {
                          final now = DateTime.now();
                          final date = await showDatePicker(
                            context: sheetContext,
                            initialDate: selectedDate ?? now,
                            firstDate: DateTime(1900),
                            lastDate: DateTime(now.year + 10),
                          );
                          if (date == null || !sheetContext.mounted) return;

                          setSheetState(() => selectedDate = date);
                          dateField.didChange(date);
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: selectedStatus == PlantingStatus.planned
                                ? '${plantingEventTypeLabel(selectedEventType)}: дата (необов’язково)'
                                : '${plantingEventTypeLabel(selectedEventType)}: дата',
                            border: const OutlineInputBorder(),
                            errorText: dateField.errorText,
                            suffixIcon: const Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            selectedDate == null
                                ? 'Не вказана'
                                : _formatDate(selectedDate!),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: noteCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Нотатка (необов’язково)',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      minLines: 2,
                      maxLines: 4,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(
                          Planting.maxNoteLength,
                        ),
                      ],
                    ),
                    if (existingPlanting != null) ...[
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        onPressed: () => _confirmHarvestPlanting(
                          sheetContext,
                          state,
                          garden,
                          r,
                          c,
                          existingPlanting,
                        ),
                        icon: const Icon(Icons.agriculture_outlined),
                        label: const Text('Зібрати врожай'),
                      ),
                      const SizedBox(height: 2),
                      TextButton.icon(
                        onPressed: () => _confirmDeletePlanting(
                          sheetContext,
                          state,
                          garden,
                          r,
                          c,
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Видалити посадку'),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            child: const Text('Скасувати'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              if (formKey.currentState?.validate() != true) {
                                return;
                              }

                              final planting = Planting(
                                id: existingPlanting?.id ?? generateId(),
                                gardenId: garden.id,
                                cropId: selectedCropId,
                                inventoryItemId: selectedInventoryItemId,
                                variety: varietyCtrl.text.trim(),
                                eventType: selectedEventType,
                                status: selectedStatus,
                                plantedAt: selectedDate,
                                actualMaturityAt: actualMaturityDate,
                                note: noteCtrl.text.trim(),
                              );

                              try {
                                await state.setPlanting(
                                  gardenId: garden.id,
                                  row: r,
                                  col: c,
                                  planting: planting,
                                );
                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }
                              } on StorageWriteException {
                                if (sheetContext.mounted) {
                                  _showStorageError(sheetContext);
                                }
                              }
                            },
                            child: const Text('Зберегти'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmHarvestPlanting(
    BuildContext context,
    AppState state,
    Garden garden,
    int row,
    int col,
    Planting planting,
  ) async {
    final crop = planting.cropId == null
        ? null
        : state.crops.where((item) => item.id == planting.cropId).firstOrNull;
    final today = DateTime.now();
    if (planting.plantedAt != null && planting.plantedAt!.isAfter(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Дата посадки ще не настала. Спочатку змініть статус.'),
        ),
      );
      return;
    }
    var selectedHarvestDate = DateTime(today.year, today.month, today.day);
    final harvestDate = await showDialog<DateTime>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Урожай зібрано?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${crop == null ? 'Посадка' : '«${crop.name}»'} буде '
                'перенесена в історію, а клітинка стане вільною.',
              ),
              const SizedBox(height: 14),
              _PlantingDateField(
                key: const Key('actual-harvest-date'),
                label: 'Фактична дата збору',
                value: selectedHarvestDate,
                firstDate: planting.plantedAt ?? DateTime(1900),
                lastDate: today,
                onChanged: (date) {
                  setDialogState(() => selectedHarvestDate = date);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Скасувати'),
            ),
            FilledButton.icon(
              onPressed: () =>
                  Navigator.pop(dialogContext, selectedHarvestDate),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Так, зібрано'),
            ),
          ],
        ),
      ),
    );
    if (harvestDate == null || !context.mounted) return;

    final rootContext = Navigator.of(context, rootNavigator: true).context;
    try {
      final harvested = await state.harvestPlanting(
        gardenId: garden.id,
        row: row,
        col: col,
        harvestedAt: harvestDate,
      );
      if (harvested == null || !context.mounted) return;
      Navigator.pop(context);
      if (crop == null || !rootContext.mounted) return;

      final suggestions = rotationSuggestionsFor(
        crop,
        state.crops,
        afterHarvest: harvested.harvestedAt,
      );
      await showDialog<void>(
        context: rootContext,
        builder: (dialogContext) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.change_circle_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Flexible(child: Text('Що посадити далі')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Після «${crop.name}» не повторюйте одразу родину '
                  '«${cropFamilyLabel(crop.family)}». За можливості поверніть '
                  'її на це місце через '
                  '${crop.minimumRotationYears == null ? '2–4 роки' : '${crop.minimumRotationYears} роки'}.',
                  style: const TextStyle(height: 1.4),
                ),
                if (suggestions.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Варіанти для наступної посадки:',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  for (final suggestion in suggestions)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.eco_outlined),
                      title: Text(suggestion.name),
                      subtitle: Text(
                        '${cropFamilyLabel(suggestion.family)} • '
                        'орієнтовно: ${seasonName(suggestion.season)}',
                      ),
                    ),
                ],
                const SizedBox(height: 8),
                const Text(
                  'Строк посадки залежить від регіону й погоди. Перед добривами перевірте стан ґрунту: після збору не завжди потрібне автоматичне підживлення.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Зрозуміло'),
            ),
          ],
        ),
      );
    } on StorageWriteException {
      if (context.mounted) _showStorageError(context);
    }
  }

  Future<void> _confirmDeletePlanting(
    BuildContext context,
    AppState state,
    Garden garden,
    int r,
    int c,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Видалити посадку?'),
        content: const Text(
          'Культуру, сорт, дату посадки та нотатку буде видалено.',
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
      await state.removePlanting(
        gardenId: garden.id,
        row: r,
        col: c,
      );
      if (context.mounted) Navigator.pop(context);
    } on StorageWriteException {
      if (context.mounted) _showStorageError(context);
    }
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}

Color _cropColor(String id) {
  final hash = id.codeUnits.fold<int>(0, (p, e) => (p * 31 + e) & 0xFFFFFF);
  const palette = [
    Color(0xFF4CAF50),
    Color(0xFF66BB6A),
    Color(0xFF81C784),
    Color(0xFF8BC34A),
    Color(0xFF9CCC65),
    Color(0xFFFFB74D),
  ];
  return palette[hash % palette.length];
}

void _showStorageError(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Не вдалося зберегти зміни. Спробуйте ще раз.'),
    ),
  );
}
