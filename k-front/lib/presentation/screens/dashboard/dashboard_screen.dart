import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:knoty/core/network/dio_client.dart';
import 'package:knoty/core/controllers/auth_controller.dart';
import 'package:knoty/core/controllers/tab_visibility_controller.dart';
import 'package:knoty/core/enums/user_role.dart';
import 'package:knoty/core/utils/app_logger.dart';
import 'package:knoty/data/models/user_model.dart';
import 'package:knoty/providers/user_provider.dart';
import 'package:knoty/l10n/app_localizations.dart';
import 'package:knoty/locale_provider.dart';
import 'package:knoty/theme_provider.dart';
import 'package:knoty/presentation/widgets/knoty_app_bar.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n  = AppLocalizations.of(context)!;
    final auth  = context.watch<AuthController>();
    final user  = auth.currentUser;
    final role  = user?.role ?? UserRole.student;
    final vis   = context.watch<TabVisibilityController>();

    return Scaffold(
      appBar: KnotyAppBar(title: l10n.dashboardTitle),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

            // ── Theme ─────────────────────────────────────────────
            _ThemeCard(),
            const SizedBox(height: 4),

            // ── Tab visibility ────────────────────────────────────
            _ExpandCard(
              icon: Icons.tune_rounded,
              title: l10n.settingsTabsTitle,
              initiallyExpanded: true,
              children: [
                _TabToggle(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: l10n.settingsTabChats,
                  value: vis.showChatsTab,
                  onChanged: vis.setChatsTab,
                  allValues: _baseTabValues(vis, role),
                ),
                _TabToggle(
                  icon: Icons.psychology_rounded,
                  label: l10n.settingsTabAi,
                  value: vis.showAiTab,
                  onChanged: vis.setAiTab,
                  allValues: _baseTabValues(vis, role),
                ),
                _TabToggle(
                  icon: Icons.school_rounded,
                  label: l10n.settingsTabSchool,
                  value: vis.showScheduleTab,
                  onChanged: vis.setScheduleTab,
                  allValues: _baseTabValues(vis, role),
                ),
                if (role.hasChildTab)
                  _TabToggle(
                    icon: Icons.child_care_rounded,
                    label: l10n.settingsTabKind,
                    value: vis.showKindTab,
                    onChanged: vis.setKindTab,
                    allValues: _baseTabValues(vis, role),
                  ),
                if (role.hasMyClassesTab)
                  _TabToggle(
                    icon: Icons.class_rounded,
                    label: l10n.settingsTabClasses,
                    value: vis.showClassesTab,
                    onChanged: vis.setClassesTab,
                    allValues: _baseTabValues(vis, role),
                  ),
                if (role.hasManagementTab)
                  _TabToggle(
                    icon: Icons.admin_panel_settings_rounded,
                    label: l10n.settingsTabVerwaltung,
                    value: vis.showVerwaltungTab,
                    onChanged: vis.setVerwaltungTab,
                    allValues: _baseTabValues(vis, role),
                  ),
              ],
            ),

            // ── Language ──────────────────────────────────────────
            _LanguageExpandCard(),

            // ── App info ─────────────────────────────────────────
            _ExpandCard(
              icon: Icons.info_outline_rounded,
              title: l10n.dashboardAppInfo,
              children: [
                _InfoRow('App', 'Knoty'),
                _InfoRow(l10n.settingsVersion, '1.0.0 (1)'),
                _InfoRow('Build', '1'),
                _InfoRow('API', 'v1.0'),
              ],
            ),

            // ── Bug report ───────────────────────────────────────
            _ReportButton(user: user),
            const SizedBox(height: 8),
          ],
          ),
        ),
      ),
    );
  }

  List<bool> _baseTabValues(TabVisibilityController vis, UserRole role) {
    return [
      vis.showChatsTab,
      vis.showAiTab,
      vis.showScheduleTab,
      if (role.hasChildTab)      vis.showKindTab,
      if (role.hasMyClassesTab)  vis.showClassesTab,
      if (role.hasManagementTab) vis.showVerwaltungTab,
    ];
  }
}

// ── Theme card ────────────────────────────────────────────────────────────────

class _ThemeCard extends StatelessWidget {
  const _ThemeCard();

  @override
  Widget build(BuildContext context) {
    final l10n  = AppLocalizations.of(context)!;
    final theme = context.watch<ThemeProvider>();
    final isDark = theme.isDarkMode;

    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(
          color: cs.outline.withValues(alpha: 0.4),
          blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFE6B800).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            color: const Color(0xFFE6B800), size: 17),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(l10n.settingsTheme,
          style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w500, color: cs.onSurface))),
        // Segmented toggle
        Container(
          height: 34,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ThemeSegment(
                icon: Icons.light_mode_rounded,
                label: l10n.settingsThemeLight,
                active: !isDark,
                onTap: () => theme.setTheme(false),
              ),
              const SizedBox(width: 2),
              _ThemeSegment(
                icon: Icons.dark_mode_rounded,
                label: l10n.settingsThemeDark,
                active: isDark,
                onTap: () => theme.setTheme(true),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _ThemeSegment extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ThemeSegment({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? Theme.of(context).colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: active
              ? [BoxShadow(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                  blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
            size: 14,
            color: active ? const Color(0xFFE6B800) : Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label,
            style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: active ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant)),
        ]),
      ),
    );
  }
}

