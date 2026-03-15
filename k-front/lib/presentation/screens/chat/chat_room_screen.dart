// v1.1.3
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:knoty/core/constants.dart';
import 'package:knoty/core/controllers/chat_controller.dart';
import 'package:knoty/data/models/chat_room.dart';
import 'package:knoty/l10n/app_localizations.dart';
import 'package:knoty/presentation/widgets/molecules/chat_input_field.dart';
import 'package:knoty/presentation/widgets/molecules/message_bubble.dart';

class ChatRoomScreen extends StatefulWidget {
  final ChatRoom chat;

  const ChatRoomScreen({
    super.key,
    required this.chat,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  late bool _hadUnread;
  late int _unreadCount;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _unreadCount = widget.chat.unread;
    _hadUnread = _unreadCount > 0;
    if (_hadUnread) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<ChatController>().markAsRead(widget.chat.id);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _showActionSnack(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(label),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChatController>();
    final messages = controller.messagesForChat(widget.chat.id);

    return Scaffold(
      appBar: _ChatAppBar(chat: widget.chat),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _EmptyChat(isGroup: widget.chat.isGroup)
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: messages.length + (_hadUnread ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_hadUnread && index == _unreadCount) {
                        return _NewMessagesDivider();
                      }
                      final msgIndex = (_hadUnread && index > _unreadCount) ? index - 1 : index;
                      final message = messages[msgIndex];
                      final isPrevSame = msgIndex < messages.length - 1 &&
                          (messages[msgIndex + 1].senderId ?? '') == (message.senderId ?? '');
                      // Date divider: показываем если это последнее сообщение дня
                      final showDate = msgIndex == messages.length - 1 ||
                          !_isSameDay(message.timestamp,
                              messages[msgIndex + 1].timestamp);
                      return KeyedSubtree(
                        key: ValueKey(message.id),
                        child: Column(
                          children: [
                            if (showDate) _DateDivider(date: message.timestamp),
                            _SwipeableBubble(
                              onReply: () => _showActionSnack(context, AppLocalizations.of(context)!.msgActionReply),
                              onForward: () => _showActionSnack(context, AppLocalizations.of(context)!.msgActionForward),
                              child: MessageBubble(
                                message: message,
                                isMe: message.isMe,
                                isPreviousFromSameSender: isPrevSame,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          ChatInputField(
            onSendMessage: (text) =>
                controller.sendMessage(widget.chat.id, text),
          ),
        ],
      ),
    );
  }
}

// ── Swipeable bubble (WhatsApp-style reply / forward) ─────────────────────────

class _SwipeableBubble extends StatefulWidget {
  final Widget child;
  final VoidCallback onReply;
  final VoidCallback onForward;

  const _SwipeableBubble({
    required this.child,
    required this.onReply,
    required this.onForward,
  });

  @override
  State<_SwipeableBubble> createState() => _SwipeableBubbleState();
}

class _SwipeableBubbleState extends State<_SwipeableBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _snapCtrl;
  late Animation<double> _snapAnim;
  double _dx = 0;
  bool _triggered = false;

  static const _kThreshold = 72.0;

  @override
  void initState() {
    super.initState();
    _snapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _snapCtrl.dispose();
    super.dispose();
  }

  void _onUpdate(DragUpdateDetails d) {
    final clamped = (_dx + d.delta.dx).clamp(-_kThreshold * 1.3, _kThreshold * 1.3);
    setState(() => _dx = clamped);
    if (!_triggered && _dx.abs() >= _kThreshold) {
      _triggered = true;
      HapticFeedback.mediumImpact();
    } else if (_triggered && _dx.abs() < _kThreshold * 0.5) {
      _triggered = false;
    }
  }

  void _onEnd(DragEndDetails _) {
    if (_dx >= _kThreshold) widget.onForward();
    else if (_dx <= -_kThreshold) widget.onReply();
    _snapBack();
  }

  void _snapBack() {
    final start = _dx;
    _snapCtrl.stop();
    _snapAnim = Tween<double>(begin: start, end: 0.0).animate(
      CurvedAnimation(parent: _snapCtrl, curve: Curves.elasticOut),
    )..addListener(() => setState(() => _dx = _snapAnim.value));
    _snapCtrl.forward(from: 0);
    _triggered = false;
  }

  @override
  Widget build(BuildContext context) {
    final abs = (_dx / _kThreshold).abs().clamp(0.0, 1.0);
    final goRight = _dx > 8;
    final goLeft  = _dx < -8;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Icon hint (behind bubble)
        if (goRight || goLeft)
          Positioned.fill(
            child: Align(
              alignment: goRight ? Alignment.centerLeft : Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Opacity(
                  opacity: abs,
                  child: Transform.scale(
                    scale: 0.5 + 0.5 * abs,
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: (goRight
                            ? const Color(0xFFAB47BC)
                            : const Color(0xFF5B8DEF)).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        goRight ? Icons.forward_rounded : Icons.reply_rounded,
                        size: 18,
                        color: goRight
                            ? const Color(0xFFAB47BC)
                            : const Color(0xFF5B8DEF),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        // Bubble
        GestureDetector(
          onHorizontalDragUpdate: _onUpdate,
          onHorizontalDragEnd: _onEnd,
          onHorizontalDragCancel: () => _snapBack(),
          child: Transform.translate(
            offset: Offset(_dx, 0),
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ChatRoom chat;

  const _ChatAppBar({required this.chat});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _showCallSnack(BuildContext context, {required bool isVideo}) {
    final l10n = AppLocalizations.of(context)!;
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Row(
          children: [
            Icon(
              isVideo ? Icons.videocam_rounded : Icons.call_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(l10n.chatCallComingSoon),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF1A1A1A),
      ));
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }

  Color _getAvatarColor(String id) {
    const colors = [
      Color(0xFF5C6BC0),
      Color(0xFF26A69A),
      Color(0xFFEF5350),
      Color(0xFF42A5F5),
      Color(0xFFAB47BC),
      Color(0xFFEC407A),
      Color(0xFF66BB6A),
      Color(0xFFFF7043),
    ];
    return colors[id.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: Theme.of(context).colorScheme.outline,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: Theme.of(context).colorScheme.onSurface, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          // Avatar
          if (chat.isGroup)
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE6B800).withOpacity(0.3),
                ),
              ),
              child: Icon(
                chat.isClassGroup
                    ? Icons.school_rounded
                    : Icons.group_rounded,
                size: 20,
                color: const Color(0xFFE6B800),
              ),
            )
          else
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _getAvatarColor(chat.id),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _getInitials(chat.name),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  chat.name ?? AppLocalizations.of(context)!.chatUnknown,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  chat.isGroup
                      ? (chat.isClassGroup ? AppLocalizations.of(context)!.chatTypeClass : AppLocalizations.of(context)!.chatTypeSchool)
                      : (chat.isOnline ? AppLocalizations.of(context)!.chatOnline : AppLocalizations.of(context)!.chatLastSeen),
                  style: TextStyle(
                    color: chat.isOnline && chat.isPersonal
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFF9E9E9E),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: AppLocalizations.of(context)!.chatCallVoice,
          icon: const Icon(Icons.call_rounded,
              color: Color(0xFF1A1A1A), size: 22),
          onPressed: () => _showCallSnack(context, isVideo: false),
        ),
        IconButton(
          tooltip: AppLocalizations.of(context)!.chatCallVideo,
          icon: const Icon(Icons.videocam_rounded,
              color: Color(0xFF1A1A1A), size: 22),
          onPressed: () => _showCallSnack(context, isVideo: true),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert_rounded,
              color: Color(0xFF1A1A1A), size: 22),
          onPressed: () {}, // TODO: chat options
        ),
      ],
    );
  }
}

class _EmptyChat extends StatelessWidget {
  final bool isGroup;

  _EmptyChat({required this.isGroup});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isGroup
                  ? Icons.group_rounded
                  : Icons.chat_bubble_outline_rounded,
              size: 36,
              color: const Color(0xFFE6B800),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.chatNoMessages,
            style: TextStyle(fontSize: 16, color: Color(0xFF9E9E9E)),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context)!.chatFirstMessage,
            style: TextStyle(fontSize: 14, color: Color(0xFFBDBDBD)),
          ),
        ],
      ),
    );
  }
}

class _NewMessagesDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Divider(
                color: const Color(0xFFE6B800).withOpacity(0.4), height: 1),
          ),
          const SizedBox(width: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFE6B800).withOpacity(0.3)),
            ),
            child: Builder(
              builder: (ctx) => Text(
                AppLocalizations.of(ctx)!.chatNewMessages,
                style: const TextStyle(
                  color: Color(0xFFE6B800),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(
                color: const Color(0xFFE6B800).withOpacity(0.4), height: 1),
          ),
        ],
      ),
    );
  }
}

// ── Date divider ──────────────────────────────────────────────────────────────

class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider({required this.date});

  String _label(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d     = DateTime(date.year, date.month, date.day);
    final diff  = today.difference(d).inDays;
    if (diff == 0) return AppLocalizations.of(context)!.chatDateToday;
    if (diff == 1) return AppLocalizations.of(context)!.chatDateYesterday;
    return '${date.day.toString().padLeft(2, '0')}.'
           '${date.month.toString().padLeft(2, '0')}.'
           '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Expanded(child: Divider(color: Colors.grey.withOpacity(0.18), height: 1)),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(_label(context),
            style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w500)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: Colors.grey.withOpacity(0.18), height: 1)),
      ]),
    );
  }
}