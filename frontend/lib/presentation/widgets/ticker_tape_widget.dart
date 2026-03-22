import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../providers/market_provider.dart';

class TickerTapeWidget extends ConsumerStatefulWidget {
  const TickerTapeWidget({super.key});

  @override
  ConsumerState<TickerTapeWidget> createState() => _TickerTapeWidgetState();
}

class _TickerTapeWidgetState extends ConsumerState<TickerTapeWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 240))..repeat();
    _controller.addListener(() {
      if (_scrollController.hasClients) {
        double maxScroll = _scrollController.position.maxScrollExtent;
        double currentScroll = maxScroll * _controller.value;
        _scrollController.jumpTo(currentScroll);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final markets = ref.watch(marketListProvider);
    if (markets.isEmpty) return const SizedBox();

    final topMarkets = markets.take(20).toList();
    final repeatedMarkets = [...topMarkets, ...topMarkets, ...topMarkets, ...topMarkets]; // Smoother illusion

    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          children: repeatedMarkets.map((m) {
            final isPositive = m.changePercent >= 0;
            final color = isPositive ? AppTheme.bullish : AppTheme.bearish;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(m.symbol.replaceAll('USDT', ''), style: const TextStyle(color: Color(0xFFa0a4bc), fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Text('\$${Formatters.formatKriptoFiyat(m.price)}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 6),
                  Text('${isPositive ? '+' : ''}${m.changePercent.toStringAsFixed(1)}%', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
