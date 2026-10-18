import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../app_theme.dart';
import '../calendar/lunar_phase.dart';
import '../models.dart';
import 'reminders_screen.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = InheritedAppState.of(context).state;
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final reminders = [...state.reminders]
          ..sort((a, b) => a.date.compareTo(b.date));
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Календар',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: [
              IconButton(
                tooltip: 'Усі нагадування',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RemindersScreen()),
                ),
                icon: const Icon(Icons.notifications_none_rounded),
              ),
            ],
          ),
          body: ListView(
            key: const PageStorageKey('calendar-list'),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _MonthCard(reminders: reminders),
              const SizedBox(height: 12),
              _LunarPhaseCard(date: DateTime.now()),
              const SizedBox(height: 20),
              Text(
                'Найближчі події',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              if (reminders.isEmpty)
                const _EmptyCalendar()
              else
                for (final reminder in reminders.take(8))
                  _CalendarEventTile(reminder: reminder),
            ],
          ),
        );
      },
    );
  }
}

class _LunarPhaseCard extends StatelessWidget {
  final DateTime date;

  const _LunarPhaseCard({required this.date});

  @override
  Widget build(BuildContext context) {
    final phase = LunarPhase.forDate(date);
    return Container(
      key: const Key('lunar-phase-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F2FA),
        border: Border.all(color: const Color(0xFFE2DDEF)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  phase.type.symbol,
                  style: const TextStyle(fontSize: 28),
                  semanticsLabel: phase.type.label,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Фаза Місяця сьогодні',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      phase.type.label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Орієнтовно освітлено ${phase.illuminationPercent}%',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Про місячний календар',
                onPressed: () => _showLunarCalendarInfo(context),
                icon: const Icon(Icons.info_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.science_outlined,
                color: AppColors.textSecondary,
                size: 19,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Довідково, не рекомендація для посіву. Фаза Місяця не '
                  'змінює дати посадки й догляду в застосунку.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.35,
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

void _showLunarCalendarInfo(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Як ми враховуємо Місяць',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Деякі досліди фіксують реакції окремих рослин на місячне '
              'світло або відмінності між строками посіву. Але результатів '
              'ще недостатньо, щоб місячний календар вважати надійним '
              'способом підвищення врожаю.',
              style: TextStyle(height: 1.45),
            ),
            const SizedBox(height: 12),
            const _LunarPriorityItem(
              icon: Icons.thermostat_rounded,
              text: 'Спочатку перевіряйте температуру ґрунту й заморозки.',
            ),
            const _LunarPriorityItem(
              icon: Icons.water_drop_outlined,
              text: 'Враховуйте вологість, погоду та потреби культури.',
            ),
            const _LunarPriorityItem(
              icon: Icons.eco_outlined,
              text: 'Фаза Місяця показана лише як традиційний орієнтир.',
            ),
            const SizedBox(height: 12),
            Text(
              'Дослідження',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.open_in_new_rounded),
              title: const Text('Ріст коренів і місячні цикли'),
              subtitle: const Text('Annals of Botany, 2012'),
              onTap: () => _openLunarSource(
                context,
                'https://pubmed.ncbi.nlm.nih.gov/22437666/',
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.open_in_new_rounded),
              title: const Text('Місячне світло й біоритм кави'),
              subtitle: const Text('BMC Plant Biology, 2020'),
              onTap: () => _openLunarSource(
                context,
                'https://doi.org/10.1186/s12870-020-2238-4',
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.open_in_new_rounded),
              title: const Text('Фази Місяця та проростання кукурудзи'),
              subtitle: const Text('Journal of Agricultural Science, 2021'),
              onTap: () => _openLunarSource(
                context,
                'https://doi.org/10.5539/jas.v13n3p61',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _LunarPriorityItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _LunarPriorityItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 9),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

Future<void> _openLunarSource(BuildContext context, String value) async {
  final opened = await launchUrl(
    Uri.parse(value),
    mode: LaunchMode.externalApplication,
  );
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Не вдалося відкрити дослідження.')),
    );
  }
}

class _MonthCard extends StatelessWidget {
  final List<Reminder> reminders;

  const _MonthCard({required this.reminders});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const monthNames = [
      'Січень',
      'Лютий',
      'Березень',
      'Квітень',
      'Травень',
      'Червень',
      'Липень',
      'Серпень',
      'Вересень',
      'Жовтень',
      'Листопад',
      'Грудень',
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.softGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${now.day}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${monthNames[now.month - 1]} ${now.year}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reminders.isEmpty
                      ? 'Запланованих подій поки немає'
                      : 'Заплановано подій: ${reminders.length}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarEventTile extends StatelessWidget {
  final Reminder reminder;

  const _CalendarEventTile({required this.reminder});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.softGreen,
          child: Icon(Icons.event_available_rounded, color: AppColors.primary),
        ),
        title: Text(
          reminder.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(_formatDateTime(reminder.date)),
      ),
    );
  }
}

class _EmptyCalendar extends StatelessWidget {
  const _EmptyCalendar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(Icons.event_note_outlined, size: 42, color: AppColors.primary),
          SizedBox(height: 10),
          Text(
            'Календар порожній',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 5),
          Text(
            'Додайте посадку або нагадування — подія з’явиться тут.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day.$month.${value.year} • $hour:$minute';
}
