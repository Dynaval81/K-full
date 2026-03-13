import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:knoty/core/controllers/auth_controller.dart';
import 'package:knoty/core/constants/app_constants.dart';
import 'package:knoty/providers/user_provider.dart';
import 'package:knoty/theme_provider.dart';
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
    final user = context.read<AuthController>().currentUser ??
        context.read<UserProvider>().user;
    final themeProvider = context.read<ThemeProvider>();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'profile',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        final curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: _ProfileOverlay(user: user, themeProvider: themeProvider),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      leading: leading,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
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
          color: Colors.black.withOpacity(0.06),
        ),
      ),
    );
  }
}

// ── Profile Overlay ───────────────────────────────────────────────────────────
class _ProfileOverlay extends StatelessWidget {
  final User? user;
  final ThemeProvider themeProvider;

  const _ProfileOverlay({this.user, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: Colors.black.withOpacity(0.25)),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 60,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar + info
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: Row(
                      children: [
                        _UserAvatarWidget(
                          user: user,
                          size: 56,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '@${user?.username ?? '—'}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              if (user?.email.isNotEmpty == true) ...[
                                const SizedBox(height: 2),
                                Text(
                                  user!.email,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (user?.knotyNumber.isNotEmpty == true) ...[
                                const SizedBox(height: 2),
                                Text(
                                  user!.knotyNumber.startsWith('KN-')
                                      ? user!.knotyNumber
                                      : 'KN-${user!.knotyNumber}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFE6B800),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Change photo
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.camera_alt_outlined,
                        size: 18, color: Colors.grey.shade600),
                    title: const Text('Profilbild ändern',
                        style: TextStyle(fontSize: 14)),
                    onTap: () {
                      Navigator.of(context).pop();
                      // TODO: image picker
                    },
                  ),

                  const Divider(height: 1),

                  // Settings
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.settings_outlined,
                        size: 18, color: Colors.grey.shade600),
                    title: const Text('Einstellungen',
                        style: TextStyle(fontSize: 14)),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push(AppRoutes.settings);
                    },
                  ),

                  // Logout
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.logout_rounded,
                        size: 18, color: Colors.redAccent),
                    title: const Text('Abmelden',
                        style: TextStyle(
                            fontSize: 14, color: Colors.redAccent)),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await context.read<AuthController>().logout();
                      if (context.mounted) context.go(AppRoutes.auth);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
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

// ── User Avatar Widget ────────────────────────────────────────────────────────
class _UserAvatarWidget extends StatelessWidget {
  final User? user;
  final double size;

  const _UserAvatarWidget({this.user, required this.size});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user?.avatar;
    return Container(
      width: size,
      height: size,
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