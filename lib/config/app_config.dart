class AppConfig {
  AppConfig._();

  static const String openUVApiKey = String.fromEnvironment(
    'OPENUV_API_KEY',
    defaultValue: 'openuv-hl753rmmosurxz-io',
  );
}
