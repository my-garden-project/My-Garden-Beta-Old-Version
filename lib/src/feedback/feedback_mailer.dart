import 'package:url_launcher/url_launcher.dart';

const feedbackRecipient = String.fromEnvironment(
  'GARDEN_MII_FEEDBACK_EMAIL',
  defaultValue: 'marynnnaa01@gmail.com',
);

enum FeedbackKind {
  general,
  cropList,
  cropCorrection,
  featureIdea,
}

String feedbackKindLabel(FeedbackKind kind) => switch (kind) {
      FeedbackKind.general => 'Загальний відгук',
      FeedbackKind.cropList => 'Зміна у списку культур',
      FeedbackKind.cropCorrection => 'Виправлення опису культури',
      FeedbackKind.featureIdea => 'Пропозиція функції',
    };

class FeedbackDraft {
  final FeedbackKind kind;
  final String message;
  final String replyEmail;
  final String cropName;
  final String cropSlug;
  final String section;

  const FeedbackDraft({
    required this.kind,
    required this.message,
    this.replyEmail = '',
    this.cropName = '',
    this.cropSlug = '',
    this.section = '',
  });

  String get subject {
    final crop = cropName.isEmpty ? '' : ' • $cropName';
    return 'Мій город: ${feedbackKindLabel(kind)}$crop';
  }

  String get body => [
        'Тип: ${feedbackKindLabel(kind)}',
        if (cropName.isNotEmpty) 'Культура: $cropName',
        if (cropSlug.isNotEmpty) 'Ідентифікатор: $cropSlug',
        if (section.isNotEmpty) 'Розділ: $section',
        if (replyEmail.isNotEmpty) 'Email для відповіді: $replyEmail',
        '',
        'Повідомлення:',
        message.trim(),
        '',
        'Надіслано із застосунку «Мій город» 0.1.0.',
      ].join('\n');

  Uri toMailUri({String recipient = feedbackRecipient}) => Uri(
        scheme: 'mailto',
        path: recipient,
        queryParameters: {
          'subject': subject,
          'body': body,
        },
      );
}

Future<bool> openFeedbackEmail(FeedbackDraft draft) => launchUrl(
      draft.toMailUri(),
      mode: LaunchMode.externalApplication,
    );
