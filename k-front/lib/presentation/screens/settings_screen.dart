import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:knoty/core/controllers/auth_controller.dart';
import 'package:knoty/core/constants/app_constants.dart';
import 'package:knoty/l10n/app_localizations.dart';
import 'package:knoty/locale_provider.dart';
import 'package:knoty/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n   = AppLocalizations.of(context)!;
    final cs     = Theme.of(context).colorScheme;
    final theme  = context.watch<ThemeProvider>();
    final locale = context.watch<LocaleProvider>();

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: cs.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: cs.onSurface, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.settingsTitle),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Оформление ───────────────────────────────────────────────────
          _SectionCard(
            children: [
              // Dark / Light toggle
              _SettingsRow(
                icon: theme.isDarkMode
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                title: l10n.settingsTheme,
                trailing: _ThemeSegment(theme: theme, l10n: l10n),
              ),
              _Divider(),
              // Language
              _SettingsRow(
                icon: Icons.language_rounded,
                title: l10n.settingsLanguage,
                trailing: _LangSegment(locale: locale),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Аккаунт ──────────────────────────────────────────────────────
          _SectionCard(
            children: [
              _SettingsRow(
                icon: Icons.person_outline_rounded,
                title: l10n.settingsAccount,
                trailing: Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: cs.onSurfaceVariant),
                onTap: () => context.push('/profile'),
              ),
              _Divider(),
              _SettingsRow(
                icon: Icons.camera_alt_outlined,
                title: l10n.profileChangePhoto,
                trailing: Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: cs.onSurfaceVariant),
                onTap: () {},
              ),
              _Divider(),
              _SettingsRow(
                icon: Icons.notifications_outlined,
                title: l10n.settingsNotifications,
                trailing: Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: cs.onSurfaceVariant),
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── О приложении ─────────────────────────────────────────────────
          _SectionCard(
            children: [
              _SettingsRow(
                icon: Icons.info_outline_rounded,
                title: l10n.dashboardAppInfo,
                trailing: Text(
                  '1.0.0',
                  style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Выйти ────────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () async {
                if (context.mounted) context.go(AppRoutes.auth);
                await context.read<AuthController>().logout();
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

// ── Theme toggle (Hell / Dunkel) ─────────────────────────────────────────────
class _ThemeSegment extends StatelessWidget {
  final ThemeProvider theme;
  final AppLocalizations l10n;
  const _ThemeSegment({required this.theme, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final isDark = theme.isDarkMode;
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Seg(
            label: l10n.settingsThemeLight,
            icon: Icons.light_mode_rounded,
            selected: !isDark,
            onTap: () { if (isDark) theme.toggleTheme(); },
          ),
          _Seg(
            label: l10n.settingsThemeDark,
            icon: Icons.dark_mode_rounded,
            selected: isDark,
            onTap: () { if (!isDark) theme.toggleTheme(); },
          ),
        ],
      ),
    );
  }
}

class _Seg extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _Seg({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? cs.primary.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14,
                color: selected ? cs.primary : cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? cs.primary : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Language selector ────────────────────────────────────────────────────────
class _LangSegment extends StatelessWidget {
  final LocaleProvider locale;
  const _LangSegment({required this.locale});

  static const _langs = ['de', 'en', 'ru'];
  static const _labels = {'de': 'DE', 'en': 'EN', 'ru': 'RU'};

  @override
  Widget build(BuildContext context) {
    final cs      = Theme.of(context).colorScheme;
    final current = locale.locale.languageCode;
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _langs.map((code) {
          final sel = current == code;
          return GestureDetector(
            onTap: () => locale.setLocale(Locale(code)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: sel ? cs.primary.withOpacity(0.18) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _labels[code]!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  color: sel ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Internal widgets ─────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
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

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Divider(
      height: 1,
      indent: 56,
      endIndent: 0,
      color: cs.outline.withOpacity(0.5),
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
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: cs.primary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
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
