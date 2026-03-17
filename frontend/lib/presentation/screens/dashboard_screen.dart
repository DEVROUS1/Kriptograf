import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/coin_selector.dart';
import '../widgets/live_price_widget.dart';
import '../widgets/cvd_widget.dart';
import '../widgets/connection_status_widget.dart';
import '../widgets/tradingview_chart.dart';
import '../widgets/ai_summary_widget.dart';
import '../widgets/signal_widget.dart';
import '../widgets/alarm_widget.dart';
import '../widgets/stress_index_widget.dart';
import '../widgets/fear_greed_widget.dart';
import '../widgets/global_markets_widget.dart';
import '../widgets/correlation_widget.dart';
import '../widgets/whale_widget.dart';
import '../widgets/liquidity_heatmap_widget.dart';
import '../widgets/spread_widget.dart';
import '../widgets/news_sentiment_widget.dart';
import '../widgets/support_resistance_widget.dart';
import '../widgets/advanced_indicators_widget.dart';
import '../widgets/smc_widget.dart';
import '../widgets/scenario_widget.dart';
import '../widgets/onchain_widget.dart';
import 'markets_screen.dart';
import 'portfolio_screen.dart';

// ── Sekme tanımları ────────────────────────────────────────────────────────

enum DashTab {
  panel,
  analiz,
  yapayZeka,
  onchain,
  piyasalar,
  portfoy,
}

extension DashTabExt on DashTab {
  String get etiket => switch (this) {
        DashTab.panel => 'Panel',
        DashTab.analiz => 'Analiz',
        DashTab.yapayZeka => 'AI',
        DashTab.onchain => 'On-Chain',
        DashTab.piyasalar => 'Piyasalar',
        DashTab.portfoy => 'Portföy',
      };

  IconData get ikon => switch (this) {
        DashTab.panel => Icons.candlestick_chart_rounded,
        DashTab.analiz => Icons.analytics_rounded,
        DashTab.yapayZeka => Icons.auto_awesome_rounded,
        DashTab.onchain => Icons.link_rounded,
        DashTab.piyasalar => Icons.bar_chart_rounded,
        DashTab.portfoy => Icons.account_balance_wallet_rounded,
      };
}

// ── Ana ekran ──────────────────────────────────────────────────────────────

void _showSettingsInfo(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      title: const Row(
        children: [
          Icon(Icons.construction_rounded, color: AppTheme.primary),
          SizedBox(width: 10),
          Text('Yapım Aşamasında', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: const Text(
        'Ayarlar modülü şu anda Kriptograf sistem mühendisleri tarafından geliştiriliyor. Yakında aktif edilecek.',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Anladım', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardState();
}

class _DashboardState extends ConsumerState<DashboardScreen> {
  DashTab _aktif = DashTab.panel;

  @override
  Widget build(BuildContext context) {
    final genis = MediaQuery.sizeOf(context).width > 900;

    if (genis) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Column(children: [
          const _TopBar(),
          const ConnectionStatusWidget(),
          Expanded(
            child: _GenisDuzen(
              aktif: _aktif,
              onTabChanged: (t) => setState(() => _aktif = t),
            ),
          ),
        ]),
      );
    }

    // Mobil
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const _AppBarTitle(),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_rounded, size: 22, color: Colors.white.withValues(alpha: 0.4)),
            onPressed: () => _showSettingsInfo(context),
          ),
          const SizedBox(width: 8),
        ],
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: ConnectionStatusWidget(),
        ),
      ),
      body: _MobilIcerik(aktif: _aktif),
      bottomNavigationBar: _MobilNavBar(
        aktif: _aktif,
        onChanged: (t) => setState(() => _aktif = t),
      ),
    );
  }
}

// ── Geniş ekran düzeni ─────────────────────────────────────────────────────

class _GenisDuzen extends StatelessWidget {
  const _GenisDuzen({required this.aktif, required this.onTabChanged});
  final DashTab aktif;
  final void Function(DashTab) onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      // Sol sidebar
      _Sidebar(aktif: aktif, onTabChanged: onTabChanged),
      // Ana içerik
      Expanded(child: _GenisMerkez(aktif: aktif)),
      // Sağ panel — sadece Panel ve Analiz sekmelerinde
      if (aktif == DashTab.panel || aktif == DashTab.analiz)
        _SagPanel(aktif: aktif),
    ]);
  }
}

