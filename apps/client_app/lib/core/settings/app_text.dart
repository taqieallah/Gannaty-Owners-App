import 'app_settings.dart';

class AppText {
  const AppText(this.settings);

  final AppSettings settings;

  bool get ar => settings.isArabic;

  String get appSettings => ar ? 'الإعدادات' : 'Settings';
  String get language => ar ? 'اللغة' : 'Language';
  String get arabic => ar ? 'العربية' : 'Arabic';
  String get english => ar ? 'الإنجليزية' : 'English';
  String get theme => ar ? 'الوضع' : 'Theme';
  String get light => ar ? 'فاتح' : 'Light';
  String get dark => ar ? 'داكن' : 'Dark';
  String get home => ar ? 'الرئيسية' : 'Home';
  String get balance => ar ? 'الرصيد' : 'Balance';
  String get payments => ar ? 'المدفوعات' : 'Payments';
  String get requests => ar ? 'طلباتي' : 'My Requests';
  String get newRequest => ar ? 'طلب جديد' : 'New Request';
  String get login => ar ? 'تسجيل الدخول' : 'Login';
  String get loginSubtitle => ar ? 'سجل الدخول إلى كمبوند جنتي' : 'Login to Gannaty Compound';
  String get phone => ar ? 'رقم الهاتف' : 'Phone Number';
  String get password => ar ? 'كلمة المرور' : 'Password';
  String get enterPhone => ar ? 'أدخل رقم الهاتف' : 'Enter phone number';
  String get enterPassword => ar ? 'أدخل كلمة المرور' : 'Enter password';
  String get firstLoginHint => ar ? 'أول دخول يتم بكلمة المرور الافتراضية 123456' : 'First login uses the default password 123456';
  String get setPassword => ar ? 'تعيين كلمة مرور جديدة' : 'Set a New Password';
  String get setPasswordSubtitle => ar ? 'أنشئ كلمة مرور جديدة قبل المتابعة' : 'Set a new password before continuing';
  String get setPasswordReason => ar ? 'لأن هذه أول مرة تدخل أو ما زلت تستخدم 123456' : 'Because this is your first login or you are still using 123456';
  String get newPassword => ar ? 'كلمة المرور الجديدة' : 'New Password';
  String get confirmPassword => ar ? 'تأكيد كلمة المرور' : 'Confirm Password';
  String get enterNewPassword => ar ? 'أدخل كلمة مرور جديدة' : 'Enter a new password';
  String get minFourChars => ar ? '4 أحرف على الأقل' : 'Minimum 4 characters';
  String get confirmPasswordHint => ar ? 'أكد كلمة المرور' : 'Confirm password';
  String get passwordsDontMatch => ar ? 'كلمتا المرور غير متطابقتين' : 'Passwords do not match';
  String get saveAndContinue => ar ? 'حفظ والمتابعة' : 'Save & Continue';
  String get passwordUpdated => ar ? 'تم تحديث كلمة المرور' : 'Password updated';
  String get balanceSummary => ar ? 'ملخص الحساب' : 'Account Summary';
  String get outstanding => ar ? 'إجمالي المديونية' : 'Outstanding Balance';
  String get paid => ar ? 'تم سداده' : 'Paid';
  String get overdue => ar ? 'متأخر' : 'Overdue';
  String get unpaid => ar ? 'غير مسدد' : 'Unpaid';
  String get due => ar ? 'المستحق' : 'Due';
  String get requestStatus => ar ? 'حالة طلباتك' : 'Request Status';
  String get pending => ar ? 'معلقة' : 'Pending';
  String get inProgress => ar ? 'جاري الحل' : 'In Progress';
  String get solved => ar ? 'تم الحل' : 'Solved';
  String get quickActions => ar ? 'إجراءات سريعة' : 'Quick Actions';
  String get currentBalance => ar ? 'الرصيد الحالي' : 'Current Balance';
  String get totalOutstanding => ar ? 'إجمالي الرصيد المستحق' : 'Total outstanding balance';
  String get billsCount => ar ? 'عدد الفواتير' : 'Bills Count';
  String get loginButton => ar ? 'دخول' : 'Login';
  String get gannatyCompound => ar ? 'كمبوند جنتي' : 'Gannaty Compound';
  String get welcome => ar ? 'أهلاً' : 'Welcome';
  String get homeHeroSubtitle => ar ? 'تابع الفواتير وطلبات الخدمة من مكان واحد' : 'Manage your bills and service requests in one place';
  String get noSettlementYet => ar ? 'لا توجد تسوية سنوية بعد' : 'No annual settlement yet';
  String get failedLoadStatement => ar ? 'تعذر تحميل كشف الحساب' : 'Failed to load statement';
  String get noPaidPaymentsYet => ar ? 'لا توجد مدفوعات مسجلة حتى الآن' : 'No paid payments yet';
  String get failedLoadPayments => ar ? 'تعذر تحميل المدفوعات' : 'Failed to load payments';
  String get accountStatement => ar ? 'كشف الحساب' : 'Account Statement';
  String get openingBalance => ar ? 'رصيد مفتوح' : 'Opening Balance';
  String get annualCharges => ar ? 'الرسوم السنوية' : 'Annual Charges';
  String get depositReturn => ar ? 'عائد الوديعة' : 'Deposit Return';
  String get totalPaid => ar ? 'المدفوع' : 'Total Paid';
  String get area => ar ? 'المساحة' : 'Area';
  String get pricePerMeter => ar ? 'السعر/م²' : 'Price/m²';
  String get deposit => ar ? 'الوديعة' : 'Deposit';
  String get closingBalance => ar ? 'الرصيد الختامي' : 'Closing Balance';
  String get amount => ar ? 'المبلغ' : 'Amount';
  String get dueDate => ar ? 'الاستحقاق' : 'Due Date';
  String get description => ar ? 'الوصف' : 'Description';
  String get paymentAttachments => ar ? 'مرفقات الدفع' : 'Payment Attachments';
  String get noRequestsYet => ar ? 'لا توجد طلبات خدمة حتى الآن' : 'No requests yet';
  String get failedLoadRequests => ar ? 'تعذر تحميل الطلبات' : 'Failed to load requests';
  String get afterRepairPhoto => ar ? 'صورة بعد الإصلاح' : 'After Repair Photo';
  String get progressPhoto => ar ? 'صورة متابعة الطلب' : 'Progress Photo';
  String get failedLoadImage => ar ? 'تعذر تحميل الصورة' : 'Failed to load image';
  String get maintenance => ar ? 'صيانة' : 'Maintenance';
  String get complaint => ar ? 'شكوى' : 'Complaint';
  String get other => ar ? 'طلب آخر' : 'Other';
  String get requestType => ar ? 'نوع الطلب' : 'Request Type';
  String get issueDescription => ar ? 'وصف المشكلة' : 'Description';
  String get enterDescription => ar ? 'اكتب وصف المشكلة' : 'Enter a description';
  String get attachImage => ar ? 'إرفاق صورة' : 'Attach Image';
  String get submitRequest => ar ? 'إرسال الطلب' : 'Submit Request';
  String get requestSent => ar ? 'تم إرسال الطلب بنجاح' : 'Request sent successfully';
  String get failedSubmitRequest => ar ? 'تعذر إرسال الطلب' : 'Failed to submit';

