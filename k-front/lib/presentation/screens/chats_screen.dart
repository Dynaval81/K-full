// v1.3.0
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:knoty/core/controllers/auth_controller.dart';
import 'package:knoty/core/controllers/chat_controller.dart';
import 'package:knoty/core/enums/verification_level.dart';
import 'package:knoty/data/models/chat_room.dart';
import 'package:knoty/presentation/screens/chat/chat_room_screen.dart';
import 'package:knoty/presentation/widgets/knoty_app_bar.dart';
import 'package:knoty/l10n/app_localizations.dart';

enum _ChatFilter { all, personal, groups, school }

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  _ChatFilter _activeFilter = _ChatFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<ChatController>();
      if (controller.chatRooms.isEmpty) controller.loadChatRooms();
    });
  }

  void _openChat(BuildContext context, ChatRoom chat) {
    context.read<ChatController>().markAsRead(chat.id);
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => ChatRoomScreen(chat: chat)),
    );
  }

  List<ChatRoom> _filtered(List<ChatRoom> all, bool isSchoolVerified) {
    // Школьные чаты скрыты для неверифицированных
    final visible = isSchoolVerified
        ? all
        : all.where((c) => !c.type.requiresVerification).toList();
    switch (_activeFilter) {
      case _ChatFilter.all:      return visible;
      case _ChatFilter.personal: return visible.where((c) => c.isPersonal).toList();
      case _ChatFilter.groups:   return visible.where((c) => c.isGroup && !c.isClassGroup).toList();
      case _ChatFilter.school:   return visible.where((c) => c.isClassGroup).toList();
    }
  }

  String _emptyText(AppLocalizations l10n) {
    switch (_activeFilter) {
      case _ChatFilter.all:      return l10n.chatsEmptyAll;
      case _ChatFilter.personal: return l10n.chatsEmptyPrivate;
      case _ChatFilter.groups:   return l10n.chatsEmptyGroups;
      case _ChatFilter.school:   return l10n.chatsEmptySchool;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = context.watch<ChatController>();
    final user = context.watch<AuthController>().currentUser;
    final isSchoolVerified = user?.verificationLevel == VerificationLevel.verified
        && user?.schoolId != null;
    final rooms = _filtered(controller.chatRooms, isSchoolVerified);
    final all = controller.chatRooms;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: KnotyAppBar(title: l10n.tabChats),
      body: Column(
        children: [
          // ── Фильтр-чипсы — занимают всю ширину без скролла ──
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.withOpacity(0.10)),
              ),
            ),
            child: Row(
              children: [
                Expanded(child: _Chip(
                  label: l10n.chatsFilterAll,
                  count: all.length,
                  active: _activeFilter == _ChatFilter.all,
                  onTap: () => setState(() => _activeFilter = _ChatFilter.all),
                )),
                const SizedBox(width: 6),
                Expanded(child: _Chip(
                  label: l10n.chatsFilterPrivate,
                  count: all.where((c) => c.isPersonal).length,
                  active: _activeFilter == _ChatFilter.personal,
                  onTap: () => setState(() => _activeFilter = _ChatFilter.personal),
                )),
                const SizedBox(width: 6),
                Expanded(child: _Chip(
                  label: l10n.chatsFilterGroups,
                  count: all.where((c) => c.isGroup && !c.isClassGroup).length,
                  active: _activeFilter == _ChatFilter.groups,
                  onTap: () => setState(() => _activeFilter = _ChatFilter.groups),
                )),
                const SizedBox(width: 6),
                Expanded(child: _Chip(
                  label: l10n.chatsFilterSchool,
                  count: all.where((c) => c.isClassGroup).length,
                  active: _activeFilter == _ChatFilter.school,
                  isLocked: !isSchoolVerified,
                  onTap: isSchoolVerified
                      ? () => setState(() => _activeFilter = _ChatFilter.school)
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.sandboxLimitChats),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                )),
              ],
            ),
          ),
          // ── Список ────────────────────────────────────────────
          Expanded(
            child: controller.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFE6B800), strokeWidth: 2),
                  )
                : _ChatList(
                    rooms: rooms,
                    onTap: (chat) => _openChat(context, chat),
                    emptyText: _emptyText(l10n),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFFE6B800),
        foregroundColor: Colors.white,
        elevation: 2,
        child: const Icon(Icons.edit_rounded, size: 22),
      ),
    );
  }
}

// ── Чип ───────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final int count;
  final bool active;
  final bool isLocked;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          height: 34,
          decoration: BoxDecoration(
            color: active ? const Color(0xFFE6B800) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLocked) ...[
                    Icon(Icons.lock_outline_rounded,
                        size: 11,
                        color: active ? Colors.white : const Color(0xFF9E9E9E)),
                    const SizedBox(width: 3),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : const Color(0xFF757575),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!isLocked && count > 0) ...[
                    const SizedBox(width: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white.withValues(alpha: 0.35)
                            : const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: active ? Colors.white : const Color(0xFF757575),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
          ),
      ),
    );
  }
}

