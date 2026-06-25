import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:compound_core/compound_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/settings/app_text.dart';
import '../../../shared/widgets/client_page_scaffold.dart';

class SubmitRequestScreen extends ConsumerStatefulWidget {
  const SubmitRequestScreen({super.key});

  @override
  ConsumerState<SubmitRequestScreen> createState() =>
      _SubmitRequestScreenState();
}

class _SubmitRequestScreenState extends ConsumerState<SubmitRequestScreen> {
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  ServiceRequestType _type = ServiceRequestType.maintenance;
  PlatformFile? _selectedFile;
  bool _submitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() => _selectedFile = result.files.single);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final villa = ref.read(currentVillaProvider);
    if (villa == null) return;

    setState(() => _submitting = true);
    final settings = ref.read(appSettingsProvider).value ??
        const AppSettings(themeMode: ThemeMode.light, isArabic: true);
    final t = AppText(settings);

    try {
      String? imageUrl;
      if (_selectedFile != null) {
        final file = _selectedFile!;
        final ext = file.extension ?? 'jpg';
        final storageRef = FirebaseStorage.instanceFor(app: Firebase.app('expenses')).ref(
          'service_requests/client_uploads/${villa.id}/${DateTime.now().millisecondsSinceEpoch}.$ext',
        );

        if (file.bytes != null) {
          await storageRef.putData(file.bytes!);
        } else if (file.path != null && !kIsWeb) {
          await storageRef.putFile(File(file.path!));
        }
        imageUrl = await storageRef.getDownloadURL();
      }

      final request = ServiceRequest(
        id: '',
        villaId: villa.id,
        villaNumber: villa.villaNumber,
        clientPhone: villa.phoneNumber,
        clientName: villa.ownerName,
        type: _type,
        description: _descriptionController.text.trim(),
        status: ServiceRequestStatus.pending,
        imageUrl: imageUrl,
        adminNote: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final requestId = await ref.read(serviceRequestRepositoryProvider).add(request);
      await _enqueueAdminPush(
        requestId: requestId,
        villaNumber: villa.villaNumber,
        clientName: villa.ownerName,
        type: _type,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.requestSent)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t.failedSubmitRequest}: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _enqueueAdminPush({
    required String requestId,
    required String villaNumber,
    required String clientName,
    required ServiceRequestType type,
  }) async {
    try {
      final firestore = FirebaseFirestore.instanceFor(app: Firebase.app('expenses'));
      await firestore.collection('service_request_push_queue').doc(requestId).set({
        'requestId': requestId,
        'villaNumber': villaNumber,
        'clientName': clientName,
        'type': type.name,
        'createdAt': FieldValue.serverTimestamp(),
        'source': 'client_app',
      });
    } catch (e) {
      debugPrint('service request push queue failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider).value ??
        const AppSettings(themeMode: ThemeMode.light, isArabic: true);
    final t = AppText(settings);

    return ClientPageScaffold(
      title: t.newRequest,
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            DropdownButtonFormField<ServiceRequestType>(
              initialValue: _type,
              decoration: InputDecoration(
                labelText: t.requestType,
              ),
              items: [
                DropdownMenuItem(
                  value: ServiceRequestType.maintenance,
                  child: Text(t.maintenance),
                ),
                DropdownMenuItem(
                  value: ServiceRequestType.complaint,
                  child: Text(t.complaint),
                ),
                DropdownMenuItem(
                  value: ServiceRequestType.other,
                  child: Text(t.other),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _type = value);
                }
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: t.issueDescription,
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return t.enterDescription;
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_camera_back_rounded),
              label: Text(
                _selectedFile == null ? t.attachImage : _selectedFile!.name,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(t.submitRequest),
            ),
          ],
        ),
      ),
    );
  }
}
