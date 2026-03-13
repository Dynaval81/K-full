// v1.5.1
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:knoty/core/controllers/chat_controller.dart';
import 'package:knoty/data/models/message_model.dart';
import 'package:knoty/l10n/app_localizations.dart';

class MessageBubble extends StatefulWidget {
  final MessageModel message;
  final bool isMe;
  final bool isPreviousFromSameSender;
  final String? senderName;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.isPreviousFromSameSender = false,
    this.senderName,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  OverlayEntry? _overlayEntry;

  static const _reactionIcons = [
    'icon_thumbup', 'icon_e_biggrin', 'icon_lol', 'icon_clap',
    'icon_cry',     'icon_eek',       'icon_mad',  'icon_wave',
  ];

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showContextMenu(BuildContext context) {
    if (!mounted) return;
    _removeOverlay();

    final controller = context.read<ChatController>();
    final mq         = MediaQuery.of(context);
    final keyboardH  = mq.viewInsets.bottom; // высота клавиатуры
    final screenH    = mq.size.height;

    // Высота контента меню
    final itemCount  = widget.isMe ? 6 : 5;
    final menuH      = 72.0 + 8.0 + (50.0 * itemCount) + 16.0;

    // Позиция пузыря
    final renderBox  = context.findRenderObject() as RenderBox?;
    final bubbleY    = renderBox?.localToGlobal(Offset.zero).dy ?? 0.0;

    // Максимальная нижняя граница — ровно над клавиатурой
    final maxBottom  = screenH - keyboardH - 8;
    // Идеально — над пузырём
    double top = bubbleY - menuH - 8;
    // Не выше AppBar
    if (top < 80) top = 80;
    // Не ниже клавиатуры
    if (top + menuH > maxBottom) top = (maxBottom - menuH).clamp(80.0, maxBottom);

    _overlayEntry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          // Затемнение — закрывает при тапе
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _removeOverlay,
              child: Container(color: Colors.black.withOpacity(0.2)),
            ),
          ),
          // Меню — всегда выше клавиатуры
          Positioned(
            top: top,
            left: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ReactionsBar(
                    icons: _reactionIcons,
                    currentReaction:
                        controller.reactionFor(widget.message.id),
                    onReact: (icon) {
                      controller.setReaction(widget.message.id, icon);
                      _removeOverlay();
                    },
                    onMore: () =>
                        _showFullReactionPicker(context, controller),
                  ),
                  const SizedBox(height: 8),
                  _ActionsMenu(
                    isMe: widget.isMe,
                    onAction: (action) {
                      _removeOverlay();
                      _handleAction(context, action, controller);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _showFullReactionPicker(
      BuildContext context, ChatController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SizedBox(
        height: 380,
        child: _FullReactionPicker(
          currentReaction: controller.reactionFor(widget.message.id),
          onReact: (icon) {
            controller.setReaction(widget.message.id, icon);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _handleAction(
      BuildContext context, _MsgAction action, ChatController ctrl) {
    switch (action) {
      case _MsgAction.reply:   break; // TODO
      case _MsgAction.forward: break; // TODO
      case _MsgAction.pin:     break; // TODO
      case _MsgAction.edit:    break; // TODO
      case _MsgAction.copy:
        Clipboard.setData(ClipboardData(text: widget.message.text));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.msgCopied),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ));
        break;
      case _MsgAction.delete:
        ctrl.deleteMessage(widget.message.id, widget.message.chatId ?? '');
        break;
      case _MsgAction.deleteLocal:
        ctrl.deleteMessageLocal(widget.message.id);
        break;
      case _MsgAction.report:
        _showReportDialog(context);
        break;
    }
  }

  void _showReportDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.msgReportTitle,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(l10n.msgReportConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.msgReportCancel,
                  style: const TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(l10n.msgReported),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ));
            },
            child: Text(l10n.msgReportSend,
                style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';

  Color _nameColor(String id) {
    const colors = [
      Color(0xFF5B8DEF), Color(0xFF26A69A), Color(0xFFAB47BC),
      Color(0xFFEC407A), Color(0xFF66BB6A), Color(0xFFFF7043),
    ];
    return colors[id.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final reaction =
        context.watch<ChatController>().reactionFor(widget.message.id);

    return Padding(
      padding: EdgeInsets.only(
        top:   widget.isPreviousFromSameSender ? 2 : 8,
        left:  widget.isMe ? 56 : 0,
        right: widget.isMe ? 0 : 56,
      ),
      child: Row(
        mainAxisAlignment:
            widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!widget.isMe) ...[
            if (!widget.isPreviousFromSameSender)
              _SenderAvatar(
                  name: widget.senderName ?? (widget.message.senderId ?? ''))
            else
              const SizedBox(width: 32),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: widget.isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!widget.isMe &&
                    !widget.isPreviousFromSameSender &&
                    widget.senderName != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 3),
                    child: Text(
                      widget.senderName!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _nameColor(widget.message.senderId ?? ''),
                      ),
                    ),
                  ),

                GestureDetector(
                  onLongPress: () => _showContextMenu(context),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: widget.isMe
                              ? const Color(0xFFE6B800)
                              : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft:
                                Radius.circular(widget.isMe ? 20 : 4),
                            bottomRight:
                                Radius.circular(widget.isMe ? 4 : 20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _MessageContent(
                                text: widget.message.text,
                                isMe: widget.isMe),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatTime(widget.message.timestamp),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: widget.isMe
                                        ? Colors.white.withOpacity(0.75)
                                        : const Color(0xFF9E9E9E),
                                  ),
                                ),
                                if (widget.isMe) ...[
                                  const SizedBox(width: 4),
                                  _StatusIcon(
                                      status: widget.message.status),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (reaction != null)
                        Positioned(
                          bottom: -14,
                          right: widget.isMe ? null : 8,
                          left:  widget.isMe ? 8 : null,
                          child: Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0xFFF0F0F0)),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 4)
                              ],
                            ),
                            padding: const EdgeInsets.all(4),
                            child: SvgPicture.asset(
                              'assets/emojis_v2/$reaction.svg',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (reaction != null) const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reactions bar ─────────────────────────────────────────────────────────────

class _ReactionsBar extends StatelessWidget {
  final List<String> icons;
  final String? currentReaction;
  final void Function(String) onReact;
  final VoidCallback onMore;

  const _ReactionsBar({
    required this.icons,
    required this.currentReaction,
    required this.onReact,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ...icons.map((icon) {
            final isActive = icon == currentReaction;
            return GestureDetector(
              onTap: () => onReact(icon),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFE6B800).withOpacity(0.18)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: isActive
                      ? Border.all(
                          color: const Color(0xFFE6B800), width: 1.5)
                      : null,
                ),
                padding: const EdgeInsets.all(6),
                child: SvgPicture.asset(
                    'assets/emojis_v2/$icon.svg',
                    fit: BoxFit.contain),
              ),
            );
          }),
          // Кнопка «+» — открывает полный пикер реакций
          GestureDetector(
            onTap: onMore,
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add_rounded,
                  color: Color(0xFF9E9E9E), size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Full reaction picker (открывается по «+») ─────────────────────────────────

class _FullReactionPicker extends StatefulWidget {
  final String? currentReaction;
  final void Function(String) onReact;

  const _FullReactionPicker({
    required this.currentReaction,
    required this.onReact,
  });

  @override
  State<_FullReactionPicker> createState() => _FullReactionPickerState();
}

class _FullReactionPickerState extends State<_FullReactionPicker> {
  static const _allSvg = [
    'icon_e_smile','icon_e_biggrin','icon_e_wink','icon_e_sad',
    'icon_e_surprised','icon_e_confused','icon_e_geek','icon_e_ugeek',
    'icon_cool','icon_lol','icon_lolno','icon_mad','icon_razz',
    'icon_redface','icon_rolleyes','icon_neutral','icon_twisted','icon_evil',
    'icon_cry','icon_eek','icon_eh','icon_angel','icon_arrow','icon_clap',
    'icon_crazy','icon_exclaim','icon_idea','icon_mrgreen','icon_problem',
    'icon_question','icon_shh','icon_shifty','icon_sick','icon_silent',
    'icon_think','icon_thumbdown','icon_thumbup','icon_wave','icon_wtf','icon_yawn',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 12),
        const Text('Reaktion wählen',   // TODO: l10n.msgReactionPicker когда AppLocalizations появится в этом контексте
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              mainAxisSpacing: 8, crossAxisSpacing: 8,
            ),
            itemCount: _allSvg.length,
            itemBuilder: (_, i) {
              final icon = _allSvg[i];
              final isActive = icon == widget.currentReaction;
              return GestureDetector(
                onTap: () => widget.onReact(icon),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFE6B800).withOpacity(0.15)
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                    border: isActive
                        ? Border.all(
                            color: const Color(0xFFE6B800), width: 1.5)
                        : null,
                  ),
                  padding: const EdgeInsets.all(6),
                  child: SvgPicture.asset(
                      'assets/emojis_v2/$icon.svg',
                      fit: BoxFit.contain),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Actions menu ──────────────────────────────────────────────────────────────

enum _MsgAction { reply, copy, forward, pin, edit, delete, deleteLocal, report }

class _ActionsMenu extends StatelessWidget {
  final bool isMe;
  final void Function(_MsgAction) onAction;
  const _ActionsMenu({required this.isMe, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = isMe
        ? [
            _I(Icons.reply_rounded,         l10n.msgActionReply,    _MsgAction.reply,       const Color(0xFF5B8DEF)),
            _I(Icons.copy_rounded,           l10n.msgActionCopy,     _MsgAction.copy,        const Color(0xFF26A69A)),
            _I(Icons.forward_rounded,        l10n.msgActionForward,  _MsgAction.forward,     const Color(0xFFAB47BC)),
            _I(Icons.push_pin_rounded,       l10n.msgActionPin,      _MsgAction.pin,         const Color(0xFFFF7043)),
            _I(Icons.edit_rounded,           l10n.msgActionEdit,     _MsgAction.edit,        const Color(0xFF66BB6A)),
            _I(Icons.delete_outline_rounded, l10n.msgActionDelete,   _MsgAction.delete,      Colors.redAccent),
          ]
        : [
            _I(Icons.reply_rounded,         l10n.msgActionReply,    _MsgAction.reply,       const Color(0xFF5B8DEF)),
            _I(Icons.copy_rounded,           l10n.msgActionCopy,     _MsgAction.copy,        const Color(0xFF26A69A)),
            _I(Icons.forward_rounded,        l10n.msgActionForward,  _MsgAction.forward,     const Color(0xFFAB47BC)),
            _I(Icons.push_pin_rounded,       l10n.msgActionPin,      _MsgAction.pin,         const Color(0xFFFF7043)),
            _I(Icons.flag_outlined,          l10n.msgActionReport,   _MsgAction.report,      Colors.orange),
            _I(Icons.delete_outline_rounded, l10n.msgActionRemove,   _MsgAction.deleteLocal, Colors.redAccent),
          ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: items.asMap().entries.map((e) {
          final idx = e.key; final item = e.value;
          final isFirst = idx == 0;
          final isLast  = idx == items.length - 1;
          final isDanger = item.action == _MsgAction.delete ||
              item.action == _MsgAction.deleteLocal ||
              item.action == _MsgAction.report;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.vertical(
                top:    isFirst ? const Radius.circular(20) : Radius.zero,
                bottom: isLast  ? const Radius.circular(20) : Radius.zero,
              ),
              onTap: () => onAction(item.action),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(
                          bottom: BorderSide(
                              color: Colors.grey.withOpacity(0.08))),
                ),
                child: Row(children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, color: item.color, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Flexible(child: Text(item.label,
                      style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500,
                        color: isDanger ? item.color : Colors.black87,
                      ))),
                ]),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _I {
  final IconData icon; final String label;
  final _MsgAction action; final Color color;
  const _I(this.icon, this.label, this.action, this.color);
}

// ── Message content ───────────────────────────────────────────────────────────

class _MessageContent extends StatelessWidget {
  final String text;
  final bool isMe;
  const _MessageContent({required this.text, required this.isMe});

  static final _re = RegExp(r'\[([^\]]+)\]');

  List<InlineSpan> _buildSpans() {
    final baseStyle = TextStyle(
      fontSize: 16,
      color: isMe ? Colors.white : const Color(0xFF1A1A1A),
      height: 1.4,
    );
    final spans = <InlineSpan>[];
    int last = 0;
    for (final m in _re.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(
            text: text.substring(last, m.start), style: baseStyle));
      }
      final code = m.group(1)!;
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: code.startsWith('icon_')
              ? SvgPicture.asset('assets/emojis_v2/$code.svg',
                  width: 22, height: 22)
              : Image.asset('assets/emojis/$code.gif',
                  width: 22, height: 22, gaplessPlayback: true),
        ),
      ));
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last), style: baseStyle));
    }
    if (spans.isEmpty) {
      spans.add(TextSpan(text: text, style: baseStyle));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) =>
      Text.rich(TextSpan(children: _buildSpans()));
}

