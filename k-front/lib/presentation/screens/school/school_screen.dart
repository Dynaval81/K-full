// v3.1.0 — School Tab: schedule views, teachers, grade detail, notes, QR
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:knoty/core/controllers/auth_controller.dart';
import 'package:knoty/core/enums/user_role.dart';
import 'package:knoty/data/models/user_model.dart';
import 'package:knoty/l10n/app_localizations.dart';
import 'package:knoty/presentation/widgets/knoty_app_bar.dart';

// ─── Data models ──────────────────────────────────────────────────────────────

class _Slot {
  final int startH, startM, endH, endM;
  final bool isBreak;
  final String? subject, teacher, room;
  final Color color;
  final IconData icon;

  const _Slot({
    required this.startH, required this.startM,
    required this.endH,   required this.endM,
    this.isBreak = false,
    this.subject, this.teacher, this.room,
    this.color = const Color(0xFFE6B800),
    this.icon  = Icons.circle_outlined,
  });

  int get _startMin => startH * 60 + startM;
  int get _endMin   => endH   * 60 + endM;

  bool active(int h, int m) {
    final now = h * 60 + m;
    return now >= _startMin && now < _endMin;
  }

  double progress(int h, int m) =>
      ((h * 60 + m - _startMin) / (_endMin - _startMin)).clamp(0.0, 1.0);

  int minsLeft(int h, int m) => (_endMin - (h * 60 + m)).clamp(0, 9999);

  String get startStr =>
      '${startH.toString().padLeft(2, '0')}:${startM.toString().padLeft(2, '0')}';
  String get endStr =>
      '${endH.toString().padLeft(2, '0')}:${endM.toString().padLeft(2, '0')}';

  String get noteKey => '${startStr}_${subject ?? 'break'}';
}

class _TeacherInfo {
  final String name, subject, room, email;
  const _TeacherInfo({
    required this.name, required this.subject,
    required this.room, required this.email,
  });
  String get initials => name
      .split(' ')
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0])
      .join()
      .toUpperCase();
}

class _GradeEntry {
  final String date, topic;
  final int value;
  const _GradeEntry({required this.date, required this.topic, required this.value});
}

// ─── Notes ChangeNotifier ─────────────────────────────────────────────────────

class _NotesModel extends ChangeNotifier {
  final Map<String, String> _notes = {};
  String? getNote(String key) => _notes[key];
  bool hasNote(String key) => (_notes[key]?.isNotEmpty) ?? false;
  void saveNote(String key, String note) {
    if (note.trim().isEmpty) {
      _notes.remove(key);
    } else {
      _notes[key] = note.trim();
    }
    notifyListeners();
  }
}

// ─── Mock schedule ────────────────────────────────────────────────────────────

const _kSchedule = <_Slot>[
  _Slot(startH:  8, startM:  0, endH:  8, endM: 45,
        subject: 'Mathematik',  teacher: 'Fr. Müller',  room: '212',
        color: Color(0xFF5B8DEF), icon: Icons.calculate_rounded),
  _Slot(startH:  8, startM: 45, endH:  8, endM: 55, isBreak: true,
        icon: Icons.free_breakfast_rounded, color: Color(0xFF9E9E9E)),
  _Slot(startH:  8, startM: 55, endH:  9, endM: 40,
        subject: 'Deutsch',     teacher: 'Hr. Schmidt', room: '107',
        color: Color(0xFFFF7043), icon: Icons.menu_book_rounded),
  _Slot(startH:  9, startM: 40, endH:  9, endM: 55, isBreak: true,
        icon: Icons.free_breakfast_rounded, color: Color(0xFF9E9E9E)),
  _Slot(startH:  9, startM: 55, endH: 10, endM: 40,
        subject: 'Englisch',    teacher: 'Fr. Weber',   room: '114',
        color: Color(0xFF26A69A), icon: Icons.language_rounded),
  _Slot(startH: 10, startM: 40, endH: 11, endM: 30,
        subject: 'Geschichte',  teacher: 'Hr. Braun',   room: '305',
        color: Color(0xFFEC407A), icon: Icons.history_edu_rounded),
  _Slot(startH: 11, startM: 30, endH: 11, endM: 45, isBreak: true,
        icon: Icons.restaurant_rounded, color: Color(0xFF9E9E9E)),
  _Slot(startH: 11, startM: 45, endH: 12, endM: 30,
        subject: 'Biologie',    teacher: 'Fr. Keller',  room: '118',
        color: Color(0xFF66BB6A), icon: Icons.science_rounded),
  _Slot(startH: 12, startM: 30, endH: 13, endM: 15,
        subject: 'Physik',      teacher: 'Hr. Richter', room: '220',
        color: Color(0xFF7C4DFF), icon: Icons.bolt_rounded),
  _Slot(startH: 13, startM: 15, endH: 14, endM:  0,
        subject: 'Chemie',      teacher: 'Fr. Lange',   room: '119',
        color: Color(0xFFE6B800), icon: Icons.biotech_rounded),
];

// ─── Mock teachers ────────────────────────────────────────────────────────────

const _kTeachers = <_TeacherInfo>[
  _TeacherInfo(name: 'Anna Müller',   subject: 'Mathematik', room: '212', email: 'a.mueller@schule.de'),
  _TeacherInfo(name: 'Klaus Schmidt', subject: 'Deutsch',    room: '107', email: 'k.schmidt@schule.de'),
  _TeacherInfo(name: 'Lisa Weber',    subject: 'Englisch',   room: '114', email: 'l.weber@schule.de'),
  _TeacherInfo(name: 'Max Braun',     subject: 'Geschichte', room: '305', email: 'm.braun@schule.de'),
  _TeacherInfo(name: 'Eva Keller',    subject: 'Biologie',   room: '118', email: 'e.keller@schule.de'),
  _TeacherInfo(name: 'Peter Richter', subject: 'Physik',     room: '220', email: 'p.richter@schule.de'),
  _TeacherInfo(name: 'Jana Lange',    subject: 'Chemie',     room: '119', email: 'j.lange@schule.de'),
];

// ─── Mock grade history ───────────────────────────────────────────────────────

const _kGradeHistory = <String, List<_GradeEntry>>{
  'Mathematik': [
    _GradeEntry(date: '12.03.25', topic: 'Lineare Gleichungen',      value: 2),
    _GradeEntry(date: '28.02.25', topic: 'Quadratische Funktionen',  value: 2),
    _GradeEntry(date: '14.02.25', topic: 'Mündliche Note',           value: 1),
    _GradeEntry(date: '31.01.25', topic: 'Klassenarbeit',            value: 3),
  ],
  'Deutsch': [
    _GradeEntry(date: '11.03.25', topic: 'Aufsatz: Erörterung',      value: 3),
    _GradeEntry(date: '25.02.25', topic: 'Diktat',                   value: 3),
    _GradeEntry(date: '10.02.25', topic: 'Referat Sturm und Drang',  value: 2),
  ],
  'Englisch': [
    _GradeEntry(date: '10.03.25', topic: 'Vocabulary Test',          value: 1),
    _GradeEntry(date: '24.02.25', topic: 'Speaking Assessment',      value: 2),
    _GradeEntry(date: '07.02.25', topic: 'Grammar Test',             value: 1),
  ],
  'Biologie': [
    _GradeEntry(date: '06.03.25', topic: 'Photosynthese',            value: 2),
    _GradeEntry(date: '20.02.25', topic: 'Zellbiologie',             value: 2),
  ],
  'Geschichte': [
    _GradeEntry(date: '05.03.25', topic: 'Weimarer Republik',        value: 3),
    _GradeEntry(date: '19.02.25', topic: 'Mündliche Note',           value: 4),
    _GradeEntry(date: '04.02.25', topic: 'Klassenarbeit WW2',        value: 3),
  ],
  'Physik': [
    _GradeEntry(date: '04.03.25', topic: 'Elektrische Stromkreise',  value: 2),
    _GradeEntry(date: '18.02.25', topic: 'Optik',                    value: 3),
  ],
};

