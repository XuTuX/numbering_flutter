# NUMBERING

NUMBERING is a Flutter equation puzzle with Arcade progression and a
server-verified Time Attack ranking.

## Highlights

- Arcade levels with local progress
- Server-verified Time Attack sessions and rankings
- Purchasable and daily bonus hints
- Google and Apple login
- Settings for language, audio, haptics, and account management
- Korean, English, Japanese, Simplified Chinese, and Hindi localization

## How to Play

Keep the digits in their original order. Place arithmetic operators and one
equals sign so both sides of the equation have the same value. Parentheses can
be added by selecting two consecutive digits.

## Technology

- Flutter / Dart
- Supabase Auth, server-verified Time Attack, and hint balances
- GetX state and dependency management
- Shared Preferences for local progress and settings
- Google / Apple sign-in, in-app purchases, audio, and haptics

## Runtime Configuration

This app now expects runtime values through `--dart-define`.

Required authentication values:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY` (`SUPABASE_ANON_KEY` is accepted temporarily)

The app requires a valid login before any gameplay or other screen is shown.
Omitting either value is treated as a configuration error; offline guest mode
is not available.

Example:

```bash
flutter run \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=...
```

## Google Sign-In Configuration

Google Sign-In client identifiers are configured natively:

- Android: `android/app/src/main/res/values/strings.xml`
- iOS: `ios/Runner/Info.plist`

## Android Signing

Release signing can be provided in either of these ways:

1. `android/key.properties`
2. Environment variables: `storeFile`, `storePassword`, `keyAlias`, `keyPassword`

If signing values are missing, Gradle can still produce an unsigned release artifact for verification builds.

## Supabase Scope

When Supabase configuration is supplied, Numbering uses Supabase Auth, hint
balances, purchase verification, and server-verified Time Attack RPCs. The
client submits completed expressions instead of writing trusted ranking scores
directly. Arcade progress remains local and never affects rankings. See
[`docs/numbering_supabase.md`](docs/numbering_supabase.md) for the validation and
retry rules.

## Verification

```bash
flutter analyze
flutter test
flutter build web --release
```

## Source and Asset Notice

Source code is provided for review. Third-party packages remain under their
respective licenses. Before redistributing the project media independently,
confirm the authorship or license records for the files in `assets/icons/` and
`assets/bgm/`.
