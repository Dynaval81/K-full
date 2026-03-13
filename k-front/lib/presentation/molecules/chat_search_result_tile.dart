import 'package:flutter/material.dart';
import '../../data/models/chat_room.dart';

// HAI3 search tokens: high-contrast on #FFFFFF
const Color kSearchBackground = Color(0xFFFFFFFF);
const Color kSearchPrimaryText = Color(0xFF121212);
const Color kSearchSecondaryText = Color(0xFF757575);

/// HAI3 Molecule: chat search result row – composed, reusable result item.
class ChatSearchResultTile extends StatelessWidget {
  final ChatRoom chat;
  final VoidCallback onTap;

  const ChatSearchResultTile({
    super.key,
    required this.chat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = chat.name ?? 'Unknown';
    return Material(
      color: kSearchBackground,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: kSearchSecondaryText.withValues(alpha: 0.2),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: kSearchPrimaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: kSearchPrimaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (chat.isGroup)
                      Text(
                        'Group',
                        style: TextStyle(color: kSearchSecondaryText, fontSize: 13),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: kSearchSecondaryText, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
