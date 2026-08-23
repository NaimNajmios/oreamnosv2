# Oreamnos

**Oreamnos** is an AI-Assisted Social Media Curator built with Flutter. It helps you craft, refine, and curate social media posts using various AI providers (Gemini, Groq, OpenRouter, Cerebras).

## Features & Progress

Oreamnos is currently in development. Here is the progress so far:

### ✅ Phase 0: Foundation
- Flutter project scaffolding with Neo-Editorial design system.
- Light, Dark, and Deep Blue themes.
- Navigation using `go_router` and `ShellRoute`.

### 🚧 Phase 1: Settings & AI Provider Configuration (In Progress)
- **Implemented:** Full settings screen, AI provider selection (Gemini, Groq, OpenRouter, Cerebras), API key management with secure storage (`flutter_secure_storage`), Tone toggle, and Theme switcher.
- **Pending:** Model selection per provider and connection testing.

### 🔜 Upcoming Phases
- **Content Generation Core**: Prompt manager, web content extraction, and content curation.
- **Share Intent**: Android/iOS share sheet integration for receiving URLs and text.
- **Output & Refinement**: Output cards with refinement tools (rephrase, check flow).
- **Hashtag & Usage Stats**: Hashtag management and token tracking.
- **Card Generator**: Generate visual cards from text for sharing.
- **Vision Extraction**: ML Kit and AI OCR for image text extraction.

## Getting Started

To run the app locally:

1. Ensure you have Flutter installed.
2. Clone this repository.
3. Run `flutter pub get` to install dependencies.
4. Run the app on your preferred device/emulator using `flutter run`.

For full migration plans and architecture details, refer to `project_context/migration_plan`.
