import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:knoty/constants/palette.dart';
import 'package:knoty/core/controllers/auth_controller.dart';
import 'package:knoty/core/enums/user_role.dart';
import 'package:knoty/l10n/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthController>().currentUser;
    _firstName = TextEditingController(text: user?.firstName ?? '');
    _lastName  = TextEditingController(text: user?.lastName ?? '');
    _firstName.addListener(_markDirty);
    _lastName.addListener(_markDirty);
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    // TODO: call PATCH /auth/me when API is ready
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.profileSaved),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1A1A1A),
      ),
    );
    setState(() => _dirty = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs   = Theme.of(context).colorScheme;
    final user = context.watch<AuthController>().currentUser;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: cs.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: cs.onSurface, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.profileTitle),
        centerTitle: true,
        actions: [
          if (_dirty)
            TextButton(
              onPressed: () => _save(context),
              child: Text(
                l10n.profileSave,
                style: TextStyle(
                  color: KPalette.gold,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Avatar ──────────────────────────────────────────────────────
          Center(
            child: Stack(
              children: [
                _Avatar(
                  firstName: user?.firstName,
                  lastName: user?.lastName,
                  size: 88,
                ),
                Positioned(
                  right: 0, bottom: 0,
                  child: GestureDetector(
                    onTap: () {}, // TODO: image picker
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: KPalette.gold,
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.surface, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          size: 15, color: KPalette.ink),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // KN Number chip
          if (user?.knotyNumber != null) ...[
            const SizedBox(height: 12),
            Center(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Clipboard.setData(ClipboardData(text: 'KN-${user!.knotyNumber}'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('KN-ID kopiert'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: KPalette.gold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: KPalette.gold.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'KN-',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: KPalette.gold.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        user!.knotyNumber,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: KPalette.gold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.copy_rounded, size: 13,
                          color: KPalette.gold.withOpacity(0.7)),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // ── Name fields ──────────────────────────────────────────────────
          _SectionCard(
            children: [
              _FieldRow(
                label: l10n.registerFirstName,
                controller: _firstName,
                hint: 'Max',
              ),
              _Divider(),
              _FieldRow(
                label: l10n.registerLastName,
                controller: _lastName,
                hint: 'Mustermann',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Read-only info ───────────────────────────────────────────────
          _SectionCard(
            children: [
              _InfoRow(
                label: l10n.profileEmail,
                value: user?.email ?? '—',
                icon: Icons.email_outlined,
              ),
              _Divider(),
              _InfoRow(
                label: l10n.profileRole,
                value: _roleLabel(user?.role, l10n),
                icon: Icons.badge_outlined,
              ),
              if (user?.school != null) ...[
                _Divider(),
                _InfoRow(
                  label: l10n.profileMySchool,
                  value: user!.school!,
                  icon: Icons.school_outlined,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // ── Actions ──────────────────────────────────────────────────────
          _SectionCard(
            children: [
              _ActionRow(
                icon: Icons.lock_outline_rounded,
                title: l10n.profileChangePassword,
                onTap: () {}, // TODO
              ),
              _Divider(),
              _ActionRow(
                icon: Icons.school_outlined,
                title: l10n.profileSchoolChange,
                onTap: () {}, // TODO
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _roleLabel(UserRole? role, AppLocalizations l10n) {
    switch (role) {
      case UserRole.teacher:     return 'Lehrer';
      case UserRole.parent:      return 'Elternteil';
      case UserRole.student:     return 'Schüler';
      case UserRole.schoolAdmin: return 'Schuladmin';
      case UserRole.superAdmin:  return 'Superadmin';
      default:                   return '—';
    }
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String? firstName;
  final String? lastName;
  final double size;
  const _Avatar({this.firstName, this.lastName, required this.size});

  String get _initials {
    final f = firstName?.isNotEmpty == true ? firstName![0] : '';
    final l = lastName?.isNotEmpty  == true ? lastName![0]  : '';
    return (f + l).toUpperCase().isEmpty ? '?' : (f + l).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: KPalette.gold.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: KPalette.gold.withOpacity(0.4), width: 2),
      ),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            fontSize: size * 0.35,
            fontWeight: FontWeight.w700,
            color: KPalette.gold,
          ),
        ),
      ),
    );
  }
}

// ── Internal widgets ──────────────────────────────────────────────────────────
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
    return Divider(
      height: 1, indent: 56, endIndent: 0,
      color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  const _FieldRow({required this.label, required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
              style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(fontSize: 15, color: cs.onSurface),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: cs.onSurfaceVariant.withOpacity(0.5)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _InfoRow({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: cs.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                Text(value,
                  style: TextStyle(fontSize: 15,
                      fontWeight: FontWeight.w500, color: cs.onSurface)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _ActionRow({required this.icon, required this.title, required this.onTap});

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
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: cs.primary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title,
                style: TextStyle(fontSize: 15,
                    fontWeight: FontWeight.w500, color: cs.onSurface)),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
