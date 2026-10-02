# Gannaty Owners App — تطبيق الملاك

تطبيق Flutter لملاك كمبوند جنّتي: كشف الحساب، المدفوعات، الإيصالات، طلبات
الصيانة، والإعلانات. يشتغل على **Supabase** ويتشارك نفس المشروع وجدول
`documents` مع برنامج الإدارة المكتبي (ERP).

Flutter app for the owners of the Gannaty compound. It runs on **Supabase** and
shares one project and one `documents` table with the desktop ERP.

> **للفهم الكامل للنظام (الـ ERP، الـ backend، الأمان، قواعد الاستهلاك) اقرأ
> [`PROJECT_OVERVIEW.md`](PROJECT_OVERVIEW.md) أولًا.**
> Read `PROJECT_OVERVIEW.md` first for the full picture.

## المكوّنات / Components

| المسار | الوصف |
|---|---|
| `apps/client_app` | تطبيق الملاك (أندرويد). |
| `packages/compound_core` | موديلات + repositories + طبقة Supabase المشتركة. |
| `supabase/` | الـ Edge Functions (`owner-login`, `push-owner-transaction`) وملفات SQL (RLS، الدخول، الإشعارات). |

## المصادقة / Authentication

الدخول برقم الهاتف وكلمة المرور عبر Edge Function `owner-login` اللي بتتحقق
من الباسورد في Postgres وبتصدر JWT فيه `owner_id`، والـ RLS بيحصر كل مالك في
بياناته. الباسورد الافتراضي `123456` بيجبر المالك على تعيين باسورد جديد.

## التشغيل / Getting started

```bash
dart pub global activate melos
melos bootstrap

cd apps/client_app && flutter run
cd apps/client_app && flutter build apk --release
```

نشر Edge Function (مرر المشروع صراحةً — الـ CLI أحيانًا بيختار مشروع قديم متوقف):

```bash
supabase functions deploy owner-login --no-verify-jwt --project-ref hgfrtxktcucqucanfqhi
```

ملفات SQL بتتلصق في SQL Editor في لوحة Supabase.

## البنية / Structure

```
.
├── apps/client_app/       # تطبيق الملاك
├── packages/compound_core/ # الموديلات + الـ repositories المشتركة
├── supabase/              # Edge Functions + SQL
└── melos.yaml
```
