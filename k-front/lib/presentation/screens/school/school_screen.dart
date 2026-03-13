// v1.1.1
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:knoty/core/controllers/auth_controller.dart';
import 'package:knoty/data/models/user_model.dart';
import 'package:knoty/l10n/app_localizations.dart';
import 'package:knoty/presentation/widgets/knoty_app_bar.dart';

class SchoolScreen extends StatelessWidget {
  const SchoolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    final isVerified = user?.isSchoolVerified ?? false;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: KnotyAppBar(title: l10n.schoolTitle),
      body: isVerified
          ? _SchoolContent(user: user)
          : _NotVerifiedState(user: user),
    );
  }
}

// ── Not verified ──────────────────────────────────────────────────────────────

class _NotVerifiedState extends StatefulWidget {
  final User? user;
  const _NotVerifiedState({this.user});
  @override
  State<_NotVerifiedState> createState() => _NotVerifiedStateState();
}

class _NotVerifiedStateState extends State<_NotVerifiedState> {
  final _codeCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() { _codeCtrl.dispose(); super.dispose(); }

  Future<void> _submit(AppLocalizations l10n) async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) { setState(() => _error = l10n.schoolCodeEmpty); return; }
    setState(() { _isLoading = true; _error = null; });
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() { _isLoading = false; _error = l10n.schoolCodeInvalid; });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(children: [
      Positioned.fill(child: _SchoolContentPreview()),
      Positioned.fill(child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(color: Colors.white.withOpacity(0.82)),
      )),
      Center(child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE6B800).withOpacity(0.4)),
            ),
            child: const Icon(Icons.school_rounded, size: 40, color: Color(0xFFE6B800)),
          ),
          const SizedBox(height: 20),
          Text(l10n.schoolNotVerifiedTitle,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
            textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(l10n.schoolNotVerifiedSubtitle,
            style: const TextStyle(fontSize: 16, color: Color(0xFF9E9E9E), height: 1.5),
            textAlign: TextAlign.center),
          const SizedBox(height: 28),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _error != null
                  ? const Color(0xFFDD0000).withOpacity(0.5)
                  : const Color(0xFFE6B800).withOpacity(0.4)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: TextField(
              controller: _codeCtrl,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
                LengthLimitingTextInputFormatter(12),
              ],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 4, color: Color(0xFF1A1A1A)),
              decoration: InputDecoration(
                hintText: l10n.schoolCodeHint,
                hintStyle: const TextStyle(fontSize: 18, color: Color(0xFFBDBDBD), letterSpacing: 2, fontWeight: FontWeight.w400),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
              onSubmitted: (_) => _submit(l10n),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(fontSize: 14, color: Color(0xFFDD0000)), textAlign: TextAlign.center),
          ],
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: GestureDetector(
            onTap: _isLoading ? null : () => _submit(l10n),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(color: const Color(0xFFE6B800), borderRadius: BorderRadius.circular(24)),
              child: Center(child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                : Text(l10n.schoolCodeRedeem, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white))),
            ),
          )),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE6B800).withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.hourglass_top_rounded, size: 18, color: Color(0xFFE6B800)),
              const SizedBox(width: 10),
              Expanded(child: Text(
                widget.user?.school != null
                    ? l10n.schoolWaitingFrom(widget.user!.school!)
                    : l10n.schoolWaitingConfirmation,
                style: const TextStyle(fontSize: 14, color: Color(0xFFE6B800), fontWeight: FontWeight.w500, height: 1.4),
              )),
            ]),
          ),
        ]),
      )),
    ]);
  }
}

class _SchoolContentPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Container(height: 160, decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFE6B800), Color(0xFFFFD84D)]),
          borderRadius: BorderRadius.circular(28),
        )),
        const SizedBox(height: 20),
        GridView.count(crossAxisCount: 2, shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.15,
          children: List.generate(6, (_) => Container(
            decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(24)),
          )),
        ),
      ]),
    );
  }
}

// ── Verified content ──────────────────────────────────────────────────────────

