import 'package:flutter/foundation.dart';
import 'package:knoty/data/models/message_model.dart';

/// Mock delay for "AI is thinking..." (seconds).
const int kAiThinkingDelaySeconds = 2;

/// HAI3 Core: AI chat state and logic.
class AIController extends ChangeNotifier {
  final List<MessageModel> _messages = [];
  bool _isThinking = false;

  List<MessageModel> get messages => List.unmodifiable(_messages);
  bool get isThinking => _isThinking;

  static const String _assistantId = 'v-assistant';

  /// Sends user message and triggers mock AI reply after delay.
  Future<void> sendUserMessage(String text) {
    if (text.trim().isEmpty) return Future.value();
    final userMessage = MessageModel(
      id: 'u-${DateTime.now().millisecondsSinceEpoch}',
      text: text.trim(),
      chatId: 'ai',
      isMe: true,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      senderId: 'user',
    );
    _messages.add(userMessage);
    notifyListeners();

    return _simulateAiReply();
  }

  Future<void> _simulateAiReply() async {
    _isThinking = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: kAiThinkingDelaySeconds));

    _isThinking = false;
    final reply = MessageModel(
      id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
      text: _mockReply(),
      chatId: 'ai',
      isMe: false,
      timestamp: DateTime.now(),
      status: MessageStatus.read,
      senderId: _assistantId,
    );
    _messages.add(reply);
    notifyListeners();
  }

  String _mockReply() {
    const responses = [
      "Thanks for your message. I'm V-Assistant, your AI helper. How can I assist you today?",
      "I'm here to help. What would you like to know?",
      "Got it! Is there anything else you'd like to ask?",
    ];
    return responses[_messages.length % responses.length];
  }

  void clearChat() {
    _messages.clear();
    _isThinking = false;
    notifyListeners();
  }
}
