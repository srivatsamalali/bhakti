# 🪙 Seva Karma Points, Rewards & Future Ads Deployment Blueprint

This document serves as the architectural reference for how **Devotional Seva Karma Points**, **Ad-Free Passes**, **In-App Purchases**, and **Google Mobile Ads (AdMob)** are integrated and how to deploy ads in production without disrupting spiritual chanting.

---

## 🏛️ 1. Karma Points & Rewards Ecosystem

### A. Ways Devotees Earn Karma Points (`SevaTokenService`)
| Contribution / Action | Seva Points | Auto-Trigger |
|---|---|---|
| **Upload a Devotional Song/Stotra** | **+15 🪙** | Triggered upon admin song creation/upload in `AdminAddEditSongScreen`. |
| **Request a Missing Song/Stotra** | **+5 🪙** | Triggered immediately upon submitting a valid request in `SongRequestDialog`. |
| **Daily Shloka Chanting / Sadhana** | **+1 🪙** | Awarded for daily continuous devotion. |

### B. Sacred Badges & Unlocking Milestones
- **Bhakti Sadhaka** (0+ 🪙): Beginning spiritual seeker.
- **Sangeeta Seva Karta** (50+ 🪙): Devoted contributor.
- **Punya Karta** (200+ 🪙): Chanting protector.
- **Seva Ratna Mahapurusha** (500+ 🪙): Pillar of the global devotional sangha.

---

## 🎟️ 2. Sacred Ad-Free Perks & Redemption Logic

When ads are deployed in production, devotees can redeem their earned Seva Karma points for temporary Ad-Free Sacred Listening Passes without spending real money:

```
[User earns Seva Points] 
        ⬇️
[SevaWalletScreen.redeemAdFreePass(days, costTokens)]
        ⬇️
[SevaTokenService sets adFreeExpiryDate = now + days]
        ⬇️
[AdService.instance.setPremium(true)]
        ⬇️
[AdFrequencyManager.setPremiumUser(true)]
        ⬇️
All Banner, Interstitial & Transition Ads are completely silenced!
```

- **1-Day Ad-Free Sacred Listening Pass**: Costs **200 🪙**.
- **3-Day Ad-Free VIP Devotee Pass**: Costs **500 🪙**.
- **7-Day Divine Moksha Pass**: Costs **1,000 🪙**.

---

## 📢 3. Future Ads Deployment Checklist (When Going Live)

When ready to enable Google AdMob in production:

### Step 1: Configure Production Ad Unit IDs
In `lib/core/constants/app_constants.dart`:
```dart
// Replace with production AdMob App ID & Ad Unit IDs:
static const String prodAndroidBannerId = "ca-app-pub-XXXXXXXX/YYYYYYYY";
static const String prodAndroidInterstitialId = "ca-app-pub-XXXXXXXX/ZZZZZZZZ";
static const String prodIosBannerId = "ca-app-pub-XXXXXXXX/AAAAAAAA";
static const String prodIosInterstitialId = "ca-app-pub-XXXXXXXX/BBBBBBBB";
```

### Step 2: Native Manifest & Info.plist Verification
- **Android**: `android/app/src/main/AndroidManifest.xml`
  ```xml
  <meta-data
      android:name="com.google.android.gms.ads.APPLICATION_ID"
      android:value="ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY"/>
  ```
- **iOS**: `ios/Runner/Info.plist`
  ```xml
  <key>GADApplicationIdentifier</key>
  <string>ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY</string>
  <key>SKAdNetworkItems</key>
  <array>
      <dict>
          <key>SKAdNetworkIdentifier</key>
          <string>cstr6suwn9.skadnetwork</string>
      </dict>
  </array>
  ```

### Step 3: Sacred Listening Guardrails (`AdFrequencyManager`)
To preserve devotional peace and comply with app store guidelines:
1. **Never show ads during active audio playback** (`isAudioCurrentlyPlaying == true`).
2. **Never show ads immediately upon clicking play**.
3. **Minimum 10-minute cooldown** between any interstitial ads.
4. **Minimum 3 full songs completed** before a transition ad is eligible.
5. **Instant bypass for VIPs & Pass Holders** (`isPremiumUser == true`).

---

## 💎 4. Dual Monetization Synergy

| Monetization Stream | Targeted Devotees | Integration Hook |
|---|---|---|
| **Direct IAP (Premium Moksha)** | Devotees wanting permanent instant ad-free access (`₹249/yr` or `₹499 lifetime`). | `PremiumService.purchasePlan()` |
| **Seva Karma Points Economy** | Devotees who contribute content, request hymns, or participate daily (`100 🪙 = 1-Day Pass`). | `SevaTokenService.redeemAdFreePass()` |
| **Google AdMob (Free Tier)** | Free-tier listeners between non-consecutive hymns. | `AdService.showInterstitialAtNaturalTransition()` |

---
