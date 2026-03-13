// v1.2.0
import 'package:flutter/material.dart';
import 'package:knoty/data/models/chat_room.dart';
import 'package:knoty/data/models/message_model.dart';

class ChatController extends ChangeNotifier {
  List<ChatRoom> _chatRooms = [];
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  String? _matrixUserId;

  // messageId → emoji code (хранится здесь, а не в State виджета)
  final Map<String, String> _reactions = {};

  List<ChatRoom> get chatRooms => _chatRooms;
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;

  /// Возвращает реакцию на сообщение или null
  String? reactionFor(String messageId) => _reactions[messageId];

  /// Устанавливает реакцию. Повторный тап на ту же — снимает.
  void setReaction(String messageId, String emojiCode) {
    if (_reactions[messageId] == emojiCode) {
      _reactions.remove(messageId);
    } else {
      _reactions[messageId] = emojiCode;
    }
    notifyListeners();
  }

  List<ChatRoom> get personalRooms => _chatRooms.where((r) => r.isPersonal).toList();
  List<ChatRoom> get groupRooms => _chatRooms.where((r) => r.isGroup).toList();

  void updateUserId(String? userId) {
    _matrixUserId = userId;
    debugPrint('ChatController: User ID updated to $userId');
    loadChatRooms();
    notifyListeners();
  }

  Future<void> loadChatRooms() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    // Mock chat rooms
    _chatRooms = [
      ChatRoom(
        id: 'group_10b',
        name: 'Klasse 10B',
        type: ChatType.classGroup,
        isOnline: true,
        unread: 5,
        lastMessage: 'Hausaufgabe für alle!',
        lastActivity: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      ChatRoom(
        id: 'personal_anna',
        name: 'Anna Müller',
        type: ChatType.personal,
        isOnline: true,
        unread: 2,
        lastMessage: 'Kannst du mir helfen?',
        lastActivity: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      ChatRoom(
        id: 'personal_max',
        name: 'Max Schmidt',
        type: ChatType.personal,
        isOnline: false,
        unread: 0,
        lastMessage: 'Bis morgen!',
        lastActivity: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ChatRoom(
        id: 'personal_lehrer',
        name: 'Hr. Weber',
        type: ChatType.personal,
        isOnline: true,
        unread: 1,
        lastMessage: 'Bitte pünktlich sein.',
        lastActivity: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ];

    // Mock messages per chat
    final now = DateTime.now();
    _messages = [
      // Klasse 10B
      MessageModel(
        id: 'm1', chatId: 'group_10b', text: 'Guten Morgen alle!',
        isMe: false, senderId: 'anna', timestamp: now.subtract(const Duration(hours: 1)),
        status: MessageStatus.read,
      ),
      MessageModel(
        id: 'm2', chatId: 'group_10b', text: 'Hausaufgabe für alle!',
        isMe: false, senderId: 'lehrer', timestamp: now.subtract(const Duration(minutes: 10)),
        status: MessageStatus.delivered,
      ),
      MessageModel(
        id: 'm3', chatId: 'group_10b', text: 'Verstanden, danke!',
        isMe: true, senderId: 'me', timestamp: now.subtract(const Duration(minutes: 8)),
        status: MessageStatus.read,
      ),

      // Anna Müller
      MessageModel(
        id: 'm4', chatId: 'personal_anna', text: 'Hey! Wie geht\'s?',
        isMe: true, senderId: 'me', timestamp: now.subtract(const Duration(minutes: 45)),
        status: MessageStatus.read,
      ),
      MessageModel(
        id: 'm5', chatId: 'personal_anna', text: 'Kannst du mir helfen?',
        isMe: false, senderId: 'anna', timestamp: now.subtract(const Duration(minutes: 30)),
        status: MessageStatus.delivered,
      ),

      // Max Schmidt
      MessageModel(
        id: 'm6', chatId: 'personal_max', text: 'Treffen wir uns morgen?',
        isMe: true, senderId: 'me', timestamp: now.subtract(const Duration(hours: 3)),
        status: MessageStatus.read,
      ),
      MessageModel(
        id: 'm7', chatId: 'personal_max', text: 'Bis morgen!',
        isMe: false, senderId: 'max', timestamp: now.subtract(const Duration(hours: 2)),
        status: MessageStatus.read,
      ),

      // Hr. Weber
      MessageModel(
        id: 'm8', chatId: 'personal_lehrer', text: 'Guten Tag, Herr Weber.',
        isMe: true, senderId: 'me', timestamp: now.subtract(const Duration(hours: 6)),
        status: MessageStatus.read,
      ),
      MessageModel(
        id: 'm9', chatId: 'personal_lehrer', text: 'Bitte pünktlich sein.',
        isMe: false, senderId: 'lehrer', timestamp: now.subtract(const Duration(hours: 5)),
        status: MessageStatus.delivered,
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }

  void markAsRead(String chatId) {
    final index = _chatRooms.indexWhere((r) => r.id == chatId);
    if (index != -1) {
      _chatRooms[index] = _chatRooms[index].copyWith(unread: 0);
      notifyListeners();
    }
  }

  List<MessageModel> messagesForChat(String chatId) {
    final list = _messages.where((m) => m.chatId == chatId).toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  void deleteMessageLocal(String messageId) {
    _messages.removeWhere((m) => m.id == messageId);
    _reactions.remove(messageId);
    notifyListeners();
  }

  void deleteMessage(String messageId, String chatId) {
    _messages.removeWhere((m) => m.id == messageId);
    _reactions.remove(messageId);
    // Обновляем lastMessage в ChatRoom
    final roomIdx = _chatRooms.indexWhere((r) => r.id == chatId);
    if (roomIdx != -1) {
      final last = _messages
          .where((m) => m.chatId == chatId)
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _chatRooms[roomIdx] = _chatRooms[roomIdx].copyWith(
        lastMessage: last.isNotEmpty ? last.first.text : '',
      );
    }
    notifyListeners();
  }

  Future<void> sendMessage(String chatId, String text) async {
    final msg = MessageModel(
      // Уникальный ID: timestamp + hashCode текста (без dart:math)
      id: '${DateTime.now().millisecondsSinceEpoch}_${text.hashCode.abs()}',
      chatId: chatId,
      text: text,
      isMe: true,
      senderId: 'me',
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );
    _messages.add(msg);
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 400));

    // Фикс race condition: ищем по id, не по индексу last
    final idx = _messages.indexWhere((m) => m.id == msg.id);
    if (idx != -1) {
      _messages[idx] = _messages[idx].copyWith(status: MessageStatus.sent);
    }
    notifyListeners();
  }
}