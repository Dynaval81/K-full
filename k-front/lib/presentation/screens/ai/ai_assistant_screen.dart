import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:knoty/core/controllers/ai_controller.dart';
import 'package:knoty/l10n/app_localizations.dart';
import 'package:knoty/presentation/widgets/molecules/chat_input_field.dart';
import 'package:knoty/presentation/widgets/molecules/message_bubble.dart';
import 'package:knoty/presentation/widgets/knoty_app_bar.dart';

const Color kAiBubbleColor = Color(0xFFF3E5F5);

const LinearGradient kAiBackgroundGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFFF8F5FA), Color(0xFFFDFBFF)],
);

class AiAssistantScreen extends StatelessWidget {
  const AiAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AIController(),
      child: Scaffold(
        appBar: KnotyAppBar(title: AppLocalizations.of(context)!.tabAi),
        body: Container(
          decoration: const BoxDecoration(gradient: kAiBackgroundGradient),
          child: Consumer<AIController>(
            builder: (context, ai, _) => Column(
              children: [
                Expanded(child: _buildMessageList(context, ai)),
                ChatInputField(onSendMessage: ai.sendUserMessage),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList(BuildContext context, AIController ai) {
    if (ai.messages.isEmpty && !ai.isThinking) {
      return _buildEmptyState(context);
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      reverse: true,
      itemCount: ai.messages.length + (ai.isThinking ? 1 : 0),
      itemBuilder: (context, index) {
        if (ai.isThinking && index == 0) {
          return _buildThinkingBubble(context);
        }
        final msgIndex = ai.isThinking ? index - 1 : index;
        final message = ai.messages[ai.messages.length - 1 - msgIndex];
        final isPreviousFromSame = msgIndex < ai.messages.length - 1 &&
            ai.messages[ai.messages.length - 2 - msgIndex].isMe ==
                message.isMe;
        return MessageBubble(
          message: message,
          isMe: message.isMe,
          isPreviousFromSameSender: isPreviousFromSame,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE6B800).withOpacity(0.10),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.auto_awesome,
                size: 40, color: Color(0xFFE6B800)),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.aiEmptyTitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.aiEmptySubtitle,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B6B6B)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildThinkingBubble(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: kAiBubbleColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE6B800)),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(context)!.aiThinking,
                style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}