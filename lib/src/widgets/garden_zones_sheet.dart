import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../app_theme.dart';
import '../models.dart';
import '../storage.dart';

Future<void> showGardenZonesSheet(
  BuildContext context, {
  required String gardenId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (_) => _GardenZonesSheet(gardenId: gardenId),
  );
}

class _GardenZonesSheet extends StatelessWidget {
  final String gardenId;

  const _GardenZonesSheet({required this.gardenId});

  @override
  Widget build(BuildContext context) {
    final state = InheritedAppState.of(context).state;
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final garden = state.gardens.firstWhere(
          (item) => item.id == gardenId,
        );
        return SafeArea(
          top: false,
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.76,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Сегменти ділянки',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Об’єднуйте клітинки в іменовані грядки, ряди, теплиці або доріжки.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: garden.zones.isEmpty
                      ? const _EmptyZones()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: garden.zones.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final zone = garden.zones[index];
                            return _ZoneTile(
                              garden: garden,
                              zone: zone,
                              onEdit: () => _showZoneDialog(
                                context,
                                state,
                                garden,
                                existing: zone,
                              ),
                              onDelete: () => _confirmDeleteZone(
                                context,
                                state,
                                garden,
                                zone,
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: FilledButton.icon(
                    key: const ValueKey('add-garden-zone'),
                    onPressed: garden.zones.length >= Garden.maxZoneCount
                        ? null
                        : () => _showZoneDialog(context, state, garden),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Додати сегмент'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ZoneTile extends StatelessWidget {
  final Garden garden;
  final GardenZone zone;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ZoneTile({
    required this.garden,
    required this.zone,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bounds = garden.zoneGridBounds(zone);
    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        key: ValueKey('garden-zone-${zone.id}'),
        contentPadding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Color(zone.colorValue),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            zone.canPlant ? Icons.grid_view_rounded : Icons.route_outlined,
            color: AppColors.darkGreen,
          ),
        ),
        title: Text(
          zone.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${gardenZoneTypeLabel(zone.type)} • '
          'ряди ${bounds.startRow + 1}–${bounds.endRow + 1}, '
          'стовпці ${bounds.startCol + 1}–${bounds.endCol + 1}',
        ),
        trailing: PopupMenuButton<String>(
          tooltip: 'Меню сегмента',
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
                value: 'edit', child: Text('Редагувати назву й межі')),
            PopupMenuItem(value: 'delete', child: Text('Видалити сегмент')),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }
}

class _EmptyZones extends StatelessWidget {
  const _EmptyZones();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dashboard_customize_outlined,
                size: 52, color: AppColors.primary),
            SizedBox(height: 12),
            Text(
              'Сегментів поки немає',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 6),
            Text(
              'Наприклад, створіть «Грядка з томатами» або «Доріжка».',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showZoneDialog(
  BuildContext context,
  AppState state,
  Garden garden, {
  GardenZone? existing,
}) async {
  final formKey = GlobalKey<FormState>();
  final existingBounds =
      existing == null ? null : garden.zoneGridBounds(existing);
  final nameController = TextEditingController(
    text: existing?.name ?? 'Сегмент ${garden.zones.length + 1}',
  );
  final startRowController = TextEditingController(
    text: '${(existingBounds?.startRow ?? 0) + 1}',
  );
  final endRowController = TextEditingController(
    text: '${(existingBounds?.endRow ?? 0) + 1}',
  );
  final startColController = TextEditingController(
    text: '${(existingBounds?.startCol ?? 0) + 1}',
  );
  final endColController = TextEditingController(
    text: '${(existingBounds?.endCol ?? 0) + 1}',
  );
  final noteController = TextEditingController(text: existing?.note ?? '');
  var type = existing?.type ?? GardenZoneType.bed;
  var canPlant = existing?.canPlant ?? true;
  var colorValue = existing?.colorValue ?? _zoneColors.first.$1;
  String? formError;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        scrollable: true,
        title: Text(existing == null ? 'Новий сегмент' : 'Редагувати сегмент'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Назва сегмента'),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(GardenZone.maxNameLength),
                ],
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Вкажіть назву'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<GardenZoneType>(
                initialValue: type,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Тип'),
                items: GardenZoneType.values
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(gardenZoneTypeLabel(item)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setDialogState(() {
                    type = value;
                    if (value == GardenZoneType.path) canPlant = false;
                  });
                },
              ),
              const SizedBox(height: 14),
              _RangeFields(
                firstLabel: 'Від рядка',
                lastLabel: 'До рядка',
                firstController: startRowController,
                lastController: endRowController,
                maximum: garden.rows,
              ),
              const SizedBox(height: 12),
              _RangeFields(
                firstLabel: 'Від стовпця',
                lastLabel: 'До стовпця',
                firstController: startColController,
                lastController: endColController,
                maximum: garden.cols,
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Колір на карті',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final color in _zoneColors)
                    ChoiceChip(
                      selected: colorValue == color.$1,
                      onSelected: (_) =>
                          setDialogState(() => colorValue = color.$1),
                      avatar: CircleAvatar(backgroundColor: Color(color.$1)),
                      label: Text(color.$2),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('У сегменті можна садити'),
                subtitle: const Text('Вимкніть для доріжки або технічної зони'),
                value: canPlant,
                onChanged: (value) => setDialogState(() => canPlant = value),
              ),
              TextFormField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Нотатка (необов’язково)',
                ),
                minLines: 2,
                maxLines: 3,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(GardenZone.maxNoteLength),
                ],
              ),
              if (formError != null) ...[
                const SizedBox(height: 10),
                Text(
                  formError!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Скасувати'),
          ),
          FilledButton(
            onPressed: () async {
              setDialogState(() => formError = null);
              if (formKey.currentState?.validate() != true) return;
              final startRow = int.parse(startRowController.text) - 1;
              final endRow = int.parse(endRowController.text) - 1;
              final startCol = int.parse(startColController.text) - 1;
              final endCol = int.parse(endColController.text) - 1;
              if (startRow > endRow || startCol > endCol) {
                setDialogState(
                  () => formError = 'Початок сегмента має бути перед кінцем.',
                );
                return;
              }
              try {
                final zone = garden.zoneFromGridRange(
                  id: existing?.id ?? generateId(),
                  name: nameController.text,
                  type: type,
                  startRow: startRow,
                  endRow: endRow,
                  startCol: startCol,
                  endCol: endCol,
                  colorValue: colorValue,
                  canPlant: canPlant,
                  note: noteController.text,
                );
                await state.saveGardenZone(gardenId: garden.id, zone: zone);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } on RangeError {
                setDialogState(
                  () => formError = 'Перевірте вказані рядки та стовпці.',
                );
              } on ArgumentError {
                setDialogState(
                  () => formError =
                      'Сегмент виходить за межі або накладається на інший.',
                );
              } on StorageWriteException {
                setDialogState(
                  () => formError = 'Не вдалося зберегти сегмент.',
                );
              }
            },
            child: const Text('Зберегти'),
          ),
        ],
      ),
    ),
  );
}

