import 'package:flutter/material.dart';
import 'package:knoty/core/constants.dart';
import 'package:knoty/data/models/server_model.dart';

/// HAI3 Molecule: Server/location picker list (Airy style).
class ServerPicker extends StatelessWidget {
  final List<ServerModel> servers;
  final ServerModel? selectedServer;
  final ValueChanged<ServerModel> onServerSelected;

  const ServerPicker({
    super.key,
    required this.servers,
    required this.selectedServer,
    required this.onServerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Location',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ),
          if (servers.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No servers available')),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: servers.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.15),
              ),
              itemBuilder: (context, index) {
                final server = servers[index];
                final isSelected = selectedServer?.id == server.id;
                return Material(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : Colors.transparent,
                  child: InkWell(
                    onTap: () => onServerSelected(server),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Text(
                            server.flagEmoji ?? '🌐',
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              server.displayName,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle, color: AppColors.primary, size: 22),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
