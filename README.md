# Oreamnos

**Oreamnos** is an AI-Assisted Social Media Curator built with Flutter. It helps you craft, refine, and curate social media posts from football news using various AI providers (Gemini, Groq, OpenRouter, Cerebras), transforming them into highly engaging Malaysian Malay content.

## Features & Progress

Oreamnos is currently in development. Here is the progress so far:

### ✅ Phase 0: Foundation
- Flutter project scaffolding with a **Flat Minimalist** design system and Material 3 Dynamic Color support.
- Custom Light, Dark, and Deep Blue themes.
- Navigation using `go_router` and `ShellRoute`.

### ✅ Phase 1: Settings & AI Provider Configuration
- **Implemented:** Full settings screen, AI provider selection (Gemini, Groq, OpenRouter, Cerebras), API key management with secure storage (`flutter_secure_storage`), Tone toggle, and Theme switcher.
- **Implemented:** Dynamic model fetching per provider and implicit connection testing.

### ✅ Phase 2: Content Generation Core
- **Implemented:** `PromptManager` for generating system instructions based on user preferences.
- **Implemented:** AI service layer with `IContentCurator` abstraction, `CuratorFactory`, and provider-specific REST API wrappers.
- **Implemented:** Generate screen UI featuring a custom `TypewriterMarkdown` widget for streaming AI responses beautifully.

### ✅ Phase 3: Share Intent & Input
- **Implemented:** Android share intent handling (receive text/URLs), URL metadata extraction via web scraping, clipboard paste detection, and direct routing to the Generate screen.

### ✅ Phase 4: Output & Refinement
- **Implemented:** Output card with swipe gestures (copy/share), Refinement pills (Rephrase, Check Flow, Shorter) for AI revision, and a full-screen immersive Reading Mode.

### ✅ Phase 5: Hashtag Manager
- **Implemented:** Custom hashtag grouping and management, dynamic default hashtag injection.

### ✅ Phase 6: Usage Statistics & Analytics
- **Implemented:** Rolling window tracking of token usage, latency, and success rates, custom Flutter Canvas (`CustomPainter`) line charts for visual data representation, and dashboard history in Settings.

### ✅ Phase 7: Card Generator
- **Implemented:** Custom `CardData` model with deterministic JSON extraction.
- **Implemented:** Multiple templates (Standard, Breaking News, Quote) and custom backgrounds.
- **Implemented:** Native high-quality PNG export (Gallery Saving) and sharing mechanisms via `RepaintBoundary` and `gal`.

## 🚧 Upcoming (Migration Plan)

- **Phase 8:** Vision Extraction (ML Kit OCR, platform-specific models)
- **Phase 9:** Polish & Platform Features (Haptics, Spring animations, background services)

## Getting Started

To run the app locally:

1. Ensure you have Flutter installed.
2. Clone this repository.
3. Run `flutter pub get` to install dependencies.
4. Run the app on your preferred device/emulator using `flutter run`.

For full migration plans and architecture details, refer to `project_context/migration_plan`.
