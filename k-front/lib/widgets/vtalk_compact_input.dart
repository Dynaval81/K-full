import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../utils/glass_kit.dart';
import '../theme_provider.dart';

class VTalkCompactInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback? onEmojiTap;
  final VoidCallback? onAttachTap;
  final VoidCallback? onCameraTap;
  final VoidCallback? onMicTap;
  final bool isMicMode;

  const VTalkCompactInput({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    this.onEmojiTap,
    this.onAttachTap,
    this.onCameraTap,
    this.onMicTap,
    this.isMicMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.1),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Поле ввода с иконками ВНУТРИ (одна строка, высота контролируется)
            Expanded(
              child: GlassKit.liquidGlass(
                radius: 20,
                isDark: isDark,
                opacity: 0.1,
                useBlur: true,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Сообщение...',
                    hintStyle: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.38) : Colors.black.withValues(alpha: 0.38), fontSize: 14),
                    filled: true,
                    fillColor: Colors.transparent,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    // Иконки ВНУТРИ поля
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Эмодзи
                          GestureDetector(
                            onTap: onEmojiTap,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(
                                Icons.emoji_emotions_outlined,
                                color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.6),
                                size: 24,
                              ),
                            ),
                          ),
                          // Разделитель
                          Container(
                            width: 1,
                            height: 24,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.2),
                          ),
                          // Прикрепление
                          GestureDetector(
                            onTap: () => _showAttachmentMenu(context, isDark),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(
                                Icons.add_circle_outline,
                                color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.6),
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: isMicMode ? onMicTap : onSend,
                        child: Icon(
                          isMicMode ? Icons.mic : Icons.send,
                          color: Colors.blue,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  maxLines: 1,
                  minLines: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentMenu(BuildContext context, bool isDark) {
    HapticFeedback.mediumImpact(); // Тактильный отклик при открытии

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black45, // Чуть сильнее затемняем фон чата
      isScrollControlled: true,
      useSafeArea: true,
      // УБИРАЕМ constraints - даем меню полную высоту
      builder: (context) => GlassKit.liquidGlass(
        radius: 32, // Увеличиваем скругление как в Mercury Action Menu
        isDark: isDark,
        opacity: 0.15,
        useBlur: true,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7, // ОГРАНИЧИВАЕМ ВНУТРИ КОНТЕЙНЕРА
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Заголовок в стиле Mercury
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Прикрепить',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            HapticFeedback.lightImpact(); // Тактильный отклик на закрытие
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.close, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Mercury стиль сетки вложений 2x3
                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildUltraAttachOption(context, Icons.photo_library_rounded, "Gallery", Colors.blueAccent, isDark),
                      _buildUltraAttachOption(context, Icons.camera_alt_rounded, "Camera", Colors.pinkAccent, isDark),
                      _buildUltraAttachOption(context, Icons.insert_drive_file_rounded, "File", Colors.amberAccent, isDark),
                      _buildUltraAttachOption(context, Icons.location_on_rounded, "Place", Colors.greenAccent, isDark),
                      _buildUltraAttachOption(context, Icons.headset_rounded, "Music", Colors.purpleAccent, isDark),
                      _buildUltraAttachOption(context, Icons.contact_page_rounded, "Contact", Colors.cyanAccent, isDark),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUltraAttachOption(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    bool isDark,
  ) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        // Логика нажатия
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(isDark ? 0.15 : 0.1),
              // Внутреннее свечение (неоновое)
              border: Border.all(
                color: color.withOpacity(0.4),
                width: 1.5,
              ),
              // Неоновое свечение снаружи
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 16,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

}
