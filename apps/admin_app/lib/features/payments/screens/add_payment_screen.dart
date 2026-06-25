import 'dart:io';
import 'package:compound_core/compound_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../core/di/providers.dart';
import '../../../core/providers/app_settings_provider.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/ds_components.dart';

class AddPaymentScreen extends ConsumerStatefulWidget {
  final String? preselectedVillaId;
  const AddPaymentScreen({super.key, this.preselectedVillaId});

  @override
  ConsumerState<AddPaymentScreen> createState() =>
      _AddPaymentScreenState();
}

class _AddPaymentScreenState extends ConsumerState<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String? _selectedVillaId;
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  bool _isPaid = false;
  bool _loading = false;

  /// Holds picked files — each is either an image or PDF path
  final List<_AttachmentFile> _attachments = [];

  @override
  void initState() {
    super.initState();
    _selectedVillaId = widget.preselectedVillaId;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── Platform helpers ────────────────────────────────────────────────────

  static bool get _isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);

  // ── Attachment Pickers ────────────────────────────────────────────────────

  Future<void> _pickCamera() async {
    if (_isDesktop) {
      // Desktop has no camera — fall back to file picker for images
      return _pickImageFile();
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 95,
    );
    if (picked == null) return;

    // Auto-crop with image_cropper (mobile only)
    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      compressQuality: 90,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop',
          toolbarColor: const Color(0xFF5C2D1A),
          toolbarWidgetColor: Colors.white,
          statusBarColor: const Color(0xFF3A1A0D),
          activeControlsWidgetColor: const Color(0xFF5C2D1A),
          backgroundColor: Colors.black,
          cropGridColor: Colors.white54,
          cropFrameColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          hideBottomControls: false,
        ),
        IOSUiSettings(title: 'Crop'),
      ],
    );
    if (cropped != null && mounted) {
      setState(() => _attachments.add(
          _AttachmentFile(path: cropped.path, type: _FileType.image)));
    }
  }

  Future<void> _pickGallery() async {
    if (_isDesktop) {
      return _pickImageFile();
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null) return;

    // Optional crop (mobile only)
    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      compressQuality: 90,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop',
          toolbarColor: const Color(0xFF5C2D1A),
          toolbarWidgetColor: Colors.white,
          statusBarColor: const Color(0xFF3A1A0D),
          activeControlsWidgetColor: const Color(0xFF5C2D1A),
          backgroundColor: Colors.black,
          cropGridColor: Colors.white54,
          cropFrameColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          hideBottomControls: false,
        ),
        IOSUiSettings(title: 'Crop'),
      ],
    );
    if (cropped != null && mounted) {
      setState(() => _attachments.add(
          _AttachmentFile(path: cropped.path, type: _FileType.image)));
    }
  }

  /// Desktop fallback — pick image files via file_picker
  Future<void> _pickImageFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null && result.files.single.path != null && mounted) {
      setState(() => _attachments.add(_AttachmentFile(
          path: result.files.single.path!, type: _FileType.image)));
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null && mounted) {
      setState(() => _attachments.add(_AttachmentFile(
          path: result.files.single.path!, type: _FileType.pdf)));
    }
  }

  void _showAttachmentPicker() {
    final l10n = ref.read(l10nProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.isAr ? 'إضافة مرفق' : 'Add Attachment',
                style: AppTextStyles.title,
              ),
              const SizedBox(height: 20),
              // Camera option — mobile only
              if (!_isDesktop) ...[
                _AttachOption(
                  icon: Icons.camera_alt_rounded,
                  color: AppColors.navy,
                  label: l10n.isAr ? 'التقاط صورة' : 'Take Photo',
                  subtitle: l10n.isAr
                      ? 'التقط صورة مع قص وتحسين تلقائي'
                      : 'Capture with auto-crop & enhance',
                  onTap: () {
                    Navigator.pop(context);
                    _pickCamera();
                  },
                ),
                const SizedBox(height: 10),
              ],
              _AttachOption(
                icon: Icons.photo_library_rounded,
                color: AppColors.gold,
                label: l10n.isAr ? 'اختيار صورة' : 'Choose Image',
                subtitle: _isDesktop
                    ? (l10n.isAr
                        ? 'اختر ملف صورة من الجهاز'
                        : 'Select an image file')
                    : (l10n.isAr
                        ? 'اختر من معرض الصور'
                        : 'Select from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickGallery();
                },
              ),
              const SizedBox(height: 10),
              _AttachOption(
                icon: Icons.picture_as_pdf_rounded,
                color: AppColors.error,
                label: l10n.isAr ? 'اختيار ملف PDF' : 'Choose PDF',
                subtitle: l10n.isAr
                    ? 'اختر مستند PDF من الجهاز'
                    : 'Select a PDF document',
                onTap: () {
                  Navigator.pop(context);
                  _pickPdf();
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // ── Upload Attachments ────────────────────────────────────────────────────

  Future<List<String>> _uploadAttachments(String paymentId) async {
    final urls = <String>[];
    for (var i = 0; i < _attachments.length; i++) {
      final att = _attachments[i];
      final ext = att.type == _FileType.pdf ? 'pdf' : 'jpg';
      final storageRef = FirebaseStorage.instance
          .ref('payments/$paymentId/attachment_$i.$ext');
      await storageRef.putFile(File(att.path));
      final url = await storageRef.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVillaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(l10nProvider).isAr
                ? 'يرجى اختيار فيلا'
                : 'Please select a villa',
          ),
        ),
      );
      return;
    }
    setState(() => _loading = true);

    try {
      final villas = ref.read(villasProvider).value ?? [];
      final villa =
          villas.firstWhere((v) => v.id == _selectedVillaId!);
      final payment = Payment(
        id: '',
        villaId: villa.id,
        villaNumber: villa.villaNumber,
        month: _month,
        year: _year,
        amount: double.parse(_amountCtrl.text.trim()),
        dueDate: _dueDate,
        isPaid: _isPaid,
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        createdAt: DateTime.now(),
      );

      final paymentId =
          await ref.read(paymentRepositoryProvider).add(payment);

      // Upload attachments and update the payment document
      if (_attachments.isNotEmpty) {
        final urls = await _uploadAttachments(paymentId);
        await ref
            .read(paymentRepositoryProvider)
            .updateAttachments(paymentId, urls);
      }

      if (mounted) {
        final l10n = ref.read(l10nProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.isAr ? 'تمت إضافة الدفعة بنجاح' : 'Payment added',
            ),
          ),
        );
        context.go('/payments');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${ref.read(l10nProvider).error}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(l10nProvider);
    final colors = context.appColors;
    final villasAsync = ref.watch(villasProvider);

    return AppScaffold(
      title: l10n.isAr ? 'إضافة دفعة' : 'Add Payment',
      showBottomNav: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH, 20, AppSpacing.screenH, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Villa selection ─────────────────────────────────────────
              _SectionLabel(
                  label: l10n.isAr ? 'الفيلا *' : 'Villa *'),
              const SizedBox(height: 8),
              GdsCard(
                padding: const EdgeInsets.all(4),
                child: villasAsync.when(
                  data: (villas) => DropdownButtonFormField<String>(
                    value: _selectedVillaId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      prefixIcon: Icon(Icons.home_work_outlined,
                          color: colors.textSecondary),
                    ),
                    hint: Text(
                      l10n.isAr ? 'اختر الفيلا' : 'Select a villa',
                      style: AppTextStyles.body
                          .copyWith(color: colors.textHint),
                    ),
                    dropdownColor: colors.surface,
                    items: villas
                        .map((v) => DropdownMenuItem(
                              value: v.id,
                              child: Text(
                                l10n.isAr
                                    ? 'فيلا ${v.villaNumber} — ${v.ownerName}'
                                    : 'Villa ${v.villaNumber} — ${v.ownerName}',
                                style: AppTextStyles.body,
                              ),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedVillaId = v),
                    validator: (v) => v == null
                        ? (l10n.isAr
                            ? 'اختر فيلا'
                            : 'Select a villa')
                        : null,
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child:
                        Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('${l10n.error}: $e',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.error)),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Month & Year ───────────────────────────────────────────
              _SectionLabel(
                  label: l10n.isAr
                      ? 'الشهر والسنة *'
                      : 'Month & Year *'),
              const SizedBox(height: 8),
              GdsCard(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _month,
                        isExpanded: true,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                          labelText:
                              l10n.isAr ? 'الشهر' : 'Month',
                        ),
                        dropdownColor: colors.surface,
                        items: List.generate(
                          12,
                          (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text(
                              DateFormat('MMMM')
                                  .format(DateTime(2000, i + 1)),
                              style: AppTextStyles.body,
                            ),
                          ),
                        ),
                        onChanged: (v) =>
                            setState(() => _month = v!),
                      ),
                    ),
                    Container(
                        width: 1,
                        height: 40,
                        color: colors.border),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _year,
                        isExpanded: true,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                          labelText:
                              l10n.isAr ? 'السنة' : 'Year',
                        ),
                        dropdownColor: colors.surface,
                        items: List.generate(
                          5,
                          (i) => DropdownMenuItem(
                            value: DateTime.now().year - 1 + i,
                            child: Text(
                              '${DateTime.now().year - 1 + i}',
                              style: AppTextStyles.body,
                            ),
                          ),
                        ),
                        onChanged: (v) =>
                            setState(() => _year = v!),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Amount ─────────────────────────────────────────────────
              _SectionLabel(
                  label: l10n.isAr ? 'المبلغ *' : 'Amount *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.attach_money,
                      color: colors.textSecondary),
                  suffixText: l10n.currencySuffix,
                  filled: true,
                  fillColor: colors.surface,
                ),
                style: AppTextStyles.number
                    .copyWith(color: colors.textPrimary),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return l10n.isAr
                        ? 'أدخل المبلغ'
                        : 'Enter amount';
                  }
                  if (double.tryParse(v) == null) {
                    return l10n.isAr
                        ? 'مبلغ غير صحيح'
                        : 'Invalid amount';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Due Date ───────────────────────────────────────────────
              _SectionLabel(
                  label: l10n.isAr
                      ? 'تاريخ الاستحقاق *'
                      : 'Due Date *'),
              const SizedBox(height: 8),
              GdsCard(
                padding: EdgeInsets.zero,
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dueDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      builder: (context, child) => Theme(
                        data: Theme.of(context),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setState(() => _dueDate = picked);
                    }
                  },
                  borderRadius:
                      BorderRadius.circular(AppRadius.md),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            color: colors.textSecondary,
                            size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.isAr
                                    ? 'تاريخ الاستحقاق'
                                    : 'Due Date',
                                style: AppTextStyles.caption
                                    .copyWith(
                                        color: colors.textHint),
                              ),
                              Text(
                                DateFormat('dd MMM yyyy')
                                    .format(_dueDate),
                                style: AppTextStyles.body.copyWith(
                                    color: colors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: colors.textHint),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Description ────────────────────────────────────────────
              _SectionLabel(
                  label: l10n.isAr
                      ? 'الوصف (اختياري)'
                      : 'Description (optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: l10n.isAr
                      ? 'ملاحظات إضافية...'
                      : 'Additional notes...',
                  prefixIcon: Icon(Icons.notes_outlined,
                      color: colors.textSecondary),
                  filled: true,
                  fillColor: colors.surface,
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Attachments ────────────────────────────────────────────
              _SectionLabel(
                  label: l10n.isAr
                      ? 'المرفقات (اختياري)'
                      : 'Attachments (optional)'),
              const SizedBox(height: 8),

              // Attachment grid
              if (_attachments.isNotEmpty) ...[
                SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _attachments.length,
                    itemBuilder: (_, i) {
                      final att = _attachments[i];
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 110,
                              decoration: BoxDecoration(
                                borderRadius: AppRadius.mdRadius,
                                border: Border.all(
                                    color: colors.border),
                                color: colors.surfaceAlt,
                              ),
                              child: ClipRRect(
                                borderRadius: AppRadius.mdRadius,
                                child: att.type == _FileType.image
                                    ? Image.file(
                                        File(att.path),
                                        fit: BoxFit.cover,
                                        width: 100,
                                        height: 110,
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment
                                                .center,
                                        children: [
                                          Icon(
                                              Icons
                                                  .picture_as_pdf_rounded,
                                              color:
                                                  AppColors.error,
                                              size: 36),
                                          const SizedBox(
                                              height: 4),
                                          Text('PDF',
                                              style: AppTextStyles
                                                  .labelSm
                                                  .copyWith(
                                                      color: colors
                                                          .textSecondary)),
                                        ],
                                      ),
                              ),
                            ),
                            // Remove button
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => setState(() =>
                                    _attachments.removeAt(i)),
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      color: Colors.white,
                                      size: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Add attachment button
              GdsButton(
                label: l10n.isAr ? 'إضافة مرفق' : 'Add Attachment',
                icon: Icons.attach_file_rounded,
                variant: GdsButtonVariant.secondary,
                onPressed: _showAttachmentPicker,
                height: 44,
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Paid toggle ────────────────────────────────────────────
              GdsCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _isPaid
                            ? AppColors.successLight
                            : colors.surfaceAlt,
                        borderRadius: AppRadius.smRadius,
                      ),
                      child: Icon(
                        _isPaid
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: _isPaid
                            ? AppColors.success
                            : colors.textHint,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.isAr
                                ? 'وضع علامة مدفوع'
                                : 'Mark as Paid',
                            style: AppTextStyles.titleSm,
                          ),
                          Text(
                            l10n.isAr
                                ? 'فعّل إذا تم تحصيل الدفعة'
                                : 'Enable if payment was received',
                            style: AppTextStyles.caption.copyWith(
                                color: colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isPaid,
                      onChanged: (v) =>
                          setState(() => _isPaid = v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // ── Save button ────────────────────────────────────────────
              GdsButton(
                label: _loading
                    ? ''
                    : (l10n.isAr ? 'حفظ الدفعة' : 'Save Payment'),
                icon: _loading ? null : Icons.save_rounded,
                loading: _loading,
                onPressed: _loading ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// == Helper types ==============================================================

enum _FileType { image, pdf }

class _AttachmentFile {
  final String path;
  final _FileType type;
  const _AttachmentFile({required this.path, required this.type});
}

// == Section Label ============================================================

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.label
          .copyWith(color: context.appColors.textSecondary),
    );
  }
}

// == Attachment Option ========================================================

class _AttachOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _AttachOption({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GdsCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: AppRadius.smRadius,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.titleSm),
                    Text(subtitle,
                        style: AppTextStyles.caption
                            .copyWith(color: colors.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: colors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}
