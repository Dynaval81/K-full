/// Конфигурация flavor — определяет язык приложения.
/// Значение APP_LOCALE задаётся при сборке через productFlavors в build.gradle.kts
class FlavorConfig {
  /// Текущая локаль приложения — задаётся на этапе сборки.
  /// ru = русский, en = английский, de = немецкий
  static const String locale = String.fromEnvironment(
    'APP_LOCALE',
    defaultValue: 'ru',
  );
}
