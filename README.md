<div align="center">
  <img src="assets/flutter_01.png" alt="BizPulse Logo" width="120" />
  <h1>💼 BizPulse</h1>
  <p><b>All-in-one business management app for independent service professionals in LATAM</b></p>
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.41-02569B?logo=flutter&logoColor=white)](#)
  [![Firebase](https://img.shields.io/badge/Firebase-Auth%20|%20Firestore-FFCA28?logo=firebase&logoColor=white)](#)
  [![SQLite](https://img.shields.io/badge/SQLite-Local%20DB-003B57?logo=sqlite&logoColor=white)](#)
  [![Android](https://img.shields.io/badge/Android-7.0+-3DDC84?logo=android&logoColor=white)](#)
</div>

<br/>

## 🚀 About the Project

BizPulse empowers service professionals (barbers, hairstylists, tattoo artists, masseuses, mechanics, veterinarians, psychologists, lawyers, accountants, and more) across Latin America. It solves the challenge of daily business management by centralizing appointments, clients, supplies, products, and finances in a single offline-first app.

Currently in **Phase 1 (Free v1.0)**, optimized to work seamlessly even with limited internet connectivity, using a hybrid **offline-first architecture**.

---

## 🛡️ Security & Privacy

- **Firebase Security Rules** protecting user data: users can only read/write their own appointments, clients, and services under `users/{uid}/` collections
- **SQLite offline-first:** Sensitive data (finances, inventory) never leaves the device unless explicitly exported by the user
- **Passwords secured** via Firebase Auth (Email/Password with industry-standard hashing)
- **Backup files** stored locally in device storage, never uploaded without explicit user consent
- **Encrypted exports:** User-initiated backup/restore operations remain under user control
- **No telemetry:** Minimal data collection, no analytics tracking without consent

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────┐
│              Flutter App (Provider)                 │
└──────────┬──────────────────────────────────────────┘
           │
     ┌─────┴──────┬──────────────┬────────────────┐
     ▼            ▼              ▼                ▼
Firebase Auth  Firestore      SQLite Local    Notifications
(Email/Pass)   (Cloud)        (Device)        (flutter_local_
               ├─ Appt        ├─ Supplies      notifications)
               ├─ Clients     ├─ Products
               └─ Services    └─ Transactions

                                     │
                                     └─── Google AdMob
                                           (Free plan ads)
```

---

## 📊 Data Model

### Appointment (Firestore)
```json
{
  "id": "apt_d1e2f3g4h5i6",
  "clientName": "Juan Pérez",
  "service": "Haircut Classic",
  "whenLocal": "2026-06-23T14:30:00",
  "price": 25.00,
  "remindBeforeMin": 30,
  "status": "confirmed"
}
```

### Supply (SQLite)
```json
{
  "id": "supp_x9y8z7w6v5u4",
  "name": "Premium Hair Gel",
  "quantity": 3.5,
  "minQty": 1.0,
  "unit": "kg",
  "createdAt": "2026-01-15T10:00:00Z"
}
```

### Transaction (SQLite)
```json
{
  "id": "trans_a1b2c3d4e5f6",
  "type": "income",
  "amount": 150.00,
  "description": "Services on 2026-06-23",
  "date": "2026-06-23T17:00:00Z",
  "category": "Appointments"
}
```

---

## 📸 UI Screenshots

| ![Dashboard](docs/screenshots/dashboard.png) | ![Agenda](docs/screenshots/agenda.png) |
|:---:|:---:|
| **Dashboard** — Daily summary & quick stats | **Agenda** — Weekly view with reminders |
| ![Finance](docs/screenshots/finance.png) | ![Settings](docs/screenshots/settings.png) |
| **Finance** — Income/expense tracking | **Settings** — Customization & backup |

> Screenshots will be updated with production builds.

---

## ✨ Key Features

- 📅 **Smart Appointments:** Daily and weekly views with automatic local notifications
- 👥 **Client Management:** Visit history and detailed client profiles
- 📦 **Inventory Control:** Internal supplies with minimum stock alerts (offline)
- 💰 **Finance & Reports:** Income/expense tracking with monthly statistical reports
- 💾 **Local Backup:** JSON-based export/import fully controlled by the user
- 🎨 **Customization:** Themes, colors, and business type adaptation
- 🔕 **Notifications:** Android 8–13 compatible with smart reminder scheduling
- 📱 **Responsive Design:** Optimized for phones with a clean, professional UI

---

## 🧪 Testing & QA

**Tested Devices:**
- Samsung Galaxy A51 (Android 13, One UI 5) ✅
- Xiaomi MIUI device (Android 12) ✅

**Testing Coverage:**
- ✅ Global error handling: try/catch on all async operations
- ✅ Notification compatibility: Android 8 through 13 (exact alarms + POST_NOTIFICATIONS permission)
- ✅ Keyboard behavior: native per-screen (no forced autofocus)
- ✅ Offline resilience: full functionality without internet
- ✅ Firebase Security Rules: user data isolation verified
- ✅ SQLite integrity: transaction logging and backup/restore tested

---

## 🚧 Roadmap / Future Phases

- **v1.1:** Optimization of Firestore queries (DB-side filtering)
- **Pro v1:** Multi-device sync, encrypted backups, no ads (RevenueCat integration)
- **WhatsApp Bot:** Automatic appointment reminders via official WhatsApp channel
- **Enterprise:** Multi-user support with role-based access and event auditing

---

## 🛠️ Installation & Local Development

1. Clone the repository:
   ```bash
   git clone https://github.com/ezequielpazz/bizpulse.git
   cd bizpulse
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure Firebase (if needed):
   ```bash
   flutterfire configure
   ```

4. Run the app:
   ```bash
   flutter run
   ```

---

## 📄 License & Attribution

Developed with ❤️ by Ezequiel Ituarte.

BizPulse is built using:
- [Flutter](https://flutter.dev) — Cross-platform mobile framework
- [Firebase](https://firebase.google.com) — Backend-as-a-Service
- [Provider](https://pub.dev/packages/provider) — State management
- [sqflite](https://pub.dev/packages/sqflite) — SQLite database
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) — Local notifications
- [google_mobile_ads](https://pub.dev/packages/google_mobile_ads) — Ad monetization
