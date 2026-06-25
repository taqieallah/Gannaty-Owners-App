# Gannaty Owners App — نظام اتحاد شاغلي كمبوند جنّتي

نظام متكامل لإدارة كمبوند جنّتي وخدمة الملاك، مبني على Flutter + Firebase.
يتكوّن من تطبيقين وحزمة مشتركة و Cloud Functions، ويتشارك نفس مشروع Firebase
(`gannaty-f16cc`) مع برنامج الإدارة المكتبي (ERP).

An integrated system for managing the Gannaty compound and serving owners,
built with Flutter + Firebase. It contains two apps, a shared package, and
Cloud Functions, all on the same Firebase project (`gannaty-f16cc`).

---

## 🧩 المكوّنات / Components

| المسار | الوصف |
|---|---|
| `apps/client_app` | تطبيق الملاك (موبايل): دخول برقم التليفون، عرض كشف الحساب، المدفوعات، الإيصالات، طلبات الصيانة، والإشعارات. |
| `apps/admin_app` | تطبيق الإدارة: الفيلات، المدفوعات، التسويات السنوية، طلبات الخدمة، والإعلانات. |
| `packages/compound_core` | حزمة مشتركة: الموديلات، الـ repositories، ومنطق الحسابات (يقرأ حسابات الملاك من `users/{workspaceUid}/...`). |
| `functions/` | Firebase Cloud Functions (Node.js) — الإشعارات والمعالجة الخلفية. |

## 🔗 التكامل مع برنامج الإدارة / ERP integration

برنامج الإدارة المكتبي هو **المصدر الوحيد** لبيانات الملاك. يكتب الحسابات
والحركات وإعدادات السنة إلى Firestore على المسار الذي يقرأه هذا النظام:

```
users/{workspaceUid}/owners
users/{workspaceUid}/owner_transactions
users/{workspaceUid}/owner_year_settings
```

حيث `workspaceUid` منشور في `config/compound.workspaceUid`. أما بيانات الكمبوند
(الفيلات، المدفوعات الشهرية، التسويات، طلبات الخدمة، الإعلانات) فمخزّنة في
مجموعات عليا: `villas` / `payments` / `annualSettlements` / `serviceRequests` /
`announcements`.

## 🔐 المصادقة / Authentication

- **الملاك:** دخول برقم الهاتف (Phone Auth) — يُطابَق برقم الفيلا/التليفون.
- **الإدارة:** بريد إلكتروني، أو وصول الخدمة عبر مصادقة مجهولة (anonymous).
- صلاحيات القراءة/الكتابة محكومة في `firestore.rules`.

## 🚀 التشغيل / Getting started

```bash
# تثبيت أدوات المونوريبو
dart pub global activate melos
melos bootstrap

# تشغيل تطبيق الملاك
cd apps/client_app && flutter run

# تشغيل تطبيق الإدارة
cd apps/admin_app && flutter run

# نشر القواعد والـ functions (تأكّد من المشروع الصحيح أولاً)
firebase deploy --only firestore:rules,functions
```

> راجع `SETUP_GUIDE.md` لتفاصيل الإعداد الكاملة.

## 📦 Firebase

- **Project:** `gannaty-f16cc`
- **Firestore:** `firestore.rules` + `firestore.indexes.json`
- **Functions:** `functions/` (codebase: `default`)

## 🗂️ البنية / Structure

```
.
├── apps/
│   ├── admin_app/        # تطبيق الإدارة
│   └── client_app/       # تطبيق الملاك
├── packages/
│   └── compound_core/    # الموديلات + الـ repositories المشتركة
├── functions/            # Cloud Functions (Node.js)
├── firestore.rules
├── firestore.indexes.json
└── melos.yaml
```

---

صُمِّم لخدمة ملاك كمبوند جنّتي بتجربة عربية أولًا (RTL) وواجهة حديثة.
