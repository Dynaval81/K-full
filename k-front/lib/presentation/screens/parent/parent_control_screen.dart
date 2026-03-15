// v2.1.0 — Parent Monitoring Dashboard
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:knoty/constants/palette.dart';
import 'package:knoty/core/controllers/auth_controller.dart';
import 'package:knoty/l10n/app_localizations.dart';
import 'package:knoty/presentation/widgets/knoty_app_bar.dart';
import 'package:knoty/presentation/widgets/knoty_empty_state.dart';

// ── Mock data models ──────────────────────────────────────────────────────────
enum _Attendance { atSchool, absent, unknown }

class _Grade {
  final String subject;
  final String grade;
  const _Grade(this.subject, this.grade);
}

class _MockChild {
  final String kn;
  final String name;
  final _Attendance attendance;
  final int screenUsedMin;
  final int screenLimitMin;
  final List<_Grade> grades;
  final bool isPending;

  const _MockChild({
    required this.kn,
    required this.name,
    this.attendance = _Attendance.unknown,
    this.screenUsedMin = 0,
    this.screenLimitMin = 120,
    this.grades = const [],
    this.isPending = false,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String get firstName => name.split(' ').first;
}

_MockChild _mockFromKn(String kn, {bool isPending = false}) {
  final h = kn.hashCode.abs();
  const names = ['Anna M.', 'Max K.', 'Sophie L.', 'Tim B.', 'Lena R.'];
  final name = names[h % names.length];
  if (isPending) return _MockChild(kn: kn, name: name, isPending: true);
  return _MockChild(
    kn: kn,
    name: name,
    attendance: h % 3 != 2 ? _Attendance.atSchool : _Attendance.absent,
    screenUsedMin: 45 + (h % 75),
    screenLimitMin: 120,
    grades: [
      _Grade('Mathe', '${1 + (h % 3)}'),
      _Grade('Deutsch', '${1 + ((h + 1) % 4)}'),
      _Grade('Englisch', '${1 + ((h + 2) % 3)}'),
    ],
  );
}

// ── Root screen ───────────────────────────────────────────────────────────────
class ParentControlScreen extends StatelessWidget {
  const ParentControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final user = context.watch<AuthController>().currentUser;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      appBar: KnotyAppBar(title: l10n.parentTitle),
      body: _ParentDashboard(
        confirmedKns: [
          if (user?.linkedChildId != null) user!.linkedChildId!,
          ...?user?.linkedAccounts,
        ],
      ),
    );
  }
}

// ── Main stateful dashboard ───────────────────────────────────────────────────
class _ParentDashboard extends StatefulWidget {
  final List<String> confirmedKns;
  const _ParentDashboard({required this.confirmedKns});

  @override
  State<_ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<_ParentDashboard> {
  List<String> _pendingKns = [];
  int _selectedIndex = 0;
  double _timeLimitHours = 2.0;
  bool _eveningLock = true;
  bool _emergencyLocked = false;

  static const _prefsKey = 'parent_pending_kns';

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefsKey) ?? [];
    final confirmed = widget.confirmedKns.toSet();
    if (mounted) {
      setState(() => _pendingKns = saved.where((k) => !confirmed.contains(k)).toList());
    }
  }

  Future<void> _savePending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _pendingKns);
  }

  void _addChild(String kn) async {
    if (_pendingKns.contains(kn) || widget.confirmedKns.contains(kn)) return;
    setState(() => _pendingKns.add(kn));
    await _savePending();
  }

  void _removeChild(String kn) async {
    setState(() => _pendingKns.remove(kn));
    await _savePending();
  }

  List<_MockChild> get _allChildren {
    final confirmed = widget.confirmedKns.map((kn) => _mockFromKn(kn)).toList();
    final pending = _pendingKns.map((kn) => _mockFromKn(kn, isPending: true)).toList();
    return [...confirmed, ...pending];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final children = _allChildren;

    if (children.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          KnotyEmptyState(
            icon: Icons.family_restroom_rounded,
            title: l10n.lockedNoChildTitle,
            subtitle: l10n.lockedNoChildSubtitle,
            action: FilledButton.icon(
              onPressed: () => _showAddSheet(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(l10n.parentAddChild),
              style: FilledButton.styleFrom(
                backgroundColor: KPalette.gold,
                foregroundColor: KPalette.ink,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      );
    }

    final idx = _selectedIndex.clamp(0, children.length - 1);
    final selected = children[idx];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        // Child selector (only when multiple)
        if (children.length > 1) ...[
          _ChildSelector(
            children: children,
            selectedIndex: idx,
            onSelect: (i) => setState(() => _selectedIndex = i),
          ),
          const SizedBox(height: 16),
        ],

        // Header card
        _ChildHeaderCard(child: selected),
        const SizedBox(height: 12),

        if (selected.isPending) ...[
          _PendingCard(child: selected, onRemove: () => _removeChild(selected.kn)),
        ] else ...[
          _AttendanceCard(child: selected),
          const SizedBox(height: 12),
          _ScreenTimeCard(child: selected),
          const SizedBox(height: 12),
          _GradesCard(child: selected),
          const SizedBox(height: 12),
          _ControlsCard(
            timeLimitHours: _timeLimitHours,
            eveningLock: _eveningLock,
            onTimeLimitChanged: (v) => setState(() => _timeLimitHours = v),
            onEveningLockChanged: (v) => setState(() => _eveningLock = v),
          ),
          const SizedBox(height: 16),
          _EmergencyLockButton(
            isLocked: _emergencyLocked,
            onToggle: () => _showEmergencyConfirm(context),
          ),
        ],

        // Low-prominence add child link
        const SizedBox(height: 20),
        Center(
          child: TextButton.icon(
            onPressed: () => _showAddSheet(context),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text(l10n.parentAddChild),
            style: TextButton.styleFrom(
              foregroundColor: cs.onSurfaceVariant,
              textStyle: const TextStyle(fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddChildSheet(onAdd: (kn) {
        _addChild(kn);
        Navigator.of(context).pop();
      }),
    );
  }

  void _showEmergencyConfirm(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(_emergencyLocked ? l10n.parentEmergencyDeactivateTitle : l10n.parentEmergencyActivateTitle),
        content: Text(
          _emergencyLocked
              ? l10n.parentEmergencyDeactivateMsg
              : l10n.parentEmergencyActivateMsg,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.buttonCancel),
          ),
          TextButton(
            onPressed: () {
              setState(() => _emergencyLocked = !_emergencyLocked);
              HapticFeedback.heavyImpact();
              Navigator.of(ctx).pop();
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFCC0000)),
            child: Text(_emergencyLocked ? l10n.parentEmergencyDeactivateBtn : l10n.parentEmergencyActivateBtn),
          ),
        ],
      ),
    );
  }
}

