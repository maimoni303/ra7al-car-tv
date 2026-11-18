# RA7AL Car TV

Live TV (M3U/IPTV), a browser, a video library and screen mirroring to the car display — iPhone app.

## Screens
Home (categories, source switcher) · Browser (ad blocking, tabs, mirroring) · Cast (CarPlay status + Start Mirroring) · Library (imported videos, favorites) · Settings (Manage Sources, appearance, Arabic/English, Block Ads).

## Build
- Any Mac: `./build-mac.sh` → `RA7AL-CarTV-unsigned.ipa`
- GitHub Actions: `.github/workflows/ios.yml` builds and tests on every push.

## Car screen
- The CarPlay scene shows channel lists and playback controls.
- Video and mirroring on the car screen need the CarPlay entitlement from Apple — see `docs/carplay-entitlement-request.md`.
- Mirroring uses a ReplayKit broadcast extension (`Broadcast/`) and the App Group `group.com.ra7al.cartv`.
