import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:knoty/core/constants.dart';
import 'package:knoty/core/controllers/chat_controller.dart';
import 'package:knoty/core/services/chat_service.dart';
import 'package:knoty/data/models/chat_room.dart';
import 'package:knoty/data/mock/mock_messages.dart';
import 'package:knoty/presentation/screens/chat/chat_room_screen.dart';

class AiryChatListItem extends StatefulWidget {
  final ChatRoom chatRoom;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool showUnreadIndicator;

  const AiryChatListItem({
    super.key,
    required this.chatRoom,
    this.onTap,
    this.isSelected = false,
    this.showUnreadIndicator = true,
  });

  @override
  State<AiryChatListItem> createState() => _AiryChatListItemState();
}

class _AiryChatListItemState extends State<AiryChatListItem> {
  String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatController>(
      builder: (context, chatController, _) {
        final unreadCount = chatController.getUnreadCount(widget.chatRoom.id);
        return _buildContent(context, unreadCount);
      },
    );
  }

  Widget _buildContent(BuildContext context, int unreadCount) {
    final chatService = ChatService();
    final title = chatService.generateChatTitle(widget.chatRoom);
    final lastMsg = mockMessages.where((m) => m.chatId == widget.chatRoom.id).toList().lastOrNull;
    final preview = lastMsg?.text ?? "No messages yet";
    final lastMessage = widget.chatRoom.messages?.isNotEmpty == true ? widget.chatRoom.messages!.last : null;
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: widget.isSelected ? const Color(0xFF00A3FF).withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppBorderRadius.button),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(context, CupertinoPageRoute(builder: (context) => ChatRoomScreen(chat: widget.chatRoom)));
          },
          borderRadius: BorderRadius.circular(AppBorderRadius.button),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildSquircleAvatar(widget.chatRoom),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title, style: AppTextStyles.body.copyWith(fontSize: 16.0, fontWeight: FontWeight.bold, color: widget.isSelected ? AppColors.primary : AppColors.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(preview, style: AppTextStyles.body.copyWith(color: Colors.grey, fontSize: 15.0), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 72.0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (lastMessage != null)
                        Text(
                          chatService.formatMessageTime(lastMessage.timestamp),
                          style: AppTextStyles.body.copyWith(
                            color: const Color(0xFF757575),
                            fontSize: 12.0,
                          ),
                        ),
                      const SizedBox(height: 4),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A3FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10)),
                        )
                      else if (lastMessage != null)
                        Icon(
                          Icons.done_all,
                          color: const Color(0xFF00A3FF),
                          size: 17,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 📷 Build squircle avatar
  Widget _buildSquircleAvatar(ChatRoom chatRoom) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: CircleAvatar(
        radius: 20, // Unified radius
        backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=${chatRoom.name}'),
      ),
    );
  }

  /// 📝 Get initials from title
  String _getInitials(String title) {
    final parts = title.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }
}

/// 📱 Airy Chat List Separator (16px spacing only)
class AiryChatListSeparator extends StatelessWidget {
  const AiryChatListSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 16); // Only spacing, no divider lines
  }
}
