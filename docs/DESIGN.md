# Digital Susu V2 — Design System (from supplied references)

Source references: `assets/design/design_reference_1.jpg` (13-screen deck) and
`design_reference_2.jpg` (12-screen deck). These define the visual contract the
app follows — screen inventory, palette, typography, and flows. Applied from
Phase 1 onward so every screen built lands on the design system; full visual
polish remains Phase 11.

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

## Implementation status

- ✅ Palette applied (`core/theme/app_colors.dart`)
- ✅ Poppins bundled + registered (`assets/fonts/`, pubspec)
- ✅ Splash screen (`features/authentication/.../splash_screen.dart`)
- ⏳ Onboarding / Login / Sign Up screens — Phase 3 (authentication)
- ⏳ Dashboard, Wallet, My Susu, Susu Details, Contribute, Payments, Chat,
  Notifications, Profile — Phase 4–7 with the feature work
- ⏳ Bottom nav shell — Phase 4
- ⏳ Full visual polish — Phase 11
