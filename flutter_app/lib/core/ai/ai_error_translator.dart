import 'ai_service.dart';

/// Maps AI/network exceptions to a short, honest, non-technical message
/// plus a suggested recovery action label. UI layers use this instead of
/// showing stack traces or raw exception text (product spec §26).
class AiErrorPresentation {
  final String message;
  final String actionLabel;
  final bool isRetryable;

  const AiErrorPresentation({
    required this.message,
    required this.actionLabel,
    required this.isRetryable,
  });
}

class AiErrorTranslator {
  AiErrorTranslator._();

  static AiErrorPresentation translate(Object error, {String localeCode = 'en'}) {
    if (error is MissingApiKeyException) {
      return _forLocale(localeCode, _Kind.missingKey);
    }
    if (error is AINetworkException) {
      return _forLocale(localeCode, _Kind.network);
    }
    if (error is AIApiException) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        return _forLocale(localeCode, _Kind.invalidKey);
      }
      if (error.statusCode == 429) {
        return _forLocale(localeCode, _Kind.rateLimit);
      }
      return _forLocale(localeCode, _Kind.serverError);
    }
    if (error is AIParsingException) {
      return _forLocale(localeCode, _Kind.parsing);
    }
    return _forLocale(localeCode, _Kind.unknown);
  }

  static AiErrorPresentation _forLocale(String locale, _Kind kind) {
    switch (locale) {
      case 'ru':
        return _ru(kind);
      case 'hy':
        return _hy(kind);
      default:
        return _en(kind);
    }
  }

  static AiErrorPresentation _en(_Kind kind) {
    switch (kind) {
      case _Kind.missingKey:
        return const AiErrorPresentation(
          message: 'AI features aren\'t set up for this build yet.',
          actionLabel: 'Learn more',
          isRetryable: false,
        );
      case _Kind.invalidKey:
        return const AiErrorPresentation(
          message: 'The AI service rejected this build\'s access key.',
          actionLabel: 'Learn more',
          isRetryable: false,
        );
      case _Kind.network:
        return const AiErrorPresentation(
          message: 'No internet connection.',
          actionLabel: 'Try again',
          isRetryable: true,
        );
      case _Kind.rateLimit:
        return const AiErrorPresentation(
          message: 'Too many requests right now. Please wait a moment.',
          actionLabel: 'Try again',
          isRetryable: true,
        );
      case _Kind.serverError:
        return const AiErrorPresentation(
          message: 'The AI service is temporarily unavailable.',
          actionLabel: 'Try again',
          isRetryable: true,
        );
      case _Kind.parsing:
        return const AiErrorPresentation(
          message: 'The AI response couldn\'t be understood.',
          actionLabel: 'Try again',
          isRetryable: true,
        );
      case _Kind.unknown:
        return const AiErrorPresentation(
          message: 'Something went wrong. Please try again.',
          actionLabel: 'Try again',
          isRetryable: true,
        );
    }
  }

  static AiErrorPresentation _ru(_Kind kind) {
    switch (kind) {
      case _Kind.missingKey:
        return const AiErrorPresentation(
          message: 'Функции ИИ ещё не настроены для этой сборки.',
          actionLabel: 'Подробнее',
          isRetryable: false,
        );
      case _Kind.invalidKey:
        return const AiErrorPresentation(
          message: 'Сервис ИИ отклонил ключ доступа этой сборки.',
          actionLabel: 'Подробнее',
          isRetryable: false,
        );
      case _Kind.network:
        return const AiErrorPresentation(
          message: 'Нет подключения к интернету.',
          actionLabel: 'Повторить',
          isRetryable: true,
        );
      case _Kind.rateLimit:
        return const AiErrorPresentation(
          message: 'Слишком много запросов. Подождите немного.',
          actionLabel: 'Повторить',
          isRetryable: true,
        );
      case _Kind.serverError:
        return const AiErrorPresentation(
          message: 'Сервис ИИ временно недоступен.',
          actionLabel: 'Повторить',
          isRetryable: true,
        );
      case _Kind.parsing:
        return const AiErrorPresentation(
          message: 'Не удалось разобрать ответ ИИ.',
          actionLabel: 'Повторить',
          isRetryable: true,
        );
      case _Kind.unknown:
        return const AiErrorPresentation(
          message: 'Что-то пошло не так. Попробуйте ещё раз.',
          actionLabel: 'Повторить',
          isRetryable: true,
        );
    }
  }

  static AiErrorPresentation _hy(_Kind kind) {
    switch (kind) {
      case _Kind.missingKey:
        return const AiErrorPresentation(
          message: 'AI գործառույթները դեռ կարգավորված չեն այս տարբերակի համար։',
          actionLabel: 'Իմանալ ավելին',
          isRetryable: false,
        );
      case _Kind.invalidKey:
        return const AiErrorPresentation(
          message: 'AI ծառայությունը մերժեց այս տարբերակի հասանելիության բանալին։',
          actionLabel: 'Իմանալ ավելին',
          isRetryable: false,
        );
      case _Kind.network:
        return const AiErrorPresentation(
          message: 'Ինտերնետ կապ չկա։',
          actionLabel: 'Կրկին փորձել',
          isRetryable: true,
        );
      case _Kind.rateLimit:
        return const AiErrorPresentation(
          message: 'Չափազանց շատ հարցումներ։ Խնդրում ենք սպասել։',
          actionLabel: 'Կրկին փորձել',
          isRetryable: true,
        );
      case _Kind.serverError:
        return const AiErrorPresentation(
          message: 'AI ծառայությունը ժամանակավորապես անհասանելի է։',
          actionLabel: 'Կրկին փորձել',
          isRetryable: true,
        );
      case _Kind.parsing:
        return const AiErrorPresentation(
          message: 'AI պատասխանը հնարավոր չէր մշակել։',
          actionLabel: 'Կրկին փորձել',
          isRetryable: true,
        );
      case _Kind.unknown:
        return const AiErrorPresentation(
          message: 'Ինչ-որ բան այն չէ։ Խնդրում ենք կրկին փորձել։',
          actionLabel: 'Կրկին փորձել',
          isRetryable: true,
        );
    }
  }
}

enum _Kind {
  missingKey,
  invalidKey,
  network,
  rateLimit,
  serverError,
  parsing,
  unknown,
}
