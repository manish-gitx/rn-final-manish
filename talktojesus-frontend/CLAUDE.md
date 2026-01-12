# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter application called "Talk to Jesus" - a spiritual companion app with multiple interactive features. The app uses Flutter 3.9.2+ with Dart and follows a clean architecture pattern with Riverpod for state management.

## Development Commands

### Running the app
```bash
flutter run
```

### Building the app
```bash
# iOS
flutter build ios

# Android
flutter build apk

# Web
flutter build web
```

### Code analysis and quality
```bash
flutter analyze
```

### Getting/updating dependencies
```bash
flutter pub get
flutter pub upgrade
```

## Architecture Overview

The project follows a **Clean Architecture** pattern with clear separation of concerns:

### Directory Structure
- **lib/core/**: Core functionality and shared components
  - **constants/**: App-wide constants (colors, strings, text styles, audio constants)
  - **providers/**: Riverpod providers for state management (app state, connectivity, audio)
  - **navigation/**: Navigation system with custom router and page transitions
  - **accessibility/**: Accessibility utilities and focus management
  - **widgets/**: Reusable core widgets (error boundary, network awareness)
  - **enums/**: App enumerations (app language)

- **lib/presentation/**: UI layer
  - **pages/**: Main app screens (JesusPage, AudioSongsPage, AudioPlayerPage, BiblePage)
  - **widgets/**: UI components and page-specific widgets
  - **controllers/**: UI controllers

- **lib/domain/**: Business logic layer
  - **models/**: Data models (Song, etc.)
  - **repositories/**: Repository interfaces

- **lib/data/**: Data layer
  - **repositories/**: Repository implementations (mock implementations)

### Key Architectural Features

1. **State Management**: Uses Riverpod providers for reactive state management
2. **Navigation**: Custom router with enhanced route handling and page transitions
3. **Accessibility**: Built-in accessibility support with focus management and high contrast mode
4. **Error Handling**: Global error boundary with graceful error recovery
5. **Network Awareness**: Connectivity monitoring with offline/online state handling
6. **Audio System**: Integrated audio player with song management
7. **Theming**: Material 3 design system with Google Fonts (Poppins) and high contrast support

### Core Dependencies
- **flutter_riverpod**: State management
- **google_fonts**: Typography (Poppins font family)
- **audioplayers**: Audio playback functionality
- **connectivity_plus**: Network connectivity monitoring
- **flutter_svg**: SVG asset support
- **shimmer**: Loading animations
- **path_provider**: File system access

### Application Routes
- `/` (home) - JesusPage: Main interface with Jesus image and user interaction
- `/audio-songs` - AudioSongsPage: Browse and select spiritual songs
- `/audio-player` - AudioPlayerPage: Audio playback interface
- `/bible` - BiblePage: Bible reading interface

### State Providers
- **appStateProvider**: Global app state (language, accessibility settings)
- **connectivityProvider**: Network connectivity status
- **audioProvider**: Audio playback state and controls

### Asset Organization
- **assets/images/**: Image assets including jesus.png
- **assets/svg/**: SVG graphics
- **assets/music/**: Audio files for spiritual content

## Key Implementation Notes

- The app enforces portrait orientation only
- Uses Material 3 design system with custom color schemes
- Implements comprehensive accessibility features including high contrast mode
- Error boundary wraps the entire app for graceful error handling
- Text scaling is clamped between 0.8x and 1.4x for readability
- Custom page transitions provide smooth navigation experience
- Focus management ensures proper keyboard and screen reader navigation