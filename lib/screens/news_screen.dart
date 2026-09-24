import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../config/obsidian_theme.dart';
import '../l10n/gen/app_localizations.dart';

class NewsItem {
  final String title, source, time, impact;
  final String? description, url, image;
  NewsItem({
    required this.title,
    required this.source,
    required this.time,
    required this.impact,
    this.description,
    this.url,
    this.image,
  });
}

class NewsEvent {
  final String title, impact, currency, time, category;
  final String? actual, forecast, previous;
  final bool isSoon, isPast;
  NewsEvent({
    required this.title,
    required this.impact,
    required this.currency,
    required this.time,
    required this.category,
    this.actual,
    this.forecast,
    this.previous,
    this.isSoon = false,
    this.isPast = false,
  });
}

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});
  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<NewsItem> _news = [];
  List<NewsEvent> _events = [];
  bool _loadingNews = true, _loadingEvents = true;
  Timer? _refreshTimer;
  DateTime _lastNewsUpdate = DateTime.now();

  static final _backend = 'https://pulstrade-backend-production.up.railway.app';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _fetchNews();
    _fetchEvents();
    // Auto-refresh news every 5 minutes
    _refreshTimer = Timer.periodic(Duration(minutes: 5), (_) {
      _fetchNews();
      _fetchEvents();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchNews() async {
    setState(() => _loadingNews = true);
    try {
      final res = await http
          .get(Uri.parse('$_backend/news'))
          .timeout(Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List;
        setState(() {
          _news = data
              .map((n) => NewsItem(
                    title: n['title']?.toString() ?? '',
                    source: n['source']?.toString() ?? '',
                    time: n['time']?.toString() ?? '',
                    impact: n['impact']?.toString() ?? 'low',
                    description: n['description']?.toString(),
                    url: n['url']?.toString(),
                    image: n['image']?.toString(),
                  ))
              .where((n) => n.title.isNotEmpty)
              .toList();
          _news = _refineNews(_news);
          _loadingNews = false;
          _lastNewsUpdate = DateTime.now();
        });
        return;
      }
    } catch (_) {}
    _loadFallbackNews();
  }

  Future<void> _fetchEvents() async {
    setState(() => _loadingEvents = true);
    try {
      // Fetch live calendar from backend
      final res = await http
          .get(Uri.parse('$_backend/calendar'))
          .timeout(Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List;
        setState(() {
          _events = data
              .map((e) => NewsEvent(
                    title: e['title']?.toString() ?? '',
                    impact: e['impact']?.toString() ?? 'low',
                    currency: e['currency']?.toString() ?? 'USD',
                    time: e['timeLabel']?.toString() ?? '',
                    category: e['category']?.toString() ?? '',
                    forecast: e['forecast']?.toString(),
                    previous: e['previous']?.toString(),
                    actual: e['actual']?.toString(),
                    isSoon: e['isSoon'] == true,
                    isPast: e['isPast'] == true,
                  ))
              .toList();
          _loadingEvents = false;
        });
        return;
      }
    } catch (_) {}
    _loadFallbackEvents();
  }

  // Gold-Relevanz: dedupliziert und bewertet Headlines danach,
  // ob sie XAU/USD wirklich bewegen. Impact-Badge wird neu vergeben.
  List<NewsItem> _refineNews(List<NewsItem> raw) {
    final seen = <String>{};
    final unique = <NewsItem>[];
    for (final item in raw) {
      final key = item.title
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
          .split(' ')
          .where((w) => w.isNotEmpty)
          .take(8)
          .join(' ');
      if (seen.contains(key)) continue;
      seen.add(key);
      unique.add(item);
    }
    int score(NewsItem item) {
      final t = '${item.title} ${item.description ?? ''}'.toLowerCase();
      var sc = 0;
      final hi = ['gold', 'xau', 'bullion', 'fed', 'fomc', 'powell',
        'rate cut', 'rate hike', 'interest rate', 'inflation', 'cpi',
        'ppi', 'nfp', 'non-farm', 'payroll', 'jobless', 'dollar', 'dxy',
        'treasury', 'yield', 'safe-haven', 'safe haven', 'geopolit',
        'tariff', 'sanction', 'war', 'recession'];
      final lo = ['rbi', 'india', 'rupee', 'aggregator', 'show hn',
        'crypto', 'bitcoin', 'ethereum'];
      for (final k in hi) { if (t.contains(k)) sc += 2; }
      for (final k in lo) { if (t.contains(k)) sc -= 3; }
      return sc;
    }
    final scored = <({NewsItem item, int s, int idx})>[];
    for (var i = 0; i < unique.length; i++) {
      scored.add((item: unique[i], s: score(unique[i]), idx: i));
    }
    var keep = scored.where((e) => e.s > 0).toList();
    if (keep.length < 3) keep = scored.where((e) => e.s >= 0).toList();
    if (keep.isEmpty) keep = scored;
    keep.sort((a, b) => a.s != b.s ? b.s.compareTo(a.s) : a.idx.compareTo(b.idx));
    return keep.map((e) => NewsItem(
      title: e.item.title,
      source: e.item.source,
      time: e.item.time,
      impact: e.s >= 6 ? 'high' : (e.s >= 3 ? 'medium' : 'low'),
      description: e.item.description,
      url: e.item.url,
      image: e.item.image,
    )).toList();
  }

  void _loadFallbackNews() {
    setState(() {
      _news = [
        NewsItem(
            title: 'Gold hits record high amid safe-haven demand',
            source: 'Reuters',
            time: '2h ago',
            impact: 'high',
            description:
                'Gold prices surged to record levels as geopolitical tensions escalated, driving safe-haven demand globally.'),
        NewsItem(
            title: 'Fed signals data-dependent approach to rate cuts',
            source: 'Bloomberg',
            time: '4h ago',
            impact: 'high',
            description:
                'Federal Reserve officials indicated a cautious approach to rate reductions as inflation data remains mixed.'),
        NewsItem(
            title: 'Dollar strength pressures gold prices',
            source: 'FT',
            time: '6h ago',
            impact: 'medium',
            description:
                'A stronger US dollar index created headwinds for gold, which typically moves inversely to DXY.'),
        NewsItem(
            title: 'Central banks add to gold reserves in Q1',
            source: 'WGC',
            time: '8h ago',
            impact: 'medium',
            description:
                'World Gold Council reports continued buying from emerging market central banks supporting gold demand.'),
      ];
      _loadingNews = false;
    });
  }

  void _loadFallbackEvents() {
    setState(() {
      _events = [
        NewsEvent(
            title: 'US Non-Farm Payrolls',
            currency: 'USD',
            category: 'Employment',
            impact: 'high',
            time: 'Fri 13:30 UTC',
            forecast: '185K',
            previous: '175K'),
        NewsEvent(
            title: 'Fed Interest Rate Decision',
            currency: 'USD',
            category: 'Central Bank',
            impact: 'high',
            time: 'Wed 19:00 UTC',
            forecast: '5.25%',
            previous: '5.25%'),
        NewsEvent(
            title: 'US CPI (MoM)',
            currency: 'USD',
            category: 'Inflation',
            impact: 'high',
            time: 'Tue 13:30 UTC',
            forecast: '0.3%',
            previous: '0.4%'),
        NewsEvent(
            title: 'US Jobless Claims',
            currency: 'USD',
            category: 'Employment',
            impact: 'medium',
            time: 'Thu 13:30 UTC',
            forecast: '215K',
            previous: '210K'),
        NewsEvent(
            title: 'US PPI (MoM)',
            currency: 'USD',
            category: 'Inflation',
            impact: 'medium',
            time: 'Thu 13:30 UTC',
            forecast: '0.2%',
            previous: '0.2%'),
      ];
      _loadingEvents = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txt = Obsidian.textHi;
    final muted = Obsidian.textMid;
    final bg = Obsidian.bg;

    return Scaffold(
      body: Column(children: [
        Container(
            color: bg,
            child: SafeArea(
                bottom: false,
                child: Column(children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(children: [
                      Text(AppLocalizations.of(context).newsTitle,
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: txt)),
                      Spacer(),
                      // Live indicator
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Obsidian.buyBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(children: [
                          Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                  color: Obsidian.buy,
                                  shape: BoxShape.circle)),
                          SizedBox(width: 4),
                          Text(AppLocalizations.of(context).liveBadge,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Obsidian.buy)),
                        ]),
                      ),
                    ]),
                  ),
                  TabBar(
                    controller: _tabs,
                    labelColor: Obsidian.gold,
                    unselectedLabelColor: muted,
                    indicatorColor: Obsidian.gold,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelStyle: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                    tabs: [Tab(text: AppLocalizations.of(context).tabNews), Tab(text: AppLocalizations.of(context).tabCalendar)],
                  ),
                ]))),
        Expanded(
            child: TabBarView(controller: _tabs, children: [
          // NEWS TAB
          _loadingNews
              ? Center(
                  child: CircularProgressIndicator(color: Obsidian.gold))
              : RefreshIndicator(
                  color: Obsidian.gold,
                  onRefresh: _fetchNews,
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: _news.length + 1,
                    itemBuilder: (ctx, i) {
                      if (i == 0) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            AppLocalizations.of(context).newsUpdated(_timeAgo(context, _lastNewsUpdate)),
                            style: TextStyle(fontSize: 11, color: muted),
                          ),
                        );
                      }
                      return _NewsCard(item: _news[i - 1], isDark: isDark);
                    },
                  ),
                ),

          // CALENDAR TAB
          _loadingEvents
              ? Center(
                  child: CircularProgressIndicator(color: Obsidian.gold))
              : RefreshIndicator(
                  color: Obsidian.gold,
                  onRefresh: _fetchEvents,
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: _events.length + 1,
                    itemBuilder: (ctx, i) {
                      if (i == 0) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Obsidian.goldBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Obsidian.gold.withValues(alpha: .2)),
                            ),
                            child: Row(children: [
                              Icon(Icons.info_outline,
                                  size: 14, color: Obsidian.gold),
                              SizedBox(width: 8),
                              Expanded(
                                  child: Text(
                                AppLocalizations.of(context).pausedTip,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Obsidian.gold,
                                    height: 1.4),
                              )),
                            ]),
                          ),
                        );
                      }
                      return _EventCard(event: _events[i - 1], isDark: isDark);
                    },
                  ),
                ),
        ])),
      ]),
    );
  }

  String _timeAgo(BuildContext context, DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return AppLocalizations.of(context).justNow;
    if (diff.inMinutes < 60) return AppLocalizations.of(context).minAgo(diff.inMinutes);
    return AppLocalizations.of(context).hourAgo(diff.inHours);
  }
}

