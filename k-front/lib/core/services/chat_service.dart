import 'dart:convert';
import '../../data/models/message_model.dart';
import '../../data/models/chat_room.dart';
import '../constants.dart';

/// 📱 Chat Service - L1 Core Business Logic
/// Pure Dart - no UI dependencies
class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  /// 📝 Parse message text with emoji decoding
  /// Ensures Unicode sequences are properly decoded
  String parseMessageText(String rawText) {
    try {
      // 🚨 Decode Unicode escapes (e.g., \u1f600)
      return jsonDecode('"$rawText"');
    } catch (e) {
      // If text is plain, return as-is
      return rawText;
    }
  }

  /// 📝 Format message timestamp
  String formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      // Show date for older messages
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  /// 📝 Generate chat room preview
  String generateChatPreview(List<MessageModel> messages) {
    if (messages.isEmpty) return 'No messages';
    
    final lastMessage = messages.last;
    final text = parseMessageText(lastMessage.text);
    
    if (text.length > 50) {
      return '${text.substring(0, 47)}...';
    }
    
    return text;
  }

  /// 📝 Generate chat room title
  String generateChatTitle(ChatRoom chatRoom) {
    if (chatRoom.name?.isNotEmpty == true) {
      return chatRoom.name!;
    }
    
    // Generate from participants if no name
    final participants = chatRoom.participants ?? [];
    if (participants.isEmpty) return 'Unknown Chat';
    
    // For 1-on-1 chats, use the other person's name
    if (participants.length == 2) {
      // TODO: Get current user ID and filter them out
      return participants.firstWhere(
        (p) => p['name'] != 'You',
        orElse: () => {'name': 'Unknown'},
      )['name'] as String;
    }
    
    // For group chats, use participant count
    return '${participants.length} participants';
  }

  /// 📝 Check if message contains emoji
  bool containsEmoji(String text) {
    // Simple emoji detection - can be enhanced
    final emojiRegex = RegExp(
      r'[\u{1F600}-\u{1F64F}]|' // Emoticons
      r'[\u{1F300}-\u{1F5FF}]|' // Misc Symbols and Pictographs
      r'[\u{1F680}-\u{1F6FF}]|' // Transport and Map Symbols
      r'[\u{1F1E0}-\u{1F1FF}]|' // Miscellaneous Symbols
      r'[\u{2600}-\u{26FF}]|'   // Misc Symbols
      r'[\u{2700}-\u{27BF}]',    // Dingbats
      unicode: true,
    );
    
    return emojiRegex.hasMatch(text);
  }

  /// 📝 Truncate message for preview
  String truncateMessage(String text, {int maxLength = 50}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  /// 📝 Get message status icon
  String getMessageStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return '⏳';
      case MessageStatus.sent:
        return '✓';
      case MessageStatus.delivered:
        return '✓✓';
      case MessageStatus.read:
        return '🔵';
      case MessageStatus.failed:
        return '❌';
      default:
        return '';
    }
  }

  /// 📝 Sort chat rooms by last activity
  List<ChatRoom> sortChatRoomsByActivity(List<ChatRoom> chatRooms) {
    final sortedRooms = List<ChatRoom>.from(chatRooms);
    sortedRooms.sort((a, b) {
      final aTime = a.lastActivity ?? DateTime(0);
      final bTime = b.lastActivity ?? DateTime(0);
      return bTime.compareTo(aTime); // Most recent first
    });
    return sortedRooms;
  }

  /// 📝 Filter chat rooms by search query
  List<ChatRoom> filterChatRooms(List<ChatRoom> chatRooms, String query) {
    if (query.isEmpty) return chatRooms;
    
    final lowerQuery = query.toLowerCase();
    return chatRooms.where((chat) {
      final title = generateChatTitle(chat).toLowerCase();
      final preview = generateChatPreview(chat.messages ?? []).toLowerCase();
      
      return title.contains(lowerQuery) || preview.contains(lowerQuery);
    }).toList();
  }

  /// 📝 Get unread message count
  int getUnreadCount(ChatRoom chatRoom, String currentUserId) {
    final messages = chatRoom.messages ?? [];
    return messages.where((message) {
      return !message.isRead && 
             message.senderId != currentUserId &&
             message.status == MessageStatus.delivered;
    }).length;
  }

  /// 📝 Mark messages as read - returns updated messages list
  List<MessageModel> markMessagesAsRead(ChatRoom chatRoom, String currentUserId) {
    final messages = chatRoom.messages ?? [];
    final updatedMessages = <MessageModel>[];
    
    for (final msg in messages) {
      if (!msg.isRead && msg.senderId != currentUserId) {
        updatedMessages.add(msg.copyWith(
          isRead: true,
          status: MessageStatus.read,
        ));
      } else {
        updatedMessages.add(msg);
      }
    }
    
    return updatedMessages;
  }

  /// 📝 Validate message before sending
  bool validateMessage(String text) {
    if (text.trim().isEmpty) return false;
    if (text.length > 1000) return false; // Max message length
    return true;
  }

  /// 📝 Get typing indicator text
  String getTypingIndicatorText(List<String> typingUsers) {
    if (typingUsers.isEmpty) return '';
    
    if (typingUsers.length == 1) {
      return '${typingUsers.first} is typing...';
    } else if (typingUsers.length == 2) {
      return '${typingUsers.first} and ${typingUsers.last} are typing...';
    } else {
      return 'Several people are typing...';
    }
  }
}
