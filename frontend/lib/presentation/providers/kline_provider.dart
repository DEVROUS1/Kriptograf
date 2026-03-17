import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_config.dart';
import '../../core/network/websocket_service.dart';
import '../../data/models/kline_model.dart';
import 'selected_coin_provider.dart';

final wsServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  ref.onDispose(service.dispose);
  return service;
});

final wsStatusProvider = StreamProvider<WebSocketStatus>((ref) {
  final service = ref.watch(wsServiceProvider);
  return service.statusStream;
});

class KlineListNotifier extends StateNotifier<List<KlineModel>> {
  KlineListNotifier() : super([]);

  StreamSubscription<KlineModel>? _sub;
  WebSocketService? _service;

  void subscribe(String symbol, String interval) {
    _sub?.cancel();
    _service?.dispose();
    _service = WebSocketService();
    _service!.connect(symbol, interval);
    _sub = _service!.klineStream.listen(_onKline);
  }

  void _onKline(KlineModel incoming) {
    final list = [...state];
    if (list.isNotEmpty &&
        list.last.openTime == incoming.openTime &&
        !list.last.isClosed) {
      list[list.length - 1] = incoming;
    } else {
      list.add(incoming);
      if (list.length > AppConfig.maxKlineCount) {
        list.removeAt(0);
      }
    }
    state = list;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _service?.dispose();
    super.dispose();
  }
}

final klineListProvider =
    StateNotifierProvider<KlineListNotifier, List<KlineModel>>((ref) {
  final notifier = KlineListNotifier();
  final coin = ref.watch(selectedCoinProvider);
  notifier.subscribe(coin.symbol, coin.interval);
  return notifier;
});

final latestPriceProvider = Provider<double?>((ref) {
  final list = ref.watch(klineListProvider);
  return list.isEmpty ? null : list.last.close;
});

final priceChangeProvider = Provider<double?>((ref) {
  final list = ref.watch(klineListProvider);
  if (list.length < 2) return null;
  final first = list.first.open;
  final last = list.last.close;
  if (first == 0) return null;
  return ((last - first) / first) * 100;
});