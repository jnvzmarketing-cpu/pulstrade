import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});
  @override State<JournalScreen> createState() => _State();
}

class _State extends State<JournalScreen> {
  Map<String, double> _dailyPnL = {};
  DateTime _selectedMonth = DateTime.now();
  String? _editingDate;
  double? _monthlyGoal;
  final _goalCtrl = TextEditingController();

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('journal_v2') ?? '{}';
    _monthlyGoal = p.getDouble('monthly_goal');
    setState(() => _dailyPnL = Map<String, double>.from(
      (json.decode(raw) as Map).map((k, v) => MapEntry(k, (v as num).toDouble()))));
    if (_monthlyGoal != null) _goalCtrl.text = _monthlyGoal!.toStringAsFixed(0);
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('journal_v2', json.encode(_dailyPnL));
    if (_monthlyGoal != null) await p.setDouble('monthly_goal', _monthlyGoal!);
  }

  String _monthName(int m) => ['January','February','March','April','May','June','July','August','September','October','November','December'][m-1];

  double get _monthTotal {
    final prefix = '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2,'0')}';
    return _dailyPnL.entries.where((e) => e.key.startsWith(prefix)).fold(0.0, (s, e) => s + e.value);
  }

  int get _tradeDays {
    final prefix = '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2,'0')}';
    return _dailyPnL.entries.where((e) => e.key.startsWith(prefix)).length;
  }

  int get _winDays {
    final prefix = '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2,'0')}';
    return _dailyPnL.entries.where((e) => e.key.startsWith(prefix) && e.value > 0).length;
  }

  void _tapDay(String date, bool isFuture) {
    if (isFuture) return;
    HapticFeedback.lightImpact();
    setState(() => _editingDate = _editingDate == date ? null : date);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txt    = isDark ? Colors.white : Colors.black;
    final muted  = isDark ? AppColors.textMuted : AppColors.textMutedLight;
    final card   = isDark ? AppColors.darkCard : AppColors.lightCard;
    final bord   = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final bg     = isDark ? AppColors.darkBg : AppColors.lightBg;

    final now          = DateTime.now();
    final daysInMonth  = DateUtils.getDaysInMonth(_selectedMonth.year, _selectedMonth.month);
    final firstWeekday = DateTime(_selectedMonth.year, _selectedMonth.month, 1).weekday % 7;
    final monthTotal   = _monthTotal;
    final goal         = _monthlyGoal;
    final goalProgress = goal != null && goal > 0 ? (monthTotal / goal).clamp(0.0, 1.0) : null;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: const Text('Trade Journal', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        leading: const BackButton(color: AppColors.gold),
        elevation: 0,
      ),
      body: SingleChildScrollView(child: Column(children: [

        // Month selector
        Padding(padding: const EdgeInsets.fromLTRB(20,4,20,16), child: Row(children: [
          GestureDetector(
            onTap: () => setState(() { _editingDate=null; _selectedMonth=DateTime(_selectedMonth.year, _selectedMonth.month-1); }),
            child: Container(padding:const EdgeInsets.all(10), decoration:BoxDecoration(color:card, borderRadius:BorderRadius.circular(12), border:Border.all(color:bord, width:.5)),
              child: Icon(Icons.chevron_left_rounded, color:txt, size:20))),
          Expanded(child: Center(child: Text('${_monthName(_selectedMonth.month)} ${_selectedMonth.year}',
            style: TextStyle(fontSize:18, fontWeight:FontWeight.w800, color:txt)))),
          GestureDetector(
            onTap: () => setState(() { _editingDate=null; _selectedMonth=DateTime(_selectedMonth.year, _selectedMonth.month+1); }),
            child: Container(padding:const EdgeInsets.all(10), decoration:BoxDecoration(color:card, borderRadius:BorderRadius.circular(12), border:Border.all(color:bord, width:.5)),
              child: Icon(Icons.chevron_right_rounded, color:txt, size:20))),
        ])),

        // P&L Hero + Goal
        Padding(padding: const EdgeInsets.fromLTRB(20,0,20,16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Total P&L
          Expanded(child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color:card, borderRadius:BorderRadius.circular(20), border:Border.all(color:bord, width:.5)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Total P&L', style: TextStyle(fontSize:11, color:muted, fontWeight:FontWeight.w600)),
              const SizedBox(height:6),
              Text('${monthTotal>=0?'+':''}\$${monthTotal.abs().toStringAsFixed(2)}',
                style: TextStyle(fontSize:28, fontWeight:FontWeight.w900, color:monthTotal>=0?AppColors.green:AppColors.red, letterSpacing:-1)),
              const SizedBox(height:8),
              Row(children:[
                _pill('$_winDays W', AppColors.green, isDark),
                const SizedBox(width:6),
                _pill('${_tradeDays-_winDays} L', AppColors.red, isDark),
                const SizedBox(width:6),
                _pill('$_tradeDays days', muted, isDark),
              ]),
            ]),
          )),
          const SizedBox(width:12),
          // Monthly Goal
          Expanded(child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color:card, borderRadius:BorderRadius.circular(20), border:Border.all(color:bord, width:.5)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children:[
                Text('Monthly Goal', style: TextStyle(fontSize:11, color:muted, fontWeight:FontWeight.w600)),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showGoalDialog(isDark, txt, muted, card),
                  child: Icon(Icons.edit_outlined, size:14, color:muted)),
              ]),
              const SizedBox(height:6),
              Text(goal!=null ? '\$${goal.toStringAsFixed(0)}' : 'Set goal', style:TextStyle(fontSize:22, fontWeight:FontWeight.w900, color:goal!=null?AppColors.gold:muted, letterSpacing:-0.5)),
              const SizedBox(height:10),
              if (goalProgress != null) ...[
                ClipRRect(borderRadius:BorderRadius.circular(4), child:LinearProgressIndicator(
                  value:goalProgress, minHeight:6,
                  backgroundColor:isDark?Colors.white12:Colors.black12,
                  color: goalProgress>=1.0?AppColors.green:AppColors.gold)),
                const SizedBox(height:4),
                Text('${(goalProgress*100).toStringAsFixed(0)}% reached', style:TextStyle(fontSize:10, color:muted)),
              ] else
                Text('Tap edit to set', style:TextStyle(fontSize:11, color:muted)),
            ]),
          )),
        ])),

        // Calendar
        Padding(padding: const EdgeInsets.fromLTRB(20,0,20,16), child: Container(
          padding: const EdgeInsets.fromLTRB(14,14,14,10),
          decoration: BoxDecoration(color:card, borderRadius:BorderRadius.circular(20), border:Border.all(color:bord, width:.5)),
          child: Column(children: [
            // Weekday headers
            Row(children: ['SUN','MON','TUE','WED','THU','FRI','SAT'].map((d) =>
              Expanded(child: Center(child: Text(d, style: TextStyle(fontSize:9, fontWeight:FontWeight.w700, color:muted, letterSpacing:.5))))).toList()),
            const SizedBox(height:8),

            // Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:7, crossAxisSpacing:4, mainAxisSpacing:4, childAspectRatio:0.75),
              itemCount: firstWeekday + daysInMonth,
              itemBuilder: (ctx, i) {
                if (i < firstWeekday) return const SizedBox.shrink();
                final day     = i - firstWeekday + 1;
                final dateStr = '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2,'0')}-${day.toString().padLeft(2,'0')}';
                final pnl     = _dailyPnL[dateStr];
                final isToday = now.year==_selectedMonth.year && now.month==_selectedMonth.month && now.day==day;
                final isFut   = DateTime(_selectedMonth.year, _selectedMonth.month, day).isAfter(now);
                final isEdit  = _editingDate == dateStr;

                // Colors
                Color bg2, numColor, dayColor;
                if (isFut) {
                  bg2=Colors.transparent; numColor=muted.withValues(alpha:.25); dayColor=muted.withValues(alpha:.25);
                } else if (pnl==null) {
                  bg2=isDark?AppColors.darkCard2:AppColors.lightCard2; numColor=muted; dayColor=muted;
                } else if (pnl>0) {
                  final intensity = pnl>500?1.0:pnl>200?0.85:pnl>100?0.65:pnl>50?0.45:0.28;
                  bg2=AppColors.green.withValues(alpha:intensity); numColor=Colors.white; dayColor=Colors.white70;
                } else {
                  final intensity = pnl.abs()>500?1.0:pnl.abs()>200?0.85:pnl.abs()>100?0.65:pnl.abs()>50?0.45:0.28;
                  bg2=AppColors.red.withValues(alpha:intensity); numColor=Colors.white; dayColor=Colors.white70;
                }

                if (isEdit) { bg2=AppColors.goldDim; numColor=AppColors.gold; dayColor=AppColors.gold; }

                return GestureDetector(
                  onTap: () => _tapDay(dateStr, isFut),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds:200),
                    decoration: BoxDecoration(
                      color: bg2,
                      borderRadius: BorderRadius.circular(10),
                      border: isEdit ? Border.all(color:AppColors.gold, width:2)
                            : isToday ? Border.all(color:AppColors.gold.withValues(alpha:.5), width:1.5)
                            : null,
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('$day', style:TextStyle(fontSize:10, fontWeight:FontWeight.w600, color:dayColor)),
                      if (pnl != null) ...[
                        const SizedBox(height:1),
                        FittedBox(fit:BoxFit.scaleDown, child:Text(
                          '${pnl>=0?'+':''}\$${pnl.abs()>=1000?'${(pnl.abs()/1000).toStringAsFixed(1)}k':pnl.abs().toStringAsFixed(0)}',
                          style:TextStyle(fontSize:9, fontWeight:FontWeight.w800, color:numColor))),
                      ],
                    ]),
                  ),
                );
              },
            ),

            // Inline editor
            if (_editingDate != null) ...[
              const SizedBox(height:12),
              _DayEditor(
                date: _editingDate!,
                currentValue: _dailyPnL[_editingDate!],
                isDark: isDark,
                onSave: (val) {
                  setState(() {
                    if (val == null) {
                      _dailyPnL.remove(_editingDate!);
                    } else {
                      _dailyPnL[_editingDate!] = val;
                    }
                    _editingDate = null;
                  });
                  _save();
                },
                onCancel: () => setState(() => _editingDate = null),
              ),
            ],

            const SizedBox(height:10),
            Row(mainAxisAlignment:MainAxisAlignment.center, children:[
              _legendTile(AppColors.green.withValues(alpha:0.3), 'Small win'),
              const SizedBox(width:10),
              _legendTile(AppColors.green, 'Big win'),
              const SizedBox(width:10),
              _legendTile(AppColors.red.withValues(alpha:0.3), 'Small loss'),
              const SizedBox(width:10),
              _legendTile(AppColors.red, 'Big loss'),
            ]),
          ]),
        )),

        // Day list
        ..._buildDayList(isDark, txt, muted, card, bord),
        const SizedBox(height:40),
      ])),
    );
  }

  List<Widget> _buildDayList(bool isDark, Color txt, Color muted, Color card, Color bord) {
    final prefix = '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2,'0')}';
    final entries = _dailyPnL.entries.where((e) => e.key.startsWith(prefix)).toList()
      ..sort((a,b) => b.key.compareTo(a.key));
    if (entries.isEmpty) return [];
    return [
      Padding(padding:const EdgeInsets.fromLTRB(20,0,20,8), child:Text('Daily Breakdown', style:TextStyle(fontSize:14, fontWeight:FontWeight.w700, color:txt))),
      ...entries.map((e) => Padding(padding:const EdgeInsets.fromLTRB(20,0,20,6), child:
        Dismissible(
          key:Key(e.key),
          direction:DismissDirection.endToStart,
          background:Container(decoration:BoxDecoration(color:AppColors.red, borderRadius:BorderRadius.circular(14)), alignment:Alignment.centerRight, padding:const EdgeInsets.only(right:16), child:const Icon(Icons.delete_rounded, color:Colors.white)),
          onDismissed:(_){setState(()=>_dailyPnL.remove(e.key));_save();},
          child:Container(padding:const EdgeInsets.symmetric(horizontal:16, vertical:12),
            decoration:BoxDecoration(color:card, borderRadius:BorderRadius.circular(14), border:Border.all(color:bord, width:.5)),
            child:Row(children:[
              Container(width:8, height:8, decoration:BoxDecoration(color:e.value>=0?AppColors.green:AppColors.red, shape:BoxShape.circle)),
              const SizedBox(width:10),
              Text(e.key, style:TextStyle(fontSize:13, color:txt)),
              const Spacer(),
              Text('${e.value>=0?'+':''}\$${e.value.toStringAsFixed(2)}',
                style:TextStyle(fontSize:15, fontWeight:FontWeight.w800, color:e.value>=0?AppColors.green:AppColors.red)),
            ])),
        )
      )),
    ];
  }

  void _showGoalDialog(bool isDark, Color txt, Color muted, Color card) {
    showDialog(context:context, builder:(_)=>AlertDialog(
      backgroundColor:card,
      title:Text('Monthly Goal', style:TextStyle(color:txt, fontWeight:FontWeight.w700)),
      content:TextField(
        controller:_goalCtrl,
        autofocus:true,
        keyboardType:const TextInputType.numberWithOptions(decimal:true),
        style:TextStyle(color:txt, fontSize:20, fontWeight:FontWeight.w700),
        decoration:InputDecoration(prefixText:'\$', prefixStyle:const TextStyle(color:AppColors.gold, fontSize:20), hintText:'e.g. 3000', hintStyle:TextStyle(color:muted)),
      ),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(context), child:Text('Cancel', style:TextStyle(color:muted))),
        TextButton(onPressed:(){setState((){_monthlyGoal=double.tryParse(_goalCtrl.text)??_monthlyGoal;});_save();Navigator.pop(context);},
          child:const Text('Save', style:TextStyle(color:AppColors.gold, fontWeight:FontWeight.w700))),
      ],
    ));
  }

  Widget _pill(String text, Color color, bool isDark) => Container(
    padding:const EdgeInsets.symmetric(horizontal:7, vertical:3),
    decoration:BoxDecoration(color:color.withValues(alpha:0.15), borderRadius:BorderRadius.circular(20)),
    child:Text(text, style:TextStyle(fontSize:10, fontWeight:FontWeight.w700, color:color)));

  Widget _legendTile(Color color, String label) => Row(children:[
    Container(width:10, height:10, decoration:BoxDecoration(color:color, borderRadius:BorderRadius.circular(3))),
    const SizedBox(width:4),
    Text(label, style:const TextStyle(fontSize:9, color:AppColors.textMuted)),
  ]);
}

