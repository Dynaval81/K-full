import 'package:flutter/material.dart';
import 'dart:convert'; // 🚨 НОВОЕ: Для декодирования Unicode
import '../utils/glass_kit.dart';
import '../theme_provider.dart';
import '../widgets/emoji_renderer.dart';
import 'package:provider/provider.dart';

class VTalkMessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String? time;
  final Map<String, int>? reactions;
  final Map<String, dynamic>? replyTo;
  final bool isDeleted;
  final VoidCallback? onReply;
  final VoidCallback? onReact;
  final VoidCallback? onEdit;
  final Function(String emoji)? onAddReaction;
  final VoidCallback? onDelete;

  const VTalkMessageBubble({
    Key? key,
    required this.text,
    required this.isMe,
    this.time,
    this.reactions,
    this.replyTo,
    this.isDeleted = false,
    this.onReply,
    this.onReact,
    this.onEdit,
    this.onAddReaction,
    this.onDelete,
  }) : super(key: key);

  // 🚨 НОВОЕ: Функция для обработки текста с эмодзи (с декодированием)
  Widget _buildTextWithEmojis(String text, TextStyle style) {
    String decodedText = text;
    try {
      // 🚨 Декодируем Unicode-последовательности, если они пришли строкой
      decodedText = jsonDecode('"$decodedText"'); 
    } catch (e) {
      decodedText = text; // 🚨 Если не получилось, оставляем как есть
    }

    return Text(
      decodedText,
      style: style.copyWith(
        fontFamily: 'Roboto', // 🚨 Шрифт поддерживающий Emoji
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Ответ на сообщение
          if (replyTo != null) _buildReplyPreview(context, isDark),
          
          // Основное сообщение
          GestureDetector(
            onLongPress: () => _showMessageActions(context),
            child: GlassKit.liquidGlass(
              radius: 18,
              isDark: isDark,
              opacity: isMe ? 0.15 : 0.08,
              useBlur: true,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Текст сообщения
                    if (isDeleted)
                      Text(
                        'Сообщение удалено',
                        style: TextStyle(
                          color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.45),
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                        ),
                      )
                    else
                      _buildTextWithEmojis(
                        text,
                        TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                    
                    // Время
                    if (time != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        time!,
                        style: TextStyle(
                          color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.45),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          
          // Реакции
          if (reactions != null && reactions!.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildReactions(context, isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildReplyPreview(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe 
            ? Colors.blue.withValues(alpha: 0.3)
            : (isDark ? Colors.white.withValues(alpha: 0.24) : Colors.black.withValues(alpha: 0.12)),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.reply,
            size: 16,
            color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.45),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              replyTo!['text'] as String? ?? '...',
              style: TextStyle(
                color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.45),
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactions(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: reactions!.entries.map((entry) {
          final emoji = entry.key;
          final count = entry.value;
          
          return GestureDetector(
            onTap: () => onReact?.call(),
            child: GlassKit.liquidGlass(
              radius: 12,
              isDark: isDark,
              opacity: 0.1,
              useBlur: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      emoji,
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (count > 1) ...[
                      const SizedBox(width: 2),
                      Text(
                        count.toString(),
                        style: TextStyle(
                          color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.54),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showMessageActions(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassKit.liquidGlass(
        radius: 20,
        isDark: isDark,
        opacity: 0.15,
        useBlur: true,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Основные действия
                ListTile(
                  leading: const Icon(Icons.reply),
                  title: const Text('Ответить'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.pop(context);
                    onReply?.call();
                  },
                ),
                if (isMe)
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Редактировать'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onTap: () {
                      Navigator.pop(context);
                      onEdit?.call();
                    },
                  ),
                if (isMe)
                  ListTile(
                    leading: const Icon(Icons.delete),
                    title: const Text('Удалить'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onTap: () {
                      Navigator.pop(context);
                      onDelete?.call();
                    },
                  ),
                
                const SizedBox(height: 12),
                const Divider(height: 8),
                const SizedBox(height: 12),
                
                // Реакции (8 основных)
                Text(
                  'Реагировать',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: ['😊', '😎', '👍', '❤️', '😂', '🔥', '🎉', '💯'].map((emoji) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        onAddReaction?.call(emoji);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                        ),
                        child: Text(emoji, style: const TextStyle(fontSize: 20)),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 8),
                // Add more reactions
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onReact?.call();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                      ),
                      child: const Text('➕', style: TextStyle(fontSize: 18)),
                    ),
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
