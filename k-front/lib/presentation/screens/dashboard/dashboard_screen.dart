import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:knoty/core/constants/app_constants.dart';
import 'package:knoty/core/controllers/auth_controller.dart';
import 'package:knoty/core/controllers/tab_visibility_controller.dart';
import 'package:knoty/core/enums/user_role.dart';
import 'package:knoty/core/utils/app_logger.dart';
import 'package:knoty/data/models/user_model.dart';
import 'package:knoty/providers/user_provider.dart';
import 'package:knoty/l10n/app_localizations.dart';
import 'package:knoty/locale_provider.dart';
import 'package:knoty/presentation/widgets/knoty_app_bar.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n     = AppLocalizations.of(context)!;
    final auth     = context.watch<AuthController>();
    final user     = auth.currentUser;
    final role     = user?.role ?? UserRole.student;
    final vis      = context.watch<TabVisibilityController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: KnotyAppBar(title: l10n.dashboardTitle),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

            // ── User info card ───────────────────────────────────
            _UserInfoCard(user: user, role: role),
            const SizedBox(height: 16),

            // ── Tab visibility — общие вкладки (у всех) ──────────
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
                // Role-specific toggles
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
            const SizedBox(height: 4),

            // ── Language ──────────────────────────────────────────
            _LanguageCard(),
            const SizedBox(height: 4),

            // ── App info ─────────────────────────────────────────
            _ExpandCard(
              icon: Icons.info_outline_rounded,
              title: l10n.dashboardAppInfo,
              children: [
                _InfoRow('App', 'Knoty'),
                _InfoRow('Version', '1.0.0 (1)'),
                _InfoRow('Build', '1'),
                _InfoRow('API', 'v1.0'),
              ],
            ),

            // ── Bug report ───────────────────────────────────────
            _ReportButton(user: user),
            const SizedBox(height: 8),

            // ── Logout ───────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await context.read<AuthController>().logout();
                  if (context.mounted) context.go(AppRoutes.auth);
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text(l10n.dashboardLogout),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ),
          ],
          ),  // Column
        ),
      ),
    );
  }

  /// Все значения базовых вкладок + роль-специфичных — для защиты от отключения последней
  List<bool> _baseTabValues(TabVisibilityController vis, UserRole role) {
    return [
      vis.showChatsTab,
      vis.showAiTab,
      vis.showScheduleTab,
      if (role.hasChildTab)    vis.showKindTab,
      if (role.hasMyClassesTab) vis.showClassesTab,
      if (role.hasManagementTab) vis.showVerwaltungTab,
    ];
  }
}

// ── User info card ────────────────────────────────────────────────────────────

class _UserInfoCard extends StatelessWidget {
  final User? user;
  final UserRole role;
  const _UserInfoCard({required this.user, required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        // Avatar circle
        Container(
          width: 52, height: 52,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFFE6B800), Color(0xFFFFD84D)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
          child: Center(child: Text(
            (user?.username ?? '?').substring(0, 1).toUpperCase(),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
          )),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(user?.username ?? '–',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
            overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(user?.email ?? '–',
            style: const TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
            overflow: TextOverflow.ellipsis),
        ])),
        // Role badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(role.displayName,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFE6B800))),
        ),
      ]),
    );
  }
}

// ── Expand card ───────────────────────────────────────────────────────────────

class _ExpandCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;

  const _ExpandCard({
    required this.icon,
    required this.title,
    required this.children,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
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
          leading: Icon(icon, color: const Color(0xFFE6B800), size: 24),
          title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
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
            color: const Color(0xFFE6B800).withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFFE6B800), size: 17),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87))),
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
        Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black)),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.bug_report_outlined, color: Colors.redAccent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(l10n.dashboardReport,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87))),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.black26),
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ReportSheet(onSend: (text) => _send(user, text)),
    );
  }

  Future<void> _send(User? user, String text) async {
    if (text.isEmpty) return;
    try {
      final token = await const FlutterSecureStorage().read(key: 'auth_token');
      final body = {
        'description': text,
        'appVersion': '1.0.0',
        'platform': 'android',
        'logs': '=== USER ===\nuser=${user?.username ?? "unknown"}\n'
            'email=${user?.email ?? "unknown"}\n'
            'kn=${user?.knotyNumber ?? ""}\n'
            '=== LOGS ===\n${AppLogger.instance.getLogs()}',
      };
      await http.post(
        Uri.parse('https://hypermax.duckdns.org/api/v1/bug-report'),
        headers: {'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('[REPORT] $e');
    }
  }
}

// ── Language card ─────────────────────────────────────────────────────────────

class _LanguageCard extends StatelessWidget {
  const _LanguageCard();

  static const _langs = [
    ('de', 'Deutsch', '🇩🇪'),
    ('en', 'English', '🇬🇧'),
    ('ru', 'Русский', '🇷🇺'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.watch<LocaleProvider>();
    final current = localeProvider.locale.languageCode;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE6B800).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.language_rounded, color: Color(0xFFE6B800), size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(l10n.settingsLanguage,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87))),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: _langs.map((entry) {
              final (code, label, flag) = entry;
              final active = current == code;
              return GestureDetector(
                onTap: () => context.read<LocaleProvider>().setLocale(Locale(code)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFFE6B800) : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('$flag $label',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : const Color(0xFF757575),
                    )),
                ),
              );
            }).toList(),
          ),
        ]),
      ),
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
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        Text(l10n.dashboardReport, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(l10n.dashboardReportHint, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 16),
        if (_sent)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Bericht gesendet', style: TextStyle(color: Colors.green, fontSize: 15)),
            ]),
          )
        else ...[
          Container(
            decoration: BoxDecoration(color: const Color(0xFFF1F3F5), borderRadius: BorderRadius.circular(16)),
            child: TextField(
              controller: _ctrl, maxLines: 5, autofocus: true,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
              decoration: const InputDecoration(
                hintText: 'Was ist passiert?',
                hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(14),
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
                : const Text('Senden', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
          ),
        ],
        const SizedBox(height: 8),
      ]),
    );
  }
}