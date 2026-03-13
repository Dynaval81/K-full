import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../utils/glass_kit.dart';
import '../theme_provider.dart';

class VTalkInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback? onEmojiTap;
  final VoidCallback? onAttachTap;
  final VoidCallback? onCameraTap;
  final VoidCallback? onMicTap;
  final bool isMicMode;

  const VTalkInputField({
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.3),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Кнопка дополнительно
            GestureDetector(
              onTap: () => _showAttachmentMenu(context, isDark),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
                ),
                child: Icon(
                  Icons.add_circle_outline,
                  color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.54),
                  size: 24,
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Поле ввода
            Expanded(
              child: GlassKit.liquidGlass(
                radius: 24,
                isDark: isDark,
                opacity: 0.1,
                useBlur: true,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Написать сообщение...',
                    hintStyle: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.38) : Colors.black.withValues(alpha: 0.38)),
                    filled: true,
                    fillColor: Colors.transparent,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: 5,
                  minLines: 1,
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Кнопка эмодзи
            GestureDetector(
              onTap: onEmojiTap,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
                ),
                child: Icon(
                  Icons.emoji_emotions_outlined,
                  color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.54),
                  size: 24,
                ),
              ),
            ),
            
            const SizedBox(width: 4),
            
            // Кнопка отправки/микрофон
            GestureDetector(
              onTap: isMicMode ? onMicTap : onSend,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.blue,
                ),
                child: Icon(
                  isMicMode ? Icons.mic : Icons.send,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentMenu(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassKit.liquidGlass(
        radius: 20,
        isDark: isDark,
        opacity: 0.15,
        useBlur: true,
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Заголовок
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Прикрепить',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Опции
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1,
                children: [
                  _buildAttachmentOption(
                    context,
                    Icons.photo_library,
                    'Галерея',
                    () => _pickImage(context),
                    isDark,
                  ),
                  _buildAttachmentOption(
                    context,
                    Icons.camera_alt,
                    'Камера',
                    () => _openCamera(context),
                    isDark,
                  ),
                  _buildAttachmentOption(
                    context,
                    Icons.attach_file,
                    'Файл',
                    () => _pickFile(context),
                    isDark,
                  ),
                  _buildAttachmentOption(
                    context,
                    Icons.location_on,
                    'Место',
                    () => _shareLocation(context),
                    isDark,
                  ),
                  _buildAttachmentOption(
                    context,
                    Icons.poll,
                    'Опрос',
                    () => _createPoll(context),
                    isDark,
                  ),
                  _buildAttachmentOption(
                    context,
                    Icons.contact_page,
                    'Контакт',
                    () => _shareContact(context),
                    isDark,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
            ),
            child: Icon(
              icon,
              color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.54),
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.54),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    // TODO: Обработка изображения
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Галерея')),
    );
  }

  Future<void> _openCamera(BuildContext context) async {
    // TODO: Открыть камеру
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Камера')),
    );
  }

  Future<void> _pickFile(BuildContext context) async {
    // TODO: Обработка файла
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Файл')),
    );
  }

  Future<void> _shareLocation(BuildContext context) async {
    // TODO: Геолокация
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Геолокация')),
    );
  }

  Future<void> _createPoll(BuildContext context) async {
    // TODO: Создание опроса
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Создание опроса')),
    );
  }

  Future<void> _shareContact(BuildContext context) async {
    // TODO: Поделиться контактом
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Поделиться контактом')),
    );
  }
}
