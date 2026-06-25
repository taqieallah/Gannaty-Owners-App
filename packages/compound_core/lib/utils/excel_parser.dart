import 'package:excel/excel.dart';
import '../models/payment.dart';

class ExcelParseResult {
  final List<Payment> payments;
  final List<String> errors;

  const ExcelParseResult({required this.payments, required this.errors});
  bool get hasErrors => errors.isNotEmpty;
}

/// Parses an Excel file into Payment objects.
///
/// Expected headers (case-insensitive, any column order):
/// VillaNumber | VillaId | Month | Year | Amount | DueDate | IsPaid | Description
class ExcelParser {
  static ExcelParseResult parse(List<int> bytes, String defaultVillaId) {
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.sheets.values.first;
    final rows = sheet.rows;

    if (rows.isEmpty) {
      return const ExcelParseResult(
          payments: [], errors: ['Excel file is empty']);
    }

    // Build header index map (lowercase)
    final headers = <String, int>{};
    final headerRow = rows.first;
    for (var i = 0; i < headerRow.length; i++) {
      final cell = headerRow[i];
      if (cell?.value != null) {
        headers[cell!.value.toString().trim().toLowerCase()] = i;
      }
    }

    int? col(String name) => headers[name.toLowerCase()];

    // Validate required headers
    final required = ['villanumber', 'month', 'year', 'amount', 'duedate'];
    final missing = required.where((h) => col(h) == null).toList();
    if (missing.isNotEmpty) {
      return ExcelParseResult(
        payments: [],
        errors: ['Missing required columns: ${missing.join(', ')}'],
      );
    }

    final payments = <Payment>[];
    final errors = <String>[];

    for (var rowIdx = 1; rowIdx < rows.length; rowIdx++) {
      final row = rows[rowIdx];
      if (row.every((cell) => cell?.value == null)) continue; // skip blank rows

      String cellStr(int? colIdx) =>
          colIdx != null && colIdx < row.length
              ? (row[colIdx]?.value?.toString().trim() ?? '')
              : '';

      final villaNumber = cellStr(col('villanumber'));
      final villaId = col('villaid') != null
          ? cellStr(col('villaid'))
          : defaultVillaId;
      final monthStr = cellStr(col('month'));
      final yearStr = cellStr(col('year'));
      final amountStr = cellStr(col('amount'));
      final dueDateStr = cellStr(col('duedate'));
      final isPaidStr = cellStr(col('ispaid')).toLowerCase();
      final description = col('description') != null
          ? cellStr(col('description'))
          : null;

      // Validate
      final rowErrors = <String>[];
      if (villaNumber.isEmpty) rowErrors.add('VillaNumber is empty');
      final month = int.tryParse(monthStr);
      if (month == null || month < 1 || month > 12) {
        rowErrors.add('Invalid Month "$monthStr"');
      }
      final year = int.tryParse(yearStr);
      if (year == null || year < 2000) rowErrors.add('Invalid Year "$yearStr"');
      final amount = double.tryParse(amountStr);
      if (amount == null || amount < 0) {
        rowErrors.add('Invalid Amount "$amountStr"');
      }

      DateTime? dueDate;
      if (dueDateStr.isNotEmpty) {
        dueDate = _parseDate(dueDateStr);
        if (dueDate == null) rowErrors.add('Invalid DueDate "$dueDateStr"');
      } else {
        rowErrors.add('DueDate is empty');
      }

      if (rowErrors.isNotEmpty) {
        errors.add('Row ${rowIdx + 1}: ${rowErrors.join('; ')}');
        continue;
      }

      payments.add(Payment(
        id: '',
        villaId: villaId.isEmpty ? defaultVillaId : villaId,
        villaNumber: villaNumber,
        month: month!,
        year: year!,
        amount: amount!,
        dueDate: dueDate!,
        isPaid: isPaidStr == 'true' || isPaidStr == '1' || isPaidStr == 'yes',
        description: description?.isEmpty == true ? null : description,
        createdAt: DateTime.now(),
      ));
    }

    return ExcelParseResult(payments: payments, errors: errors);
  }

  static DateTime? _parseDate(String value) {
    // Try ISO format yyyy-mm-dd
    try {
      return DateTime.parse(value);
    } catch (_) {}

    // Try dd/mm/yyyy
    final parts = value.split(RegExp(r'[/\-]'));
    if (parts.length == 3) {
      final nums = parts.map(int.tryParse).toList();
      if (nums.every((n) => n != null)) {
        if (nums[2]! > 31) {
          // yyyy-mm-dd or yyyy/mm/dd
          return DateTime(nums[0]!, nums[1]!, nums[2]!);
        } else {
          // dd/mm/yyyy
          return DateTime(nums[2]!, nums[1]!, nums[0]!);
        }
      }
    }
    return null;
  }
}
