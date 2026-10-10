# Notch feature implementation plan

This fork starts at upstream commit `e2654ee41b0b9aee72c5a8113a11ab855896d6e6`. The first implementation branch is `feature/glass-notch-foundation`.

The goal is a personal notch utility with a glass appearance, Bluetooth connection activities, weather, configurable cards, lock-screen cards, and extensions. Notifications remain experimental. The design uses original SwiftUI views. The repository's upstream attribution and GPL license remain in place.

## Current architecture

`ContentView.swift` draws the notch and chooses expanded content or a closed activity. `BoringViewCoordinator` coordinates the Home and Shelf tabs, sneak peeks, and expanding activities. `BoringViewModel` manages each display's notch dimensions and interactions.

`NotchHomeView.swift` combines music, calendar, and camera. Defaults stores preferences. The expanded window currently has a fixed 640 by 190 point budget in `sizing/matters.swift`. New cards cannot just stack below the existing content without changing window sizing and display positioning together.

The app already has power activities, volume and brightness HUDs, and lock-screen window handling. `BoringNotchSkyLightWindow` uses private SkyLight APIs. Lock-screen support therefore needs testing on each supported macOS release. It is separate from WidgetKit.

The project targets macOS 14 and uses explicit Xcode source membership for most folders. New Swift files must join the application target. The first changes stay in existing target files.

## Implementation order

1. Establish the appearance controls and layout presets.
2. Add a shared activity queue and Bluetooth connection events.
3. Add weather retrieval, caching, and a weather card.
4. Expand layouts into a card registry and editor.
5. Add a separate lock-screen presentation with privacy defaults.
6. Expose the card and activity contracts to extensions.
7. Add opt-in notifications from the app and approved extensions.

Each stage includes usable UI, failure states, and validation. Settings for unimplemented features must not appear as working toggles.

## Glass appearance and layouts

The first implementation adds Glass and Classic surfaces under Settings > Appearance. Glass uses SwiftUI material, a dark tint for text contrast, and a restrained gradient border. This works with the macOS 14 baseline. It is not the newer native Liquid Glass API.

The closed notch stays black to blend into the camera area. The expanded notch uses the selected surface. Reduce Transparency selects an opaque background. Reduce Motion removes gesture scaling and the affected Home movement effects. Existing animations outside this change still need an accessibility audit.

The first layouts are Balanced, Calendar first, and Music focus. Music focus hides calendar and camera without overwriting their saved visibility preferences. Compact spacing is independent of the layout. The layout respects the current window size.

Later work introduces a typed card registry with stable identifiers, visibility, order, and supported sizes. The editor needs keyboard-accessible move controls as well as drag reordering. A versioned layout document must repair duplicate or removed card identifiers and provide a reset action. Width and height changes must update window frames, hit regions, screen edges, and multi-display placement together.

Acceptance requires all three presets to fit with calendar and camera enabled, immediate preference updates, persistence after relaunch, and no clipping during Home/Shelf transitions. Test on a notched display and an external display, with both accessibility settings enabled separately and together.

## Bluetooth connection activities

Use IOBluetooth connection notifications for supported devices, and register disconnect notifications for each tracked device. Seed connected devices at startup without presenting a burst of connection banners. Own notification registrations in a single service and unregister them during teardown.

Normalize each transition into a device identifier, display name, category, connection state, and timestamp. Deduplicate repeated callbacks and coalesce reconnect bursts by device. Provide a generic device symbol when the category is unknown. Do not invent battery percentages for devices that do not report them.

Create an activity queue before adding another branch to `ContentView`. An activity has an identifier, source, priority, expiration, and compact and expanded presentation. Keep volume and brightness feedback responsive. Limit queue length, discard expired items, and avoid interrupting active shelf drags. Share the queue across displays.

Add a Bluetooth activities switch and a device list. Implement user-requested connect and disconnect actions separately from event monitoring, with pending, success, and failure states. Disable repeated clicks during an operation. Show devices that the selected API can actually control. Bluetooth Low Energy discovery and control require a separate capability check; do not assume IOBluetooth covers every accessory.

Acceptance covers initial state, connect, disconnect, rapid reconnect, unnamed devices, Bluetooth disabled, sleep/wake, multiple displays, and activity suppression while locked. Hardware testing is required.

