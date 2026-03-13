import '../../../data/models/message_model.dart';
import '../../../data/models/message_model.dart' as mm;

/// Global mock messages for demonstration
final List<MessageModel> mockMessages = [
  MessageModel(
    id: '1',
    senderId: 'user1',
    text: 'Hey, how are you?',
    chatId: '1',
    timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
    type: MessageType.text,
    status: MessageStatus.read,
  ),
  MessageModel(
    id: '2',
    senderId: 'me',
    text: 'I\'m good, thanks! How about you?',
    chatId: '1',
    timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
    type: MessageType.text,
    status: MessageStatus.read,
  ),
  MessageModel(
    id: '3',
    senderId: 'me',
    text: 'Doing great! Just working on some projects.',
    chatId: '1',
    timestamp: DateTime.now().subtract(const Duration(minutes: 6)),
    type: MessageType.text,
    status: MessageStatus.read,
  ),
  MessageModel(
    id: '4',
    senderId: 'bob_id',
    text: 'Did you see the game last night? 🏈',
    chatId: '2',
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    type: MessageType.text,
    status: MessageStatus.read,
  ),
  MessageModel(
    id: '5',
    senderId: 'me',
    text: 'Yeah! Amazing comeback! 🎯',
    chatId: '2',
    timestamp: DateTime.now().subtract(const Duration(minutes: 58)),
    type: MessageType.text,
    status: MessageStatus.read,
  ),
  MessageModel(
    id: '6',
    senderId: 'team_member_1',
    text: 'Great work on the new features everyone! 🚀',
    chatId: '3',
    timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
    type: MessageType.text,
    status: MessageStatus.read,
  ),
  MessageModel(
    id: '7',
    senderId: 'current_user_id',
    text: 'Thanks! The HAI3 architecture is really paying off 🎨',
    chatId: '3',
    timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
    type: MessageType.text,
    status: MessageStatus.read,
  ),
  MessageModel(
    id: '8',
    senderId: 'emma_id',
    text: 'Happy birthday! 🎂🎉',
    chatId: '4',
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
    type: MessageType.text,
    status: MessageStatus.read,
  ),
  MessageModel(
    id: '9',
    senderId: 'current_user_id',
    text: 'Thank you so much! 🥰',
    chatId: '4',
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
    type: MessageType.text,
    status: MessageStatus.read,
  ),
];

/// Global helper to get the last message for a chatId
String getLastMessage(String chatId) {
  final messages = mockMessages.where((m) => m.chatId == chatId).toList();
  if (messages.isEmpty) {
    return 'Start chatting...';
  }
  return messages.last.text;
}
