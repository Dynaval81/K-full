import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:knoty/core/controllers/auth_controller.dart';
import 'package:knoty/core/constants/app_constants.dart';
import 'package:knoty/l10n/app_localizations.dart';
import 'package:knoty/providers/user_provider.dart';
import 'package:knoty/data/models/user_model.dart';

/// Единая шапка для всех экранов Knoty.
/// Использование:
///   appBar: KnotyAppBar(title: 'Chats')
///   — или в SliverAppBar через KnotyAppBar.sliver(...)
class KnotyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showAvatar;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  const KnotyAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showAvatar = true,
    this.leading,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(60 + (bottom?.preferredSize.height ?? 0));

  void _showProfileOverlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProfileSheet(
        user: context.read<AuthController>().currentUser ??
            context.read<UserProvider>().user,
        authController: context.read<AuthController>(),
        l10n: AppLocalizations.of(context)!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppBar(
      backgroundColor: cs.surface,
      elevation: 0,
      centerTitle: false,
      leading: leading,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
      ),
      actions: [
        if (actions != null) ...actions!,
        if (showAvatar)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => _showProfileOverlay(context),
              child: _AppBarAvatar(),
            ),
          ),
      ],
      bottom: bottom ?? PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: cs.outline,
        ),
      ),
    );
  }
}

// ── Profile Bottom Sheet (HAI3 "Knoty Airy Profile") ─────────────────────────
class _ProfileSheet extends StatelessWidget {
  final User? user;
  final AuthController authController;
  final AppLocalizations l10n;

  const _ProfileSheet({
    this.user,
    required this.authController,
    required this.l10n,
  });

  String _displayName() {
    final first = user?.firstName?.trim() ?? '';
    final last = user?.lastName?.trim() ?? '';
    if (first.isNotEmpty || last.isNotEmpty) return '$first $last'.trim();
    return user?.username.isNotEmpty == true ? user!.username : '—';
  }

  String _knDigits() {
    final kn = user?.knotyNumber ?? '';
    if (kn.isEmpty) return '';
    return kn.startsWith('KN-') ? kn.substring(3) : kn;
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l10n.comingSoon),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final nickname = user?.username ?? '';
    final email = user?.email ?? '';
    final schoolName = '—'; // TODO: resolve school name from user.schoolId

    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ───────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Header card ───────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(
                color: cs.outline.withOpacity(0.5),
                blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                // Avatar with gradient ring
                Stack(
                  children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE6B800), Color(0xFF1A1A1A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.all(2.5),
                      child: ClipOval(
                        child: user?.avatar != null && user!.avatar!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: user!.avatar!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) =>
                                    _GradientAvatar(_displayName()),
                                errorWidget: (_, __, ___) =>
                                    _GradientAvatar(_displayName()),
                              )
                            : _GradientAvatar(_displayName()),
                      ),
                    ),
                    // Camera badge
                    Positioned(
                      right: 0, bottom: 0,
                      child: GestureDetector(
                        onTap: () => _comingSoon(context),
                        child: Container(
                          width: 26, height: 26,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6B800),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              size: 13, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayName(),
                        style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700,
                          color: cs.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_knDigits().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(children: [
                            const TextSpan(
                              text: 'KN-',
                              style: TextStyle(
                                fontSize: 13, color: Color(0xFFBDBDBD),
                                fontWeight: FontWeight.w500),
                            ),
                            TextSpan(
                              text: _knDigits(),
                              style: const TextStyle(
                                fontSize: 13, color: Color(0xFFE6B800),
                                fontWeight: FontWeight.w700),
                            ),
                          ]),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Profile info tiles ────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(
                color: cs.outline.withOpacity(0.5),
                blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                _ProfileTile(
                  icon: Icons.alternate_email_rounded,
                  label: l10n.registerNicknameLabel,
                  value: nickname.isNotEmpty ? '@$nickname' : '—',
                  onTap: () => _comingSoon(context),
                ),
                _Divider(),
                _ProfileTile(
                  icon: Icons.mail_outline_rounded,
                  label: l10n.registerEmailLabel,
                  value: email.isNotEmpty ? email : '—',
                  onTap: () => _comingSoon(context),
                ),
                _Divider(),
                _ProfileTile(
                  icon: Icons.school_rounded,
                  label: l10n.schoolTitle,
                  value: schoolName,
                  actionIcon: Icons.swap_horiz_rounded,
                  onTap: () => _comingSoon(context),
                ),
              ],
            ),
          ),

          // ── Logout ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  if (context.mounted) context.go(AppRoutes.auth);
                  await authController.logout();
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text(l10n.dashboardLogout),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          ),

          SizedBox(height: 16 + bottomPad),
        ],
        ),
      ),
    );
  }
}

// ── Profile tile ──────────────────────────────────────────────────────────────
class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.value,
    this.actionLabel,
    this.actionIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFE6B800).withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: const Color(0xFFE6B800)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                    style: TextStyle(
                      fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(value,
                    style: TextStyle(
                      fontSize: 14, color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (actionIcon != null)
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(actionIcon!, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
              )
            else if (actionLabel != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(actionLabel!,
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
              )
            else
              Icon(Icons.edit_outlined,
                  size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(
    height: 1, indent: 70,
    color: Theme.of(context).colorScheme.outline);
}


// ── AppBar Avatar Button ──────────────────────────────────────────────────────
String _fullName(User? user) {
  if (user == null) return '?';
  final first = user.firstName?.trim() ?? '';
  final last = user.lastName?.trim() ?? '';
  if (first.isNotEmpty && last.isNotEmpty) return '$first $last';
  return user.username.isNotEmpty ? user.username : '?';
}

class _AppBarAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    User? user;
    try {
      user = context.watch<AuthController>().currentUser;
    } catch (_) {}

    final avatarUrl = user?.avatar;

    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: avatarUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => _GradientAvatar(_fullName(user)),
                errorWidget: (_, __, ___) => _GradientAvatar(_fullName(user)),
              )
            : _GradientAvatar(_fullName(user)),
      ),
    );
  }
}



// ── German Flag Avatar ───────────────────────────────────────────────────────
class _GradientAvatar extends StatelessWidget {
  final String name;
  const _GradientAvatar(this.name);

  List<String> _initials(String n) {
    final parts = n.trim().split(' ');
    if (parts.length >= 2) {
      return [parts[0][0].toUpperCase(), parts[1][0].toUpperCase()];
    }
    if (n.isNotEmpty) return [n[0].toUpperCase(), ''];
    return ['?', ''];
  }

  @override
  Widget build(BuildContext context) {
    final parts = _initials(name);
    return CustomPaint(
      painter: const _GermanFlagRingPainter(),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        margin: const EdgeInsets.all(3),
        child: Center(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: parts[0],
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (parts[1].isNotEmpty)
                  TextSpan(
                    text: parts[1],
                    style: const TextStyle(
                      color: Color(0xFFE6B800),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── German Flag Ring Painter ──────────────────────────────────────────────────
class _GermanFlagRingPainter extends CustomPainter {
  const _GermanFlagRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 3.0;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rect = Rect.fromCircle(
        center: center, radius: radius - strokeWidth / 2);

    paint.color = const Color(0xFF1A1A1A); // Schwarz
    canvas.drawArc(rect, -1.5708, 2.0944, false, paint);

    paint.color = const Color(0xFFDD0000); // Rot
    canvas.drawArc(rect, 0.5236, 2.0944, false, paint);

    paint.color = const Color(0xFFE6B800); // Gold
    canvas.drawArc(rect, 2.6180, 2.0944, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}