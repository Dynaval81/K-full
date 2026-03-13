import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../utils/glass_kit.dart';
import '../widgets/emoji_renderer.dart';

class EmojiPreviewOverlay extends StatefulWidget {
  final Widget child;
  
  const EmojiPreviewOverlay({required this.child});
  
  @override
  _EmojiPreviewOverlayState createState() => _EmojiPreviewOverlayState();
}

class _EmojiPreviewOverlayState extends State<EmojiPreviewOverlay> 
    with TickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  // Removed unused field: String? _currentEmoji;
  late AnimationController _previewController;
  Timer? _hideTimer;
  
  @override
  void initState() {
    super.initState();
    _previewController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }
  
  @override
  void dispose() {
    _hideTimer?.cancel();
    _previewController.dispose();
    _removeOverlay();
    super.dispose();
  }
  
  void showPreview(String emojiCode) {
    HapticFeedback.mediumImpact(); // Более ощутимый отклик, "поднятие" элемента над стеклом
    
    if (_overlayEntry != null) {
      _removeOverlay();
    }
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Center(
        child: GlassKit.liquidGlass(
          radius: 32,
          useBlur: true, // Здесь блюр НУЖЕН для акцента на смайле
          isDark: true, // Превью всегда лучше выглядит в темном стекле
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: EmojiRenderer.render(
              emojiCode, 
              EmojiSizes.preview, // Используем 48.0
              semanticLabel: 'Selected emoji preview',
            ),
          ),
        ),
      ),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
    _previewController.forward();
    
    // Haptic feedback
    HapticFeedback.lightImpact();
    
    // Memory Leak Guard - автоудаление через 2 секунды
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 2), () {
      _removeOverlay();
    });
  }
  
  void _removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      _previewController.reset();
    }
  }
  
  void hidePreview() {
    _hideTimer?.cancel();
    _removeOverlay();
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
