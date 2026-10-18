import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../app_theme.dart';
import '../models.dart';
import '../storage.dart';
import 'package_scanner_screen.dart';

class SuppliesScreen extends StatefulWidget {
  final InventoryItemType? initialFilter;

  const SuppliesScreen({super.key, this.initialFilter});

  @override
  State<SuppliesScreen> createState() => _SuppliesScreenState();
}

class _SuppliesScreenState extends State<SuppliesScreen> {
  InventoryItemType? _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    final state = InheritedAppState.of(context).state;
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final items = state.inventory
            .where((item) => _filter == null || item.type == _filter)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Мої запаси',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: [
              IconButton(
                tooltip: 'Додати вручну',
                onPressed: () => _showItemForm(state),
                icon: const Icon(Icons.add_box_outlined),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              _PlantedSummary(state: state),
              const SizedBox(height: 14),
              _ScannerCard(onScan: () => _scanPackage(state)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Усі'),
                    selected: _filter == null,
                    onSelected: (_) => setState(() => _filter = null),
                  ),
                  for (final type in InventoryItemType.values)
                    ChoiceChip(
                      label: Text(inventoryItemTypeLabel(type)),
                      selected: _filter == type,
                      onSelected: (_) => setState(() => _filter = type),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const _InventoryEmpty()
              else
                for (final item in items)
                  _InventoryCard(
                    item: item,
                    crop: item.cropId == null
                        ? null
                        : state.crops
                            .where((crop) => crop.id == item.cropId)
                            .firstOrNull,
                    plantedCount:
                        state.activePlantingCountForInventory(item.id),
                    onEdit: () => _showItemForm(state, existing: item),
                    onDelete: () => _confirmDelete(state, item),
                    onInstructions: () => _showInstructions(item),
                  ),
            ],
          ),
          floatingActionButton: MediaQuery.sizeOf(context).width < 390
              ? FloatingActionButton.small(
                  key: const Key('scan-package'),
                  tooltip: 'Сканувати паковання',
                  onPressed: () => _scanPackage(state),
                  child: const Icon(Icons.qr_code_scanner_rounded),
                )
              : FloatingActionButton.extended(
                  key: const Key('scan-package'),
                  onPressed: () => _scanPackage(state),
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Сканувати'),
                ),
        );
      },
    );
  }

  Future<void> _scanPackage(AppState state) async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const PackageScannerScreen()),
    );
    if (barcode == null || !mounted) return;
    final existing = state.inventoryByBarcode(barcode);
    if (existing != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Пакет «${existing.productName}» уже є.')),
      );
      await _showItemForm(state, existing: existing);
      return;
    }
    await _showItemForm(state, scannedBarcode: barcode);
  }

  Future<void> _showItemForm(
    AppState state, {
    InventoryItem? existing,
    String scannedBarcode = '',
  }) async {
    final formKey = GlobalKey<FormState>();
    var type = existing?.type ?? InventoryItemType.seeds;
    var cropId = existing?.cropId;
    final barcodeController = TextEditingController(
      text: existing?.barcode ?? scannedBarcode,
    );
    final nameController = TextEditingController(text: existing?.productName);
    final brandController = TextEditingController(text: existing?.brand);
    final varietyController = TextEditingController(
      text: existing?.varietyName,
    );
    final resistanceController = TextEditingController(
      text: existing?.resistanceClaims,
    );
    var varietyType = existing?.varietyType ?? SeedVarietyType.unknown;
    var maturityGroup = existing?.maturityGroup ?? SeedMaturityGroup.unknown;
    final quantityController = TextEditingController(
      text: _formatQuantity(existing?.quantity ?? 1),
    );
    final instructionsController = TextEditingController(
      text: existing?.instructions,
    );
    var unit = existing?.unit ?? 'пак.';
    final sortedCrops = [...state.crops]
      ..sort((a, b) => a.name.compareTo(b.name));

    final dialogRoute = DialogRoute<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          scrollable: true,
          title: Text(existing == null ? 'Додати до запасів' : 'Редагувати'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<InventoryItemType>(
                  segments: const [
                    ButtonSegment(
                      value: InventoryItemType.seeds,
                      icon: Icon(Icons.eco_outlined),
                      label: Text('Насіння'),
                    ),
                    ButtonSegment(
                      value: InventoryItemType.fertilizer,
                      icon: Icon(Icons.science_outlined),
                      label: Text('Добриво'),
                    ),
                    ButtonSegment(
                      value: InventoryItemType.plantProtection,
                      icon: Icon(Icons.health_and_safety_outlined),
                      label: Text('Захист'),
                    ),
                  ],
                  showSelectedIcon: false,
                  selected: {type},
                  onSelectionChanged: (values) {
                    setDialogState(() {
                      type = values.first;
                      if (type != InventoryItemType.seeds) cropId = null;
                    });
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const Key('inventory-product-name'),
                  controller: nameController,
                  maxLength: InventoryItem.maxProductNameLength,
                  decoration:
                      const InputDecoration(labelText: 'Назва продукту'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Вкажіть назву'
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: brandController,
                  maxLength: InventoryItem.maxBrandLength,
                  decoration: const InputDecoration(
                    labelText: 'Бренд (необов’язково)',
                  ),
                ),
                if (type == InventoryItemType.seeds) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    key: const Key('inventory-crop'),
                    initialValue: cropId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Культура'),
                    items: sortedCrops
                        .map(
                          (crop) => DropdownMenuItem(
                            value: crop.id,
                            child: Text(crop.name),
                          ),
                        )
                        .toList(),
                    validator: (value) =>
                        value == null ? 'Оберіть культуру з каталогу' : null,
                    onChanged: (value) {
                      setDialogState(() => cropId = value);
                      if (instructionsController.text.trim().isEmpty &&
                          value != null) {
                        final crop = state.crops.firstWhere(
                          (item) => item.id == value,
                        );
                        instructionsController.text = crop.recommendation;
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: const Key('inventory-variety-name'),
                    controller: varietyController,
                    maxLength: InventoryItem.maxVarietyNameLength,
                    decoration: const InputDecoration(
                      labelText: 'Сорт або гібрид із пакування',
                      hintText: 'Наприклад, Белфаст F1',
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<SeedVarietyType>(
                    initialValue: varietyType,
                    decoration: const InputDecoration(
                      labelText: 'Тип насіння',
                    ),
                    items: SeedVarietyType.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(seedVarietyTypeLabel(value)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setDialogState(
                      () => varietyType = value ?? SeedVarietyType.unknown,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<SeedMaturityGroup>(
                    initialValue: maturityGroup,
                    decoration: const InputDecoration(
                      labelText: 'Строк достигання',
                    ),
                    items: SeedMaturityGroup.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(seedMaturityGroupLabel(value)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setDialogState(
                      () => maturityGroup = value ?? SeedMaturityGroup.unknown,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: const Key('inventory-resistance-claims'),
                    controller: resistanceController,
                    maxLength: InventoryItem.maxResistanceClaimsLength,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Стійкість, заявлена на пакуванні',
                      hintText: 'Наприклад: фітофтороз — середня стійкість',
                      helperText:
                          'Перенесіть формулювання дослівно з етикетки.',
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                TextFormField(
                  controller: barcodeController,
                  inputFormatters: [LengthLimitingTextInputFormatter(64)],
                  decoration: const InputDecoration(
                    labelText: 'Штрихкод / QR (необов’язково)',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: quantityController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration:
                            const InputDecoration(labelText: 'Кількість'),
                        validator: (value) {
                          final parsed = double.tryParse(
                            (value ?? '').replaceAll(',', '.'),
                          );
                          return parsed == null || parsed < 0
                              ? 'Невірне число'
                              : null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: unit,
                        decoration: const InputDecoration(labelText: 'Одиниця'),
                        items: const ['пак.', 'г', 'кг', 'мл', 'л']
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setDialogState(() => unit = value ?? unit),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: instructionsController,
                  maxLength: InventoryItem.maxInstructionsLength,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Інструкція або нотатка',
                    hintText:
                        'Дозування, строк очікування, спосіб застосування…',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Скасувати'),
            ),
            FilledButton(
              key: const Key('save-inventory-item'),
              onPressed: () async {
                if (formKey.currentState?.validate() != true) return;
                final item = InventoryItem(
                  id: existing?.id ?? generateId(),
                  type: type,
                  barcode: barcodeController.text.trim(),
                  productName: nameController.text.trim(),
                  brand: brandController.text.trim(),
                  cropId: type == InventoryItemType.seeds ? cropId : null,
                  varietyName: type == InventoryItemType.seeds
                      ? varietyController.text.trim()
                      : '',
                  varietyType: type == InventoryItemType.seeds
                      ? varietyType
                      : SeedVarietyType.unknown,
                  maturityGroup: type == InventoryItemType.seeds
                      ? maturityGroup
                      : SeedMaturityGroup.unknown,
                  resistanceClaims: type == InventoryItemType.seeds
                      ? resistanceController.text.trim()
                      : '',
                  quantity: double.parse(
                    quantityController.text.replaceAll(',', '.'),
                  ),
                  unit: unit,
                  instructions: instructionsController.text.trim(),
                  createdAt: existing?.createdAt ?? DateTime.now(),
                );
                try {
                  await state.saveInventoryItem(item);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } on ArgumentError {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('Цей штрихкод уже додано.'),
                      ),
                    );
                  }
                } on StorageWriteException {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('Не вдалося зберегти локальні дані.'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Зберегти'),
            ),
          ],
        ),
      ),
    );
    await Navigator.of(context, rootNavigator: true).push(dialogRoute);
    await dialogRoute.completed;

    barcodeController.dispose();
    nameController.dispose();
    brandController.dispose();
    varietyController.dispose();
    resistanceController.dispose();
    quantityController.dispose();
    instructionsController.dispose();
  }

  Future<void> _confirmDelete(AppState state, InventoryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Видалити із запасів?'),
        content: Text(
          '«${item.productName}» буде видалено. Уже створені посадки залишаться, але зв’язок із пакетом зникне.',
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
    if (confirmed == true) await state.deleteInventoryItem(item.id);
  }

  void _showInstructions(InventoryItem item) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                item.instructions.isEmpty
                    ? 'Інструкцію ще не додано. Відредагуйте запис і перенесіть основні вказівки з етикетки.'
                    : item.instructions,
                style: const TextStyle(height: 1.45),
              ),
              if (item.type == InventoryItemType.seeds &&
                  (item.varietyName.isNotEmpty ||
                      item.varietyType != SeedVarietyType.unknown ||
                      item.maturityGroup != SeedMaturityGroup.unknown ||
                      item.resistanceClaims.isNotEmpty)) ...[
                const SizedBox(height: 14),
                const Text(
                  'Профіль сорту з пакування',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  [
                    if (item.varietyName.isNotEmpty) item.varietyName,
                    if (item.varietyType != SeedVarietyType.unknown)
                      seedVarietyTypeLabel(item.varietyType),
                    if (item.maturityGroup != SeedMaturityGroup.unknown)
                      '${seedMaturityGroupLabel(item.maturityGroup)} строк',
                    if (item.resistanceClaims.isNotEmpty)
                      'Заявлена стійкість: ${item.resistanceClaims}',
                  ].join('\n'),
                  style: const TextStyle(height: 1.45),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Заявлена стійкість зменшує ризик лише для вказаної '
                  'хвороби й не скасовує регулярний огляд.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
              if (item.type != InventoryItemType.seeds) ...[
                const SizedBox(height: 14),
                Text(
                  item.type == InventoryItemType.plantProtection
                      ? 'Застосовуйте лише дозволений для вашої культури засіб. Звіряйте дозу, захисний одяг, кількість обробок і строк очікування з оригінальною етикеткою.'
                      : 'Для добрив завжди звіряйте дозування та спосіб внесення з оригінальною етикеткою.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PlantedSummary extends StatelessWidget {
  final AppState state;

  const _PlantedSummary({required this.state});

  @override
  Widget build(BuildContext context) {
    final active = state.plantings.where((item) => !item.isHarvested);
    final counts = <String, int>{};
    for (final planting in active) {
      final cropId = planting.cropId;
      if (cropId != null) counts[cropId] = (counts[cropId] ?? 0) + 1;
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.softGreen,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.yard_rounded, color: AppColors.primary),
              SizedBox(width: 9),
              Text(
                'Що зараз посаджено',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (counts.isEmpty)
            const Text(
              'Активних посадок поки немає.',
              style: TextStyle(color: AppColors.textSecondary),
            )
          else
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final entry in counts.entries)
                  Chip(
                    avatar: const Icon(Icons.eco_outlined, size: 17),
                    label: Text(
                      '${state.crops.firstWhere((crop) => crop.id == entry.key).name} • ${entry.value}',
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ScannerCard extends StatelessWidget {
  final VoidCallback onScan;

  const _ScannerCard({required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: const CircleAvatar(
          backgroundColor: AppColors.softGreen,
          child: Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
        ),
        title: const Text(
          'Скануйте пакетики',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: const Text(
          'Насіння, добриво або захист • код зберігається локально',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onScan,
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final InventoryItem item;
  final Crop? crop;
  final int plantedCount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onInstructions;

  const _InventoryCard({
    required this.item,
    required this.crop,
    required this.plantedCount,
    required this.onEdit,
    required this.onDelete,
    required this.onInstructions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.softGreen,
                  child: Icon(
                    _inventoryIcon(item.type),
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        [
                          if (item.brand.isNotEmpty) item.brand,
                          inventoryItemTypeLabel(item.type),
                          if (crop != null) crop!.name,
                        ].join(' • '),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Редагувати')),
                    PopupMenuItem(value: 'delete', child: Text('Видалити')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Chip(
                    label:
                        Text('${_formatQuantity(item.quantity)} ${item.unit}')),
                if (item.type == InventoryItemType.seeds)
                  Chip(
                    avatar: Icon(
                      plantedCount > 0
                          ? Icons.check_circle_outline
                          : Icons.inventory_2_outlined,
                      size: 17,
                    ),
                    label: Text(
                      plantedCount > 0
                          ? 'Посаджено: $plantedCount'
                          : 'Є в запасі',
                    ),
                  ),
                if (item.varietyName.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.label_outline, size: 17),
                    label: Text(item.varietyName),
                  ),
                if (item.maturityGroup != SeedMaturityGroup.unknown)
                  Chip(
                    label: Text(
                      '${seedMaturityGroupLabel(item.maturityGroup)} строк',
                    ),
                  ),
                if (item.barcode.isNotEmpty)
                  Chip(label: Text('Код ${item.barcode}')),
              ],
            ),
            const SizedBox(height: 7),
            TextButton.icon(
              onPressed: onInstructions,
              icon: const Icon(Icons.description_outlined),
              label: const Text('Інструкція'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryEmpty extends StatelessWidget {
  const _InventoryEmpty();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 34),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 52, color: AppColors.primary),
          SizedBox(height: 12),
          Text(
            'Запасів поки немає',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          SizedBox(height: 6),
          Text(
            'Скануйте насіння, добриво або засіб захисту чи додайте його вручну.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

String _formatQuantity(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');

IconData _inventoryIcon(InventoryItemType type) => switch (type) {
      InventoryItemType.seeds => Icons.eco_outlined,
      InventoryItemType.fertilizer => Icons.science_outlined,
      InventoryItemType.plantProtection => Icons.health_and_safety_outlined,
    };
