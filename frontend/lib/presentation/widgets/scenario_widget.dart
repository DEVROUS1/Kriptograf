import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../providers/selected_coin_provider.dart';

final scenarioProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final coin = ref.watch(selectedCoinProvider);
  final url = Uri.parse(
    '${AppConfig.httpBaseUrl}/api/senaryo/${coin.symbol.toUpperCase()}',
  );
  final res = await http.get(url).timeout(const Duration(seconds: 30));
  if (res.statusCode != 200) throw Exception('Senaryo alınamadı');
  return json.decode(res.body) as Map<String, dynamic>;
});

class ScenarioWidget extends ConsumerWidget {
  const ScenarioWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(scenarioProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.06),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border(bottom: BorderSide(color: AppTheme.primary.withValues(alpha: 0.15))),
          ),
          child: Row(children: [
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(5)),
              child: const Icon(Icons.auto_awesome_rounded, size: 11, color: Colors.white),
            ),
            const SizedBox(width: 8),
            const Text('AI SENARYO ANALİZİ',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                    color: Color(0xFFa89fff), letterSpacing: 0.8)),
            const Spacer(),
            dataAsync.when(
              data: (d) => Text(d['olusturulma'] as String,
                  style: const TextStyle(fontSize: 9, color: Color(0xFF5a6080))),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          ]),
        ),
        dataAsync.when(
          data: (d) => _Body(data: d),
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Column(children: [
              CircularProgressIndicator(strokeWidth: 2),
              SizedBox(height: 10),
              Text('AI analiz yapıyor...', style: TextStyle(color: Color(0xFF5a6080), fontSize: 11)),
            ]),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Icon(Icons.warning_amber_rounded, size: 14, color: AppTheme.warning),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('GROQ_API_KEY Render.com\'a ekleyin.',
                    style: TextStyle(color: Color(0xFF8890b0), fontSize: 11)),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final s = data['senaryolar'] as Map<String, dynamic>;
    final boga = s['boga'] as Map<String, dynamic>;
    final ayi = s['ayi'] as Map<String, dynamic>;
    final yatay = s['yatay'] as Map<String, dynamic>;
    final genelYorum = s['genel_yorum'] as String? ?? '';
    final kritikSeviye = s['kritik_seviye'];

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        // Genel yorum
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(genelYorum,
              style: const TextStyle(
                  color: Color(0xFFd0d4ee), fontSize: 12, fontStyle: FontStyle.italic, height: 1.5)),
        ),
        if (kritikSeviye != null) ...[
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.my_location_rounded, size: 12, color: AppTheme.warning),
            const SizedBox(width: 5),
            Text('Kritik Seviye: \$${_fmt((kritikSeviye as num).toDouble())}',
                style: TextStyle(fontSize: 11, color: AppTheme.warning, fontWeight: FontWeight.w700)),
          ]),
        ],
        const SizedBox(height: 12),

        // 3 Senaryo
        _SenaryoKart(
          baslik: boga['baslik'] as String,
          ihtimal: (boga['ihtimal'] as num).toInt(),
          hedef: '\$${_fmt((boga['hedef'] as num).toDouble())}',
          tetikleyici: boga['tetikleyici'] as String,
          aciklama: boga['aciklama'] as String,
          color: AppTheme.bullish,
          ikon: Icons.trending_up_rounded,
        ),
        const SizedBox(height: 8),
        _SenaryoKart(
          baslik: ayi['baslik'] as String,
          ihtimal: (ayi['ihtimal'] as num).toInt(),
          hedef: '\$${_fmt((ayi['hedef'] as num).toDouble())}',
          tetikleyici: ayi['tetikleyici'] as String,
          aciklama: ayi['aciklama'] as String,
          color: AppTheme.bearish,
          ikon: Icons.trending_down_rounded,
        ),
        const SizedBox(height: 8),
        _SenaryoKart(
          baslik: yatay['baslik'] as String,
          ihtimal: (yatay['ihtimal'] as num).toInt(),
          hedef: '\$${_fmt((yatay['aralik_alt'] as num).toDouble())}–\$${_fmt((yatay['aralik_ust'] as num).toDouble())}',
          tetikleyici: '',
          aciklama: yatay['aciklama'] as String,
          color: AppTheme.warning,
          ikon: Icons.trending_flat_rounded,
        ),
      ]),
    );
  }
}

class _SenaryoKart extends StatelessWidget {
  const _SenaryoKart({
    required this.baslik,
    required this.ihtimal,
    required this.hedef,
    required this.tetikleyici,
    required this.aciklama,
    required this.color,
    required this.ikon,
  });
  final String baslik;
  final int ihtimal;
  final String hedef;
  final String tetikleyici;
  final String aciklama;
  final Color color;
  final IconData ikon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(ikon, size: 16, color: color),
          const SizedBox(width: 7),
          Expanded(child: Text(baslik,
              style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w700))),
          // İhtimal göstergesi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('%$ihtimal',
                style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w800)),
          ),
        ]),
        const SizedBox(height: 6),
        // İhtimal barı
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: ihtimal / 100,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(color.withValues(alpha: 0.6)),
            minHeight: 3,
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          const Text('Hedef:', style: TextStyle(fontSize: 10, color: Color(0xFF6b6f8e))),
          const SizedBox(width: 4),
          Text(hedef, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700)),
        ]),
        if (tetikleyici.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('Tetikleyici: $tetikleyici',
              style: const TextStyle(fontSize: 10, color: Color(0xFF8890b0))),
        ],
        const SizedBox(height: 6),
        Text(aciklama,
            style: const TextStyle(fontSize: 11, color: Color(0xFFa0a4bc), height: 1.5)),
      ]),
    );
  }
}

String _fmt(double v) {
  if (v >= 10000) return v.toStringAsFixed(0);
  if (v >= 1) return v.toStringAsFixed(2);
  return v.toStringAsFixed(6);
}
