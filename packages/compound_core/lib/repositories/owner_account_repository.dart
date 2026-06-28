import '../cloud/supa_db.dart';
import '../models/owner_account.dart';
import '../models/owner_ledger_entry.dart';
import '../models/owner_statement.dart';
import '../models/villa.dart';

/// Reads owner financial data from Supabase (the `documents` table written by
/// the ERP migration under the shared workspace uid):
///   owners, owner_transactions, owner_year_settings, owner_statements,
///   revenues, attachments.
///
/// Villa IDs that originate from this repo are prefixed with "owner_" (e.g.
/// "owner_42") so SessionController routes password changes to the right place.
class OwnerAccountRepository {
  static const ownerIdPrefix = 'owner_';

  OwnerAccountRepository();

  final SupaDb _db = SupaDb.instance;

  static const _owners = 'owners';
  static const _tx = 'owner_transactions';
  static const _yearSettings = 'owner_year_settings';
  static const _statements = 'owner_statements';
  static const _revenues = 'revenues';
  static const _attachments = 'attachments';

  // ── Statements ────────────────────────────────────────────────────────────

  /// Years that have a precomputed statement for [ownerId], newest first.
  Future<List<int>> availableStatementYears(int ownerId) async {
    try {
      final docs = await _db.queryEq(_statements, 'OwnerId', ownerId);
      final years = docs
          .map((d) => (d.data['Year'] as num?)?.toInt())
          .whereType<int>()
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));
      if (years.isNotEmpty) return years;
    } catch (_) {}
    return [DateTime.now().year];
  }

  /// Precomputed statement pushed by the ERP for [ownerId]/[year], or null.
  Future<OwnerStatement?> _fetchStatement(int ownerId, int year) async {
    try {
      final doc = await _db.getById(_statements, '$ownerId-$year');
      if (doc != null) return OwnerStatement.fromMap(doc.data);
      final docs = await _db.queryEq(_statements, 'OwnerId', ownerId);
      for (final d in docs) {
        if ((d.data['Year'] as num?)?.toInt() == year) {
          return OwnerStatement.fromMap(d.data);
        }
      }
    } catch (_) {}
    return null;
  }

  // ── Auth helpers ────────────────────────────────────────────────────────

  /// Find owner by phone number. Returns the document (id + data) or null.
  Future<SupaDoc?> findOwnerDocByPhone(String phone) async {
    final raw = phone.trim();
    final normalized = _normalizePhone(raw);

    final exact = await _db.queryEq(_owners, 'Phone', raw, limit: 1);
    if (exact.isNotEmpty) return exact.first;

    if (normalized != raw && normalized.isNotEmpty) {
      final byNorm = await _db.queryEq(_owners, 'Phone', normalized, limit: 1);
      if (byNorm.isNotEmpty) return byNorm.first;
    }

    final all = await _db.list(_owners);
    for (final d in all) {
      final ownerPhone = _normalizePhone((d.data['Phone'] as String?) ?? '');
      if (ownerPhone.isNotEmpty && ownerPhone == normalized) return d;
    }
    return null;
  }

  /// Build a [Villa] session object from an owner document. Villa.id is
  /// prefixed with "owner_" so SessionController knows the source collection.
  static Villa buildVillaFromDoc(SupaDoc doc) {
    final d = doc.data;
    final ownerId = (d['Id'] as num?)?.toInt() ?? 0;
    final storedPwd = ((d['Password'] as String?) ?? '').trim();
    final isFirstLogin = (d['IsFirstLogin'] as bool?) ??
        (storedPwd.isEmpty || storedPwd == '123456');

    return Villa(
      id: '$ownerIdPrefix$ownerId',
      villaNumber: ((d['VillaNo'] as String?) ?? '').trim(),
      ownerName: ((d['Name'] as String?) ?? '').trim(),
      phoneNumber: ((d['Phone'] as String?) ?? '').trim(),
      area: (d['VillaArea'] as num?)?.toDouble() ?? 0,
      annualFee: (d['InitialMaintenance'] as num?)?.toDouble() ?? 0,
      depositAmount: (d['DepositPaid'] as num?)?.toDouble() ?? 0,
      password: storedPwd.isNotEmpty ? storedPwd : '123456',
      isFirstLogin: isFirstLogin,
      createdAt: DateTime.tryParse((d['CreatedAt'] as String?) ?? '') ??
          DateTime.now(),
    );
  }

  /// Rebuild a Villa session object by owner int ID (used to restore session).
  Future<Villa?> rebuildVillaById(int ownerId) async {
    final docs = await _db.queryEq(_owners, 'Id', ownerId, limit: 1);
    if (docs.isEmpty) return null;
    return buildVillaFromDoc(docs.first);
  }

  /// Update password for an owner and clear the first-login flag.
  Future<void> updatePassword(int ownerId, String newPassword) async {
    final docId = await _ownerDocIdById(ownerId);
    if (docId == null) return;
    await _db.update(_owners, docId, {
      'Password': newPassword,
      'IsFirstLogin': false,
    });
  }

  // ── Balance queries ───────────────────────────────────────────────────────

  Future<OwnerAccount?> fetchById(int ownerId, {int? year}) async {
    final docs = await _db.queryEq(_owners, 'Id', ownerId, limit: 1);
    if (docs.isEmpty) return null;
    return _buildAccount(docs.first, year ?? DateTime.now().year);
  }

  Future<OwnerAccount?> fetchByVillaNo(String villaNo, {int? year}) async {
    final doc = await _findOwnerDocByVillaNo(villaNo);
    if (doc == null) return null;
    return _buildAccount(doc, year ?? DateTime.now().year);
  }

  Future<OwnerAccount> _buildAccount(SupaDoc ownerDoc, int currentYear) async {
    final ownerId = (ownerDoc.data['Id'] as num?)?.toInt() ?? 0;

    final yearDocs = await _db.queryEq(_yearSettings, 'OwnerId', ownerId);
    final yearList = yearDocs
        .map((d) => d.data)
        .where((d) => (d['Year'] as num?)?.toInt() == currentYear)
        .toList();
    final yearSettings = yearList.isNotEmpty ? yearList.first : null;

    final txDocs = await _db.queryEq(_tx, 'OwnerId', ownerId);
    final from = '$currentYear-01-01';
    final to = '${currentYear + 1}-01-01';

    double totalCharges = 0;
    double totalPayments = 0;
    for (final d in txDocs) {
      final txDate = ((d.data['TxDate'] as String?) ?? '');
      if (txDate.compareTo(from) < 0 || txDate.compareTo(to) >= 0) continue;
      final type = ((d.data['TxType'] as String?) ?? '').toUpperCase();
      final amount = (d.data['Amount'] as num?)?.toDouble() ?? 0;
      if (type == 'PAYMENT') {
        totalPayments += amount;
      } else {
        totalCharges += amount;
      }
    }

    final statement = await _fetchStatement(ownerId, currentYear);

    return OwnerAccount.fromMap(
      ownerData: ownerDoc.data,
      yearSettings: yearSettings,
      totalCharges: totalCharges,
      totalPayments: totalPayments,
      year: currentYear,
      statement: statement,
    );
  }

  // ── FCM token (stored on the owner doc for the admin to read) ──────────────

  Future<void> saveFcmToken(int ownerId, String token) async {
    final docId = await _ownerDocIdById(ownerId);
    if (docId == null) return;
    await _db.update(_owners, docId, {'FcmToken': token});
  }

  // ── Transactions ───────────────────────────────────────────────────────────

  List<OwnerLedgerEntry> _sortTx(List<SupaDoc> docs) {
    final entries = docs
        .map((d) => OwnerLedgerEntry.fromMap(d.data))
        .where((e) => e.id != 0)
        .toList();
    entries.sort((a, b) {
      final c = b.txDate.compareTo(a.txDate);
      return c != 0 ? c : b.id.compareTo(a.id);
    });
    return entries;
  }

  /// Real-time stream of all transactions for an owner, newest first.
  Stream<List<OwnerLedgerEntry>> watchTransactions(int ownerId) {
    return _db.watch(_tx).map((docs) => _sortTx(
        docs.where((d) => (d.data['OwnerId'] as num?)?.toInt() == ownerId)
            .toList()));
  }

  /// All transactions for an owner, sorted newest first.
  Future<List<OwnerLedgerEntry>> fetchTransactions(int ownerId) async {
    final docs = await _db.queryEq(_tx, 'OwnerId', ownerId);
    return _sortTx(docs);
  }

  int? _extractRevenueIdFromNotes(String? notes) {
    final raw = (notes ?? '').trim();
    if (raw.isEmpty) return null;
    final match = RegExp(r'AUTO_REVENUE[:= ]*(-?\d+)', caseSensitive: false)
        .firstMatch(raw);
    if (match == null) return null;
    return int.tryParse(match.group(1) ?? '');
  }

  Future<List<int>> _findRevenueIdsByReceiptNo(int receiptNo) async {
    if (receiptNo <= 0) return const <int>[];
    final docs = await _db.queryEq(_revenues, 'ReceiptNo', receiptNo);
    return docs
        .map((d) => (d.data['Id'] as num?)?.toInt() ?? 0)
        .where((id) => id != 0)
        .toList();
  }

  Future<List<int>> _findRevenueIdsByTxMatch({
    required String txDate,
    required double txAmount,
    String? txDescription,
  }) async {
    final all = await _db.list(_revenues);
    final wantedDesc = (txDescription ?? '').trim();
    final hi = '$txDate';
    return all
        .where((d) {
          final rd = (d.data['RevenueDate'] as String?) ?? '';
          if (rd.compareTo(txDate) < 0 || rd.compareTo(hi) >= 0) return false;
          final amount = (d.data['Amount'] as num?)?.toDouble() ?? 0;
          if ((amount - txAmount).abs() > 0.001) return false;
          if (wantedDesc.isEmpty) return true;
          final desc = (d.data['Description'] ?? '').toString().trim();
          return desc == wantedDesc;
        })
        .map((d) => (d.data['Id'] as num?)?.toInt() ?? 0)
        .where((id) => id != 0)
        .toList();
  }

  /// Fetch the download URL of a receipt attachment for a transaction.
  Future<(String?, String)> fetchTxAttachmentUrlDebug(
    int txId, {
    String? txNotes,
    int? txRefNo,
    String? txDate,
    double? txAmount,
    String? txDescription,
  }) async {
    try {
      final docs = await _db.list(_attachments);
      final total = docs.length;
      if (total == 0) return (null, 'المجموعة فارغة (0 مستند)');

      final linkedRevenueId = _extractRevenueIdFromNotes(txNotes);
      final revenueIdsByReceipt = txRefNo == null
          ? const <int>[]
          : await _findRevenueIdsByReceiptNo(txRefNo);
      final revenueIdsByMatch =
          (txDate == null || txDate.isEmpty || txAmount == null)
              ? const <int>[]
              : await _findRevenueIdsByTxMatch(
                  txDate: txDate,
                  txAmount: txAmount,
                  txDescription: txDescription,
                );

      final ids = <String>[];
      for (final doc in docs) {
        final eidRaw = doc.data['EntityId'];
        final et = (doc.data['EntityType'] ?? '').toString();
        ids.add('$et:$eidRaw');

        final isOwnerTx = et == 'OWNER_TX';
        final isLinkedRevenue = linkedRevenueId != null && et == 'REVENUE';
        final isRevenueByReceipt =
            revenueIdsByReceipt.isNotEmpty && et == 'REVENUE';
        final isRevenueByMatch = revenueIdsByMatch.isNotEmpty && et == 'REVENUE';
        if (!isOwnerTx &&
            !isLinkedRevenue &&
            !isRevenueByReceipt &&
            !isRevenueByMatch) {
          continue;
        }

        int? eid;
        if (eidRaw is num) {
          eid = eidRaw.toInt();
        } else if (eidRaw is String) {
          eid = int.tryParse(eidRaw);
        }
        if (eid == null) continue;
        if (isOwnerTx && eid != txId) continue;
        if (isLinkedRevenue && eid != linkedRevenueId) continue;
        if (isRevenueByReceipt && !revenueIdsByReceipt.contains(eid)) continue;
        if (isRevenueByMatch && !revenueIdsByMatch.contains(eid)) continue;

        final url = (doc.data['DownloadUrl'] ?? '').toString().trim();
        if (url.isNotEmpty) return (url, '');
        final sp = (doc.data['StoragePath'] ?? '').toString().trim();
        if (sp.isNotEmpty) return (sp, '');
      }

      final preview = ids.take(5).join(' | ');
      return (
        null,
        'وُجد $total مستند - معرّف الحركة: $txId'
            '${txRefNo != null ? '\nرقم الإيصال: $txRefNo' : ''}'
            '\nالمستندات: $preview',
      );
    } catch (e) {
      return (null, 'خطأ: $e');
    }
  }

  Future<String?> fetchTxAttachmentUrl(int txId) async {
    final (url, _) = await fetchTxAttachmentUrlDebug(txId);
    return url;
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<SupaDoc?> _findOwnerDocByVillaNo(String villaNo) async {
    final exact = await _db.queryEq(_owners, 'VillaNo', villaNo, limit: 1);
    if (exact.isNotEmpty) return exact.first;

    final trimmed = villaNo.replaceAll(RegExp(r'\s+'), '').trim();
    final all = await _db.list(_owners);
    for (final d in all) {
      final v = ((d.data['VillaNo'] as String?) ?? '')
          .replaceAll(RegExp(r'\s+'), '')
          .trim()
          .toLowerCase();
      if (v == trimmed.toLowerCase()) return d;
    }
    return null;
  }

  Future<String?> _ownerDocIdById(int ownerId) async {
    final docs = await _db.queryEq(_owners, 'Id', ownerId, limit: 1);
    return docs.isNotEmpty ? docs.first.id : null;
  }

  /// Egyptian phone number normalization (same as VillaRepository).
  static String _normalizePhone(String value) {
    const arabicIndic = {
      '٠': '0',
      '١': '1',
      '٢': '2',
      '٣': '3',
      '٤': '4',
      '٥': '5',
      '٦': '6',
      '٧': '7',
      '٨': '8',
      '٩': '9',
    };
    var n = value.trim();
    arabicIndic.forEach((src, tgt) => n = n.replaceAll(src, tgt));
    n = n.replaceAll(RegExp(r'[^0-9+]'), '');
    if (n.startsWith('+20')) {
      n = '0${n.substring(3)}';
    } else if (n.startsWith('20') && n.length > 10) {
      n = '0${n.substring(2)}';
    }
    if (n.startsWith('0020')) n = '0${n.substring(4)}';
    return n;
  }
}
