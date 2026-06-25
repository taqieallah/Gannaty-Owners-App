import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/settings/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/client_page_scaffold.dart';

// ── Biometric provider ─────────────────────────────────────────────────────

final biometricEnabledProvider =
    NotifierProvider<BiometricNotifier, bool>(BiometricNotifier.new);

class BiometricNotifier extends Notifier<bool> {
  static const _enabledKey = 'biometric_enabled';
  static const _phoneKey = 'biometric_phone';

  @override
  bool build() {
    _load();
    return false;
  }

  static Future<String?> savedPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_phoneKey);
  }

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_enabledKey) ?? false;
  }

  Future<void> enable(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, true);
    await prefs.setString(_phoneKey, phone);
    state = true;
  }

  Future<void> disable() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, false);
    await prefs.remove(_phoneKey);
    state = false;
  }
}

// ── Screen ─────────────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final villa = ref.watch(currentVillaProvider);
    final settings = ref.watch(appSettingsProvider).value ??
        const AppSettings(themeMode: ThemeMode.light, isArabic: true);
    final t = AppText(settings);
    final biometricEnabled = ref.watch(biometricEnabledProvider);

    if (villa == null) return ClientPageScaffold(title: t.profile, body: const SizedBox.shrink());

    return ClientPageScaffold(
      title: t.profile,
      body: ListView(
        children: [
          // ── Avatar / name header ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5C2D1A), AppTheme.cognac],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    villa.ownerName.isNotEmpty
                        ? villa.ownerName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        villa.ownerName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${t.gannatyCompound} - ${villa.villaNumber}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Villa info card ─────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.villaInfo,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                  _InfoRow(label: t.villaNumberLabel, value: villa.villaNumber),
                  _InfoRow(label: t.ownerNameLabel, value: villa.ownerName),
                  _InfoRow(label: t.phoneLabel, value: villa.phoneNumber),
                  _InfoRow(
                    label: t.areaLabel,
                    value: '${villa.area.toStringAsFixed(0)} m²',
                  ),
                  _InfoRow(
                    label: t.annualFeeLabel,
                    value: '${villa.annualFee.toStringAsFixed(0)} EGP',
                  ),
                  _InfoRow(
                    label: t.depositLabel,
                    value: '${villa.depositAmount.toStringAsFixed(0)} EGP',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Security card ───────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.changePassword,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                  _ChangePasswordForm(t: t),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Biometric card ──────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.cognac.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.fingerprint_rounded,
                      color: AppTheme.cognac,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.biometricLogin,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          biometricEnabled
                              ? t.biometricEnabled
                              : t.biometricDisabled,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: biometricEnabled,
                    onChanged: (val) =>
                        _toggleBiometric(context, ref, val, t, villa.phoneNumber),
                    activeThumbColor: AppTheme.cognac,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Sign out ────────────────────────────────────────────────────
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () =>
                ref.read(sessionControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout_rounded),
            label: Text(t.signOut),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _toggleBiometric(
    BuildContext context,
    WidgetRef ref,
    bool value,
    AppText t,
    String phone,
  ) async {
    if (value) {
      final auth = LocalAuthentication();
      final canCheck = await auth.canCheckBiometrics;
      final isDeviceSupported = await auth.isDeviceSupported();
      if (!canCheck || !isDeviceSupported) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.biometricNotAvailable)),
          );
        }
        return;
      }
      final authenticated = await auth.authenticate(
        localizedReason: t.biometricHint,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (!authenticated) return;
      await ref.read(biometricEnabledProvider.notifier).enable(phone);
    } else {
      await ref.read(biometricEnabledProvider.notifier).disable();
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordForm extends ConsumerStatefulWidget {
  const _ChangePasswordForm({required this.t});
  final AppText t;

  @override
  ConsumerState<_ChangePasswordForm> createState() =>
      _ChangePasswordFormState();
}

class _ChangePasswordFormState extends ConsumerState<_ChangePasswordForm> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = widget.t;
    if (_newCtrl.text.trim() != _confirmCtrl.text.trim()) {
      setState(() => _error = t.passwordsDontMatch);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await ref
        .read(sessionControllerProvider.notifier)
        .changePassword(
          currentPassword: _currentCtrl.text,
          newPassword: _newCtrl.text,
        );
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
    } else {
      _currentCtrl.clear();
      _newCtrl.clear();
      _confirmCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.passwordChanged)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return Column(
      children: [
        TextField(
          controller: _currentCtrl,
          obscureText: true,
          decoration: InputDecoration(labelText: t.currentPasswordLabel),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _newCtrl,
          obscureText: true,
          decoration: InputDecoration(labelText: t.newPassword),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirmCtrl,
          obscureText: true,
          decoration: InputDecoration(labelText: t.confirmPassword),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(
            _error!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 13,
            ),
          ),
        ],
        const SizedBox(height: 14),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(t.saveAndContinue),
        ),
      ],
    );
  }
}