class _RangeFields extends StatelessWidget {
  final String firstLabel;
  final String lastLabel;
  final TextEditingController firstController;
  final TextEditingController lastController;
  final int maximum;

  const _RangeFields({
    required this.firstLabel,
    required this.lastLabel,
    required this.firstController,
    required this.lastController,
    required this.maximum,
  });

  @override
  Widget build(BuildContext context) {
    String? validate(String? value) {
      final number = int.tryParse(value ?? '');
      if (number == null) return 'Введіть число';
      if (number < 1 || number > maximum) return '1–$maximum';
      return null;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: firstController,
            decoration: InputDecoration(labelText: firstLabel),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: validate,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: lastController,
            decoration: InputDecoration(labelText: lastLabel),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: validate,
          ),
        ),
      ],
    );
  }
}

Future<void> _confirmDeleteZone(
  BuildContext context,
  AppState state,
  Garden garden,
  GardenZone zone,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Видалити сегмент?'),
      content: Text(
        '«${zone.name}» буде видалено. Посадки в його клітинках залишаться на сітці.',
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
    await state.deleteGardenZone(gardenId: garden.id, zoneId: zone.id);
  } on StorageWriteException {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Не вдалося видалити сегмент.')),
    );
  }
}

const _zoneColors = <(int, String)>[
  (0xFFB7D8A8, 'Зелений'),
  (0xFFD7EBC8, 'Світлий'),
  (0xFFFFD59A, 'Теплий'),
  (0xFFBFE0EE, 'Блакитний'),
  (0xFFD8C3B8, 'Земляний'),
];
