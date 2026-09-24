import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme.dart';

/// Live Price Header — shows current XAU/USD price with tick animation
/// Refreshes every 30 seconds from backend cache
class LivePriceHeader extends StatefulWidget {
  final bool compact;
  const LivePriceHeader({super.key, this.compact = false});
  @override
  State<LivePriceHeader> createState() => _State();
}

class _State extends State<LivePriceHeader>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  double? _price;
  double? _previousPrice;
  bool _loading = true;
  bool _justUpdated = false;

  static const _backend = 'https://pulstrade-backend-production.up.railway.app';

  @override
  void initState() {
    super.initState();
    _fetch();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _fetch());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final res = await http
          .get(Uri.parse('$_backend/price'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final newPrice = (data['price'] as num?)?.toDouble();
        if (newPrice != null && mounted) {
          setState(() {
            _previousPrice = _price;
            _price = newPrice;
            _loading = false;
            if (_previousPrice != null && _previousPrice != newPrice) {
              _justUpdated = true;
            }
          });
          if (_justUpdated) {
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) setState(() => _justUpdated = false);
            });
          }
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.textMuted : AppColors.textMutedLight;
    final txt = isDark ? Colors.white : Colors.black;

    if (_loading || _price == null) {
      return Container(
        padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 10 : 16,
            vertical: widget.compact ? 8 : 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
                color: AppColors.gold, strokeWidth: 1.5),
          ),
          const SizedBox(width: 8),
          Text('Loading XAU/USD...',
              style: TextStyle(fontSize: 11, color: muted)),
        ]),
      );
    }

    final isUp = _previousPrice == null || _price! >= _previousPrice!;
    final tickColor = isUp ? AppColors.green : AppColors.red;
    final showTick = _previousPrice != null && _previousPrice != _price;

    if (widget.compact) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _justUpdated
              ? tickColor.withOpacity(.15)
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: AppColors.gold.withOpacity(.3), width: .5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('🥇', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Text('\$${_price!.toStringAsFixed(2)}',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: txt,
                  letterSpacing: -0.2)),
          if (showTick) ...[
            const SizedBox(width: 4),
            Icon(isUp ? Icons.arrow_upward : Icons.arrow_downward,
                size: 10, color: tickColor),
          ],
        ]),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _justUpdated
              ? [
                  tickColor.withOpacity(.18),
                  tickColor.withOpacity(.05),
                ]
              : [
                  AppColors.gold.withOpacity(isDark ? .12 : .08),
                  Colors.transparent,
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.gold.withOpacity(.25), width: .5),
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.gold,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: AppColors.gold.withOpacity(.3),
                  blurRadius: 8,
                  spreadRadius: 1),
            ],
          ),
          child: const Center(
              child: Text('🥇', style: TextStyle(fontSize: 18))),
        ),
        const SizedBox(width: 12),
        Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('XAU/USD',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: muted,
                        letterSpacing: 0.8)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                      color: AppColors.greenDim,
                      borderRadius: BorderRadius.circular(3)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                            color: AppColors.green,
                            shape: BoxShape.circle)),
                    const SizedBox(width: 3),
                    const Text('LIVE',
                        style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            color: AppColors.green,
                            letterSpacing: 0.5)),
                  ]),
                ),
              ]),
              const SizedBox(height: 2),
              Text('Gold Spot Price',
                  style: TextStyle(fontSize: 9, color: muted)),
            ]),
        const Spacer(),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('\$${_price!.toStringAsFixed(2)}',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: txt,
                  letterSpacing: -0.5)),
          if (showTick)
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(isUp ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 10, color: tickColor),
              const SizedBox(width: 2),
              Text(
                  '${isUp ? '+' : ''}${(_price! - _previousPrice!).toStringAsFixed(2)}',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: tickColor)),
            ])
          else
            Text('per oz',
                style: TextStyle(fontSize: 9, color: muted)),
        ]),
      ]),
    );
  }
}