// ─── Schedule view mode ───────────────────────────────────────────────────────

enum _SchedView { today, week }

// ─── Main screen ──────────────────────────────────────────────────────────────

class SchoolScreen extends StatelessWidget {
  const SchoolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: KnotyAppBar(title: l10n.schoolTitle),
      body: auth.isRestoringSession
          ? const _LoadingState()
          : user == null
              ? const _NotVerifiedState()
              : user.role == UserRole.parent
                  ? _ParentSchoolView(user: user)
                  : user.role == UserRole.teacher
                      ? _TeacherSchoolView(user: user)
                      : _SchoolDashboard(user: user),
    );
  }
}

// ─── Loading skeleton ─────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(height: 80,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
        const SizedBox(height: 12),
        Container(height: 120,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
        const SizedBox(height: 12),
        Row(children: [
          for (int i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: Container(height: 56,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)))),
          ],
        ]),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.5,
          children: List.generate(6, (_) => Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))))),
      ]),
    );
  }
}

// ─── Not verified state ───────────────────────────────────────────────────────

class _NotVerifiedState extends StatelessWidget {
  const _NotVerifiedState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.school_rounded, color: Color(0xFFE6B800), size: 36)),
          const SizedBox(height: 20),
          Text(l10n.schoolNotVerifiedTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 8),
          Text(l10n.schoolNotVerifiedSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF9E9E9E), height: 1.5)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(14)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.tag_rounded, size: 16, color: Color(0xFFE6B800)),
              const SizedBox(width: 8),
              Text(l10n.schoolCodeHint,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFE6B800))),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Verified dashboard ───────────────────────────────────────────────────────

class _SchoolDashboard extends StatelessWidget {
  final User? user;
  const _SchoolDashboard({this.user});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ChangeNotifierProvider(
      create: (_) => _NotesModel(),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _CompactHeader(user: user),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _LiveStatusCard(),
          ),
          const SizedBox(height: 14),
          _ScheduleSection(),
          const SizedBox(height: 16),
          _SectionHeader(title: l10n.schoolServicesTitle, icon: Icons.grid_view_rounded),
          const SizedBox(height: 10),
          _BentoGrid(),
          const SizedBox(height: 10),
          _TeachersCard(),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

// ─── Compact header with QR button ───────────────────────────────────────────

class _CompactHeader extends StatelessWidget {
  final User? user;
  const _CompactHeader({this.user});

  void _showQr(BuildContext context) {
    final l10n  = AppLocalizations.of(context)!;
    final knNum = user?.knotyNumber ?? '';
    final knId  = knNum.isNotEmpty ? 'KN-$knNum' : '—';
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QrSheet(knId: knId, l10n: l10n),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n      = AppLocalizations.of(context)!;
    final schoolName = user?.school ?? l10n.schoolTitle;
    final className  = user?.schoolClass;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFE6B800), Color(0xFFFFD84D)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
            color: const Color(0xFFE6B800).withOpacity(0.30),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(
              child: Text(schoolName,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(l10n.schoolVerifiedBadge,
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white))),
          ]),
          const SizedBox(height: 4),
          if (className != null)
            Text('${l10n.schoolStatClass}: $className',
                style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85))),
        ])),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => _showQr(context),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.20),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 24)),
        ),
      ]),
    );
  }
}

// ─── Live status card ─────────────────────────────────────────────────────────

_Slot? _currentSlot() {
  final now = DateTime.now();
  for (final s in _kSchedule) {
    if (s.active(now.hour, now.minute)) return s;
  }
  return null;
}

_Slot? _nextLesson() {
  final now    = DateTime.now();
  final nowMin = now.hour * 60 + now.minute;
  for (final s in _kSchedule) {
    if (!s.isBreak && s._startMin > nowMin) return s;
  }
  return null;
}

class _LiveStatusCard extends StatefulWidget {
  @override
  State<_LiveStatusCard> createState() => _LiveStatusCardState();
}

class _LiveStatusCardState extends State<_LiveStatusCard> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n      = AppLocalizations.of(context)!;
    final current   = _currentSlot();
    final next      = _nextLesson();
    final isWeekend = _now.weekday >= 6;
    final schoolStart = 8 * 60;
    final schoolEnd   = 14 * 60;
    final nowMin    = _now.hour * 60 + _now.minute;
    final beforeSchool = nowMin < schoolStart;
    final afterSchool  = nowMin >= schoolEnd;

    if (isWeekend || (beforeSchool && next == null) || afterSchool) {
      return _LiveAfterHours(
          next: next,
          label: isWeekend ? l10n.schoolNoSchedule : l10n.schoolAfterHours);
    }

    if (current == null) {
      return _LiveNextOnly(next: next, l10n: l10n);
    }

    if (current.isBreak) {
      return _LiveBreak(slot: current, next: next, now: _now, l10n: l10n);
    }

    return _LiveLesson(slot: current, next: next, now: _now, l10n: l10n);
  }
}

class _LiveLesson extends StatelessWidget {
  final _Slot slot;
  final _Slot? next;
  final DateTime now;
  final AppLocalizations l10n;

  const _LiveLesson(
      {required this.slot, required this.next, required this.now, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final prog = slot.progress(now.hour, now.minute);
    final mins = slot.minsLeft(now.hour, now.minute);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12, offset: const Offset(0, 4))],
        border: Border(left: BorderSide(color: slot.color, width: 4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: slot.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(slot.icon, color: slot.color, size: 20)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.schoolNow.toUpperCase(),
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: slot.color, letterSpacing: 1.0)),
            Text(slot.subject ?? '',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700,
                    color: cs.onSurface)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: slot.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20)),
            child: Text('$mins ${l10n.schoolMinLeft}',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: slot.color)),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _MetaChip(icon: Icons.person_outline_rounded, label: slot.teacher ?? ''),
          const SizedBox(width: 8),
          _MetaChip(icon: Icons.room_outlined,
              label: '${l10n.schoolRoom} ${slot.room ?? ''}'),
          const Spacer(),
          Text('${slot.startStr} – ${slot.endStr}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: prog, minHeight: 5,
            backgroundColor: slot.color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation(slot.color),
          ),
        ),
        if (next != null) ...[
          const SizedBox(height: 12),
          _NextLessonChip(next: next!, l10n: l10n),
        ],
      ]),
    );
  }
}

class _LiveBreak extends StatelessWidget {
  final _Slot slot;
  final _Slot? next;
  final DateTime now;
  final AppLocalizations l10n;

  const _LiveBreak(
      {required this.slot, this.next, required this.now, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mins = slot.minsLeft(now.hour, now.minute);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12, offset: const Offset(0, 4))],
        border: Border(left: BorderSide(
            color: const Color(0xFF9E9E9E).withOpacity(0.5), width: 4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10)),
            child: Icon(slot.icon, color: const Color(0xFF9E9E9E), size: 20)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.schoolBreak.toUpperCase(),
                style: const TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: Color(0xFF9E9E9E), letterSpacing: 1.0)),
            Text(slot.subject ?? l10n.schoolBreak,
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700,
                    color: cs.onSurface)),
          ])),
          Text('$mins ${l10n.schoolMinLeft}',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: Color(0xFF9E9E9E))),
        ]),
        if (next != null) ...[
          const SizedBox(height: 12),
          _NextLessonChip(next: next!, l10n: l10n),
        ],
      ]),
    );
  }
}

class _LiveNextOnly extends StatelessWidget {
  final _Slot? next;
  final AppLocalizations l10n;
  const _LiveNextOnly({this.next, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12, offset: const Offset(0, 4))]),
      child: next == null
          ? Text(l10n.schoolAfterHours,
              style: const TextStyle(fontSize: 16, color: Color(0xFF9E9E9E)))
          : _NextLessonChip(next: next!, l10n: l10n, expanded: true),
    );
  }
}

