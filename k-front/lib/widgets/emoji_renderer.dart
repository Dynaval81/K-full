import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EmojiRenderer {
  static const String _path = 'assets/emojis';
  static const String _svgPath = 'assets/emojis_v2';

  // Маппинг кодов эмодзи на имена файлов (GIF - ретро)
  static const Map<String, String> _emojiMap = {
    ':smile:': 'smiley',
    ':smiley:': 'smiley',
    ':cool:': 'cool',
    ':shock:': 'shocked',
    ':shocked:': 'shocked',
    ':tongue:': 'tongue',
    ':heart:': 'kiss',
    ':sad:': 'sad',
    ':angry:': 'angry',
    ':grin:': 'grin',
    ':wink': 'wink',
    ':cry:': 'cry',
    ':laugh:': 'laugh',
    ':evil:': 'evil',
    ':afro:': 'afro',
    ':angel:': 'angel',
    ':azn:': 'azn',
    ':bang:': 'bang',
    ':blank:': 'blank',
    ':buenpost:': 'buenpost',
    ':cheesy:': 'cheesy',
    ':embarrassed:': 'embarrassed',
    ':huh:': 'huh',
    ':lipsrsealed:': 'lipsrsealed',
    ':mario:': 'mario',
    ':pacman:': 'pacman', // Добавляем пакман!
    ':police:': 'police',
    ':rolleyes:': 'rolleyes',
    ':sad2:': 'sad2',
    ':shrug:': 'shrug',
    ':undecided:': 'undecided',
  };

  // Маппинг кодов эмодзи на SVG файлы (основной набор)
  static const Map<String, String> _svgEmojiMap = {
    ':smile:': 'icon_e_smile',
    ':cool:': 'icon_cool',
    ':shock:': 'icon_e_surprised',
    ':tongue:': 'icon_e_wink',
    ':heart:': 'icon_e_biggrin',
    ':sad:': 'icon_e_sad',
    ':angry:': 'icon_mad',
    ':grin:': 'icon_e_biggrin',
    ':wink:': 'icon_e_wink',
    ':cry:': 'icon_cry',
    ':laugh:': 'icon_lol',
    ':evil:': 'icon_evil',
    ':afro:': 'icon_angel',
    ':angel:': 'icon_angel',
    ':azn:': 'icon_e_geek',
    ':bang:': 'icon_exclaim',
    ':blank:': 'icon_e_confused',
    ':buenpost:': 'icon_idea',
    ':cheesy:': 'icon_razz',
    ':embarrassed:': 'icon_e_surprised',
    ':huh:': 'icon_eh',
    ':lipsrsealed:': 'icon_shh',
    ':mario:': 'icon_crazy',
    ':pacman': 'icon_arrow',
    ':police:': 'icon_clap',
    ':rolleyes:': 'icon_rolleyes',
    ':sad2:': 'icon_sick',
    ':shrug:': 'icon_shifty',
    ':undecided:': 'icon_neutral',
    ':eek:': 'icon_eek',
    ':eh:': 'icon_eh',
    ':exclaim:': 'icon_exclaim',
    ':idea:': 'icon_idea',
    ':lol:': 'icon_lol',
    ':lolno:': 'icon_lolno',
    ':mad:': 'icon_mad',
    ':mrgreen:': 'icon_mrgreen',
    ':neutral:': 'icon_neutral',
    ':problem:': 'icon_problem',
    ':question:': 'icon_question',
    ':razz:': 'icon_razz',
    ':redface:': 'icon_redface',
    ':shh:': 'icon_shh',
    ':shifty:': 'icon_shifty',
    ':sick:': 'icon_sick',
    ':silent:': 'icon_silent',
    ':think:': 'icon_think',
    ':thumbdown:': 'icon_thumbdown',
    ':thumbup:': 'icon_thumbup',
    ':twisted:': 'icon_twisted',
    ':wave:': 'icon_wave',
    ':wtf:': 'icon_wtf',
    ':yawn:': 'icon_yawn',
  };

  static Widget render(String code, double size, {String? semanticLabel}) {
    // Проверяем и убираем префикс [retro] если есть
    String cleanCode = code;
    bool isRetro = false;
    
    if (code.startsWith('[retro]')) {
      cleanCode = code.substring(7); // Убираем '[retro]' префикс
      isRetro = true;
    }
    
    // Определяем, какой формат использовать
    String? fileName;
    String assetPath = ''; // Инициализируем переменную
    
    if (isRetro) {
      // Ретро смайлы - GIF
      fileName = _emojiMap[cleanCode];
      if (fileName != null) {
        assetPath = '$_path/$fileName.gif';
      }
    } else {
      // Основные смайлы - SVG
      fileName = _svgEmojiMap[cleanCode];
      if (fileName != null) {
        assetPath = '$_svgPath/$fileName.svg';
      }
    }
    
    if (fileName == null) {
      // Если кода нет в маппинге, возвращаем текст
      return Text(
        code,
        style: TextStyle(
          fontSize: size * 0.8,
          color: Colors.red.withOpacity(0.7),
        ),
      );
    }

    return SizedBox.square(
      dimension: size,
      child: isRetro 
        ? Image.asset(
            assetPath,
            width: size,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            cacheWidth: (size * 2).toInt(),
            cacheHeight: (size * 2).toInt(),
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.broken_image,
                  size: size * 0.6,
                  color: Colors.red,
                ),
              );
            },
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) return child;
              return AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: child,
              );
            },
            semanticLabel: semanticLabel ?? 'Emoji $code',
          )
        : SvgPicture.asset(
            assetPath,
            width: size,
            height: size,
            fit: BoxFit.contain,
            placeholderBuilder: (context) => Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.image,
                size: size * 0.6,
                color: Colors.grey,
              ),
            ),
          ),
    );
  }
}

class EmojiSizes {
  static const double chat = 28.0;    // Размер смайлов в чате (увеличили!)
  static const double preview = 48.0;  // Размер смайлов в превью
  static const double input = 24.0;    // Размер смайлов в поле ввода
  static const double reaction = 16.0; // Размер смайлов в реакциях
}
