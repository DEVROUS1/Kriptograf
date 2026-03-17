import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/global_market_model.dart';
import '../providers/global_markets_provider.dart';

class GlobalMarketsWidget extends ConsumerWidget {
  const GlobalMarketsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(globalMarketsProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Baslik(),
          dataAsync.when(
            data: (d) => _Govde(data: d),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Piyasa verisi alınamadı',
                  style: TextStyle(color: AppTheme.bearish, fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Baslik extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Row(children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: const Color(0xFF0099ff), shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        const Text('KÜRESEL & TÜRKİYE PİYASALARI',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: Color(0xFF5a6080), letterSpacing: 0.8)),
      ]),
    );
  }
}

class _Govde extends StatelessWidget {
  const _Govde({required this.data});
  final GlobalMarketsModel data;

  @override
  Widget build(BuildContext context) {
    final tr = data.turkiye;
    final usdTry = (tr['usd_try']['fiyat'] as num?)?.toDouble();
    final eurTry = (tr['eur_try']['fiyat'] as num?)?.toDouble();
    final bist = tr['bist100']['veri'] as Map<String, dynamic>?;
    final altin = tr['altin_tl'] as Map<String, dynamic>?;
    final btcTry = data.kriptoTl['btc_try'];
    final fg = data.korkuAcgozluluk;

    return Column(
      children: [
        // ── BTC/ETH TL ────────────────────────────────────────────
        if (btcTry != null)
          _KriptoBolumu(btcTry: btcTry, ethTry: data.kriptoTl['eth_try']),

        const _Ayrac(baslik: 'KÜRESEL ENDEKSLER'),
        ...data.kuresel.entries.map((e) => _MarketSatiri(item: e.value)),

        const _Ayrac(baslik: 'TÜRKİYE'),
        if (bist != null)
          _MarketSatiri(
            item: MarketItemModel.fromJson('BIST 100', bist),
            oncu: true,
          ),
        if (usdTry != null)
          _DovizSatiri(isim: 'USD / TRY', fiyat: usdTry),
        if (eurTry != null)
          _DovizSatiri(isim: 'EUR / TRY', fiyat: eurTry),
        if (altin != null) ...[
          _DovizSatiri(isim: 'Gram Altın', fiyat: altin['gram_tl'] as double),
          _DovizSatiri(isim: 'Çeyrek Altın', fiyat: altin['ceyrek_tl'] as double),
        ],

        const _Ayrac(baslik: 'KRİPTO DUYGU'),
        _FearGreedSatiri(data: fg),

        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('Son güncelleme: ${data.guncelleme}',
              style: const TextStyle(fontSize: 9, color: Color(0xFF3a3d55))),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _KriptoBolumu extends StatelessWidget {
  const _KriptoBolumu({required this.btcTry, this.ethTry});
  final double btcTry;
  final double? ethTry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _Ayrac(baslik: 'KRİPTO / TL'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(children: [
            _TlKart(sembol: 'BTC', fiyatTl: btcTry),
            const SizedBox(width: 8),
            if (ethTry != null) _TlKart(sembol: 'ETH', fiyatTl: ethTry!),
          ]),
        ),
      ],
    );
  }
}

class _TlKart extends StatelessWidget {
  const _TlKart({required this.sembol, required this.fiyatTl});
  final String sembol;
  final double fiyatTl;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$sembol/TRY',
              style: TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(
            '₺${_fmt(fiyatTl)}',
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ]),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(2);
  }
}

class _Ayrac extends StatelessWidget {
  const _Ayrac({required this.baslik});
  final String baslik;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Row(children: [
        Text(baslik,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                color: Color(0xFF3a3d55), letterSpacing: 0.7)),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 0.5, color: const Color(0xFF1e2035))),
      ]),
    );
  }
}

class _MarketSatiri extends StatelessWidget {
  const _MarketSatiri({required this.item, this.oncu = false});
  final MarketItemModel item;
  final bool oncu;

  @override
  Widget build(BuildContext context) {
    final color = item.pozitif ? AppTheme.bullish : AppTheme.bearish;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.03))),
      ),
      child: Row(children: [
        Expanded(
          child: Text(item.isim,
              style: TextStyle(
                color: oncu ? AppTheme.warning : const Color(0xFFa0a4bc),
                fontSize: 12,
              )),
        ),
        Text(item.fiyatStr,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(width: 10),
        Container(
          width: 72,
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(item.degisimStr,
                style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}

class _DovizSatiri extends StatelessWidget {
  const _DovizSatiri({required this.isim, required this.fiyat});
  final String isim;
  final double fiyat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.03))),
      ),
      child: Row(children: [
        Expanded(child: Text(isim,
            style: const TextStyle(color: Color(0xFFa0a4bc), fontSize: 12))),
        Text('₺${fiyat.toStringAsFixed(fiyat > 100 ? 0 : 4)}',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _FearGreedSatiri extends StatelessWidget {
  const _FearGreedSatiri({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final deger = (data['bugun'] as num).toInt();
    final etiket = data['bugun_etiket'] as String;
    final color = deger < 30
        ? AppTheme.bearish
        : deger > 70
            ? AppTheme.bullish
            : AppTheme.warning;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(children: [
        const Text('Korku / Açgözlülük',
            style: TextStyle(color: Color(0xFFa0a4bc), fontSize: 12)),
        const Spacer(),
        Text('$deger/100',
            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(etiket,
              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}