// ── Sender avatar ─────────────────────────────────────────────────────────────

class _SenderAvatar extends StatelessWidget {
  final String name;
  const _SenderAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty ? '?'
        : name.trim().split(' ').map((p) => p[0]).take(2).join().toUpperCase();
    const colors = [
      Color(0xFF5B8DEF), Color(0xFF26A69A), Color(0xFFAB47BC),
      Color(0xFFEC407A), Color(0xFF66BB6A), Color(0xFFFF7043),
    ];
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors[name.hashCode.abs() % colors.length]),
      child: Center(
        child: Text(initials,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: Colors.white)),
      ),
    );
  }
}

// ── Status icon ───────────────────────────────────────────────────────────────

class _StatusIcon extends StatelessWidget {
  final MessageStatus status;
  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageStatus.sending:
        return const SizedBox(width: 12, height: 12,
          child: CircularProgressIndicator(strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation(Colors.white70)));
      case MessageStatus.sent:
        return const Icon(Icons.check_rounded, size: 14, color: Colors.white70);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all_rounded, size: 14, color: Colors.white70);
      case MessageStatus.read:
        return const Icon(Icons.done_all_rounded, size: 14, color: Colors.white);
      case MessageStatus.failed:
        return const Icon(Icons.error_outline_rounded,
            size: 14, color: Colors.redAccent);
    }
  }
}