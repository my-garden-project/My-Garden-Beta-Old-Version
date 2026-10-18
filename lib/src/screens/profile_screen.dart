import 'package:flutter/material.dart';

import '../app_state.dart';
import '../app_theme.dart';
import '../feedback/feedback_mailer.dart';
import '../storage.dart';
import 'feedback_screen.dart';
import 'legal_screen.dart';

class ProfileScreen extends StatelessWidget {
  final bool adsRemoved;
  final ValueChanged<bool>? onAdsChanged;
  final VoidCallback? onShowTour;

  const ProfileScreen({
    super.key,
    this.adsRemoved = false,
    this.onAdsChanged,
    this.onShowTour,
  });

  @override
  Widget build(BuildContext context) {
    final state = InheritedAppState.of(context).state;
    final profileName =
        state.profileName.isEmpty ? 'Користувач' : state.profileName;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Профіль',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            key: const Key('open-feedback-appbar'),
            tooltip: 'Надіслати відгук',
            onPressed: () => _openFeedback(context),
            icon: const Icon(Icons.rate_review_outlined),
          ),
        ],
      ),
      body: ListView(
        key: const PageStorageKey('profile-list'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _ProfileHeader(
            name: profileName,
            onEdit: () => _editProfileName(context),
          ),
          const SizedBox(height: 12),
          _FeedbackCard(onTap: () => _openFeedback(context)),
          const SizedBox(height: 18),
          const _SettingsSection(
            title: 'Налаштування',
            items: [
              _SettingsItem(Icons.place_outlined, 'Регіон', 'Не вказано'),
              _SettingsItem(
                  Icons.straighten_outlined, 'Одиниці', 'м² / сотки / га'),
              _SettingsItem(Icons.language_outlined, 'Мова', 'Українська'),
              _SettingsItem(Icons.notifications_none_rounded, 'Сповіщення',
                  'Локальні нагадування'),
            ],
          ),
          const SizedBox(height: 14),
          const _AccessibilityCard(),
          const SizedBox(height: 14),
          _DataConsentCard(),
          const SizedBox(height: 14),
          _SettingsSection(
            title: 'Дані й підтримка',
            items: [
              const _SettingsItem(
                  Icons.cloud_off_outlined, 'Синхронізація', 'Premium • макет'),
              _SettingsItem(
                Icons.privacy_tip_outlined,
                'Приватність і фото',
                'Локальні дані • окремі згоди',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LegalScreen(
                      document: LegalDocument.privacy,
                    ),
                  ),
                ),
              ),
              _SettingsItem(
                Icons.gavel_outlined,
                'Правила користування',
                'Версія ${PrefsStorage.currentTermsVersion}',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LegalScreen(
                      document: LegalDocument.terms,
                    ),
                  ),
                ),
              ),
              _SettingsItem(
                Icons.help_outline_rounded,
                'Інтерактивна екскурсія',
                'Повторити підсвітку елементів',
                onTap: onShowTour,
              ),
              const _SettingsItem(Icons.info_outline_rounded, 'Про застосунок',
                  'Мій город 0.1.0'),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.darkGreen, AppColors.primary],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.workspace_premium_outlined,
                  color: Colors.white,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Мій город Premium',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Тестовий режим без реальної оплати. Партнерські матеріали залишаються позначеними, а мінібанер можна приховати.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  key: const Key('demo-premium-toggle'),
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: Colors.white,
                  activeTrackColor: Colors.white38,
                  title: const Text(
                    'Прибрати мінібанер',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    adsRemoved
                        ? 'Тестовий Premium увімкнено'
                        : 'Показується реклама',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  value: adsRemoved,
                  onChanged: onAdsChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final VoidCallback onEdit;

  const _ProfileHeader({required this.name, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.softGreen,
                child: Text(
                  name.characters.first.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 26,
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
                      name,
                      key: const Key('profile-display-name'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Локальний профіль • без авторизації',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('edit-profile-name'),
                tooltip: 'Змінити ім’я',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _editProfileName(BuildContext context) async {
  final state = InheritedAppState.of(context).state;
  final updatedName = await showDialog<String>(
    context: context,
    builder: (_) => _EditProfileNameDialog(
      initialName: state.profileName,
    ),
  );
  if (updatedName == null || !context.mounted) return;
  try {
    await state.setProfileName(updatedName);
  } on Object {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Не вдалося зберегти ім’я.')),
    );
  }
}

class _EditProfileNameDialog extends StatefulWidget {
  final String initialName;

  const _EditProfileNameDialog({required this.initialName});

  @override
  State<_EditProfileNameDialog> createState() => _EditProfileNameDialogState();
}

class _EditProfileNameDialogState extends State<_EditProfileNameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('edit-profile-name-dialog'),
      title: const Text('Змінити ім’я'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          key: const Key('edit-profile-name-field'),
          controller: _controller,
          autofocus: true,
          maxLength: 40,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(labelText: 'Ім’я або псевдонім'),
          validator: (value) {
            final normalized = value?.trim() ?? '';
            if (normalized.length < 2) return 'Введіть щонайменше 2 символи';
            return null;
          },
          onFieldSubmitted: (_) => _save(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Скасувати'),
        ),
        FilledButton(
          key: const Key('save-profile-name'),
          onPressed: _save,
          child: const Text('Зберегти'),
        ),
      ],
    );
  }
}

void _openFeedback(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const FeedbackScreen(
        initialKind: FeedbackKind.general,
      ),
    ),
  );
}

