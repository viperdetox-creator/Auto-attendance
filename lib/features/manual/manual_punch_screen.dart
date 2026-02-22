import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/services/attendance_service.dart';

class ManualPunchScreen extends StatefulWidget {
  const ManualPunchScreen({super.key});
  @override
  State<ManualPunchScreen> createState() => _ManualPunchScreenState();
}

class _ManualPunchScreenState extends State<ManualPunchScreen>
    with TickerProviderStateMixin {
  DateTime _selDate = DateTime.now();
  TimeOfDay _inT = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _outT = const TimeOfDay(hour: 16, minute: 0);

  late AnimationController _entryCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _orbCtrl;
  late List<Animation<double>> _cardFade;
  late List<Animation<Offset>> _cardSlide;

  // ── Palette ──────────────────────────────────
  static const _bg = Color(0xFF0A0E1A);
  static const _surface = Color(0xFF131929);
  static const _card = Color(0xFF1C2333);
  static const _teal = Color(0xFF00D4B8);
  static const _tealDark = Color(0xFF00A896);
  static const _amber = Color(0xFFFFB347);
  static const _rose = Color(0xFFFF6B8A);
  static const _textPri = Color(0xFFEEF2FF);
  static const _textSec = Color(0xFF7A8BAA);

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _orbCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat();

    _cardFade = List.generate(4, (i) {
      final start = i * 0.18;
      final end = (start + 0.5).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
          parent: _entryCtrl,
          curve: Interval(start, end, curve: Curves.easeOut)));
    });

    _cardSlide = List.generate(4, (i) {
      final start = i * 0.18;
      final end = (start + 0.55).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
          .animate(CurvedAnimation(
              parent: _entryCtrl,
              curve: Interval(start, end, curve: Curves.easeOutCubic)));
    });

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    _orbCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AttendanceService>(
      builder: (context, service, _) {
        final isIn = service.isPunchedIn;
        return Scaffold(
          backgroundColor: _bg,
          body: Stack(
            children: [
              _buildOrbBackground(),
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _animated(0, _buildPageTitle()),
                      const SizedBox(height: 24),
                      _animated(1, _buildLivePunchCard(service, isIn)),
                      const SizedBox(height: 24),
                      _animated(
                          2,
                          _buildSectionHeader(
                              'Manual Override', Icons.edit_calendar_outlined)),
                      const SizedBox(height: 12),
                      _animated(3, _buildOverrideCard(service)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Animated orb background ───────────────────
  Widget _buildOrbBackground() {
    return AnimatedBuilder(
      animation: _orbCtrl,
      builder: (_, __) {
        final t = _orbCtrl.value * 2 * math.pi;
        return Stack(children: [
          Positioned(
            top: -60 + math.sin(t) * 20,
            right: -40 + math.cos(t) * 15,
            child: _glowOrb(200, _teal.withOpacity(0.08)),
          ),
          Positioned(
            bottom: 100 + math.cos(t) * 25,
            left: -60 + math.sin(t * 0.7) * 20,
            child: _glowOrb(180, _rose.withOpacity(0.06)),
          ),
        ]);
      },
    );
  }

  Widget _glowOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }

  // ── Page title ────────────────────────────────
  Widget _buildPageTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Manual Punch',
            style: TextStyle(
                color: _textPri,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text(_todayLabel(),
            style: const TextStyle(color: _textSec, fontSize: 13)),
      ],
    );
  }

  // ── Live punch card ───────────────────────────
  Widget _buildLivePunchCard(AttendanceService service, bool isIn) {
    final Color accent = isIn ? _rose : _teal;
    final Color dimmed =
        isIn ? const Color(0xFF3D1E28) : const Color(0xFF0D2E2A);

    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, child) {
        final glow = 0.4 + _pulseCtrl.value * 0.6;
        return Container(
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accent.withOpacity(0.25), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: accent.withOpacity(0.12 * glow),
                  blurRadius: 24,
                  spreadRadius: 2),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent.withOpacity(0.3), accent.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.sensors_rounded, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Live Status',
                      style: TextStyle(
                          color: _textPri,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                  Text(
                    isIn ? 'Currently punched in' : 'Currently punched out',
                    style: TextStyle(color: accent, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Big punch button
          GestureDetector(
            onTap: () async {
              HapticFeedback.heavyImpact();
              await service.handlePunch(punchType: 'manual');
              if (mounted) {
                _showToast(
                  isIn ? '✓ Punched Out' : '✓ Punched In',
                  isIn ? _rose : _teal,
                );
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 58,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isIn
                      ? [_rose, const Color(0xFFFF4D6D)]
                      : [_teal, _tealDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: (isIn ? _rose : _teal).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 6)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isIn ? Icons.logout_rounded : Icons.fingerprint_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isIn ? 'Manual Punch Out' : 'Manual Punch In',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Override card ─────────────────────────────
  Widget _buildOverrideCard(AttendanceService service) {
    return Container(
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
          _pickerRow(
            Icons.calendar_month_rounded,
            _teal,
            'Date',
            '${_selDate.day} ${_month(_selDate.month)} ${_selDate.year}',
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _selDate,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now(),
                builder: (ctx, child) => Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme:
                        const ColorScheme.dark(primary: _teal, surface: _card),
                  ),
                  child: child!,
                ),
              );
              if (d != null) setState(() => _selDate = d);
            },
          ),
          _hairline(),
          _pickerRow(
            Icons.login_rounded,
            _teal,
            'Punch In',
            _inT.format(context),
            onTap: () async {
              final t = await showTimePicker(
                context: context,
                initialTime: _inT,
                builder: (ctx, child) => Theme(
                  data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                          primary: _teal, surface: _card)),
                  child: child!,
                ),
              );
              if (t != null) setState(() => _inT = t);
            },
          ),
          _hairline(),
          _pickerRow(
            Icons.logout_rounded,
            _amber,
            'Punch Out',
            _outT.format(context),
            onTap: () async {
              final t = await showTimePicker(
                context: context,
                initialTime: _outT,
                builder: (ctx, child) => Theme(
                  data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                          primary: _amber, surface: _card)),
                  child: child!,
                ),
              );
              if (t != null) setState(() => _outT = t);
            },
          ),
          _hairline(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: GestureDetector(
              onTap: () => _confirm(service),
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3949AB), Color(0xFF5C6BC0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF3949AB).withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 5)),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Save Record',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pickerRow(IconData icon, Color color, String label, String value,
      {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: _textSec,
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(
                          color: _textPri,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.chevron_right_rounded,
                  color: _textSec, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hairline() => Divider(
      height: 1,
      color: Colors.white.withOpacity(0.06),
      indent: 20,
      endIndent: 20);

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _teal.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _teal, size: 16),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(
                color: _textPri, fontSize: 15, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _animated(int i, Widget child) {
    return FadeTransition(
      opacity: _cardFade[i],
      child: SlideTransition(position: _cardSlide[i], child: child),
    );
  }

  void _showToast(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
      content: Text(msg,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700)),
      duration: const Duration(seconds: 2),
    ));
  }

  void _confirm(AttendanceService service) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: _amber, size: 28),
              ),
              const SizedBox(height: 16),
              const Text('Confirm Override',
                  style: TextStyle(
                      color: _textPri,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('This will replace existing logs for this date.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _textSec, fontSize: 13)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        foregroundColor: _textSec,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side:
                              BorderSide(color: Colors.white.withOpacity(0.1)),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        service.manualOverridePunch(
                          selectedDate: _selDate,
                          inTime: _inT,
                          outTime: _outT,
                        );
                        Navigator.pop(ctx);
                        _showToast('✓ Record Saved', _teal);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Save',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _month(int m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[m - 1];
  }

  String _todayLabel() {
    final now = DateTime.now();
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[now.weekday - 1]}, ${now.day} ${_month(now.month)} ${now.year}';
  }
}
