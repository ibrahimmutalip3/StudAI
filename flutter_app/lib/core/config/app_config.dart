/// Central configuration layer for the app.
///
/// SECURITY CONTRACT
/// ------------------
/// The Gemini API key is NEVER hardcoded, never committed to git, and never
/// stored in a `.env` file. It flows exclusively through this chain:
///
///   GitHub Repository Secret (GEMINI_API_KEY)
///        │  (injected by .github/workflows/*.yml)
///        ▼
///   flutter build ... --dart-define=GEMINI_API_KEY=***
///        │  (compiled into the binary at build time, not runtime)
///        ▼
///   String.fromEnvironment('GEMINI_API_KEY')   ← read ONLY here
///        │
///        ▼
///   AppConfig.geminiApiKey  →  GeminiAIService
///
/// Nothing outside this file should ever call `String.fromEnvironment`
/// directly for the API key. This keeps the "secret entry point" to a
/// single, auditable location.
///
/// If you build locally without passing `--dart-define=GEMINI_API_KEY=...`,
/// [geminiApiKey] will be empty and [hasValidApiKeyConfigured] will be
/// false. The AI layer is expected to check this and surface a clear,
/// user-facing "AI not configured" state rather than crash — see
/// [MissingApiKeyException] usage in `core/ai/gemini_ai_service.dart`.
library;

class AppConfig {
  AppConfig._();

  /// Read once, at compile time, from `--dart-define=GEMINI_API_KEY=...`.
  /// This is the ONLY place in the entire codebase this should be read.
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// True when a build actually injected a (non-empty) key.
  /// Does not validate the key is *correct* — only that one was provided.
  static bool get hasValidApiKeyConfigured => geminiApiKey.trim().isNotEmpty;

  /// Gemini model used for text/vision generation.
  /// Centralized here so upgrading models is a one-line change.
  ///
  /// NOTE: gemini-2.0-flash was shut down by Google on June 1, 2026 (see
  /// https://ai.google.dev/gemini-api/docs/deprecations) — any request to
  /// it now returns 404. gemini-3.5-flash is the current stable GA model
  /// as of September 2026, with no shutdown date announced. If this build
  /// is happening well after that, check the deprecations page above
  /// before assuming this string is still current.
  static const String geminiModel = 'gemini-3.5-flash';

  /// Base endpoint for the Gemini REST API (generateContent).
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Request timeout for any single Gemini call.
  static const Duration aiRequestTimeout = Duration(seconds: 45);

  /// Max image dimension (longest side, px) sent to Gemini for homework
  /// photo recognition. Larger images are downscaled client-side before
  /// upload to keep requests fast and within API limits.
  static const int maxImageDimensionPx = 1600;

  /// Max upload size (bytes) accepted for a single material file.
  static const int maxUploadBytes = 20 * 1024 * 1024; // 20 MB

  /// App-wide flag: is this a debug/dev build?
  static const bool isDebugBuild = bool.fromEnvironment(
    'dart.vm.product',
    defaultValue: false,
  ) ==
      false;

  /// Schema/version string stamped into exported data and AI conversation
  /// records, useful for future migrations.
  static const String appDataSchemaVersion = '1.0.0';

  /// Optional Syncfusion license key for the in-app PDF viewer
  /// (`syncfusion_flutter_pdfviewer`). Same `--dart-define` pattern as the
  /// Gemini key — never hardcoded, never committed.
  ///
  /// Not strictly required: the viewer works without it, but Syncfusion
  /// shows a small trial watermark in unlicensed release builds. Syncfusion
  /// offers a free Community License for individuals/small companies
  /// (https://www.syncfusion.com/sales/communitylicense) — register there,
  /// then pass the key at build time:
  ///   --dart-define=SYNCFUSION_LICENSE_KEY=...
  /// (add the equivalent secret + flag to the GitHub Actions workflows if
  /// you want CI builds to be watermark-free too). Left empty by default.
  static const String syncfusionLicenseKey = String.fromEnvironment(
    'SYNCFUSION_LICENSE_KEY',
    defaultValue: '',
  );
}
