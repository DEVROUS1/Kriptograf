import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../providers/selected_coin_provider.dart';

final smcProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final coin = ref.watch(selectedCoinProvider);
  final url = Uri.parse(
    '${AppConfig.httpBaseUrl}/api/smc/${coin.symbol.toUpperCase()}?interval=4h',
  );
  final res = await http.get(url).timeout(const Duration(seconds: 15));
  return json.decode(res.body) as Map<String, dynamic>;
});

class SmcWidget extends ConsumerStatefulWidget {
  const SmcWidget({super.key});

  @override
  ConsumerState<SmcWidget> createState() => _SmcWidgetState();
}

class _SmcWidgetState extends ConsumerState<SmcWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(smcProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        // Başlık
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.06),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Column(children: [
            Row(children: [
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                    color: AppTheme.primary, borderRadius: BorderRadius.circular(5)),
                child: const Icon(Icons.psychology_rounded, size: 12, color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Text('SMART MONEY CONCEPTS (ICT/SMC)',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                      color: Color(0xFFa89fff), letterSpacing: 0.6)),
              const Spacer(),
              dataAsync.when(
                data: (d) {
                  final yapi = d['piyasa_yapisi'] as String;
                  final color = yapi.contains('Boğa')
                      ? AppTheme.bullish
                      : yapi.contains('Ayı')
                          ? AppTheme.bearish
                          : AppTheme.warning;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      yapi.split(' — ').first,
                      style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.w800),
                    ),
                  );
                },
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
            ]),
            const SizedBox(height: 8),
            TabBar(
              controller: _tab,
              labelColor: AppTheme.primary,
              unselectedLabelColor: const Color(0xFF5a6080),
              indicatorColor: AppTheme.primary,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 10),
              tabs: const [
                Tab(text: 'Order Block'),
                Tab(text: 'FVG'),
                Tab(text: 'Likidite'),
                Tab(text: 'Yapı'),
              ],
            ),
          ]),
        ),
        // İçerik
        SizedBox(
          height: 280,
          child: dataAsync.when(
            data: (d) => TabBarView(
              controller: _tab,
              children: [
                _OrderBlockTab(data: d),
                _FvgTab(data: d),
                _LikaTab(data: d),
                _YapiTab(data: d),
              ],
            ),
            loading: () =>
                const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            error: (e, _) => Center(
              child: Text('SMC verisi alınamadı',
                  style: TextStyle(color: AppTheme.bearish, fontSize: 11)),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Order Block Sekmesi ────────────────────────────────────────────────────

class _OrderBlockTab extends StatelessWidget {
  const _OrderBlockTab({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final obs = data['order_blocks'] as Map<String, dynamic>;
    final bullish = (obs['bullish'] as List).cast<Map<String, dynamic>>();
    final bearish = (obs['bearish'] as List).cast<Map<String, dynamic>>();
    final enYakin = obs['en_yakin'] as Map<String, dynamic>?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (enYakin != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (enYakin['tip'] == 'BULLISH' ? AppTheme.bullish : AppTheme.bearish)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (enYakin['tip'] == 'BULLISH' ? AppTheme.bullish : AppTheme.bearish)
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Row(children: [
              Icon(Icons.my_location_rounded,
                  size: 14,
                  color: enYakin['tip'] == 'BULLISH' ? AppTheme.bullish : AppTheme.bearish),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'En Yakın OB: ${enYakin['tip']} — \$${_fmt((enYakin['alt'] as num).toDouble())}–\$${_fmt((enYakin['ust'] as num).toDouble())} · %${obs['en_yakin_mesafe_yuzde']} uzakta',
                  style: TextStyle(
                      fontSize: 11,
                      color: enYakin['tip'] == 'BULLISH' ? AppTheme.bullish : AppTheme.bearish,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 10),
        ],

        const Text('BULLISH ORDER BLOCKS',
            style: TextStyle(fontSize: 9, color: Color(0xFF5a6080),
                fontWeight: FontWeight.w700, letterSpacing: 0.7)),
        const SizedBox(height: 6),
        ...bullish.map((ob) => _ObSatiri(ob: ob, color: AppTheme.bullish)),

        const SizedBox(height: 10),
        const Text('BEARISH ORDER BLOCKS',
            style: TextStyle(fontSize: 9, color: Color(0xFF5a6080),
                fontWeight: FontWeight.w700, letterSpacing: 0.7)),
        const SizedBox(height: 6),
        ...bearish.map((ob) => _ObSatiri(ob: ob, color: AppTheme.bearish)),
      ]),
    );
  }
}

class _ObSatiri extends StatelessWidget {
  const _ObSatiri({required this.ob, required this.color});
  final Map<String, dynamic> ob;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final guc = ob['guc'] as String;
    final gucColor = switch (guc) {
      'GUCLU' => AppTheme.bullish,
      'ORTA' => AppTheme.warning,
      _ => const Color(0xFF5a6080),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                '\$${_fmt((ob['alt'] as num).toDouble())} – \$${_fmt((ob['ust'] as num).toDouble())}',
                style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                      color: gucColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3)),
                  child: Text(guc,
                      style: TextStyle(fontSize: 8, color: gucColor, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 6),
                Text('${ob['test_sayisi']} test',
                    style: const TextStyle(fontSize: 9, color: Color(0xFF5a6080))),
              ]),
            ]),
          ),
          Text('%${ob['mesafe_yuzde']}',
              style: const TextStyle(fontSize: 10, color: Color(0xFF5a6080))),
        ]),
      ),
    );
  }
}

