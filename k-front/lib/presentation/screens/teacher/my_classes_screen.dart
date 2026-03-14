// v2.0.0 — Bento-style class journal
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:knoty/core/controllers/auth_controller.dart';
import 'package:knoty/l10n/app_localizations.dart';
import 'package:knoty/presentation/widgets/knoty_app_bar.dart';
import 'package:knoty/presentation/widgets/locked_feature_wrapper.dart';

// ── HAI3 Palette ──────────────────────────────────────────────────────────────
const Color _kGold      = Color(0xFFE6B800);
const Color _kGoldLight = Color(0xFFFFF8E1);
const Color _kDanger    = Color(0xFFCC0000);
const Color _kPrimary   = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF6B6B6B);
const Color _kSurface   = Color(0xFFF5F5F5);
const Color _kBorder    = Color(0xFFE0E0E0);

// Avatar background palette — decorative only, all are readable
const _kAvatarPalette = [
  Color(0xFFE6B800), // gold
  Color(0xFF1A1A1A), // dark
  Color(0xFF5C6BC0), // indigo
  Color(0xFF00796B), // teal
  Color(0xFF6D4C41), // brown
  Color(0xFF558B2F), // forest
  Color(0xFF7B1FA2), // purple
];

bool _avatarNeedsWhiteText(Color bg) => bg.computeLuminance() < 0.4;

// ── Models ────────────────────────────────────────────────────────────────────

enum _GradeType { oral, written, test, homework }

class _GradeEntry {
  final int grade;        // 1–6 (German system), 0 = absent
  final bool absent;
  final _GradeType type;
  final DateTime date;
  _GradeEntry({
    required this.grade,
    this.absent = false,
    this.type = _GradeType.oral,
    DateTime? date,
  }) : date = date ?? DateTime.now();
}

class _Student {
  final String id;
  final String firstName;
  final String lastName;
  final int colorIndex;
  // subjectId → list of grade entries (newest first)
  final Map<String, List<_GradeEntry>> grades;

  _Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.colorIndex,
  }) : grades = {};

  _GradeEntry? latestGrade(String subjectId) {
    final list = grades[subjectId];
    return (list != null && list.isNotEmpty) ? list.first : null;
  }

  String get initials => '${firstName[0]}${lastName[0]}';
  String get displayName => '$firstName $lastName';
  Color get avatarColor => _kAvatarPalette[colorIndex % _kAvatarPalette.length];
}

class _Subject {
  final String id;
  final String Function(AppLocalizations) label;
  const _Subject({required this.id, required this.label});
}

const _kSubjects = [
  _Subject(id: 'math',    label: _subjectMath),
  _Subject(id: 'german',  label: _subjectGerman),
  _Subject(id: 'english', label: _subjectEnglish),
];

String _subjectMath(AppLocalizations l) => l.teacherJournalSubjectMath;
String _subjectGerman(AppLocalizations l) => l.teacherJournalSubjectGerman;
String _subjectEnglish(AppLocalizations l) => l.teacherJournalSubjectEnglish;

// ── Mock data ─────────────────────────────────────────────────────────────────

class _ClassDef {
  final String id;
  final String label;
  final List<_Student> students;
  _ClassDef({required this.id, required this.label, required this.students});
}

