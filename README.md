# Mason

A native iPhone and iPad app written in SwiftUI. It runs on iOS 13 through iOS 26.

- **iOS 26:** uses Apple's Liquid Glass design: the floating glass tab bar that shrinks on scroll, `glassEffect` cards, glass buttons and glass sheet windows.
- **iOS 13–18:** the same screens with frosted blur instead of glass (Liquid Glass doesn't exist before iOS 26).

## Simulator runs

Every push runs `.github/workflows/ios-simulator.yml` on GitHub's Mac machines. It builds the app once, then runs it in Apple's iOS Simulator on each of these:

| Device | OS |
| --- | --- |
| iPhone 11 Pro Max | iOS 13.0 (the version it shipped with) |
| iPad Pro 11-inch | iPadOS 13.7 |
| iPad Pro 11-inch | iPadOS 14.5 |
| iPad Pro 11-inch | iPadOS 15.5 |
| iPad Pro 11-inch | iPadOS 16.4 |
| iPad Pro 11-inch | iPadOS 17.5 |
| iPad Pro 11-inch (M4) | iPadOS 18 |
| iPhone 17 Pro | iOS 26 |

Each run screenshots every screen in light and dark mode and commits them to `screenshots/<device>/`. Missing simulator versions are downloaded from Apple during the run.

### Using it interactively from Windows

1. Download `Mason-simulator.zip` from the latest run in the **Actions** tab.
2. Upload it at [appetize.io](https://appetize.io) and pick any iPhone or iPad and iOS version.
3. Appetize streams a real iOS Simulator to your browser.

### On a Mac

```sh
brew install xcodegen
xcodegen generate
open Mason.xcodeproj   # then Run on any simulator
```
