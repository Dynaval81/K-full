// v1.1.2
import 'package:knoty/data/models/message_model.dart';

class ChatRoom {
  final String id;
  final String? name;
  final bool isGroup;
  final bool isClassGroup;
  final bool isOnline;
  int unread;
  final String? lastMessage;
  final List<Map<String, dynamic>>? participants;
  final List<MessageModel>? messages;
  final DateTime? lastActivity;

  ChatRoom({
    required this.id,
    this.name,
    this.isGroup = false,
    this.isClassGroup = false,
    this.isOnline = true,
    this.unread = 0,
    this.lastMessage,
    this.participants,
    this.messages,
    this.lastActivity,
  });

  // Алиас для совместимости с chats_screen
  DateTime? get lastMessageTime => lastActivity;

  // Personal = nicht group
  bool get isPersonal => !isGroup;

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? map['title'] ?? '',
      isGroup: map['isGroup'] ?? false,
      isClassGroup: map['isClassGroup'] ?? false,
      isOnline: map['isOnline'] ?? true,
      unread: map['unread'] ?? 0,
      lastMessage: map['lastMessage'],
    );
  }

  ChatRoom copyWith({
    String? id,
    String? name,
    bool? isGroup,
    bool? isClassGroup,
    bool? isOnline,
    int? unread,
    String? lastMessage,
    List<Map<String, dynamic>>? participants,
    List<MessageModel>? messages,
    DateTime? lastActivity,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      isGroup: isGroup ?? this.isGroup,
      isClassGroup: isClassGroup ?? this.isClassGroup,
      isOnline: isOnline ?? this.isOnline,
      unread: unread ?? this.unread,
      lastMessage: lastMessage ?? this.lastMessage,
      participants: participants ?? this.participants,
      messages: messages ?? this.messages,
      lastActivity: lastActivity ?? this.lastActivity,
    );
  }
}