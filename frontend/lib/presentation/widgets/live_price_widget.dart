import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../providers/market_provider.dart';
import '../providers/selected_coin_provider.dart';

class LivePriceWidget extends ConsumerWidget {
  const LivePriceWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sadece sembol değiştiğinde ana sarmalayıcıyı (container) rebuild yapıyoruz.
    // Diğer veriler aşağıdaki Consumer/Select üzerinden çekilecek.
    final symbol = ref.watch(selectedCoinProvider.select((coin) => coin.symbol.toUpperCase()));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: _MarketDataView(symbol: symbol),
    );
  }
}

// Fiyat değişimlerini izole edip performansı artırmak için ayrı bir widget
class _MarketDataView extends ConsumerWidget {
  final String symbol;
  const _MarketDataView({required this.symbol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sadece bu coinin market verisi güncellendiğinde burası rebuild olacak!
    // marketListProvider tüm coinleri içerir, .select sayeside sadece "ilgili coin" süzülüp takip edilir.
    final selectedMarket = ref.watch(marketListProvider.select((markets) {
      for (final m in markets) {
        if (m.symbol == symbol) return m;
      }
      return null;
    }));

    if (selectedMarket == null) {
      return const SizedBox(height: 38); // Yüklenme anında kaymayı önlemek için placeholder boşluk
    }

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              selectedMarket.symbol.replaceAll('USDT', '/USDT'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const SizedBox(width: 12),
            // KRİTİK EKLENTİ: Fiyat saniyede 5 kez değişebilir, bunu Paint tree'de izole ediyoruz:
            RepaintBoundary(
              child: _PriceAnimator(
                price: selectedMarket.price,
                changePercent: selectedMarket.changePercent,
              ),
            ),
          ],
        ),
        // Statik veriler 24s Yüksek/Düşük, bunlar daha az değişir fakat yine de izole etmek hızlandırır.
        RepaintBoundary(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStat('24s Yüksek', Formatters.formatKriptoFiyat(selectedMarket.high24h)),
              const SizedBox(width: 16),
              _buildStat('24s Düşük', Formatters.formatKriptoFiyat(selectedMarket.low24h)),
              const SizedBox(width: 16),
              _buildStat('24s Hacim', Formatters.formatHacim(selectedMarket.volume)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF6B6F8E), fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white)),
      ],
    );
  }
}

// Fiyatın kırmızı/yeşil parlama efekti için State yönetimi sağlayan özel görsel bileşen
class _PriceAnimator extends StatefulWidget {
  final double price;
  final double changePercent;

  const _PriceAnimator({required this.price, required this.changePercent});

  @override
  State<_PriceAnimator> createState() => _PriceAnimatorState();
}

class _PriceAnimatorState extends State<_PriceAnimator> {
  Color _flashColor = Colors.white;

  @override
  void didUpdateWidget(covariant _PriceAnimator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.price != oldWidget.price) {
      // Fiyat artarsa Yeşil, düşerse Kırmızı
      setState(() {
        _flashColor = widget.price > oldWidget.price ? AppTheme.bullish : AppTheme.bearish;
      });

      // 300ms sonra varsayılan renk olan beyaza geri dön
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _flashColor = Colors.white;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final changeColor = widget.changePercent >= 0 ? AppTheme.bullish : AppTheme.bearish;
    
    final formattedPrice = Formatters.formatKriptoFiyat(widget.price);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Fiyat Metni: Parlama animasyonunu burası yapar
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          style: TextStyle(
            fontSize: 24, 
            fontWeight: FontWeight.w800, 
            color: _flashColor,
            letterSpacing: -0.5,
          ),
          child: Text('\$$formattedPrice'),
        ),
        const SizedBox(width: 8),
        // Fiyat Yüzdelik Değişim Kutucuğu
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: changeColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${widget.changePercent >= 0 ? '+' : ''}${widget.changePercent.toStringAsFixed(2)}%',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: changeColor),
          ),
        ),
      ],
    );
  }
}
