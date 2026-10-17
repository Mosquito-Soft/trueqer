# Trueqer Mobile Client (Flutter)

This directory is the dedicated location for the **Trueqer Flutter Mobile Application** (Android 10+ and iOS 15+) within our monorepo architecture.

---

## 1. Monorepo Integration Guide for the Flutter Team

If you have already started developing the Flutter client in a separate folder or standalone repository, follow these steps to integrate your existing work into this monorepo cleanly:

### Step 1: Clone the Monorepo and Create a Feature Branch
Do not work directly on `main` or `dev`. Always create an ephemeral feature branch:

```bash
# Clone the repository (if not already cloned)
git clone https://github.com/Mosquito-Soft/trueqer.git
cd trueqer

# Switch to the dev branch and ensure it is up-to-date
git checkout dev
git pull origin dev

# Create your integration branch
git checkout -b feature/mobile-initial-integration
```

---

### Step 2: Copy Your Existing Flutter Files into `/mobile`
Copy your existing Flutter project files directly into the `/mobile` directory so the structure looks like this:

```
trueqer/
├── mobile/
│   ├── android/                  # Android native project files
│   ├── ios/                      # iOS native project files
│   ├── lib/                      # Flutter Dart source code
│   │   ├── core/
│   │   │   ├── network/          # ApiClient, Dio interceptors
│   │   │   └── theme/            # App styles, typography, theme
│   │   ├── features/
│   │   │   ├── auth/             # Google / Apple OAuth2 login
│   │   │   ├── discovery/        # H3 geospatial search & catalog
│   │   │   ├── swaps/            # Swap proposals & state machine UI
│   │   │   ├── chat/             # Guided transactional chat
│   │   │   ├── qr_meeting/       # Dynamic TOTP QR display & scanner
│   │   │   └── reviews/          # Blind reviews & profile
│   │   └── main.dart             # Application entrypoint
│   ├── test/                     # Unit and widget tests
│   ├── assets/                   # Images, icons, vectors
│   ├── pubspec.yaml              # Dependencies and Flutter config
│   ├── analysis_options.yaml     # Dart linting rules
│   └── README.md                 # This file
├── functions/                    # Serverless API Gateway (TypeScript)
├── database/                     # MySQL schema & migrations
└── docs/                         # OpenAPI specs and architectural docs
```

> [!IMPORTANT]
> **Do NOT copy** your local `.git/` folder from your standalone project. Only copy the Flutter source code, native directories (`android`, `ios`), `assets`, `pubspec.yaml`, and configuration files into `mobile/`.

---

### Step 3: Verify and Test the Flutter App
Run standard Flutter verification commands inside `mobile/`:

```bash
cd mobile

# Install dependencies
flutter pub get

# Run analyzer to ensure code passes linting
flutter analyze

# Execute all tests
flutter test

# Run app on simulator/emulator
flutter run
```

---

### Step 4: Configure API Client to Use Local Mock Server
During development, configure your `ApiClient` base URL to point to the **Prism Mock Server**:

- In root directory: `npm run mock:api`
- In Flutter:
  - **Android Emulator**: `http://10.0.2.2:4010`
  - **iOS Simulator**: `http://127.0.0.1:4010`
  - **Physical Device**: `http://<YOUR_LOCAL_IP>:4010`

For full details on using OpenAPI contracts and generating Dart models, refer to:
[Flutter & OpenAPI Integration Guide](../docs/FLUTTER_OPENAPI_GUIDE.md).

---

### Step 5: Commit and Submit a Pull Request
Once your code compiles and passes tests, commit your changes and submit a PR:

```bash
# From repository root
git add mobile/
git status

# Commit using conventional commits
git commit -m "feat(mobile): integrate initial Flutter mobile codebase into monorepo"

# Push feature branch to GitHub
git push -u origin feature/mobile-initial-integration
```

Then go to GitHub and create a **Pull Request targeting `dev`**.
