import 'package:flutter/material.dart';

import '../app_state.dart';
import '../app_theme.dart';
import '../care_recommendations.dart';
import '../catalog/crop_photo_catalog.dart';
import '../models.dart';
import '../storage.dart';

class CareRecommendationsScreen extends StatelessWidget {
  final String gardenId;

  const CareRecommendationsScreen({
    super.key,
    required this.gardenId,
  });

  @override
  Widget build(BuildContext context) {
    final state = InheritedAppState.of(context).state;

    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final garden = state.gardens.firstWhere((item) => item.id == gardenId);
        final cropsById = {for (final crop in state.crops) crop.id: crop};
        final activePlantingIds = garden.cells
            .map((cell) => cell.plantingId)
            .whereType<String>()
            .toSet();
        final activePlantings = state.plantings
            .where(
              (planting) =>
                  activePlantingIds.contains(planting.id) &&
                  !planting.isHarvested,
            )
            .toList();
        activePlantings.sort((a, b) {
          final aDate = a.plantedAt ?? DateTime(9999);
          final bDate = b.plantedAt ?? DateTime(9999);
          return aDate.compareTo(bDate);
        });
        final inventoryById = {
          for (final item in state.inventory) item.id: item,
        };
        final protectionItems = state.inventory
            .where((item) => item.type == InventoryItemType.plantProtection)
            .toList();
        final harvested = state.plantings
            .where(
              (planting) =>
                  planting.gardenId == gardenId && planting.isHarvested,
            )
            .toList()
          ..sort(
            (a, b) => b.harvestedAt!.compareTo(a.harvestedAt!),
          );

        return Scaffold(
          appBar: AppBar(title: const Text('Догляд за ділянкою')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _IntroCard(garden: garden),
              const SizedBox(height: 18),
              Text(
                'Що робити зараз',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Поради сформовані за культурами, які зараз є на сітці.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              if (activePlantings.isEmpty)
                const _EmptyCareCard()
              else
                for (var index = 0;
                    index < activePlantings.length;
                    index++) ...[
                  if (cropsById[activePlantings[index].cropId] case final crop?)
                    _CropCareCard(
                      crop: crop,
                      garden: garden,
                      planting: activePlantings[index],
                      initiallyExpanded: index == 0,
                      seedPackages: [
                        if (activePlantings[index].inventoryItemId
                            case final id?)
                          if (inventoryById[id] case final item?) item,
                      ],
                      protectionItems: protectionItems,
                      onCreateWateringCheck: () => _createWateringCheck(
                        context,
                        state,
                        garden,
                        crop,
                        activePlantings[index],
                      ),
                      onCreateMaturityReminder: (date) => _createGrowthReminder(
                        context,
                        state,
                        garden,
                        crop,
                        activePlantings[index],
                        type: ReminderType.maturity,
                        date: date,
                        title: 'Наближається дозрівання: ${crop.name}',
                        successMessage: 'Нагадування про дозрівання створено',
                      ),
                      onCreateHarvestReminder: (date) => _createGrowthReminder(
                        context,
                        state,
                        garden,
                        crop,
                        activePlantings[index],
                        type: ReminderType.harvest,
                        date: date,
                        title: 'Перевірити готовність до збору: ${crop.name}',
                        successMessage: 'Нагадування про збір створено',
                      ),
                      onCreateProtectionCheck: () => _createProtectionCheck(
                        context,
                        state,
                        garden,
                        crop,
                        activePlantings[index],
                        [
                          if (activePlantings[index].inventoryItemId
                              case final id?)
                            if (inventoryById[id] case final item?) item,
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
              const SizedBox(height: 8),
              _RotationExplainer(
                harvested: harvested,
                cropsById: cropsById,
                catalog: state.crops,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createWateringCheck(
    BuildContext context,
    AppState state,
    Garden garden,
    Crop crop,
    Planting planting,
  ) async {
    final days = recommendationsFor(
      crop: crop,
      planting: planting,
      garden: garden,
    ).defaultCheckIntervalDays;
    final reminder = Reminder(
      id: generateId(),
      title: 'Перевірити потребу в поливі: ${crop.name}',
      date: DateTime.now().add(Duration(days: days)),
      gardenId: garden.id,
      cropId: crop.id,
      plantingId: planting.id,
      type: ReminderType.watering,
      source: ReminderSource.careRule,
      ruleVersion: planting.timingRuleVersion,
      repeatEveryDays: days,
    );

    try {
      await state.addReminder(reminder);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Нагадування створено через $days дн.'),
          action: SnackBarAction(label: 'Гаразд', onPressed: () {}),
        ),
      );
    } on StorageWriteException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не вдалося зберегти нагадування.')),
      );
    }
  }

  Future<void> _createProtectionCheck(
    BuildContext context,
    AppState state,
    Garden garden,
    Crop crop,
    Planting planting,
    List<InventoryItem> seedPackages,
  ) async {
    final plan = plantProtectionPlanFor(
      crop,
      resistanceClaims: seedPackages.map((item) => item.resistanceClaims),
      maturityGroups: seedPackages.map((item) => item.maturityGroup),
    );
    final days = plan.checkIntervalDays;
    final reminder = Reminder(
      id: generateId(),
      title: 'Огляд захисту: ${crop.name}',
      date: DateTime.now().add(Duration(days: days)),
      gardenId: garden.id,
      cropId: crop.id,
      plantingId: planting.id,
      type: ReminderType.protection,
      source: ReminderSource.careRule,
    );

    try {
      await state.addReminder(reminder);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Огляд захисту заплановано через $days дн.')),
      );
    } on StorageWriteException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не вдалося зберегти нагадування.')),
      );
    }
  }

  Future<void> _createGrowthReminder(
    BuildContext context,
    AppState state,
    Garden garden,
    Crop crop,
    Planting planting, {
    required ReminderType type,
    required DateTime date,
    required String title,
    required String successMessage,
  }) async {
    final now = DateTime.now();
    final plannedMorning = DateTime(date.year, date.month, date.day, 9);
    final scheduledDate = plannedMorning.isAfter(now)
        ? plannedMorning
        : now.add(const Duration(minutes: 5));
    final duplicate = state.reminders.any(
      (reminder) =>
          reminder.gardenId == garden.id &&
          reminder.cropId == crop.id &&
          reminder.plantingId == planting.id &&
          reminder.type == type &&
          reminder.title == title &&
          _isSameCalendarDay(reminder.date, scheduledDate),
    );
    if (duplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Таке нагадування на ${_formatCareDate(scheduledDate)} вже є.',
          ),
        ),
      );
      return;
    }

