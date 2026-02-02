# Kash Flutter App - AI Agent Instructions

## Project Overview
**Kash** is a Flutter mobile app for tracking cash/expenses. Currently in early development with basic authentication flow and welcome screen. Multi-platform support: Android, iOS, Linux, macOS, Windows.

## Architecture & Organization

### Directory Structure
- **`lib/main.dart`**: App entry point, Material theme setup, routes to `WelcomeView`
- **`lib/view/`**: Screen/page widgets organized by feature (login/, home/)
  - `login/welcome_view.dart`: Splash screen with logo and get-started button
  - `login/sign_in_view.dart`: Authentication screen (exists, implementation in progress)
  - `home/home_view.dart`: Main app screen (stub, ready for implementation)
- **`lib/common/`**: Shared utilities and extensions
  - `color_extension.dart`: Centralized color palette via `TColor` static class
- **`lib/common_widget/`**: Reusable custom widgets (currently empty, add here)
- **`assets/img/`**: Image assets (welcome_screen.png, app_logo.png, get_started_button.png)

### Key Design Patterns

**Color Management**: All colors defined in [color_extension.dart](lib/common/color_extension.dart) as static getters on `TColor` class:
```dart
TColor.primary       // 0xff5E00F5 (main purple)
TColor.secondary     // 0xffFF7966 (orange accent)
TColor.secondaryG    // 0xff00FAD9 (cyan accent)
TColor.gray*         // Gray scales (80-10, darkest to lightest)
TColor.yellow        // 0xffCBBE12 (highlight)
```
Always use `TColor.*` instead of hardcoded colors.

**Theme Setup**: `MaterialApp` uses `ColorScheme.fromSeed()` with `TColor.primary` as seed. Navigation theme colors map to TColor values (see [main.dart](lib/main.dart) lines 17-27).

**View Architecture**: 
- Views are `StatefulWidget`s in `lib/view/{feature}/` subdirectories
- Use responsive sizing: `MediaQuery.sizeOf(context)` for screen dimensions
- Leverage `SafeArea` for system UI compatibility
- Use `Scaffold` + `Stack` for layered backgrounds

## Development Workflows

### Build & Run
```bash
flutter pub get              # Fetch dependencies
flutter run                  # Run on connected device/emulator
flutter run -d <device-id>  # Specific device (list via `flutter devices`)
flutter build apk           # Android APK
flutter build ios           # iOS (requires macOS)
```

### Analysis & Linting
```bash
flutter analyze             # Check linting per analysis_options.yaml
dart fix --apply           # Auto-fix issues where possible
```

### Project Setup
- **Dart SDK**: 3.10.7+
- **Dependencies**: Minimal (flutter, cupertino_icons, flutter_lints only)
- **Linting**: Uses `flutter_lints` with default Flutter rules (see [analysis_options.yaml](analysis_options.yaml))

## Conventions & Patterns

1. **File Naming**: `snake_case.dart` for files (e.g., `welcome_view.dart`, `color_extension.dart`)
2. **Class Naming**: `PascalCase` (e.g., `WelcomeView`, `TColor`)
3. **Colors**: Always use `TColor.*` getters; never hardcode `Color(0xff...)` in widget code
4. **Responsive Design**: Use `MediaQuery.sizeOf()` for dimensions, avoid fixed pixel sizes where possible
5. **Widget Structure**: Stateless for UI-only, Stateful when state management needed (no BLoC/Provider yet)
6. **System UI**: Use `SystemChrome.setEnabledSystemUIMode()` for full-screen layouts (see [welcome_view.dart](lib/view/login/welcome_view.dart) line 16)
7. **Asset Loading**: Images via `Image.asset()`, paths relative to `assets/img/` (see [pubspec.yaml](pubspec.yaml) line 44)

## Important Implementation Notes

- **No external state management** (BLoC, Provider, Riverpod) currently in use—use `setState()` for simple state
- **Navigation**: Currently basic (single entry point to `WelcomeView`). Migrate to named routes/router as features grow
- **Assets**: All static images must be declared in `pubspec.yaml` flutter.assets section
- **Conflict Resolution**: README.md has merge conflict markers—resolve before committing
- **Empty Directories**: `lib/common_widget/` and `lib/view/home/` are ready for implementation; avoid leaving permanent stubs

## When Adding Features

1. **New screens**: Create `lib/view/{feature}/{feature}_view.dart`
2. **New utilities**: Add to `lib/common/` with appropriate extension/helper class
3. **New colors**: Add to `TColor` class in [color_extension.dart](lib/common/color_extension.dart)
4. **Navigation**: Update imports in target views; consider future migration to named routes
5. **Testing**: Add to `test/` directory (currently minimal—basic `widget_test.dart`)

## External References
- [Flutter Docs](https://docs.flutter.dev/)
- [Dart Lints Guide](https://dart.dev/lints)
- Platforms: Android (API 16+), iOS (11.0+), Web, Linux, macOS, Windows
