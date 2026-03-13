// v1.2.0
// Хранит emoji как Unicode Private Use Area символы (U+E000+)
// Курсор всегда точный т.к. каждый emoji = ровно 1 char в строке
// Map<int codePoint, String emojiCode> хранится отдельно
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Контроллер который хранит кастомные emoji как одиночные символы
/// из Unicode Private Use Area (U+E000..U+F8FF).
/// Это решает проблему смещения курсора — каждый emoji ровно 1 char.
class EmojiTextEditingController extends TextEditingController {
  // code point → emoji asset code, напр. 0xE000 → 'icon_cool'
  final Map<int, String> _emojiMap = {};
  // Следующий свободный PUA code point
  int _nextPua = 0xE000;

  EmojiTextEditingController({String? text}) : super(text: text);

  static final _knownSvg = <String>{
    'icon_e_smile','icon_e_biggrin','icon_e_wink','icon_e_sad',
    'icon_e_surprised','icon_e_confused','icon_e_geek','icon_e_ugeek',
    'icon_cool','icon_lol','icon_lolno','icon_mad','icon_razz',
    'icon_redface','icon_rolleyes','icon_neutral','icon_twisted','icon_evil',
    'icon_cry','icon_eek','icon_eh','icon_angel','icon_arrow','icon_clap',
    'icon_crazy','icon_exclaim','icon_idea','icon_mrgreen','icon_problem',
    'icon_question','icon_shh','icon_shifty','icon_sick','icon_silent',
    'icon_think','icon_thumbdown','icon_thumbup','icon_wave','icon_wtf','icon_yawn',
  };

  bool isSvg(String code) => _knownSvg.contains(code);

  /// Вставляет emoji в позицию курсора. Возвращает true при успехе.
  void insertEmoji(String code) {
    // Находим или создаём PUA char для этого кода
    final cp = _getOrRegister(code);
    final ch = String.fromCharCode(cp);

    final text = this.text;
    final sel  = selection;
    final pos  = (sel.isValid && sel.start >= 0)
        ? sel.start.clamp(0, text.length)
        : text.length;

    // Пробел перед если предыдущий не пробел
    final needsSpace = pos > 0 && text[pos - 1] != ' ';
    final insert = (needsSpace ? ' ' : '') + ch;
    final next = text.replaceRange(pos, pos, insert);
    final newOffset = pos + insert.length;

    // copyWith + composing.empty — IME не будет трогать уже вставленный char
    value = value.copyWith(
      text: next,
      selection: TextSelection.collapsed(offset: newOffset),
      composing: TextRange.empty,
    );
  }

  int _getOrRegister(String code) {
    for (final e in _emojiMap.entries) {
      if (e.value == code) return e.key;
    }
    final cp = _nextPua++;
    _emojiMap[cp] = code;
    return cp;
  }

  /// Конвертирует внутренний текст (с PUA chars) в формат [code]
  /// для отправки/сохранения
  String toDisplayText() {
    final sb = StringBuffer();
    for (final ch in text.runes) {
      final code = _emojiMap[ch];
      if (code != null) {
        sb.write('[$code]');
      } else {
        sb.writeCharCode(ch);
      }
    }
    return sb.toString();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (_emojiMap.isEmpty) {
      // Нет emoji — стандартный рендер Flutter (cursor идеален)
      return super.buildTextSpan(
          context: context, style: style, withComposing: withComposing);
    }

    final base = style ?? const TextStyle(
        fontSize: 16, color: Color(0xFF1A1A1A), height: 1.4);
    final spans = <InlineSpan>[];
    final fullText = text;
    final buf = StringBuffer();

    void flushBuf() {
      if (buf.isNotEmpty) {
        spans.add(TextSpan(text: buf.toString(), style: base));
        buf.clear();
      }
    }

    for (final cp in fullText.runes) {
      final emojiCode = _emojiMap[cp];
      if (emojiCode != null) {
        flushBuf();
        final isSvgEmoji = isSvg(emojiCode);
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: isSvgEmoji
                ? SvgPicture.asset('assets/emojis_v2/$emojiCode.svg',
                    width: 22, height: 22, fit: BoxFit.contain)
                : Image.asset('assets/emojis/$emojiCode.gif',
                    width: 22, height: 22,
                    fit: BoxFit.contain, gaplessPlayback: true),
          ),
        ));
      } else {
        buf.writeCharCode(cp);
      }
    }
    flushBuf();

    if (spans.isEmpty) {
      return TextSpan(text: fullText, style: base);
    }
    return TextSpan(style: style, children: spans);
  }
}