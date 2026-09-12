import 'package:url_launcher/url_launcher.dart';

/// Compound management contact channels used by "التواصل مع الإدارة", the dues
/// reminder and the emergency directory.
///
/// ⚠️ Replace the placeholder numbers below with the real ones (international
/// format, digits only, no "+" — e.g. Egypt: 20 followed by the number without
/// the leading 0).
class AdminContact {
  AdminContact._();

  static const String whatsapp = '201000000000'; // TODO: real admin WhatsApp
  static const String phone = '201000000000'; // TODO: real admin phone
  static const String security = '201000000000'; // TODO: gate / security
  static const String maintenance = '201000000000'; // TODO: maintenance desk

  static bool get isConfigured => whatsapp != '201000000000';

  static Future<void> openWhatsApp({String? message}) async {
    final q = message == null ? '' : '?text=${Uri.encodeComponent(message)}';
    await launchUrl(Uri.parse('https://wa.me/$whatsapp$q'),
        mode: LaunchMode.externalApplication);
  }

  static Future<void> call([String? number]) async {
    await launchUrl(Uri.parse('tel:${number ?? phone}'));
  }
}