List<_ClassDef> _buildMockClasses() {
  final names5A = [
    ('Anna', 'Müller'), ('Ben', 'Schmidt'), ('Clara', 'Weber'),
    ('David', 'Fischer'), ('Emma', 'Wagner'), ('Felix', 'Becker'),
    ('Greta', 'Schulz'), ('Hans', 'Richter'), ('Ida', 'Koch'),
    ('Jan', 'Bauer'), ('Klara', 'Hoffmann'), ('Leon', 'Meyer'),
    ('Mia', 'Herrmann'), ('Noah', 'Schäfer'), ('Olivia', 'Klein'),
    ('Paul', 'Lange'), ('Rosa', 'Braun'), ('Sam', 'Neumann'),
    ('Tanja', 'Schwarz'), ('Uwe', 'Wolf'),
  ];
  final names5B = [
    ('Alma', 'Kaiser'), ('Boris', 'Zimmermann'), ('Celine', 'Frank'),
    ('Dennis', 'Lenz'), ('Elena', 'Berg'), ('Florian', 'Haas'),
    ('Gabi', 'Schreiber'), ('Heinz', 'Krause'), ('Ines', 'Roth'),
    ('Jonas', 'Simon'), ('Katja', 'Krug'), ('Lars', 'König'),
    ('Marina', 'Engel'), ('Niklas', 'Kuhn'), ('Pia', 'Vogel'),
    ('Ralf', 'Horn'), ('Sophie', 'Weis'), ('Tim', 'Stern'),
  ];
  final names7C = [
    ('Amir', 'Hassan'), ('Bella', 'Schulze'), ('Chris', 'Lüdke'),
    ('Diana', 'Pfeiffer'), ('Egor', 'Sokolov'), ('Fiona', 'Hartmann'),
    ('Greg', 'Bauer'), ('Hanna', 'Fuchs'), ('Ivan', 'Petrov'),
    ('Jana', 'Keller'), ('Kevin', 'Maier'), ('Laura', 'Berger'),
    ('Max', 'Werner'), ('Nora', 'Hoffmann'), ('Omar', 'Ali'),
    ('Petra', 'Braun'), ('Quentin', 'Müller'), ('Rita', 'Schmidt'),
    ('Stefan', 'Fischer'), ('Uma', 'Koch'), ('Vito', 'Russo'),
    ('Wendy', 'Park'), ('Xenia', 'Klein'), ('Yusuf', 'Demir'),
  ];

  int i = 0;
  _Student s(String first, String last) =>
      _Student(id: '$first$last', firstName: first, lastName: last, colorIndex: i++);

  return [
    _ClassDef(id: '5a', label: '5A', students: names5A.map((n) => s(n.$1, n.$2)).toList()),
    _ClassDef(id: '5b', label: '5B', students: names5B.map((n) => s(n.$1, n.$2)).toList()),
    _ClassDef(id: '7c', label: '7C', students: names7C.map((n) => s(n.$1, n.$2)).toList()),
  ];
}

// ── Screen ────────────────────────────────────────────────────────────────────

class MyClassesScreen extends StatefulWidget {
  const MyClassesScreen({super.key});

  @override
  State<MyClassesScreen> createState() => _MyClassesScreenState();
}

class _MyClassesScreenState extends State<MyClassesScreen> {
  final List<_ClassDef> _classes = _buildMockClasses();
  int _classIdx   = 0;
  int _subjectIdx = 0;

  _ClassDef get _currentClass => _classes[_classIdx];
  _Subject  get _currentSubject => _kSubjects[_subjectIdx];

