import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/services/attendance_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with TickerProviderStateMixin {
  // ── Animation controllers ─────────────────────
  late AnimationController _entryCtrl; // staggered entry
  late AnimationController _ripple1Ctrl; // ripple ring 1
  late AnimationController _ripple2Ctrl; // ripple ring 2 (offset)
  late AnimationController _ripple3Ctrl; // ripple ring 3 (offset)
  late AnimationController _pinBounce; // pin idle bounce
  late AnimationController _graceCtrl; // grace arc sweep
  late AnimationController _orbCtrl; // background orbs
  late AnimationController _radarCtrl; // radar sweep (outside zone)

  late Animation<double> _graceAnim;

  // Staggered entry animations
  late List<Animation<double>> _cardFade;
  late List<Animation<Offset>> _cardSlide;

  double _lastGraceProgress = 0;

  // ── Palette (matches other screens) ──────────
  static const _bg = Color(0xFF0A0E1A);
  static const _card = Color(0xFF1C2333);
  static const _surface = Color(0xFF131929);
  static const _teal = Color(0xFF00D4B8);
  static const _tealDark = Color(0xFF00A896);
  static const _rose = Color(0xFFFF6B8A);
  static const _amber = Color(0xFFFFB347);
  static const _indigo = Color(0xFF6C7FE8);
  static const _textPri = Color(0xFFEEF2FF);
  static const _textSec = Color(0xFF7A8BAA);

  @override
  void initState() {
    super.initState();

    // Entry
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));

    // 3 staggered ripple rings
    _ripple1Ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat();
    _ripple2Ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat();
    _ripple3Ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat();

    // Pin bounce
    _pinBounce = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);

    // Grace arc
    _graceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _graceAnim =
        CurvedAnimation(parent: _graceCtrl, curve: Curves.easeOutCubic);
    _graceCtrl.forward();

    // Background orbs
    _orbCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();

    // Radar sweep for outside zone
    _radarCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();

    // Stagger ripple rings by offset
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _ripple2Ctrl.forward(from: 0.33);
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _ripple3Ctrl.forward(from: 0.66);
    });

    // Staggered card entry
    _cardFade = List.generate(5, (i) {
      final start = i * 0.14;
      final end = (start + 0.45).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
          parent: _entryCtrl,
          curve: Interval(start, end, curve: Curves.easeOut)));
    });
    _cardSlide = List.generate(5, (i) {
      final start = i * 0.14;
      final end = (start + 0.5).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero)
          .animate(CurvedAnimation(
              parent: _entryCtrl,
              curve: Interval(start, end, curve: Curves.easeOutCubic)));
    });

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _ripple1Ctrl.dispose();
    _ripple2Ctrl.dispose();
    _ripple3Ctrl.dispose();
    _pinBounce.dispose();
    _graceCtrl.dispose();
    _orbCtrl.dispose();
    _radarCtrl.dispose();
    super.dispose();
  }

  void _animateGraceIfChanged(double newProgress) {
    if ((newProgress - _lastGraceProgress).abs() > 0.001) {
      _lastGraceProgress = newProgress;
      _graceCtrl
        ..reset()
        ..forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<AttendanceService>();
    final bool isInside = service.isInside;
    final bool isPunchedIn = service.isPunchedIn;
    final bool hasPunch = service.punchIn != null;

    const int totalGrace = 250;
    final int monthlyUsed = service.monthlyGraceTotal;
    final int graceLeft = (totalGrace - monthlyUsed).clamp(0, totalGrace);
    final double graceProgress = (graceLeft / totalGrace).clamp(0.0, 1.0);
    _animateGraceIfChanged(graceProgress);

    final Color graceColor = graceLeft < 50
        ? _rose
        : graceLeft < 150
            ? _amber
            : _teal;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          _buildOrbBg(),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // ── Location animation section ──
                _animated(0, _buildLocationSection(isInside, isPunchedIn)),
                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // ── Punch times ─────────────
                      _animated(1, _buildPunchRow(service, context)),
                      const SizedBox(height: 14),

                      // ── Status + Grace ───────────
                      _animated(
                          2,
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                  child: _buildStatusCard(service, hasPunch)),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: _buildGraceCard(graceLeft, monthlyUsed,
                                      totalGrace, graceProgress, graceColor)),
                            ],
                          )),
                      const SizedBox(height: 14),

                      // ── Stats strip ──────────────
                      _animated(3, _buildStatsStrip(service)),
                      const SizedBox(height: 20),

                      // ── Punch button ─────────────
                      _animated(
                          4, _buildPunchButton(context, service, isPunchedIn)),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Drifting orb background ───────────────────
  Widget _buildOrbBg() {
    return AnimatedBuilder(
      animation: _orbCtrl,
      builder: (_, __) {
        final t = _orbCtrl.value * 2 * math.pi;
        return Stack(children: [
          Positioned(
              top: -80 + math.sin(t) * 20,
              right: -60,
              child: _orb(220, _teal.withOpacity(0.05))),
          Positioned(
              bottom: 160 + math.cos(t) * 25,
              left: -70,
              child: _orb(200, _indigo.withOpacity(0.06))),
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

  // ─────────────────────────────────────────────
  //  LOCATION SECTION
  //  Inside  → Swiggy-style expanding ripple rings
  //  Outside → Radar sweep searching animation
  // ─────────────────────────────────────────────
  Widget _buildLocationSection(bool isInside, bool isPunchedIn) {
    final Color activeColor = isInside ? _teal : _rose;
    final Color dimColor =
        isInside ? _teal.withOpacity(0.15) : _rose.withOpacity(0.12);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        border: Border.all(color: activeColor.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(
              color: activeColor.withOpacity(0.12),
              blurRadius: 30,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Text(_todayLabel(),
              style: const TextStyle(
                  color: _textSec, fontSize: 12, letterSpacing: 1.1)),
          const SizedBox(height: 28),

          // ── Animation area ──────────────────
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ── OUTSIDE: Radar sweep ──────
                if (!isInside) ...[
                  // Static concentric guide rings
                  _staticRing(160, _rose, 0.07),
                  _staticRing(120, _rose, 0.1),
                  _staticRing(80, _rose, 0.13),
                  // Rotating radar sweep
                  AnimatedBuilder(
                    animation: _radarCtrl,
                    builder: (_, __) => Transform.rotate(
                      angle: _radarCtrl.value * 2 * math.pi,
                      child: CustomPaint(
                        size: const Size(200, 200),
                        painter: _RadarSweepPainter(color: _rose),
                      ),
                    ),
                  ),
                  // Radar blip dots that pulse in/out
                  _radarBlip(40, 20, 0.3),
                  _radarBlip(70, 320, 0.55),
                  _radarBlip(55, 170, 0.75),
                ],

                // ── INSIDE: Ripple rings ───────
                if (isInside) ...[
                  _rippleRing(_ripple3Ctrl, _teal, 190, 0.05),
                  _rippleRing(_ripple2Ctrl, _teal, 148, 0.10),
                  _rippleRing(_ripple1Ctrl, _teal, 106, 0.18),
                ],

                // ── Glow base ─────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dimColor,
                    boxShadow: [
                      BoxShadow(
                          color: activeColor.withOpacity(isInside ? 0.3 : 0.2),
                          blurRadius: isInside ? 30 : 16,
                          spreadRadius: isInside ? 4 : 2),
                    ],
                  ),
                ),

                // ── Pin ───────────────────────
                AnimatedBuilder(
                  animation: _pinBounce,
                  builder: (_, __) {
                    final bounce = isInside
                        ? Tween<double>(begin: -6, end: 4).evaluate(
                            CurvedAnimation(
                                parent: _pinBounce, curve: Curves.easeInOut))
                        : Tween<double>(begin: -2, end: 2).evaluate(
                            CurvedAnimation(
                                parent: _pinBounce, curve: Curves.easeInOut));
                    return Transform.translate(
                      offset: Offset(0, bounce),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(colors: [
                                activeColor,
                                activeColor.withOpacity(0.75),
                              ]),
                              boxShadow: [
                                BoxShadow(
                                    color: activeColor.withOpacity(0.5),
                                    blurRadius: 18,
                                    spreadRadius: 2),
                              ],
                            ),
                            child: Icon(
                              isInside
                                  ? Icons.location_on_rounded
                                  : Icons.location_searching_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          CustomPaint(
                            size: const Size(14, 10),
                            painter: _PinTailPainter(color: activeColor),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            width: isInside ? 20 : 12,
                            height: 5,
                            decoration: BoxDecoration(
                              color: activeColor.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Status text
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Column(
              key: ValueKey(isInside),
              children: [
                Text(
                  isInside ? 'Inside Campus' : 'Outside Campus',
                  style: TextStyle(
                      color: activeColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2),
                ),
                const SizedBox(height: 4),
                if (!isInside)
                  Text(
                    'Scanning for campus…',
                    style:
                        TextStyle(color: _rose.withOpacity(0.6), fontSize: 12),
                  ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: activeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: activeColor.withOpacity(0.3), width: 1),
                  ),
                  child: Text(
                    isInside
                        ? '● Auto attendance active'
                        : '◌ Auto attendance inactive',
                    style: TextStyle(
                        color: activeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Ripple ring (inside) ──────────────────────
  Widget _rippleRing(AnimationController ctrl, Color color, double maxSize,
      double maxOpacity) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final t = ctrl.value;
        final size = maxSize * 0.35 + maxSize * 0.65 * t;
        final opacity = maxOpacity * (1.0 - t);
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: color.withOpacity(opacity.clamp(0.0, 1.0)), width: 1.5),
          ),
        );
      },
    );
  }

  // ── Static ring guide (outside radar) ────────
  Widget _staticRing(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(opacity), width: 1),
      ),
    );
  }

  // ── Radar blip dot ────────────────────────────
  // Appears at [distance] px from center at [angleDeg] degrees
  // [phase] controls when in the radar cycle it lights up
  Widget _radarBlip(double distance, double angleDeg, double phase) {
    final rad = angleDeg * math.pi / 180;
    final dx = distance * math.cos(rad);
    final dy = distance * math.sin(rad);
    return AnimatedBuilder(
      animation: _radarCtrl,
      builder: (_, __) {
        // Blip is visible just after the radar sweeps past it
        final sweepAngle = _radarCtrl.value; // 0..1
        final blipAngle = angleDeg / 360;
        final diff = (sweepAngle - blipAngle + 1) % 1.0;
        // Bright just after sweep, fades over next 0.35 of rotation
        final opacity = diff < 0.35 ? (1.0 - diff / 0.35) * 0.9 : 0.0;
        return Transform.translate(
          offset: Offset(dx, dy),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _rose.withOpacity(opacity),
              boxShadow: opacity > 0.3
                  ? [
                      BoxShadow(
                          color: _rose.withOpacity(opacity * 0.7),
                          blurRadius: 6,
                          spreadRadius: 1)
                    ]
                  : null,
            ),
          ),
        );
      },
    );
  }

  // ── Punch time row ────────────────────────────
  Widget _buildPunchRow(AttendanceService service, BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _punchTile(
          icon: Icons.login_rounded,
          color: _teal,
          label: 'Punch In',
          value: service.punchIn == null
              ? '--:--'
              : TimeOfDay.fromDateTime(service.punchIn!).format(context),
        )),
        const SizedBox(width: 12),
        Expanded(
            child: _punchTile(
          icon: Icons.logout_rounded,
          color: _amber,
          label: 'Punch Out',
          value: service.finalPunchOut == null
              ? '--:--'
              : TimeOfDay.fromDateTime(service.finalPunchOut!).format(context),
        )),
      ],
    );
  }

  Widget _punchTile({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 11, color: _textSec)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _textPri)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Day status card ───────────────────────────
  Widget _buildStatusCard(AttendanceService service, bool hasPunch) {
    if (!hasPunch) {
      return _darkCard(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pending_outlined,
              color: _textSec.withOpacity(0.4), size: 30),
          const SizedBox(height: 8),
          const Text('Not Started',
              style: TextStyle(
                  color: _textSec, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 2),
          Text('No punch today',
              style: TextStyle(fontSize: 10, color: _textSec.withOpacity(0.5))),
        ],
      ));
    }

    final type = service.dayType;
    final isHalf = type == 'HALF';
    final isLeave = type == 'LEAVE';
    final isAbsent = type == 'ABSENT';
    final Color c = isLeave
        ? _indigo
        : isAbsent
            ? _rose
            : isHalf
                ? _amber
                : _teal;
    final IconData ic = isLeave
        ? Icons.event_busy_rounded
        : isAbsent
            ? Icons.cancel_rounded
            : isHalf
                ? Icons.hourglass_bottom_rounded
                : Icons.check_circle_rounded;

    return _darkCard(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: c.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14)),
          child: Icon(ic, color: c, size: 26),
        ),
        const SizedBox(height: 8),
        Text(type ?? 'IN PROGRESS',
            style:
                TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 13)),
        const SizedBox(height: 3),
        Text('Grace: ${service.graceMinutes} min',
            style: const TextStyle(fontSize: 10, color: _textSec)),
      ],
    ));
  }

  // ── Compact grace card ────────────────────────
  Widget _buildGraceCard(int graceLeft, int monthlyUsed, int totalGrace,
      double graceProgress, Color color) {
    return _darkCard(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 72,
          height: 72,
          child: AnimatedBuilder(
            animation: _graceAnim,
            builder: (_, __) => Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: graceProgress * _graceAnim.value,
                  strokeWidth: 6,
                  color: color,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Text('$graceLeft',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: color)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text('Grace Left',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: _textPri)),
        const SizedBox(height: 2),
        Text('$monthlyUsed / $totalGrace min',
            style: const TextStyle(fontSize: 10, color: _textSec)),
      ],
    ));
  }

  // ── Stats strip ───────────────────────────────
  Widget _buildStatsStrip(AttendanceService service) {
    final int used = service.monthlyGraceTotal;
    final int left = (250 - used).clamp(0, 250);
    final pct = ((left / 250) * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat('Grace Used', '$used min', _rose),
          _vDivider(),
          _stat('Grace Left', '$left min', _teal),
          _vDivider(),
          _stat('Balance', '$pct%', _indigo),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(children: [
      Text(value,
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 3),
      Text(label, style: const TextStyle(fontSize: 11, color: _textSec)),
    ]);
  }

  Widget _vDivider() =>
      Container(height: 36, width: 1, color: Colors.white.withOpacity(0.07));

  // ── Punch button ──────────────────────────────
  Widget _buildPunchButton(
      BuildContext context, AttendanceService service, bool isPunchedIn) {
    final Color btnColor = isPunchedIn ? _rose : _teal;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
      child: GestureDetector(
        onTap: () async {
          HapticFeedback.heavyImpact();
          await service.handlePunch(punchType: 'manual');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: btnColor,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              content: Text(
                isPunchedIn ? '✓ Punched Out' : '✓ Punched In',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
              duration: const Duration(seconds: 2),
            ));
          }
        },
        child: Container(
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPunchedIn
                  ? [_rose, const Color(0xFFFF4D6D)]
                  : [_teal, _tealDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: btnColor.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPunchedIn ? Icons.logout_rounded : Icons.fingerprint_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                isPunchedIn ? 'Manual Punch Out' : 'Manual Punch In',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Reusable dark card ────────────────────────
  Widget _darkCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }

  // ── Animated entry helper ─────────────────────
  Widget _animated(int i, Widget child) {
    return FadeTransition(
      opacity: _cardFade[i],
      child: SlideTransition(position: _cardSlide[i], child: child),
    );
  }

  // ── Helpers ───────────────────────────────────
  String _todayLabel() {
    final now = DateTime.now();
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}'
        .toUpperCase();
  }
}

// ── Custom painter: radar sweep ──────────────────
class _RadarSweepPainter extends CustomPainter {
  final Color color;
  _RadarSweepPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Sweep wedge — 70 degree arc with gradient fade
    final sweepPaint = Paint()..style = PaintingStyle.fill;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Draw gradient sweep wedge
    for (int i = 0; i < 30; i++) {
      final frac = i / 30.0;
      final opacity = (1.0 - frac) * 0.25;
      final startRad = -frac * (70 * math.pi / 180);
      sweepPaint.color = color.withOpacity(opacity);
      canvas.drawArc(rect, startRad, -(2 * math.pi / 180), false, sweepPaint);
    }

    // Leading edge line
    final linePaint = Paint()
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(center, Offset(center.dx + radius, center.dy), linePaint);
  }

  @override
  bool shouldRepaint(_RadarSweepPainter old) => old.color != color;
}

// ── Custom painter: location pin tail ────────────
class _PinTailPainter extends CustomPainter {
  final Color color;
  _PinTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PinTailPainter old) => old.color != color;
}