class _LiveAfterHours extends StatelessWidget {
  final _Slot? next;
  final String label;
  const _LiveAfterHours({this.next, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12, offset: const Offset(0, 4))]),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.nights_stay_rounded,
              color: Color(0xFF9E9E9E), size: 20)),
        const SizedBox(width: 12),
        Text(label,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600,
                color: Color(0xFF9E9E9E))),
      ]),
    );
  }
}

class _NextLessonChip extends StatelessWidget {
  final _Slot next;
  final AppLocalizations l10n;
  final bool expanded;
  const _NextLessonChip(
      {required this.next, required this.l10n, this.expanded = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(next.icon, size: 14, color: next.color),
        const SizedBox(width: 8),
        if (expanded) ...[
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.schoolNextLesson,
                style: const TextStyle(
                    fontSize: 10, color: Color(0xFF9E9E9E),
                    fontWeight: FontWeight.w600)),
            Text(next.subject ?? '',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: cs.onSurface)),
          ])),
          Text('${next.startStr}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
        ] else ...[
          Text(l10n.schoolNextLesson,
              style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
          const SizedBox(width: 6),
          Expanded(child: Text(next.subject ?? '',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: cs.onSurface),
              overflow: TextOverflow.ellipsis)),
          Text(next.startStr,
              style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
        ],
      ]),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: const Color(0xFF9E9E9E)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
    ]);
  }
}

// ─── Schedule section (Today / Week toggle) ───────────────────────────────────

class _ScheduleSection extends StatefulWidget {
  @override
  State<_ScheduleSection> createState() => _ScheduleSectionState();
}

class _ScheduleSectionState extends State<_ScheduleSection> {
  _SchedView _view = _SchedView.today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Icon(Icons.today_rounded, size: 15, color: const Color(0xFFBDBDBD)),
          const SizedBox(width: 6),
          Text(l10n.schoolScheduleToday.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: Color(0xFFBDBDBD), letterSpacing: 0.8)),
          const Spacer(),
          _ViewToggle(
            value: _view,
            todayLabel: l10n.schoolScheduleToday,
            weekLabel:  l10n.schoolWeekView,
            onChanged:  (v) => setState(() => _view = v),
          ),
        ]),
      ),
      const SizedBox(height: 8),
      if (_view == _SchedView.today)
        _TodayScheduleRow()
      else
        _WeekScheduleView(),
    ]);
  }
}

class _ViewToggle extends StatelessWidget {
  final _SchedView value;
  final String todayLabel, weekLabel;
  final void Function(_SchedView) onChanged;

  const _ViewToggle({
    required this.value,
    required this.todayLabel,
    required this.weekLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 28,
      decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _Tab(
            label: todayLabel,
            active: value == _SchedView.today,
            onTap: () => onChanged(_SchedView.today)),
        _Tab(
            label: weekLabel,
            active: value == _SchedView.week,
            onTap: () => onChanged(_SchedView.week)),
      ]),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: active ? cs.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active
              ? [BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: active
                      ? cs.onSurface
                      : const Color(0xFF9E9E9E))),
        ),
      ),
    );
  }
}

// ─── Today schedule row ───────────────────────────────────────────────────────

class _TodayScheduleRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now      = DateTime.now();
    final lessons  = _kSchedule.where((s) => !s.isBreak).toList();
    final nowMin   = now.hour * 60 + now.minute;
    final isWeekend = now.weekday >= 6;

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: lessons.length,
        itemBuilder: (ctx, i) {
          final slot   = lessons[i];
          final isDone = slot._endMin <= nowMin;
          final isNow  = slot.active(now.hour, now.minute);
          return _ScheduleTile(
              slot: slot,
              isNow: isNow,
              isDone: isDone || isWeekend);
        },
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  final _Slot slot;
  final bool isNow, isDone;
  const _ScheduleTile(
      {required this.slot, required this.isNow, required this.isDone});

  void _openNote(BuildContext context) {
    final l10n  = AppLocalizations.of(context)!;
    final notes = Provider.of<_NotesModel>(context, listen: false);
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: notes,
        child: _NoteSheet(slot: slot, l10n: l10n),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final notes  = context.watch<_NotesModel>();
    final hasNote = notes.hasNote(slot.noteKey);
    final accent = isNow
        ? slot.color
        : (isDone ? const Color(0xFFE0E0E0) : slot.color.withOpacity(0.6));

    return GestureDetector(
      onLongPress: () => _openNote(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isNow ? 110 : 90,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isNow ? slot.color.withOpacity(0.10) : cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isNow ? slot.color : Colors.transparent, width: 1.5),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Stack(children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(slot.icon, size: 12, color: accent),
                const SizedBox(width: 4),
                Text(slot.startStr,
                    style: TextStyle(
                        fontSize: 10, color: accent,
                        fontWeight: FontWeight.w600)),
              ]),
              Text(slot.subject ?? '',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: isDone
                          ? const Color(0xFFBDBDBD)
                          : cs.onSurface),
                  overflow: TextOverflow.ellipsis, maxLines: 2),
            ],
          ),
          if (hasNote)
            Positioned(
              top: 0, right: 0,
              child: Container(
                width: 7, height: 7,
                decoration: BoxDecoration(
                    color: slot.color, shape: BoxShape.circle),
              ),
            ),
        ]),
      ),
    );
  }
}

// ─── Week schedule view ───────────────────────────────────────────────────────

class _WeekScheduleView extends StatefulWidget {
  final double horizontalPadding;
  const _WeekScheduleView({this.horizontalPadding = 16});

  @override
  State<_WeekScheduleView> createState() => _WeekScheduleViewState();
}

class _WeekScheduleViewState extends State<_WeekScheduleView> {
  late int _expandedIndex;

  @override
  void initState() {
    super.initState();
    final wd = DateTime.now().weekday;
    _expandedIndex = (wd >= 1 && wd <= 5) ? wd - 1 : 0;
  }

  @override
  Widget build(BuildContext context) {
    final today  = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final lessons = _kSchedule.where((s) => !s.isBreak).toList();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (i) {
          final day     = monday.add(Duration(days: i));
          final isToday = day.day   == today.day &&
                          day.month == today.month &&
                          day.year  == today.year;
          final expanded = _expandedIndex == i;

          return _WeekDayRow(
            day:      day,
            isToday:  isToday,
            expanded: expanded,
            lessons:  lessons,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _expandedIndex = expanded ? -1 : i);
            },
          );
        }),
      ),
    );
  }
}

class _WeekDayRow extends StatelessWidget {
  final DateTime day;
  final bool isToday, expanded;
  final List<_Slot> lessons;
  final VoidCallback onTap;

  const _WeekDayRow({
    required this.day, required this.isToday, required this.expanded,
    required this.lessons, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final locale  = Localizations.localeOf(context).toString();
    final dayName = DateFormat.E(locale).format(day);
    final dateStr = DateFormat.d(locale).format(day);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: isToday ? const Color(0xFFFFF8E1) : cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: isToday
              ? Border.all(color: const Color(0xFFE6B800), width: 1.5)
              : Border.all(color: Colors.transparent),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Day header row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: isToday
                      ? const Color(0xFFE6B800)
                      : cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(dayName.toUpperCase(),
                      style: TextStyle(
                          fontSize: 8, fontWeight: FontWeight.w700,
                          color: isToday ? Colors.white : const Color(0xFF9E9E9E)),
                      overflow: TextOverflow.clip),
                  Text(dateStr,
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800,
                          color: isToday ? Colors.white : cs.onSurface)),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(child: Wrap(
                spacing: 4, runSpacing: 4,
                children: lessons.take(4).map((s) =>
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                          color: s.color.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(s.subject ?? '',
                          style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w600,
                              color: s.color)),
                    )).toList(),
              )),
              AnimatedRotation(
                duration: const Duration(milliseconds: 200),
                turns: expanded ? -0.5 : 0,
                child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18, color: Color(0xFFBDBDBD)),
              ),
            ]),
          ),
          // Expanded lesson list.
          // ClipRect + AnimatedAlign(heightFactor) is the standard overflow-free
          // Flutter pattern: the child renders at its natural height, the clip
          // handles the visual slide without triggering RenderFlex overflow.
          ClipRect(
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              heightFactor: expanded ? 1.0 : 0.0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: Column(mainAxisSize: MainAxisSize.min, children: lessons.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    Icon(s.icon, size: 13, color: s.color),
                    const SizedBox(width: 8),
                    Text('${s.startStr}–${s.endStr}',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9E9E9E))),
                    const SizedBox(width: 8),
                    Expanded(child: Text(s.subject ?? '',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: cs.onSurface))),
                    Text(s.room ?? '',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9E9E9E))),
                  ]),
                )).toList()),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Bento grid ───────────────────────────────────────────────────────────────