  String get profile => ar ? 'الملف الشخصي' : 'Profile';
  String get villaInfo => ar ? 'معلومات الفيلا' : 'Villa Information';
  String get ownerNameLabel => ar ? 'اسم المالك' : 'Owner Name';
  String get villaNumberLabel => ar ? 'رقم الفيلا' : 'Villa Number';
  String get phoneLabel => ar ? 'رقم الهاتف' : 'Phone';
  String get areaLabel => ar ? 'المساحة (م²)' : 'Area (m²)';
  String get annualFeeLabel => ar ? 'الرسوم السنوية' : 'Annual Fee';
  String get depositLabel => ar ? 'الوديعة' : 'Deposit Amount';
  String get changePassword => ar ? 'تغيير كلمة المرور' : 'Change Password';
  String get signOut => ar ? 'تسجيل الخروج' : 'Sign Out';
  String get currentPasswordLabel => ar ? 'كلمة المرور الحالية' : 'Current Password';
  String get passwordChanged => ar ? 'تم تغيير كلمة المرور بنجاح' : 'Password changed successfully';

  String get biometricLogin => ar ? 'الدخول بالبصمة' : 'Biometric Login';
  String get enableBiometric => ar ? 'تفعيل الدخول بالبصمة' : 'Enable biometric login';
  String get biometricEnabled => ar ? 'الدخول بالبصمة مُفعّل' : 'Biometric login enabled';
  String get biometricDisabled => ar ? 'الدخول بالبصمة مُعطّل' : 'Biometric login disabled';
  String get loginWithBiometric => ar ? 'الدخول بالبصمة' : 'Login with Biometrics';
  String get biometricNotAvailable => ar ? 'البصمة غير متاحة على هذا الجهاز' : 'Biometrics not available on this device';
  String get biometricHint => ar ? 'المس المستشعر للتحقق من هويتك' : 'Touch the sensor to verify your identity';

