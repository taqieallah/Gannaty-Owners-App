import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────────────────────
// APP SETTINGS STATE
// ─────────────────────────────────────────────────────────────────────────────

class AppSettings {
  final ThemeMode themeMode;
  final bool isArabic;

  const AppSettings({
    this.themeMode = ThemeMode.light,
    this.isArabic = true,
  });

  bool get isDark => themeMode == ThemeMode.dark;

  AppSettings copyWith({ThemeMode? themeMode, bool? isArabic}) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      isArabic: isArabic ?? this.isArabic,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────

class AppSettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => const AppSettings();

  void toggleTheme() {
    state = state.copyWith(
      themeMode: state.isDark ? ThemeMode.light : ThemeMode.dark,
    );
  }

  void toggleLanguage() {
    state = state.copyWith(isArabic: !state.isArabic);
  }

  void setDark(bool dark) {
    state = state.copyWith(
        themeMode: dark ? ThemeMode.dark : ThemeMode.light);
  }

  void setArabic(bool arabic) {
    state = state.copyWith(isArabic: arabic);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────────────────────

final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// LOCALIZATION STRINGS
// ─────────────────────────────────────────────────────────────────────────────

class AppL10n {
  final bool isAr;
  const AppL10n({required this.isAr});

  // ── App ────────────────────────────────────────────────────────────────────
  String get appName => isAr ? 'جنتي' : 'Gannaty';

  // ── Bottom Nav (Admin) ─────────────────────────────────────────────────────
  String get navDashboard => isAr ? 'الرئيسية' : 'Home';
  String get navVillas => isAr ? 'الفيلات' : 'Villas';
  String get navPayments => isAr ? 'المدفوعات' : 'Payments';
  String get navRequests => isAr ? 'الطلبات' : 'Requests';
  String get navSettlements => isAr ? 'التسوية' : 'Settle';

  // ── Bottom Nav (Client) ────────────────────────────────────────────────────
  String get navHome => isAr ? 'الرئيسية' : 'Home';
  String get navBalance => isAr ? 'الرصيد' : 'Balance';
  String get navMyRequests => isAr ? 'طلباتي' : 'Requests';

  // ── Screen Titles ──────────────────────────────────────────────────────────
  String get dashboardTitle => isAr ? 'جنتي — لوحة التحكم' : 'Gannaty — Admin';
  String get villasTitle => isAr ? 'الفيلات' : 'Villas';
  String get paymentsTitle => isAr ? 'المدفوعات' : 'Payments';
  String get requestsTitle => isAr ? 'طلبات الخدمة' : 'Service Requests';
  String get settlementsTitle => isAr ? 'التسوية السنوية' : 'Settlements';
  String get homeTitle => isAr ? 'جنتي' : 'Gannaty';
  String get myPaymentsTitle => isAr ? 'المدفوعات' : 'My Payments';
  String get myRequestsTitle => isAr ? 'طلباتي' : 'My Requests';
  String get balanceTitle => isAr ? 'الرصيد والتسوية' : 'Balance';

  // ── Common Actions ─────────────────────────────────────────────────────────
  String get logout => isAr ? 'تسجيل الخروج' : 'Logout';
  String get refresh => isAr ? 'تحديث' : 'Refresh';
  String get save => isAr ? 'حفظ' : 'Save';
  String get cancel => isAr ? 'إلغاء' : 'Cancel';
  String get delete => isAr ? 'حذف' : 'Delete';
  String get edit => isAr ? 'تعديل' : 'Edit';
  String get add => isAr ? 'إضافة' : 'Add';
  String get viewAll => isAr ? 'عرض الكل' : 'View all';
  String get retry => isAr ? 'إعادة المحاولة' : 'Try again';
  String get newRequest => isAr ? 'طلب جديد' : 'New Request';

  // ── Common Labels ──────────────────────────────────────────────────────────
  String get overview => isAr ? 'نظرة عامة' : 'Overview';
  String get quickActions => isAr ? 'إجراءات سريعة' : 'Quick Actions';
  String get recentRequests => isAr ? 'آخر الطلبات' : 'Recent Requests';
  String get noData => isAr ? 'لا توجد بيانات' : 'No data yet';
  String get loading => isAr ? 'جارٍ التحميل...' : 'Loading...';
  String get error => isAr ? 'حدث خطأ' : 'An error occurred';

  // ── Dashboard Stats ────────────────────────────────────────────────────────
  String get totalVillas => isAr ? 'إجمالي الفيلات' : 'Total Villas';
  String get pendingPayments => isAr ? 'مدفوعات معلقة' : 'Pending Payments';
  String get openRequests => isAr ? 'طلبات مفتوحة' : 'Open Requests';
  String get resolved => isAr ? 'تم الحل' : 'Resolved';
  String get addVilla => isAr ? 'إضافة فيلا' : 'Add Villa';
  String get addPayment => isAr ? 'إضافة دفعة' : 'Add Payment';
  String get settlement => isAr ? 'التسوية' : 'Settlement';

  // ── Greeting ───────────────────────────────────────────────────────────────
  String get greetingAdmin => isAr ? 'المسؤول' : 'Admin';
  String greeting(int hour) {
    if (isAr) {
      if (hour < 12) return 'صباح الخير';
      if (hour < 17) return 'مساء الخير';
      return 'مساء النور';
    } else {
      if (hour < 12) return 'Good morning';
      if (hour < 17) return 'Good afternoon';
      return 'Good evening';
    }
  }

  // ── Status Chips ───────────────────────────────────────────────────────────
  String get paid => isAr ? 'مدفوع' : 'Paid';
  String get pending => isAr ? 'معلق' : 'Pending';
  String get overdue => isAr ? 'متأخر' : 'Overdue';
  String get inProgress => isAr ? 'قيد التنفيذ' : 'In Progress';
  String get settled => isAr ? 'تمت التسوية' : 'Settled';
  String get manual => isAr ? 'يدوي' : 'Manual';

  // ── Payment Labels ─────────────────────────────────────────────────────────
  String get paymentSummary => isAr ? 'ملخص المدفوعات' : 'Payment Summary';
  String get totalCollected => isAr ? 'إجمالي المحصل' : 'Total Collected';
  String get paymentRate => isAr ? 'نسبة السداد' : 'Payment Rate';
  String get dueDate => isAr ? 'تاريخ الاستحقاق' : 'Due';
  String get amount => isAr ? 'المبلغ' : 'Amount';

  // ── Request Labels ─────────────────────────────────────────────────────────
  String get all => isAr ? 'الكل' : 'All';
  String get villa => isAr ? 'فيلا' : 'Villa';
  String get submitRequest => isAr ? 'تقديم طلب' : 'Submit Request';

  // ── Balance Labels ─────────────────────────────────────────────────────────
  String get balanceSummary => isAr ? 'تسوية سنة' : 'Year';
  String get owedByVilla => isAr ? 'مبلغ مستحق على الفيلا' : 'Amount owed by villa';
  String get creditForVilla => isAr ? 'رصيد لصالح الفيلا' : 'Credit in your favor';
  String get openingBalance => isAr ? 'رصيد افتتاحي' : 'Opening Balance';
  String get actualCost => isAr ? 'التكلفة الفعلية' : 'Actual Cost';
  String get depositReturn => isAr ? 'إعادة التأمين' : 'Deposit Return';
  String get totalPaid => isAr ? 'إجمالي المدفوع' : 'Total Paid';
  String get closingBalance => isAr ? 'الرصيد الختامي' : 'Closing Balance';
  String get villaDetails => isAr ? 'تفاصيل الفيلا' : 'Villa Details';
  String get settlementHistory => isAr ? 'سجل التسويات' : 'Settlement History';
  String get area => isAr ? 'المساحة' : 'Area';
  String get annualFee => isAr ? 'الرسم السنوي' : 'Annual Fee';
  String get deposit => isAr ? 'مبلغ التأمين' : 'Deposit';
  String get monthlyTarget => isAr ? 'الهدف الشهري' : 'Monthly Target';
  String get noSettlements => isAr ? 'لا توجد تسويات بعد' : 'No settlements yet';
  String get noSettlementsHint =>
      isAr ? 'ستظهر تسوية نهاية السنة هنا بعد مراجعة الإدارة'
           : 'Year-end settlements will appear here after admin review';

  // ── Villa Labels ───────────────────────────────────────────────────────────
  String get notRegistered =>
      isAr ? 'الفيلا غير مسجلة — تواصل مع الإدارة'
           : 'Villa not registered — contact admin';
  String get overduePayments => isAr ? 'دفعات متأخرة السداد' : 'Overdue Payments';
  String get overdueHint =>
      isAr ? 'لديك دفعات متأخرة، يرجى السداد في أقرب وقت'
           : 'You have overdue payments, please settle as soon as possible';

  // ── Settings ───────────────────────────────────────────────────────────────
  String get darkMode => isAr ? 'الوضع الداكن' : 'Dark Mode';
  String get language => isAr ? 'اللغة' : 'Language';
  String get arabic => isAr ? 'عربي' : 'Arabic';
  String get english => isAr ? 'إنجليزي' : 'English';

  // ── Screen-specific labels ─────────────────────────────────────────────────
  String get noRequestsYet => isAr ? 'لا توجد طلبات بعد' : 'No requests yet';
  String get requestsWillAppear =>
      isAr ? 'ستظهر الطلبات الواردة هنا' : 'Requests will appear here';
  String get noPaymentsYet => isAr ? 'لا توجد مدفوعات' : 'No payments yet';
  String get paymentsWillAppear =>
      isAr ? 'ستظهر سجلات الدفع هنا عند إضافتها من الإدارة'
           : 'Payment records will appear here when added by admin';
  String get summaryQuick => isAr ? 'ملخص سريع' : 'Quick Summary';
  String get viewPaymentHistory => isAr ? 'عرض سجل الدفع' : 'View payment history';
  String get maintenanceOrComplaint => isAr ? 'صيانة أو شكوى' : 'Maintenance or complaint';
  String get annualSettlement => isAr ? 'التسوية السنوية' : 'Annual Settlement';
  String get requestHistoryLabel => isAr ? 'سجل الطلبات' : 'Request History';
  String get previousRequests => isAr ? 'الطلبات السابقة' : 'Previous requests';
  String get noRequestsClientHint =>
      isAr ? 'قدّم طلب صيانة أو شكوى وسنعود إليك في أقرب وقت'
           : 'Submit a request and we\'ll get back to you soon';
  String get noRequestsInCategory =>
      isAr ? 'لا توجد طلبات في هذه الفئة' : 'No requests in this category';
  String get currencySuffix => isAr ? 'ج.م' : 'EGP';
  String get fromTotal => isAr ? 'من أصل' : 'from';
  String get villaOwner => isAr ? 'مالك الفيلا' : 'Villa Owner';
  String get dueDatePrefix => isAr ? 'استحقاق:' : 'Due:';
  String year(int y) => isAr ? 'سنة $y' : 'Year $y';
  String requestsCount(int n) => isAr ? 'الطلبات ($n)' : 'Requests ($n)';
  String villaNum(String n) => isAr ? 'فيلا $n' : 'Villa $n';
  String overdueAlert(int n) =>
      isAr ? 'لديك $n دفعة متأخرة، يرجى السداد في أقرب وقت'
           : 'You have $n overdue payment(s), please settle soon';
  String pendingPaymentsCount(int n) => isAr ? '$n دفعة' : '$n payment(s)';
}

/// Provider to access localized strings
final l10nProvider = Provider<AppL10n>((ref) {
  final isAr = ref.watch(appSettingsProvider).isArabic;
  return AppL10n(isAr: isAr);
});
