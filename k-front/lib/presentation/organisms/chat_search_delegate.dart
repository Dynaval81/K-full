import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/chat_room.dart';
import '../../core/constants/app_constants.dart';
import '../molecules/chat_search_result_tile.dart';

/// HAI3 Organism: full search UI – app bar, actions, results list.
class ChatSearchDelegate extends SearchDelegate<String> {
  final List<ChatRoom> chats;

  ChatSearchDelegate({required this.chats});

  List<ChatRoom> _filter(String q) {
    if (q.isEmpty) return [];
    final lower = q.toLowerCase();
    return chats.where((c) => c.name?.toLowerCase().contains(lower) ?? false).toList();
  }

  void _openChat(BuildContext context, ChatRoom chat) {
    close(context, chat.name ?? '');
    context.push('${AppRoutes.chat}/${chat.id}', extra: chat);
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear, color: kSearchPrimaryText),
        onPressed: () {
          query = '';
          close(context, '');
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: kSearchPrimaryText),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final suggestions = _filter(query);
    return Container(
      color: kSearchBackground,
      child: ListView.builder(
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final chat = suggestions[index];
          return ChatSearchResultTile(chat: chat, onTap: () => _openChat(context, chat));
        },
      ),
    );
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.copyWith(
      scaffoldBackgroundColor: kSearchBackground,
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: kSearchBackground,
        iconTheme: const IconThemeData(color: kSearchPrimaryText),
        titleTextStyle: const TextStyle(
          color: kSearchPrimaryText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) return const SizedBox.shrink();
    final list = _filter(query).take(5).toList();
    return Container(
      color: kSearchBackground,
      child: ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, index) {
          final chat = list[index];
          return ChatSearchResultTile(chat: chat, onTap: () => _openChat(context, chat));
        },
      ),
    );
  }
}
