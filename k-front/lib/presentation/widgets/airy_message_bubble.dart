import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/services/chat_service.dart';
import '../../data/models/message_model.dart';

/// 💬 Airy Message Bubble - L4 UI Component
/// Airy design with different corner radius for message tail
class AiryMessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool showTime;
  final bool showStatus;

  const AiryMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showTime = true,
    this.showStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    final chatService = ChatService();
    final parsedText = chatService.parseMessageText(message.text);
    
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75, // 75% of screen width
      ),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // 💬 Message bubble
          Container(
            decoration: _buildMessageDecoration(isMe),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              child: Text(
                parsedText,
                style: AppTextStyles.body.copyWith(
                  color: isMe ? AppColors.onPrimary : AppColors.onSurface,
                  fontSize: 16, // Inter font size as requested
                  height: 1.4,
                ),
              ),
            ),
          ),
          
          // ⏰ Time and status
          if (showTime || (showStatus && isMe)) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (showTime)
                  Text(
                    chatService.formatMessageTime(message.timestamp),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                
                if (showStatus && isMe) ...[
                  const SizedBox(width: 4),
                  Text(
                    chatService.getMessageStatusIcon(message.status),
                    style: const TextStyle(
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 🎨 Build message decoration with different corner radii
  BoxDecoration _buildMessageDecoration(bool isMe) {
    return BoxDecoration(
      color: isMe ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(20),
        topRight: const Radius.circular(20),
        bottomLeft: Radius.circular(isMe ? 20 : 4), // Different radius for tail
        bottomRight: Radius.circular(isMe ? 4 : 20),  // Different radius for tail
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05), // Subtle shadow as requested
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      border: isMe 
          ? null 
          : Border.all(
              color: AppColors.onSurface.withOpacity(0.1),
              width: 0.5,
            ),
    );
  }
}

/// 💬 Airy Message Container - Full message with spacing
class AiryMessageContainer extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool showTimestamp;

  const AiryMessageContainer({
    super.key,
    required this.message,
    required this.isMe,
    this.showTimestamp = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // 📅 Date separator (if needed)
          if (showTimestamp && _shouldShowDateSeparator())
            _buildDateSeparator(),
          
          // 💬 Message bubble
          AiryMessageBubble(
            message: message,
            isMe: isMe,
            showTime: showTimestamp,
            showStatus: isMe,
          ),
        ],
      ),
    );
  }

  /// 📅 Check if date separator should be shown
  bool _shouldShowDateSeparator() {
    final now = DateTime.now();
    final messageDate = DateTime(
      message.timestamp.year,
      message.timestamp.month,
      message.timestamp.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    
    return messageDate.isBefore(today);
  }

  /// 📅 Build date separator
  Widget _buildDateSeparator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.onSurface.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _formatDate(message.timestamp),
        style: AppTextStyles.caption.copyWith(
          color: AppColors.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 📅 Format date for separator
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    
    if (date.day == now.day && 
        date.month == now.month && 
        date.year == now.year) {
      return 'Today';
    } else if (date.day == yesterday.day && 
               date.month == yesterday.month && 
               date.year == yesterday.year) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
