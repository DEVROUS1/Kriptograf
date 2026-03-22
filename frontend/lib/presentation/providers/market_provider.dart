import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../data/models/market_model.dart';
import '../../config/app_config.dart';

final marketListProvider = StateNotifierProvider<MarketListNotifier, List<MarketModel>>((ref) {
  return MarketListNotifier();
});

class MarketListNotifier extends StateNotifier<List<MarketModel>> {
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  
  MarketListNotifier() : super([]) {
    _fetchInitialMarkets();
    _connectWebSocket();
  }
  
  Future<void> _fetchInitialMarkets() async {
    try {
      final response = await http.get(Uri.parse('${AppConfig.backendHttpUrl}/api/piyasalar'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        state = data.map((json) => MarketModel.fromJson(json)).toList();
      }
    } catch (e) {
      // Handle silently
    }
  }
  
  void _connectWebSocket() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse('${AppConfig.backendWsUrl}/ws/markets'));
      _channel!.stream.listen((message) {
        if (message == 'ping') {
          _channel!.sink.add('pong');
          return;
        }
        if (message == 'Rate limit exceeded') return;
        
        try {
          final List<dynamic> newJsonData = jsonDecode(message);
          final currentState = [...state];
          
          for (final json in newJsonData) {
            final parsed = MarketModel.fromJson(json);
            final index = currentState.indexWhere((m) => m.symbol == parsed.symbol);
            if (index != -1) {
              currentState[index] = currentState[index].copyWith(
                price: parsed.price,
                changePercent: parsed.changePercent,
                volume: parsed.volume,
                high24h: parsed.high24h,
                low24h: parsed.low24h,
              );
            } else {
              currentState.add(parsed);
            }
          }
          state = currentState;
        } catch (e) {
          // Parse error
        }
      }, onDone: () {
        _scheduleReconnect();
      }, onError: (e) {
        _scheduleReconnect();
      });
    } catch (e) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      _connectWebSocket();
    });
  }
  
  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}