// ── Список чатов ──────────────────────────────────────────────────────────────

class _ChatList extends StatelessWidget {
  final List<ChatRoom> rooms;
  final void Function(ChatRoom) onTap;
  final String emptyText;

  const _ChatList({
    required this.rooms,
    required this.onTap,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    if (rooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  size: 36, color: Color(0xFFBDBDBD)),
            ),
            const SizedBox(height: 16),
            Text(emptyText,
              style: const TextStyle(
                  fontSize: 15, color: Color(0xFF9E9E9E),
                  fontWeight: FontWeight.w400)),
          ],
        ),
      );
    }
    return ListView.builder(
      physics: const ClampingScrollPhysics(),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final chat = rooms[index];
        return _ChatListItem(
          chat: chat,
          onTap: () => onTap(chat),
        );
      },
    );
  }
}

// ── Элемент чата ──────────────────────────────────────────────────────────────

class _ChatListItem extends StatelessWidget {
  final ChatRoom chat;
  final VoidCallback onTap;

  const _ChatListItem({
    required this.chat,
    required this.onTap,
  });

  String _formatTime(BuildContext context, DateTime? dt) {
    if (dt == null) return '';
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return l10n.chatTimeNow;
    if (diff.inHours < 1) return '${diff.inMinutes} ${l10n.chatTimeMin}';
    if (diff.inDays < 1) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays < 7) {
      return DateFormat('EEE', locale).format(dt);
    }
    return '${dt.day}.${dt.month}';
  }


  @override
  Widget build(BuildContext context) {
    final hasUnread = chat.unread > 0;
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Stack(
              children: [
                _Avatar(chat: chat),
                if (chat.isOnline && chat.isPersonal)
                  Positioned(
                    right: 0, bottom: 0,
                    child: Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.name ?? l10n.chatUnknown,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                            color: const Color(0xFF1A1A1A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(context, chat.lastMessageTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: hasUnread ? const Color(0xFFE6B800) : const Color(0xFF9E9E9E),
                          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: _PreviewText(
                          text: chat.lastMessage ?? '',
                          hasUnread: hasUnread,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6B800),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            chat.unread > 99 ? '99+' : '${chat.unread}',
                            style: const TextStyle(
                              fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Превью сообщения (с SVG-смайлами) ────────────────────────────────────────

class _PreviewText extends StatelessWidget {
  final String text;
  final bool hasUnread;

  const _PreviewText({required this.text, required this.hasUnread});

  static final _re = RegExp(r'\[([^\]]+)\]');

  List<InlineSpan> _buildSpans(TextStyle base) {
    if (text.isEmpty) return [TextSpan(text: '', style: base)];
    final spans = <InlineSpan>[];
    int last = 0;
    for (final m in _re.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start), style: base));
      }
      final code = m.group(1)!;
      if (code.startsWith('icon_')) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: SvgPicture.asset(
              'assets/emojis_v2/$code.svg',
              width: 15, height: 15,
            ),
          ),
        ));
      } else {
        spans.add(TextSpan(text: text.substring(m.start, m.end), style: base));
      }
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last), style: base));
    }
    if (spans.isEmpty) spans.add(TextSpan(text: text, style: base));
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontSize: 13,
      color: hasUnread ? const Color(0xFF1A1A1A) : const Color(0xFF9E9E9E),
      fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
    );
    return Text.rich(
      TextSpan(children: _buildSpans(base)),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}

// ── Аватар ────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final ChatRoom chat;
  const _Avatar({required this.chat});

  @override
  Widget build(BuildContext context) {
    if (chat.isGroup) {
      return Container(
        width: 50, height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFFE6B800).withOpacity(0.3), width: 1),
        ),
        child: Icon(
          chat.isClassGroup ? Icons.school_rounded : Icons.group_rounded,
          size: 24, color: const Color(0xFFE6B800),
        ),
      );
    }
    return Container(
      width: 50, height: 50,
      decoration: BoxDecoration(
          color: _getAvatarColor(chat.id), shape: BoxShape.circle),
      child: Center(
        child: Text(
          _getInitials(chat.name),
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }

  Color _getAvatarColor(String id) {
    const colors = [
      Color(0xFF5C6BC0), Color(0xFF26A69A), Color(0xFFEF5350),
      Color(0xFF42A5F5), Color(0xFFAB47BC), Color(0xFFEC407A),
      Color(0xFF66BB6A), Color(0xFFFF7043),
    ];
    return colors[id.hashCode.abs() % colors.length];
  }
}