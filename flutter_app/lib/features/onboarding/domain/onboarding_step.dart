/// Steps in the onboarding flow. Kept as an enum (not a raw int index)
/// so the screen's PageView and the app bar back-button logic can't
/// silently drift out of sync.
enum OnboardingStep { splash, language, name, grade }
