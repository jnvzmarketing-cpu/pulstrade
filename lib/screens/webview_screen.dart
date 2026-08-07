import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme.dart';

/// In-App WebView Screen — for displaying Terms of Use, Privacy Policy
/// Keeps users inside the app instead of launching external browser
class WebviewScreen extends StatefulWidget {
  final String url;
  final String title;

  const WebviewScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<WebviewScreen> createState() => _WebviewScreenState();
}

class _WebviewScreenState extends State<WebviewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  double _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progress = p / 100),
          onPageStarted: (_) => setState(() {
            _loading = true;
            _error = null;
          }),
          onPageFinished: (_) => setState(() => _loading = false),
          onWebResourceError: (err) {
            // Only set error for main-frame errors (ignore favicon/sub-resource fails)
            if (err.isForMainFrame == true) {
              setState(() {
                _error = err.description;
                _loading = false;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _retry() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    await _controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;
    final txt = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: txt, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: txt,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            if (_error == null) WebViewWidget(controller: _controller),
            if (_loading && _error == null)
              LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                backgroundColor: Colors.transparent,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.gold),
                minHeight: 2,
              ),
            if (_error != null) _ErrorView(error: _error!, onRetry: _retry),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txt = isDark ? Colors.white : Colors.black;
    final muted =
        isDark ? AppColors.textMuted : AppColors.textMutedLight;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 56, color: muted),
            const SizedBox(height: 16),
            Text(
              "Couldn't load page",
              style: TextStyle(
                color: txt,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Check your internet connection and try again.",
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Try again',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