    try {
      await state.addReminder(
        Reminder(
          id: generateId(),
          title: title,
          date: scheduledDate,
          gardenId: garden.id,
          cropId: crop.id,
          plantingId: planting.id,
          type: type,
          source: ReminderSource.careRule,
          ruleVersion: planting.timingRuleVersion,
        ),
      );
      if (!context.mounted) return;
      final dateNote = plannedMorning.isAfter(now)
          ? _formatCareDate(scheduledDate)
          : 'сьогодні — розрахунковий строк уже настав';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$successMessage: $dateNote.')),
      );
    } on StorageWriteException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не вдалося зберегти нагадування.')),
      );
    }
  }
}

class _IntroCard extends StatelessWidget {
  final Garden garden;

  const _IntroCard({required this.garden});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.softGreen,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white,
            child: Icon(Icons.eco_rounded, color: AppColors.primary, size: 30),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  garden.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatArea(garden.areaSquareMeters, garden.areaUnit)} • '
                  'сітка ${garden.rows}×${garden.cols}\n'
                  '${gardenTypeLabel(garden.type)} • '
                  '${soilTypeLabel(garden.soilType)} ґрунт'
                  '${garden.oblast.isEmpty ? '' : ' • ${garden.oblast}'}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.4,
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

class _CropCareCard extends StatelessWidget {
  final Crop crop;
  final Garden garden;
  final Planting planting;
  final bool initiallyExpanded;
  final List<InventoryItem> seedPackages;
  final List<InventoryItem> protectionItems;
  final VoidCallback onCreateWateringCheck;
  final ValueChanged<DateTime> onCreateMaturityReminder;
  final ValueChanged<DateTime> onCreateHarvestReminder;
  final VoidCallback onCreateProtectionCheck;

