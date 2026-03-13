import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:knoty/constants/app_colors.dart';
import 'package:knoty/core/controllers/auth_controller.dart';
import 'package:knoty/core/controllers/tab_visibility_controller.dart';
import 'package:knoty/core/enums/user_role.dart';
import 'package:knoty/core/constants/app_constants.dart';
import 'package:knoty/l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;
    final role = user?.role ?? UserRole.student;
    final visibility = context.watch<TabVisibilityController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.black87, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.settingsTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Вкладки ────────────────────────────────────────────
          _SectionCard(
            children: [
              _SectionTitle(l10n.settingsTabsTitle),
              _ToggleRow(
                icon: Icons.chat_bubble_outline_rounded,
                title: l10n.settingsTabChats,
                value: visibility.showChatsTab,
                onChanged: (v) => visibility.setChatsTab(v),
              ),
              _ToggleRow(
                icon: Icons.psychology_rounded,
                title: l10n.settingsTabAi,
                value: visibility.showAiTab,
                onChanged: (v) => visibility.setAiTab(v),
              ),
              _ToggleRow(
                icon: Icons.school_rounded,
                title: l10n.settingsTabSchool,
                value: visibility.showScheduleTab,
                onChanged: (v) => visibility.setScheduleTab(v),
              ),
              if (role.hasChildTab)
                _ToggleRow(
                  icon: Icons.child_care_rounded,
                  title: l10n.settingsTabKind,
                  value: visibility.showKindTab,
                  onChanged: (v) => visibility.setKindTab(v),
                ),
              if (role.hasMyClassesTab)
                _ToggleRow(
                  icon: Icons.class_rounded,
                  title: l10n.settingsTabClasses,
                  value: visibility.showClassesTab,
                  onChanged: (v) => visibility.setClassesTab(v),
                ),
              if (role.hasManagementTab)
                _ToggleRow(
                  icon: Icons.admin_panel_settings_rounded,
                  title: l10n.settingsTabVerwaltung,
                  value: visibility.showVerwaltungTab,
                  onChanged: (v) => visibility.setVerwaltungTab(v),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Аккаунт ──────────────────────────────────────────────
          _SectionCard(
            children: [
              _SettingsRow(
                icon: Icons.workspace_premium_outlined,
                title: l10n.settingsAccount,
                trailing: const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: Colors.black26),
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── О приложении ─────────────────────────────────────────
          _SectionCard(
            children: [
              _SettingsRow(
                icon: Icons.info_outline_rounded,
                title: l10n.dashboardAppInfo,
                trailing: Text(
                  '1.0.0',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Выйти ────────────────────────────────────────────────
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primaryBlue, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
    child: Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFFBDBDBD),
        letterSpacing: 0.8,
      ),
    ),
  );
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE6B800).withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFE6B800), size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFE6B800),
          ),
        ],
      ),
    );
  }
}