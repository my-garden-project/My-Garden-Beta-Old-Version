import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../storage.dart';

enum LegalDocument { terms, privacy }

class ConsentScreen extends StatefulWidget {
  final Future<bool> Function({
    required bool researchConsent,
    required bool catalogPhotoLicense,
  }) onAccepted;

  const ConsentScreen({super.key, required this.onAccepted});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _acceptedRules = false;
  bool _researchConsent = false;
  bool _catalogPhotoLicense = false;
  bool _saving = false;

  Future<void> _continue() async {
    if (!_acceptedRules || _saving) return;
    setState(() => _saving = true);
    final saved = await widget.onAccepted(
      researchConsent: _researchConsent,
      catalogPhotoLicense: _catalogPhotoLicense,
    );
    if (!mounted || saved) return;
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                children: [
                  const _ConsentLogo(),
                  const SizedBox(height: 16),
                  Text(
                    'Перед початком',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Правила користування є обов’язковими. Передавання відгуків '
                    'і фото для розвитку каталогу чи розумного асистента — '
                    'окремий добровільний вибір.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _ConsentOption(
                    key: const Key('accept-required-terms'),
                    value: _acceptedRules,
                    requiredOption: true,
                    title: 'Приймаю правила користування',
                    description:
                        'Не додаю чужих фото, небезпечних порад, спаму або '
                        'незаконного вмісту. Розумію, що агрономічні підказки не '
                        'замінюють етикетку препарату та консультацію фахівця.',
                    onChanged: (value) =>
                        setState(() => _acceptedRules = value),
                  ),
                  const SizedBox(height: 10),
                  _ConsentOption(
                    key: const Key('research-consent'),
                    value: _researchConsent,
                    title: 'Допомагати навчанню асистента',
                    description:
                        'Дозволяю використовувати лише ті відгуки та записи '
                        'щоденника, які я окремо позначу для передавання. Локальні '
                        'фото без цієї позначки не передаються.',
                    onChanged: (value) =>
                        setState(() => _researchConsent = value),
                  ),
                  const SizedBox(height: 10),
                  _ConsentOption(
                    key: const Key('catalog-photo-license'),
                    value: _catalogPhotoLicense,
                    title: 'Ділитися вибраними фото з каталогом',
                    description:
                        'Підтверджую, що маю права на вибрані фото, і надаю '
                        'невиключний дозвіл використовувати їх у каталозі етапів '
                        'росту. Авторське право залишається моїм.',
                    onChanged: (value) =>
                        setState(() => _catalogPhotoLicense = value),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () =>
                            _openLegal(context, LegalDocument.terms),
                        child: const Text('Правила'),
                      ),
                      TextButton(
                        onPressed: () =>
                            _openLegal(context, LegalDocument.privacy),
                        child: const Text('Приватність і фото'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const Key('continue-after-consent'),
                        onPressed:
                            _acceptedRules && !_saving ? _continue : null,
                        icon: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.arrow_forward_rounded),
                        label: Text(
                          _acceptedRules
                              ? 'Продовжити'
                              : 'Спочатку прийміть правила',
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Згоди на дані можна змінити у профілі • '
                      '${PrefsStorage.currentTermsVersion}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsentLogo extends StatelessWidget {
  const _ConsentLogo();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: AppColors.softGreen,
          child: Icon(Icons.energy_savings_leaf,
              size: 42, color: AppColors.primary),
        ),
        SizedBox(height: 10),
        Text(
          'Мій город',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
        ),
      ],
    );
  }
}

class _ConsentOption extends StatelessWidget {
  final bool value;
  final bool requiredOption;
  final String title;
  final String description;
  final ValueChanged<bool> onChanged;

  const _ConsentOption({
    super.key,
    required this.value,
    this.requiredOption = false,
    required this.title,
    required this.description,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: value ? AppColors.softGreen : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: value ? AppColors.primary : AppColors.border,
        ),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: (next) => onChanged(next ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
        title: Text(
          '$title${requiredOption ? ' • обов’язково' : ' • добровільно'}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(description, style: const TextStyle(height: 1.35)),
        ),
      ),
    );
  }
}

class LegalScreen extends StatelessWidget {
  final LegalDocument document;

  const LegalScreen({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    final isTerms = document == LegalDocument.terms;
    final sections = isTerms ? _termsSections : _privacySections;
    return Scaffold(
      appBar: AppBar(
        title: Text(isTerms ? 'Правила користування' : 'Приватність і фото'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.softGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Тестова редакція • ${PrefsStorage.currentTermsVersion}\n'
              'Контакт: marynnnaa01@gmail.com',
              style: TextStyle(fontWeight: FontWeight.w700, height: 1.4),
            ),
          ),
          const SizedBox(height: 18),
          for (final section in sections) ...[
            Text(
              section.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(section.body, style: const TextStyle(height: 1.5)),
            const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }
}

void _openLegal(BuildContext context, LegalDocument document) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => LegalScreen(document: document)),
  );
}

const _termsSections = [
  _LegalSection(
    '1. Призначення тестової версії',
    '«Мій город» допомагає планувати ділянки, догляд і вести щоденник. '
        'Підказки є довідковими. Для добрив і засобів захисту визначальною '
        'є чинна етикетка продукту, місцева реєстрація та порада агронома.',
  ),
  _LegalSection(
    '2. Правила користувача',
    'Заборонено додавати чужі фото без дозволу, незаконний або образливий '
        'вміст, спам, шкідливі інструкції, навмисно неправдиві агрономічні '
        'дані чи намагатися порушити роботу застосунку.',
  ),
  _LegalSection(
    '3. Обмеження доступу',
    'Після появи реєстрації та серверної модерації доступ може бути '
        'тимчасово обмежений або припинений за суттєві чи повторні порушення '
        'після перевірки. У поточній локальній версії дистанційного '
        'блокування облікового запису ще немає.',
  ),
  _LegalSection(
    '4. Авторські права',
    'Користувач зберігає авторське право на свої фото. Позначення фото для '
        'каталогу є окремим добровільним дозволом, а не переданням авторства. '
        'Користувач підтверджує, що зробив фото сам або має необхідний дозвіл.',
  ),
];

const _privacySections = [
  _LegalSection(
    '1. Що зберігається зараз',
    'Ім’я локального профілю, ділянки, посадки, нагадування, записи '
        'щоденника і фото зберігаються '
        'локально на пристрої. Відгук відкривається у поштовій програмі й '
        'надсилається лише після підтвердження користувача.',
  ),
  _LegalSection(
    '2. Фото для каталогу та навчання',
    'Локальне фото не передається автоматично. Для майбутнього передавання '
        'потрібні: активна добровільна згода та окрема позначка конкретного '
        'запису щоденника. До підключення сервера ця позначка лише зберігає '
        'намір користувача на пристрої.',
  ),
  _LegalSection(
    '3. Відкликання згоди',
    'Згоду на навчання або каталог можна вимкнути у профілі. Це припиняє '
        'майбутнє передавання. Для видалення вже надісланих матеріалів '
        'користувач зможе звернутися на контактну адресу із зазначенням '
        'ідентифікатора матеріалу після запуску серверного сховища.',
  ),
  _LegalSection(
    '4. Публікація застосунку',
    'Перед публічним запуском власник продукту має доповнити політику '
        'юридичною назвою оператора, адресою, строками зберігання, '
        'постачальниками серверів і процедурою видалення даних.',
  ),
];

class _LegalSection {
  final String title;
  final String body;

  const _LegalSection(this.title, this.body);
}
