# App Logo Instructions

## How to Add Your Custom Logo:

1. **Prepare your logo image:**
   - Size: 1024x1024 pixels (square)
   - Format: PNG with transparent background
   - Design: Should work well as a small icon

2. **Replace the placeholder:**
   - Place your logo file here: `assets/app_logo.png`
   - Make sure it's named exactly `app_logo.png`

3. **Generate launcher icons:**
   - Run: `flutter pub get`
   - Run: `flutter pub run flutter_launcher_icons:main`

4. **Build the app:**
   - Run: `flutter build apk`
   - The new APK will have your custom logo

## Current Structure:
- `assets/app_logo.png` - Your main logo (replace this)
- `android/app/src/main/res/mipmap-*/ic_launcher.png` - Generated launcher icons

## Note:
The app name has been updated from "blood_hero1" to "Blood Hero" for better branding.
