import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../catalog/crop_catalog.dart';
import '../catalog/crop_catalog_repository.dart';
import '../feedback/feedback_mailer.dart';
import 'crop_detail_screen.dart';
import 'feedback_screen.dart';

class CropCatalogScreen extends StatefulWidget {
  const CropCatalogScreen({super.key});

  @override
  State<CropCatalogScreen> createState() => _CropCatalogScreenState();
}

class _CropCatalogScreenState extends State<CropCatalogScreen> {
  late Future<CropCatalog> _catalogFuture;
  String _query = '';
  String _category = 'Усі';

  @override
  void initState() {
    super.initState();
    _catalogFuture = CropCatalogRepository.load();
  }

  void _retry() {
    setState(() => _catalogFuture = CropCatalogRepository.load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Каталог культур',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Запропонувати зміну списку',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FeedbackScreen(
                  initialKind: FeedbackKind.cropList,
                ),
              ),
            ),
            icon: const Icon(Icons.playlist_add_check_circle_outlined),
          ),
        ],
      ),
      body: FutureBuilder<CropCatalog>(
        future: _catalogFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _CatalogError(onRetry: _retry);
          }
          return _buildCatalog(context, snapshot.requireData);
        },
      ),
    );
  }

  Widget _buildCatalog(BuildContext context, CropCatalog catalog) {
    final categories = catalog.records
        .map((record) => cropCategoryLabel(record.category.text))
        .toSet()
        .toList()
      ..sort();
    final normalizedQuery = _query.trim().toLowerCase();
    final records = catalog.records.where((record) {
      final matchesQuery = normalizedQuery.isEmpty ||
          record.searchableText.contains(normalizedQuery);
      final matchesCategory = _category == 'Усі' ||
          cropCategoryLabel(record.category.text) == _category;
      return matchesQuery && matchesCategory;
    }).toList();

    return CustomScrollView(
      key: const PageStorageKey('crop-catalog-list'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          sliver: SliverToBoxAdapter(
            child: _CatalogSummary(catalog: catalog),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverToBoxAdapter(
            child: TextField(
              key: const Key('crop-catalog-search'),
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                labelText: 'Пошук культури',
                hintText: 'Українською, польською або латиною',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 58,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final category in ['Усі', ...categories])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(category),
                      selected: _category == category,
                      onSelected: (_) => setState(() => _category = category),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Знайдено: ${records.length}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        if (records.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptySearch(),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList.separated(
              itemCount: records.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _CropCatalogCard(entry: records[index]),
            ),
          ),
      ],
    );
  }
}

class _CatalogSummary extends StatelessWidget {
  final CropCatalog catalog;

  const _CatalogSummary({required this.catalog});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.softGreen,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${catalog.records.length} перевірених культур',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Посів, ґрунт, полив, добрива, сівозміна, хвороби та перевірені посилання.',
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.verified_outlined,
                size: 17,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Пакет ${catalog.batch} • перевірено ${catalog.checkedOn}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CropCatalogCard extends StatelessWidget {
  final CropCatalogEntry entry;

  const _CropCatalogCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CropDetailScreen(entry: entry),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.softGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.eco_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.nameUk.text,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.namePl.text} • ${entry.latinName.text}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _SmallTag(label: entry.familyUk.text),
                        _SmallTag(
                          label: cropCategoryLabel(entry.category.text),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallTag extends StatelessWidget {
  final String label;

  const _SmallTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 52, color: AppColors.primary),
            SizedBox(height: 12),
            Text(
              'Нічого не знайдено',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            SizedBox(height: 6),
            Text(
              'Спробуйте іншу назву або категорію.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogError extends StatelessWidget {
  final VoidCallback onRetry;

  const _CatalogError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 52, color: AppColors.error),
            const SizedBox(height: 12),
            const Text(
              'Не вдалося відкрити каталог',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Спробувати ще раз'),
            ),
          ],
        ),
      ),
    );
  }
}
