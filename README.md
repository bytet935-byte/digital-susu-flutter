# Digital Susu V2

Ghana-first digital savings, **susu**, wallet, contribution, group-management
and financial-record platform — built with Flutter.

> **Status: Phase 1 (Foundation) — code written, NOT yet verified on a machine
> with the Flutter SDK.** Run the verification commands below and report any
> failures so they can be fixed before Phase 2.

## Quick start

Requirements: Flutter SDK (stable, Dart ≥ 3.4).

```sh
# 1. Fetch dependencies
flutter pub get

# 2. Static analysis (must be clean)
flutter analyze

# 3. Run tests (must pass)
flutter test

# 4. Run the app with mock data (default behaviour)
flutter run --dart-define=USE_MOCK_DATA=true

# 5. Run against a real backend when one is available
flutter run --dart-define=USE_MOCK_DATA=false \
  --dart-define=API_BASE_URL=https://api.example.com/v1
```

> **If `flutter pub get` fails on the `intl` version:** your Flutter release
> pins a different `intl` inside `flutter_localizations`. Set `intl` in
> `pubspec.yaml` to the exact version your Flutter pins (check with
> `flutter pub deps`) and run `flutter pub get` again.

## Verification status

| Check | Status |
|-------|--------|
| `flutter pub get` | ⏳ Pending — requires Flutter SDK (not available in the authoring environment) |
| `flutter analyze` | ⏳ Pending |
| `flutter test` | ⏳ Pending |

This project is developed in an environment without the Flutter SDK, so all
code is written by hand and **must be verified locally**. Per the project rule,
"all tests pass" will only be claimed once they are actually executed.

## Project structure

```
lib/
  core/                 # Framework-agnostic foundations
    config/             # AppConfig (Ghana defaults), AppEnvironment (dart-define)
    constants/          # AppConstants, Permissions
    errors/             # AppException hierarchy (typed, user-friendly)
    network/            # (Phase 2) API client, endpoints, interceptors
    providers/          # App-level Riverpod providers
    routing/            # AppRoutes, AppRouter (go_router)
    storage/            # SecureStorageService, LocalStorageService
    theme/              # AppTheme, colors, typography
    utils/              # Formatters, validators, Result<T>
  features/             # One folder per domain (auth, groups, wallet, …)
  shared/               # Reusable widgets, models (Money), services
test/                   # Unit + widget tests per area
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the full architecture and
[docs/PHASES.md](docs/PHASES.md) for the phase-by-phase plan.

## Ghana-first configuration

All market defaults are centralised in `lib/core/config/app_config.dart` —
**no widget hard-codes country-specific values** (spec §2):

| Setting | Value |
|---------|-------|
| Country | Ghana (`GH`) |
| Currency | GHS (`GH₵`) |
| Phone code | `+233` |
| Timezone | `Africa/Accra` |
| Locale | `en-GH` |
| Payment methods | mobile money, bank transfer, card |

Future markets are supported by introducing per-market configuration without
touching business logic.

## Money handling

`lib/shared/models/money.dart` is the financial-integrity foundation:

- Amounts are **integer minor units** (pesewas) — no floating-point drift.
- Arithmetic across different currencies throws instead of silently mixing.
- Display always flows through `CurrencyFormatter` (symbol-aware).

## Feature roadmap

| Phase | Scope | Status |
|-------|-------|--------|
| 1 | Foundation: config, theme, routing, storage, utils, shared widgets | ✅ Code written — awaiting local verification |
| 2 | Network/API layer (dio, interceptors, token refresh, mock fallback) | Pending |
| 3 | Authentication (register, login, OTP, sessions, permissions) | Pending |
| 4 | Profile, dashboard, notifications, settings | Pending |
| 5 | Groups, members, permissions, chat | Pending |
| 6 | Financial system: wallets, contributions, transactions, payments | Pending |
| 7 | Susu systems: rotational susu, savings goals, joint business | Pending |
| 8 | Governance: proposals, voting, moderation, audit | Pending |
| 9 | Reporting & KYC | Pending |
| 10 | Hardening: security, data integrity, offline behaviour | Pending |
| 11 | UI/UX polish (design references) | Pending |