String _deTime(String t) {
  final m = RegExp(r'^(\d+)\s*(m|min|h|d)\s*ago$').firstMatch(t.trim());
  if (m == null) return t;
  final unit = {'m': 'Min', 'min': 'Min', 'h': 'Std', 'd': 'T'}[m.group(2)];
  return 'vor ${m.group(1)} $unit';
}

class _NewsCard extends StatefulWidget {
  final NewsItem item;
  final bool isDark;
  const _NewsCard({required this.item, required this.isDark});
  @override
  State<_NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<_NewsCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final txt = Obsidian.textHi;
    final muted = Obsidian.textMid;
    final card = Obsidian.card;
    final bord = Obsidian.stroke;
    final impact = widget.item.impact;
    final impactColor = impact == 'high'
        ? Obsidian.sell
        : impact == 'medium'
            ? Obsidian.gold
            : muted;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _expanded ? Obsidian.gold.withValues(alpha: .4) : bord,
            width: _expanded ? 1 : 0.5,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: impactColor.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(impact.toUpperCase(),
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: impactColor)),
            ),
            SizedBox(width: 8),
            Text(widget.item.source,
                style: TextStyle(fontSize: 10, color: muted)),
            Spacer(),
            Text(_deTime(widget.item.time),
                style: TextStyle(fontSize: 10, color: muted)),
            SizedBox(width: 6),
            Icon(
                _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 16,
                color: muted),
          ]),
          SizedBox(height: 8),
          Text(widget.item.title,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: txt,
                  height: 1.4)),
          if (_expanded) ...[
            if (widget.item.description != null) ...[
              SizedBox(height: 10),
              Text(widget.item.description!,
                  style: TextStyle(fontSize: 12, color: muted, height: 1.6)),
            ],
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: impactColor.withValues(alpha: .07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                Icon(Icons.show_chart, size: 14, color: impactColor),
                SizedBox(width: 6),
                Expanded(
                    child: Text(
                  impact == 'high'
                      ? AppLocalizations.of(context).impactHighNews
                      : impact == 'medium'
                          ? AppLocalizations.of(context).impactMediumNews
                          : AppLocalizations.of(context).impactLowNews,
                  style: TextStyle(
                      fontSize: 11,
                      color: impactColor,
                      fontWeight: FontWeight.w600),
                )),
              ]),
            ),
            if (widget.item.url != null) ...[
              SizedBox(height: 10),
              GestureDetector(
                onTap: () => launchUrl(Uri.parse(widget.item.url!),
                    mode: LaunchMode.externalApplication),
                child: Row(children: [
                  Spacer(),
                  Text(AppLocalizations.of(context).readFull,
                      style: TextStyle(
                          fontSize: 11,
                          color: Obsidian.gold,
                          fontWeight: FontWeight.w600)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios,
                      size: 10, color: Obsidian.gold),
                ]),
              ),
            ],
          ] else ...[
            SizedBox(height: 6),
            Text(AppLocalizations.of(context).tapMore,
                style: TextStyle(fontSize: 10, color: muted)),
          ],
        ]),
      ),
    );
  }
}