// ── Sol Sidebar ────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.aktif, required this.onTabChanged});
  final DashTab aktif;
  final void Function(DashTab) onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      color: const Color(0xFF0C0D1E),
      child: Column(children: [
        const SizedBox(height: 12),
        // Logo
        Container(
          width: 36, height: 36,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.candlestick_chart_rounded, color: Colors.white, size: 18),
        ),
        // Sekme butonları
        ...DashTab.values.map((tab) => _SidebarBtn(
              tab: tab,
              aktif: aktif == tab,
              onTap: () => onTabChanged(tab),
            )),
        const Spacer(),
        // Ayarlar
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: IconButton(
            icon: Icon(Icons.settings_rounded, size: 20, color: Colors.white.withValues(alpha: 0.3)),
            onPressed: () => _showSettingsInfo(context),
            tooltip: 'Ayarlar',
            hoverColor: Colors.white.withValues(alpha: 0.05),
          ),
        ),
      ]),
    );
  }
}

class _SidebarBtn extends StatelessWidget {
  const _SidebarBtn({required this.tab, required this.aktif, required this.onTap});
  final DashTab tab;
  final bool aktif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tab.etiket,
      preferBelow: false,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 44,
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: aktif
                ? AppTheme.primary.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: aktif
                ? Border.all(color: AppTheme.primary.withValues(alpha: 0.4))
                : null,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(tab.ikon, size: 20,
                color: aktif ? AppTheme.primary : Colors.white.withValues(alpha: 0.28)),
            const SizedBox(height: 3),
            Text(tab.etiket,
                style: TextStyle(
                  fontSize: 8,
                  color: aktif ? AppTheme.primary : Colors.white.withValues(alpha: 0.28),
                  fontWeight: aktif ? FontWeight.w700 : FontWeight.w400,
                )),
          ]),
        ),
      ),
    );
  }
}

// ── Geniş ekran — merkez içerik ────────────────────────────────────────────

class _GenisMerkez extends StatelessWidget {
  const _GenisMerkez({required this.aktif});
  final DashTab aktif;

  @override
  Widget build(BuildContext context) {
    return switch (aktif) {
      DashTab.panel => const _PanelMerkez(),
      DashTab.analiz => const _AnalizMerkez(),
      DashTab.yapayZeka => const _YapayZekaMerkez(),
      DashTab.onchain => const _OnchainMerkez(),
      DashTab.piyasalar => const MarketsScreen(),
      DashTab.portfoy => const PortfolioScreen(),
    };
  }
}

// ── Geniş ekran — sağ panel ────────────────────────────────────────────────

class _SagPanel extends StatelessWidget {
  const _SagPanel({required this.aktif});
  final DashTab aktif;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 10, 12, 12),
        child: aktif == DashTab.analiz
            ? const Column(children: [
                SmcWidget(),
                SizedBox(height: 10),
                SupportResistanceWidget(),
                SizedBox(height: 10),
                AdvancedIndicatorsWidget(),
              ])
            : const Column(children: [
                ScenarioWidget(),
                SizedBox(height: 10),
                AiSummaryWidget(),
                SizedBox(height: 10),
                SignalWidget(),
                SizedBox(height: 10),
                AlarmWidget(),
                SizedBox(height: 10),
                StressIndexWidget(),
                SizedBox(height: 10),
                FearGreedWidget(),
                SizedBox(height: 10),
                GlobalMarketsWidget(),
                SizedBox(height: 10),
                NewsSentimentWidget(),
              ]),
      ),
    );
  }
}

// ── Panel merkez (grafik + CVD) ────────────────────────────────────────────

class _PanelMerkez extends StatelessWidget {
  const _PanelMerkez();

  @override
  Widget build(BuildContext context) {
    return const Column(children: [
      Padding(
        padding: EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: LivePriceWidget(),
      ),
      SizedBox(height: 8),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: CoinSelector(),
      ),
      SizedBox(height: 8),
      Expanded(
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, 0),
          child: _ChartCard(),
        ),
      ),
      SizedBox(height: 8),
      Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: CvdWidget(),
      ),
    ]);
  }
}

// ── Analiz merkez ──────────────────────────────────────────────────────────

class _AnalizMerkez extends StatelessWidget {
  const _AnalizMerkez();

  @override
  Widget build(BuildContext context) {
    return const Column(children: [
      Padding(
        padding: EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: LivePriceWidget(),
      ),
      SizedBox(height: 8),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: CoinSelector(),
      ),
      SizedBox(height: 8),
      Expanded(
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: _ChartCard(),
        ),
      ),
    ]);
  }
}

// ── Yapay Zeka merkez ──────────────────────────────────────────────────────

