import 'package:knoty/data/models/chat_room.dart';

/// Data layer model for chat list state (HAI3).
/// Holds unread count and exposes [markAsRead] for the controller to call.
class ChatModel {
  final String id;
  final String? name;
  final bool isGroup;
  final bool isOnline;
  int unreadCount;
  final DateTime? lastActivity;

  ChatModel({
    required this.id,
    this.name,
    this.isGroup = false,
    this.isOnline = true,
    this.unreadCount = 0,
    this.lastActivity,
  });

  /// Sets unread count to 0 (data-layer contract for "mark as read").
  void markAsRead() {
    unreadCount = 0;
  }

  factory ChatModel.fromChatRoom(ChatRoom room) {
    return ChatModel(
      id: room.id,
      name: room.name,
      isGroup: room.isGroup,
      isOnline: room.isOnline,
      unreadCount: room.unread,
      lastActivity: room.lastActivity,
    );
  }
}