class _BentoGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final tiles = [
      _TileData(
        icon: Icons.assignment_rounded,
        color: const Color(0xFF26A69A), bg: const Color(0xFFE0F5F4),
        title: l10n.schoolHomework,
        subtitle: l10n.schoolHomeworkOpen(3), badge: '3',
        content: const _HomeworkSheet(),
      ),
      _TileData(
        icon: Icons.campaign_rounded,
        color: const Color(0xFFFF7043), bg: const Color(0xFFFFF3F0),
        title: l10n.schoolAnnouncements,
        subtitle: l10n.schoolAnnouncementsNew(2), badge: '2',
        content: const _AnnouncementsSheet(),
      ),
      _TileData(
        icon: Icons.grade_rounded,
        color: const Color(0xFF7C4DFF), bg: const Color(0xFFF3EEFF),
        title: l10n.schoolGrades, subtitle: 'Ø 2.3',
        content: const _GradesSheet(),
      ),
      _TileData(
        icon: Icons.folder_rounded,
        color: const Color(0xFFE6B800), bg: const Color(0xFFFFFBE6),
        title: l10n.schoolDocuments,
        subtitle: l10n.schoolDocumentsCount(5),
        content: const _DocumentsSheet(),
      ),
      _TileData(
        icon: Icons.groups_rounded,
        color: const Color(0xFF5B8DEF), bg: const Color(0xFFEEF3FF),
        title: l10n.schoolClubs,
        subtitle: l10n.schoolClubsActive(2),
        content: const _ClubsSheet(),
      ),
      _TileData(
        icon: Icons.restaurant_rounded,
        color: const Color(0xFFEC407A), bg: const Color(0xFFFCEEF4),
        title: l10n.schoolCafeteria,
        subtitle: l10n.schoolCafeteriaMenuToday,
        content: const _CafeteriaSheet(),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        Row(children: [
          Expanded(child: _BentoTile(data: tiles[0])),
          const SizedBox(width: 10),
          Expanded(child: _BentoTile(data: tiles[1])),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _BentoTile(data: tiles[2])),
          const SizedBox(width: 10),
          Expanded(child: _BentoTile(data: tiles[3])),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _BentoTile(data: tiles[4])),
          const SizedBox(width: 10),
          Expanded(child: _BentoTile(data: tiles[5])),
        ]),
      ]),
    );
  }
}

class _TileData {
  final IconData icon;
  final Color color, bg;
  final String title, subtitle;
  final String? badge;
  final Widget content;

  const _TileData({
    required this.icon, required this.color, required this.bg,
    required this.title, required this.subtitle,
    this.badge, required this.content,
  });
}

class _BentoTile extends StatefulWidget {
  final _TileData data;
  const _BentoTile({required this.data});

  @override
  State<_BentoTile> createState() => _BentoTileState();
}

class _BentoTileState extends State<_BentoTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween(begin: 1.0, end: 0.94).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _openSheet() {
    final cs = Theme.of(context).colorScheme;
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.60,
        minChildSize: 0.40,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, ctrl) => Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Container(width: 40, height: 40,
                    decoration: BoxDecoration(
                        color: widget.data.bg,
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(widget.data.icon,
                        color: widget.data.color, size: 22)),
                const SizedBox(width: 12),
                Text(widget.data.title,
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700,
                        color: cs.onSurface)),
              ]),
            ),
            const SizedBox(height: 12),
            Expanded(child: SingleChildScrollView(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: widget.data.content,
            )),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTapDown:   (_) => _ctrl.forward(),
      onTapUp:     (_) { _ctrl.reverse(); _openSheet(); },
      onTapCancel: ()  => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Stack(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 42, height: 42,
                  decoration: BoxDecoration(
                      color: widget.data.bg,
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(widget.data.icon,
                      color: widget.data.color, size: 22)),
              const SizedBox(height: 10),
              Text(widget.data.title,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: cs.onSurface),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(widget.data.subtitle,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
            ]),
            if (widget.data.badge != null)
              Positioned(top: 0, right: 0,
                  child: Container(
                    width: 20, height: 20,
                    decoration: const BoxDecoration(
                        color: Color(0xFFFF3B30), shape: BoxShape.circle),
                    child: Center(child: Text(widget.data.badge!,
                        style: const TextStyle(
                            fontSize: 10, color: Colors.white,
                            fontWeight: FontWeight.w700))))),
          ]),
        ),
      ),
    );
  }
}

// ─── Teachers full-width card ─────────────────────────────────────────────────

class _TeachersCard extends StatelessWidget {
  void _openSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.40,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, ctrl) => Container(
          decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Container(width: 40, height: 40,
                    decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.people_rounded,
                        color: Color(0xFF43A047), size: 22)),
                const SizedBox(width: 12),
                Text(l10n.schoolTeachersTitle,
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700,
                        color: cs.onSurface)),
              ]),
            ),
            const SizedBox(height: 12),
            Expanded(child: _TeachersSheet(scrollCtrl: ctrl, l10n: l10n)),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => _openSheet(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(width: 42, height: 42,
              decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.people_rounded,
                  color: Color(0xFF43A047), size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.schoolTeachersTitle,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: cs.onSurface)),
            Text('${_kTeachers.length} ${l10n.schoolTeacherLabel.toLowerCase()}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
          ])),
          // Avatar stack
          SizedBox(
            width: 80, height: 32,
            child: Stack(children: [
              for (int i = 0; i < _kTeachers.length.clamp(0, 4); i++)
                Positioned(
                  left: i * 18.0,
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: [
                        const Color(0xFF5B8DEF),
                        const Color(0xFF26A69A),
                        const Color(0xFFFF7043),
                        const Color(0xFF7C4DFF),
                      ][i % 4],
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.surface, width: 2),
                    ),
                    child: Center(child: Text(_kTeachers[i].initials,
                        style: const TextStyle(
                            fontSize: 9, fontWeight: FontWeight.w700,
                            color: Colors.white))),
                  ),
                ),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded,
              size: 18, color: Color(0xFFBDBDBD)),
        ]),
      ),
    );
  }
}

// ─── Sheet: Homework ──────────────────────────────────────────────────────────

class _HomeworkSheet extends StatelessWidget {
  const _HomeworkSheet();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Mathematik', 'Seite 84, Aufgaben 1–5',          'Morgen',    false),
      ('Deutsch',    'Aufsatz schreiben – 300 Wörter',  'Fr, 20.03', false),
      ('Englisch',   'Vokabeln Lektion 7 lernen',        'Mo, 24.03', false),
      ('Biologie',   'Referat Photosynthese',             'Di, 25.03', true),
    ];
    return Column(children: [
      ...items.map((e) => _SheetItem(
          title: e.$1, subtitle: e.$2, trailing: e.$3, done: e.$4,
          color: const Color(0xFF26A69A))),
      const SizedBox(height: 16),
    ]);
  }
}

// ─── Sheet: Announcements ─────────────────────────────────────────────────────