  const _CropCareCard({
    required this.crop,
    required this.garden,
    required this.planting,
    required this.initiallyExpanded,
    required this.seedPackages,
    required this.protectionItems,
    required this.onCreateWateringCheck,
    required this.onCreateMaturityReminder,
    required this.onCreateHarvestReminder,
    required this.onCreateProtectionCheck,
  });

  @override
  Widget build(BuildContext context) {
    final profile = recommendationsFor(
      crop: crop,
      planting: planting,
      garden: garden,
    );
    final protectionPlan = plantProtectionPlanFor(
      crop,
      resistanceClaims: seedPackages.map((item) => item.resistanceClaims),
      maturityGroups: seedPackages.map((item) => item.maturityGroup),
    );
    final varietyNames = <String>{
      if (planting.variety.trim().isNotEmpty) planting.variety.trim(),
      ...seedPackages
          .map((item) => item.varietyName.trim())
          .where((value) => value.isNotEmpty),
    };
    final plantingDate = planting.plantedAt;
    final maturityEstimate = maturityEstimateFor(
      crop,
      maturityGroups: seedPackages.map((item) => item.maturityGroup),
      plantingEventType: planting.eventType,
      agroclimaticZone: garden.agroclimaticZone,
    );
    final maturityDate = planting.expectedMaturityAt ??
        (plantingDate == null || maturityEstimate == null
            ? null
            : plantingDate.add(Duration(days: maturityEstimate.selectedDays)));
    final harvestDate = planting.expectedHarvestAt ?? maturityDate;
    final maturityReminderDate = maturityDate?.subtract(
      const Duration(days: 7),
    );
    final careStages = <Widget>[];

    void addStage({
      required String keyName,
      required IconData icon,
      required String title,
      required String subtitle,
      required List<Widget> children,
    }) {
      final number = careStages.length + 1;
      careStages.add(
        _CareStageSection(
          key: ValueKey('care-stage-$keyName-${planting.id}'),
          number: number,
          icon: icon,
          title: title,
          subtitle: subtitle,
          initiallyExpanded: number == 1,
          children: children,
        ),
      );
    }

    final hasSeedlingStage = _hasCareFact(crop.transplantingUkraine);
    if (hasSeedlingStage && _hasCareFact(crop.sowingUkraine)) {
      addStage(
        keyName: 'seedlings',
        icon: Icons.nature_outlined,
        title: 'Підготовка розсади',
        subtitle: 'Коли і як почати вирощування розсади',
        children: [
          _CareSection(
            icon: Icons.nature_outlined,
            title: 'Підготовка розсади',
            text: crop.sowingUkraine,
          ),
        ],
      );
    }
    if (_hasCareFact(crop.soilAndPh)) {
      addStage(
        keyName: 'soil',
        icon: Icons.landscape_outlined,
        title: 'Підготовка ґрунту',
        subtitle: 'Вимоги до ґрунту та кислотності',
        children: [
          _CareSection(
            icon: Icons.landscape_outlined,
            title: 'Ґрунт і pH',
            text: crop.soilAndPh,
          ),
        ],
      );
    }
    final plantingFacts = <String>[
      if (hasSeedlingStage) 'Висаджування: ${crop.transplantingUkraine}',
      if (!hasSeedlingStage && _hasCareFact(crop.sowingUkraine))
        'Посів: ${crop.sowingUkraine}',
      if (spacingRuleFor(crop, garden.type) case final rule?)
        'Відстань: ${spacingRuleText(rule)}'
      else if (_hasCareFact(crop.spacing))
        'Відстань: ${crop.spacing}',
    ];
    if (plantingFacts.isNotEmpty) {
      addStage(
        keyName: 'planting',
        icon: Icons.grass_rounded,
        title: 'Посадка / посів',
        subtitle: 'Строки висаджування та відстань між рослинами',
        children: [
          _CareSection(
            icon: Icons.grass_rounded,
            title: 'Посадка / посів',
            text: plantingFacts.join('. '),
          ),
        ],
      );
    }
    addStage(
      keyName: 'care',
      icon: Icons.water_drop_outlined,
      title: 'Догляд і полив',
      subtitle: 'Поточний догляд та перевірка вологості',
      children: [
        _CareSection(
          icon: Icons.water_drop_outlined,
          title: 'Полив',
          text: profile.watering,
        ),
        if (crop.catalogId.isEmpty) ...[
          const SizedBox(height: 9),
          _CareSection(
            icon: Icons.yard_outlined,
            title: 'Догляд',
            text: profile.care,
          ),
        ],
        const SizedBox(height: 9),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: onCreateWateringCheck,
            icon: const Icon(Icons.notifications_active_outlined),
            label: Text(
              'Нагадати через ${profile.defaultCheckIntervalDays} дн.',
            ),
          ),
        ),
      ],
    );
    if (_hasCareFact(crop.maturity)) {
      addStage(
        keyName: 'maturity',
        icon: Icons.timelapse_rounded,
        title: 'Дозрівання',
        subtitle: 'Орієнтовний строк і ознаки стиглості',
        children: [
          _CareSection(
            icon: Icons.timelapse_rounded,
            title: 'Дозрівання',
            text: crop.maturity,
          ),
          const SizedBox(height: 9),
          _RipenessPhoto(crop: crop),
          const SizedBox(height: 9),
          _GrowthTimingPanel(
            key: ValueKey('maturity-timing-${planting.id}'),
            planting: planting,
            actualDate: planting.actualMaturityAt,
            stageLabel: 'Дозрівання',
            plantingDate: plantingDate,
            estimate: maturityEstimate,
            targetDate: maturityDate,
            reminderDate: maturityReminderDate,
            buttonLabel: 'Нагадати про наближення дозрівання',
            missingDateText: 'Додайте дату посіву / посадки у клітинці, '
                'щоб розрахувати дозрівання.',
            onCreateReminder: maturityReminderDate == null
                ? null
                : () => onCreateMaturityReminder(maturityReminderDate),
          ),
        ],
      );
    }
    if (_hasCareFact(crop.harvest)) {
      addStage(
        keyName: 'harvest',
        icon: Icons.shopping_basket_outlined,
        title: 'Збір',
        subtitle: 'Коли та як збирати врожай',
        children: [
          _CareSection(
            icon: Icons.shopping_basket_outlined,
            title: 'Збір урожаю',
            text: crop.harvest,
          ),
          const SizedBox(height: 9),
          _RipenessPhoto(crop: crop),
          const SizedBox(height: 9),
          _GrowthTimingPanel(
            key: ValueKey('harvest-timing-${planting.id}'),
            planting: planting,
            actualDate: planting.harvestedAt,
            stageLabel: 'Збір',
            plantingDate: plantingDate,
            estimate: maturityEstimate,
            targetDate: harvestDate,
            reminderDate: harvestDate,
            buttonLabel: 'Нагадати перевірити врожай',
            missingDateText: 'Додайте дату посіву / посадки у клітинці, '
                'щоб розрахувати орієнтовний збір.',
            onCreateReminder: harvestDate == null
                ? null
                : () => onCreateHarvestReminder(harvestDate),
          ),
        ],
      );
    }

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ExpansionTile(
        key: ValueKey('care-planting-${planting.id}'),
        initiallyExpanded: initiallyExpanded,
        shape: const RoundedRectangleBorder(),
        collapsedShape: const RoundedRectangleBorder(),
        tilePadding: const EdgeInsets.fromLTRB(14, 7, 14, 7),
        leading: CircleAvatar(
          backgroundColor: AppColors.softGreen,
          child: const Icon(Icons.spa_rounded, color: AppColors.primary),
        ),
        title: Text(
          crop.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${planting.col == null || planting.row == null ? 'Ділянка' : _gridCellLabel(planting.col!, planting.row!)} • '
          '${plantingEventTypeLabel(planting.eventType)} • '
          '${varietyNames.isEmpty ? cropFamilyLabel(crop.family) : varietyNames.join(', ')}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _CarePlanIntroduction(cropName: crop.name),
          const SizedBox(height: 11),
          ...careStages,
          const SizedBox(height: 9),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Додатково',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
            ),
          ),
          const SizedBox(height: 8),
          _CareExtraSection(
            key: ValueKey('care-extra-fertilizer-${planting.id}'),
            icon: Icons.science_outlined,
            title: 'Добрива',
            subtitle: 'Підживлення лише за потреби рослини та ґрунту',
            children: [
              _CareSection(
                icon: Icons.science_outlined,
                title: 'Рекомендації щодо добрив',
                text: profile.fertilizer,
              ),
            ],
          ),
          _CareExtraSection(
            key: ValueKey('care-extra-protection-${planting.id}'),
            icon: Icons.health_and_safety_outlined,
            title: 'Захист рослин',
            subtitle: 'Ризики, симптоми та безпечний план дій',
            children: [
              _ProtectionPlanSection(
                crop: crop,
                plan: protectionPlan,
                planting: planting,
                seedPackages: seedPackages,
                protectionItems: protectionItems,
              ),
              const SizedBox(height: 9),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  key: ValueKey('create-protection-check-${planting.id}'),
                  onPressed: onCreateProtectionCheck,
                  icon: const Icon(Icons.health_and_safety_outlined),
                  label: Text(
                    'Запланувати огляд через '
                    '${protectionPlan.checkIntervalDays} дн.',
                  ),
                ),
              ),
            ],
          ),
          _CareExtraSection(
            key: ValueKey('care-extra-safety-${planting.id}'),
            icon: Icons.shield_outlined,
            title: 'Безпека',
            subtitle: 'Обмеження для добрив і засобів захисту',
            children: const [
              _SafetyNote(),
            ],
          ),
        ],
      ),
    );
  }
}

