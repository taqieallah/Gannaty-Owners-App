import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/owner_account.dart';
import '../models/owner_ledger_entry.dart';
import '../models/villa.dart';

/// Reads/writes owner financial data from the Firestore collections
/// written by I:\Rebrand's OwnersRepo under `users/{workspaceUid}/...`.
///
/// The workspace UID is resolved at runtime from `config/compound.workspaceUid`
/// which I:\Rebrand publishes on every admin login.
///
/// Villa IDs that originate from this repo are prefixed with "owner_" (e.g. "owner_42")
/// so SessionController can route password changes to the right collection.
class OwnerAccountRepository {
  static const ownerIdPrefix = 'owner_';
  static const _configPath = 'config/compound';

  OwnerAccountRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  String? _cachedWorkspaceUid;

  // â”€â”€ Workspace resolution â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Primary workspace UID â€” the Firebase Auth UID of the compound admin account.
  static const _legacyWorkspaceUid = '5nCpbFKDt1NyrXCw56HaattDVT42';

  Future<String> _workspaceUid() async {
    if (_cachedWorkspaceUid != null) return _cachedWorkspaceUid!;

    // Try config/compound first (published by I:\Rebrand on admin login).
    try {
      final doc = await _firestore
          .doc(_configPath)
          .get()
          .timeout(const Duration(seconds: 6));
      final uid = (doc.data()?['workspaceUid'] as String?)?.trim();
      if (uid != null && uid.isNotEmpty) {
        _cachedWorkspaceUid = uid;
        return _cachedWorkspaceUid!;
      }
    } catch (_) {}

    // Fallback: use the known compound admin UID directly.
    _cachedWorkspaceUid = _legacyWorkspaceUid;
    return _cachedWorkspaceUid!;
  }

  Future<CollectionReference<Map<String, dynamic>>> _owners() async {
    final uid = await _workspaceUid();
    return _firestore.collection('users/$uid/owners');
  }

  Future<CollectionReference<Map<String, dynamic>>> _tx() async {
    final uid = await _workspaceUid();
    return _firestore.collection('users/$uid/owner_transactions');
  }

  Future<CollectionReference<Map<String, dynamic>>> _year() async {
    final uid = await _workspaceUid();
    return _firestore.collection('users/$uid/owner_year_settings');
  }

  // â”€â”€ Auth helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Find owner by phone number. Returns the Firestore document or null.
  Future<DocumentSnapshot<Map<String, dynamic>>?> findOwnerDocByPhone(
      String phone) async {
    final owners = await _owners();
    final normalized = _normalizePhone(phone.trim());

    // Exact match
    var snap =
        await owners.where('Phone', isEqualTo: phone.trim()).limit(1).get();
    if (snap.docs.isNotEmpty) return snap.docs.first;

    // Normalized match
    if (normalized != phone.trim() && normalized.isNotEmpty) {
      snap =
          await owners.where('Phone', isEqualTo: normalized).limit(1).get();
      if (snap.docs.isNotEmpty) return snap.docs.first;
    }

    // Full-scan local compare (handles Arabic/mixed numbers)
    final all = await owners.get();
    for (final doc in all.docs) {
      final ownerPhone =
          _normalizePhone((doc.data()['Phone'] as String?) ?? '');
      if (ownerPhone.isNotEmpty && ownerPhone == normalized) return doc;
    }
    return null;
  }