class _AnnouncementsSheet extends StatelessWidget {
  const _AnnouncementsSheet();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Elternsprechtag',         'Mo, 24.03 · 14:00–18:00 · Aula'),
      ('Klassenfahrt Anmeldung',  'Bitte bis 30.03 anmelden. Kosten: 120 €'),
      ('Schulkonzert',            'Fr, 28.03 · 18:00 Uhr · Aula'),
      ('Prüfungsplan Mai',        'Der neue Prüfungsplan wurde veröffentlicht.'),
    ];
    return Column(children: [
      ...items.map((e) => _SheetItem(
          title: e.$1, subtitle: e.$2,
          color: const Color(0xFFFF7043))),
      const SizedBox(height: 16),
    ]);
  }
}

// ─── Sheet: Grades (with expandable detail) ───────────────────────────────────

class _GradesSheet extends StatefulWidget {
  const _GradesSheet();

  @override
  State<_GradesSheet> createState() => _GradesSheetState();
}

class _GradesSheetState extends State<_GradesSheet> {
  final Set<String> _expanded = {};

  static const _subjects = [
    ('Mathematik', '2', '2.1'),
    ('Deutsch',    '3', '2.8'),
    ('Englisch',   '1', '1.5'),
    ('Biologie',   '2', '2.0'),
    ('Geschichte', '3', '3.2'),
    ('Physik',     '2', '2.5'),
  ];

  static const _gradeColors = {
    1: Color(0xFF43A047),
    2: Color(0xFF7CB342),
    3: Color(0xFFFFB300),
    4: Color(0xFFFF7043),
    5: Color(0xFFE53935),
    6: Color(0xFF8E24AA),
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Column(children: [
      // Average badge
      Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
            color: const Color(0xFFF3EEFF),
            borderRadius: BorderRadius.circular(16)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Ø ${l10n.schoolAvgLabel}  ',
              style: const TextStyle(fontSize: 16, color: Color(0xFF9E9E9E))),
          const Text('2.3',
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w800,
                  color: Color(0xFF7C4DFF))),
        ]),
      ),

      // Subject rows
      ..._subjects.map((e) {
        final subject  = e.$1;
        final last     = int.tryParse(e.$2) ?? 2;
        final avg      = e.$3;
        final isExp    = _expanded.contains(subject);
        final history  = _kGradeHistory[subject] ?? const [];
        final gradeClr = _gradeColors[last] ?? const Color(0xFF7C4DFF);

        return GestureDetector(
          onTap: () {
            if (history.isEmpty) return;
            HapticFeedback.selectionClick();
            setState(() {
              if (isExp) _expanded.remove(subject);
              else       _expanded.add(subject);
            });
          },
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                  color: cs.surface, borderRadius: BorderRadius.circular(14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Subject row
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(children: [
                    Expanded(child: Text(subject,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600))),
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                          color: gradeClr.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8)),
                      child: Center(child: Text(e.$2,
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w800,
                              color: gradeClr)))),
                    const SizedBox(width: 10),
                    Text('Ø $avg',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF9E9E9E))),
                    if (history.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Icon(
                        isExp
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 18, color: const Color(0xFFBDBDBD)),
                    ],
                  ]),
                ),
                // Expanded grade history
                if (isExp)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                    child: Column(children: history.map((g) {
                      final gc = _gradeColors[g.value] ?? const Color(0xFF7C4DFF);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(children: [
                          Container(
                            width: 26, height: 26,
                            decoration: BoxDecoration(
                                color: gc.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6)),
                            child: Center(child: Text('${g.value}',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w800,
                                    color: gc)))),
                          const SizedBox(width: 10),
                          Expanded(child: Text(g.topic,
                              style: TextStyle(
                                  fontSize: 12, color: cs.onSurface))),
                          Text(g.date,
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF9E9E9E))),
                        ]),
                      );
                    }).toList()),
                  ),
              ]),
            ),
          ),
        );
      }),
      const SizedBox(height: 16),
    ]);
  }
}

// ─── Sheet: Documents ────────────────────────────────────────────────────────

class _DocumentsSheet extends StatelessWidget {
  const _DocumentsSheet();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const items = [
      ('Stundenplan 2024-25.pdf',   '1.2 MB', Icons.picture_as_pdf_rounded),
      ('Hausordnung.pdf',           '340 KB', Icons.picture_as_pdf_rounded),
      ('Lehrplan Mathematik.docx',  '520 KB', Icons.description_rounded),
      ('Klassenfahrt Info.pdf',     '890 KB', Icons.picture_as_pdf_rounded),
      ('Prüfungsplan Mai.xlsx',     '210 KB', Icons.table_chart_rounded),
    ];
    return Column(children: [
      ...items.map((e) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
              color: cs.surface, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Icon(e.$3, color: const Color(0xFFE6B800), size: 22),
            const SizedBox(width: 12),
            Expanded(child: Text(e.$1,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
            Text(e.$2,
                style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
            const SizedBox(width: 8),
            const Icon(Icons.download_rounded,
                size: 18, color: Color(0xFFE6B800)),
          ]))),
      const SizedBox(height: 16),
    ]);
  }
}

// ─── Sheet: Clubs ─────────────────────────────────────────────────────────────

class _ClubsSheet extends StatelessWidget {
  const _ClubsSheet();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const clubs = [
      ('Theater AG', 'Mi 14:00–16:00 · Aula',             Icons.theater_comedy_rounded),
      ('Schach AG',  'Do 13:30–15:00 · R. 115',           Icons.casino_rounded),
      ('Fußball AG', 'Di & Do 15:00–17:00 · Sportplatz',  Icons.sports_soccer_rounded),
      ('Chor',       'Mo 14:30–16:00 · Musikraum',        Icons.music_note_rounded),
    ];
    return Column(children: [
      ...clubs.map((e) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: cs.surface, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Container(width: 38, height: 38,
                decoration: BoxDecoration(
                    color: const Color(0xFFEEF3FF),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(e.$3, color: const Color(0xFF5B8DEF), size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.$1,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              Text(e.$2,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF9E9E9E))),
            ])),
          ]))),
      const SizedBox(height: 16),
    ]);
  }
}

// ─── Sheet: Cafeteria ────────────────────────────────────────────────────────

class _CafeteriaSheet extends StatelessWidget {
  const _CafeteriaSheet();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    const menu = [
      ('Menü 1', 'Schnitzel mit Pommes & Salat',  '4.50 €', '🥩'),
      ('Menü 2', 'Gemüse-Curry mit Basmatireis',   '3.80 €', '🍛'),
      ('Menü 3', 'Spaghetti Bolognese',            '3.50 €', '🍝'),
      ('Dessert', 'Apfelkuchen mit Sahne',          '1.20 €', '🍰'),
    ];
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
            color: const Color(0xFFFCEEF4),
            borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          const Icon(Icons.access_time_rounded,
              size: 16, color: Color(0xFFEC407A)),
          const SizedBox(width: 8),
          Text(l10n.schoolOpenHoursLabel,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500,
                  color: Color(0xFFEC407A))),
        ]),
      ),
      ...menu.map((e) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: cs.surface, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Text(e.$4,
                style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.$1,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF9E9E9E))),
              Text(e.$2,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ])),
            Text(e.$3,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: Color(0xFFEC407A))),
          ]))),
      const SizedBox(height: 16),
    ]);
  }
}

// ─── Sheet: Teachers ─────────────────────────────────────────────────────────

class _TeachersSheet extends StatelessWidget {
  final ScrollController scrollCtrl;
  final AppLocalizations l10n;
  const _TeachersSheet({required this.scrollCtrl, required this.l10n});

