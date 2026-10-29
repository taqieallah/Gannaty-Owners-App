import 'package:url_launcher/url_launcher.dart';

/// Compound management contact channels used by "التواصل مع الإدارة" and the dues
/// reminder. Security and maintenance numbers come from the admin app
/// (see ImportantNumbersRepository).
///
/// ⚠️ Replace the placeholder numbers below with the real ones (international
/// format, digits only, no "+" — e.g. Egypt: 20 followed by the number without
/// the leading 0).
class AdminContact {
  AdminContact._();

  static const String whatsapp = '201098868292';
  static const String phone = '201098868292';

  static bool get isConfigured => whatsapp.isNotEmpty;

  static Future<void> openWhatsApp({String? message}) async {
    final q = message == null ? '' : '?text=${Uri.encodeComponent(message)}';
    await launchUrl(
      Uri.parse('https://wa.me/$whatsapp$q'),
      mode: LaunchMode.externalApplication,
    );
  }

  static Future<void> call([String? number]) async {
    await launchUrl(Uri.parse('tel:${number ?? phone}'));
  }
}