class _FeedbackCard extends StatelessWidget {
  final VoidCallback onTap;

  const _FeedbackCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: AppColors.softGreen,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        key: const Key('open-general-feedback'),
        contentPadding: const EdgeInsets.all(12),
        leading: const CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(Icons.rate_review_outlined, color: AppColors.primary),
        ),
        title: const Text(
          'Надіслати відгук',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: const Text(
          'Помилка, пропозиція або зміна каталогу',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;

  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        Material(
          color: AppColors.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                ListTile(
                  leading: Icon(items[index].icon, color: AppColors.primary),
                  title: Text(items[index].title),
                  subtitle: Text(items[index].value),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: items[index].onTap,
                ),
                if (index < items.length - 1)
                  const Divider(height: 1, indent: 56),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  const _SettingsItem(
    this.icon,
    this.title,
    this.value, {
    this.onTap,
  });
}

class _AccessibilityCard extends StatelessWidget {
  const _AccessibilityCard();

  @override
  Widget build(BuildContext context) {
    final state = InheritedAppState.of(context).state;
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) => Container(
        key: const Key('text-scale-settings'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.text_fields_rounded, color: AppColors.primary),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Розмір тексту',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Tooltip(
                  message: 'Збільшує текст у всьому застосунку та враховує '
                      'системні налаштування телефона.',
                  child: Icon(Icons.info_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<double>(
              segments: const [
                ButtonSegment(value: 1.0, label: Text('100%')),
                ButtonSegment(value: 1.25, label: Text('125%')),
                ButtonSegment(value: 1.5, label: Text('150%')),
              ],
              selected: {_nearestScale(state.textScale)},
              onSelectionChanged: (values) async {
                try {
                  await state.setTextScale(values.first);
                } on StorageWriteException {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Не вдалося зберегти розмір тексту.'),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 10),
            Text(
              'Приклад: нагадування про полив і захист',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

double _nearestScale(double value) {
  if (value >= 1.375) return 1.5;
  if (value >= 1.125) return 1.25;
  return 1.0;
}

class _DataConsentCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = InheritedAppState.of(context).state;
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) => Material(
        color: const Color(0xFFF4F8F1),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFD7E6D1)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.verified_user_outlined,
                    color: AppColors.primary),
                title: Text(
                  'Згоди на дані',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  'Фото щоденника залишаються локальними. Передавання на '
                  'сервер у цій версії ще не увімкнене.',
                ),
              ),
              SwitchListTile(
                key: const Key('profile-research-consent'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Навчання розумного асистента'),
                subtitle:
                    const Text('Лише записи, окремо позначені для обміну'),
                value: state.researchConsent,
                onChanged: (value) => _saveConsent(
                    context, () => state.setResearchConsent(value)),
              ),
              SwitchListTile(
                key: const Key('profile-photo-license'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Фото для каталогу росту'),
                subtitle: const Text(
                  'Невиключний дозвіл лише на вибрані користувачем фото',
                ),
                value: state.catalogPhotoLicense,
                onChanged: (value) => _saveConsent(
                  context,
                  () => state.setCatalogPhotoLicense(value),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveConsent(
    BuildContext context,
    Future<void> Function() save,
  ) async {
    try {
      await save();
    } on StorageWriteException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не вдалося зберегти вибір.')),
      );
    }
  }
}
