/// Lightweight Arabic date formatting (no locale-init dependency).
const _months = [
  'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
];

String arDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

String arDateStr(String iso) {
  final d = DateTime.tryParse(iso);
  return d == null ? iso : arDate(d);
}

/// A compact relative label ("منذ ساعتين", "أمس", "منذ 3 أيام") falling back to
/// an absolute date for older items.
String arRelative(DateTime d) {
  final now = DateTime.now();
  final diff = now.difference(d);
  if (diff.inMinutes < 1) return 'الآن';
  if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
  if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
  if (diff.inDays == 1) return 'أمس';
  if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
  return arDate(d);
}
