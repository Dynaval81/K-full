import 'package:flutter/material.dart';
import '../utils/glass_kit.dart';
import '../constants/app_constants.dart';

class VtalkUnifiedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isDark;
  final VoidCallback? onAvatarTap;
  final List<Widget>? actions;
  final double elevation;

  const VtalkUnifiedAppBar({
    Key? key,
    required this.title,
    required this.isDark,
    this.onAvatarTap,
    this.actions,
    this.elevation = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GlassKit.liquidGlass(
      radius: 0,
      isDark: isDark,
      opacity: 0.08,
      useBlur: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: elevation,
          leading: GestureDetector(
            onTap: onAvatarTap,
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Image.network(
                  "${AppConstants.defaultAvatarUrl}?u=profile",
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Icon(
                    Icons.person,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ),
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          centerTitle: false,
          actions: actions ?? [
            IconButton(
              icon: Icon(Icons.more_vert, color: isDark ? Colors.white70 : Colors.black54),
              onPressed: () {},
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
