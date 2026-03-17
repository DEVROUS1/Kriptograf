import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/global_markets_provider.dart';

class CorrelationWidget extends ConsumerWidget {
  const CorrelationWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(correlationProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(children: [
              Container(width: 8, height: 8,
                  decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle)),
              const SizedBox(width: 7),
              const Text('BTC MAKRO KORELASYON (30G)',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                      color: Color(0xFF5a6080), letterSpacing: 0.8)),
            ]),
          ),
          dataAsync.when(
            data: (d) => _Body(data: d),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => const SizedBox(height: 40),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final satirlar = [
      ('S&P 500', data['sp500']),
      ('NASDAQ', data['nasdaq']),
      ('Altın', data['altin']),
      ('Dolar Endeksi', data['dxy']),
    ];

    return Column(
      children: [
        // Özet
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              data['ozet'] as String,
              style: const TextStyle(color: Color(0xFFa0a4bc), fontSize: 11, height: 1.5),
            ),
          ),
        ),
        ...satirlar.map((s) {
          final isim = s.$1;
          final kor = s.$2 as Map<String, dynamic>;
          final deger = (kor['deger'] as num?)?.toDouble();
          return _KorelasyonSatiri(isim: isim, korelasyon: deger);
        }),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _KorelasyonSatiri extends StatelessWidget {
  const _KorelasyonSatiri({required this.isim, required this.korelasyon});
  final String isim;
  final double? korelasyon;

  @override
  Widget build(BuildContext context) {
    final k = korelasyon ?? 0;
    final color = k > 0.3
        ? AppTheme.bullish
        : k < -0.3
            ? AppTheme.bearish
            : AppTheme.warning;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: Row(children: [
        SizedBox(
          width: 110,
          child: Text(isim, style: const TextStyle(color: Color(0xFFa0a4bc), fontSize: 11)),
        ),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Arka plan çizgisi
              Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
              // Merkez nokta
              Center(child: Container(width: 2, height: 8, color: Colors.white.withValues(alpha: 0.1))),
              // Korelasyon barı
              Align(
                alignment: Alignment(k.clamp(-1.0, 1.0), 0),
                child: Container(
                  width: 3, height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 50,
          child: Text(
            korelasyon != null ? k.toStringAsFixed(2) : '-',
            textAlign: TextAlign.right,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ]),
    );
  }
}
