import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/selected_coin_provider.dart';
import '../providers/market_provider.dart';

class OrderBookWidget extends ConsumerStatefulWidget {
  const OrderBookWidget({super.key});

  @override
  ConsumerState<OrderBookWidget> createState() => _OrderBookWidgetState();
}

class _OrderBookWidgetState extends ConsumerState<OrderBookWidget> with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  final _rnd = Random();
  late List<_OrderRow> _asks;
  late List<_OrderRow> _bids;
  double _currentPrice = 0.0;
  String _symbol = '';

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _asks = [];
    _bids = [];
    
    // Yarı rastgele güncelleme motoru
    Future.delayed(const Duration(milliseconds: 500), _updateBookLoop);
  }

  void _updateBookLoop() {
    if (!mounted) return;
    
    if (_currentPrice > 0) {
      _generateFakeBook();
      _anim.forward(from: 0.0);
      setState(() {});
    }
    
    // Her 500-1500 ms arası güncelle
    Future.delayed(Duration(milliseconds: 500 + _rnd.nextInt(1000)), _updateBookLoop);
  }

  void _generateFakeBook() {
    final askList = <_OrderRow>[];
    final bidList = <_OrderRow>[];
    
    double maxVol = 0.0;
    
    // Asks (Sells)
    for (int i = 0; i < 7; i++) {
        // Fiyatlar gitgide artar (yukarı doğru)
        final p = _currentPrice * (1 + (0.0001 * (9 - i)) + (_rnd.nextDouble() * 0.0005));
        final v = 0.5 + _rnd.nextDouble() * 15.0; // 0.5 ile 15.5 arası
        if (v > maxVol) maxVol = v;
        askList.add(_OrderRow(price: p, volume: v));
    }
    
    // Bids (Buys)
    for (int i = 0; i < 7; i++) {
        // Fiyatlar gitgide azalır (aşağı doğru)
        final p = _currentPrice * (1 - (0.0001 * (i + 1)) - (_rnd.nextDouble() * 0.0005));
        final v = 0.5 + _rnd.nextDouble() * 15.0;
        if (v > maxVol) maxVol = v;
        bidList.add(_OrderRow(price: p, volume: v));
    }
    
    for (var a in askList) { a.depth = a.volume / maxVol; }
    for (var b in bidList) { b.depth = b.volume / maxVol; }
    
    _asks = askList;
    _bids = bidList;
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coin = ref.watch(selectedCoinProvider.select((c) => c.symbol.toUpperCase()));
    final piyasalar = ref.watch(marketListProvider);
    
    if (coin != _symbol) {
      _symbol = coin;
      _currentPrice = 0;
    }
    
    if (piyasalar.isNotEmpty) {
      try {
        final guncel = piyasalar.firstWhere((p) => p.symbol == coin).price;
        if (_currentPrice == 0) {
           _currentPrice = guncel;
           _generateFakeBook();
        } else {
           // Gerçek fiyata yakınsın diye arada bir güncelle
           _currentPrice = guncel;
        }
      } catch (_) {}
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(symbol: _symbol),
          
          if (_asks.isEmpty && _bids.isEmpty)
             const Padding(
               padding: EdgeInsets.all(20.0),
               child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
             )
          else ...[
            // Title Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                children: [
                  const Text('FİYAT', style: TextStyle(color: Color(0xFF6b6f8e), fontSize: 9, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  const Text('MİKTAR', style: TextStyle(color: Color(0xFF6b6f8e), fontSize: 9, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 25),
                  const Text('TOPLAM', style: TextStyle(color: Color(0xFF6b6f8e), fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            
            // Asks (Sells)
            ..._asks.map((a) => _buildRow(a, true)),
            
            // Current Market Price Center
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: Colors.white.withValues(alpha: 0.02),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Row(
                     children: [
                        Text(_currentPrice.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_upward_rounded, color: AppTheme.bullish, size: 14),
                     ]
                   ),
                   const Text('SÜREKLİ', style: TextStyle(color: Color(0xFF5a6080), fontSize: 10, letterSpacing: 0.5)),
                ],
              ),
            ),
            
            // Bids (Buys)
            ..._bids.map((b) => _buildRow(b, false)),
            const SizedBox(height: 8),
          ]
        ],
      ),
    );
  }

  Widget _buildRow(_OrderRow row, bool isAsk) {
    final cColor = isAsk ? AppTheme.bearish : AppTheme.bullish;
    return FadeTransition(
      opacity: _anim,
      child: SizedBox(
        height: 22,
        child: Stack(
          children: [
             // Depth Background
             Positioned(
               right: 0, top: 0, bottom: 0,
               width: MediaQuery.sizeOf(context).width * 0.35 * row.depth, // Max 35% of container
               child: Container(
                 color: cColor.withValues(alpha: 0.15),
               ),
             ),
             // Texts
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 14),
               child: Row(
                 children: [
                   Text(row.price.toStringAsFixed(2), style: TextStyle(color: cColor, fontSize: 11, fontWeight: FontWeight.w600)),
                   const Spacer(),
                   Text(row.volume.toStringAsFixed(3), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                   const SizedBox(width: 20),
                   SizedBox(
                     width: 45,
                     child: Text((row.price * row.volume / 1000).toStringAsFixed(1) + 'K', 
                       textAlign: TextAlign.right, style: const TextStyle(color: Color(0xFF8890b0), fontSize: 11, fontWeight: FontWeight.w500)),
                   )
                 ],
               ),
             ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String symbol;
  const _Header({required this.symbol});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          const Text('CANLI EMİR DEFTERİ TR',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                  color: Color(0xFF5a6080), letterSpacing: 0.8)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(symbol.replaceAll('USDT', ''),
                style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _OrderRow {
  final double price;
  final double volume;
  double depth;
  _OrderRow({required this.price, required this.volume, this.depth = 0});
}
