import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

/// Position Size Calculator
/// Calculates lot size based on account, risk %, and SL distance
class PositionCalculatorScreen extends StatefulWidget {
  // Optional preset values (e.g. when opened from a signal)
  final double? presetEntry;
  final double? presetSL;
  final double? presetTP;
  final bool? presetIsBuy;

  const PositionCalculatorScreen({
    super.key,
    this.presetEntry,
    this.presetSL,
    this.presetTP,
    this.presetIsBuy,
  });

  @override
  State<PositionCalculatorScreen> createState() => _State();
}

class _State extends State<PositionCalculatorScreen> {
  final _accountCtrl = TextEditingController(text: '10000');
  final _riskPctCtrl = TextEditingController(text: '1.0');
  final _entryCtrl = TextEditingController();
  final _slCtrl = TextEditingController();
  final _tpCtrl = TextEditingController();

  bool _isBuy = true;

  // Gold contract size: 1 lot = 100 oz, 1 pip = $0.01 movement = $1 P/L per 0.01 lot
  // Standard lot calculation:
  // Risk $ = (Account × Risk%) / 100
  // SL Distance (in $) = |Entry - SL|
  // Lot Size = Risk $ / (SL Distance × 100)  (because 1 lot = 100 oz)

  @override
  void initState() {
    super.initState();
    _loadDefaults();
    if (widget.presetEntry != null) {
      _entryCtrl.text = widget.presetEntry!.toStringAsFixed(2);
    }
    if (widget.presetSL != null) {
      _slCtrl.text = widget.presetSL!.toStringAsFixed(2);
    }
    if (widget.presetTP != null) {
      _tpCtrl.text = widget.presetTP!.toStringAsFixed(2);
    }
    if (widget.presetIsBuy != null) _isBuy = widget.presetIsBuy!;
  }

