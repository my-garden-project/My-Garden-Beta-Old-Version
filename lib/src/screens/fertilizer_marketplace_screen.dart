import 'package:flutter/material.dart';

import '../app_state.dart';
import '../app_theme.dart';
import '../models.dart';
import '../monetization/partner_fertilizers.dart';
import '../storage.dart';

class FertilizerMarketplaceScreen extends StatelessWidget {
  const FertilizerMarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = InheritedAppState.of(context).state;
    final plantedCropIds = state.plantings
        .where((planting) => !planting.isHarvested)
        .map((planting) => planting.cropId)
        .whereType<String>()
        .toSet();
    final plantedFamilies = state.crops
        .where((crop) => plantedCropIds.contains(crop.id))
        .map((crop) => crop.family)
        .toSet();
    final recommended = partnerFertilizers.where(
      (product) =>
          plantedFamilies.isEmpty ||
          product.suitedFamilies.any(plantedFamilies.contains),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Добрива та партнери',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
        children: [
          const _AdvertisingPolicyCard(),
          const SizedBox(height: 20),
          Text(
            plantedFamilies.isEmpty
                ? 'Партнерські пропозиції'
                : 'Для ваших посаджених культур',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          for (final product in recommended)
            _PartnerProductCard(
              product: product,
              onInstructions: () => _showInstructions(context, product),
              onAdd: () => _addToInventory(context, state, product),
            ),
          const SizedBox(height: 16),
          const _PartnerCallout(),
        ],
      ),
    );
  }

  static Future<void> _addToInventory(
    BuildContext context,
    AppState state,
    PartnerFertilizer product,
  ) async {
    final exists = state.inventory.any(
      (item) =>
          item.type == InventoryItemType.fertilizer &&
          item.productName == product.name &&
          item.brand == product.brand,
    );
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Це добриво вже є у ваших запасах.')),
      );
      return;
    }
    try {
      await state.saveInventoryItem(
        InventoryItem(
          id: generateId(),
          type: InventoryItemType.fertilizer,
          productName: product.name,
          brand: product.brand,
          instructions: product.instructions,
          createdAt: DateTime.now(),
        ),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Додано до «Моїх запасів».')),
        );
      }
    } on StorageWriteException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не вдалося зберегти локальні дані.')),
        );
      }
    }
  }

  static void _showInstructions(
    BuildContext context,
    PartnerFertilizer product,
  ) {
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
              const _SponsoredBadge(),
              const SizedBox(height: 10),
              Text(
                product.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                product.brand,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              Text(product.instructions, style: const TextStyle(height: 1.45)),
              const SizedBox(height: 12),
              const Text(
                'Це демонстраційна рекламна пропозиція. Реального замовлення або оплати в застосунку немає.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdvertisingPolicyCard extends StatelessWidget {
  const _AdvertisingPolicyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE0A3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.campaign_outlined, color: AppColors.warning),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Платні розміщення завжди позначені. Партнерський продукт не підміняє аналіз ґрунту, етикетку виробника чи незалежну рекомендацію.',
              style: TextStyle(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _PartnerProductCard extends StatelessWidget {
  final PartnerFertilizer product;
  final VoidCallback onInstructions;
  final VoidCallback onAdd;

  const _PartnerProductCard({
    required this.product,
    required this.onInstructions,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 11),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.softGreen,
                  child: Icon(Icons.science_outlined, color: AppColors.primary),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SponsoredBadge(),
                      const SizedBox(height: 7),
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        product.brand,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(product.summary, style: const TextStyle(height: 1.4)),
            const SizedBox(height: 5),
            Text(
              product.format,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onInstructions,
                    child: const Text('Інструкція'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: onAdd,
                    child: const Text('У мої запаси'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SponsoredBadge extends StatelessWidget {
  const _SponsoredBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE8B2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Реклама • Партнерський матеріал',
        style: TextStyle(
          color: Color(0xFF8A5A00),
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _PartnerCallout extends StatelessWidget {
  const _PartnerCallout();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.darkGreen,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Icon(Icons.handshake_outlined, color: Colors.white),
          SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Місце для партнерів та інвесторів',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'У наступному етапі тут можна підключити кампанії, регіони показу, аналітику та партнерські посилання.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
