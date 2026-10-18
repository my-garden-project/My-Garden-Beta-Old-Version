import 'package:flutter/material.dart';

import '../app_state.dart';
import '../app_theme.dart';
import '../catalog/crop_catalog.dart';
import '../catalog/crop_catalog_repository.dart';
import '../models.dart';
import 'care_recommendations_screen.dart';
import 'crop_catalog_screen.dart';
import 'fertilizer_marketplace_screen.dart';
import 'supplies_screen.dart';

class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = InheritedAppState.of(context).state;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Рекомендації',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        key: const PageStorageKey('recommendations-list'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const _MockWeatherCard(),
          const SizedBox(height: 12),
          const _CatalogCard(),
          const SizedBox(height: 10),
          _FeatureLinkCard(
            key: const Key('open-supplies'),
            icon: Icons.qr_code_scanner_rounded,
            title: 'Мої запаси та сканер',
            subtitle: 'Насіння, добрива, засоби захисту й посаджені культури',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SuppliesScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _FeatureLinkCard(
            key: const Key('open-plant-protection'),
            icon: Icons.health_and_safety_outlined,
            title: 'Засоби захисту рослин',
            subtitle: 'Ваші препарати, інструкції та строки очікування',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SuppliesScreen(
                  initialFilter: InventoryItemType.plantProtection,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _FeatureLinkCard(
            key: const Key('open-partner-fertilizers'),
            icon: Icons.science_outlined,
            title: 'Добрива та партнери',
            subtitle: 'Поради й чітко позначені рекламні пропозиції',
            sponsored: true,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FertilizerMarketplaceScreen(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Сьогодні',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          const _RecommendationCard(
            icon: Icons.water_drop_outlined,
            title: 'Перевірте вологість ґрунту',
            description:
                'Поливайте лише за потреби, враховуючи опади та стан верхнього шару ґрунту.',
            color: AppColors.info,
          ),
          const _RecommendationCard(
            icon: Icons.eco_outlined,
            title: 'Огляньте молоді рослини',
            description:
                'Перевірте листя на ознаки стресу й шкідників до вечірнього поливу.',
            color: AppColors.primary,
          ),
          if (state.gardens.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'За ділянками',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            for (final garden in state.gardens)
              Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: AppColors.border),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.softGreen,
                    child: Icon(Icons.yard_rounded, color: AppColors.primary),
                  ),
                  title: Text(
                    garden.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text('Сегментів: ${garden.zones.length}'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CareRecommendationsScreen(gardenId: garden.id),
                    ),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 8),
          const _PremiumPreview(),
        ],
      ),
    );
  }
}

class _FeatureLinkCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool sponsored;
  final VoidCallback onTap;

  const _FeatureLinkCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.sponsored = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: sponsored ? const Color(0xFFFFD481) : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor:
              sponsored ? const Color(0xFFFFF3D8) : AppColors.softGreen,
          child: Icon(
            icon,
            color: sponsored ? const Color(0xFF9A6700) : AppColors.primary,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(
          sponsored ? 'Реклама • $subtitle' : subtitle,
          style: const TextStyle(height: 1.3),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  const _CatalogCard();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CropCatalog>(
      future: CropCatalogRepository.load(),
      builder: (context, snapshot) {
        final count = snapshot.data?.records.length ?? 50;
        return Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: AppColors.softGreen,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: InkWell(
            key: const Key('open-crop-catalog'),
            borderRadius: BorderRadius.circular(18),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CropCatalogScreen()),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Каталог культур',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$count культур • догляд, сівозміна, Вікіпедія та джерела',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MockWeatherCard extends StatelessWidget {
  const _MockWeatherCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE7F3FA), Color(0xFFF7FBFD)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD5E8F3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.cloud_outlined, size: 46, color: AppColors.info),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '+22°C • мінлива хмарність',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                ),
                SizedBox(height: 4),
                Text(
                  'Демонстраційний прогноз • без онлайн-оновлення погоди',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _RecommendationCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 5),
                  Text(description, style: const TextStyle(height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumPreview extends StatelessWidget {
  const _PremiumPreview();

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
          Icon(Icons.lock_outline_rounded, color: AppColors.warning),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Детальний прогноз • Premium',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 4),
                Text(
                  'Інформаційний preview. Реальна оплата та погодний API не підключені.',
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