// ── Child selector (horizontal avatars) ──────────────────────────────────────
class _ChildSelector extends StatelessWidget {
  final List<_MockChild> children;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _ChildSelector({
    required this.children,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final child = children[i];
          final selected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFE6B800) : const Color(0xFFFFF8E1),
                    shape: BoxShape.circle,
                    border: selected ? Border.all(color: const Color(0xFFE6B800), width: 2.5) : null,
                  ),
                  child: Center(
                    child: Text(
                      child.initials,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: selected ? const Color(0xFF1A1A1A) : const Color(0xFFE6B800),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  child.firstName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? const Color(0xFFE6B800) : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Child header card ─────────────────────────────────────────────────────────
class _ChildHeaderCard extends StatelessWidget {
  final _MockChild child;
  const _ChildHeaderCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _Card(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: Color(0xFFFFF8E1), shape: BoxShape.circle),
            child: Center(
              child: Text(
                child.initials,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFFE6B800)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.name,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: cs.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  child.kn,
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
          _StatusBadge(
            label: child.isPending
                ? AppLocalizations.of(context)!.parentStatusPending
                : AppLocalizations.of(context)!.parentStatusLinked,
            color: const Color(0xFFE6B800),
            bg: const Color(0xFFFFF8E1),
          ),
        ],
      ),
    );
  }
}

// ── Attendance card ───────────────────────────────────────────────────────────
class _AttendanceCard extends StatelessWidget {
  final _MockChild child;
  const _AttendanceCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final atSchool = child.attendance == _Attendance.atSchool;
    final color = atSchool ? const Color(0xFFE6B800) : cs.onSurfaceVariant;
    final bg = atSchool ? const Color(0xFFFFF8E1) : cs.surfaceContainerLow;
    final label = atSchool
        ? l10n.parentAttendanceAtSchool
        : child.attendance == _Attendance.absent
            ? l10n.parentAttendanceAbsent
            : l10n.parentAttendanceUnknown;

