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
    'btcusdt', 'ethusdt', 'solusdt', 'xrpusdt', 'zecusdt', 'dogeusdt', '1000pepeusdt', 'bnxusdt', 'bnbusdt', 'taousdt', 'animeusdt', 'polyxusdt', 'asterusdt', 'degousdt', 'adausdt', 'suiusdt', 'trumpusdt', 'avaxusdt', 'nearusdt', 'linkusdt', 'dotusdt', 'cfgusdt', 'vanryusdt', 'fetusdt', 'filusdt', 'paxgusdt', 'vidtusdt', 'sxpusdt', 'agixusdt', 'ltcusdt', 'wldusdt', 'linausdt', 'memefiusdt', 'enausdt', 'leverusdt', 'neiroethusdt', 'ftmusdt', 'bchusdt', 'pixelusdt', 'crclusdt', 'xplusdt', 'trxusdt', 'wavesusdt', 'aaveusdt', 'wifusdt', 'uniusdt', 'omniusdt', 'yalausdt', 'ambusdt', 'hyperusdt', 'triausdt', 'bswusdt', 'oceanusdt', 'beatusdt', 'straxusdt', 'dashusdt', 'penguusdt', 'renusdt', 'unfiusdt', 'opnusdt', 'virtualusdt', '1000shibusdt', 'grassusdt', 'renderusdt', 'dgbusdt', '1000bonkusdt', 'troyusdt', 'humausdt', 'arbusdt', 'irusdt', 'xlmusdt', 'banusdt', 'kiteusdt', 'hbarusdt', 'crvusdt', 'litusdt', 'xanusdt', 'rvnusdt', 'hifiusdt', 'aptusdt', 'tlmusdt', 'tslausdt', 'omusdt', 'xmrusdt', 'icpusdt', 'tonusdt', 'zenusdt', 'shibusdt', 'ldousdt', 'opudsdt', 'mkrudst', 'axsusdt', 'sandusdt', 'manausdt', 'flowusdt', 'galausdt', 'runeusdt', 'injusdt', 'lqtyusdt', 'rdntusdt'
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