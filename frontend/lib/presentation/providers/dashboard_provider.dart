import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DashTab {
  panel,
  analiz,
  yapayZeka,
  onchain,
  piyasalar,
  isiHaritasi,
  portfoy,
  balina,
}

extension DashTabExt on DashTab {
  String get etiket => switch (this) {
        DashTab.panel => 'Panel',
        DashTab.analiz => 'Analiz',
        DashTab.yapayZeka => 'AI',
        DashTab.onchain => 'On-Chain',
        DashTab.piyasalar => 'Piyasalar',
        DashTab.isiHaritasi => 'Isı Hrt',
        DashTab.portfoy => 'Portföy',
        DashTab.balina => 'Balina',
      };

  IconData get ikon => switch (this) {
        DashTab.panel => Icons.candlestick_chart_rounded,
        DashTab.analiz => Icons.analytics_rounded,
        DashTab.yapayZeka => Icons.auto_awesome_rounded,
        DashTab.onchain => Icons.link_rounded,
        DashTab.piyasalar => Icons.bar_chart_rounded,
        DashTab.isiHaritasi => Icons.grid_view_rounded,
        DashTab.portfoy => Icons.account_balance_wallet_rounded,
        DashTab.balina => Icons.waves_rounded,
      };
}

// Tüm sekmelerin global state yönetimi
// Tüm sekmelerin global state yönetimi
final dashboardTabProvider = StateProvider<DashTab>((ref) => DashTab.panel);

// TradingView Iframe Z-Index pointer sorununu çözmek için (Arama açıldığında grafiği inaktif yapmak)
final isSearchOpenProvider = StateProvider<bool>((ref) => false);

// Çoklu grafik modu: 1 (Tek), 2 (İkili), 4 (Dörtlü)
final multiChartModeProvider = StateProvider<int>((ref) => 1);
