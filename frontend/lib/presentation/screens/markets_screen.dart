import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../providers/selected_coin_provider.dart';

// ── Provider ───────────────────────────────────────────────────────────────

final marketsListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final url = Uri.parse('${AppConfig.httpBaseUrl}/api/piyasalar');
  final res = await http.get(url).timeout(const Duration(seconds: 12));
  if (res.statusCode != 200) throw Exception('Piyasa listesi alınamadı');
  return (json.decode(res.body) as List).cast<Map<String, dynamic>>();
});

final marketsSearchProvider = StateProvider<String>((ref) => '');
final marketsSortProvider = StateProvider<String>((ref) => 'hacim');

// ── Ekran ──────────────────────────────────────────────────────────────────

class MarketsScreen extends ConsumerWidget {
  const MarketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(marketsListProvider);
    final arama = ref.watch(marketsSearchProvider);
    final siralama = ref.watch(marketsSortProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // Arama + sıralama
          _AramaBar(arama: arama, siralama: siralama),
          // Tablo başlığı
          const _TabloBaslik(),
          // Liste
          Expanded(
            child: dataAsync.when(
              data: (liste) {
                var filtered = liste.where((m) {
                  if (arama.isEmpty) return true;
                  return (m['sembol'] as String)
                      .toLowerCase()
                      .contains(arama.toLowerCase());
                }).toList();

                // Sırala
                filtered.sort((a, b) {
                  switch (siralama) {
                    case 'degisim':
                      return (b['degisim_yuzde'] as num)
                          .abs()
                          .compareTo((a['degisim_yuzde'] as num).abs());
                    case 'fiyat':
                      return (b['fiyat'] as num)
                          .compareTo(a['fiyat'] as num);
                    default: // hacim
                      return (b['hacim_usdt'] as num)
                          .compareTo(a['hacim_usdt'] as num);
                  }
                });

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      '"$arama" bulunamadı',
                      style: const TextStyle(
                          color: Color(0xFF5a6080), fontSize: 13),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppTheme.primary,
                  backgroundColor: AppTheme.surface,
                  onRefresh: () => ref.refresh(marketsListProvider.future),
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) =>
                        _PiyasaSatiri(veri: filtered[i]),
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off_rounded,
                        color: AppTheme.bearish, size: 32),
                    const SizedBox(height: 12),
                    Text('Piyasa verisi alınamadı',
                        style: TextStyle(
                            color: AppTheme.bearish, fontSize: 13)),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => ref.refresh(marketsListProvider.future),
                      child: Text('Yeniden dene',
                          style: TextStyle(color: AppTheme.primary)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Alt bileşenler ──────────────────────────────────────────────────────────

class _AramaBar extends ConsumerWidget {
  const _AramaBar({required this.arama, required this.siralama});
  final String arama;
  final String siralama;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Row(
        children: [
          // Arama kutusu
          Expanded(
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: TextField(
                onChanged: (v) =>
                    ref.read(marketsSearchProvider.notifier).state = v,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Coin ara... (BTC, ETH)',
                  hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.2),
                      fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.3)),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Sıralama
          _SiralamaMenu(secili: siralama),
        ],
      ),
    );
  }
}

class _SiralamaMenu extends ConsumerWidget {
  const _SiralamaMenu({required this.secili});
  final String secili;

  static const _secenekler = {
    'hacim': 'Hacim',
    'degisim': 'Değişim',
    'fiyat': 'Fiyat',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: secili,
          dropdownColor: AppTheme.surfaceVariant,
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          icon: Icon(Icons.sort_rounded,
              size: 16,
              color: Colors.white.withValues(alpha: 0.4)),
          items: _secenekler.entries
              .map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) {
              ref.read(marketsSortProvider.notifier).state = v;
            }
          },
        ),
      ),
    );
  }
}

class _TabloBaslik extends StatelessWidget {
  const _TabloBaslik();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(children: const [
        Expanded(
          flex: 3,
          child: Text('Sembol',
              style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF5a6080),
                  fontWeight: FontWeight.w700)),
        ),
        Expanded(
          flex: 3,
          child: Text('Fiyat',
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF5a6080),
                  fontWeight: FontWeight.w700)),
        ),
        Expanded(
          flex: 2,
          child: Text('24s %',
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF5a6080),
                  fontWeight: FontWeight.w700)),
        ),
        SizedBox(width: 60,
          child: Text('Grafik',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF5a6080),
                  fontWeight: FontWeight.w700)),
        ),
        Expanded(
          flex: 3,
          child: Text('Hacim',
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF5a6080),
                  fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

class _PiyasaSatiri extends ConsumerWidget {
  const _PiyasaSatiri({required this.veri});
  final Map<String, dynamic> veri;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sembol = veri['sembol'] as String;
    final fiyat = (veri['fiyat'] as num).toDouble();
    final degisim = (veri['degisim_yuzde'] as num).toDouble();
    final hacim = (veri['hacim_usdt'] as num).toDouble();
    final sparkline = (veri['sparkline'] as List?)?.cast<num>() ?? [];
    final isPozitif = degisim >= 0;
    final color = isPozitif ? AppTheme.bullish : AppTheme.bearish;
    final base = sembol.replaceAll('USDT', '');

    return InkWell(
      onTap: () {
        ref.read(selectedCoinProvider.notifier).setSymbol(sembol.toLowerCase());
        // Geniş ekranda panel sekmesine geç
        if (MediaQuery.sizeOf(context).width > 900) {
          Navigator.of(context).pop();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.04)),
          ),
        ),
        child: Row(children: [
          // Sembol
          Expanded(
            flex: 3,
            child: Row(children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  base.length > 3 ? base.substring(0, 3) : base,
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(base,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text('USDT',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 10)),
              ]),
            ]),
          ),
          // Fiyat
          Expanded(
            flex: 3,
            child: Text(
              _fmtFiyat(fiyat),
              textAlign: TextAlign.right,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
          // Değişim
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${isPozitif ? '+' : ''}${degisim.toStringAsFixed(2)}%',
                  style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          // Mini grafik
          SizedBox(
            width: 60,
            height: 32,
            child: sparkline.length > 2
                ? CustomPaint(
                    painter: _SparklinePainter(
                        prices: sparkline
                            .map((n) => n.toDouble())
                            .toList(),
                        color: color),
                  )
                : const SizedBox(),
          ),
          // Hacim
          Expanded(
            flex: 3,
            child: Text(
              _fmtHacim(hacim),
              textAlign: TextAlign.right,
              style: const TextStyle(
                  color: Color(0xFF8890b0), fontSize: 11),
            ),
          ),
        ]),
      ),
    );
  }

  String _fmtFiyat(double v) {
    if (v >= 10000) return '\$${v.toStringAsFixed(0)}';
    if (v >= 1) return '\$${v.toStringAsFixed(2)}';
    if (v >= 0.01) return '\$${v.toStringAsFixed(4)}';
    return '\$${v.toStringAsFixed(6)}';
  }

  String _fmtHacim(double v) {
    if (v >= 1e9) return '\$${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '\$${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '\$${(v / 1e3).toStringAsFixed(0)}K';
    return '\$${v.toStringAsFixed(0)}';
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.prices, required this.color});
  final List<double> prices;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.length < 2) return;
    final min = prices.reduce((a, b) => a < b ? a : b);
    final max = prices.reduce((a, b) => a > b ? a : b);
    final range = max - min == 0 ? 1.0 : max - min;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (int i = 0; i < prices.length; i++) {
      final x = i / (prices.length - 1) * size.width;
      final y = size.height - (prices[i] - min) / range * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.prices != prices;
}
