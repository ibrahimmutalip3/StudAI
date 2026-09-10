# StudAI — Personal AI Study Assistant

Flutter app in `flutter_app/`. See `flutter_app/DESIGN.md` for the design contract.

## Gemini API key setup (required before building)

No `.env` file is used anywhere in this project. The key is injected only
at build time via `--dart-define`, sourced from a GitHub Actions secret:

1. GitHub repo → **Settings → Secrets and variables → Actions → New repository secret**
2. Name: `GEMINI_API_KEY`
3. Value: your Gemini API key

Then push to `main` or run a workflow manually (**Actions** tab →
`Android Release Build` / `iOS Unsigned Build` → **Run workflow**).

- Android → `studai-android-release-apk` artifact (installable `.apk`)
- iOS → `studai-ios-unsigned-ipa` artifact (unsigned `.ipa`, sign it yourself
  with ESign or similar before installing on a device)

**Gemini model:** the model string is centralized in
`lib/core/config/app_config.dart` (`AppConfig.geminiModel`), currently
`gemini-3.5-flash`. Google regularly deprecates and shuts down Gemini
models (see https://ai.google.dev/gemini-api/docs/deprecations) — if AI
features suddenly stop working, check that page and update this one
constant.

## Optional: PDF viewer license (no watermark)

The in-app PDF viewer (`syncfusion_flutter_pdfviewer`) works without any
license, but unlicensed release builds show a small trial watermark.
Syncfusion offers a free Community License for individuals and small
companies: https://www.syncfusion.com/sales/communitylicense

1. GitHub repo → **Settings → Secrets and variables → Actions → New repository secret**
2. Name: `SYNCFUSION_LICENSE_KEY`
3. Value: your Syncfusion license key

Leave this secret unset and everything still works — the viewer just
shows the watermark.

## Local development

```bash
cd flutter_app
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

Without a key, the app runs fully offline (schedule, homework, notes,
materials, flashcards, statistics) and shows an honest "AI not configured"
state wherever Gemini would be used.