  static const _colors = [
    Color(0xFF5B8DEF), Color(0xFF26A69A), Color(0xFFFF7043),
    Color(0xFF7C4DFF), Color(0xFF66BB6A), Color(0xFFE6B800),
    Color(0xFFEC407A),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView.builder(
      controller: scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _kTeachers.length,
      itemBuilder: (_, i) {
        final t   = _kTeachers[i];
        final clr = _colors[i % _colors.length];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: cs.surface, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: clr.withOpacity(0.15), shape: BoxShape.circle),
              child: Center(child: Text(t.initials,
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800, color: clr)))),
            const SizedBox(width: 12),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.name,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: cs.onSurface)),
              Text(t.subject,
                  style: TextStyle(
                      fontSize: 12, color: clr, fontWeight: FontWeight.w600)),
              Text('${l10n.schoolRoom} ${t.room}',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF9E9E9E))),
            ])),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(t.email),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: clr.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.mail_outline_rounded, size: 14, color: clr),
                  const SizedBox(width: 4),
                  Text(l10n.schoolTeacherContact,
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600, color: clr)),
                ])),
            ),
          ]),
        );
      },
    );
  }
}

// ─── Sheet: QR Code ───────────────────────────────────────────────────────────

class _QrSheet extends StatelessWidget {
  final String knId;
  final AppLocalizations l10n;
  const _QrSheet({required this.knId, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Text(l10n.schoolQrTitle,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700,
                color: cs.onSurface)),
        const SizedBox(height: 8),
        Text(l10n.schoolQrHint,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBE6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE6B800).withOpacity(0.3)),
          ),
          child: QrImageView(
            data: knId,
            version: QrVersions.auto,
            size: 200,
            backgroundColor: const Color(0xFFFFFBE6),
            eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF1A1A1A)),
            dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF1A1A1A)),
          ),
        ),
        const SizedBox(height: 16),
        Text(knId,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800,
                color: cs.onSurface, letterSpacing: 1.5)),
        const SizedBox(height: 4),
      ]),
    );
  }
}

// ─── Sheet: Note ──────────────────────────────────────────────────────────────

class _NoteSheet extends StatefulWidget {
  final _Slot slot;
  final AppLocalizations l10n;
  const _NoteSheet({required this.slot, required this.l10n});

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    final existing = Provider.of<_NotesModel>(context, listen: false)
        .getNote(widget.slot.noteKey);
    _ctrl = TextEditingController(text: existing ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n  = widget.l10n;
    final notes = Provider.of<_NotesModel>(context, listen: false);
    final color = widget.slot.color;

    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Row(children: [
            Container(width: 36, height: 36,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(widget.slot.icon, color: color, size: 18)),
            const SizedBox(width: 10),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.schoolNotesTitle,
                  style: const TextStyle(
                      fontSize: 10, color: Color(0xFF9E9E9E),
                      fontWeight: FontWeight.w600)),
              Text(widget.slot.subject ?? '',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: cs.onSurface)),
            ])),
          ]),
          const SizedBox(height: 14),
          TextField(
            controller: _ctrl,
            autofocus: true,
            maxLines: 5,
            minLines: 3,
            decoration: InputDecoration(
              hintText: l10n.schoolNotesHint,
              hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
              filled: true,
              fillColor: cs.surfaceContainerLow,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                notes.saveNote(widget.slot.noteKey, _ctrl.text);
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(l10n.schoolNotesSave,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Shared: Sheet item ───────────────────────────────────────────────────────

class _SheetItem extends StatelessWidget {
  final String title, subtitle;
  final String? trailing;
  final bool done;
  final Color color;

  const _SheetItem({
    required this.title, required this.subtitle, required this.color,
    this.trailing, this.done = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          color: done ? cs.surfaceContainerLow : cs.surface,
          borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Icon(
            done
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 20,
            color: done ? const Color(0xFF9E9E9E) : color),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: done
                      ? const Color(0xFF9E9E9E)
                      : cs.onSurface,
                  decoration: done ? TextDecoration.lineThrough : null)),
          Text(subtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
        ])),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(8)),
            child: Text(trailing!,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: color))),
      ]),
    );
  }
}

// ─── Shared: Section header ───────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Icon(icon, size: 15, color: const Color(0xFFBDBDBD)),
        const SizedBox(width: 6),
        Text(title.toUpperCase(),
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: Color(0xFFBDBDBD), letterSpacing: 0.8)),
      ]),
    );
  }
}

// ─── Parent School View ───────────────────────────────────────────────────────


