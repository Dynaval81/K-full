import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:knoty/l10n/app_localizations.dart';

/// Универсальная обёртка для заблокированного функционала.
/// Показывает размытый [child] с замком поверх если [isLocked] == true.
class LockedFeatureWrapper extends StatelessWidget {
  final bool isLocked;
  final Widget child;
  final String? title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const LockedFeatureWrapper({
    super.key,
    required this.isLocked,
    required this.child,
    this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLocked) return child;
    final l10n = AppLocalizations.of(context)!;
    final resolvedTitle    = title    ?? l10n.lockedDefaultTitle;
    final resolvedSubtitle = subtitle ?? l10n.lockedDefaultSubtitle;

    return Stack(children: [
      IgnorePointer(child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: child,
      )),
      Positioned.fill(child: Container(color: Colors.white.withOpacity(0.55))),
      Center(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: const BoxDecoration(color: Color(0xFFFFF8E1), shape: BoxShape.circle),
            child: const Icon(Icons.lock_outline_rounded, size: 34, color: Color(0xFFE6B800)),
          ),
          const SizedBox(height: 20),
          Text(resolvedTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 10),
          Text(resolvedSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Color(0xFF9E9E9E), height: 1.5)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(color: const Color(0xFFE6B800), borderRadius: BorderRadius.circular(24)),
                child: Text(actionLabel!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ],
        ]),
      )),
    ]);
  }
}