// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/selected_coin_provider.dart';

class LiquidationScreen extends ConsumerStatefulWidget {
  const LiquidationScreen({super.key});

  @override
  ConsumerState<LiquidationScreen> createState() => _LiquidationScreenState();
}

class _LiquidationScreenState extends ConsumerState<LiquidationScreen> {
  late String _viewId;
  late html.IFrameElement _iframe;
  String _currentSymbol = '';

  @override
  void initState() {
    super.initState();
    _viewId = 'coinglass-liq-\${DateTime.now().millisecondsSinceEpoch}';
    _iframe = html.IFrameElement()
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.border = 'none'
      ..style.backgroundColor = '#07080E'
      ..setAttribute('frameborder', '0')
      ..setAttribute('allowtransparency', 'true');

    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int id) => _iframe,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCoin = ref.watch(selectedCoinProvider);
    final symbol = selectedCoin.symbol.replaceAll('USDT', '');

    if (_currentSymbol != symbol) {
      _currentSymbol = symbol;
      final url = 'https://www.coinglass.com/pro/i/LiquidationHeatMap?symbol=$symbol';
      _iframe.src = url;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: HtmlElementView(viewType: _viewId),
      ),
    );
  }
}