  String get notifications => ar ? 'الإشعارات' : 'Notifications';
  String get noNotificationsYet => ar ? 'لا توجد إشعارات بعد' : 'No notifications yet';
  String get clearNotifications => ar ? 'مسح الإشعارات' : 'Clear All';

  String get announcements => ar ? 'الإعلانات' : 'Announcements';
  String get noAnnouncementsYet => ar ? 'لا توجد إعلانات بعد' : 'No announcements yet';
  String get failedLoadAnnouncements => ar ? 'تعذر تحميل الإعلانات' : 'Failed to load announcements';

  String get requestDetail => ar ? 'تفاصيل الطلب' : 'Request Details';
  String get statusTimeline => ar ? 'مسار الطلب' : 'Request Timeline';
  String get submittedOn => ar ? 'تاريخ الإرسال' : 'Submitted on';
  String get lastUpdated => ar ? 'آخر تحديث' : 'Last updated';

  String get filterByYear => ar ? 'تصفية بالسنة' : 'Filter by Year';
  String get allYears => ar ? 'كل السنوات' : 'All Years';
  String get paidOnly => ar ? 'المسدد فقط' : 'Paid Only';
  String get unpaidOnly => ar ? 'غير المسدد' : 'Unpaid Only';

  String get offlineMessage => ar ? 'لا يوجد اتصال بالإنترنت' : 'No internet connection';

  String get ownerAccountTitle => ar ? 'حساب المالك' : 'Owner Account';
  String get ownerNotSetup => ar ? 'حساب الفيلا غير مُعدّ في النظام' : 'Villa account not set up';
  String get ownerNotSetupHint => ar ? 'تواصل مع إدارة الكمبوند لإضافة بيانات حسابك' : 'Contact compound management to set up your account';
  String get creditBalance => ar ? 'رصيد دائن' : 'Credit Balance';
  String get debitBalance => ar ? 'مديونية' : 'Amount Owed';
  String get maintenanceFee => ar ? 'رسوم الصيانة' : 'Maintenance Fee';
  String get totalChargesLabel => ar ? 'إجمالي المطالبات' : 'Total Charges';
  String get totalPaymentsLabel => ar ? 'إجمالي المدفوعات' : 'Total Payments';
  String get ledgerHistory => ar ? 'سجل الحساب' : 'Account Ledger';
  String get charge => ar ? 'مطالبة' : 'Charge';
  String get noLedgerEntries => ar ? 'لا توجد حركات مسجلة' : 'No transactions recorded';
  String get forYear => ar ? 'للسنة' : 'For Year';
  String get pricePerMeterLabel => ar ? 'سعر المتر' : 'Meter Price';
}