  Future<void> _loadDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    final acc = prefs.getString('calc_account');
    final risk = prefs.getString('calc_risk');
    if (acc != null) _accountCtrl.text = acc;
    if (risk != null) _riskPctCtrl.text = risk;
    if (mounted) setState(() {});
  }

  Future<void> _saveDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('calc_account', _accountCtrl.text.trim());
    await prefs.setString('calc_risk', _riskPctCtrl.text.trim());
  }

  @override
  void dispose() {
    _accountCtrl.dispose();
    _riskPctCtrl.dispose();
    _entryCtrl.dispose();
    _slCtrl.dispose();
    _tpCtrl.dispose();
    super.dispose();
  }

  // Returns map with: lotSize, riskUsd, slDist, tpDist, profitUsd, rr
  Map<String, double>? _calculate() {
    final account = double.tryParse(_accountCtrl.text.trim());
    final riskPct = double.tryParse(_riskPctCtrl.text.trim());
    final entry = double.tryParse(_entryCtrl.text.trim());
    final sl = double.tryParse(_slCtrl.text.trim());
    final tp = double.tryParse(_tpCtrl.text.trim());

    if (account == null || riskPct == null || entry == null || sl == null) {
      return null;
    }

    final riskUsd = account * (riskPct / 100);
    final slDist = (entry - sl).abs();
    if (slDist == 0) return null;

    // For Gold (XAU/USD): 1 standard lot = 100 oz
    // P/L = price_movement × 100 oz × lot_size
    // SL Distance (USD) per 1 lot = slDist × 100
    final lotSize = riskUsd / (slDist * 100);

    double tpDist = 0;
    double profitUsd = 0;
    double rr = 0;
    if (tp != null) {
      tpDist = (tp - entry).abs();
      profitUsd = tpDist * 100 * lotSize;
      rr = slDist != 0 ? tpDist / slDist : 0;
    }

    return {
      'lotSize': lotSize,
      'riskUsd': riskUsd,
      'slDist': slDist,
      'tpDist': tpDist,
      'profitUsd': profitUsd,
      'rr': rr,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txt = isDark ? Colors.white : Colors.black;
    final muted = isDark ? AppColors.textMuted : AppColors.textMutedLight;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final bord = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final calc = _calculate();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Position Calculator',
            style: TextStyle(fontWeight: FontWeight.w700)),
        leading: const BackButton(color: AppColors.gold),
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        elevation: 0,
        actions: [
          // Done button to dismiss keyboard
          TextButton(
            onPressed: () => FocusScope.of(context).unfocus(),
            child: const Text('Done',
                style: TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Account Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: bord, width: .5),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Account Settings',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gold,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 12),
                  _input('Account Size', _accountCtrl, '\$', txt, muted, bord,
                      onChanged: (_) => _onChanged()),
                  const SizedBox(height: 10),
                  _input('Risk per Trade', _riskPctCtrl, '%', txt, muted, bord,
                      onChanged: (_) => _onChanged()),
                  const SizedBox(height: 6),
                  _quickRiskRow(),
                ]),
          ),
          const SizedBox(height: 14),

          // Direction Toggle
          Row(children: [
            Expanded(
                child: _directionButton('▲ BUY', true, AppColors.green)),
            const SizedBox(width: 8),
            Expanded(
                child: _directionButton('▼ SELL', false, AppColors.red)),
          ]),
          const SizedBox(height: 14),

          // Trade Levels Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: bord, width: .5),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Trade Levels (XAU/USD)',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gold,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 12),
                  _input('Entry Price', _entryCtrl, '\$', txt, muted, bord,
                      onChanged: (_) => _onChanged()),
                  const SizedBox(height: 10),
                  _input('Stop Loss', _slCtrl, '\$', txt, muted, bord,
                      onChanged: (_) => _onChanged()),
                  const SizedBox(height: 10),
                  _input('Take Profit (optional)', _tpCtrl, '\$', txt, muted,
                      bord,
                      onChanged: (_) => _onChanged()),
                ]),
          ),
          const SizedBox(height: 16),

          // Results Card
          if (calc != null) _resultsCard(calc, txt, muted, card, bord, isDark)
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: card.withOpacity(.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: bord, width: .5),
              ),
              child: Center(
                child: Text(
                    'Enter Account Size, Risk %, Entry, and SL to calculate',
                    style: TextStyle(fontSize: 11, color: muted)),
              ),
            ),

          const SizedBox(height: 24),
          // Disclaimer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Calculations are for XAU/USD with 1 standard lot = 100 oz. '
              'Verify with your broker. Trading carries risk — only trade with capital you can afford to lose.',
              style: TextStyle(
                  fontSize: 10, color: muted, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
        ]),
      )),
    );
  }

  void _onChanged() {
    setState(() {});
    _saveDefaults();
  }

  Widget _resultsCard(Map<String, double> calc, Color txt, Color muted,
      Color card, Color bord, bool isDark) {
    final lotSize = calc['lotSize']!;
    final riskUsd = calc['riskUsd']!;
    final profitUsd = calc['profitUsd']!;
    final rr = calc['rr']!;
    final hasTp = profitUsd > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gold.withOpacity(isDark ? .15 : .08),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.gold.withOpacity(.4), width: 1),
      ),
      child: Column(children: [
        Text('POSITION SIZE',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: muted,
                letterSpacing: 1)),
        const SizedBox(height: 6),
        Text(
            lotSize >= 0.01
                ? '${lotSize.toStringAsFixed(2)} lots'
                : '${(lotSize * 100).toStringAsFixed(2)} micro lots',
            style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppColors.gold,
                letterSpacing: -1)),
        Text(
            '${(lotSize * 100).toStringAsFixed(2)} oz · ${(lotSize * 100000).toStringAsFixed(0)} units',
            style: TextStyle(fontSize: 11, color: muted)),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(
              child: _statBox('Max Loss', '\$${riskUsd.toStringAsFixed(2)}',
                  AppColors.red, muted)),
          const SizedBox(width: 8),
          Expanded(
              child: _statBox(
                  'Potential Profit',
                  hasTp ? '\$${profitUsd.toStringAsFixed(2)}' : '—',
                  AppColors.green,
                  muted)),
          const SizedBox(width: 8),
          Expanded(
              child: _statBox(
                  'R:R',
                  hasTp ? '1:${rr.toStringAsFixed(1)}' : '—',
                  AppColors.gold,
                  muted)),
        ]),
      ]),
    );
  }

  Widget _statBox(String label, String value, Color color, Color muted) =>
      Container(
        padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 9, color: muted, height: 1.2),
              textAlign: TextAlign.center),
        ]),
      );

  Widget _input(String label, TextEditingController ctrl, String prefix,
      Color txt, Color muted, Color bord,
      {ValueChanged<String>? onChanged}) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: bord, width: .5),
      ),
      child: Row(children: [
        Text(prefix,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: muted)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 9, color: muted)),
                TextField(
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: txt),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: onChanged,
                ),
              ]),
        ),
      ]),
    );
  }

  Widget _quickRiskRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(children: [
        _riskChip('0.5%'),
        const SizedBox(width: 6),
        _riskChip('1%'),
        const SizedBox(width: 6),
        _riskChip('2%'),
        const SizedBox(width: 6),
        _riskChip('3%'),
      ]),
    );
  }

  Widget _riskChip(String label) {
    final isSelected = _riskPctCtrl.text.trim() ==
        label.replaceAll('%', '');
    return GestureDetector(
      onTap: () {
        _riskPctCtrl.text = label.replaceAll('%', '');
        _onChanged();
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gold.withOpacity(.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: AppColors.gold.withOpacity(isSelected ? .5 : .2),
              width: .5),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.gold)),
      ),
    );
  }

  Widget _directionButton(String label, bool isBuy, Color color) {
    final isSelected = _isBuy == isBuy;
    return GestureDetector(
      onTap: () => setState(() => _isBuy = isBuy),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? color : color.withOpacity(.3),
              width: 1),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isSelected
                      ? Colors.white
                      : color)),
        ),
      ),
    );
  }
}
