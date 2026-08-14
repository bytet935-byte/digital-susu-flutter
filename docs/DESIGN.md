# Digital Susu V2 — Design System (from supplied references)

Source references: `assets/design/design_reference_1.jpg` + `design_reference_3.jpg`
(13-screen decks) and `design_reference_2.jpg` + `design_reference_4.jpg`
(12-screen decks). These define the visual contract the app follows — screen
inventory, palette, typography, and flows. Applied from Phase 1 onward so every
screen built lands on the design system; full visual polish remains Phase 11.

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
- ✅ Dashboard (balance card, quick actions, active susu, recent
  transactions) — Phase 4
- ✅ Notifications screen (read/unread, mark-all-read) — Phase 4
- ✅ Profile screen (avatar, name, phone, KYC chip, menu, red Logout) — Phase 4
- ✅ Settings screen (notification toggles, market readout) — Phase 4
- ✅ Bottom nav shell (Home · Groups · [+] · Wallet · Profile) — Phase 4
- ⏳ Wallet, My Susu list, Susu Details, Contribute, Payments, Chat —
  Phase 5–7 with the feature work
- ⏳ Onboarding screen — Phase 11 polish
- ⏳ Full visual polish — Phase 11