class _YapayZekaMerkez extends StatelessWidget {
  const _YapayZekaMerkez();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(12),
      child: Column(children: [
        ScenarioWidget(),
        SizedBox(height: 12),
        AiSummaryWidget(),
        SizedBox(height: 12),
        SignalWidget(),
        SizedBox(height: 12),
        NewsSentimentWidget(),
      ]),
    );
  }
}

// ── On-Chain merkez ────────────────────────────────────────────────────────

class _OnchainMerkez extends StatelessWidget {
  const _OnchainMerkez();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(12),
      child: Column(children: [
        OnchainWidget(),
        SizedBox(height: 12),
        WhaleWidget(),
        SizedBox(height: 12),
        LiquidityHeatmapWidget(),
        SizedBox(height: 12),
        SpreadWidget(),
        SizedBox(height: 12),
        CorrelationWidget(),
        SizedBox(height: 12),
        GlobalMarketsWidget(),
      ]),
    );
  }
}

// ── Mobil içerik ───────────────────────────────────────────────────────────

class _MobilIcerik extends StatelessWidget {
  const _MobilIcerik({required this.aktif});
  final DashTab aktif;

  @override
  Widget build(BuildContext context) {
    return switch (aktif) {
      DashTab.panel => const SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: Column(children: [
            LivePriceWidget(),
            SizedBox(height: 10),
            CoinSelector(),
            SizedBox(height: 10),
            SizedBox(height: 320, child: _ChartCard()),
            SizedBox(height: 10),
            CvdWidget(),
            SizedBox(height: 10),
            AlarmWidget(),
            SizedBox(height: 10),
            StressIndexWidget(),
            SizedBox(height: 10),
            FearGreedWidget(),
          ]),
        ),
      DashTab.analiz => const SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: Column(children: [
            SmcWidget(),
            SizedBox(height: 12),
            SupportResistanceWidget(),
            SizedBox(height: 12),
            AdvancedIndicatorsWidget(),
            SizedBox(height: 12),
            SignalWidget(),
          ]),
        ),
      DashTab.yapayZeka => const SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: Column(children: [
            ScenarioWidget(),
            SizedBox(height: 12),
            AiSummaryWidget(),
            SizedBox(height: 12),
            NewsSentimentWidget(),
          ]),
        ),
      DashTab.onchain => const SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: Column(children: [
            OnchainWidget(),
            SizedBox(height: 12),
            WhaleWidget(),
            SizedBox(height: 12),
            LiquidityHeatmapWidget(),
            SizedBox(height: 12),
            SpreadWidget(),
            SizedBox(height: 12),
            CorrelationWidget(),
          ]),
        ),
      DashTab.piyasalar => const MarketsScreen(),
      DashTab.portfoy => const PortfolioScreen(),
    };
  }
}

// ── Mobil bottom nav ───────────────────────────────────────────────────────

class _MobilNavBar extends StatelessWidget {
  const _MobilNavBar({required this.aktif, required this.onChanged});
  final DashTab aktif;
  final void Function(DashTab) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 58,
          child: Row(
            children: DashTab.values.map((tab) {
              final secili = tab == aktif;
              final color = secili
                  ? AppTheme.primary
                  : Colors.white.withValues(alpha: 0.28);
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(tab),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      border: secili
                          ? const Border(
                              top: BorderSide(
                                  color: AppTheme.primary, width: 2))
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(tab.ikon, size: 19, color: color),
                        const SizedBox(height: 3),
                        Text(tab.etiket,
                            style: TextStyle(
                              fontSize: 9,
                              color: color,
                              fontWeight: secili ? FontWeight.w700 : FontWeight.w400,
                            )),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ── TopBar ─────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      color: const Color(0xFF0F1020),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        const _AppBarTitle(),
        const Spacer(),
        Container(width: 7, height: 7,
            decoration: const BoxDecoration(color: AppTheme.bullish, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        const Text('CANLI', style: TextStyle(
            fontSize: 10, color: AppTheme.bullish, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle();

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 26, height: 26,
        decoration: BoxDecoration(
            color: AppTheme.primary, borderRadius: BorderRadius.circular(7)),
        child: const Icon(Icons.candlestick_chart_rounded, color: Colors.white, size: 14),
      ),
      const SizedBox(width: 9),
      const Text('KriptoGraf',
          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4))),
        child: const Text('PRO',
            style: TextStyle(
                fontSize: 8, color: AppTheme.primary, fontWeight: FontWeight.w800)),
      ),
    ]);
  }
}

// ── Grafik kartı ───────────────────────────────────────────────────────────

class _ChartCard extends ConsumerWidget {
  const _ChartCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: const TradingViewChart(),
      ),
    );
  }
}
