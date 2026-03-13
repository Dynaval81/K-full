import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:knoty/core/constants.dart';
import 'package:knoty/core/constants/app_constants.dart';

class AiryChatHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSearchPressed;
  final VoidCallback? onAvatarPressed;
  final bool showProfileIcon;

  const AiryChatHeader({
    super.key,
    required this.title,
    required this.onSearchPressed,
    this.onAvatarPressed,
    this.showProfileIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: Colors.white,
      elevation: 0.5,
      centerTitle: false,
      title: Text(
        title,
        style: TextStyle(
          color: AppColors.onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: AppColors.onSurface),
          onPressed: onSearchPressed,
        ),
        if (showProfileIcon)
          IconButton(
            icon: Icon(Icons.person_outline_rounded, color: AppColors.onSurface),
            onPressed: () => context.push(AppRoutes.settings),
          )
        else if (onAvatarPressed != null)
          GestureDetector(
            onTap: onAvatarPressed,
            child: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=my'),
              ),
            ),
          ),
      ],
    );
  }
}
