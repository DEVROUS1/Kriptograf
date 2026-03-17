class AppConfig {
  AppConfig._();

  static const String _backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:8000',
  );

  static String get httpBaseUrl => _backendUrl;
  static String get backendHttpUrl => _backendUrl;

  static String get wsBaseUrl {
    return _backendUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
  }

  static String get backendWsUrl => wsBaseUrl;

  static const List<String> supportedSymbols = [
    'btcusdt', 'ethusdt', 'bnbusdt', 'solusdt', 'xrpusdt',
    'adausdt', 'dogeusdt', 'avaxusdt', 'maticusdt', 'dotusdt',
    'linkusdt', 'uniusdt', 'atomusdt', 'ltcusdt', 'bchusdt',
  ];

  static const List<String> supportedIntervals = [
    '1s', '1m', '3m', '5m', '15m', '30m', '1h', '4h', '1d',
  ];

  static const Map<String, String> intervalLabels = {
    '1s': '1sn', '1m': '1dk', '3m': '3dk', '5m': '5dk',
    '15m': '15dk', '30m': '30dk', '1h': '1sa', '4h': '4sa', '1d': '1g',
  };

  static const int maxKlineCount = 200;
}