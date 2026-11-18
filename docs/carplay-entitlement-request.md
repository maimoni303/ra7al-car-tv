# CarPlay entitlement request — RA7AL Car TV

Submit at: https://developer.apple.com/contact/carplay/ (signed in with the Apple Developer account)

| Field | Value |
|---|---|
| App name | RA7AL Car TV |
| Bundle ID | com.ra7al.cartv |
| Category requested | Video (first choice). If the form doesn't list Video for the region, choose the closest available category and explain below. |
| Platforms | iPhone, iOS 17+ |
| Contact | ra7al.server@gmail.com |

## Description (paste into the form)

RA7AL Car TV is a video player for people who spend long periods parked in their vehicle, such as on road trips, in desert camps, and while waiting. It plays live TV channels from M3U playlists that the user adds, and videos the user imports from their own library.

On the CarPlay display the app shows a browsing interface: categories, channel lists and favorites built with CarPlay templates. Video plays on the car display only while the vehicle is parked, as CarPlay video apps require. The app streams over AirPlay video and respects the session's video-availability signal. When the car reports that video isn't available, for example once it starts moving, playback on the car display stops and only audio controls remain.

The app has no ads, requires no account and collects no data. Playlists and videos stay on the device.

## Notes

- Apple decides whether to grant the entitlement. Approval can take days or weeks, and Apple may ask follow-up questions.
- Once it's granted, enable the matching CarPlay capability on the App ID in Certificates, Identifiers & Profiles. Regenerate the provisioning profile, then set the granted key in `project.yml` under `entitlements`: `com.apple.developer.carplay-video`, or `com.apple.developer.carplay-maps` if that category is granted.
- Video on the car screen also requires a car whose head unit supports CarPlay video ("video in car"). On cars without it, the app still shows the channel browser on the car screen and plays audio.