class _EventCard extends StatefulWidget {
  final NewsEvent event;
  final bool isDark;
  const _EventCard({required this.event, required this.isDark});
  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final txt = Obsidian.textHi;
    final muted = Obsidian.textMid;
    final card = Obsidian.card;
    final bord = Obsidian.stroke;
    final stat = Obsidian.cardAlt;
    final e = widget.event;
    final impactColor = e.impact == 'high'
        ? Obsidian.sell
        : e.impact == 'medium'
            ? Obsidian.gold
            : muted;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: e.isSoon ? impactColor.withValues(alpha: .05) : card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: e.isSoon
                ? impactColor.withValues(alpha: .4)
                : _expanded
                    ? Obsidian.gold.withValues(alpha: .4)
                    : bord,
            width: e.isSoon || _expanded ? 1 : 0.5,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            // Impact bars
            Row(
                children: List.generate(
                    3,
                    (j) => Container(
                          width: 4,
                          height: j == 0
                              ? 8
                              : j == 1
                                  ? 12
                                  : 16,
                          margin: EdgeInsets.only(right: 2),
                          decoration: BoxDecoration(
                            color: j <
                                    (e.impact == 'high'
                                        ? 3
                                        : e.impact == 'medium'
                                            ? 2
                                            : 1)
                                ? impactColor
                                : impactColor.withValues(alpha: .2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ))),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: stat, borderRadius: BorderRadius.circular(6)),
              child: Text(e.currency,
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w800, color: txt)),
            ),
            SizedBox(width: 6),
            Text(e.category, style: TextStyle(fontSize: 10, color: muted)),
            Spacer(),
            // Time badge — highlighted if soon
            Container(
              padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: e.isSoon
                    ? impactColor.withValues(alpha: .15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: e.isSoon
                    ? Border.all(
                        color: impactColor.withValues(alpha: .4), width: .5)
                    : null,
              ),
              child: Text(e.time,
                  style: TextStyle(
                      fontSize: 10,
                      color: e.isSoon ? impactColor : muted,
                      fontWeight:
                          e.isSoon ? FontWeight.w700 : FontWeight.w400)),
            ),
            SizedBox(width: 6),
            Icon(
                _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 16,
                color: muted),
          ]),
          SizedBox(height: 8),
          Text(e.title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: e.isPast ? muted : txt)),
          if (_expanded) ...[
            SizedBox(height: 12),
            Row(children: [
              _chip(AppLocalizations.of(context).chipForecast, e.forecast ?? '—', Obsidian.gold, stat),
              SizedBox(width: 8),
              _chip(AppLocalizations.of(context).chipPrevious, e.previous ?? '—', muted, stat),
              if (e.actual != null) ...[
                SizedBox(width: 8),
                _chip(AppLocalizations.of(context).chipActual, e.actual!, Obsidian.buy, stat),
              ],
            ]),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: impactColor.withValues(alpha: .07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                Icon(Icons.info_outline, size: 14, color: impactColor),
                SizedBox(width: 6),
                Expanded(
                    child: Text(
                  e.impact == 'high'
                      ? AppLocalizations.of(context).eventHighTip
                      : AppLocalizations.of(context).eventMediumTip,
                  style:
                      TextStyle(fontSize: 11, color: impactColor, height: 1.4),
                )),
              ]),
            ),
          ] else ...[
            SizedBox(height: 8),
            Row(children: [
              _chip(AppLocalizations.of(context).chipForecast, e.forecast ?? '—', Obsidian.gold, stat),
              SizedBox(width: 8),
              _chip(AppLocalizations.of(context).chipPrevious, e.previous ?? '—', muted, stat),
              Spacer(),
              Text(AppLocalizations.of(context).tapDetails,
                  style: TextStyle(fontSize: 10, color: muted)),
            ]),
          ],
        ]),
      ),
    );
  }

  Widget _chip(String label, String value, Color color, Color bg) => Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Column(children: [
          Text(label,
              style: TextStyle(fontSize: 8, color: Obsidian.textMid)),
          SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ]),
      );
}
