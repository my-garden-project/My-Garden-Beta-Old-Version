import 'package:flutter/material.dart';

import '../app_theme.dart';

Future<void> showAppGuide(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.softGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.eco, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Як користуватися',
                        style: Theme.of(sheetContext)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const Text(
                        'Від розміру ділянки до сівозміни',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const _GuideStep(
              number: 1,
              icon: Icons.add_box_outlined,
              title: 'Створіть ділянку',
              description:
                  'Оберіть площу в м², сотках чи гектарах або вкажіть сторони. Назву, розмір, ґрунт та інші дані потім можна змінити кнопкою з олівцем.',
            ),
            const _GuideStep(
              number: 2,
              icon: Icons.grid_view_outlined,
              title: 'Поділіть сітку на сегменти',
              description:
                  'Відкрийте «Сегменти», об’єднайте потрібні рядки й стовпці та дайте їм зрозумілі назви: наприклад, «Томати», «Теплиця» або «Доріжка».',
            ),
            const _GuideStep(
              number: 3,
              icon: Icons.touch_app_outlined,
              title: 'Оберіть клітинку',
              description:
                  'Натисніть на клітинку схеми, де хочете додати або змінити посадку.',
            ),
            const _GuideStep(
              number: 4,
              icon: Icons.spa_outlined,
              title: 'Додайте посадку',
              description:
                  'Оберіть культуру, сорт, дату й за бажанням залиште нотатку. Щоб швидко заповнити кілька клітинок, затисніть готову посадку та протягніть її до потрібної клітинки.',
            ),
            const _GuideStep(
              number: 5,
              icon: Icons.notifications_active_outlined,
              title: 'Не забудьте про догляд',
              description:
                  'Відкрийте «Полив, догляд, захист і добрива»: там є поради для ваших культур, наявні засоби та швидкі нагадування.',
            ),
            const _GuideStep(
              number: 6,
              icon: Icons.change_circle_outlined,
              title: 'Позначте збір урожаю',
              description:
                  'У картці посадки натисніть «Зібрати врожай». Історія збережеться, а застосунок підкаже іншу родину культур для сівозміни.',
            ),
            const _GuideStep(
              number: 7,
              icon: Icons.add_a_photo_outlined,
              title: 'Фіксуйте ріст у щоденнику',
              description:
                  'На екрані ділянки відкрийте «Щоденник росту й врожаю». Додайте фото сходів, росту, пошкодження, обробки або врожаю та прив’яжіть його до культури й клітинки.',
              isLast: true,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(sheetContext),
              child: const Text('Зрозуміло'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _GuideStep extends StatelessWidget {
  final int number;
  final IconData icon;
  final String title;
  final String description;
  final bool isLast;

  const _GuideStep({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: AppColors.border),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          description,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
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