  /// Build a [Villa] session object from an owner Firestore document.
  /// Villa.id is prefixed with "owner_" so SessionController knows which
  /// collection to use for password updates.
  static Villa buildVillaFromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
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
    final owners = await _owners();
    final snap =
        await owners.where('Id', isEqualTo: ownerId).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return buildVillaFromDoc(snap.docs.first);
  }

  /// Update password for an owner and clear the first-login flag.
  Future<void> updatePassword(int ownerId, String newPassword) async {
    final owners = await _owners();
    final docId = await _findDocIdByIntId(owners, ownerId);
    if (docId == null) return;
    await owners.doc(docId).update({
      'Password': newPassword,
      'IsFirstLogin': false,
    });
  }

  // â”€â”€ Balance queries â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Fetch [OwnerAccount] by owner int ID for the given [year].
  Future<OwnerAccount?> fetchById(int ownerId, {int? year}) async {
    final owners = await _owners();
    final snap =
        await owners.where('Id', isEqualTo: ownerId).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return _buildAccount(snap.docs.first, year ?? DateTime.now().year);
  }

  /// Fetch [OwnerAccount] by villa number for the given [year].
  Future<OwnerAccount?> fetchByVillaNo(String villaNo, {int? year}) async {
    final ownerDoc = await _findOwnerDocByVillaNo(villaNo);
    if (ownerDoc == null) return null;
    return _buildAccount(ownerDoc, year ?? DateTime.now().year);
  }

  Future<OwnerAccount> _buildAccount(
    DocumentSnapshot<Map<String, dynamic>> ownerDoc,
    int currentYear,
  ) async {
    final ownerId = (ownerDoc.data()!['Id'] as num?)?.toInt() ?? 0;

    // Fetch all year settings for this owner and filter client-side
    // (avoids composite index on OwnerId + Year).
    final yearCol = await _year();
    final yearSnap = await yearCol
        .where('OwnerId', isEqualTo: ownerId)
        .get();
    final yearList = yearSnap.docs
        .map((d) => d.data())
        .where((d) => (d['Year'] as num?)?.toInt() == currentYear)
        .toList();
    final yearSettings = yearList.isNotEmpty ? yearList.first : null;

    // Fetch all transactions for this owner and filter client-side
    // (avoids composite index on OwnerId + TxDate range).
    final txCol = await _tx();
    final txSnap = await txCol
        .where('OwnerId', isEqualTo: ownerId)
        .get();

    final from = '$currentYear-01-01';
    final to = '${currentYear + 1}-01-01';

    double totalCharges = 0;
    double totalPayments = 0;
    for (final d in txSnap.docs) {
      final txDate = ((d.data()['TxDate'] as String?) ?? '');
      if (txDate.compareTo(from) < 0 || txDate.compareTo(to) >= 0) continue;
      final type = ((d.data()['TxType'] as String?) ?? '').toUpperCase();
      final amount = (d.data()['Amount'] as num?)?.toDouble() ?? 0;
      if (type == 'PAYMENT') {
        totalPayments += amount;
      } else {
        totalCharges += amount;
      }
    }

    return OwnerAccount.fromFirestore(
      ownerDoc: ownerDoc,
      yearSettings: yearSettings,
      totalCharges: totalCharges,
      totalPayments: totalPayments,
      year: currentYear,
    );
  }

  // â”€â”€ FCM token â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Saves the device FCM token inside the owner Firestore document so the
  /// admin app can look it up and send push notifications.
  Future<void> saveFcmToken(int ownerId, String token) async {
    final owners = await _owners();
    final docId = await _findDocIdByIntId(owners, ownerId);
    if (docId == null) return;
    await owners.doc(docId).update({'FcmToken': token});
  }

  // â”€â”€ Transactions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Real-time stream of all transactions for an owner, newest first.
  Stream<List<OwnerLedgerEntry>> watchTransactions(int ownerId) async* {
    final col = await _tx();
    yield* col
        .where('OwnerId', isEqualTo: ownerId)
        .snapshots()
        .map((snap) {
      final entries = snap.docs
          .map((d) => OwnerLedgerEntry.fromMap(d.data()))
          .where((e) => e.id != 0)
          .toList();
      entries.sort((a, b) {
        final c = b.txDate.compareTo(a.txDate);
        return c != 0 ? c : b.id.compareTo(a.id);
      });
      return entries;
    });
  }

  /// All transactions for an owner, sorted newest first.
  Future<List<OwnerLedgerEntry>> fetchTransactions(int ownerId) async {
    final txCol = await _tx();
    // Single-field where only â€” no composite index needed.
    // Sorting is done client-side.
    final snap = await txCol
        .where('OwnerId', isEqualTo: ownerId)
        .get();

    final entries = snap.docs
        .map((d) => OwnerLedgerEntry.fromMap(d.data()))
        .where((e) => e.id != 0)
        .toList();

    entries.sort((a, b) {
      final c = b.txDate.compareTo(a.txDate);
      return c != 0 ? c : b.id.compareTo(a.id);
    });
    return entries;
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
    final uid = await _workspaceUid();
    final snap = await _firestore
        .collection('users/$uid/revenues')
        .where('ReceiptNo', isEqualTo: receiptNo)
        .get();
    return snap.docs
        .map((d) => (d.data()['Id'] as num?)?.toInt() ?? 0)
        .where((id) => id != 0)
        .toList();
  }

  Future<List<int>> _findRevenueIdsByTxMatch({
    required String txDate,
    required double txAmount,
    String? txDescription,
  }) async {
    final uid = await _workspaceUid();
    final snap = await _firestore
        .collection('users/$uid/revenues')
        .where('RevenueDate', isGreaterThanOrEqualTo: txDate)
        .where('RevenueDate', isLessThan: '$txDate\uf8ff')
        .get();

    final wantedDesc = (txDescription ?? '').trim();
    return snap.docs
        .where((d) {
          final data = d.data();
          final amount = (data['Amount'] as num?)?.toDouble() ?? 0;
          if ((amount - txAmount).abs() > 0.001) return false;
          if (wantedDesc.isEmpty) return true;
          final desc = (data['Description'] ?? '').toString().trim();
          return desc == wantedDesc;
        })
        .map((d) => (d.data()['Id'] as num?)?.toInt() ?? 0)
        .where((id) => id != 0)
        .toList();
  }

  /// Fetch the download URL of a receipt attachment for a transaction.
  /// Returns `(url, debugInfo)`:
  ///   - url: the download URL if found, null otherwise.
  ///   - debugInfo: human-readable diagnostic string for troubleshooting.
  Future<(String?, String)> fetchTxAttachmentUrlDebug(
    int txId, {
    String? txNotes,
    int? txRefNo,
    String? txDate,
    double? txAmount,
    String? txDescription,
  }) async {
    try {
      final uid = await _workspaceUid();
      final col = _firestore.collection('users/$uid/attachments');
      final snap = await col.get().timeout(const Duration(seconds: 10));

      final total = snap.docs.length;
      if (total == 0) {
        return (null, 'المجموعة فارغة (0 مستند) - uid=$uid');
      }

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
      for (final doc in snap.docs) {
        final eidRaw = doc.data()['EntityId'];
        final et = (doc.data()['EntityType'] ?? '').toString();
        ids.add('$et:$eidRaw');

        final isOwnerTx = et == 'OWNER_TX';
        final isLinkedRevenue = linkedRevenueId != null && et == 'REVENUE';
        final isRevenueByReceipt = revenueIdsByReceipt.isNotEmpty && et == 'REVENUE';
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

        final url = (doc.data()['DownloadUrl'] ?? '').toString().trim();
        if (url.isNotEmpty) return (url, '');
        final sp = (doc.data()['StoragePath'] ?? '').toString().trim();
        if (sp.isNotEmpty) return (sp, '');
      }

      final preview = ids.take(5).join(' | ');
      return (
        null,
        'وُجد $total مستند - معرّف الحركة: $txId'
        '${txRefNo != null ? '\nرقم الإيصال: $txRefNo' : ''}'
        '${revenueIdsByMatch.isNotEmpty ? '\nمطابقة الإيراد بالحركة: ${revenueIdsByMatch.join(', ')}' : ''}'
        '\nالمستندات: $preview',
      );
    } catch (e) {
      return (null, 'خطأ: $e');
    }
  }
  /// Fetch the download URL of a receipt attachment for a transaction.
  Future<String?> fetchTxAttachmentUrl(int txId) async {
    final (url, _) = await fetchTxAttachmentUrlDebug(txId);
    return url;
  }

  // â”€â”€ Private helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<DocumentSnapshot<Map<String, dynamic>>?> _findOwnerDocByVillaNo(
      String villaNo) async {
    final owners = await _owners();
    var snap =
        await owners.where('VillaNo', isEqualTo: villaNo).limit(1).get();
    if (snap.docs.isNotEmpty) return snap.docs.first;

    final trimmed = villaNo.replaceAll(RegExp(r'\s+'), '').trim();
    if (trimmed != villaNo) {
      snap = await owners
          .where('VillaNo', isEqualTo: trimmed)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) return snap.docs.first;
    }

    final all = await owners.get();
    for (final doc in all.docs) {
      final v = ((doc.data()['VillaNo'] as String?) ?? '')
          .replaceAll(RegExp(r'\s+'), '')
          .trim()
          .toLowerCase();
      if (v == trimmed.toLowerCase()) return doc;
    }
    return null;
  }

  Future<String?> _findDocIdByIntId(
      CollectionReference<Map<String, dynamic>> col, int ownerId) async {
    final snap =
        await col.where('Id', isEqualTo: ownerId).limit(1).get();
    return snap.docs.isNotEmpty ? snap.docs.first.id : null;
  }

  /// Egyptian phone number normalization (same as VillaRepository).
  static String _normalizePhone(String value) {
    const arabicIndic = {
      'Ù ': '0', 'Ù¡': '1', 'Ù¢': '2', 'Ù£': '3', 'Ù¤': '4',
      'Ù¥': '5', 'Ù¦': '6', 'Ù§': '7', 'Ù¨': '8', 'Ù©': '9',
    };
    var n = value.trim();
    arabicIndic.forEach((src, tgt) => n = n.replaceAll(src, tgt));
    n = n.replaceAll(RegExp(r'[^0-9+]'), '');
    if (n.startsWith('+20')) n = '0${n.substring(3)}';
    else if (n.startsWith('20') && n.length > 10) n = '0${n.substring(2)}';
    if (n.startsWith('0020')) n = '0${n.substring(4)}';
    return n;
  }
}