// ── FVG Sekmesi ────────────────────────────────────────────────────────────

class _FvgTab extends StatelessWidget {
  const _FvgTab({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final fvg = data['fair_value_gaps'] as Map<String, dynamic>;
    final bullish = (fvg['bullish'] as List).cast<Map<String, dynamic>>();
    final bearish = (fvg['bearish'] as List).cast<Map<String, dynamic>>();
    final toplam = fvg['toplam_aktif'] as int;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Fair Value Gap = Fiyatın hızlı hareketiyle oluşan boşluklar. Fiyat genellikle bu boşlukları doldurmaya döner.',
            style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5), height: 1.5),
          ),
        ),
        const SizedBox(height: 8),
        Text('$toplam aktif FVG',
            style: TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),

        const Text('BULLISH FVG (Destek Boşlukları)',
            style: TextStyle(fontSize: 9, color: Color(0xFF5a6080), fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        ...bullish.map((f) => _FvgSatiri(fvg: f, color: AppTheme.bullish)),

        const SizedBox(height: 10),
        const Text('BEARISH FVG (Direnç Boşlukları)',
            style: TextStyle(fontSize: 9, color: Color(0xFF5a6080), fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        ...bearish.map((f) => _FvgSatiri(fvg: f, color: AppTheme.bearish)),
      ]),
    );
  }
}

class _FvgSatiri extends StatelessWidget {
  const _FvgSatiri({required this.fvg, required this.color});
  final Map<String, dynamic> fvg;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Expanded(
            child: Text(
              '\$${_fmt((fvg['alt'] as num).toDouble())} – \$${_fmt((fvg['ust'] as num).toDouble())}',
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700),
            ),
          ),
          Text('Boyut: %${fvg['boyut_yuzde']}',
              style: const TextStyle(fontSize: 9, color: Color(0xFF5a6080))),
          const SizedBox(width: 8),
          Text('%${fvg['mesafe_yuzde']} uzak',
              style: const TextStyle(fontSize: 9, color: Color(0xFF5a6080))),
        ]),
      ),
    );
  }
}

// ── Likidite Sekmesi ───────────────────────────────────────────────────────

class _LikaTab extends StatelessWidget {
  const _LikaTab({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final likidite =
        (data['likidite_seviyeleri'] as List).cast<Map<String, dynamic>>();
    final bsl = likidite.where((l) => l['tip'] == 'BSL').toList();
    final ssl = likidite.where((l) => l['tip'] == 'SSL').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'BSL = Short stop-loss birikimi (yukarıda) | SSL = Long stop-loss birikimi (aşağıda). Büyük oyuncular bu seviyelere fiyatı çekip ters yöne hareket eder.',
            style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5), height: 1.5),
          ),
        ),
        const SizedBox(height: 10),

        const Text('BSL — Buy Side Liquidity (Yukarıda)',
            style: TextStyle(fontSize: 9, color: Color(0xFF5a6080), fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        ...bsl.map((l) => _LikaSatiri(likidite: l)),

        const SizedBox(height: 10),
        const Text('SSL — Sell Side Liquidity (Aşağıda)',
            style: TextStyle(fontSize: 9, color: Color(0xFF5a6080), fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        ...ssl.map((l) => _LikaSatiri(likidite: l)),
      ]),
    );
  }
}

