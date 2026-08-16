# Digital Susu V2 — Design System (from supplied references)

Source references: `design_reference_1.jpg`, `_3.jpg`, `_5.jpg` (13-screen
decks) and `design_reference_2.jpg`, `_4.jpg`, `_6.jpg` (12-screen decks).
These define the visual contract the app follows — screen inventory, palette,
typography, and flows. Applied from Phase 1 onward so every screen built lands
on the design system; full visual polish remains Phase 11.

## Color palette

| Token | Hex | Usage |
|-------|-----|-------|
| Primary (blue) | `#2563EB` | Primary actions, active nav, links, hero cards |
| Primary dark | `#1D4ED8` | Pressed/emphasis blue |
| Navy | `#1E3A8A` | Splash background, hero balance cards |
| Green | `#10B981` | Positive money (credits, top-ups, success) |
| Orange | `#F59E0B` | Warnings, alerts |
| Red | `#EF4444` | Negative money (debits, danger, logout) |
| Gray | `#687280` | Secondary text, captions |
| Light gray | `#F3F4F6` | Screen background |
| White | `#FFFFFF` | Surfaces, cards |

Semantic money rule: **green = credit/in**, **red = debit/out** — every
transaction list follows this (see Payments screen).

## Typography

- Family: **Poppins** (bundled: Regular 400, Medium 500, SemiBold 600, Bold 700)
- Headlines: SemiBold/Bold; body: Regular/Medium; amounts: Bold with tabular
  figures for alignment.

## Screen inventory (from reference)

1. Splash — navy bg, logo mark, "DIGITAL SUSU", slogan, bottom loading dot
2. Onboarding — "Welcome to Digital Susu" + Get Started
3. Login — "Welcome Back 👋", email/phone + password, forgot-password link
4. Sign Up — full name, email/phone, password, confirm, Terms checkbox
5. Dashboard — greeting "Hello, Kwame 👋", navy balance card (Total Balance),
   quick actions (My Susu, Payments, Invite, History), Active Susu list,
   Recent Transactions
6. Wallet — balance card with Top Up / Withdraw, quick actions (Add Money,
   Send Money, Bank Transfer, Airtime), recent transactions (green/red)
7. My Susu list — Active/Completed tabs, susu cards (pot amount, members,
   next payout), "+ Create New Susu" FAB
8. Susu Details — Total Pot, Next Payout date, My Contribution progress bar,
   "Contribute Now", member list / history / settings entries
9. Contribute — amount input + presets (10/20/50/100), payment method
   (Mobile Money / Card), Continue
10. Payments — wallet balance + recent payments with timestamps, color-coded
11. Group Chat — "Weekend Susu Group (10)", member bubbles, own message green
12. Notifications — New Contribution / Upcoming Payout / Payment Successful /
    New Member Added
13. Profile — photo, phone (024 123 4567), menu: Edit Profile, Bank Accounts,
    Security, Help & Support, Privacy Policy, Logout (red)

## Navigation

Bottom navigation (5 tabs): **Home · Groups · (+) Add · Wallet · Profile**
(the center "+" creates a new susu). Implemented as a `ShellRoute` when the
feature screens land (Phase 4+).

## Primary user flow

Sign Up / Login → Create / Join Susu → Contribute Securely → Track Progress
& Activity → Receive Payout

## Feature icon set

Group Susu (blue), Individual Susu (purple), Payments (green), Invite (indigo),
Chat (blue), Notifications (red), Security (orange), History (pink) — used for
quick actions and empty states.

## Navigation reconciliation (build spec §4 vs design deck)

The build spec lists primary areas HOME / GROUPS / WALLET / ACTIVITY / PROFILE;
the design deck's bottom navigation is Home · Groups · [+] · Wallet · Profile.
Resolved as: the deck's nav is authoritative (it is the visual contract), and
ACTIVITY is delivered as a full Activity/transactions screen
(`/transactions`) reachable from the dashboard (History quick action),
profile and wallet — with search, filters and statuses (spec §14).

## Responsive layout (spec §19)

Mobile (< 840dp): bottom navigation bar (deck). Tablet/desktop (≥ 840dp):
NavigationRail + content area — the desktop layout uses the extra space
instead of stretching the mobile layout.

## Reference data (from the decks)

Demo profile: **Kwame Owusu**, phone `024 123 4567`; balance **GHS 1,250.00**.
Active susu groups: **Weekend Susu** (GHS 500, 10 members, next payout
25 Aug 2026, my contribution 50/100), **Project Susu** (GHS 750, 15 members,
10 Sep 2026), **Business Susu** (GHS 1,200, 20 members, 5 Oct 2026).
Notifications: New Contribution · Upcoming Payout · Payment Successful ·
New Member Added.

## Implementation status

