import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import '../models/signal.dart';
import '../theme.dart';

/// SignalChart — TradingView-style candlestick chart
/// Uses TradingView Lightweight Charts (free, MIT licensed)
/// Shows OHLC candles + SL/TP/Entry lines
class SignalChart extends StatefulWidget {
  final Signal signal;
  final double sl;
  final double tp1;
  final double tp2;

  const SignalChart({
    super.key,
    required this.signal,
    required this.sl,
    required this.tp1,
    required this.tp2,
  });

  @override
  State<SignalChart> createState() => _State();
}

class _State extends State<SignalChart> {
  late WebViewController _ctrl;
  bool _loading = true;
  bool _error = false;
  List<dynamic> _candles = [];

  static const _serverUrl =
      'https://pulstrade-backend-production.up.railway.app';

  @override
  void initState() {
    super.initState();
    final isDark = WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(
          isDark ? const Color(0xFF0D0D0D) : Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            // Once HTML is loaded, inject chart data
            if (_candles.isNotEmpty) _renderChart();
          },
        ),
      );
    _fetchCandles();
  }

  Future<void> _fetchCandles() async {
    try {
      final tf = widget.signal.timeframe ?? '5M';
      String interval = '5min';
      if (tf.contains('1M') || tf == '1') {
        interval = '1min';
      } else if (tf.contains('5'))
        interval = '5min';
      else if (tf.contains('15'))
        interval = '15min';
      else if (tf.contains('30'))
        interval = '30min';
      else if (tf.contains('1H')) interval = '1h';

      final res = await http
          .get(Uri.parse('$_serverUrl/candles?interval=$interval&outputsize=80'))
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        _candles = json.decode(res.body) as List;
        await _ctrl.loadHtmlString(_html);
      } else {
        _error = true;
      }
    } catch (_) {
      _error = true;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _renderChart() async {
    if (_candles.isEmpty) return;

    // Convert candles to TradingView format
    // Backend returns: [{timestamp, open, high, low, close, ...}]
    // TradingView wants: [{time, open, high, low, close}]
    final chartData = _candles.reversed.map((c) {
      final ts = c['timestamp'];
      int t;
      if (ts is int) {
        t = ts > 1000000000000 ? (ts / 1000).floor() : ts;
      } else if (ts is String) {
        t = (DateTime.tryParse(ts)?.millisecondsSinceEpoch ?? 0) ~/ 1000;
      } else {
        t = 0;
      }
      return {
        'time': t,
        'open': c['open'],
        'high': c['high'],
        'low': c['low'],
        'close': c['close'],
      };
    }).toList();

    final isBuy = widget.signal.isBuy;
    final entry = widget.signal.price;

    final js = '''
      try {
        const data = ${json.encode(chartData)};
        candleSeries.setData(data);
        
        // Entry line (gold)
        candleSeries.createPriceLine({
          price: $entry,
          color: '#FFB800',
          lineWidth: 2,
          lineStyle: 0,
          axisLabelVisible: true,
          title: 'Entry ${isBuy ? "BUY" : "SELL"}',
        });
        
        // SL line (red)
        candleSeries.createPriceLine({
          price: ${widget.sl},
          color: '#EF4444',
          lineWidth: 2,
          lineStyle: 2,
          axisLabelVisible: true,
          title: 'SL',
        });
        
        // TP1 line (green)
        candleSeries.createPriceLine({
          price: ${widget.tp1},
          color: '#10B981',
          lineWidth: 2,
          lineStyle: 2,
          axisLabelVisible: true,
          title: 'TP1',
        });
        
        // TP2 line (green dashed)
        candleSeries.createPriceLine({
          price: ${widget.tp2},
          color: '#10B981',
          lineWidth: 1,
          lineStyle: 1,
          axisLabelVisible: true,
          title: 'TP2',
        });
        
        chart.timeScale().fitContent();
      } catch(e) {
        document.getElementById('error').innerText = e.toString();
      }
    ''';

    await _ctrl.runJavaScript(js);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D0D0D) : Colors.white,
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
                color: AppColors.gold, strokeWidth: 2),
          ),
        ),
      );
    }

    if (_error || _candles.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D0D0D) : Colors.white,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart,
                  size: 36,
                  color: AppColors.textMuted.withOpacity(.4)),
              const SizedBox(height: 8),
              Text('Chart unavailable',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted.withOpacity(.7))),
              const SizedBox(height: 4),
              Text('Pull to refresh or check connection',
                  style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted.withOpacity(.5))),
            ],
          ),
        ),
      );
    }

    return WebViewWidget(controller: _ctrl);
  }

  // TradingView Lightweight Charts HTML (loaded from CDN)
  String get _html {
    final isDark = WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
    final bgColor = isDark ? '#0D0D0D' : '#FFFFFF';
    final textColor = isDark ? '#9CA3AF' : '#6B7280';
    final gridColor = isDark ? '#1F2937' : '#E5E7EB';

    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no" />
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  html, body { width: 100%; height: 100%; background: $bgColor; overflow: hidden; }
  #chart { width: 100%; height: 100%; }
  #error { position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); color: #EF4444; font-family: -apple-system, sans-serif; font-size: 12px; }
</style>
</head>
<body>
<div id="chart"></div>
<div id="error"></div>
<script src="https://unpkg.com/lightweight-charts@4.1.3/dist/lightweight-charts.standalone.production.js"></script>
<script>
  const chart = LightweightCharts.createChart(document.getElementById('chart'), {
    width: window.innerWidth,
    height: window.innerHeight,
    layout: {
      background: { type: 'solid', color: '$bgColor' },
      textColor: '$textColor',
      fontSize: 10,
      fontFamily: '-apple-system, BlinkMacSystemFont, sans-serif',
    },
    grid: {
      vertLines: { color: '$gridColor', style: 1 },
      horzLines: { color: '$gridColor', style: 1 },
    },
    rightPriceScale: {
      borderColor: '$gridColor',
      borderVisible: false,
      scaleMargins: { top: 0.15, bottom: 0.15 },
    },
    timeScale: {
      borderColor: '$gridColor',
      borderVisible: false,
      timeVisible: true,
      secondsVisible: false,
    },
    crosshair: {
      mode: 1,
      vertLine: { color: '#FFB800', width: 1, style: 3, labelBackgroundColor: '#FFB800' },
      horzLine: { color: '#FFB800', width: 1, style: 3, labelBackgroundColor: '#FFB800' },
    },
    handleScroll: { mouseWheel: false, pressedMouseMove: true, horzTouchDrag: true, vertTouchDrag: false },
    handleScale: { axisPressedMouseMove: true, mouseWheel: false, pinch: true },
  });

  const candleSeries = chart.addCandlestickSeries({
    upColor: '#10B981',
    downColor: '#EF4444',
    borderUpColor: '#10B981',
    borderDownColor: '#EF4444',
    wickUpColor: '#10B981',
    wickDownColor: '#EF4444',
    priceLineVisible: false,
    lastValueVisible: true,
  });

  // Auto-resize on window changes
  window.addEventListener('resize', () => {
    chart.applyOptions({ width: window.innerWidth, height: window.innerHeight });
  });

  // Tell Flutter that page is ready
  window.chartReady = true;
</script>
</body>
</html>
''';
  }
}
