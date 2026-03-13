import 'package:knoty/data/models/chat_room.dart';
import 'package:knoty/data/models/message_model.dart';

class ChatManager {
  static List<ChatRoom> chats = _generateMockChatRooms();
  static List<MessageModel> messages = _generateMockMessages();

  static void markAsRead(String chatId) {
    final index = chats.indexWhere((c) => c.id == chatId);
    if (index >= 0) chats[index].unread = 0;
  }
}

List<ChatRoom> _generateMockChatRooms() {
  final now = DateTime.now();
  return [
    ChatRoom(
      id: '1',
      name: 'Max Müller',
      isGroup: false,
      isOnline: true,
      unread: 2,
      type: ChatType.personal,
      participants: [],
      messages: [],
      lastMessage: 'Kannst du mir die Hausaufgaben schicken?',
      lastMessageTime: now.subtract(const Duration(minutes: 5)),
      lastActivity: now.subtract(const Duration(minutes: 5)),
    ),
    ChatRoom(
      id: '2',
      name: 'Klasse 8b',
      isGroup: true,
      isOnline: false,
      unread: 5,
      type: ChatType.classGroup,
      participants: [],
      messages: [],
      lastMessage: 'Morgen fällt der Matheunterricht aus! 🎉',
      lastMessageTime: now.subtract(const Duration(hours: 1)),
      lastActivity: now.subtract(const Duration(hours: 1)),
    ),
    ChatRoom(
      id: '3',
      name: 'Goethe-Schule',
      isGroup: true,
      isOnline: false,
      unread: 0,
      type: ChatType.schoolGroup,
      participants: [],
      messages: [],
      lastMessage: 'Elternabend am Donnerstag um 19:00 Uhr.',
      lastMessageTime: now.subtract(const Duration(hours: 3)),
      lastActivity: now.subtract(const Duration(hours: 3)),
      isSchool: true,
    ),
    ChatRoom(
      id: '4',
      name: 'Sophie Wagner',
      isGroup: false,
      isOnline: false,
      unread: 0,
      type: ChatType.personal,
      participants: [],
      messages: [],
      lastMessage: 'Bis morgen! 👋',
      lastMessageTime: now.subtract(const Duration(days: 1)),
      lastActivity: now.subtract(const Duration(days: 1)),
    ),
  ];
}

List<MessageModel> _generateMockMessages() {
  final now = DateTime.now();
  return [
    // Chat 1 — Max Müller
    MessageModel(id: 'c1_1', text: 'Hey, bist du online?',                          chatId: '1', senderId: 'other_1', isMe: false, timestamp: now.subtract(const Duration(minutes: 12)), status: MessageStatus.read),
    MessageModel(id: 'c1_2', text: 'Klar, einen Moment!',                            chatId: '1', senderId: 'me',      isMe: true,  timestamp: now.subtract(const Duration(minutes: 10)), status: MessageStatus.read),
    MessageModel(id: 'c1_3', text: 'Kannst du mir die Hausaufgaben schicken?',       chatId: '1', senderId: 'other_1', isMe: false, timestamp: now.subtract(const Duration(minutes: 5)),  status: MessageStatus.delivered),
    MessageModel(id: 'c1_4', text: 'Mathe S. 47 Aufgaben 1–5, Deutsch Aufsatz.',    chatId: '1', senderId: 'me',      isMe: true,  timestamp: now.subtract(const Duration(minutes: 3)),  status: MessageStatus.read),

    // Chat 2 — Klasse 8b
    MessageModel(id: 'c2_1', text: 'Guten Morgen alle zusammen! 👋',                chatId: '2', senderId: 'teacher', isMe: false, timestamp: now.subtract(const Duration(days: 1)),    status: MessageStatus.read),
    MessageModel(id: 'c2_2', text: 'Wann ist die nächste Klassenarbeit?',            chatId: '2', senderId: 'me',      isMe: true,  timestamp: now.subtract(const Duration(hours: 2, minutes: 5)), status: MessageStatus.read),
    MessageModel(id: 'c2_3', text: 'In zwei Wochen, Kapitel 5 und 6.',              chatId: '2', senderId: 'other_2', isMe: false, timestamp: now.subtract(const Duration(hours: 2)),    status: MessageStatus.read),
    MessageModel(id: 'c2_4', text: 'Morgen fällt der Matheunterricht aus! 🎉',      chatId: '2', senderId: 'teacher', isMe: false, timestamp: now.subtract(const Duration(hours: 1)),    status: MessageStatus.delivered),

    // Chat 3 — Goethe-Schule
    MessageModel(id: 'c3_1', text: 'Willkommen im Schul-Chat der Goethe-Schule!',   chatId: '3', senderId: 'admin',   isMe: false, timestamp: now.subtract(const Duration(days: 3)),    status: MessageStatus.read),
    MessageModel(id: 'c3_2', text: 'Elternabend am Donnerstag um 19:00 Uhr.',        chatId: '3', senderId: 'admin',   isMe: false, timestamp: now.subtract(const Duration(hours: 3)),   status: MessageStatus.read),

    // Chat 4 — Sophie Wagner
    MessageModel(id: 'c4_1', text: 'Tschüss, schönen Abend!',                       chatId: '4', senderId: 'me',      isMe: true,  timestamp: now.subtract(const Duration(days: 1, minutes: 2)), status: MessageStatus.read),
    MessageModel(id: 'c4_2', text: 'Bis morgen! 👋',                                chatId: '4', senderId: 'other_4', isMe: false, timestamp: now.subtract(const Duration(days: 1)),    status: MessageStatus.read),
  ];
}