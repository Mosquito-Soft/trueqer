# Trueqer: Git Branching Workflow & Mobile Integration Guide

This guide establishes the official Git collaboration workflow and monorepo integration standards for all engineering teams at Trueqer, with special emphasis on onboarding the **Flutter mobile development team**.

---

## 1. Monorepo Structure Overview

Trueqer is structured as a unified monorepo:

```
trueqer/
├── mobile/                   # Client application (Flutter for Android 10+ & iOS 15+)
├── functions/                # Serverless API Gateway (TypeScript on Node.js)
├── database/                 # MySQL 8.0 DDL schemas, migrations, and seeds
├── docs/                     # OpenAPI 3.0.3 contracts and architecture docs
├── .github/workflows/        # CI/CD automation pipelines (Actions)
├── package.json              # Monorepo tooling (Prism mock, Redocly, TypeScript codegen)
├── tsconfig.json             # Root TypeScript configuration
├── .gitignore                # Global git ignore (including secrets and rules.txt)
└── README.md                 # Project root documentation
```

---

## 2. Git Branching Strategy

Trueqer follows a **Trunk-Based / Gitflow Hybrid** optimized for continuous integration:

```
[ main ]        ========================================== (Production releases)
                         ▲
                         │ Pull Request (Approved + CI Passed)
[ dev ]         =========o================================ (Active integration)
                          \                      ▲
                           \                    / Pull Request
[ feature/* ]               \==================/  (Short-lived task branches)
```

### Branch Hierarchy & Responsibilities

| Branch | Role | Protection Rules | Deployment Target |
| :--- | :--- | :--- | :--- |
| `main` | **Production**. Stable, tested releases. | Direct pushes blocked. Requires PR from `dev` + 1 review + CI green. | Production Firebase Cloud Functions & Store releases |
| `dev` | **Integration & Staging**. Active sprint features converge here. | Direct pushes blocked for feature work. All code arrives via PR. | Staging / Firebase Emulator Suite |
| `feature/<name>` | **Ephemeral task branches**. Created per story or task. | Created off `dev`. Deleted upon merge. | Local developer environment / Prism mock |

### Branch Naming Conventions
Always use descriptive, kebab-case branch names prefixed by task type:
- `feature/mobile-auth-screen`
- `feature/mobile-swap-request-ui`
- `feature/mobile-qr-totp-scanner`
- `fix/mobile-login-token-refresh`
- `refactor/mobile-h3-search-service`

---

## 3. Step-by-Step Git Workflow for Developers

### Step 1: Sync Your Local `dev` Branch
Before starting any new task, make sure your local `dev` branch is up to date:
```bash
git checkout dev
git pull origin dev
```

### Step 2: Create a Feature Branch
Create and switch to your feature branch off `dev`:
```bash
git checkout -b feature/mobile-initial-setup
```

### Step 3: Work and Commit Locally
Write clean, modular code. Commit frequently using **Conventional Commits**:
```bash
git status
git add mobile/
git commit -m "feat(mobile): implement profile screen and swap request modal"
```

Common commit prefixes:
- `feat(scope)`: A new feature
- `fix(scope)`: A bug fix
- `docs(scope)`: Documentation changes only
- `refactor(scope)`: Code change that neither fixes a bug nor adds a feature
- `test(scope)`: Adding or correcting tests

### Step 4: Rebase on Latest `dev` Before Pushing
Keep your git history linear and resolve conflicts early:
```bash
git fetch origin dev
git rebase origin/dev
```

### Step 5: Push Feature Branch to GitHub
```bash
git push -u origin feature/mobile-initial-setup
```

### Step 6: Open a Pull Request (PR)
1. Go to the GitHub repository: `https://github.com/Mosquito-Soft/trueqer`
2. Open a **New Pull Request**.
3. **Base branch**: `dev` ◄ **Compare branch**: `feature/mobile-initial-setup`
4. Fill in the PR template: description, screenshots/videos (for Flutter UI), and testing steps.
5. GitHub Actions will automatically run CI checks (linting, tests, and build validation).
6. Request review from a teammate. Once approved, use **Squash and Merge** into `dev`.

---

## 4. How the Flutter Team Integrates Existing Code into `/mobile`

Since the Flutter application is currently in development outside this monorepo, follow this checklist to integrate it smoothly:

### Checklist for Integration:
- [ ] **1. Clean up build artifacts in your standalone Flutter project before copying**:
  ```bash
  flutter clean
  ```
- [ ] **2. Copy files into `mobile/`**:
  Copy the contents of your standalone project into `/mobile` (include `android/`, `ios/`, `lib/`, `test/`, `assets/`, `pubspec.yaml`, `analysis_options.yaml`).
- [ ] **3. Exclude `.git/`**:
  Ensure your standalone `.git` directory is NOT copied into `mobile/`. Only the monorepo root `.git` should exist.
- [ ] **4. Verify `pubspec.yaml`**:
  Make sure dependencies are up to date and include `dio` for OpenAPI consumption:
  ```yaml
  dependencies:
    flutter:
      sdk: flutter
    dio: ^5.7.0
    qr_flutter: ^4.1.0        # For dynamic TOTP QR code display
    mobile_scanner: ^5.2.3    # For scanning the counterpart's QR
    geolocator: ^13.0.2       # For point GPS coordinates during meeting check
  ```
- [ ] **5. Test compilation inside `/mobile`**:
  ```bash
  cd mobile
  flutter pub get
  flutter analyze
  flutter test
  ```
- [ ] **6. Validate with Local Mock Server**:
  Verify the app connects to the Prism mock server running at `npm run mock:api`:
  - Android emulator URL: `http://10.0.2.2:4010`
  - iOS simulator URL: `http://127.0.0.1:4010`

---

## 5. Continuous Integration & Deployment (CI/CD)

The GitHub Actions workflow runs automatically:
1. **On PR to `dev`**: Runs `flutter analyze`, `flutter test`, and backend unit tests.
2. **On merge to `dev`**: Deploys serverless backend functions to Firebase staging environment.
3. **On merge from `dev` to `main`**: Runs full integration tests and triggers production deployment (`firebase deploy --only functions`).

---

*Questions? Contact the Trueqer Architecture and DevOps team via GitHub Discussions or team chat.*