class _ParentSchoolView extends StatelessWidget {
  final User? user;
  const _ParentSchoolView({this.user});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // School info header
          _PCard(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.school_rounded, color: Color(0xFFE6B800), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.school ?? l10n.parentSchoolMySchool,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Klasse ${user?.schoolClass ?? '–'}  •  ${l10n.parentRoleBadge}',
                        style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(20)),
                  child: Text(l10n.parentRoleBadge, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFE6B800))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Next parent-teacher conference
          _PSection(icon: Icons.event_rounded, title: l10n.parentSchoolEventsTitle),
          const SizedBox(height: 8),
          _PCard(
            child: Builder(builder: (context) {
              final dividerColor = Theme.of(context).colorScheme.outline;
              return Column(
                children: [
                  const _PEventRow(
                    icon: Icons.people_rounded,
                    iconBg: Color(0xFFFFF8E1),
                    iconColor: Color(0xFFE6B800),
                    title: 'Elternsprechtag',
                    subtitle: 'Di, 25.03.2025 · 16:00–19:00 Uhr',
                    badge: 'Bald',
                    badgeColor: Color(0xFFE6B800),
                  ),
                  Divider(height: 1, color: dividerColor),
                  const _PEventRow(
                    icon: Icons.directions_bus_rounded,
                    iconBg: Color(0xFFFFF8E1),
                    iconColor: Color(0xFFE6B800),
                    title: 'Schulausflug 7b',
                    subtitle: 'Fr, 04.04.2025 · ganztägig',
                    badge: null,
                    badgeColor: null,
                  ),
                  Divider(height: 1, color: dividerColor),
                  const _PEventRow(
                    icon: Icons.theater_comedy_rounded,
                    iconBg: Color(0xFFFFEBEE),
                    iconColor: Color(0xFFCC0000),
                    title: 'Schultheater',
                    subtitle: 'Mo, 07.04.2025 · 18:30 Uhr',
                    badge: null,
                    badgeColor: null,
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 16),

          // Class teacher contact
          _PSection(icon: Icons.contact_phone_rounded, title: l10n.parentSchoolContactsTitle),
          const SizedBox(height: 8),
          _PCard(
            child: Builder(builder: (context) {
              final dividerColor = Theme.of(context).colorScheme.outline;
              return Column(
                children: [
                  const _PContactRow(
                    initials: 'AM',
                    name: 'Anna Müller',
                    role: 'Klassenlehrerin · Mathematik',
                    email: 'a.mueller@schule.de',
                  ),
                  Divider(height: 1, color: dividerColor),
                  const _PContactRow(
                    initials: 'KS',
                    name: 'Klaus Schmidt',
                    role: 'Deutschlehrer',
                    email: 'k.schmidt@schule.de',
                  ),
                  Divider(height: 1, color: dividerColor),
                  const _PContactRow(
                    initials: 'LW',
                    name: 'Lisa Weber',
                    role: 'Englischlehrerin',
                    email: 'l.weber@schule.de',
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 16),

          // Parent announcements
          _PSection(icon: Icons.campaign_rounded, title: l10n.parentSchoolLettersTitle),
          const SizedBox(height: 8),
          _PCard(
            child: Builder(builder: (context) {
              final dividerColor = Theme.of(context).colorScheme.outline;
              return Column(
                children: [
                  const _PAnnouncementRow(
                    title: 'Digitale Geräte an der Schule',
                    date: '12.03.2025',
                    isNew: true,
                  ),
                  Divider(height: 1, color: dividerColor),
                  const _PAnnouncementRow(
                    title: 'Änderungen im Mensaplan April',
                    date: '05.03.2025',
                    isNew: false,
                  ),
                  Divider(height: 1, color: dividerColor),
                  const _PAnnouncementRow(
                    title: 'Elternabend Protokoll Feb.',
                    date: '28.02.2025',
                    isNew: false,
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 16),

          // Parent committee
          _PSection(icon: Icons.groups_rounded, title: l10n.parentSchoolCommitteeTitle),
          const SizedBox(height: 8),
          _PCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Builder(builder: (context) {
                final dividerColor = Theme.of(context).colorScheme.outline;
                return Column(
                  children: [
                    _PMenuRow(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: l10n.parentSchoolCommitteeChat,
                      onTap: () {},
                    ),
                    Divider(height: 1, color: dividerColor),
                    _PMenuRow(
                      icon: Icons.how_to_vote_rounded,
                      label: l10n.parentSchoolCommitteeVotes,
                      onTap: () {},
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Parent school sub-widgets ─────────────────────────────────────────────────

class _PCard extends StatelessWidget {
  final Widget child;
  const _PCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PSection extends StatelessWidget {
  final IconData icon;
  final String title;
  const _PSection({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFE6B800)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFFE6B800),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _PEventRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badge;
  final Color? badgeColor;

  const _PEventRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                const SizedBox(height: 1),
                Text(subtitle, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          if (badge != null && badgeColor != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor!.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge!,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: badgeColor),
              ),
            ),
        ],
      ),
    );
  }
}

class _PContactRow extends StatelessWidget {
  final String initials;
  final String name;
  final String role;
  final String email;

  const _PContactRow({
    required this.initials,
    required this.name,
    required this.role,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: Color(0xFFFFF8E1), shape: BoxShape.circle),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFE6B800)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                const SizedBox(height: 1),
                Text(role, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.mail_outline_rounded, size: 18, color: Color(0xFFE6B800)),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

class _PAnnouncementRow extends StatelessWidget {
  final String title;
  final String date;
  final bool isNew;

  const _PAnnouncementRow({
    required this.title,
    required this.date,
    required this.isNew,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isNew ? const Color(0xFFFFF8E1) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.description_outlined,
              color: isNew ? const Color(0xFFE6B800) : const Color(0xFFBDBDBD),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isNew ? FontWeight.w600 : FontWeight.w500,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 1),
                Text(date, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          if (isNew)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: Color(0xFFE6B800), shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}

class _PMenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PMenuRow({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: const Color(0xFFE6B800), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: cs.onSurface),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: cs.outline),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ─── Teacher School View ──────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════════

// Palette (mirrors HAI3)
const Color _kTGold      = Color(0xFFE6B800);
const Color _kTGoldLight = Color(0xFFFFF8E1);
const Color _kTText      = Color(0xFF1A1A1A);
const Color _kTSubtext   = Color(0xFF6B6B6B);
const Color _kTSurface   = Color(0xFFF5F5F5);
const Color _kTBorder    = Color(0xFFE0E0E0);

// Mock teaching schedule for today
class _TeachSlot {
  final String subject;
  final String className;
  final String room;
  final int startH, startM, endH, endM;
  final Color color;
  const _TeachSlot({
    required this.subject, required this.className,
    required this.room,
    required this.startH, required this.startM,
    required this.endH, required this.endM,
    this.color = const Color(0xFFE6B800),
  });
  String get timeStr =>
      '${startH.toString().padLeft(2,'0')}:${startM.toString().padLeft(2,'0')} – '
      '${endH.toString().padLeft(2,'0')}:${endM.toString().padLeft(2,'0')}';
  bool get isNow {
    final now = DateTime.now();
    final nowM = now.hour * 60 + now.minute;
    return nowM >= startH * 60 + startM && nowM < endH * 60 + endM;
  }
  bool get isNext {
    final now = DateTime.now();
    final nowM = now.hour * 60 + now.minute;
    return nowM < startH * 60 + startM;
  }
}

const _kTeachSchedule = [
  _TeachSlot(subject: 'Mathematik', className: '5A', room: '212',
      startH: 8, startM: 0, endH: 8, endM: 45,
      color: Color(0xFF5B8DEF)),
  _TeachSlot(subject: 'Mathematik', className: '7C', room: '212',
      startH: 8, startM: 55, endH: 9, endM: 40,
      color: Color(0xFF5B8DEF)),
  _TeachSlot(subject: 'Deutsch', className: '5B', room: '107',
      startH: 10, startM: 0, endH: 10, endM: 45,
      color: Color(0xFFFF7043)),
  _TeachSlot(subject: 'Mathematik', className: '5B', room: '212',
      startH: 11, startM: 0, endH: 11, endM: 45,
      color: Color(0xFF5B8DEF)),
  _TeachSlot(subject: 'Deutsch', className: '7C', room: '107',
      startH: 12, startM: 0, endH: 12, endM: 45,
      color: Color(0xFFFF7043)),
];

// Mock classes for teacher
class _TeachClass {
  final String name;
  final int studentCount;
  final String subject;
  const _TeachClass({required this.name, required this.studentCount, required this.subject});
}

const _kTeachClasses = [
  _TeachClass(name: '5A', studentCount: 20, subject: 'Mathematik'),
  _TeachClass(name: '5B', studentCount: 18, subject: 'Deutsch'),
  _TeachClass(name: '7C', studentCount: 24, subject: 'Mathematik'),
];

// Mock colleagues
class _Colleague {
  final String name;
  final String subject;
  final int colorIdx;
  const _Colleague({required this.name, required this.subject, required this.colorIdx});
  String get initials => name.split(' ').map((w) => w[0]).take(2).join().toUpperCase();
}

const _kColleagues = [
  _Colleague(name: 'Eva Braun',    subject: 'Deutsch',     colorIdx: 2),
  _Colleague(name: 'Hans Keil',    subject: 'Englisch',    colorIdx: 3),
  _Colleague(name: 'Mia Vogel',    subject: 'Biologie',    colorIdx: 4),
  _Colleague(name: 'Tom Richter',  subject: 'Geschichte',  colorIdx: 5),
  _Colleague(name: 'Sara Lenz',    subject: 'Physik',      colorIdx: 6),
];

const _kCollegueColors = [
  Color(0xFFE6B800), Color(0xFF1A1A1A), Color(0xFF5C6BC0),
  Color(0xFF00796B), Color(0xFF6D4C41), Color(0xFF558B2F), Color(0xFF7B1FA2),
];

class _TeacherSchoolView extends StatefulWidget {
  final User? user;
  const _TeacherSchoolView({this.user});

  @override
  State<_TeacherSchoolView> createState() => _TeacherSchoolViewState();
}

class _TeacherSchoolViewState extends State<_TeacherSchoolView> {
  _SchedView _schedView = _SchedView.today;

  @override
  Widget build(BuildContext context) {
    final l10n        = AppLocalizations.of(context)!;
    final now         = DateTime.now();
    final nowM        = now.hour * 60 + now.minute;
    final currentSlot = _kTeachSchedule.cast<_TeachSlot?>().firstWhere(
        (s) => s!.isNow, orElse: () => null);
    final nextSlot    = _kTeachSchedule.cast<_TeachSlot?>().firstWhere(
        (s) => nowM < s!.startH * 60 + s.startM, orElse: () => null);
    final schoolName  = widget.user?.school ?? l10n.schoolTitle;
    final monday      = now.subtract(Duration(days: now.weekday - 1));

    return LayoutBuilder(
      builder: (context, _) => CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          // ── Header card ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFFE6B800), Color(0xFFFFD84D)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(
                      color: const Color(0xFFE6B800).withOpacity(0.30),
                      blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(schoolName,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                            color: Colors.white),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.person_rounded, size: 13, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(widget.user?.firstName != null
                          ? '${widget.user!.firstName} ${widget.user!.lastName ?? ''}'.trim()
                          : '',
                          style: const TextStyle(fontSize: 13, color: Colors.white70)),
                    ]),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(l10n.teacherSchoolRoleBadge,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ]),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),

          // ── Live status card ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _kTBorder),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: currentSlot != null
                          ? currentSlot.color.withOpacity(0.12) : _kTSurface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      currentSlot != null
                          ? Icons.cast_for_education_rounded
                          : nextSlot != null
                              ? Icons.access_time_rounded
                              : Icons.check_circle_rounded,
                      color: currentSlot != null ? currentSlot.color : _kTSubtext,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: currentSlot != null
                      ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(l10n.teacherSchoolNowTeaching,
                              style: const TextStyle(fontSize: 11, color: _kTSubtext,
                                  fontWeight: FontWeight.w600, letterSpacing: 0.4)),
                          const SizedBox(height: 2),
                          Text('${currentSlot.subject} · ${currentSlot.className}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                                  color: _kTText)),
                          Text('${l10n.schoolRoom} ${currentSlot.room}  ·  ${currentSlot.timeStr}',
                              style: const TextStyle(fontSize: 12, color: _kTSubtext)),
                        ])
                      : nextSlot != null
                          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(l10n.teacherSchoolNextClass,
                                  style: const TextStyle(fontSize: 11, color: _kTSubtext,
                                      fontWeight: FontWeight.w600, letterSpacing: 0.4)),
                              const SizedBox(height: 2),
                              Text('${nextSlot.subject} · ${nextSlot.className}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                                      color: _kTText)),
                              Text('${l10n.schoolRoom} ${nextSlot.room}  ·  ${nextSlot.timeStr}',
                                  style: const TextStyle(fontSize: 12, color: _kTSubtext)),
                            ])
                          : Text(l10n.teacherSchoolFreeNow,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                                  color: _kTSubtext)),
                  ),
                ]),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Schedule section header + toggle ─────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                _TTeacherSectionHeader(
                    icon: Icons.today_rounded,
                    title: l10n.teacherSchoolMySchedule),
                const Spacer(),
                _ViewToggle(
                  value: _schedView,
                  todayLabel: l10n.schoolScheduleToday,
                  weekLabel: l10n.schoolWeekView,
                  onChanged: (v) => setState(() => _schedView = v),
                ),
              ]),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),

          // ── Schedule content ─────────────────────────────────────────
          if (_schedView == _SchedView.today)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 100,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _kTeachSchedule.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final slot     = _kTeachSchedule[i];
                    final isActive = slot.isNow;
                    return Container(
                      width: 130,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isActive ? slot.color : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive ? slot.color : _kTBorder,
                          width: isActive ? 2 : 1,
                        ),
                        boxShadow: isActive ? [BoxShadow(
                            color: slot.color.withOpacity(0.25),
                            blurRadius: 8, offset: const Offset(0, 3))] : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.white.withOpacity(0.25)
                                    : slot.color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(slot.className,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                                      color: isActive ? Colors.white : slot.color)),
                            ),
                            const Spacer(),
                            if (isActive)
                              Container(
                                width: 6, height: 6,
                                decoration: const BoxDecoration(
                                    color: Colors.white, shape: BoxShape.circle),
                              ),
                          ]),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(slot.subject,
                                style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700,
                                  color: isActive ? Colors.white : _kTText,
                                ),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(slot.timeStr,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: isActive ? Colors.white70 : _kTSubtext)),
                          ]),
                        ],
                      ),
                    );
                  },
                ),
              ),
            )
          else
            // ── Week schedule: flat SliverList, each lesson = white card R24/P20
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final slotsPerDay  = _kTeachSchedule.length;
                    final itemsPerDay  = 1 + slotsPerDay;
                    final dayIdx       = i ~/ itemsPerDay;
                    final localIdx     = i % itemsPerDay;
                    final dayDate      = monday.add(Duration(days: dayIdx));
                    final isToday      = dayDate.day   == now.day &&
                                        dayDate.month  == now.month &&
                                        dayDate.year   == now.year;

                    if (localIdx == 0) {
                      // Day section header
                      final locale  = Localizations.localeOf(ctx).toString();
                      final dayName = DateFormat.EEEE(locale).format(dayDate);
                      final dateStr = DateFormat('d. MMM', locale).format(dayDate);
                      return Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 8),
                        child: Row(children: [
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              color: isToday
                                  ? const Color(0xFFE6B800) : _kTBorder,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${dayName[0].toUpperCase()}${dayName.substring(1)}, $dateStr',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isToday
                                  ? const Color(0xFFE6B800) : _kTSubtext,
                            ),
                          ),
                          if (isToday) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF8E1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('Heute',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFE6B800))),
                            ),
                          ],
                        ]),
                      );
                    }

                    final slot     = _kTeachSchedule[localIdx - 1];
                    final isActive = isToday && slot.isNow;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TeacherLessonCard(
                        slot: slot, isActive: isActive, l10n: l10n),
                    );
                  },
                  childCount: 5 * (1 + _kTeachSchedule.length),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── My classes ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _TTeacherSectionHeader(
                    icon: Icons.groups_2_rounded,
                    title: l10n.teacherSchoolMyClasses),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.2,
                  ),
                  itemCount: _kTeachClasses.length,
                  itemBuilder: (_, i) {
                    final cls = _kTeachClasses[i];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _kTBorder),
                        boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: Row(children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                              color: _kTGoldLight,
                              borderRadius: BorderRadius.circular(10)),
                          child: Center(
                            child: Text(cls.name,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                                    color: _kTGold)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(cls.subject,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                    color: _kTText),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(l10n.teacherSchoolStudents(cls.studentCount),
                                style: const TextStyle(fontSize: 11, color: _kTSubtext)),
                          ],
                        )),
                      ]),
                    );
                  },
                ),
              ]),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Colleagues ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _TTeacherSectionHeader(
                    icon: Icons.people_alt_rounded,
                    title: l10n.teacherSchoolColleagues),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _kTBorder),
                  ),
                  child: Column(
                    children: List.generate(_kColleagues.length, (i) {
                      final col      = _kColleagues[i];
                      final bgColor  = _kCollegueColors[col.colorIdx % _kCollegueColors.length];
                      final needsWhite = bgColor.computeLuminance() < 0.4;
                      return Column(children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(children: [
                            Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                              child: Center(
                                child: Text(col.initials,
                                    style: TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.w800,
                                        color: needsWhite ? Colors.white : _kTText)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(col.name,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                        color: _kTText)),
                                Text(col.subject,
                                    style: const TextStyle(fontSize: 12, color: _kTSubtext)),
                              ],
                            )),
                            Icon(Icons.chat_bubble_outline_rounded,
                                size: 18, color: _kTBorder),
                          ]),
                        ),
                        if (i < _kColleagues.length - 1)
                          const Divider(height: 1, indent: 66, color: _kTBorder),
                      ]);
                    }),
                  ),
                ),
              ]),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

