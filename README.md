# pos_v2

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
https://fosshati.com/privacy.html
https://fosshati.com/privacy-ar.html
https://www.transfernow.net/dl/20260617vTuMVCeM




cd /path/to/Pos_App_V2

flutter clean
rm -rf build .dart_tool/hooks_runner ios/Pods ios/Podfile.lock ios/.symlinks
rm -rf ~/Library/Developer/Xcode/DerivedData/*

flutter pub get
cd ios && pod install --repo-update && cd ..

# Confirm objective_c is gone:
grep -n "objective_c" pubspec.lock || echo "OK: objective_c not in lockfile"

flutter build ipa --release