class _SchoolContent extends StatelessWidget {
  final User? user;
  const _SchoolContent({this.user});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _HeroBanner(user: user),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            _StatChip(icon: Icons.people_rounded, label: l10n.schoolStatClass, value: user?.schoolClass ?? '–'),
            const SizedBox(width: 10),
            _StatChip(icon: Icons.star_rounded, label: l10n.schoolStatStatus, value: l10n.schoolStatActive, color: const Color(0xFF4CAF50)),
            const SizedBox(width: 10),
            _StatChip(icon: Icons.notifications_rounded, label: l10n.schoolStatNew, value: '3'),
          ]),
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _SectionLabel(l10n.schoolServicesTitle),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.count(
            crossAxisCount: 2, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 1.15,
            children: [
              _ServiceCard(icon: Icons.calendar_today_rounded, label: l10n.schoolTimetable,      color: const Color(0xFF5B8DEF), bg: const Color(0xFFEEF3FF), onTap: () => _soon(context, l10n.schoolTimetable)),
              _ServiceCard(icon: Icons.campaign_rounded,        label: l10n.schoolAnnouncements, color: const Color(0xFFFF7043), bg: const Color(0xFFFFF3F0), badge: '3', onTap: () => _soon(context, l10n.schoolAnnouncements)),
              _ServiceCard(icon: Icons.folder_rounded,          label: l10n.schoolDocuments,     color: const Color(0xFFE6B800), bg: const Color(0xFFFFFBE6), onTap: () => _soon(context, l10n.schoolDocuments)),
              _ServiceCard(icon: Icons.assignment_rounded,      label: l10n.schoolHomework,      color: const Color(0xFF26A69A), bg: const Color(0xFFE0F5F4), onTap: () => _soon(context, l10n.schoolHomework)),
              _ServiceCard(icon: Icons.grade_rounded,           label: l10n.schoolGrades,        color: const Color(0xFF7C4DFF), bg: const Color(0xFFF3EEFF), onTap: () => _soon(context, l10n.schoolGrades)),
              _ServiceCard(icon: Icons.event_rounded,           label: l10n.schoolEvents,        color: const Color(0xFFEC407A), bg: const Color(0xFFFCEEF4), onTap: () => _soon(context, l10n.schoolEvents)),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _SectionLabel(l10n.schoolUpcomingTitle),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _EventTeaser(),
        ),
        const SizedBox(height: 30),
      ]),
    );
  }

  void _soon(BuildContext context, String name) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l10n.schoolComingSoon(name)),
      backgroundColor: const Color(0xFF1A1A1A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ));
  }
}

// ── Hero banner ───────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final User? user;
  const _HeroBanner({this.user});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE6B800), Color(0xFFFFD84D), Color(0xFFFFE57F)],
        ),
        boxShadow: [BoxShadow(color: const Color(0xFFE6B800).withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Stack(children: [
        Positioned(right: -20, top: -20, child: Container(width: 120, height: 120,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.10)))),
        Positioned(right: 30, bottom: -30, child: Container(width: 80, height: 80,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08)))),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Container(width: 36, height: 36,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 20)),
              const SizedBox(width: 10),
              Expanded(child: Text(user?.school ?? l10n.schoolTitle,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                overflow: TextOverflow.ellipsis)),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user?.schoolClass != null ? '${l10n.schoolStatClass} ${user!.schoolClass}' : '',
                style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85))),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.check_circle_rounded, size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(l10n.schoolVerifiedBadge, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

// ── Stat chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  const _StatChip({required this.icon, required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFFE6B800);
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: c),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c)),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)), overflow: TextOverflow.ellipsis),
      ]),
    ));
  }
}

// ── Service card ──────────────────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final String? badge;
  final VoidCallback onTap;
  const _ServiceCard({required this.icon, required this.label, required this.color, required this.bg, this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Stack(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(width: 44, height: 44,
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color, size: 22)),
              Text(label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            ]),
          ),
          if (badge != null) Positioned(top: 10, right: 10, child: Container(
            width: 20, height: 20,
            decoration: const BoxDecoration(color: Color(0xFFFF3B30), shape: BoxShape.circle),
            child: Center(child: Text(badge!, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700))),
          )),
        ]),
      ),
    );
  }
}

// ── Event teaser ──────────────────────────────────────────────────────────────

class _EventTeaser extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        Container(width: 48, height: 56,
          decoration: BoxDecoration(color: const Color(0xFFEEF3FF), borderRadius: BorderRadius.circular(16)),
          child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('MO', style: TextStyle(fontSize: 10, color: Color(0xFF5B8DEF), fontWeight: FontWeight.w600)),
            Text('24', style: TextStyle(fontSize: 18, color: Color(0xFF5B8DEF), fontWeight: FontWeight.w800, height: 1.1)),
          ])),
        const SizedBox(width: 14),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Elternsprechtag', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
          SizedBox(height: 3),
          Text('14:00 – 18:00 Uhr · Aula', style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E))),
        ])),
        Container(width: 32, height: 32,
          decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF9E9E9E))),
      ]),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel(this.title);
  @override
  Widget build(BuildContext context) => Text(title.toUpperCase(),
    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF9E9E9E), letterSpacing: 0.8));
}