class _DayEditor extends StatefulWidget {
  final String date;
  final double? currentValue;
  final bool isDark;
  final void Function(double?) onSave;
  final VoidCallback onCancel;
  const _DayEditor({required this.date, this.currentValue, required this.isDark, required this.onSave, required this.onCancel});
  @override State<_DayEditor> createState() => _DayEditorState();
}

class _DayEditorState extends State<_DayEditor> {
  late TextEditingController _ctrl;
  bool _isWin = true;

  @override
  void initState() {
    super.initState();
    final v = widget.currentValue;
    _isWin = v == null || v >= 0;
    _ctrl = TextEditingController(text: v != null ? v.abs().toStringAsFixed(2) : '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final stat = isDark ? AppColors.darkCard2 : AppColors.lightCard2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1500) : const Color(0xFFFFFBEE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha:.5), width: 1),
      ),
      child: Column(children: [
        // Win / Loss toggle
        Container(
          decoration: BoxDecoration(color:stat, borderRadius:BorderRadius.circular(12)),
          child: Row(children:[
            Expanded(child:GestureDetector(
              onTap:(){ setState(()=>_isWin=true); HapticFeedback.selectionClick(); },
              child:AnimatedContainer(duration:const Duration(milliseconds:200),
                padding:const EdgeInsets.symmetric(vertical:10),
                decoration:BoxDecoration(color:_isWin?AppColors.green:Colors.transparent, borderRadius:BorderRadius.circular(12)),
                child:Center(child:Text('▲  WIN', style:TextStyle(fontSize:13, fontWeight:FontWeight.w800, color:_isWin?Colors.white:AppColors.textMuted)))))),
            Expanded(child:GestureDetector(
              onTap:(){ setState(()=>_isWin=false); HapticFeedback.selectionClick(); },
              child:AnimatedContainer(duration:const Duration(milliseconds:200),
                padding:const EdgeInsets.symmetric(vertical:10),
                decoration:BoxDecoration(color:!_isWin?AppColors.red:Colors.transparent, borderRadius:BorderRadius.circular(12)),
                child:Center(child:Text('▼  LOSS', style:TextStyle(fontSize:13, fontWeight:FontWeight.w800, color:!_isWin?Colors.white:AppColors.textMuted)))))),
          ]),
        ),
        const SizedBox(height:12),
        // Amount input
        TextField(
          controller: _ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal:true),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize:32, fontWeight:FontWeight.w900, color:_isWin?AppColors.green:AppColors.red),
          decoration: InputDecoration(
            hintText: '0.00',
            hintStyle: TextStyle(color:AppColors.textMuted.withValues(alpha:.5), fontSize:32),
            prefixText: '\$ ',
            prefixStyle: TextStyle(fontSize:20, fontWeight:FontWeight.w700, color:_isWin?AppColors.green:AppColors.red),
            filled: true, fillColor: stat,
            border: OutlineInputBorder(borderRadius:BorderRadius.circular(14), borderSide:BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal:16, vertical:14),
          ),
        ),
        const SizedBox(height:12),
        Row(children:[
          Expanded(child:GestureDetector(
            onTap:widget.onCancel,
            child:Container(padding:const EdgeInsets.symmetric(vertical:12),
              decoration:BoxDecoration(color:stat, borderRadius:BorderRadius.circular(12)),
              child:const Center(child:Text('Cancel', style:TextStyle(fontSize:13, fontWeight:FontWeight.w600, color:AppColors.textMuted)))))),
          const SizedBox(width:8),
          Expanded(flex:2, child:GestureDetector(
            onTap:(){
              final raw = double.tryParse(_ctrl.text);
              if (raw == null || raw == 0) { widget.onSave(null); return; }
              widget.onSave(_isWin ? raw : -raw);
            },
            child:Container(padding:const EdgeInsets.symmetric(vertical:12),
              decoration:BoxDecoration(color:AppColors.gold, borderRadius:BorderRadius.circular(12)),
              child:const Center(child:Text('Save Trade', style:TextStyle(fontSize:14, fontWeight:FontWeight.w800, color:Colors.black)))))),
          if (widget.currentValue != null) ...[
            const SizedBox(width:8),
            GestureDetector(
              onTap:()=>widget.onSave(null),
              child:Container(padding:const EdgeInsets.symmetric(vertical:12, horizontal:14),
                decoration:BoxDecoration(color:AppColors.redDim, borderRadius:BorderRadius.circular(12)),
                child:const Icon(Icons.delete_rounded, color:AppColors.red, size:20))),
          ],
        ]),
      ]),
    );
  }
}
