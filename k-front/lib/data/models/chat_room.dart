// v1.1.3
import 'package:knoty/data/models/message_model.dart';

enum ChatType {
  personal,
  classGroup,
  schoolGroup;

  bool get requiresVerification =>
      this == ChatType.classGroup || this == ChatType.schoolGroup;
}

class ChatRoom {
  final String id;
  final String? name;
  final ChatType type;
  final bool isOnline;
  int unread;
  final String? lastMessage;
  final List<Map<String, dynamic>>? participants;
  final List<MessageModel>? messages;
  final DateTime? lastActivity;
  final String? schoolId;
  final String? schoolName;
  final String? classId;
  final String? className;

  ChatRoom({
    required this.id,
    this.name,
    this.type = ChatType.personal,
    this.isOnline = true,
    this.unread = 0,
    this.lastMessage,
    this.participants,
    this.messages,
    this.lastActivity,
    this.schoolId,
    this.schoolName,
    this.classId,
    this.className,
  });

  bool get isGroup => type == ChatType.classGroup || type == ChatType.schoolGroup;
  bool get isClassGroup => type == ChatType.classGroup;

  // Алиас для совместимости с chats_screen
  DateTime? get lastMessageTime => lastActivity;

  // Personal = nicht group
  bool get isPersonal => !isGroup;

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    ChatType type = ChatType.personal;
    if (map['isClassGroup'] == true) type = ChatType.classGroup;
    else if (map['isGroup'] == true) type = ChatType.schoolGroup;
    return ChatRoom(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? map['title'] ?? '',
      type: type,
      isOnline: map['isOnline'] ?? true,
      unread: map['unread'] ?? 0,
      lastMessage: map['lastMessage']?.toString(),
      lastActivity: map['lastActivity'] != null
          ? DateTime.tryParse(map['lastActivity'].toString())
          : null,
      schoolId: map['schoolId']?.toString(),
      schoolName: map['schoolName']?.toString(),
      classId: map['classId']?.toString(),
      className: map['className']?.toString(),
    );
  }

  ChatRoom copyWith({
    String? id,
    String? name,
    ChatType? type,
    bool? isOnline,
    int? unread,
    String? lastMessage,
    List<Map<String, dynamic>>? participants,
    List<MessageModel>? messages,
    DateTime? lastActivity,
    String? schoolId,
    String? schoolName,
    String? classId,
    String? className,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isOnline: isOnline ?? this.isOnline,
      unread: unread ?? this.unread,
      lastMessage: lastMessage ?? this.lastMessage,
      participants: participants ?? this.participants,
      messages: messages ?? this.messages,
      lastActivity: lastActivity ?? this.lastActivity,
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      classId: classId ?? this.classId,
      className: className ?? this.className,
    );
  }
}