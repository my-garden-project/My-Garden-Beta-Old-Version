import 'package:flutter/material.dart';

import '../app_state.dart';
import '../app_theme.dart';
import '../models.dart';
import '../storage.dart';
import '../widgets/app_guide_sheet.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = InheritedAppState.of(context).state;

    return AnimatedBuilder(
      animation: state,
      builder: (_, __) {
        final items = [...state.reminders]
          ..sort((a, b) => a.date.compareTo(b.date));

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Нагадування',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            actions: [
              IconButton(
                tooltip: 'Як користуватися',
                onPressed: () => showAppGuide(context),
                icon: const Icon(Icons.help_outline_rounded),
              ),
            ],
          ),
          body: items.isEmpty
              ? const _EmptyReminders()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final r = items[i];
                    final g = state.gardens
                        .where((x) => x.id == r.gardenId)
                        .firstOrNull;
                    final c =
                        state.crops.where((x) => x.id == r.cropId).firstOrNull;

                    return Material(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.fromLTRB(14, 8, 8, 8),
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.softGreen,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(
                              Icons.notifications_active_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                          title: Text(
                            r.title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              '${_formatReminderDate(r.date)}'
                              '${g != null ? '\n${g.name}' : ''}'
                              '${c != null ? ' • ${c.name}' : ''}',
                              style: const TextStyle(height: 1.35),
                            ),
                          ),
                          trailing: IconButton(
                            tooltip: 'Видалити нагадування',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _confirmDelete(context, state, r),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppState state,
    Reminder reminder,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Видалити нагадування?'),
        content: Text('«${reminder.title}» буде видалено.'),
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
      await state.deleteReminder(reminder.id);
    } on StorageWriteException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не вдалося видалити нагадування.'),
          ),
        );
      }
    }
  }
}

class _EmptyReminders extends StatelessWidget {
  const _EmptyReminders();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                color: AppColors.softGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Нагадувань поки немає',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'У догляді за ділянкою можна запланувати полив, огляд, '
              'наближення дозрівання або збір урожаю.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Повернутися до ділянок'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatReminderDate(DateTime value) {
  final date = value.toLocal();
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day.$month.${date.year} • $hour:$minute';
}

extension FirstOrNullExt<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
