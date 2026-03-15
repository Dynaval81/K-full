import 'package:flutter/material.dart';

/// Shimmer skeleton loader — no external package needed.
///
/// Wrap any placeholder shape with [KnotyShimmer]:
/// ```dart
/// KnotyShimmer(
///   child: Container(width: double.infinity, height: 16,
///     decoration: BoxDecoration(color: Colors.white, borderRadius: ...)),
/// )
/// ```
///
/// Or use the prebuilt [KnotyChatSkeleton], [KnotyListSkeleton], etc.
class KnotyShimmer extends StatefulWidget {
  final Widget child;

  const KnotyShimmer({super.key, required this.child});

  @override
  State<KnotyShimmer> createState() => _KnotyShimmerState();
}

class _KnotyShimmerState extends State<KnotyShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base   = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8);
    final shine  = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5);

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [base, shine, base],
            stops: const [0.0, 0.5, 1.0],
            transform: _SlideGradient(_anim.value),
          ).createShader(bounds),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlideGradient extends GradientTransform {
  final double value;
  const _SlideGradient(this.value);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * value * 0.5, 0, 0);
  }
}

// ── Prebuilt skeletons ────────────────────────────────────────────────────────

/// Skeleton for a chat list (3–5 chat rows).
class KnotyChatListSkeleton extends StatelessWidget {
  final int count;
  const KnotyChatListSkeleton({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (_, i) => const _ChatRowSkeleton(),
    );
  }
}

class _ChatRowSkeleton extends StatelessWidget {
  const _ChatRowSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8);

    return KnotyShimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar circle
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _Bone(height: 14, color: bg),
                      ),
                      const SizedBox(width: 32),
                      _Bone(width: 36, height: 11, color: bg),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _Bone(height: 12, color: bg, widthFactor: 0.7),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for a vertical list of cards (e.g. users, classes, codes).
class KnotyCardListSkeleton extends StatelessWidget {
  final int count;
  const KnotyCardListSkeleton({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => const _CardSkeleton(),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8);
    final card   = isDark ? const Color(0xFF1C1C1C) : Colors.white;

    return KnotyShimmer(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Bone(height: 13, color: bg, widthFactor: 0.6),
                  const SizedBox(height: 6),
                  _Bone(height: 11, color: bg, widthFactor: 0.4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Generic shimmer bone (rectangle).
class _Bone extends StatelessWidget {
  final double height;
  final double? width;
  final double widthFactor;
  final Color color;

  const _Bone({
    required this.height,
    required this.color,
    this.width,
    this.widthFactor = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: width != null ? null : widthFactor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(height / 2),
        ),
      ),
    );
  }
}
