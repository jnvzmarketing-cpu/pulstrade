// Kurs zählt zum neuen Wert statt zu springen. Farbe blitzt kurz in
// Trade-Richtung auf, wie auf einem Terminal.
import "package:flutter/cupertino.dart";
import "../core/format.dart";
import "../core/pt_theme.dart";

class AnimatedPrice extends StatefulWidget {
  final double? value;
  final TextStyle style;
  const AnimatedPrice({super.key, required this.value, required this.style});
  @override
  State<AnimatedPrice> createState() => _AnimatedPriceState();
}

class _AnimatedPriceState extends State<AnimatedPrice> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  double _from = 0, _to = 0;
  Color? _flash;

  @override
  void initState() {
    super.initState();
    _from = _to = widget.value ?? 0;
    _c.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(AnimatedPrice old) {
    super.didUpdateWidget(old);
    final v = widget.value;
    if (v == null || v == _to) return;
    _from = _to;
    _to = v;
    _flash = v > _from ? PT.buy : PT.sell;
    _c.forward(from: 0).then((_) { if (mounted) setState(() => _flash = null); });
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (widget.value == null) return Text("––––.–", style: widget.style.copyWith(color: PT.textTertiary));
    final v = _from + (_to - _from) * Curves.easeOutCubic.transform(_c.value);
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 300),
      style: widget.style.copyWith(color: _flash ?? widget.style.color),
      child: Text(px(v)),
    );
  }
}