String _gridCellLabel(int column, int row) {
  var number = column + 1;
  var letters = '';
  while (number > 0) {
    number--;
    letters = String.fromCharCode(65 + number % 26) + letters;
    number ~/= 26;
  }
  return 'Клітинка $letters${row + 1}';
}

bool _hasCareFact(String value) {
  final normalized = value.trim().toLowerCase();
  return normalized.isNotEmpty &&
      normalized != 'не вказано' &&
      normalized != 'не застосовується' &&
      normalized != 'not applicable';
}

class _CarePlanIntroduction extends StatelessWidget {
  final String cropName;

  const _CarePlanIntroduction({required this.cropName});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('care-plan-$cropName'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.softGreen,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.route_rounded, color: AppColors.primary, size: 26),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Покроковий догляд: $cropName',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Відкривайте етапи по черзі. Спочатку перевірте стан '
                  'рослини й ґрунту, а потім виконуйте дію.',
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

class _CareStageSection extends StatelessWidget {
  final int number;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool initiallyExpanded;
  final List<Widget> children;

  const _CareStageSection({
    super.key,
    required this.number,
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
      margin: const EdgeInsets.only(bottom: 9),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(17),
      ),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.fromLTRB(11, 6, 11, 6),
        childrenPadding: const EdgeInsets.fromLTRB(11, 0, 11, 10),
        leading: Container(
          width: 41,
          height: 41,
          decoration: const BoxDecoration(
            color: AppColors.softGreen,
            shape: BoxShape.circle,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              Positioned(
                right: 0,
                bottom: 0,
                child: CircleAvatar(
                  radius: 8,
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        title: Text(
          '$number. $title',
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

class _CareExtraSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _CareExtraSection({
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
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(11, 0, 11, 10),
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

class _CareSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _CareSection({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 21, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(text, style: const TextStyle(height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RipenessPhoto extends StatelessWidget {
  final Crop crop;

  const _RipenessPhoto({required this.crop});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CropPhotoCatalog>(
      future: CropPhotoRepository.load(),
      builder: (context, snapshot) {
        final photo = snapshot.data?.records[crop.slug]?.ripeness;
        if (photo == null) return const SizedBox.shrink();
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.asset(
                  photo.assetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const Positioned(
                left: 9,
                bottom: 9,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xDDFFFFFF),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    child: Text(
                      'Фото ознак стиглості',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final PlantingStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Text(
        plantingStatusLabel(status),
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _GrowthTimingPanel extends StatelessWidget {
  final Planting planting;
  final DateTime? actualDate;
  final String stageLabel;
  final DateTime? plantingDate;
  final CropMaturityEstimate? estimate;
  final DateTime? targetDate;
  final DateTime? reminderDate;
  final String buttonLabel;
  final String missingDateText;
  final VoidCallback? onCreateReminder;

  const _GrowthTimingPanel({
    super.key,
    required this.planting,
    required this.actualDate,
    required this.stageLabel,
    required this.plantingDate,
    required this.estimate,
    required this.targetDate,
    required this.reminderDate,
    required this.buttonLabel,
    required this.missingDateText,
    required this.onCreateReminder,
  });

  @override
  Widget build(BuildContext context) {
    final currentEstimate = estimate;
    final startDate = plantingDate;
    final calculatedTarget = targetDate;
    final calculatedReminder = reminderDate;
    final canCalculate = currentEstimate != null &&
        startDate != null &&
        calculatedTarget != null &&
        calculatedReminder != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.softGreen,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.event_available_outlined,
                size: 21,
                color: AppColors.primary,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  stageLabel,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              _StatusBadge(status: planting.status),
            ],
          ),
          const SizedBox(height: 7),
          if (currentEstimate == null)
            const Text(
              'У базі немає строку в днях, тому дату неможливо '
              'розрахувати автоматично.',
              style: TextStyle(height: 1.35),
            )
          else if (startDate == null)
            Text(missingDateText, style: const TextStyle(height: 1.35))
          else if (canCalculate) ...[
            Text(
              'Записана дата: ${_formatCareDate(startDate)} '
              '(${currentEstimate.dateBasisLabel}).',
              style: const TextStyle(height: 1.35),
            ),
            const SizedBox(height: 3),
            Text(
              'Орієнтовне вікно: ${_formatMaturityWindow(startDate, currentEstimate)}.',
              style: const TextStyle(
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Прогнозна дата: '
              '${_formatCareDate(calculatedTarget)}.',
              style: const TextStyle(height: 1.35),
            ),
            const SizedBox(height: 3),
            Text(
              'Фактична дата: '
              '${actualDate == null ? 'ще не зафіксована' : _formatCareDate(actualDate!)}.',
              style: TextStyle(
                height: 1.35,
                fontWeight:
                    actualDate == null ? FontWeight.w400 : FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Дата орієнтовна: погода, ґрунт і стан рослини можуть '
              'змінити строк. Перед збором перевірте ознаки стиглості.',
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.35,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: canCalculate ? onCreateReminder : null,
              icon: const Icon(Icons.notifications_active_outlined),
              label: Text(
                canCalculate
                    ? '$buttonLabel • '
                        '${_reminderDateLabel(calculatedReminder)}'
                    : buttonLabel,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatMaturityWindow(
  DateTime plantingDate,
  CropMaturityEstimate estimate,
) {
  final start = plantingDate.add(Duration(days: estimate.earliestDays));
  final end = plantingDate.add(Duration(days: estimate.latestDays));
  if (_isSameCalendarDay(start, end)) return _formatCareDate(start);
  return '${_formatCareDate(start)}–${_formatCareDate(end)}';
}

String _reminderDateLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final planned = DateTime(date.year, date.month, date.day);
  return planned.isBefore(today) ? 'сьогодні' : _formatCareDate(planned);
}

String _formatCareDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}

bool _isSameCalendarDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;

class _ProtectionPlanSection extends StatelessWidget {
  final Crop crop;
  final PlantProtectionPlan plan;
  final Planting planting;
  final List<InventoryItem> seedPackages;
  final List<InventoryItem> protectionItems;

  const _ProtectionPlanSection({
    required this.crop,
    required this.plan,
    required this.planting,
    required this.seedPackages,
    required this.protectionItems,
  });

  @override
  Widget build(BuildContext context) {
    final varietyNames = <String>{
      if (planting.variety.trim().isNotEmpty) planting.variety.trim(),
      ...seedPackages
          .map((item) => item.varietyName.trim())
          .where((value) => value.isNotEmpty),
    };
    final packageNames = seedPackages
        .map(
          (item) => item.brand.isEmpty
              ? item.productName
              : '${item.productName} • ${item.brand}',
        )
        .toSet();

    return Container(
      key: ValueKey('protection-plan-${planting.id}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8F1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD7E6D1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.health_and_safety_outlined,
                size: 21,
                color: AppColors.primary,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'План захисту за етапами',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Що контролювати',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final risk in plan.risks)
                Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: const Icon(Icons.coronavirus_outlined, size: 16),
                  label: Text(risk),
                ),
            ],
          ),
          if (plan.diseases.isNotEmpty) ...[
            const SizedBox(height: 10),
            _ProtectionFact(
              icon: Icons.coronavirus_outlined,
              title: 'Хвороби',
              text: plan.diseases.join(', '),
            ),
          ],
          if (plan.pests.isNotEmpty) ...[
            const SizedBox(height: 8),
            _ProtectionFact(
              icon: Icons.bug_report_outlined,
              title: 'Шкідники',
              text: plan.pests.join(', '),
            ),
          ],
          if (plan.signs.isNotEmpty) ...[
            const SizedBox(height: 8),
            _ProtectionFact(
              icon: Icons.visibility_outlined,
              title: 'Ознаки',
              text: plan.signs.join('; '),
            ),
          ],
          if (plan.prevention.isNotEmpty) ...[
            const SizedBox(height: 8),
            _ProtectionFact(
              icon: Icons.health_and_safety_outlined,
              title: 'Профілактика',
              text: plan.prevention.join('; '),
            ),
          ],
          if (plan.allowedProductTypes.isNotEmpty) ...[
            const SizedBox(height: 8),
            _ProtectionFact(
              icon: Icons.science_outlined,
              title: 'Допустимий тип засобу',
              text: plan.allowedProductTypes
                  .map(plantProtectionCategoryLabel)
                  .join(', '),
            ),
          ],
          if (plan.safetyRules.isNotEmpty) ...[
            const SizedBox(height: 8),
            _ProtectionFact(
              icon: Icons.shield_outlined,
              title: 'Правила безпеки',
              text: plan.safetyRules.join('; '),
            ),
          ],
          if (varietyNames.isNotEmpty || packageNames.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Враховано сорт із ринку',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  if (varietyNames.isNotEmpty)
                    Text('Сорт / гібрид: ${varietyNames.join(', ')}'),
                  if (packageNames.isNotEmpty)
                    Text('Пакування: ${packageNames.join(', ')}'),
                  if (plan.varietyNote.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      plan.varietyNote,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          for (var index = 0; index < plan.steps.length; index++) ...[
            _ProtectionStepTile(
              step: plan.steps[index],
              number: index + 1,
            ),
            if (index != plan.steps.length - 1) const SizedBox(height: 8),
          ],
          if (protectionItems.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'У ваших запасах: '
              '${protectionItems.map((item) => item.productName).join(', ')}.',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 3),
            Text(
              'Це не означає автоматичну сумісність. На етикетці мають '
              'збігатися культура «${crop.name}», цільова хвороба, спосіб '
              'і строк застосування.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            for (final item in protectionItems) ...[
              const SizedBox(height: 7),
              _ProtectionProductDetails(item: item, crop: crop),
            ],
          ],
        ],
      ),
    );
  }
}

class _ProtectionFact extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _ProtectionFact({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 19),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                TextSpan(text: text),
              ],
            ),
            style: const TextStyle(height: 1.35),
          ),
        ),
      ],
    );
  }
}

class _ProtectionProductDetails extends StatelessWidget {
  final InventoryItem item;
  final Crop crop;

  const _ProtectionProductDetails({required this.item, required this.crop});

  @override
  Widget build(BuildContext context) {
    final isAllowed = item.allowedCropIds.isEmpty ||
        item.allowedCropIds.contains(crop.id) ||
        item.allowedCropIds.contains(crop.slug);
    final details = <String>[
      if (item.protectionCategory case final category?)
        plantProtectionCategoryLabel(category),
      if (item.activeIngredient.isNotEmpty)
        'діюча речовина: ${item.activeIngredient}',
      if (item.waitingPeriodDays != null)
        'строк очікування: ${item.waitingPeriodDays} дн.',
      if (item.maxApplications != null)
        'не більше ${item.maxApplications} застосувань',
      if (item.minimumTemperatureC != null || item.maximumTemperatureC != null)
        'температура: ${item.minimumTemperatureC?.toStringAsFixed(0) ?? '…'}–${item.maximumTemperatureC?.toStringAsFixed(0) ?? '…'} °C',
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isAllowed ? AppColors.softGreen : const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        '${item.productName}: '
        '${isAllowed ? (details.isEmpty ? 'звірте точні умови на етикетці' : details.join('; ')) : 'культура не зазначена у дозволеному списку — не застосовуйте без перевірки етикетки'}.',
        style: const TextStyle(height: 1.35),
      ),
    );
  }
}

class _ProtectionStepTile extends StatelessWidget {
  final ProtectionStep step;
  final int number;

  const _ProtectionStepTile({required this.step, required this.number});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          child: Text(
            '$number',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                protectionStageLabel(step.stage),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                step.title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(step.action, style: const TextStyle(height: 1.38)),
            ],
          ),
        ),
      ],
    );
  }
}

class _RotationExplainer extends StatelessWidget {
  final List<Planting> harvested;
  final Map<String, Crop> cropsById;
  final List<Crop> catalog;

  const _RotationExplainer({
    required this.harvested,
    required this.cropsById,
    required this.catalog,
  });

  @override
  Widget build(BuildContext context) {
    final recent = harvested.firstOrNull;
    final crop = recent?.cropId == null ? null : cropsById[recent!.cropId];
    final suggestions = crop == null
        ? const <Crop>[]
        : rotationSuggestionsFor(
            crop,
            catalog,
            afterHarvest: recent?.harvestedAt,
          );

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      color: const Color(0xFFFFF8E8),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFFFE0A3)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ExpansionTile(
        key: const Key('care-after-harvest'),
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: const Icon(
          Icons.change_circle_outlined,
          color: Color(0xFF9A6700),
        ),
        title: const Text(
          'Після збору врожаю',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          crop == null
              ? 'Як звільнити клітинку й змінити родину культур'
              : 'Що посадити після «${crop.name}»',
        ),
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Позначте посадку як зібрану — клітинка звільниться, а історія '
              'залишиться. На тому самому місці краще змінити родину культур.',
              style: TextStyle(height: 1.4),
            ),
          ),
          if (crop != null && suggestions.isNotEmpty) ...[
            const SizedBox(height: 10),
            _CareSection(
              icon: Icons.eco_outlined,
              title: 'Рекомендовані наступні культури',
              text: suggestions
                  .map(
                    (item) => '${item.name} (${seasonName(item.season)})',
                  )
                  .join(', '),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyCareCard extends StatelessWidget {
  const _EmptyCareCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.softGreen,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.touch_app_outlined, color: AppColors.primary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Спочатку додайте культуру на сітку. Тут з’являться конкретні поради щодо її поливу, догляду та добрив.',
              style: TextStyle(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyNote extends StatelessWidget {
  const _SafetyNote();

  @override
  Widget build(BuildContext context) {
    return const ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(Icons.info_outline_rounded, color: AppColors.primary),
      title: Text('Поради є орієнтиром'),
      subtitle: Text(
        'Враховуйте дощ, температуру, тип ґрунту та стан рослин. Для добрив і засобів захисту завжди дотримуйтеся етикетки.',
      ),
    );
  }
}