Reference: [IOBluetooth connection notifications](https://developer.apple.com/documentation/iobluetooth/iobluetoothdevice/register(forconnectnotifications:selector:)).

## Weather

Use a `WeatherProviding` protocol with WeatherKit as the first provider. The app needs its own signing identity and the WeatherKit capability. Keep credentials out of source control. Start with a saved city and optional location permission requested only after the user chooses current location.

Store a timestamped snapshot with city, conditions, temperature, high and low, unit, and provider attribution. Refresh on demand and at a bounded interval while active. Cancel obsolete requests after a location change. Back off on errors and preserve the last successful snapshot with a visible stale indicator.

The weather card needs loading, unavailable, permission-denied, stale, and successful states. Expose Celsius and Fahrenheit settings and a refresh action. Reserve room for required Apple Weather attribution. Never display sample weather as live data.

Acceptance covers unit conversion, changed location, denied location permission, offline launch, stale cache, refresh throttling, and attribution. Use an injected provider for deterministic tests, then validate signed WeatherKit requests on a Mac.

References: [WeatherKit setup](https://developer.apple.com/weatherkit/) and [WeatherKit entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.weatherkit).

## Lock-screen cards

Extend the existing lock-screen window path with a dedicated presentation and allowlist. Default to clock and nonpersonal status. Calendar titles, media metadata, device names, shelf contents, and extension payloads remain hidden until explicitly enabled for the lock screen. Disable file actions, camera activation, and extension actions while locked.

Publish lock state through an observable session model. Close menus and popovers, cancel pending presentations, and replace private content as soon as the session locks. Restore the ordinary layout after unlock. Test launch while locked, rapid lock/unlock, sleep/wake, multiple displays, and display removal.

Treat this as an experimental macOS overlay because the existing path uses private APIs. A feasibility milestone must establish supported OS versions before calling the feature complete. Native desktop widgets can be a separate WidgetKit target. An iPhone or iPad Lock Screen widget would require a companion app and shared data transport.

Reference: [WidgetKit platform support](https://developer.apple.com/documentation/widgetkit).

## Extension system

Start with a versioned data-only manifest and declarative card content. A manifest declares its identifier, version, minimum host version, display name, and requested capabilities. Reject unknown schema versions, duplicate identifiers, oversized input, and unsupported actions with readable errors.

Let users import, inspect, enable, disable, and remove local extensions. Installation must not execute code. The initial renderer accepts text, SF Symbols, bounded progress values, and explicit links. Validate link schemes. Extension cards use the same layout registry and activity queue as built-in cards.

A later executable extension host should run out of process through XPC, with resource limits, a crash boundary, and explicit capability grants. Do not load arbitrary dynamic libraries into the app or execute shell commands from a manifest. Defer a marketplace and automatic updates until local installation, compatibility, and permission revocation work.

Acceptance covers malformed manifests, version mismatch, duplicate IDs, payload limits, disabled extensions, removed cards, and lock-screen redaction. Include one working example extension and schema documentation when this stage ships.

## Notifications

Keep this feature off by default while the product behavior is evaluated. Begin with events generated by this app and enabled extensions. Use the shared activity queue for notch presentation. Request UserNotifications authorization only when the user enables system notifications.

Provide source switches, quiet periods, rate limits, dismissal, and private preview controls. Do not promise mirroring every other app's notifications. UserNotifications is not a general API for reading Notification Center. Any broader integration needs a separate feasibility review.

Acceptance covers permission denied, permission revoked, duplicate events, floods, lock-screen privacy, and quiet periods. The app must remain useful without notification permission.

## Validation and current status

The first source changes implement the glass surface and the layout presets described above. Bluetooth, weather, lock-screen cards, extensions, and notifications are planned, not implemented.

This machine has Apple command-line tools, but no Xcode installation was found in `/Applications`. `xcodebuild -version` fails because the active developer directory is `/Library/Developer/CommandLineTools`. Swift frontend parsing can check syntax, but it cannot prove target integration, SwiftUI type checking, rendering, or runtime behavior.

Before release, build the application with Xcode, run it on supported macOS versions, and complete the visual and hardware checks for each stage. Capture open, closed, hover, activity, and lock-screen states. Check frame pacing and idle energy use with Instruments. Retain upstream attribution when naming and distributing the fork.

The first verification pass succeeded for Swift frontend parsing of the four changed Swift files and `git diff --check`. Full compilation and visual validation remain pending.
