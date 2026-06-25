import 'dart:async';

import 'package:compound_core/compound_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/notifications/providers/notification_history_provider.dart';
import '../providers/app_providers.dart';
import '../router/app_router.dart';
import '../settings/app_settings.dart';

class ClientNotificationBootstrap extends ConsumerStatefulWidget {
  const ClientNotificationBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ClientNotificationBootstrap> createState() =>
      _ClientNotificationBootstrapState();
}

class _ClientNotificationBootstrapState
    extends ConsumerState<ClientNotificationBootstrap> {
  StreamSubscription<List<ServiceRequest>>? _requestsSub;
  StreamSubscription<List<Payment>>? _paymentsSub;
  StreamSubscription<List<AnnualSettlement>>? _settlementsSub;
  StreamSubscription<List<Announcement>>? _announcementsSub;

  Set<String> _knownRequestStates = <String>{};
  Set<String> _knownPaymentStates = <String>{};
  Set<String> _knownSettlementStates = <String>{};
  Set<String> _knownAnnouncementStates = <String>{};
  bool _hasSeenAnnouncementSnapshot = false;
  String? _activeVillaId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await NotificationService.initialize(
        onTap: (data) {
          final route = NotificationService.routeFromMessage(
            data,
            isAdmin: false,
          );
          ref.read(routerProvider).go(route);
        },
      );
      _bindCurrentVilla();
    });
    ref.listenManual<Villa?>(currentVillaProvider, (previous, next) {
      if (previous?.id != next?.id) {
        _bindCurrentVilla();
      }
    });
  }

  Future<void> _bindCurrentVilla() async {
    final villa = ref.read(currentVillaProvider);
    if (villa == null) {
      _activeVillaId = null;
      _knownRequestStates = <String>{};
      _knownPaymentStates = <String>{};
      _knownSettlementStates = <String>{};
      _knownAnnouncementStates = <String>{};
      _hasSeenAnnouncementSnapshot = false;
      await _cancelSubs();
      return;
    }

    if (_activeVillaId == villa.id) return;
    _activeVillaId = villa.id;
    await _cancelSubs();

    _requestsSub = ref
        .read(serviceRequestRepositoryProvider)
        .watchByPhone(villa.phoneNumber)
        .listen(_handleRequestChanges);

    _paymentsSub = ref
        .read(paymentRepositoryProvider)
        .watchByVilla(villa.id)
        .listen(_handlePaymentChanges);

    _settlementsSub = ref
        .read(annualSettlementRepositoryProvider)
        .watchByVilla(villa.id)
        .listen(_handleSettlementChanges);

    _announcementsSub = ref
        .read(announcementRepositoryProvider)
        .watchAll()
        .listen(_handleAnnouncementChanges);
  }

  Future<void> _cancelSubs() async {
    await _requestsSub?.cancel();
    await _paymentsSub?.cancel();
    await _settlementsSub?.cancel();
    await _announcementsSub?.cancel();
    _requestsSub = null;
    _paymentsSub = null;
    _settlementsSub = null;
    _announcementsSub = null;
  }

  void _handleRequestChanges(List<ServiceRequest> requests) {
    final settings = ref.read(appSettingsProvider).value ??
        const AppSettings(themeMode: ThemeMode.light, isArabic: true);
    final nextKnown = <String>{};
    for (final request in requests) {
      final signature =
          '${request.id}:${request.status.name}:${request.updatedAt.millisecondsSinceEpoch}:${request.imageUrl ?? ''}:${request.adminNote ?? ''}';
      nextKnown.add(signature);

      final hasPrevious = _knownRequestStates.any(
        (entry) => entry.startsWith('${request.id}:'),
      );
      if (_knownRequestStates.isEmpty || !hasPrevious) {
        continue;
      }
      if (_knownRequestStates.contains(signature)) {
        continue;
      }

      final title = switch (request.status) {
        ServiceRequestStatus.pending =>
          settings.isArabic ? 'ØªØ­Ø¯ÙŠØ« Ø·Ù„Ø¨ Ø§Ù„Ø®Ø¯Ù…Ø©' : 'Request Update',
        ServiceRequestStatus.inProgress =>
          settings.isArabic ? 'Ø¬Ø§Ø±ÙŠ ØªÙ†ÙÙŠØ° Ø§Ù„Ø·Ù„Ø¨' : 'Work Started',
        ServiceRequestStatus.solved =>
          settings.isArabic ? 'ØªÙ… Ø¥Ù†Ù‡Ø§Ø¡ Ø§Ù„Ø·Ù„Ø¨' : 'Request Completed',
      };
      final body = switch (request.status) {
        ServiceRequestStatus.pending =>
          settings.isArabic ? 'ØªÙ… ØªØ­Ø¯ÙŠØ« Ø­Ø§Ù„Ø© Ø·Ù„Ø¨Ùƒ Ù…Ù† Ø§Ù„Ø¥Ø¯Ø§Ø±Ø©' : 'Your request was updated',
        ServiceRequestStatus.inProgress =>
          settings.isArabic ? 'Ø¨Ø¯Ø£Øª Ø§Ù„Ø¥Ø¯Ø§Ø±Ø© Ø§Ù„Ø¹Ù…Ù„ Ø¹Ù„Ù‰ Ø·Ù„Ø¨Ùƒ' : 'The team started working on your request',
        ServiceRequestStatus.solved =>
          settings.isArabic ? 'ØªÙ… Ø¥Ù†Ù‡Ø§Ø¡ Ø·Ù„Ø¨Ùƒ ÙˆÙŠÙ…ÙƒÙ†Ùƒ Ù…Ø±Ø§Ø¬Ø¹Ø© Ø§Ù„ØµÙˆØ±Ø© ÙˆØ§Ù„Ù…Ù„Ø§Ø­Ø¸Ø©' : 'Your request has been completed',
      };
      unawaited(
        NotificationService.showSimpleNotification(title: title, body: body),
      );
      unawaited(
        ref
            .read(notificationHistoryProvider.notifier)
            .add(title: title, body: body),
      );
    }
    _knownRequestStates = nextKnown;
  }

  void _handlePaymentChanges(List<Payment> payments) {
    final settings = ref.read(appSettingsProvider).value ??
        const AppSettings(themeMode: ThemeMode.light, isArabic: true);
    final nextKnown = <String>{};
    for (final payment in payments) {
      final signature =
          '${payment.id}:${payment.isPaid}:${payment.attachments.length}:${payment.amount}:${payment.description ?? ''}';
      nextKnown.add(signature);

      final hasPrevious = _knownPaymentStates.any(
        (entry) => entry.startsWith('${payment.id}:'),
      );
      if (_knownPaymentStates.isEmpty || !hasPrevious) {
        continue;
      }
      if (_knownPaymentStates.contains(signature)) {
        continue;
      }

      final title = payment.isPaid
          ? (settings.isArabic ? 'ØªÙ… ØªØ³Ø¬ÙŠÙ„ Ø¯ÙØ¹Ø©' : 'Payment Recorded')
          : (settings.isArabic ? 'ØªØ­Ø¯ÙŠØ« Ù…Ø¯ÙÙˆØ¹Ø§Øª' : 'Payments Updated');
      final body = payment.isPaid
          ? (settings.isArabic
              ? 'ØªÙ… ØªØ³Ø¬ÙŠÙ„ Ø¯ÙØ¹Ø© Ø¬Ø¯ÙŠØ¯Ø© Ø¹Ù„Ù‰ Ø­Ø³Ø§Ø¨Ùƒ'
              : 'A new payment was recorded')
          : (settings.isArabic
              ? 'ØªÙ…Øª Ø¥Ø¶Ø§ÙØ© Ø£Ùˆ ØªØ¹Ø¯ÙŠÙ„ Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„Ù…Ø¯ÙÙˆØ¹Ø§Øª'
              : 'Payments data was added or updated');
      unawaited(
        NotificationService.showSimpleNotification(title: title, body: body),
      );
      unawaited(
        ref
            .read(notificationHistoryProvider.notifier)
            .add(title: title, body: body),
      );
    }
    _knownPaymentStates = nextKnown;
  }

  void _handleSettlementChanges(List<AnnualSettlement> settlements) {
    final settings = ref.read(appSettingsProvider).value ??
        const AppSettings(themeMode: ThemeMode.light, isArabic: true);
    final nextKnown = <String>{};
    for (final settlement in settlements) {
      final signature =
          '${settlement.id}:${settlement.year}:${settlement.closingBalance}:${settlement.createdAt.millisecondsSinceEpoch}';
      nextKnown.add(signature);

      final hasPrevious = _knownSettlementStates.any(
        (entry) => entry.startsWith('${settlement.id}:'),
      );
      if (_knownSettlementStates.isEmpty || !hasPrevious) {
        continue;
      }
      if (_knownSettlementStates.contains(signature)) {
        continue;
      }

      final title = settings.isArabic ? 'ØªØ³ÙˆÙŠØ© Ø¬Ø¯ÙŠØ¯Ø©' : 'New Settlement';
      final body = settings.isArabic
          ? 'ØªÙ…Øª Ø¥Ø¶Ø§ÙØ© Ø£Ùˆ ØªØ­Ø¯ÙŠØ« Ø§Ù„ØªØ³ÙˆÙŠØ© Ø§Ù„Ø³Ù†ÙˆÙŠØ© Ø§Ù„Ø®Ø§ØµØ© Ø¨Ùƒ'
          : 'Your annual settlement was updated';
      unawaited(
        NotificationService.showSimpleNotification(title: title, body: body),
      );
      unawaited(
        ref
            .read(notificationHistoryProvider.notifier)
            .add(title: title, body: body),
      );
    }
    _knownSettlementStates = nextKnown;
  }

  void _handleAnnouncementChanges(List<Announcement> announcements) {
    final settings = ref.read(appSettingsProvider).value ??
        const AppSettings(themeMode: ThemeMode.light, isArabic: true);
    final nextKnown = <String>{};
    for (final announcement in announcements) {
      final signature =
          '${announcement.id}:${announcement.createdAt.millisecondsSinceEpoch}';
      nextKnown.add(signature);

      if (!_hasSeenAnnouncementSnapshot) {
        continue;
      }
      if (_knownAnnouncementStates.contains(signature)) {
        continue;
      }

      final title =
          settings.isArabic ? 'Ø¥Ø¹Ù„Ø§Ù† Ø¬Ø¯ÙŠØ¯ Ù…Ù† Ø§Ù„Ø¥Ø¯Ø§Ø±Ø©' : 'New Announcement';
      final body = announcement.title.trim().isEmpty
          ? (settings.isArabic
              ? 'ØªÙ…Øª Ø¥Ø¶Ø§ÙØ© Ø¥Ø¹Ù„Ø§Ù† Ø¬Ø¯ÙŠØ¯ ÙˆÙŠÙ…ÙƒÙ†Ùƒ Ù…Ø±Ø§Ø¬Ø¹ØªÙ‡ Ø§Ù„Ø¢Ù†'
              : 'A new announcement was added')
          : announcement.title;

      unawaited(
        NotificationService.showSimpleNotification(title: title, body: body),
      );
      unawaited(
        ref
            .read(notificationHistoryProvider.notifier)
            .add(title: title, body: body),
      );
    }
    _knownAnnouncementStates = nextKnown;
    _hasSeenAnnouncementSnapshot = true;
  }

  @override
  void dispose() {
    _cancelSubs();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

