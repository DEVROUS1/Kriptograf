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
import '../providers/dashboard_provider.dart';

// ── Yardımcı Araçlar ────────────────────────────────────────────────────────

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

// ── Ana Ekran (ConsumerWidget olarak yeniden tasarlandı) ───────────────────

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ekran genişliği 900px'den büyükse masaüstü, küçükse mobil mod.
    final genis = MediaQuery.sizeOf(context).width > 900;

    if (genis) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Column(children: [
          _TopBar(),
          ConnectionStatusWidget(),
          Expanded(child: _GenisDuzen()),
        ]),
      );
    }

    // Mobil Düzen
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
      body: const _MobilIcerik(),
      bottomNavigationBar: const _MobilNavBar(),
    );
  }
}

// ── Geniş ekran düzeni ─────────────────────────────────────────────────────

class _GenisDuzen extends ConsumerWidget {
  const _GenisDuzen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aktif = ref.watch(dashboardTabProvider);

    return Row(children: [
      // Sol sidebar (Menü)
      const _Sidebar(),
      // Ana içerik alanı (Grafikler vs.)
      const Expanded(child: _GenisMerkez()),
      // Sağ panel (Sadece analiz/panel durumunda aktiftir, IndexedStack ile yönetilir)
      if (aktif == DashTab.panel || aktif == DashTab.analiz)
        const _SagPanel(),
    ]);
  }
}

// ── Sol Sidebar ────────────────────────────────────────────────────────────

class _Sidebar extends ConsumerWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aktif = ref.watch(dashboardTabProvider);

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
        // Sekme butonları döngüsü
        ...DashTab.values.map((tab) => _SidebarBtn(
              tab: tab,
              aktif: aktif == tab,
              onTap: () => ref.read(dashboardTabProvider.notifier).state = tab,
            )),
        const Spacer(),
        // Ayarlar Butonu
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

// ── Geniş ekran — merkez içerik (Masaüstü Orta Ekranı) ──────────────────────

class _GenisMerkez extends ConsumerWidget {
  const _GenisMerkez();

  int getIndex(DashTab tab) {
    switch (tab) {
      case DashTab.panel:
      case DashTab.analiz:
        return 0; // İkisi de aynı ana grafiği (ortak widget) kullanır
      case DashTab.yapayZeka: return 1;
      case DashTab.onchain: return 2;
      case DashTab.piyasalar: return 3;
      case DashTab.portfoy: return 4;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aktif = ref.watch(dashboardTabProvider);

    return IndexedStack(
      index: getIndex(aktif),
      children: const [
        _MasaustuPanelAnalizOrtak(), // Index 0 (Hem Panel Hem Analiz için aynı iframe'i paylaştıran yapı)
        _YapayZekaMerkez(),          // Index 1
        _OnchainMerkez(),            // Index 2
        MarketsScreen(),             // Index 3
        PortfolioScreen(),           // Index 4
      ],
    );
  }
}

// ── Masaüstü Panel ve Analiz Ortak Widget (İframe yeniden yaratılmasını engeller) ──

class _MasaustuPanelAnalizOrtak extends ConsumerWidget {
  const _MasaustuPanelAnalizOrtak();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aktif = ref.watch(dashboardTabProvider);

    return Column(children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: LivePriceWidget(),
      ),
      const SizedBox(height: 8),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: CoinSelector(),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, aktif == DashTab.panel ? 0 : 12),
          child: const _ChartCard(), // <--- Iframe'in baştan render olmasını IndexedStack ve bu ortak yapı engeller!
        ),
      ),
      if (aktif == DashTab.panel) ...[
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: CvdWidget(),
        ),
      ],
    ]);
  }
}

// ── Geniş ekran — sağ panel ────────────────────────────────────────────────

class _SagPanel extends ConsumerWidget {
  const _SagPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aktif = ref.watch(dashboardTabProvider);

    return SizedBox(
      width: 300,
      child: IndexedStack(
        index: aktif == DashTab.analiz ? 1 : 0,
        children: const [
          // Index 0: Panel Sağ Widget'ları
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(0, 10, 12, 12),
            child: Column(children: [
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
          // Index 1: Analiz Sağ Widget'ları
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(0, 10, 12, 12),
            child: Column(children: [
              SmcWidget(),
              SizedBox(height: 10),
              SupportResistanceWidget(),
              SizedBox(height: 10),
              AdvancedIndicatorsWidget(),
            ]),
          ),
        ],
      ),
    );
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

// ── Mobil içerik (Telefonda Ana Ekran Düzeni) ──────────────────────────────

class _MobilIcerik extends ConsumerWidget {
  const _MobilIcerik();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aktif = ref.watch(dashboardTabProvider);

    return IndexedStack(
      index: DashTab.values.indexOf(aktif),
      children: const [
        // Tab 0: Panel
        SingleChildScrollView(
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
        // Tab 1: Analiz
        SingleChildScrollView(
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
        // Tab 2: Yapay Zeka
        SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: Column(children: [
            ScenarioWidget(),
            SizedBox(height: 12),
            AiSummaryWidget(),
            SizedBox(height: 12),
            NewsSentimentWidget(),
          ]),
        ),
        // Tab 3: On-Chain
        SingleChildScrollView(
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
        // Tab 4: Piyasalar
        MarketsScreen(),
        // Tab 5: Portfoy
        PortfolioScreen(),
      ],
    );
  }
}

// ── Mobil bottom nav (Telefonun Alt Menüsü) ────────────────────────────────

class _MobilNavBar extends ConsumerWidget {
  const _MobilNavBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aktif = ref.watch(dashboardTabProvider);

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
                  onTap: () => ref.read(dashboardTabProvider.notifier).state = tab,
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      // Sadece seçiliyken tepesinde ana renk ince bir çizgi göster
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

// ── TopBar (Uygulamanın En Üst Çubuğu) ─────────────────────────────────────

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

// ── Tepe Çubuğu Logosu (KriptoGraf PRO Logosu) ─────────────────────────────

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

// ── Grafik kartı Z-INDEX Yönetimi (Iframe Hata Çözümü) ─────────────────────

class _ChartCard extends ConsumerWidget {
  const _ChartCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSearchOpen = ref.watch(isSearchOpenProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            const Positioned.fill(child: TradingViewChart()),
            
            // Eğer arama (Overlay) açıksa, grafiğin pointer events (hit testing) yutmasını
            // kalıcı olarak engellemek adına görünmez bir Stack katmanı atarız!
            if (isSearchOpen)
              Positioned.fill(
                child: Container(
                  color: Colors.transparent, // Transparan kalkan (Pointer blocker)
                ),
              ),
          ],
        ),
      ),
    );
  }
}
