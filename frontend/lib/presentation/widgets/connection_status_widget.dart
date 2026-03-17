import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/websocket_service.dart';
import '../providers/kline_provider.dart';

class ConnectionStatusWidget extends ConsumerWidget {
  const ConnectionStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(wsStatusProvider);

    return statusAsync.when(
      data: (status) {
        if (status == WebSocketStatus.connected) return const SizedBox.shrink();
        return _Banner(status: status);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.status});
  final WebSocketStatus status;

  @override
  Widget build(BuildContext context) {
    final (renk, metin, ikon) = switch (status) {
      WebSocketStatus.connecting => (
          AppTheme.warning,
          'Bağlanıyor...',
          Icons.sync_rounded,
        ),
      WebSocketStatus.polling => (
          const Color(0xFF0099ff),
          'HTTP polling modu — WebSocket bağlanamadı',
          Icons.wifi_tethering_rounded,
        ),
      WebSocketStatus.disconnected => (
          AppTheme.bearish,
          'Bağlantı kesildi — yeniden bağlanılıyor...',
          Icons.wifi_off_rounded,
        ),
      WebSocketStatus.error => (
          AppTheme.bearish,
          'Bağlantı hatası — yeniden deneniyor...',
          Icons.error_outline_rounded,
        ),
      _ => (AppTheme.bullish, 'Bağlı', Icons.wifi_rounded),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: renk.withValues(alpha: 0.12),
      child: Row(children: [
        Icon(ikon, size: 14, color: renk),
        const SizedBox(width: 8),
        Text(metin, style: TextStyle(fontSize: 11, color: renk, fontWeight: FontWeight.w600)),
        if (status == WebSocketStatus.polling) ...[
          const Spacer(),
          Text('2sn', style: TextStyle(fontSize: 9, color: renk.withValues(alpha: 0.6))),
        ],
      ]),
    );
  }
}
