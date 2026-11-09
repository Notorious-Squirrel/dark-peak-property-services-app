# Dark Peak Property Services – Android Booking App

Customer-facing Android app for browsing services, calculating indicative prices and preparing booking enquiries to dean@darkpeakpropertyservices.com.

## Build an APK
Upload the Android source files to the repository root (including `app/`, `build.gradle`, `settings.gradle`, and `gradle.properties`). The GitHub Actions workflow will build a debug APK automatically.

Navigate to **Actions → Build Android APK → Run workflow**. Once complete, download the `dark-peak-test-apk` artefact.

## Important
Booking enquiries open the customer's configured email app; they are not automatically transmitted. All bookings require manual confirmation. Prices are illustrative pending review. This prototype does not provide push notifications or live synchronisation.
