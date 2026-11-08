class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );

  static const realtimeKey = String.fromEnvironment(
    'REVERB_APP_KEY',
    defaultValue: '6xishxfzssynxqynndsm',
  );

  static const realtimeHost = String.fromEnvironment(
    'REVERB_HOST',
    defaultValue: '127.0.0.1',
  );

  static const realtimePort = int.fromEnvironment(
    'REVERB_PORT',
    defaultValue: 8080,
  );

  static const realtimeScheme = String.fromEnvironment(
    'REVERB_SCHEME',
    defaultValue: 'http',
  );
}