// ── Teacher lesson card: white, R24, P20 ─────────────────────────────────────

class _TeacherLessonCard extends StatelessWidget {
  final _TeachSlot slot;
  final bool isActive;
  final AppLocalizations l10n;
  const _TeacherLessonCard({
    required this.slot,
    required this.isActive,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isActive ? slot.color : _kTBorder,
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(children: [
        // Time block
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${slot.startH.toString().padLeft(2, '0')}:${slot.startM.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isActive ? slot.color : _kTText,
              ),
            ),
            Text(
              '${slot.endH.toString().padLeft(2, '0')}:${slot.endM.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 12,
                color: isActive ? slot.color.withOpacity(0.70) : _kTSubtext,
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        // Color bar
        Container(
          width: 3,
          height: 44,
          decoration: BoxDecoration(
            color: slot.color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 16),
        // Subject + class + room
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slot.subject,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kTText,
                ),
              ),
              const SizedBox(height: 4),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: slot.color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    slot.className,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: slot.color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${l10n.schoolRoom} ${slot.room}',
                  style: const TextStyle(fontSize: 12, color: _kTSubtext),
                ),
              ]),
            ],
          ),
        ),
        if (isActive)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: slot.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'JETZT',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
      ]),
    );
  }
}

class _TTeacherSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _TTeacherSectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 15, color: const Color(0xFFBDBDBD)),
      const SizedBox(width: 6),
      Text(title.toUpperCase(),
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: Color(0xFFBDBDBD), letterSpacing: 0.8)),
    ]);
  }
}
