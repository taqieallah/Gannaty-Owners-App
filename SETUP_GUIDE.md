# Compound App – Setup Guide

## Project Structure

```
NEW APP/
├── packages/compound_core/     # Shared models, repos, services
├── apps/admin_app/             # Admin Flutter app (dark blue theme)
├── apps/client_app/            # Client Flutter app (dark blue theme)
├── functions/                  # Firebase Cloud Functions (notifications)
│   ├── index.js                # 3 triggers: new request, status change, new payment
│   └── package.json
├── firestore.rules             # Firestore security rules
├── firestore.indexes.json      # Composite index definitions
├── firebase.json               # Firebase CLI config
└── melos.yaml                  # Monorepo config
```

---

## Step 1: Create Firebase Project

1. Go to https://console.firebase.google.com
2. Click **Add Project** → name it (e.g. `compound-app`)
3. Enable **Google Analytics** (optional)

### Enable Firebase Services:
- **Authentication** → Sign-in methods → Enable:
  - Email/Password (for admin)
  - Phone (for clients)
- **Firestore Database** → Create database → Start in **production mode**
- **Storage** → Get started

---

## Step 2: Register Both Apps in Firebase

### Admin App (Android)
1. In Firebase Console → Project Settings → Add app → Android
2. Package name: `com.yourcompound.admin`
3. Download `google-services.json`
4. Place it at: `apps/admin_app/android/app/google-services.json`

### Admin App (iOS)
1. Add app → iOS
2. Bundle ID: `com.yourcompound.admin`
3. Download `GoogleService-Info.plist`
4. Place it at: `apps/admin_app/ios/Runner/GoogleService-Info.plist`

### Client App (Android)
1. Add app → Android
2. Package name: `com.yourcompound.client`
3. Download `google-services.json`
4. Place at: `apps/client_app/android/app/google-services.json`

### Client App (iOS)
1. Add app → iOS
2. Bundle ID: `com.yourcompound.client`
3. Download `GoogleService-Info.plist`
4. Place at: `apps/client_app/ios/Runner/GoogleService-Info.plist`

---

## Step 3: Deploy Firestore Security Rules

```bash
# Install Firebase CLI if not installed
npm install -g firebase-tools

# Login
firebase login

# Initialize in the project root
cd "C:\Users\TaqieAllah\Desktop\NEW APP"
firebase init firestore

# Deploy rules
firebase deploy --only firestore:rules
```

---

## Step 4: Create Firestore Indexes

In Firebase Console → Firestore → Indexes → Add composite index:

| Collection | Fields | Order |
|---|---|---|
| `payments` | `villaId` ASC, `year` DESC, `month` DESC | |
| `payments` | `isPaid` ASC, `year` DESC | |
| `serviceRequests` | `clientPhone` ASC, `createdAt` DESC | |
| `serviceRequests` | `status` ASC, `createdAt` DESC | |

---

## Step 5: Create Admin User

In Firebase Console → Authentication → Users → Add user:
- Email: `admin@yourcompound.com`
- Password: (choose a strong password)

---

## Step 6: Update Package Names

### Admin App
Edit `apps/admin_app/android/app/build.gradle`:
```gradle
defaultConfig {
    applicationId "com.yourcompound.admin"
    ...
}
```

### Client App
Edit `apps/client_app/android/app/build.gradle`:
```gradle
defaultConfig {
    applicationId "com.yourcompound.client"
    ...
}
```

---

## Step 7: Run the Apps

### Prerequisites
- Flutter SDK installed and on PATH
- Android Studio / Xcode set up

### Install dependencies

```bash
# Admin app
cd "apps/admin_app"
flutter pub get

# Client app
cd "apps/client_app"
flutter pub get

# Core package
cd "packages/compound_core"
flutter pub get
```

### Run Admin App
```bash
cd "apps/admin_app"
flutter run
```

### Run Client App
```bash
cd "apps/client_app"
flutter run
```

---

## Step 8: Push Notifications Setup

### Deploy Cloud Functions

```bash
cd "C:\Users\TaqieAllah\Desktop\NEW APP"

# Install function dependencies
cd functions
npm install
cd ..

# Deploy functions (requires Blaze plan on Firebase)
firebase deploy --only functions
```

> **Note:** Cloud Functions require the **Firebase Blaze (pay-as-you-go) plan**.
> The free Spark plan does NOT support Cloud Functions.
> Costs are negligible for a residential compound at this scale.

### Android — Add notification permission

After running `flutter create` inside each app, open:
`apps/admin_app/android/app/src/main/AndroidManifest.xml`
`apps/client_app/android/app/src/main/AndroidManifest.xml`

Add this line **above** the `<application>` tag:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

Also add this **inside** the `<application>` tag for the default notification channel:
```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="compound_high_importance" />
```

### iOS — Push notification capability

1. Open `apps/admin_app/ios/Runner.xcworkspace` in Xcode
2. Select **Runner** target → **Signing & Capabilities**
3. Click **+** → add **Push Notifications**
4. Also add **Background Modes** → check **Remote notifications**
5. Repeat for `apps/client_app/ios/Runner.xcworkspace`

---

## Step 8b: Firebase Phone Auth Setup (for client app)

### Android
1. Get your SHA-1 fingerprint:
   ```bash
   cd apps/client_app/android
   ./gradlew signingReport
   ```
2. Add SHA-1 to Firebase Console → Project Settings → Your Android App → SHA certificate fingerprints

### iOS
Enable push notifications in Xcode:
- Open `apps/client_app/ios/Runner.xcworkspace`
- Target → Signing & Capabilities → + Capability → Push Notifications
- Also add "Background Modes" → Remote notifications

---

## Excel Import Format

The admin app can import payments from Excel (.xlsx). Required columns:

| Column | Type | Example |
|---|---|---|
| VillaNumber | Text | A-12 |
| Month | Number (1-12) | 3 |
| Year | Number | 2026 |
| Amount | Decimal | 2500.00 |
| DueDate | Date (dd/mm/yyyy or yyyy-mm-dd) | 31/03/2026 |
| IsPaid | true/false (optional) | false |
| Description | Text (optional) | Monthly maintenance fee |

---

## App Features Summary

### Admin App (Blue Theme)
- Login with email/password
- Dashboard: live stats (villas, unpaid payments, open requests)
- Villa management: add/edit/delete villas, link phone numbers
- Payment management: add manually or import from Excel, mark as paid
- Service requests: view all, update status (Pending → In Progress → Solved), add admin notes

### Client App (Green Theme)
- Login with phone OTP (auto-linked to registered villa)
- Home: welcome card, overdue payment alerts, quick actions
- Payments: full history grouped by year, color-coded status
- Service requests: submit with photo attachment, track status, see admin notes

---

## Firestore Data Structure

```
/villas/{villaId}
  villaNumber: "A-12"
  ownerName: "John Doe"
  phoneNumber: "+1234567890"
  createdAt: Timestamp

/payments/{paymentId}
  villaId: "abc123"
  villaNumber: "A-12"
  month: 3
  year: 2026
  amount: 2500.0
  dueDate: Timestamp
  isPaid: false
  description: "Monthly maintenance"
  createdAt: Timestamp

/serviceRequests/{requestId}
  villaId: "abc123"
  villaNumber: "A-12"
  clientPhone: "+1234567890"
  clientName: "John Doe"
  type: "maintenance"   // maintenance | complaint | other
  description: "AC unit not working"
  status: "pending"     // pending | in_progress | solved
  imageUrl: null        // Firebase Storage URL or null
  adminNote: null       // Admin's response note
  createdAt: Timestamp
  updatedAt: Timestamp
```
