<div align="center">

<img src="ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png" width="90" height="90" style="border-radius:20px" />

# UVGuard

**The smartest UV index app built for real skin protection — not just numbers.**

*Know your UV. Protect your skin. Stay safe outside.*

<br/>

<p>
<img src="https://img.shields.io/badge/Platform-iOS%20%7C%20Android-000000?style=for-the-badge" />
<img src="https://img.shields.io/badge/Flutter-3.x-000000?style=for-the-badge&logo=flutter&logoColor=white" />
<img src="https://img.shields.io/badge/License-MIT-000000?style=for-the-badge" />
<img src="https://img.shields.io/badge/Version-1.0.0-000000?style=for-the-badge" />
</p>

<a href="https://github.com/thearyamann/UVGuard/releases/tag/v1.0.0">
<img src="https://img.shields.io/badge/%E2%AC%87%20Download%20Android%20APK-Latest%20Release-000000?style=for-the-badge&logo=android&logoColor=white" />
</a>

<br/><br/>

> iOS — coming soon to App Store

</div>

---

## What is UVGuard?

UVGuard is a free, open-source UV index app that goes far beyond just showing you a number. It uses your **skin type**, **SPF level**, and **real-time UV data** to calculate exactly how long you can stay in the sun, how many times you need to reapply sunscreen, and alerts you when you're at risk.

Most UV apps show you a number and leave you to figure out what to do with it. UVGuard tells you **exactly what to do and when**.

---

## Screenshots

| Light Mode | Dark Mode | Widget |
|:---:|:---:|:---:|
| ![Light](screenshots/light.png) | ![Dark](screenshots/dark.png) | ![Widget](screenshots/widget.png) |

---

## Features

<table>
<tr>
<td width="50%">

**Personalised Protection**
Set your skin type (Type 1–6) and SPF once during onboarding. Every calculation is personalised to your skin.

**Smart Sunscreen Timer**
Live countdown showing exactly when to reapply. Tracks each session and shows Protected for today when all applications are done.

**High UV Alert**
Red alert banner when UV hits 6+ and you haven't applied yet. Bell icon shows a red dot badge.

**Daily Routine Checklist**
Tap-to-check list for Face, Body, Lip Balm and Hand Cream. Resets every day automatically.

</td>
<td width="50%">

**Live UV + Weather**
Real-time UV from OpenUV.io and weather from Open-Meteo. Auto-refreshes every 30 minutes.

**Burn Time Calculator**
Exact burn time using the Fitzpatrick skin scale. Shows Safe all day when UV is 0.

**Dark / Light Mode**
Deep forest green dark mode with animated sun/moon toggle. Remembers your choice.

**iOS Home Screen Widget**
Small and medium sizes with deep green gradient. Updates every 30 minutes.

</td>
</tr>
</table>

---

## How is UVGuard Different?

| Feature | UVGuard | Most UV Apps |
|---|:---:|:---:|
| Personalised to your skin type | ✅ | ❌ |
| How many times to reapply today | ✅ | ❌ |
| Live countdown sunscreen timer | ✅ | ❌ |
| Tracks each application session | ✅ | ❌ |
| High UV alert with action button | ✅ | ❌ |
| Daily skincare routine checklist | ✅ | ❌ |
| SPF-adjusted reapply intervals | ✅ | ❌ |
| Home screen widget | ✅ | Sometimes |
| Free and open source | ✅ | Rarely |
| No ads ever | ✅ | Rarely |
| Works offline with cached data | ✅ | ❌ |

---

## The Widget

The iOS home screen widget gives you the **one-glance answer** every morning before you leave the house.

**Small** — UV index in large type, risk level in colour-coded text, your city name

**Medium** — UV index left side, protection recommendation right side (No cream / SPF 30 / SPF 50+), peak UV hours at the bottom

Both use the same deep forest green gradient as the app. They look like they belong on your home screen, not like an afterthought. Updates every 30 minutes automatically.

---

## The Science

UVGuard uses the **Fitzpatrick Skin Type Scale** — the same scale used by dermatologists worldwide.

| Skin Type | Description | Burns |
|---|---|---|
| Type 1 | Very fair | Always |
| Type 2 | Fair | Usually |
| Type 3 | Medium | Sometimes |
| Type 4 | Olive | Rarely |
| Type 5 | Brown | Very rarely |
| Type 6 | Dark | Almost never |

Reapply intervals factor in both UV index and SPF level. SPF 50 gives 1.6x the base protection window. Total daily applications needed is calculated from skin type combined with current UV level.

---

## Tech Stack

| Layer | Technology |
|---|---|
| App framework | Flutter 3.x |
| UV data | OpenUV.io |
| Weather | Open-Meteo (free, no key needed) |
| Geocoding | Nominatim / OpenStreetMap |
| Local storage | SharedPreferences |
| Background refresh | WorkManager |
| iOS widget bridge | home_widget |
| Native iOS widget | WidgetKit (Swift) |
| Location | geolocator |

---

## Installation

### Android APK
```
1. Go to Releases (link at top)
2. Download uvguard.apk
3. Enable Install from unknown sources in Android settings
4. Open and install
```

### Build from Source
```bash
git clone https://github.com/aryamanchaudhary/uvguard.git
cd uvguard
flutter pub get
cd ios && pod install && cd ..
flutter run --dart-define=OPENUV_API_KEY=your_key_here
```

Get a free OpenUV API key at [openuv.io](https://openuv.io) — free tier gives 50 requests/day.

---

## Roadmap

- [ ] Push notifications when UV rises above 6
- [ ] UV forecast chart for the week
- [ ] Settings screen to update skin type after onboarding
- [ ] Android widget
- [ ] Apple Watch app
- [ ] App Store release

---

## Contributing

Pull requests welcome. Open an issue first for major changes.

---

## License

MIT — see [LICENSE](LICENSE) for details.

---

<div align="center">

<svg width="40" height="40" viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg"><rect width="1024" height="1024" rx="232" fill="#1a5c35"/><rect x="188" y="368" width="648" height="288" rx="144" fill="none" stroke="#FFFFFF" stroke-width="92" stroke-linejoin="round"/></svg>

**Built by Aryamann Chaudhary**

*If UVGuard helped you stay safe in the sun, leave a ⭐*

</div>
