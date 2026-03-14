# 🛡️ TrustGuard AI — Flutter App

Real-Time Fraud Shield for ASEAN Digital Wallet Users  
**SDG 8 — Decent Work and Economic Growth**

---

## 📁 Project Structure

```
trustguard/
├── lib/
│   ├── main.dart                    ← App entry point + bottom nav shell
│   ├── theme/
│   │   └── app_theme.dart           ← Colors, text styles, theme config
│   ├── models/
│   │   └── transaction.dart         ← Data models + sample data
│   ├── widgets/
│   │   └── common_widgets.dart      ← Reusable UI components
│   └── screens/
│       ├── home_screen.dart         ← Dashboard with hero + transactions
│       ├── analyze_screen.dart      ← Transaction fraud simulator
│       ├── alerts_screen.dart       ← Filterable alert feed
│       └── profile_screen.dart      ← User profile + security settings
└── pubspec.yaml
```

---

## 🚀 Setup & Run

### Prerequisites
- Flutter SDK 3.0+  → https://docs.flutter.dev/get-started/install
- Dart SDK 3.0+
- Android Studio / VS Code with Flutter extension
- Android emulator or physical device

### Steps

```bash
# 1. Create a new Flutter project
flutter create trustguard_ai
cd trustguard_ai

# 2. Replace the generated files with the provided source files:
#    - Replace lib/main.dart
#    - Add lib/theme/app_theme.dart
#    - Add lib/models/transaction.dart
#    - Add lib/widgets/common_widgets.dart
#    - Add lib/screens/home_screen.dart
#    - Add lib/screens/analyze_screen.dart
#    - Add lib/screens/alerts_screen.dart
#    - Add lib/screens/profile_screen.dart
#    - Replace pubspec.yaml

# 3. Install dependencies
flutter pub get

# 4. Run the app
flutter run

# For a specific device:
flutter run -d android
flutter run -d ios
flutter run -d chrome   # web preview
```

---

## 📦 Dependencies

| Package | Purpose |
|---|---|
| `google_fonts` | Syne (display) + DM Sans (body) + DM Mono fonts |
| `fl_chart` | Risk distribution & timeline charts |
| `flutter_animate` | Entry animations & transitions |
| `percent_indicator` | Circular risk gauge |
| `provider` | State management (for future expansion) |
| `intl` | Currency/date formatting |

---

## 📱 Screens

### 🏠 Home
- Animated protection ring (80% safety score)
- Quick stats: Approved / Flagged / Blocked counts
- Live fraud alert banner
- Transaction list with color-coded risk pills

### 🔍 Analyze
- Transaction fraud simulator
- Inputs: amount, device type, location
- Real-time risk scoring with animated progress indicator
- Explainable AI — plain-language factor breakdown

### 🔔 Alerts
- Filterable feed (All / Blocked / Flagged / System)
- Color-coded severity levels (red / orange / green)
- Timestamps and status pills

### 👤 Profile
- User behavioral profile with animated bars
- Security toggles (Real-time protection, Alerts, Geofencing)
- Trusted device management

---

## 🎨 Design System

### Colors
```dart
AppColors.accent      // #0057FF — Brand blue
AppColors.safe        // #00B96B — Approved / low risk
AppColors.warn        // #F59E0B — Flagged / medium risk
AppColors.danger      // #EF2D56 — Blocked / high risk
```

### Typography
```dart
AppText.display(size)  // Syne — headings & titles
AppText.body(size)     // DM Sans — body text
AppText.mono(size)     // DM Mono — amounts, codes, scores
```

---

## 🤖 AI Model (Backend Integration)

To connect the Analyze screen to a real ML backend:

```dart
// In analyze_screen.dart, replace _analyze() with:
Future<void> _analyze() async {
  final response = await http.post(
    Uri.parse('https://your-api.com/predict'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'amount': double.parse(_amountCtrl.text),
      'device': _device.name,
      'location': _location.name,
    }),
  );
  final data = jsonDecode(response.body);
  setState(() {
    _score = data['risk_score'];
    _decision = data['decision'];
    _factors = (data['factors'] as List).map(...).toList();
  });
}
```

**Expected API response:**
```json
{
  "risk_score": 87,
  "decision": "BLOCKED",
  "factors": [
    { "text": "Amount 7x above user average", "level": "high" },
    { "text": "New device fingerprint", "level": "medium" },
    { "text": "Geographic anomaly", "level": "high" }
  ]
}
```

---

## 🔒 Ethical Considerations
- No real financial data used — all sample data is fictional
- Explainable AI decisions shown to users at all times
- False positive minimization through adaptive thresholds
- User privacy: behavioral profiles stored locally by default
