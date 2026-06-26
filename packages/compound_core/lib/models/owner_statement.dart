import 'dart:convert';

/// Precomputed owner account statement for a single year, written by the ERP
/// (`owner_statements/{ownerId}-{year}`). The ERP computes these with the exact
/// same engine as its Excel / PDF exports, so the client renders identical
/// numbers and the same account breakdown without recomputing anything.
class OwnerStatement {
  const OwnerStatement({
    required this.ownerId,
    required this.year,
    required this.openingBalance,
    required this.maintenance,
    required this.maintenanceBasis,
    required this.depositReturn,
    required this.depositDetails,
    required this.totalCharges,
    required this.totalPayments,
    required this.closingBalance,
    required this.isUnsettled,
    required this.billedMonths,
    required this.monthly,
    required this.meterPrice,
    required this.area,
    required this.rows,
  });

  final int ownerId;
  final int year;
  final double openingBalance;
  final double maintenance;
  final String maintenanceBasis;
  final double depositReturn;
  final String depositDetails;
  final double totalCharges;
  final double totalPayments;
  final double closingBalance;
  final bool isUnsettled;
  final int billedMonths;
  final double monthly;
  final double meterPrice;
  final double area;

  /// Detailed account rows (label / details / amount), mirroring the Excel/PDF.
  final List<OwnerStatementRow> rows;

  bool get isCredit => closingBalance < 0;

  static double _d(Object? v) => (v as num?)?.toDouble() ?? 0.0;

  factory OwnerStatement.fromMap(Map<String, dynamic> m) {
    final rowsRaw = m['RowsJson'];
    final rows = <OwnerStatementRow>[];
    if (rowsRaw is String && rowsRaw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rowsRaw);
        if (decoded is List) {
          for (final r in decoded) {
            if (r is Map) {
              rows.add(OwnerStatementRow.fromMap(Map<String, dynamic>.from(r)));
            }
          }
        }
      } catch (_) {}
    } else if (m['Rows'] is List) {
      for (final r in (m['Rows'] as List)) {
        if (r is Map) {
          rows.add(OwnerStatementRow.fromMap(Map<String, dynamic>.from(r)));
        }
      }
    }

    return OwnerStatement(
      ownerId: (m['OwnerId'] as num?)?.toInt() ?? 0,
      year: (m['Year'] as num?)?.toInt() ?? 0,
      openingBalance: _d(m['OpeningBalance']),
      maintenance: _d(m['Maintenance']),
      maintenanceBasis: (m['MaintenanceBasis'] as String?) ?? '',
      depositReturn: _d(m['DepositReturn']),
      depositDetails: (m['DepositDetails'] as String?) ?? '',
      totalCharges: _d(m['TotalCharges']),
      totalPayments: _d(m['TotalPayments']),
      closingBalance: _d(m['ClosingBalance']),
      isUnsettled: (m['IsUnsettled'] as bool?) ?? false,
      billedMonths: (m['BilledMonths'] as num?)?.toInt() ?? 0,
      monthly: _d(m['Monthly']),
      meterPrice: _d(m['MeterPrice']),
      area: _d(m['Area']),
      rows: rows,
    );
  }
}

class OwnerStatementRow {
  const OwnerStatementRow({
    required this.label,
    required this.details,
    required this.amount,
    required this.bold,
    required this.kind,
  });

  final String label;
  final String details;
  final double? amount;
  final bool bold;

  /// 'row' | 'section' | 'result'
  final String kind;

  factory OwnerStatementRow.fromMap(Map<String, dynamic> m) => OwnerStatementRow(
        label: (m['Label'] as String?) ?? '',
        details: (m['Details'] as String?) ?? '',
        amount: (m['Amount'] as num?)?.toDouble(),
        bold: (m['Bold'] as bool?) ?? false,
        kind: (m['Kind'] as String?) ?? 'row',
      );
}