  void _showGradeSheet(_Student student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GradeSheet(
        student: student,
        subjectId: _currentSubject.id,
        onGrade: (entry) {
          setState(() {
            student.grades.putIfAbsent(_currentSubject.id, () => []);
            student.grades[_currentSubject.id]!.insert(0, entry);
          });
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.teacherGradeAdded),
              duration: const Duration(seconds: 2),
              backgroundColor: _kPrimary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = context.watch<AuthController>().currentUser;
    final isVerified = user?.isSchoolVerified ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: KnotyAppBar(title: l10n.teacherClassesTitle),
      body: LockedFeatureWrapper(
        isLocked: !isVerified,
        title: l10n.lockedTeacherTitle,
        subtitle: l10n.lockedTeacherSubtitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // ── Class selector ───────────────────────────────────────
            _SelectorRow(
              items: _classes.map((c) => c.label).toList(),
              selected: _classIdx,
              onSelected: (i) => setState(() => _classIdx = i),
            ),
            const SizedBox(height: 6),
            // ── Subject selector ─────────────────────────────────────
            _SelectorRow(
              items: _kSubjects.map((s) => s.label(l10n)).toList(),
              selected: _subjectIdx,
              onSelected: (i) => setState(() => _subjectIdx = i),
              small: true,
            ),
            const SizedBox(height: 12),
            // ── Student grid ─────────────────────────────────────────
            Expanded(
              child: _currentClass.students.isEmpty
                  ? Center(
                      child: Text(
                        l10n.teacherNoStudents,
                        style: const TextStyle(color: _kSecondary),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: _currentClass.students.length,
                      itemBuilder: (_, i) {
                        final student = _currentClass.students[i];
                        return _StudentCard(
                          student: student,
                          subjectId: _currentSubject.id,
                          onTap: () => _showGradeSheet(student),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Selector Row ──────────────────────────────────────────────────────────────

class _SelectorRow extends StatelessWidget {
  final List<String> items;
  final int selected;
  final ValueChanged<int> onSelected;
  final bool small;

  const _SelectorRow({
    required this.items,
    required this.selected,
    required this.onSelected,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: small ? 34 : 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final active = i == selected;
          return GestureDetector(
            onTap: () => onSelected(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(
                horizontal: small ? 14 : 18,
                vertical: small ? 6 : 10,
              ),
              decoration: BoxDecoration(
                color: active ? _kGold : _kSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? _kGold : _kBorder,
                ),
              ),
              child: Text(
                items[i],
                style: TextStyle(
                  fontSize: small ? 13 : 14,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? _kPrimary : _kSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Student Card ──────────────────────────────────────────────────────────────

class _StudentCard extends StatefulWidget {
  final _Student student;
  final String subjectId;
  final VoidCallback onTap;

  const _StudentCard({
    required this.student,
    required this.subjectId,
    required this.onTap,
  });

  @override
  State<_StudentCard> createState() => _StudentCardState();
}

class _StudentCardState extends State<_StudentCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scale = Tween(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.student.latestGrade(widget.subjectId);
    final hasGrade = entry != null && !entry.absent;
    final isAbsent = entry?.absent ?? false;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasGrade
                  ? _gradeColor(entry!.grade).withOpacity(0.4)
                  : isAbsent
                      ? _kDanger.withOpacity(0.3)
                      : _kBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Main content
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Avatar
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isAbsent
                            ? _kDanger.withOpacity(0.12)
                            : widget.student.avatarColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isAbsent
                            ? const Icon(_kAbsentIcon, color: _kDanger, size: 24)
                            : Text(
                                widget.student.initials,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: _avatarNeedsWhiteText(
                                          widget.student.avatarColor)
                                      ? Colors.white
                                      : _kPrimary,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Name
                    Text(
                      widget.student.firstName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      widget.student.lastName,
                      style: const TextStyle(fontSize: 11, color: _kSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Grade badge — top right
              if (hasGrade)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _gradeColor(entry!.grade),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${entry.grade}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

const IconData _kAbsentIcon = Icons.person_off_rounded;

Color _gradeColor(int grade) {
  switch (grade) {
    case 1: return const Color(0xFF43A047); // green — sehr gut
    case 2: return const Color(0xFF7CB342); // light green — gut
    case 3: return const Color(0xFFE6B800); // gold — befriedigend
    case 4: return const Color(0xFFEF6C00); // orange — ausreichend
    case 5: return _kDanger;               // red — mangelhaft
    case 6: return const Color(0xFF880E4F); // dark red — ungenügend
    default: return _kSecondary;
  }
}

// ── Grade Sheet ───────────────────────────────────────────────────────────────

class _GradeSheet extends StatefulWidget {
  final _Student student;
  final String subjectId;
  final void Function(_GradeEntry entry) onGrade;

  const _GradeSheet({
    required this.student,
    required this.subjectId,
    required this.onGrade,
  });

  @override
  State<_GradeSheet> createState() => _GradeSheetState();
}

// Relative date choice
enum _DateChoice { today, yesterday, pick }

class _GradeSheetState extends State<_GradeSheet> {
  int? _selectedGrade;
  bool _absent = false;
  _GradeType _type = _GradeType.oral;
  _DateChoice _dateChoice = _DateChoice.today;
  DateTime? _pickedDate;

  DateTime get _effectiveDate {
    switch (_dateChoice) {
      case _DateChoice.today:     return DateTime.now();
      case _DateChoice.yesterday: return DateTime.now().subtract(const Duration(days: 1));
      case _DateChoice.pick:      return _pickedDate ?? DateTime.now();
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _pickedDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _kGold, onPrimary: _kPrimary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _pickedDate = picked);
  }

  void _submit() {
    if (_absent) {
      widget.onGrade(_GradeEntry(grade: 0, absent: true, type: _type, date: _effectiveDate));
      Navigator.pop(context);
      return;
    }
    if (_selectedGrade != null) {
      widget.onGrade(_GradeEntry(
        grade: _selectedGrade!,
        type: _type,
        date: _effectiveDate,
      ));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gradeLabels = [
      l10n.teacherGrade1Label, l10n.teacherGrade2Label,
      l10n.teacherGrade3Label, l10n.teacherGrade4Label,
      l10n.teacherGrade5Label, l10n.teacherGrade6Label,
    ];

    final typeLabels = {
      _GradeType.oral:     l10n.teacherGradeTypeOral,
      _GradeType.written:  l10n.teacherGradeTypeWritten,
      _GradeType.test:     l10n.teacherGradeTypeTest,
      _GradeType.homework: l10n.teacherGradeTypeHomework,
    };

    final dateLabels = {
      _DateChoice.today:     l10n.teacherGradeToday,
      _DateChoice.yesterday: l10n.teacherGradeYesterday,
      _DateChoice.pick:      _pickedDate != null
          ? '${_pickedDate!.day.toString().padLeft(2,'0')}.${_pickedDate!.month.toString().padLeft(2,'0')}.${_pickedDate!.year}'
          : '···',
    };

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: _kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title with student name
          Center(
            child: Text(
              l10n.teacherGradeFor(widget.student.firstName),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _kPrimary,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // ── Date row ────────────────────────────────────────────────
          Text(
            l10n.teacherGradeDate,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: _kSecondary, letterSpacing: 0.4),
          ),
          const SizedBox(height: 8),
          Row(
            children: _DateChoice.values.map((dc) {
              final active = _dateChoice == dc;
              final isPick = dc == _DateChoice.pick;
              return Expanded(
                child: GestureDetector(
                  onTap: () async {
                    setState(() => _dateChoice = dc);
                    if (isPick) await _pickDate();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: active ? _kGold : _kSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: active ? _kGold : _kBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isPick) ...[
                          Icon(Icons.calendar_today_rounded,
                              size: 12,
                              color: active ? _kPrimary : _kSecondary),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          dateLabels[dc]!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                            color: active ? _kPrimary : _kSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // ── Type row ────────────────────────────────────────────────
          Text(
            l10n.teacherGradeTypeLabel,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: _kSecondary, letterSpacing: 0.4),
          ),
          const SizedBox(height: 8),
          Row(
            children: _GradeType.values.map((t) {
              final active = _type == t;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _type = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: active ? _kPrimary : _kSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: active ? _kPrimary : _kBorder,
                      ),
                    ),
                    child: Text(
                      typeLabels[t]!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? Colors.white : _kSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // ── Grade title ─────────────────────────────────────────────
          Text(
            l10n.teacherGradeDialogTitle,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: _kSecondary, letterSpacing: 0.4),
          ),
          const SizedBox(height: 8),

          // Grade buttons — 1 through 6
          Row(
            children: List.generate(6, (i) {
              final grade = i + 1;
              final isSelected = _selectedGrade == grade && !_absent;
              final color = _gradeColor(grade);
              return Expanded(
                child: GestureDetector(
                  onTap: _absent ? null : () => setState(() => _selectedGrade = grade),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 4),
                    height: 52,
                    decoration: BoxDecoration(
                      color: isSelected ? color : color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? color : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$grade',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? Colors.white : color,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(6, (i) => Expanded(
              child: Text(
                gradeLabels[i],
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 8.5, color: _kSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            )),
          ),
          const SizedBox(height: 14),

          // Absent toggle + confirm in one row
          Row(
            children: [
              // Absent toggle
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _absent = !_absent;
                    if (_absent) _selectedGrade = null;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _absent ? _kDanger.withOpacity(0.08) : _kSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _absent ? _kDanger : _kBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _absent ? Icons.check_circle_rounded : Icons.person_off_rounded,
                          size: 16,
                          color: _absent ? _kDanger : _kSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.teacherMarkAbsent,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: _absent ? _kDanger : _kSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Confirm button
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: (_selectedGrade != null || _absent) ? _submit : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: (_selectedGrade != null || _absent) ? _kGold : _kSurface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      l10n.teacherGradeAdded,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: (_selectedGrade != null || _absent) ? _kPrimary : _kSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