    return _DashCard(
      icon: Icons.location_on_rounded,
      iconColor: color,
      iconBg: bg,
      title: l10n.parentSectionAttendance,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  atSchool ? 'Seit 08:00 Uhr' : 'Stand: heute',
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: atSchool ? const Color(0xFFE6B800) : const Color(0xFFBDBDBD),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Screen time card ──────────────────────────────────────────────────────────
class _ScreenTimeCard extends StatelessWidget {
  final _MockChild child;
  const _ScreenTimeCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ratio = (child.screenUsedMin / child.screenLimitMin).clamp(0.0, 1.0);
    final usedH = child.screenUsedMin ~/ 60;
    final usedM = child.screenUsedMin % 60;
    final limitH = child.screenLimitMin ~/ 60;
    final barColor = ratio > 0.85
        ? const Color(0xFFCC0000)
        : ratio > 0.6
            ? const Color(0xFFF57C00)
            : const Color(0xFFE6B800);

    return _DashCard(
      icon: Icons.phone_android_rounded,
      iconColor: const Color(0xFFE6B800),
      iconBg: const Color(0xFFFFF8E1),
      title: AppLocalizations.of(context)!.parentSectionScreenTime,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                usedH > 0 ? '${usedH}h ${usedM}m' : '${usedM}m',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/ ${limitH}h Limit',
                style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: cs.outline,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Grades card ───────────────────────────────────────────────────────────────
class _GradesCard extends StatelessWidget {
  final _MockChild child;
  const _GradesCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _DashCard(
      icon: Icons.grade_rounded,
      iconColor: const Color(0xFFE6B800),
      iconBg: const Color(0xFFFFF8E1),
      title: AppLocalizations.of(context)!.parentSectionGrades,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: child.grades.map((g) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  g.grade,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE6B800),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  g.subject,
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Controls card ─────────────────────────────────────────────────────────────
class _ControlsCard extends StatelessWidget {
  final double timeLimitHours;
  final bool eveningLock;
  final ValueChanged<double> onTimeLimitChanged;
  final ValueChanged<bool> onEveningLockChanged;

  const _ControlsCard({
    required this.timeLimitHours,
    required this.eveningLock,
    required this.onTimeLimitChanged,
    required this.onEveningLockChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tune_rounded, color: Color(0xFFE6B800), size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.parentSectionControls,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Time limit
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.parentDailyLimitLabel,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: cs.onSurface),
                ),
              ),
              Text(
                '${timeLimitHours.toStringAsFixed(1)}h',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFE6B800)),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: timeLimitHours,
              min: 0.5,
              max: 6.0,
              divisions: 11,
              activeColor: const Color(0xFFE6B800),
              inactiveColor: cs.outline,
              onChanged: onTimeLimitChanged,
            ),
          ),
          Divider(height: 8, color: cs.outline),
          const SizedBox(height: 8),

          // Evening lock
          Row(
            children: [
              Icon(Icons.nightlight_round, size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.parentEveningBlockLabel,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: cs.onSurface),
                    ),
                    Text(
                      l10n.parentEveningBlockDesc,
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Switch(
                value: eveningLock,
                onChanged: onEveningLockChanged,
                activeThumbColor: const Color(0xFFE6B800),
                activeTrackColor: const Color(0xFFFFF8E1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Emergency lock button ─────────────────────────────────────────────────────
class _EmergencyLockButton extends StatelessWidget {
  final bool isLocked;
  final VoidCallback onToggle;
  const _EmergencyLockButton({required this.isLocked, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onToggle,
        style: ElevatedButton.styleFrom(
          backgroundColor: isLocked ? const Color(0xFFFFEBEE) : const Color(0xFFCC0000),
          foregroundColor: isLocked ? const Color(0xFFCC0000) : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        icon: Icon(isLocked ? Icons.lock_open_rounded : Icons.lock_rounded, size: 20),
        label: Text(
          isLocked ? l10n.parentEmergencyLockDeactivate : l10n.parentEmergencyLockActivate,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ── Pending child card ────────────────────────────────────────────────────────
class _PendingCard extends StatelessWidget {
  final _MockChild child;
  final VoidCallback onRemove;
  const _PendingCard({required this.child, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE6B800).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.hourglass_top_rounded, size: 40, color: Color(0xFFE6B800)),
          const SizedBox(height: 12),
          Text(
            l10n.parentPendingTitle,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.parentPendingSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: 16),
            label: Text(l10n.parentWithdrawRequest),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
          ),
        ],
      ),
    );
  }
}

// ── Add child bottom sheet ────────────────────────────────────────────────────
class _AddChildSheet extends StatefulWidget {
  final ValueChanged<String> onAdd;
  const _AddChildSheet({required this.onAdd});

  @override
  State<_AddChildSheet> createState() => _AddChildSheetState();
}

class _AddChildSheetState extends State<_AddChildSheet> {
  final _ctrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final kn = _ctrl.text.trim().toUpperCase();
    if (kn.isEmpty) {
      setState(() => _error = l10n.registerKnChildHint);
      return;
    }
    if (!RegExp(r'^KN-\d{5,6}$').hasMatch(kn)) {
      setState(() => _error = l10n.parentKnFormat);
      return;
    }
    widget.onAdd(kn);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.parentLinkChildTitle,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.registerInfoParent,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(14),
              border: _error != null ? Border.all(color: Colors.redAccent, width: 1) : null,
            ),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(fontSize: 15, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: l10n.registerKnChildHint,
                hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _submit(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(_error!, style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE6B800),
                foregroundColor: const Color(0xFF1A1A1A),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                l10n.parentLinkButton,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared card widgets ───────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DashCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final Widget child;

  const _DashCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _StatusBadge({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
