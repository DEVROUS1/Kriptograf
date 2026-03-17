import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/whale_provider.dart';
import '../../data/models/whale_model.dart';

class WhaleScreen extends ConsumerStatefulWidget {
  const WhaleScreen({super.key});

  @override
  ConsumerState<WhaleScreen> createState() => _WhaleScreenState();
}

class _WhaleScreenState extends ConsumerState<WhaleScreen> {
  @override
  Widget build(BuildContext context) {
    final whaleAsync = ref.watch(whaleProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Balina Operasyonları (Canlı)',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: AppTheme.background,
        automaticallyImplyLeading: false,
      ),
      body: whaleAsync.when(
        data: (stats) => _buildBody(context, stats),
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (e, trace) => Center(
          child: Text('Ağ bağlantısında hata: $e',
              style: const TextStyle(color: AppTheme.bearish)),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WhaleStatsModel stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mega Header
          Row(
            children: [
              const Icon(Icons.waves_rounded, color: AppTheme.primary, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Küresel Balina Takip İstasyonu',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Mega Stats Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Column(
              children: [
                const Text('SON 24 SAAT BÜYÜK İŞLEM ORANI',
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6b6f8e),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PİYASA ALIMI \n(LONG / SPOT AL)',
                            style: TextStyle(fontSize: 10, color: AppTheme.bullish, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('%${stats.aliYuzde.toStringAsFixed(1)}',
                            style: const TextStyle(
                                fontSize: 24, color: AppTheme.bullish, fontWeight: FontWeight.w800)),
                        Text(_fmtUsd(stats.alisHacimUsd),
                            style: const TextStyle(
                                fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('PİYASA SATIŞI \n(SHORT / DİSTRİBÜSYON)',
                            textAlign: TextAlign.right,
                            style: TextStyle(fontSize: 10, color: AppTheme.bearish, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('%${(100 - stats.aliYuzde).toStringAsFixed(1)}',
                            style: const TextStyle(
                                fontSize: 24, color: AppTheme.bearish, fontWeight: FontWeight.w800)),
                        Text(_fmtUsd(stats.satisHacimUsd),
                            style: const TextStyle(
                                fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 12,
                    child: Row(
                      children: [
                        Flexible(
                          flex: stats.aliYuzde.round(),
                          child: Container(color: AppTheme.bullish),
                        ),
                        Flexible(
                          flex: (100 - stats.aliYuzde).round(),
                          child: Container(color: AppTheme.bearish),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('ANLIK BÜYÜK TRANSFERLER & PİYASA EMİRLERİ',
              style: TextStyle(
                  fontSize: 12, color: Color(0xFF5a6080), fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          // List of trades in big cards
          ...stats.islemler.map((t) => _MegaTradeRow(trade: t)),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  String _fmtUsd(int v) {
    if (v >= 1000000) return '\$${(v / 1000000).toStringAsFixed(2)} Milyon';
    return '\$${(v / 1000).toStringAsFixed(0)} Bin';
  }
}

class _MegaTradeRow extends StatelessWidget {
  const _MegaTradeRow({required this.trade});
  final WhaleTradeModel trade;

  @override
  Widget build(BuildContext context) {
    final bool isBuy = trade.alismi;
    final Color pColor = isBuy ? AppTheme.bullish : AppTheme.bearish;
    final String title = isBuy ? 'BALİNA ALIMI TESPİT EDİLDİ' : 'BÜYÜK SATIŞ / TRANSFER TESPİTİ';
    final IconData icon = isBuy ? Icons.rocket_launch_rounded : Icons.water_drop_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: pColor.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: pColor.withValues(alpha: 0.05),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: pColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: pColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: TextStyle(color: pColor, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    const Spacer(),
                    Text(trade.zaman, style: const TextStyle(color: Color(0xFF5a6080), fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 6),
                Text('${trade.usdFormatli} değerinde ${trade.sembol.replaceAll("USDT", "")} işlemi',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Gerçekleşen Miktar: ${trade.miktar} ${trade.sembol}',
                    style: const TextStyle(color: Color(0xFF8890b0), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
