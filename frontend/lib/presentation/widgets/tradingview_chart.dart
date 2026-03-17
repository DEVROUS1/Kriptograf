import 'dart:ui_web' as ui_web;
import 'dart:html' as html;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/selected_coin_provider.dart';

class TradingViewChart extends ConsumerStatefulWidget {
  final String? symbol;
  final String? interval;
  
  const TradingViewChart({super.key, this.symbol, this.interval});

  @override
  ConsumerState<TradingViewChart> createState() =>
      _TradingViewChartState();
}

class _TradingViewChartState extends ConsumerState<TradingViewChart> with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;
  late String _viewId;
  html.IFrameElement? _iframe;

  static const Map<String, String> _intervalMap = {
    '1s': '1',
    '1m': '1',
    '3m': '3',
    '5m': '5',
    '15m': '15',
    '30m': '30',
    '1h': '60',
    '4h': '240',
    '1d': 'D',
    '1w': 'W',
  };

  @override
  void initState() {
    super.initState();
    _viewId = 'tv-chart-\${DateTime.now().millisecondsSinceEpoch}-\${widget.symbol ?? "main"}-\${UniqueKey().toString()}';
    _registerView();
  }

  void _registerView() {
    final coin = ref.read(selectedCoinProvider);
    final currentSymbol = widget.symbol ?? coin.symbol;
    final currentInterval = widget.interval ?? coin.interval;

    _iframe = _buildIframe(currentSymbol, currentInterval);

    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int id) => _iframe!,
    );
  }

  html.IFrameElement _buildIframe(String symbol, String interval) {
    final tvInterval = _intervalMap[interval] ?? '60';
    final tvSymbol = 'BINANCE:${symbol.toUpperCase()}';

    final iframe = html.IFrameElement()
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.border = 'none'
      ..style.backgroundColor = '#0F1020'
      ..setAttribute('frameborder', '0')
      ..setAttribute('allowtransparency', 'true')
      ..srcdoc = '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width,initial-scale=1">
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  html, body { width: 100%; height: 100%; background: #0F1020; overflow: hidden; }
  #tv { width: 100%; height: 100%; }
</style>
</head>
<body>
<div id="tv"></div>
<script src="https://s3.tradingview.com/tv.js"></script>
<script>
function createTVWidget(symbol, interval) {
  document.getElementById('tv').innerHTML = '';
  new TradingView.widget({
    container_id: "tv",
    autosize: true,
    symbol: symbol,
    interval: interval,
    timezone: "Europe/Istanbul",
    theme: "dark",
    style: "1",
    locale: "tr",
    toolbar_bg: "#0F1020",
    enable_publishing: false,
    hide_top_toolbar: true,
    hide_legend: false,
    save_image: false,
    backgroundColor: "#0F1020",
    gridColor: "rgba(255,255,255,0.03)",
    studies: ["MASimple@tv-basicstudies","Volume@tv-basicstudies"],
    overrides: {
      "mainSeriesProperties.candleStyle.upColor": "#00D68F",
      "mainSeriesProperties.candleStyle.downColor": "#FF4757",
      "mainSeriesProperties.candleStyle.borderUpColor": "#00D68F",
      "mainSeriesProperties.candleStyle.borderDownColor": "#FF4757",
      "mainSeriesProperties.candleStyle.wickUpColor": "#00D68F",
      "mainSeriesProperties.candleStyle.wickDownColor": "#FF4757",
      "paneProperties.background": "#0F1020",
      "paneProperties.backgroundType": "solid",
      "scalesProperties.textColor": "#5a6080"
    }
  });
}

// Initial load
createTVWidget("$tvSymbol", "$tvInterval");

// Listen for dynamic updates from Flutter
window.addEventListener('message', function(e) {
  try {
    var data = JSON.parse(e.data);
    if(data && data.symbol && data.interval) {
      createTVWidget(data.symbol, data.interval);
    }
  } catch(err) {
    console.error('TradingView update info parse error', err);
  }
});
</script>
</body>
</html>
''';
    return iframe;
  }

  void _updateChart(String symbol, String interval) {
    if (_iframe == null) return;
    
    final tvInterval = _intervalMap[interval] ?? '60';
    final tvSymbol = 'BINANCE:${symbol.toUpperCase()}';
    
    final payload = jsonEncode({
      'symbol': tvSymbol,
      'interval': tvInterval,
    });
    
    _iframe?.contentWindow?.postMessage(payload, '*');
  }

  @override
  void didUpdateWidget(TradingViewChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.symbol != oldWidget.symbol || widget.interval != oldWidget.interval) {
      if (widget.symbol != null && widget.interval != null) {
        _updateChart(widget.symbol!, widget.interval!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // From AutomaticKeepAliveClientMixin
    
    // Only listen to global selected coin if this chart is the main chart 
    if (widget.symbol == null && widget.interval == null) {
      ref.listen(selectedCoinProvider, (prev, next) {
        if (prev?.symbol != next.symbol ||
            prev?.interval != next.interval) {
          _updateChart(next.symbol, next.interval);
        }
      });
    }

    return Container(
      color: AppTheme.surface,
      child: HtmlElementView(key: ValueKey(_viewId), viewType: _viewId),
    );
  }
}
