# Gift Exchange — App Store & Play Store submission package

All copy ready to paste into App Store Connect and Google Play Console.
App: **Gift Exchange** · Bundle iOS `com.tinyutility.giftExchange` · Android `com.tinyutility.gift_exchange`
Privacy model: **100% offline, no account, no analytics, AES-encrypted local storage.**

---

## 1. Primary details (both stores)

| Field | Value |
|---|---|
| App name | Gift Exchange |
| Bundle / package id | iOS: `com.tinyutility.giftExchange` · Android: `com.tinyutility.gift_exchange` |
| Version | 1.0.0 (build 1) |
| Category (primary) | Lifestyle |
| Category (secondary) | Finance |
| Content rating | Everyone / 4+ (no user-generated content, no web access) |
| Price | Free |
| Contains ads | No |
| Offers in-app purchases | No |
| Privacy policy URL | _required by both stores — see note in §8_ |

---

## 2. App Store Connect (iOS)

**App Name (30):** Gift Exchange
**Subtitle (30):** Track gifts given and received
**Promotional Text (170):** A private, offline way to remember every gift — and stay thoughtful all year.
**Description (4000):** *(see §4)*
**Keywords (100, comma-separated):**
```
gift,tracker,giving,birthday,exchange,budget,presents,relationships,anniversary,holiday,spending,ideas
```
**Support URL / Marketing URL:** _set to your site or support email page_
**App Store category:** Lifestyle
**Age rating answers:**
- Cartoon / Unrealistic Violence — None
- Realistic Violence — None
- Profanity / Crude Humor — None
- Sexual / Nudity — None
- Alcohol / Drug / Tobacco — None
- Gamble / Contests — None
- Unrestricted Web Access — **No**
- User-Generated Content — **No** (user data is local-only and never shared)

**Info — Privacy Nutrition Label (App Store Connect → App Privacy):**
Select **"Data Not Collected"**. The app stores data only on-device (encrypted); nothing is transmitted. Confirm on submission.

**iOS screenshots required (provide one set):**
- 6.9" iPhone (required for iPhone 16/17 Pro Max): **1320 × 2868**
- 6.7" iPhone (required): **1290 × 2796**
- 5.5" iPhone (optional but recommended): **1242 × 2208**
- iPad 13" (if iPad supported — it is): **2064 × 2752**

---

## 3. Google Play Console (Android)

**App name (30):** Gift Exchange
**Short description (80):** Track every gift you give and receive — privately, offline.
**Full description (4000):** *(see §4, can reuse the same body)*
**App category:** Lifestyle
**Content rating:** Everyone (fill the IARC questionnaire → maps to Everyone/All)
**Target audience:** 13+ (default for finance/lifestyle utility)
**Contains ads:** No
**In-app products:** No
**App access (permissions):** App uses **no permissions** — declare "All users have full access".
**Data safety form (Play Console → Data safety):**
- "Does your app collect or share any user data?" → **No**
- (Leave all data-type toggles off.) Confirm: data is stored only on-device, encrypted, not transmitted, not shared.

**Play Store screenshots:**
- Phone (required, up to 8): min 320px, max 3840px each side, **aspect 16:9 or 9:16**. Use **1080 × 2400**.
- 7-inch tablet (optional): 1080 × 2400 or larger
- 10-inch tablet (optional): 1080 × 2400 or larger
- App icon: 512 × 512 PNG (32-bit), and a **feature graphic 1024 × 500 PNG**.

---

## 4. Full description (use for both stores, ≤4000 chars)

Gift Exchange is a simple, private way to keep track of every gift you give and receive. Remember who you gave what, how much you spent, and never forget a birthday again — all stored privately on your device.

**Why Gift Exchange**
- **See the full picture.** Log gifts by person — what you gave, what you received, and when. A running balance shows who you've given more to and who's ahead.
- **Understand your spending.** Built-in analysis breaks down your giving by person, relationship, and event type, so you can spot patterns and budget for the year.
- **Truly private.** Everything is stored on your device with AES encryption. No account, no sign-up, no servers, no tracking. Your gift history is yours alone.

**Features**
- Add people and organize them by relationship — family, friends, partner, colleagues, or your own custom label.
- Record gifts with type (given or received), value, description, date, and event — birthday, wedding, holiday, anniversary, and more.
- See each person's net balance at a glance, grouped by event.
- Browse a complete history of every exchange, in one place.
- Analysis screen with top spenders, relationship breakdowns, and time-based totals.
- Back up and restore your data with an encrypted export file you control.
- Accidental delete? Undo it instantly.
- Works offline. Always.

**Built for your privacy**
Gift Exchange never connects to the internet. There are no accounts, no ads, no analytics, and no data leaves your device. Your gift records are encrypted at rest and backed up only when you choose to export them yourself.

**Perfect for**
- Remembering birthdays, holidays, weddings, and anniversaries
- Keeping gift-giving fair and balanced in families and friend groups
- Budgeting for holidays and special occasions
- Anyone who wants a thoughtful, private record of their gift-giving

Gift Exchange is free with no ads and no in-app purchases. Just you and the people you care about.

---

## 5. What's New / Release Notes

**v1.0.0**
Welcome to Gift Exchange! This is our first release.
- Track gifts given and received for every person in your life
- See net balances and spending analysis by person, relationship, and event
- Complete history of all your exchanges
- Encrypted local backup and restore
- 100% private — no account, no ads, no internet

---

## 6. Suggested screenshot captions (for marketing / optional overlay text)

1. **Track every gift** — people, relationships, and net balances at a glance
2. **See who's ahead** — per-person balances grouped by event
3. **Log in seconds** — given or received, value, date, and notes
4. **Your full history** — every exchange, beautifully organized
5. **Understand your spending** — analysis by person, relationship, and time
6. **Private by design** — encrypted, offline, no account required

---

## 7. App icon source

App icon already exists in-repo:
- iOS: `src/frontend/ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- Android: `src/frontend/android/app/src/main/res/mipmap-*/ic_launcher.*`
- For the 1024×1024 App Store icon and 512×512 Play icon, export from the master icon asset.

---

## 8. Privacy policy (REQUIRED by both stores)

Both App Store and Play Store **require a privacy policy URL** even for a no-data app. Since Gift Exchange collects nothing:

Option A (fastest): Host a short "we collect nothing" policy on a simple page (GitHub Pages, Notion, or your landing site). Required fields:
- What data is collected: **None.**
- How data is stored: **On your device only, AES-encrypted. Never transmitted.**
- Third parties: **None.**
- Permissions: **None requested.**
- Children: **No data collected from anyone, including children.**
- Contact: your support email.

Option B: If you have a landing repo (`~/dev/landing-pages/gift-exchange`), drop the policy there and link its public URL. (Per global workflow, legal pages usually live in the landing repo, not the app repo.)

> Note: this was explicitly out of scope for the code work, but you'll hit a hard block at submission without a URL — so pick A or B before you click Submit.
