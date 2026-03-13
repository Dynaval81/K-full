enum MessageType {
  text,
  image,
  video,
  audio,
  file,
  sticker,
  system,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class MessageModel {
  final String id;
  final String text;
  final String? chatId; // Made nullable
  final bool isMe;
  final DateTime timestamp;
  final Map<String, int>? reactions;
  final MessageModel? replyTo;
  final bool isDeleted;
  final List<String>? urls;
  final String? imageUrl;
  final MessageType type;
  final MessageStatus status;
  final bool isRead;
  final String? senderId;

  MessageModel({
    required this.id,
    required this.text,
    this.chatId,
    this.isMe = false,
    required this.timestamp,
    required this.status,
    this.senderId,
    this.isRead = false,
    this.reactions,
    this.replyTo,
    this.isDeleted = false,
    this.urls,
    this.imageUrl,
    this.type = MessageType.text,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      text: json['text'] as String,
      chatId: json['chatId'] as String, // Added
      isMe: json['isMe'] as bool? ?? false,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString() == 'MessageStatus.${json['status']}',
        orElse: () => MessageStatus.sent,
      ),
      senderId: json['senderId'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      reactions: (json['reactions'] as Map<String, dynamic>?)?.cast<String, int>(),
      replyTo: json['replyTo'] != null 
        ? MessageModel.fromJson(json['replyTo'] as Map<String, dynamic>)
        : null,
      isDeleted: json['isDeleted'] as bool? ?? false,
      urls: (json['urls'] as List<dynamic>?)?.cast<String>(),
      imageUrl: json['imageUrl'] as String?,
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${json['type']}',
        orElse: () => MessageType.text,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isMe': isMe,
      'timestamp': timestamp.toIso8601String(),
      'status': status.toString().split('.').last,
      'senderId': senderId,
      'isRead': isRead,
      'reactions': reactions,
      'replyTo': replyTo?.toJson(),
      'isDeleted': isDeleted,
      'urls': urls,
      'imageUrl': imageUrl,
      'type': type.toString().split('.').last,
    };
  }

  String get formattedTime {
    final hours = timestamp.hour.toString().padLeft(2, '0');
    final minutes = timestamp.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  MessageModel copyWith({
    String? id,
    String? text,
    String? chatId,
    bool? isMe,
    DateTime? timestamp,
    Map<String, int>? reactions,
    MessageModel? replyTo,
    bool? isDeleted,
    List<String>? urls,
    String? imageUrl,
    MessageType? type,
    MessageStatus? status,
    bool? isRead,
    String? senderId,
  }) {
    return MessageModel(
      id: id ?? this.id,
      text: text ?? this.text,
      chatId: chatId ?? this.chatId,
      isMe: isMe ?? this.isMe,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      senderId: senderId ?? this.senderId,
      isRead: isRead ?? this.isRead,
      reactions: reactions ?? this.reactions,
      replyTo: replyTo ?? this.replyTo,
      isDeleted: isDeleted ?? this.isDeleted,
      urls: urls ?? this.urls,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
    );
  }
}
