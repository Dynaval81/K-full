import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/glass_kit.dart';
import '../theme_provider.dart';
import 'package:provider/provider.dart';

class VTalkUrlPreview extends StatelessWidget {
  final String url;
  final String? title;
  final String? description;
  final String? imageUrl;
  final VoidCallback? onTap;

  const VTalkUrlPreview({
    Key? key,
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return GestureDetector(
      onTap: onTap ?? () => _launchUrl(url),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: GlassKit.liquidGlass(
          radius: 12,
          isDark: isDark,
          opacity: 0.08,
          useBlur: true,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Изображение
                if (imageUrl != null) _buildImage(context, imageUrl!, isDark),
                
                // Контент
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Заголовок
                      if (title != null) ...[
                        Text(
                          title!,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                      ],
                      
                      // Описание
                      if (description != null)
                        Text(
                          description!,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 12,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      
                      // URL
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.link,
                            size: 12,
                            color: isDark ? Colors.white60 : Colors.black45,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              url,
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, String imageUrl, bool isDark) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        height: 120,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: 120,
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
          child: Center(
            child: Icon(
              Icons.image,
              color: isDark ? Colors.white.withValues(alpha: 0.38) : Colors.black.withValues(alpha: 0.38),
              size: 32,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          height: 120,
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
          child: Center(
            child: Icon(
              Icons.broken_image,
              color: isDark ? Colors.white.withValues(alpha: 0.38) : Colors.black.withValues(alpha: 0.38),
              size: 32,
            ),
          ),
        ),
      ),
    );
  }

  void _launchUrl(String url) async {
    // TODO: Реализовать открытие URL
    print('Opening URL: $url');
  }
}
