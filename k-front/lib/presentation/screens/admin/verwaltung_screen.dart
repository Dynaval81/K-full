import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:knoty/core/controllers/auth_controller.dart';
import 'package:knoty/core/enums/user_role.dart';
import 'package:knoty/l10n/app_localizations.dart';
import 'package:knoty/presentation/widgets/knoty_app_bar.dart';

class VerwaltungScreen extends StatelessWidget {
  const VerwaltungScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = context.watch<AuthController>().currentUser;
    final role = user?.role ?? UserRole.student;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: KnotyAppBar(title: l10n.verwaltungTitle),
      body: role == UserRole.schoolAdmin
          ? _SchoolAdminPanel()
          : _SuperAdminPanel(),
    );
  }
}

class _SchoolAdminPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(padding: const EdgeInsets.all(20), children: [
      _AdminTile(icon: Icons.person_add_rounded,       title: l10n.verwaltungActivateUsers,    subtitle: l10n.verwaltungActivateUsersSubtitle,    onTap: () {}),
      _AdminTile(icon: Icons.vpn_key_rounded,          title: l10n.verwaltungGenerateCodes,    subtitle: l10n.verwaltungGenerateCodesSubtitle,    onTap: () {}),
      _AdminTile(icon: Icons.people_rounded,           title: l10n.verwaltungUserList,         subtitle: l10n.verwaltungUserListSubtitle,         onTap: () {}),
    ]);
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _AdminTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(width: 44, height: 44,
          decoration: const BoxDecoration(color: Color(0xFFFFF8E1), shape: BoxShape.circle),
          child: Icon(icon, color: const Color(0xFFE6B800), size: 22)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

class _SuperAdminPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.admin_panel_settings_rounded, size: 56, color: Color(0xFFE6B800)),
        const SizedBox(height: 16),
        Text(l10n.verwaltungTitle, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(l10n.verwaltungSuperAdminHint,
          textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 16)),
      ]),
    ));
  }
}