// v1.2.0
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:knoty/core/controllers/chat_controller.dart';
import 'package:knoty/data/models/chat_room.dart';
import 'package:knoty/presentation/screens/chat/chat_room_screen.dart';
import 'package:knoty/presentation/widgets/knoty_app_bar.dart';

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

  List<ChatRoom> _filtered(List<ChatRoom> all) {
    switch (_activeFilter) {
      case _ChatFilter.all:      return all;
      case _ChatFilter.personal: return all.where((c) => c.isPersonal).toList();
      case _ChatFilter.groups:   return all.where((c) => c.isGroup && !c.isClassGroup).toList();
      case _ChatFilter.school:   return all.where((c) => c.isClassGroup).toList();
    }
  }

  String _emptyText() {
    switch (_activeFilter) {
      case _ChatFilter.all:      return 'Noch keine Chats';
      case _ChatFilter.personal: return 'Noch keine persönlichen Chats';
      case _ChatFilter.groups:   return 'Noch keine Gruppen';
      case _ChatFilter.school:   return 'Noch keine Schulchats';
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChatController>();
    final rooms = _filtered(controller.chatRooms);
    final all = controller.chatRooms;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: KnotyAppBar(title: 'Chats'),
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
                  label: 'Alle',
                  count: all.length,
                  active: _activeFilter == _ChatFilter.all,
                  onTap: () => setState(() => _activeFilter = _ChatFilter.all),
                )),
                const SizedBox(width: 6),
                Expanded(child: _Chip(
                  label: 'Privat',
                  count: all.where((c) => c.isPersonal).length,
                  active: _activeFilter == _ChatFilter.personal,
                  onTap: () => setState(() => _activeFilter = _ChatFilter.personal),
                )),
                const SizedBox(width: 6),
                Expanded(child: _Chip(
                  label: 'Gruppen',
                  count: all.where((c) => c.isGroup && !c.isClassGroup).length,
                  active: _activeFilter == _ChatFilter.groups,
                  onTap: () => setState(() => _activeFilter = _ChatFilter.groups),
                )),
                const SizedBox(width: 6),
                Expanded(child: _Chip(
                  label: 'Schule',
                  count: all.where((c) => c.isClassGroup).length,
                  active: _activeFilter == _ChatFilter.school,
                  onTap: () => setState(() => _activeFilter = _ChatFilter.school),
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
                    emptyText: _emptyText(),
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
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
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
            child: count > 0
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                      const SizedBox(width: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.white.withOpacity(0.35)
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
                  )
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : const Color(0xFF757575),
                    ),
                    overflow: TextOverflow.ellipsis,
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
      // ClampingScrollPhysics — не перехватывает горизонтальные жесты
      // (BouncingScrollPhysics конкурировал со SwipeTabDetector)
      physics: const ClampingScrollPhysics(),
      itemCount: rooms.length,
      itemBuilder: (context, index) => _ChatListItem(
        chat: rooms[index],
        onTap: () => onTap(rooms[index]),
      ),
    );
  }
}

// ── Элемент чата ──────────────────────────────────────────────────────────────

class _ChatListItem extends StatelessWidget {
  final ChatRoom chat;
  final VoidCallback onTap;

  const _ChatListItem({required this.chat, required this.onTap});

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Jetzt';
    if (diff.inHours < 1) return '${diff.inMinutes} Min.';
    if (diff.inDays < 1) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays < 7) {
      const days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
      return days[dt.weekday - 1];
    }
    return '${dt.day}.${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = chat.unread > 0;
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
                          chat.name ?? 'Unbekannt',
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
                        _formatTime(chat.lastMessageTime),
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
                        child: Text(
                          chat.lastMessage ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: hasUnread ? const Color(0xFF1A1A1A) : const Color(0xFF9E9E9E),
                            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
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