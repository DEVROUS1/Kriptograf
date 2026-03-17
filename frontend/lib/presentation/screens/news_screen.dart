import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../providers/ai_provider.dart';

class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key});

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // Tab bar
          Container(
            color: AppTheme.surface,
            child: TabBar(
              controller: _tab,
              tabs: const [
                Tab(text: 'Haberler'),
                Tab(text: 'Duygu Analizi'),
              ],
              labelColor: AppTheme.primary,
              unselectedLabelColor: Color(0xFF5a6080),
              indicatorColor: AppTheme.primary,
              indicatorSize: TabBarIndicatorSize.label,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: const [
                _HaberListesi(),
                _DuyguAnalizi(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Haber Listesi ──────────────────────────────────────────────────────────

class _HaberListesi extends ConsumerWidget {
  const _HaberListesi();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(newsSentimentProvider);

    return dataAsync.when(
      data: (d) {
        final haberler =
            (d['haberler'] as List).cast<Map<String, dynamic>>();
        if (haberler.isEmpty) {
          return const Center(
            child: Text('Haber bulunamadı',
                style: TextStyle(color: Color(0xFF5a6080))),
          );
        }
        return RefreshIndicator(
          color: AppTheme.primary,
          backgroundColor: AppTheme.surface,
          onRefresh: () => ref.refresh(newsSentimentProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: haberler.length,
            itemBuilder: (ctx, i) => _HaberKarti(haber: haberler[i]),
          ),
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.newspaper_rounded,
                color: AppTheme.bearish, size: 32),
            const SizedBox(height: 12),
            Text('Haberler alınamadı',
                style: TextStyle(color: AppTheme.bearish, fontSize: 13)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => ref.refresh(newsSentimentProvider.future),
              child: Text('Yeniden dene',
                  style: TextStyle(color: AppTheme.primary)),
            ),
          ],
        ),
      ),
    );
  }
}

class _HaberKarti extends StatelessWidget {
  const _HaberKarti({required this.haber});
  final Map<String, dynamic> haber;

  @override
  Widget build(BuildContext context) {
    final baslik = haber['baslik'] as String;
    final kaynak = haber['kaynak'] as String;
    final zaman = haber['zaman'] as String;
    final link = haber['link'] as String;
    final duygu = haber['duygu'] as String;

    final duyguRenk = duygu == 'POZİTİF'
        ? AppTheme.bullish
        : duygu == 'NEGATİF'
            ? AppTheme.bearish
            : Colors.white38;

    final duyguIkon = duygu == 'POZİTİF'
        ? Icons.trending_up_rounded
        : duygu == 'NEGATİF'
            ? Icons.trending_down_rounded
            : Icons.trending_flat_rounded;

    return GestureDetector(
      onTap: () async {
        final uri = Uri.tryParse(link);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: duyguRenk == Colors.white38
                ? Colors.white.withValues(alpha: 0.06)
                : duyguRenk.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kaynak + duygu + zaman
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(kaynak,
                    style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 6),
              Icon(duyguIkon, size: 14, color: duyguRenk),
              const Spacer(),
              Text(_formatZaman(zaman),
                  style: const TextStyle(
                      fontSize: 10, color: Color(0xFF5a6080))),
              const SizedBox(width: 4),
              Icon(Icons.open_in_new_rounded,
                  size: 12,
                  color: Colors.white.withValues(alpha: 0.2)),
            ]),
            const SizedBox(height: 8),
            // Başlık
            Text(
              baslik,
              style: const TextStyle(
                color: Color(0xFFd0d4ee),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            // Duygu badge
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: duyguRenk.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                duygu,
                style: TextStyle(
                    fontSize: 9,
                    color: duyguRenk,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatZaman(String zaman) {
    if (zaman.isEmpty) return '';
    try {
      final dt = DateTime.parse(zaman);
      final fark = DateTime.now().difference(dt);
      if (fark.inMinutes < 60) return '${fark.inMinutes}dk önce';
      if (fark.inHours < 24) return '${fark.inHours}sa önce';
      return '${fark.inDays}g önce';
    } catch (_) {
      return zaman.length > 16 ? zaman.substring(0, 16) : zaman;
    }
  }
}

// ── Duygu Analizi Sekmesi ──────────────────────────────────────────────────

class _DuyguAnalizi extends ConsumerWidget {
  const _DuyguAnalizi();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(newsSentimentProvider);

    return dataAsync.when(
      data: (d) {
        final ist = d['istatistik'] as Map<String, dynamic>;
        final poz = (ist['pozitif_yuzde'] as num).toInt();
        final neg = 100 - poz;
        final genel = ist['genel_duygu'] as String;
        final toplam = ist['toplam'] as int;
        final pozSayi = ist['pozitif'] as int;
        final negSayi = ist['negatif'] as int;
        final guncelleme = d['guncelleme'] as String;

        final genelRenk = genel == 'OLUMLU'
            ? AppTheme.bullish
            : genel == 'OLUMSUZ'
                ? AppTheme.bearish
                : AppTheme.warning;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Genel durum kartı
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: genelRenk.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: genelRenk.withValues(alpha: 0.25)),
                ),
                child: Column(children: [
                  Text(
                    genel,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: genelRenk,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$toplam haber analiz edildi',
                    style: const TextStyle(
                        color: Color(0xFF5a6080), fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text('Son güncelleme: $guncelleme',
                      style: const TextStyle(
                          color: Color(0xFF3a3d55), fontSize: 10)),
                ]),
              ),
              const SizedBox(height: 20),

              // Oran barı
              Row(children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 16,
                      child: Row(children: [
                        Flexible(
                          flex: poz,
                          child: Container(
                            color: AppTheme.bullish,
                            alignment: Alignment.center,
                            child: poz > 15
                                ? Text('$poz%',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700))
                                : null,
                          ),
                        ),
                        Flexible(
                          flex: neg,
                          child: Container(
                            color: AppTheme.bearish,
                            alignment: Alignment.center,
                            child: neg > 15
                                ? Text('$neg%',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700))
                                : null,
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 20),

              // İstatistik kartları
              Row(children: [
                _IstatKart(
                  deger: pozSayi.toString(),
                  etiket: 'Olumlu Haber',
                  color: AppTheme.bullish,
                ),
                const SizedBox(width: 10),
                _IstatKart(
                  deger: (toplam - pozSayi - negSayi).toString(),
                  etiket: 'Nötr Haber',
                  color: AppTheme.warning,
                ),
                const SizedBox(width: 10),
                _IstatKart(
                  deger: negSayi.toString(),
                  etiket: 'Olumsuz Haber',
                  color: AppTheme.bearish,
                ),
              ]),
              const SizedBox(height: 20),

              // Açıklama
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('Analiz Hakkında',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(
                    'Haberler CoinDesk, CoinTelegraph, CoinTürk ve diğer '
                    'kaynaklardan toplanır. Her haber başlığı anahtar '
                    'kelime analizi ile POZİTİF, NEGATİF veya NÖTR olarak '
                    'sınıflandırılır. Analiz her 5 dakikada güncellenir.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                ]),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, __) => const SizedBox(),
    );
  }
}

class _IstatKart extends StatelessWidget {
  const _IstatKart({
    required this.deger,
    required this.etiket,
    required this.color,
  });
  final String deger;
  final String etiket;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Text(deger,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: color)),
          const SizedBox(height: 4),
          Text(etiket,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 10,
                  color: color.withValues(alpha: 0.7))),
        ]),
      ),
    );
  }
}