- ✅ Palette applied (`core/theme/app_colors.dart`)
- ✅ Poppins bundled + registered (`assets/fonts/`, pubspec)
- ✅ Splash screen (`features/authentication/.../splash_screen.dart`)
- ✅ Login / Sign Up / OTP / Forgot & Reset Password — Phase 3
- ✅ Dashboard — **rebuilt to match the React home reference**: blue header
  bar (logo · bell badge · avatar), greeting + Verified badge, white Total
  Balance card with eye toggle and "View Wallet >", Top Up / Withdraw /
  Transfer actions, four-circle quick menu, Active Susu cards with status
  pill, Recent Transactions — Phase 4
- ✅ Notifications screen (read/unread, mark-all-read) — Phase 4
- ✅ Profile screen (avatar, name, phone, KYC chip, menu, red Logout) — Phase 4
- ✅ Settings screen (notification toggles, market readout) — Phase 4
- ✅ Bottom nav shell (Home · Groups · [+] · Wallet · Profile) — Phase 4
- ✅ Wallet — **Phase 6**: balance card (GHS style, eye toggle) with Top Up /
  Withdraw amount sheets (GHS 10/20/50/100 presets, balance validation),
  quick actions (Add Money, Send Money, Bank Transfer, Airtime), recent
  wallet transactions (green credits / red debits); mock + API repositories
  (`GET /wallet`, `POST /wallet/top-up`, `POST /wallet/withdraw`), shell +
  dashboard "View Wallet" wired in
- ✅ Contribute — **Phase 6**: "Contribute Now" opens the design-reference
  sheet (GHS 10/20/50/100 presets, amount input, Mobile Money / Card
  segmented selector, Continue); records a contribution via the groups
  repository (mock updates the pot; API posts
  `POST /groups/:id/contributions` with idempotency key) and refreshes the
  group pot
- ✅ Payments — **Phase 6** (screen 10): gradient wallet-balance header
  (GHS style) + color-coded payment list (green credits / red debits),
  type icons, timestamps and Completed / Pending / Failed status chips;
  mock + API repositories (ledger served by `GET /transactions`), route
  `/payments` registered and dashboard "Payments" quick action wired to it
- ✅ Invite Friends — dashboard Invite quick action opens `/invite`: active
  susu groups with invite codes (mock SUSU-4821 / SUSU-7395 / SUSU-2106; API
  falls back until the server returns `invite_code`), one-tap Copy with
  confirmation; feeds the join-by-code flow
- ✅ My Susu list (screen 7), Susu Details (screen 8, incl. My Contribution
  progress bar), Group Chat (screen 11) — Phases 5–6
- ✅ Rotational Susu payout schedule — **Phase 7**: SusuSchedule + PayoutTurn
  models; mock cycle for Weekend Susu (12 of 26, weekly, GHS 100/cycle,
  GHS 1,000 payouts, upcoming rotation); overview "Payout Schedule" card
  (cycle progress + next payout recipient + upcoming turns); hidden for
  non-rotational groups and in API mode until the backend endpoint lands
- ✅ Savings-goal milestones — **Phase 7**: `SavingsGoal` + `GoalMilestone`
  models; mock goal for Project Susu (GHS 2,000 target by 10 Sep, 25/50/
  75/100% ladder); overview "Goal Progress" card (pot vs goal, target
  date, milestone checks derived from the pot); hidden for other group
  types and in API mode until the backend endpoint lands
- ✅ Joint-business reports — **Phase 7**: `BusinessReport` + `BusinessEntry`
  models; mock period report for Business Susu (GHS 1,200 capital, GHS 480
  revenue, GHS -315 expenses, GHS 165 profit, six activity entries);
  overview "Business Report" card (capital chip, revenue/expenses/profit
  stats, recent activity); hidden for other group types and in API mode
  until the backend endpoint lands — **Phase 7 complete**
- ✅ API mode aligned with the live backend — chat (`{messages:[...]}`
  wrapper, POST returns the created message), notifications
  (`{notifications, unread_count}` wrapper, `POST /notifications/:id/read`,
  `POST /notifications/read-all`), plus governance + member endpoint
  constants (`/proposals`, `/proposals/:id/vote`, member add/remove/role);
  adapter tests cover the real response shapes
- ✅ Governance — **build spec §16**: Proposals tab (4th group-details
  tab): proposal cards with status chips (Open/Passed/Rejected), per-option
  vote bars + counts, Approve/Decline actions, "You voted" confirmation;
  `GroupProposal` model + `getProposals`/`voteProposal` (mock persists
  votes; API against `GET/POST /groups/:id/proposals` + vote endpoint);
  8 new tests (mock voting rules, API contract, widget flows)
- ⏳ Onboarding screen — Phase 11 polish
- ⏳ Full visual polish — Phase 11
