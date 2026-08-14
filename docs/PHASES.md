# Digital Susu V2 — Phase Plan & Progress

Development proceeds phase by phase (spec §36). A phase is **done** only when
(spec §39): code compiles, `flutter analyze` passes, tests pass, flows work,
errors are handled, architecture stays consistent, existing features are
preserved, Git state is clean, and changes are documented.

> ⚠️ **Verification note:** this project is authored in an environment without
> the Flutter SDK. "Code written" means the code is on disk but has **not**
> been executed. A phase is promoted to "Done" only after the user confirms
> `flutter analyze` and `flutter test` pass on a machine with the SDK.

---

## Phase 1 — Foundation ✅ code written (awaiting local verification)

**Scope (spec §36, Phase 1):** Flutter project, architecture, configuration,
routing, theme, shared components, environment configuration, Ghana defaults,
state management, secure storage.

**Delivered:**

- `pubspec.yaml` — flutter_riverpod, go_router, dio, flutter_secure_storage,
  shared_preferences, intl, equatable (Riverpod kept as the single state
  management system, spec §29).
- `lib/core/config/` — `AppConfig` (Ghana defaults: GH, GHS, GH₵, +233,
  Africa/Accra, en-GH, payment methods), `AppEnvironment` (USE_MOCK_DATA /
  API_BASE_URL / DEBUG_LOGGING via `--dart-define`).
- `lib/core/constants/` — `AppConstants`, `Permissions` (canonical permission
  ids, spec §5).
- `lib/core/errors/` — sealed `AppException` hierarchy with friendly messages
  (network, timeout, validation, unauthorized, forbidden, not-found, conflict,
  rate-limit, server, malformed, token/session expiry).
- `lib/core/theme/` — Material 3 light/dark themes, colors, typography.
- `lib/core/routing/` — `AppRoutes` (all spec §30 paths), `AppRouter`
  (go_router with session guard + error screen).
- `lib/core/storage/` — `SecureStorageService` (tokens) +
  `LocalStorageService` (preferences), provider-injectable for tests.
- `lib/core/utils/` — `CurrencyFormatter`, `PhoneFormatter`, `DateFormatter`,
  `Validators`, `Result<T>`.
- `lib/core/providers/` — app-level Riverpod providers.
- `lib/shared/models/money.dart` — integer minor-unit Money value type
  (financial integrity foundation).
- `lib/shared/widgets/` — `AppLoadingView/Indicator`, `AppEmptyState`,
  `AppErrorState`, `AppRetryButton`.
- Placeholder screens: login (config proof) and dashboard (Phase 4 note).
- Feature skeleton: 16 feature directories with `.gitkeep`.
- Tests: config, environment, formatters, validators, Money, async-state
  widgets.
- Docs: README, ARCHITECTURE, PHASES.
- Git: initialised, Phase 1 commit created.

**To verify locally:**

```sh
flutter pub get
flutter analyze
flutter test
```

**Known risk:** `CardThemeData` in `app_theme.dart` requires Flutter ≥ 3.27;
`intl` version may need to match your Flutter pin (see README).

---

## Phase 2 — Network/API layer ✅ code written (awaiting local verification)

**Scope (spec §36, Phase 2):** API client, endpoints, interceptors, token
storage, refresh tokens, error handling, mock fallback, API tests.

**Delivered:**

- `lib/core/network/api_config.dart` — `ApiConfig` (base URL/timeout from
  environment), `RequestFlags` (skipAuth / isRefreshRequest / retried).
- `lib/core/network/api_endpoints.dart` — centralised endpoint paths for every
  feature (auth, users, groups, contributions, wallets, payments,
  transactions, notifications, chat, voting, reports, KYC, susu systems).
- `lib/core/network/api_exception_mapper.dart` — maps all DioException types
  and HTTP statuses (400/401/403/404/409/422/429/5xx) onto the `AppException`
  hierarchy; prefers the server's `message`; JSON decode failures →
  `MalformedResponseException`. No raw errors reach the UI (spec §12).
- `lib/core/network/token_store.dart` — `TokenStore` abstraction with
  `SecureStorageTokenStore` (prod) and `InMemoryTokenStore` (tests/mock).
- `lib/core/network/token_refresher.dart` — refresh with **single-flight**
  (concurrent 401s share one refresh); rejected refresh token clears the
  session and fires `onSessionExpired` (spec §10, §28).
- `lib/core/network/auth_interceptor.dart` — attaches `Bearer` token to
  protected requests, skips public ones, transparently refreshes and retries
  **once** on 401 (infinite-loop guard via `RequestFlags.retried`).
- `lib/core/network/logging_interceptor.dart` — debug logging gated by
  `DEBUG_LOGGING`.
- `lib/core/network/api_client.dart` — typed helpers `getMap/getList/postMap/
  putMap/patchMap/delete` with shape validation and last-resort error safety.
- `lib/core/network/repository_selector.dart` — `selectRepository(mock:, api:)`
  seam; feature repositories switch on `USE_MOCK_DATA` without UI changes
  (spec §11).
- `lib/core/providers/network_providers.dart` — apiConfig / tokenStore /
  apiClient providers; `sessionExpiredHandlerProvider` is overridden in
  Phase 3 to sign the user out.
- Tests (dependency-free fake Dio adapter): error mapping, API client decode/
  error paths, token refresh (success, rejection, missing token, single-
  flight), auth interceptor (attach/skip/retry/session-expiry/no-loop), mock
  fallback selection.

**To verify locally:** `flutter pub get && flutter analyze && flutter test`.

---

## Phase 3 — Authentication (pending)

Register / login / 6-digit OTP / logout / forgot password / session
management / secure token storage / refresh / permissions foundation.

## Phase 4 — User & dashboard (pending)

Profile, permission-aware dashboard, notifications, settings.

## Phase 5 — Groups (pending)

Create/join/approve/invite/remove members, permissions, rules, schedules,
announcements, chat + moderation.

## Phase 6 — Financial system (pending)

Personal/group wallet separation, transactions (unique IDs, append-only),
provider-independent payments, contributions, receipts, statements.

## Phase 7 — Susu systems (pending)

Rotational susu, savings goals, joint business — schedules, payouts,
calculations, cycle tracking, penalties.

## Phase 8 — Governance (pending)

Proposals, voting, moderation, audit system, advanced permissions.

## Phase 9 — Reporting & KYC (pending)

KYC states (NOT_STARTED/PENDING/VERIFIED/REJECTED/EXPIRED), reports,
statements, permission-gated exports.

## Phase 10 — Hardening (pending)

Security, data integrity (idempotency, transactional ops), edge cases,
performance, offline/network behaviour.

## Phase 11 — UI/UX polish (pending)

Apply supplied design references; hierarchy, navigation, spacing, typography,
forms, empty/loading/error states, accessibility, animations.

---

## Critical user journeys (spec §35)

Tracked per phase: FLOW 1–8 (register→dashboard, group lifecycle, join/approve,
contribution→receipt, rotational cycles, savings goal, joint business P/L,
proposal→vote→action). Each flow is verified during its owning phase.
