import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';

/// First-launch language picker. Shown before the login screen and never
/// again once the owner has chosen; the choice stays editable from Settings.
class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key});

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  bool _busy = false;

  Future<void> _choose(bool isArabic) async {
    if (_busy) return;
    setState(() => _busy = true);
    await ref.read(appSettingsProvider.notifier).chooseLanguage(isArabic);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.espresso, AppTheme.cognac],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/images/gannaty_icon.png',
                          width: 112,
                          height: 112,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'اختر اللغة',
                        style: TextStyle(
                          color: AppTheme.ivory,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Choose your language',
                        style: TextStyle(
                          color: AppTheme.ivory.withValues(alpha: 0.72),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _LanguageTile(
                        title: 'العربية',
                        subtitle: 'المتابعة بالعربية',
                        enabled: !_busy,
                        onTap: () => _choose(true),
                      ),
                      const SizedBox(height: 14),
                      _LanguageTile(
                        title: 'English',
                        subtitle: 'Continue in English',
                        textDirection: TextDirection.ltr,
                        enabled: !_busy,
                        onTap: () => _choose(false),
                      ),
                      const SizedBox(height: 26),
                      Text(
                        'يمكنك تغيير اللغة لاحقًا من الإعدادات\n'
                        'You can change this later in Settings',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.ivory.withValues(alpha: 0.6),
                          fontSize: 12,
                          height: 1.7,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
    this.textDirection = TextDirection.rtl,
  });

  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: textDirection,
      child: Material(
        color: AppTheme.mist,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppTheme.text,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppTheme.textSoft,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded,
                    color: AppTheme.cognac, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
