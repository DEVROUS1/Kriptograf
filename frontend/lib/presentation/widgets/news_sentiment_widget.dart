import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/ai_provider.dart';
import 'common/shimmer_card.dart';

class NewsSentimentWidget extends ConsumerWidget {
  const NewsSentimentWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(newsSentimentProvider);

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
                  decoration: const BoxDecoration(color: Color(0xFF0099ff), shape: BoxShape.circle)),
              const SizedBox(width: 7),
              const Text('HABER DUYGU ANALİZİ',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                      color: Color(0xFF5a6080), letterSpacing: 0.8)),
            ]),
          ),
          dataAsync.when(
            data: (d) => _Body(data: d),
            loading: () => const ShimmerCard(height: 180),
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
    if (data.containsKey('durum') && data['durum'] == 'hata') {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text('Haber sunucusuna ulaşılamadı.',
              style: TextStyle(color: AppTheme.bearish, fontSize: 11)),
        ),
      );
    }

    if (!data.containsKey('istatistik') || data['istatistik'] == null) {
      return const SizedBox.shrink();
    }

    final ist = data['istatistik'] as Map<String, dynamic>;
    final poz = (ist['pozitif_yuzde'] as num).toInt();
    final genel = ist['genel_duygu'] as String;
    final haberler = (data['haberler'] as List).cast<Map<String, dynamic>>();

    final genelRenk = genel == 'OLUMLU'
        ? AppTheme.bullish
        : genel == 'OLUMSUZ'
            ? AppTheme.bearish
            : AppTheme.warning;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: Row(children: [
                  Flexible(flex: poz, child: Container(color: AppTheme.bullish)),
                  Flexible(flex: 100 - poz, child: Container(color: AppTheme.bearish)),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: genelRenk.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(genel,
                style: TextStyle(fontSize: 10, color: genelRenk, fontWeight: FontWeight.w800)),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Olumlu %$poz',
                  style: const TextStyle(fontSize: 10, color: AppTheme.bullish, fontWeight: FontWeight.w600)),
              Text('${ist['toplam']} haber',
                  style: const TextStyle(fontSize: 9, color: Color(0xFF5a6080))),
              Text('Olumsuz %${100 - poz}',
                  style: const TextStyle(fontSize: 10, color: AppTheme.bearish, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        ...haberler.take(5).map((h) {
          final duygu = h['duygu'] as String;
          final color = duygu == 'POZİTİF'
              ? AppTheme.bullish
              : duygu == 'NEGATİF'
                  ? AppTheme.bearish
                  : Colors.white38;
          return Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Container(
                  width: 4, height: 4,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(h['baslik'] as String,
                    style: const TextStyle(color: Color(0xFFc0c4dc), fontSize: 11, height: 1.4),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                Text(h['kaynak'] as String,
                    style: const TextStyle(fontSize: 9, color: Color(0xFF5a6080))),
              ])),
            ]),
          );
        }),
      ]),
    );
  }
}
