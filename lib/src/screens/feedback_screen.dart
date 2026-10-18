import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_theme.dart';
import '../feedback/feedback_mailer.dart';

class FeedbackScreen extends StatefulWidget {
  final FeedbackKind initialKind;
  final String cropName;
  final String cropSlug;

  const FeedbackScreen({
    super.key,
    this.initialKind = FeedbackKind.general,
    this.cropName = '',
    this.cropSlug = '',
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _replyEmailController = TextEditingController();
  late FeedbackKind _kind;
  String _section = 'Загальний опис';
  bool _sending = false;

  static const _cropSections = [
    'Загальний опис',
    'Назва або класифікація',
    'Посів і висаджування',
    'Полив і догляд',
    'Добрива',
    'Захист рослин',
    'Сівозміна та попередники',
    'Фото культури',
    'Інше',
  ];

  @override
  void initState() {
    super.initState();
    _kind = widget.initialKind;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _replyEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Надіслати відгук',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.softGreen,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.mark_email_unread_outlined,
                    color: AppColors.primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ми підготуємо лист у вашій поштовій програмі. Перевірте його та натисніть «Надіслати». Зміни каталогу спочатку перевіряє команда.',
                    style: TextStyle(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          if (feedbackRecipient.isEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFE0A3)),
              ),
              child: const Text(
                'Адресу команди ще не налаштовано. Лист відкриється без одержувача — його потрібно буде вказати вручну.',
                style: TextStyle(height: 1.35),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<FeedbackKind>(
                  key: const Key('feedback-kind'),
                  initialValue: _kind,
                  decoration: const InputDecoration(labelText: 'Тип відгуку'),
                  items: FeedbackKind.values
                      .map(
                        (kind) => DropdownMenuItem(
                          value: kind,
                          child: Text(feedbackKindLabel(kind)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(
                    () => _kind = value ?? _kind,
                  ),
                ),
                if (widget.cropName.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: widget.cropName,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Культура'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: const Key('feedback-crop-section'),
                    initialValue: _section,
                    decoration:
                        const InputDecoration(labelText: 'Що виправити'),
                    items: _cropSections
                        .map(
                          (section) => DropdownMenuItem(
                            value: section,
                            child: Text(section),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(
                      () => _section = value ?? _section,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('feedback-message'),
                  controller: _messageController,
                  minLines: 5,
                  maxLines: 9,
                  maxLength: 3000,
                  decoration: const InputDecoration(
                    labelText: 'Ваше повідомлення',
                    hintText:
                        'Що потрібно змінити? За можливості додайте правильний варіант або джерело.',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Напишіть повідомлення'
                      : null,
                ),
                const SizedBox(height: 4),
                TextFormField(
                  key: const Key('feedback-reply-email'),
                  controller: _replyEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email для відповіді (необов’язково)',
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) return null;
                    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
                        ? null
                        : 'Перевірте email';
                  },
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  key: const Key('send-feedback-email'),
                  onPressed: _sending ? null : _send,
                  icon: const Icon(Icons.outgoing_mail),
                  label:
                      Text(_sending ? 'Відкриваємо пошту…' : 'Створити лист'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _sending = true);
    final draft = FeedbackDraft(
      kind: _kind,
      message: _messageController.text,
      replyEmail: _replyEmailController.text.trim(),
      cropName: widget.cropName,
      cropSlug: widget.cropSlug,
      section: widget.cropName.isEmpty ? '' : _section,
    );
    var opened = false;
    try {
      opened = await openFeedbackEmail(draft);
    } on Object {
      opened = false;
    }
    if (!mounted) return;
    setState(() => _sending = false);
    if (opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Лист створено. Перевірте його та надішліть.'),
        ),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: draft.body));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Поштову програму не відкрито. Текст відгуку скопійовано.',
        ),
      ),
    );
  }
}
