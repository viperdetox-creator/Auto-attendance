import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/attendance_service.dart';
import '../../data/database_helper.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  Map<String, Map<String, dynamic>> _monthRecords = {};
  bool _calendarLoading = true;

  late AnimationController _entryCtrl;
  late AnimationController _orbCtrl;
  late AnimationController _graceCtrl;
  late Animation<double> _graceAnim;

  // ── Palette ──────────────────────────────────
  static const _bg = Color(0xFF0A0E1A);
  static const _surface = Color(0xFF131929);
  static const _card = Color(0xFF1C2333);
  static const _teal = Color(0xFF00D4B8);
  static const _amber = Color(0xFFFFB347);
  static const _rose = Color(0xFFFF6B8A);
  static const _indigo = Color(0xFF6C7FE8);
  static const _textPri = Color(0xFFEEF2FF);
  static const _textSec = Color(0xFF7A8BAA);

  // Calendar colors
  static const _presentBg = Color(0xFF0D2E2A);
  static const _presentFg = Color(0xFF00D4B8);
  static const _absentBg = Color(0xFF2E0D13);
  static const _absentFg = Color(0xFFFF6B8A);
  static const _halfBg = Color(0xFF2E2200);
  static const _halfFg = Color(0xFFFFB347);
  static const _sundayBg = Color(0xFF161C2A);
  static const _sundayFg = Color(0xFF4A5568);
  static const _leaveBg = Color(0xFF1A1E2E);
  static const _leaveFg = Color(0xFF6C7FE8);

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _orbCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();
    _graceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _graceAnim =
        CurvedAnimation(parent: _graceCtrl, curve: Curves.easeOutCubic);

    _entryCtrl.forward();
    _loadMonthData();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _orbCtrl.dispose();
    _graceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMonthData() async {
    setState(() => _calendarLoading = true);
    final all = await DatabaseHelper.instance.getAllAttendance();
    final ym = '${_focusedMonth.year}-'
        '${_focusedMonth.month.toString().padLeft(2, '0')}';
    final Map<String, Map<String, dynamic>> filtered = {};
    for (final r in all) {
      final d = r['date'] as String? ?? '';
      if (d.startsWith(ym)) filtered[d.substring(0, 10)] = r;
    }
    setState(() {
      _monthRecords = filtered;
      _calendarLoading = false;
    });
    _graceCtrl.forward(from: 0);
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String _statusFor(DateTime date) {
    final today = DateTime.now();
    if (date.isAfter(today) && date.day != today.day) return 'future';
    final r = _monthRecords[_dateKey(date)];
    if (r == null) return 'absent';
    final t = (r['attendance_type'] as String? ?? '').toUpperCase();
    if (t == 'LEAVE') return 'leave';
    if (t == 'HALF' || t == 'HALF DAY') return 'half';
    if (t == 'ABSENT') return 'absent';
    return 'present';
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceService>().fetchHistory();
    });

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          _buildOrbBg(),
          SafeArea(
            child: Consumer<AttendanceService>(
              builder: (context, service, _) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fade(0.0, 0.3, _buildPageTitle()),
                      const SizedBox(height: 20),
                      _fade(0.1, 0.45, _buildGraceCard(service)),
                      const SizedBox(height: 20),
                      _fade(0.2, 0.6, _buildCalendarCard()),
                      const SizedBox(height: 20),
                      _fade(0.3, 0.75, _buildLogsSection(service)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrbBg() {
    return AnimatedBuilder(
      animation: _orbCtrl,
      builder: (_, __) {
        final t = _orbCtrl.value * 2 * math.pi;
        return Stack(children: [
          Positioned(
              top: -80 + math.sin(t) * 25,
              right: -60,
              child: _orb(220, _teal.withOpacity(0.06))),
          Positioned(
              bottom: 200 + math.cos(t) * 30,
              left: -80,
              child: _orb(200, _indigo.withOpacity(0.07))),
        ]);
      },
    );
  }

  Widget _orb(double size, Color color) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent])));

  Widget _fade(double start, double end, Widget child) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
          parent: _entryCtrl,
          curve: Interval(start, end, curve: Curves.easeOut))),
      child: child,
    );
  }

  Widget _buildPageTitle() {
    return const Text('History',
        style: TextStyle(
            color: _textPri,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5));
  }

  // ── Grace card ────────────────────────────────
  Widget _buildGraceCard(AttendanceService service) {
    const limit = 250;
    final used = service.monthlyGraceTotal;
    final progress = (used / limit).clamp(0.0, 1.0);
    final Color barColor = used > 200 ? _rose : _teal;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0D2E2A),
            const Color(0xFF0A1A2E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _teal.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
              color: _teal.withOpacity(0.08), blurRadius: 24, spreadRadius: 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Monthly Grace',
                      style: TextStyle(
                          color: _textSec,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                            text: '$used',
                            style: TextStyle(
                                color: barColor,
                                fontSize: 26,
                                fontWeight: FontWeight.w800)),
                        TextSpan(
                            text: ' / $limit',
                            style: const TextStyle(
                                color: _textSec,
                                fontSize: 16,
                                fontWeight: FontWeight.w500)),
                        const TextSpan(
                            text: ' min',
                            style: TextStyle(color: _textSec, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              // Circular mini progress
              SizedBox(
                width: 56,
                height: 56,
                child: AnimatedBuilder(
                  animation: _graceAnim,
                  builder: (_, __) => CustomPaint(
                    painter: _ArcPainter(
                        progress: progress * _graceAnim.value, color: barColor),
                    child: Center(
                      child: Text('${(progress * 100).toInt()}%',
                          style: TextStyle(
                              color: barColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: AnimatedBuilder(
              animation: _graceAnim,
              builder: (_, __) => LinearProgressIndicator(
                value: progress * _graceAnim.value,
                backgroundColor: Colors.white.withOpacity(0.08),
                valueColor: AlwaysStoppedAnimation(barColor),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('${limit - used} mins remaining',
              style: const TextStyle(color: _textSec, fontSize: 11)),
        ],
      ),
    );
  }

  // ── Calendar card ─────────────────────────────
  Widget _buildCalendarCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.07), width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _buildCalHeader(),
          const SizedBox(height: 12),
          _buildDayLabels(),
          const SizedBox(height: 6),
          _calendarLoading
              ? SizedBox(
                  height: 160,
                  child: Center(
                    child:
                        CircularProgressIndicator(color: _teal, strokeWidth: 2),
                  ),
                )
              : _buildGrid(),
          Divider(height: 24, color: Colors.white.withOpacity(0.06)),
          _buildLegend(),
          const SizedBox(height: 12),
          _buildStats(),
        ],
      ),
    );
  }

  Widget _buildCalHeader() {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _navBtn(Icons.chevron_left_rounded, () {
          setState(() => _focusedMonth =
              DateTime(_focusedMonth.year, _focusedMonth.month - 1));
          _loadMonthData();
        }),
        Text('${months[_focusedMonth.month - 1]} ${_focusedMonth.year}',
            style: const TextStyle(
                color: _textPri, fontSize: 15, fontWeight: FontWeight.w700)),
        _navBtn(Icons.chevron_right_rounded, () {
          setState(() => _focusedMonth =
              DateTime(_focusedMonth.year, _focusedMonth.month + 1));
          _loadMonthData();
        }),
      ],
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
              color: _teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: _teal, size: 18),
        ),
      );

  Widget _buildDayLabels() {
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      children: labels
          .asMap()
          .entries
          .map((e) => Expanded(
                child: Center(
                  child: Text(e.value,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: e.key == 0 ? _sundayFg : _textSec)),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildGrid() {
    final today = DateTime.now();
    final daysInMonth =
        DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    final firstWeekday =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday % 7;
    final cells = <Widget>[];

    for (int i = 0; i < firstWeekday; i++) cells.add(const SizedBox());

    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, d);
      final isSunday = date.weekday == DateTime.sunday;
      final isToday = _dateKey(date) == _dateKey(today);
      final status = isSunday ? 'sunday' : _statusFor(date);

      Color bg, fg;
      switch (status) {
        case 'present':
          bg = _presentBg;
          fg = _presentFg;
          break;
        case 'half':
          bg = _halfBg;
          fg = _halfFg;
          break;
        case 'absent':
          bg = _absentBg;
          fg = _absentFg;
          break;
        case 'sunday':
          bg = _sundayBg;
          fg = _sundayFg;
          break;
        case 'leave':
          bg = _leaveBg;
          fg = _leaveFg;
          break;
        default:
          bg = _surface;
          fg = _textSec.withOpacity(0.3);
      }

      cells.add(AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: isToday ? Border.all(color: _amber, width: 2) : null,
          boxShadow: status == 'present'
              ? [BoxShadow(color: _teal.withOpacity(0.15), blurRadius: 6)]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$d',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
            if (['present', 'absent', 'half', 'leave'].contains(status))
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                    color: fg.withOpacity(0.7), shape: BoxShape.circle),
              ),
          ],
        ),
      ));
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 5,
      crossAxisSpacing: 5,
      children: cells,
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 10,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        _dot(_presentBg, _presentFg, 'Present'),
        _dot(_absentBg, _absentFg, 'Absent'),
        _dot(_halfBg, _halfFg, 'Half'),
        _dot(_sundayBg, _sundayFg, 'Sunday'),
        _dot(_leaveBg, _leaveFg, 'Leave'),
      ],
    );
  }

  Widget _dot(Color bg, Color fg, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: fg.withOpacity(0.5))),
      ),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: _textSec, fontSize: 10)),
    ]);
  }

  Widget _buildStats() {
    final today = DateTime.now();
    final daysInMonth =
        DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    int present = 0, half = 0, absent = 0;

    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, d);
      if (date.isAfter(today)) continue;
      if (date.weekday == DateTime.sunday) continue;
      final s = _statusFor(date);
      if (s == 'present')
        present++;
      else if (s == 'half')
        half++;
      else if (s == 'absent') absent++;
    }

    final total = present + half + absent;
    final pct = total > 0 ? ((present + half * 0.5) / total * 100).round() : 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _statPill('$present', 'Present', _presentFg, _presentBg),
        _statPill('$absent', 'Absent', _absentFg, _absentBg),
        _statPill('$half', 'Half', _halfFg, _halfBg),
        Column(children: [
          Text('$pct%',
              style: const TextStyle(
                  color: _teal, fontSize: 20, fontWeight: FontWeight.w800)),
          const Text('attendance',
              style: TextStyle(color: _textSec, fontSize: 10)),
        ]),
      ],
    );
  }

  Widget _statPill(String count, String label, Color fg, Color bg) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(count,
            style: TextStyle(
                color: fg, fontWeight: FontWeight.w800, fontSize: 14)),
      ),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: _textSec, fontSize: 10)),
    ]);
  }

  // ── Logs section ──────────────────────────────
  Widget _buildLogsSection(AttendanceService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: _indigo.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8)),
              child:
                  const Icon(Icons.history_rounded, color: _indigo, size: 16),
            ),
            const SizedBox(width: 10),
            const Text('Recent Logs',
                style: TextStyle(
                    color: _textPri,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 12),
        service.history.isEmpty ? _emptyState() : _buildLogList(service),
      ],
    );
  }

  Widget _buildLogList(AttendanceService service) {
    return ListView.builder(
      itemCount: service.history.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (ctx, i) {
        final r = service.history[i];
        final type = r['attendance_type'] as String? ?? 'FULL';
        final grace = r['used_grace_minutes'] ?? 0;
        final Color c = type == 'LEAVE'
            ? _leaveFg
            : type == 'ABSENT'
                ? _absentFg
                : type == 'HALF'
                    ? _halfFg
                    : _presentFg;
        final IconData ic = type == 'LEAVE'
            ? Icons.event_busy_rounded
            : type == 'ABSENT'
                ? Icons.cancel_rounded
                : type == 'HALF'
                    ? Icons.hourglass_bottom_rounded
                    : Icons.check_circle_rounded;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.withOpacity(0.15), width: 1),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                    color: c.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(ic, color: c, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r['date'],
                        style: const TextStyle(
                            color: _textPri,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    const SizedBox(height: 3),
                    Text(
                      'In: ${r['punch_in']?.substring(11, 16) ?? '--:--'}'
                      '  •  Out: ${r['punch_out']?.substring(11, 16) ?? '--:--'}',
                      style: const TextStyle(color: _textSec, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: c.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(type,
                        style: TextStyle(
                            color: c,
                            fontWeight: FontWeight.w700,
                            fontSize: 11)),
                  ),
                  if (grace > 0) ...[
                    const SizedBox(height: 4),
                    Text('-$grace min',
                        style: const TextStyle(
                            color: _rose,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.history_toggle_off,
                size: 48, color: _textSec.withOpacity(0.3)),
            const SizedBox(height: 12),
            const Text('No logs yet',
                style: TextStyle(color: _textSec, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ── Arc painter for grace circle ──────────────────
class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  _ArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final bg = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bg);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}
