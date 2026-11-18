# Mason

A native iOS 26 app written in SwiftUI. It uses Apple's Liquid Glass design: the floating glass tab bar, `glassEffect` cards, glass buttons and glass sheet windows.

## Running it in the real iOS 26 Simulator

Apple's iOS Simulator only runs on macOS. This repo handles that with GitHub's Mac machines:

- Every push runs `.github/workflows/ios-simulator.yml` on a macOS 26 runner. It builds the app, runs it in an iPhone simulator with iOS 26, and screenshots every screen in light and dark mode.
- The screenshots are committed to `screenshots/`.
- The simulator build is uploaded as the `Mason-simulator-app` artifact on the Actions run.

### Using it interactively from Windows

1. Download `Mason-simulator.zip` from the latest run in the **Actions** tab.
2. Upload it at [appetize.io](https://appetize.io). Choose platform iOS and an iOS 26 iPhone.
3. Appetize streams a real iOS Simulator to your browser, so you can tap through the app on Windows.

### On a Mac

```sh
brew install xcodegen
xcodegen generate
open Mason.xcodeproj   # then Run on any iOS 26 simulator
```
