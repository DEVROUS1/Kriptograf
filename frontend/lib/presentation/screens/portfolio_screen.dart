import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/portfolio_model.dart';
import '../providers/global_markets_provider.dart';

class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _State();
}

class _State extends ConsumerState<PortfolioScreen> {
  final _sembolCtrl = TextEditingController();
  final _miktarCtrl = TextEditingController();

  @override
  void dispose() {
    _sembolCtrl.dispose();
    _miktarCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final portfoyAsync = ref.watch(portfolioValueProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Portföyüm'),
        backgroundColor: AppTheme.background,
        automaticallyImplyLeading: false,
      ),
      body: Column(children: [
        portfoyAsync.when(
          data: (p) => _ToplamKart(portfoy: p),
          loading: () => const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
          error: (_, __) => const SizedBox(height: 40),
        ),
        _VarlikEkle(
          sembolCtrl: _sembolCtrl,
          miktarCtrl: _miktarCtrl,
          onEkle: () {
            final sym = _sembolCtrl.text.trim();
            final mik = double.tryParse(_miktarCtrl.text.trim());
            if (sym.isNotEmpty && mik != null && mik > 0) {
              ref.read(portfolioNotifierProvider.notifier).ekle(sym, mik);
              _sembolCtrl.clear();
              _miktarCtrl.clear();
              ref.invalidate(portfolioValueProvider);
            }
          },
        ),
        Expanded(
          child: portfoyAsync.when(
            data: (p) {
              if (p.varliklar.isEmpty) {
                return Center(
                  child: Text('Henüz varlık eklemediniz.',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 13)),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: p.varliklar.length,
                itemBuilder: (ctx, i) {
                  final v = p.varliklar[i];
                  final yuzde = p.toplamUsd > 0
                      ? (v.degerUsd / p.toplamUsd) * 100
                      : 0.0;
                  return _VarlikSatiri(
                    asset: v,
                    yuzde: yuzde,
                    onSil: () {
                      ref
                          .read(portfolioNotifierProvider.notifier)
                          .sil(v.sembol);
                      ref.invalidate(portfolioValueProvider);
                    },
                  );
                },
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            error: (_, __) => const Center(
              child: Text('Değerlemede hata',
                  style: TextStyle(color: AppTheme.bearish, fontSize: 12)),
            ),
          ),
        ),
      ]),
    );
  }
}

class _ToplamKart extends StatelessWidget {
  const _ToplamKart({required this.portfoy});
  final PortfolioModel portfoy;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Toplam Değer (USD)',
              style: TextStyle(fontSize: 11, color: Color(0xFF8890b0))),
          Text('\$${portfoy.toplamUsd.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
        ]),
        const Spacer(),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          const Text('Toplam (TL)',
              style: TextStyle(fontSize: 11, color: Color(0xFF8890b0))),
          Text('₺${portfoy.toplamTl.toStringAsFixed(0)}',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.bullish)),
          Text('USD/TRY: ${portfoy.usdTry.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 9, color: Color(0xFF5a6080))),
        ]),
      ]),
    );
  }
}

class _VarlikEkle extends StatelessWidget {
  const _VarlikEkle({
    required this.sembolCtrl,
    required this.miktarCtrl,
    required this.onEkle,
  });
  final TextEditingController sembolCtrl;
  final TextEditingController miktarCtrl;
  final VoidCallback onEkle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(children: [
        Expanded(
          flex: 2,
          child: TextField(
            controller: sembolCtrl,
            decoration: const InputDecoration(
              hintText: 'Sembol (BTC)',
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextField(
            controller: miktarCtrl,
            decoration: const InputDecoration(
              hintText: 'Miktar (0.5)',
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: onEkle,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: const Text('Ekle',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

class _VarlikSatiri extends StatelessWidget {
  const _VarlikSatiri({
    required this.asset,
    required this.yuzde,
    required this.onSil,
  });
  final PortfolioAsset asset;
  final double yuzde;
  final VoidCallback onSil;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              asset.sembol.length > 3
                  ? asset.sembol.substring(0, 3)
                  : asset.sembol,
              style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(asset.sembol,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              Text(
                  '${asset.miktar} adet × \$${asset.fiyatUsd.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Color(0xFF6b6f8e), fontSize: 11)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('\$${asset.degerUsd.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
            Text('₺${asset.degerTl.toStringAsFixed(0)}',
                style: const TextStyle(color: AppTheme.bullish, fontSize: 11)),
          ]),
          IconButton(
            onPressed: onSil,
            icon: Icon(Icons.close_rounded,
                size: 16, color: Colors.white.withValues(alpha: 0.3)),
            padding: const EdgeInsets.only(left: 8),
            constraints: const BoxConstraints(),
          ),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: (yuzde / 100).clamp(0.0, 1.0),
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            valueColor: AlwaysStoppedAnimation(
                AppTheme.primary.withValues(alpha: 0.6)),
            minHeight: 3,
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text('Portföy payı: %${yuzde.toStringAsFixed(1)}',
              style:
                  const TextStyle(fontSize: 9, color: Color(0xFF5a6080))),
        ),
      ]),
    );
  }
}