class _LikaSatiri extends StatelessWidget {
  const _LikaSatiri({required this.likidite});
  final Map<String, dynamic> likidite;

  @override
  Widget build(BuildContext context) {
    final tip = likidite['tip'] as String;
    final color = tip == 'BSL' ? AppTheme.bearish : AppTheme.bullish;
    final guc = likidite['guc'] as String;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(tip, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '\$${_fmt((likidite['fiyat'] as num).toDouble())}',
              style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w700),
            ),
          ),
          Text(guc, style: const TextStyle(fontSize: 9, color: Color(0xFF5a6080))),
          const SizedBox(width: 6),
          Text('%${(likidite['mesafe_yuzde'] as num).abs().toStringAsFixed(1)}',
              style: const TextStyle(fontSize: 9, color: Color(0xFF5a6080))),
        ]),
      ),
    );
  }
}

// ── Yapı Sekmesi ───────────────────────────────────────────────────────────

class _YapiTab extends StatelessWidget {
  const _YapiTab({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final bos = data['bos_choch'] as Map<String, dynamic>;
    final yapi = data['piyasa_yapisi'] as String;
    final trend = bos['trend'] as String;
    final bosData = bos['bos'] as Map<String, dynamic>?;
    final chochData = bos['choch'] as Map<String, dynamic>?;
    final ozet = data['ozet'] as String;

    final trendColor = trend == 'YUKSELIS'
        ? AppTheme.bullish
        : trend == 'DUSUS'
            ? AppTheme.bearish
            : AppTheme.warning;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Piyasa yapısı
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: trendColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: trendColor.withValues(alpha: 0.3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Piyasa Yapısı',
                style: TextStyle(fontSize: 10, color: trendColor.withValues(alpha: 0.7))),
            const SizedBox(height: 4),
            Text(yapi,
                style: TextStyle(fontSize: 14, color: trendColor, fontWeight: FontWeight.w800)),
          ]),
        ),
        const SizedBox(height: 10),

        // BOS/CHoCH
        if (bosData != null) ...[
          _BosChochKart(data: bosData, tip: 'BOS'),
          const SizedBox(height: 8),
        ],
        if (chochData != null) ...[
          _BosChochKart(data: chochData, tip: 'CHoCH'),
          const SizedBox(height: 8),
        ],
        if (bosData == null && chochData == null)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('BOS/CHoCH tespit edilmedi — yapı devam ediyor',
                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4))),
          ),

        const SizedBox(height: 10),

        // SMC Özet
        const Text('SMC ANALİZ ÖZETİ',
            style: TextStyle(fontSize: 9, color: Color(0xFF5a6080),
                fontWeight: FontWeight.w700, letterSpacing: 0.7)),
        const SizedBox(height: 6),
        ...ozet.split(' | ').map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Container(
                  width: 4, height: 4,
                  decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.6),
                      shape: BoxShape.circle)),
            ),
            const SizedBox(width: 7),
            Expanded(child: Text(s,
                style: const TextStyle(fontSize: 11, color: Color(0xFFa0a4bc), height: 1.4))),
          ]),
        )),
      ]),
    );
  }
}

class _BosChochKart extends StatelessWidget {
  const _BosChochKart({required this.data, required this.tip});
  final Map<String, dynamic> data;
  final String tip;

  @override
  Widget build(BuildContext context) {
    final isBullish = (data['tip'] as String).contains('BULLISH');
    final color = isBullish ? AppTheme.bullish : AppTheme.bearish;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(tip,
              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w900)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('\$${_fmt((data['seviye'] as num).toDouble())}',
                style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700)),
            Text(data['aciklama'] as String,
                style: const TextStyle(fontSize: 10, color: Color(0xFF8890b0))),
          ]),
        ),
      ]),
    );
  }
}

String _fmt(double v) {
  if (v >= 10000) return v.toStringAsFixed(0);
  if (v >= 1) return v.toStringAsFixed(2);
  return v.toStringAsFixed(6);
}
