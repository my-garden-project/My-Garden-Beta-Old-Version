import '../models.dart';

class PartnerFertilizer {
  final String id;
  final String name;
  final String brand;
  final String summary;
  final String instructions;
  final List<CropFamily> suitedFamilies;
  final String format;

  const PartnerFertilizer({
    required this.id,
    required this.name,
    required this.brand,
    required this.summary,
    required this.instructions,
    required this.suitedFamilies,
    required this.format,
  });
}

const partnerFertilizers = <PartnerFertilizer>[
  PartnerFertilizer(
    id: 'partner_bio_compost',
    name: 'BioStart Компост',
    brand: 'Демо-партнер GreenField',
    summary: 'Органічний покращувач ґрунту перед посадкою.',
    instructions:
        'Використовуйте лише за інструкцією виробника. Перед внесенням оцініть родючість і pH ґрунту; не змішуйте автоматично з іншими добривами.',
    suitedFamilies: [
      CropFamily.nightshade,
      CropFamily.cucurbit,
      CropFamily.brassica,
    ],
    format: 'Гранули • демонстраційний продукт',
  ),
  PartnerFertilizer(
    id: 'partner_leaf_balance',
    name: 'Leaf Balance',
    brand: 'Демо-партнер AgroNova',
    summary: 'Комплексне живлення для листових культур.',
    instructions:
        'Не перевищуйте норму з етикетки. Для їстівної зелені дотримуйтеся строку очікування і не вносьте азот «про запас».',
    suitedFamilies: [CropFamily.leafy, CropFamily.brassica],
    format: 'Рідкий концентрат • демонстраційний продукт',
  ),
  PartnerFertilizer(
    id: 'partner_root_support',
    name: 'Root Support PK',
    brand: 'Демо-партнер TerraLab',
    summary: 'Партнерська пропозиція для коренеплодів і цибулевих.',
    instructions:
        'Спочатку перевірте аналіз ґрунту. Не застосовуйте універсальну дозу без урахування культури, стадії росту та рекомендації виробника.',
    suitedFamilies: [CropFamily.apiaceae, CropFamily.allium],
    format: 'Водорозчинне • демонстраційний продукт',
  ),
];
