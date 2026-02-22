import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/utils/pdf_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late AnimationController _orbCtrl;
  late List<Animation<double>> _cardFade;
  late List<Animation<Offset>> _cardSlide;

  // ── Palette ──────────────────────────────────
  static const _bg = Color(0xFF0A0E1A);
  static const _card = Color(0xFF1C2333);
  static const _teal = Color(0xFF00D4B8);
  static const _amber = Color(0xFFFFB347);
  static const _rose = Color(0xFFFF6B8A);
  static const _indigo = Color(0xFF6C7FE8);
  static const _textPri = Color(0xFFEEF2FF);
  static const _textSec = Color(0xFF7A8BAA);

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _orbCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 9))
          ..repeat();

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
      return Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
          .animate(CurvedAnimation(
              parent: _entryCtrl,
              curve: Interval(start, end, curve: Curves.easeOutCubic)));
    });

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _orbCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeCtrl = context.watch<ThemeController>();
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          _buildOrbBg(),
          SafeArea(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .snapshots(),
              builder: (context, snap) {
                String name = 'Faculty Member';
                String dept = 'Department';
                if (snap.hasData && snap.data!.exists) {
                  final d = snap.data!.data() as Map<String, dynamic>;
                  name = d['name'] ?? name;
                  dept = d['department'] ?? dept;
                }

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _animated(0, _buildProfileCard(name, dept, user?.email)),
                      const SizedBox(height: 20),
                      _animated(1,
                          _sectionLabel('Appearance', Icons.palette_outlined)),
                      const SizedBox(height: 10),
                      _animated(2, _buildThemeCard(themeCtrl)),
                      const SizedBox(height: 20),
                      _animated(
                          3,
                          _sectionLabel('Data & Account',
                              Icons.manage_accounts_outlined)),
                      const SizedBox(height: 10),
                      _animated(4, _buildActionsCard(context)),
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
              top: -60 + math.sin(t) * 20,
              left: -40,
              child: _orb(200, _indigo.withOpacity(0.07))),
          Positioned(
              bottom: 60 + math.cos(t) * 25,
              right: -60,
              child: _orb(180, _teal.withOpacity(0.06))),
        ]);
      },
    );
  }

  Widget _orb(double s, Color c) => Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [c, Colors.transparent])));

  // ── Profile card ──────────────────────────────
  Widget _buildProfileCard(String name, String dept, String? email) {
    // Derive avatar initials
    final initials = name
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .take(2)
        .join();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2545), Color(0xFF0D1A35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _indigo.withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(
              color: _indigo.withOpacity(0.1), blurRadius: 24, spreadRadius: 2),
        ],
      ),
      child: Row(
        children: [
          // Avatar with glow
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                  colors: [Color(0xFF3949AB), Color(0xFF00D4B8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              boxShadow: [
                BoxShadow(
                    color: _teal.withOpacity(0.25),
                    blurRadius: 16,
                    spreadRadius: 1),
              ],
            ),
            child: Center(
              child: Text(initials,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: _textPri,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _indigo.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(dept,
                      style: const TextStyle(
                          color: _indigo,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
                if (email != null) ...[
                  const SizedBox(height: 4),
                  Text(email,
                      style: const TextStyle(color: _textSec, fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Theme card ────────────────────────────────
  Widget _buildThemeCard(ThemeController ctrl) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.07), width: 1),
      ),
      child: Column(
        children: [
          _themeTile(
            ctrl: ctrl,
            value: ThemeMode.light,
            icon: Icons.light_mode_rounded,
            label: 'Light Mode',
            sub: 'Bright & energising',
            color: _amber,
          ),
          Divider(
              height: 1,
              color: Colors.white.withOpacity(0.06),
              indent: 16,
              endIndent: 16),
          _themeTile(
            ctrl: ctrl,
            value: ThemeMode.dark,
            icon: Icons.dark_mode_rounded,
            label: 'Dark Mode',
            sub: 'Easy on the eyes',
            color: _indigo,
          ),
        ],
      ),
    );
  }

  Widget _themeTile({
    required ThemeController ctrl,
    required ThemeMode value,
    required IconData icon,
    required String label,
    required String sub,
    required Color color,
  }) {
    final selected = ctrl.themeMode == value;
    return InkWell(
      onTap: () =>
          value == ThemeMode.light ? ctrl.setLightMode() : ctrl.setDarkMode(),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: _textPri,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  Text(sub,
                      style: const TextStyle(color: _textSec, fontSize: 11)),
                ],
              ),
            ),
            // Animated radio
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? color : Colors.transparent,
                border: Border.all(
                    color: selected ? color : _textSec.withOpacity(0.3),
                    width: 2),
                boxShadow: selected
                    ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)]
                    : null,
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 13)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ── Actions card ──────────────────────────────
  Widget _buildActionsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.07), width: 1),
      ),
      child: Column(
        children: [
          _actionTile(
            icon: Icons.picture_as_pdf_rounded,
            color: _rose,
            label: 'Generate PDF Report',
            sub: 'Export attendance as PDF',
            onTap: () async {
              _showToast(context, '📄 Generating PDF...', _indigo);
              try {
                await PdfExportService.generateAttendancePdf();
              } catch (e) {
                _showToast(context, 'Export failed: $e', _rose);
              }
            },
          ),
          Divider(
              height: 1,
              color: Colors.white.withOpacity(0.06),
              indent: 16,
              endIndent: 16),
          _actionTile(
            icon: Icons.logout_rounded,
            color: _rose,
            label: 'Sign Out',
            sub: 'Log out of your account',
            labelColor: _rose,
            onTap: () => _confirmSignOut(context),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required Color color,
    required String label,
    required String sub,
    required VoidCallback onTap,
    Color? labelColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: labelColor ?? _textPri,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  Text(sub,
                      style: const TextStyle(color: _textSec, fontSize: 11)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.chevron_right_rounded,
                  color: _textSec, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: _teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: _teal, size: 15),
        ),
        const SizedBox(width: 10),
        Text(text,
            style: const TextStyle(
                color: _textSec,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
      ],
    );
  }

  Widget _animated(int i, Widget child) {
    return FadeTransition(
      opacity: _cardFade[i],
      child: SlideTransition(position: _cardSlide[i], child: child),
    );
  }

  void _showToast(BuildContext ctx, String msg, Color color) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: color,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      content: Text(msg,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700)),
      duration: const Duration(seconds: 2),
    ));
  }

  void _confirmSignOut(BuildContext context) {
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
                    color: _rose.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.logout_rounded, color: _rose, size: 28),
              ),
              const SizedBox(height: 16),
              const Text('Sign Out?',
                  style: TextStyle(
                      color: _textPri,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('You will need to log in again.',
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
                        Navigator.pop(ctx);
                        FirebaseAuth.instance.signOut();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _rose,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Sign Out',
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
}