// ── Expand card ───────────────────────────────────────────────────────────────

class _ExpandCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;
  final String? subtitle;

  const _ExpandCard({
    required this.icon,
    required this.title,
    required this.children,
    this.initiallyExpanded = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(
          color: cs.outline.withValues(alpha: 0.4),
          blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: ExpansionTile(
          key: PageStorageKey<String>(title),
          initiallyExpanded: initiallyExpanded,
          shape: const Border(),
          backgroundColor: Colors.transparent,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          leading: Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE6B800).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFE6B800), size: 17),
          ),
          title: Text(title,
            style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface)),
          subtitle: subtitle != null
              ? Text(subtitle!,
                  style: TextStyle(
                    fontSize: 12, color: cs.onSurfaceVariant))
              : null,
          children: children,
        ),
      ),
    );
  }
}

// ── Tab toggle ────────────────────────────────────────────────────────────────

class _TabToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final List<bool> allValues; // защита от отключения последней вкладки

  const _TabToggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.allValues,
  });

  @override
  Widget build(BuildContext context) {
    final enabledCount = allValues.where((v) => v).length;
    final isLast = value && enabledCount <= 1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFE6B800).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFFE6B800), size: 17),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface))),
        Switch.adaptive(
          value: value,
          onChanged: isLast ? null : onChanged,
          activeColor: const Color(0xFFE6B800),
        ),
      ]),
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface)),
      ]),
    );
  }
}

// ── Bug report button ─────────────────────────────────────────────────────────

class _ReportButton extends StatelessWidget {
  final User? user;
  const _ReportButton({required this.user});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => _showSheet(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.bug_report_outlined, color: Colors.redAccent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(l10n.dashboardReport,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface))),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ]),
      ),
    );
  }

  void _showSheet(BuildContext context) {
    final up   = context.read<UserProvider>();
    final auth = context.read<AuthController>();
    final user = auth.currentUser ?? up.user;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ReportSheet(onSend: (text) => _send(user, text)),
    );
  }

  Future<void> _send(User? user, String text) async {
    if (text.isEmpty) return;
    try {
      await DioClient().dio.post('/bug-report', data: {
        'description': text,
        'appVersion': '1.0.0',
        'platform': 'android',
        'logs': '=== USER ===\nkn=${user?.knotyNumber ?? ""}\n'
            'role=${user?.role.name ?? "unknown"}\n'
            '=== LOGS ===\n${AppLogger.instance.getLogs()}',
      });
    } catch (e) {
      debugPrint('[REPORT] $e');
    }
  }
}

// ── Language expand card ──────────────────────────────────────────────────────

class _LanguageExpandCard extends StatelessWidget {
  const _LanguageExpandCard();

  static const _langs = [
    ('de', '🇩🇪', 'Deutsch'),
    ('en', '🇬🇧', 'English'),
    ('ru', '🇷🇺', 'Русский'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n    = AppLocalizations.of(context)!;
    final current = context.watch<LocaleProvider>().locale.languageCode;
    final currentEntry = _langs.firstWhere(
        (e) => e.$1 == current, orElse: () => _langs.first);

    return _ExpandCard(
      icon: Icons.language_rounded,
      title: l10n.settingsLanguage,
      subtitle: '${currentEntry.$2} ${currentEntry.$3}',
      children: _langs.map((e) {
        final active = e.$1 == current;
        return GestureDetector(
          onTap: () =>
              context.read<LocaleProvider>().setLocale(Locale(e.$1)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFFE6B800).withValues(alpha: 0.08)
                  : Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: active
                    ? const Color(0xFFE6B800).withValues(alpha: 0.4)
                    : Colors.transparent,
              ),
            ),
            child: Row(children: [
              Text(e.$2, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(child: Text(e.$3,
                style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w500,
                  color: active ? const Color(0xFFE6B800) : Theme.of(context).colorScheme.onSurface))),
              if (active)
                const Icon(Icons.check_circle_rounded,
                    size: 18, color: Color(0xFFE6B800)),
            ]),
          ),
        );
      }).toList(),
    );
  }
}

// ── Report sheet ──────────────────────────────────────────────────────────────

class _ReportSheet extends StatefulWidget {
  final Future<void> Function(String text) onSend;
  const _ReportSheet({required this.onSend});
  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final _ctrl = TextEditingController();
  bool _sending = false;
  bool _sent    = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    await widget.onSend(text);
    if (!mounted) return;
    setState(() { _sending = false; _sent = true; });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n   = AppLocalizations.of(context)!;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4,
          decoration: BoxDecoration(color: cs.outline, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        Text(l10n.dashboardReport, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: cs.onSurface)),
        const SizedBox(height: 6),
        Text(l10n.dashboardReportHint, style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
        const SizedBox(height: 16),
        if (_sent)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text(l10n.dashboardReportSent, style: const TextStyle(color: Colors.green, fontSize: 15)),
            ]),
          )
        else ...[
          Container(
            decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
            child: TextField(
              controller: _ctrl, maxLines: 5, autofocus: true,
              style: TextStyle(fontSize: 15, color: cs.onSurface),
              decoration: InputDecoration(
                hintText: l10n.dashboardReportPlaceholder,
                hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _sending ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE6B800), foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: _sending
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(l10n.dashboardReportSend, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
          ),
        ],
        const SizedBox(height: 8),
      ]),
    );
  }
}