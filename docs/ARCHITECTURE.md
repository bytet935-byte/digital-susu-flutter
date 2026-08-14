# Digital Susu V2 — Architecture

Layered architecture (spec §4): UI stays separate from business logic; data
flow is strictly one-directional.

## Data flow

```
UI (widgets / screens)
        ↓  watch / read
Provider / Controller (Riverpod)
        ↓  call
Service (use cases, business logic)
        ↓  delegate
Repository (data source selection: API or mock)
        ↓
API layer (dio) / Local storage / Mock source
```

- **Widgets** never contain financial or business logic (spec §4).
- **Repositories** decide the data source via `AppEnvironment.useMockData`
  (spec §11): UI is untouched when switching `USE_MOCK_DATA` (Phase 2).
- **Services** implement business rules (contribution, payout, savings
  calculations) and are pure Dart where possible for testability.
- **Providers** expose state to the UI; they never talk to the network
  directly.

## Directory layout

```
lib/
  core/                 # Cross-cutting foundations, no feature knowledge
    config/             # AppConfig (market defaults), AppEnvironment (flags)
    constants/          # AppConstants, Permissions (canonical permission ids)
    errors/             # AppException sealed hierarchy (friendly messages)
    network/            # Phase 2: api_config, api_endpoints, api_client,
                        #   auth/logging interceptors, token_refresher
    providers/          # App-level providers (storage, environment)
    routing/            # AppRoutes (paths), AppRouter (go_router + guards)
    storage/            # SecureStorageService (tokens),
                        #   LocalStorageService (preferences)
    theme/              # AppTheme, AppColors, AppTypography
    utils/              # CurrencyFormatter, PhoneFormatter, DateFormatter,
                        #   Validators, Result<T>
  features/
    <feature>/          # One feature per domain (spec §4):
      data/             #   repositories, DTOs, data sources (mock/api)
      domain/           #   entities, business rules, services
      presentation/     #   providers/controllers, screens, widgets
  shared/
    models/             # Money (integer minor units), future shared entities
    services/           # Cross-feature services
    widgets/            # AppEmptyState, AppErrorState, AppLoadingView, …
test/
  core/                 # config, utils tests
  features/             # per-feature unit & widget tests
  shared/               # models, widgets tests
```

Feature directories are created as their phases land; `lib/features/*/.gitkeep`
marks the full list (spec §4).

## Financial integrity (spec §7, §8, §28)

- **Money** stores integer minor units (pesewas); currency mixing throws.
- **Wallet separation**: PERSONAL and GROUP wallets are distinct domains with
  distinct owners — a transaction always carries `walletId`, `userId` and
  `groupId` (where applicable) so group money can never silently become
  personal money (Phase 6).
- **Append-only ledger**: corrections create ADJUSTMENT/REVERSAL records;
  historical records are never silently overwritten (Phase 6).
- **Idempotency keys** and unique transaction IDs prevent duplicates (Phase 6).
- **Payment state is backend-confirmed** — a client response never proves a
  payment succeeded; webhooks/verification determine final state (Phase 6).

## Authorization (spec §5)

Permission-driven: `Permissions` constants are the single source of truth.
Roles (Member, Group Owner, Admin, Treasurer, Moderator, System Admin) are
bundles of permissions; checks are always performed against effective
permissions, never roles alone. Backend re-enforces everything the client
checks (Phase 3+).

## Error handling (spec §12, §27)

All errors map to the sealed `AppException` hierarchy with user-friendly
messages. Raw technical errors never reach the UI; details are logged for
diagnostics. Phase 2 wires network failures onto these types.

## Theme & locale

- Material 3 themes in `core/theme` (light + dark); visual polish is Phase 11.
- Business locale is `en-GH` (AppConfig), Material localises to `en` because
  `flutter_localizations` ships no `en-GH` table; money/date/phone formatting
  uses explicit Ghana-first formatters.
