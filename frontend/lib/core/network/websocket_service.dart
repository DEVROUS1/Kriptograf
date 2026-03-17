import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../config/app_config.dart';
import '../../data/models/kline_model.dart';

enum WebSocketStatus { disconnected, connecting, connected, polling, error }

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _reconnectTimer;
  Timer? _pollTimer;

  final _klineCtrl = StreamController<KlineModel>.broadcast();
  final _statusCtrl = StreamController<WebSocketStatus>.broadcast();

  int _reconnectAttempts = 0;
  static const int _maxAttempts = 8;
  bool _disposed = false;
  bool _pollingMode = false;

  String? _symbol;
  String? _interval;

  Stream<KlineModel> get klineStream => _klineCtrl.stream;
  Stream<WebSocketStatus> get statusStream => _statusCtrl.stream;

  void connect(String symbol, String interval) {
    if (_symbol == symbol && _interval == interval) return;
    _symbol = symbol;
    _interval = interval;
    _reconnectAttempts = 0;
    _pollingMode = false;
    _temizle();
    _baglan();
  }

  void _baglan() {
    if (_disposed) return;
    _statusCtrl.add(WebSocketStatus.connecting);
    final uri = Uri.parse('${AppConfig.wsBaseUrl}/ws/kline/$_symbol/$_interval');
    try {
      _channel = WebSocketChannel.connect(uri);
      _sub = _channel!.stream.listen(
        _onMesaj,
        onError: _onHata,
        onDone: _onKapandi,
        cancelOnError: false,
      );
      _statusCtrl.add(WebSocketStatus.connected);
      _reconnectAttempts = 0;
      _pollingMode = false;
    } catch (e) {
      debugPrint('[WS] Bağlantı hatası: $e');
      _yenidenBaglan();
    }
  }

  void _onMesaj(dynamic raw) {
    try {
      final data = json.decode(raw as String) as Map<String, dynamic>;
      if (data['type'] == 'ping') {
        _channel?.sink.add(json.encode({'type': 'pong'}));
        return;
      }
      if (data['type'] == 'error') return;
      if (data.containsKey('k') || data.containsKey('t')) {
        _klineCtrl.add(KlineModel.fromJson(data));
      }
    } catch (e) {
      debugPrint('[WS] Parse hatası: $e');
    }
  }

  void _onHata(Object error) {
    debugPrint('[WS] Hata: $error');
    _statusCtrl.add(WebSocketStatus.error);
    _yenidenBaglan();
  }

  void _onKapandi() {
    if (!_disposed) _yenidenBaglan();
  }

  void _yenidenBaglan() {
    if (_disposed) return;
    _reconnectAttempts++;
    if (_reconnectAttempts >= _maxAttempts) {
      _pollingBaslat();
      return;
    }
    final ms = (1000 * (1 << _reconnectAttempts.clamp(0, 6))).clamp(1000, 32000);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: ms), _baglan);
  }

  void _pollingBaslat() {
    if (_disposed || _pollingMode) return;
    _pollingMode = true;
    _statusCtrl.add(WebSocketStatus.polling);
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _pollFiyat());
    _pollFiyat();
  }

  Future<void> _pollFiyat() async {
    if (_disposed || _symbol == null) return;
    try {
      final usdt = _symbol!.toUpperCase() +
          (_symbol!.toUpperCase().endsWith('USDT') ? '' : 'USDT');
      final url = Uri.parse(
        'https://api.binance.com/api/v3/klines'
        '?symbol=$usdt&interval=${_interval ?? '1m'}&limit=1',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final raw = json.decode(res.body) as List;
        if (raw.isNotEmpty) {
          final k = raw[0] as List;
          _klineCtrl.add(KlineModel(
            openTime: (k[0] as num).toInt(),
            open: double.parse(k[1].toString()),
            high: double.parse(k[2].toString()),
            low: double.parse(k[3].toString()),
            close: double.parse(k[4].toString()),
            volume: double.parse(k[5].toString()),
            closeTime: (k[6] as num).toInt(),
            isClosed: true,
            quoteVolume: double.parse(k[7].toString()),
            numberOfTrades: (k[8] as num).toInt(),
          ));
        }
      }
    } catch (e) {
      debugPrint('[POLL] Hata: $e');
    }
  }

  void _temizle() {
    _reconnectTimer?.cancel();
    _pollTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    _channel = null;
    _sub = null;
  }

  void dispose() {
    _disposed = true;
    _temizle();
    _klineCtrl.close();
    _statusCtrl.close();
  }
}