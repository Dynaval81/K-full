// v3.2.0 — Smart header, tile colors, swipe back
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:knoty/core/controllers/auth_controller.dart';
import 'package:knoty/core/controllers/swipe_lock_controller.dart';
import 'package:knoty/core/enums/user_role.dart';
import 'package:knoty/l10n/app_localizations.dart';
import 'package:knoty/presentation/widgets/knoty_app_bar.dart';

// ── HAI3 Palette ─────────────────────────────────────────────────────────────

const Color _kBg        = Color(0xFFFFFFFF);
const Color _kSurface   = Color(0xFFF5F5F5);
const Color _kGold      = Color(0xFFE6B800);
const Color _kPrimary   = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF6B6B6B);
const Color _kBorder    = Color(0xFFE0E0E0);

// ── Enums & Models ───────────────────────────────────────────────────────────

enum _AiView { hub, chat, stickerLab, photoMagic }
enum _PhotoState { empty, loaded, processing, done }

class _ChatMsg {
  final bool isUser;
  String text;
  bool streaming;
  _ChatMsg({required this.isUser, required this.text, this.streaming = false});
}

class _StickerStyle {
  final String labelKey;
  final IconData icon;
  final List<String> promptSuffixes;
  const _StickerStyle({
    required this.labelKey,
    required this.icon,
    required this.promptSuffixes,
  });
}

// ── Mock data ─────────────────────────────────────────────────────────────────

const _kStyles = <_StickerStyle>[
  _StickerStyle(
    labelKey: 'aiStyleAnime',
    icon: Icons.face_retouching_natural_rounded,
    promptSuffixes: [', anime style, studio ghibli, soft shading, pastel colors, kawaii'],
  ),
  _StickerStyle(
    labelKey: 'aiStyle3d',
    icon: Icons.view_in_ar_rounded,
    promptSuffixes: [', 3D render, octane render, cinematic lighting, ultra detailed, 8k'],
  ),
  _StickerStyle(
    labelKey: 'aiStyleComic',
    icon: Icons.menu_book_rounded,
    promptSuffixes: [', comic book art, bold ink outlines, vibrant flat colors, pop art'],
  ),
  _StickerStyle(
    labelKey: 'aiStylePixel',
    icon: Icons.grid_on_rounded,
    promptSuffixes: [', pixel art, 16-bit retro style, low-poly, game sprite, bright palette'],
  ),
  _StickerStyle(
    labelKey: 'aiStyleRealist',
    icon: Icons.camera_alt_rounded,
    promptSuffixes: [', photorealistic, DSLR photo, natural lighting, highly detailed, sharp focus'],
  ),
];

const _kMockResponses = {
  'explain': '''**Thema erklärt**

Gute Frage! Hier ist eine klare Übersicht:

**Kernkonzepte:**
- **Definition** — Beginne mit der Grundidee
- **Beispiele** — Anwendungen aus dem Alltag
- **Formel** (falls zutreffend): `E = mc²`

**So merkst du es dir:**
1. Verstehe zuerst das **Warum**
2. Übe mit **3–5 Beispielen**
3. Erkläre es jemand anderem 💡

*Soll ich ein bestimmtes Thema erklären? Frag einfach!*''',
  'grammar': '''**Grammatikprüfung**

Ich helfe dir, perfekt zu schreiben! Das prüfe ich:

**Häufige Fehler:**
- Subjekt-Verb-**Übereinstimmung** (*Er gehen* → *Er **geht***)
- **Kommafehler** — zwei Sätze nur durch Komma verbunden
- Passiv-Übernutzung

**So nutzt du mich:**
Füge deinen Text ein und ich markiere:
✅ Korrekte Formulierungen
⚠️ Verbesserungsvorschläge
❌ Fehler

*Bereit — füge deinen Text unten ein!*''',
  'math': '''**Mathe-Hilfe** 📐

Ich helfe bei allen Schulmathematik-Themen:

| Stufe | Themen |
|---|---|
| **Grundlagen** | Brüche, Prozent, Verhältnisse |
| **Algebra** | Gleichungen, Funktionen, Graphen |
| **Geometrie** | Flächen, Volumen, Beweise |
| **Analysis** | Ableitungen, Integrale |

**Beispielaufgabe:**
Löse: `2x + 5 = 13`

> Schritt 1: `2x = 13 - 5 = 8`
> Schritt 2: `x = 8 / 2 = 4` ✅

*Welches Thema brauchst du?*''',
  'summarize': '''**Textzusammenfassung** 📝

Füge einen Text ein und du bekommst:

1. **Kurzfassung** — 1–2 Sätze
2. **Kernpunkte** — 3–5 Stichpunkte
3. **Wichtige Begriffe** — markierter Wortschatz
4. **Meine Einschätzung** — kurze Analyse

**Funktioniert gut für:**
- Lehrbuchkapitel
- Zeitungsartikel
- Facharbeiten
- Unterrichtsnotizen

*Los — füge deinen Text ein!*''',
  'default': '''**Hallo! Ich bin Knoty AI** ✨

Ich bin dein persönlicher Lernassistent. So helfe ich dir:

- 📚 **Erkläre** jedes Schulthema
- ✍️ **Prüfe** deine Grammatik und deinen Text
- 🔢 **Löse** Matheaufgaben Schritt für Schritt
- 📝 **Fasse** lange Texte zusammen
- 💡 **Brainstorme** Ideen für Aufsätze

Tippe deine Frage oder tippe auf einen der Vorschläge oben.

*Womit möchtest du heute anfangen?*''',
};

// ── Parent mock responses ─────────────────────────────────────────────────────

const _kParentResponses = {
  'tip': '''**Erziehungstipp des Tages** 🌱

Kinder brauchen klare Strukturen — und gleichzeitig Raum zum Wachsen.

**Worauf es ankommt:**
- **Verlässlichkeit** — feste Zeiten geben Sicherheit
- **Zuhören** — nicht sofort Lösungen anbieten, erst verstehen
- **Grenzen mit Erklärung** — „Weil ich es sage" reicht heute nicht mehr

**Heute ausprobieren:**
> Frag dein Kind heute Abend: *„Was war heute das Beste und was das Schwierigste?"*
> Nur zuhören — kein Kommentieren.

*Hast du eine konkrete Situation, bei der ich helfen kann?*''',

  'outing': '''**Ausflug-Ideen in der Region** 🗺️

Gemeinsame Erlebnisse stärken die Eltern-Kind-Bindung mehr als teures Spielzeug.

**Für jedes Wetter:**
| Idee | Alter | Aufwand |
|---|---|---|
| Naturpark-Wanderung | ab 5 | gering |
| Planetarium | ab 7 | mittel |
| Kletterhalle | ab 6 | mittel |
| Flomarkt zusammen | ab 8 | gering |
| Escape Room (junior) | ab 10 | hoch |

**Tipp:** Lass das Kind den Ausflug mitplanen — das steigert die Vorfreude enorm.

*Sag mir das Alter deines Kindes und die Stadt — ich mache konkretere Vorschläge.*''',

  'letter': '''**Brief an die Schule verfassen** ✉️

Ich helfe dir, professionell und freundlich zu kommunizieren.

**Häufige Anlässe:**
- Entschuldigung nach Krankheit
- Anfrage beim Klassenlehrer
- Anmeldung für Schulveranstaltung
- Feedback oder Beschwerde (konstruktiv)

**Struktur eines guten Elternbriefs:**
1. **Betreff** — kurz und klar
2. **Einleitung** — wer schreibt und warum
3. **Hauptteil** — konkret, sachlich, freundlich
4. **Abschluss** — Bitte um Antwort / Danke

*Schreib mir den Anlass — ich formuliere den Brief für dich.*''',

  'stress': '''**Schulstress beim Kind — was wirklich hilft** 💙

Druck entsteht oft nicht nur durch Noten, sondern durch soziale Faktoren.

**Signale erkennen:**
- Schlafprobleme oder Appetitlosigkeit
- Reizbarkeit oder Rückzug
- Körperliche Beschwerden ohne Befund

**Was du tun kannst:**
1. **Nicht sofort in Lösungsmodus** — erst Gefühle anerkennen
2. **Gemeinsam priorisieren** — was ist wirklich wichtig?
3. **Mit Lehrer sprechen** — früh, nicht erst bei Krise
4. **Pufferzeit einplanen** — nach der Schule erstmal 30 min. Pause

*Beschreibe die Situation genauer — ich helfe dir, einen Plan zu machen.*''',

  'default': '''**Hallo! Ich bin dein Eltern-Assistent** 👨‍👩‍👧

Ich begleite dich im Schulalltag deines Kindes. So kann ich helfen:

- 🌱 **Erziehungstipps** — alltagspraktische Ratschläge
- 🗺️ **Ausflug-Ideen** — Aktivitäten für die Familie
- ✉️ **Briefe schreiben** — an Schule, Lehrer, Behörden
- 💙 **Schulstress** — wenn das Kind Probleme hat
- 📅 **Elternsprechtag** — Vorbereitung und Gesprächstipps

*Womit kann ich dir heute helfen?*''',
};

// ── Main Screen ───────────────────────────────────────────────────────────────

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  _AiView _view = _AiView.hub;

  void _navigate(_AiView v, {String? prefill}) {
    HapticFeedback.lightImpact();
    setState(() {
      _view = v;
      _chatPrefill = prefill;
    });
    final lock = context.read<SwipeLockController>();
    if (v == _AiView.hub) {
      lock.unlock();
    } else {
      lock.lock();
    }
  }

  String? _chatPrefill;

  @override
  void dispose() {
    context.read<SwipeLockController>().unlock();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: _view == _AiView.hub,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _view != _AiView.hub) _navigate(_AiView.hub);
      },
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: _view == _AiView.hub
            ? KnotyAppBar(title: l10n.tabAi)
            : null,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: switch (_view) {
            _AiView.hub => _AiHub(
                onNavigate: _navigate,
                key: const ValueKey('hub'),
              ),
            _AiView.chat => _SwipeBackWrapper(
                onBack: () => _navigate(_AiView.hub),
                key: const ValueKey('chat_wrap'),
                child: _AiChatView(
                  onBack: () => _navigate(_AiView.hub),
                  prefill: _chatPrefill,
                  key: ValueKey('chat_$_chatPrefill'),
                ),
              ),
            _AiView.stickerLab => _SwipeBackWrapper(
                onBack: () => _navigate(_AiView.hub),
                key: const ValueKey('sticker_wrap'),
                child: _StickerLabView(
                  onBack: () => _navigate(_AiView.hub),
                  key: const ValueKey('sticker'),
                ),
              ),
            _AiView.photoMagic => _SwipeBackWrapper(
                onBack: () => _navigate(_AiView.hub),
                key: const ValueKey('photo_wrap'),
                child: _PhotoMagicView(
                  onBack: () => _navigate(_AiView.hub),
                  key: const ValueKey('photo'),
                ),
              ),
          },
        ),
      ),
    );
  }
}

// ── Swipe Back Wrapper ────────────────────────────────────────────────────────

class _SwipeBackWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback onBack;
  const _SwipeBackWrapper({
    required this.child,
    required this.onBack,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) > 280) {
          HapticFeedback.lightImpact();
          onBack();
        }
      },
      child: child,
    );
  }
}

// ── Smart Header ──────────────────────────────────────────────────────────────

/// Time-aware, tappable, breathing header.
/// - Morning  (05–11): gold  + sun icon   + "Guten Morgen, {name}!"
/// - Day      (12–16): gold  + brain icon + "Bereit für die Schule, {name}?"
/// - Evening  (17–22): amber + book icon  + "Hausaufgaben fertig, {name}?"
/// Tap → opens AI chat with "Surprise me" prompt.
class _SmartHeader extends StatefulWidget {
  final String name;
  final AppLocalizations l10n;
  final VoidCallback onTap;
  final bool isParent;
  final bool isTeacher;
  const _SmartHeader({
    required this.name,
    required this.l10n,
    required this.onTap,
    this.isParent = false,
    this.isTeacher = false,
  });

  @override
  State<_SmartHeader> createState() => _SmartHeaderState();
}

class _SmartHeaderState extends State<_SmartHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final int _hour;

  @override
  void initState() {
    super.initState();
    _hour = DateTime.now().hour;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Time helpers ──────────────────────────────────────────────────

  bool get _isMorning => _hour >= 5 && _hour < 12;
  bool get _isEvening => _hour >= 17 && _hour < 23;

  String _greeting() {
    if (widget.isParent) {
      if (_isMorning) return widget.l10n.aiParentGreetingMorning;
      if (_isEvening) return widget.l10n.aiParentGreetingEvening;
      return widget.l10n.aiParentGreetingDay;
    }
    if (widget.isTeacher) {
      if (_isMorning) return widget.l10n.aiTeacherGreetingMorning(widget.name);
      if (_isEvening) return widget.l10n.aiTeacherGreetingEvening(widget.name);
      return widget.l10n.aiTeacherGreetingDay(widget.name);
    }
    if (_isMorning) return widget.l10n.aiGreetingMorning(widget.name);
    if (_isEvening) return widget.l10n.aiGreetingEvening(widget.name);
    return widget.l10n.aiGreeting(widget.name);
  }

  IconData _icon() {
    if (widget.isParent) return Icons.family_restroom_rounded;
    if (widget.isTeacher) return Icons.draw_rounded;
    if (_isMorning) return Icons.wb_sunny_rounded;
    if (_isEvening) return Icons.menu_book_rounded;
    return Icons.psychology_rounded;
  }

  /// Two breathing colors per time-of-day. Gold for students/parents.
  ({Color from, Color to, Color border}) _theme() {
    if (widget.isParent) {
      return (
        from: const Color(0xFFFFF8E1),
        to: const Color(0xFFFFF0B0),
        border: const Color(0xFFE6B800),
      );
    }
    if (_isEvening) {
      return (
        from: const Color(0xFFFFF8E1),
        to: const Color(0xFFFFF0B0),
        border: const Color(0xFFE6B800),
      );
    }
    return (
      from: const Color(0xFFFFFDE7),
      to: const Color(0xFFFFF9C4),
      border: const Color(0xFFE6B800),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _theme();
    const accent = _kGold;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = (sin(_ctrl.value * 2 * pi) + 1) / 2;
        final bg = Color.lerp(theme.from, theme.to, t)!;

        // Pulsing rings use same phase
        final ringT1 = (_ctrl.value * 1.2) % 1.0;
        final ringT2 = (_ctrl.value * 1.2 + 0.5) % 1.0;

        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.border.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Animated icon with pulsing rings
                SizedBox(
                  width: 64,
                  height: 64,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      for (final rt in [ringT1, ringT2]) ...[
                        Opacity(
                          opacity: ((1 - rt) * 0.35).clamp(0.0, 0.35),
                          child: Container(
                            width: 40 + rt * 28,
                            height: 40 + rt * 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: accent, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.20),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_icon(), color: accent, size: 28),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _greeting(),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _kPrimary,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.l10n.aiHubSubtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _kSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Tap affordance — chevron chip
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: accent,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Hub ───────────────────────────────────────────────────────────────────────

class _AiHub extends StatelessWidget {
  final void Function(_AiView, {String? prefill}) onNavigate;
  const _AiHub({required this.onNavigate, super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthController>();
    final name = auth.currentUser?.firstName?.trim() ??
        auth.currentUser?.username ??
        '…';
    final role = auth.currentUser?.role;
    final isParent  = role == UserRole.parent;
    final isTeacher = role == UserRole.teacher;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SmartHeader(
            name: name,
            l10n: l10n,
            isParent: isParent,
            isTeacher: isTeacher,
            onTap: () => onNavigate(
              _AiView.chat,
              prefill: isParent
                  ? l10n.aiParentChipTip
                  : isTeacher
                      ? l10n.aiTeacherChipTest
                      : l10n.aiSurpriseMe,
            ),
          ),
          const SizedBox(height: 20),

          if (isTeacher) ...[
            // Teacher hub — test + lesson plan top row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _FeatureTile(
                      icon: Icons.quiz_rounded,
                      title: l10n.aiTeacherTile1Title,
                      subtitle: l10n.aiTeacherTile1Subtitle,
                      badge: 'KI',
                      bgColor: _kBg,
                      accentColor: _kGold,
                      onTap: () => onNavigate(_AiView.chat, prefill: l10n.aiTeacherChipTest),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _FeatureTile(
                      icon: Icons.calendar_today_rounded,
                      title: l10n.aiTeacherTile2Title,
                      subtitle: l10n.aiTeacherTile2Subtitle,
                      bgColor: const Color(0xFFFFF8E1),
                      accentColor: _kGold,
                      onTap: () => onNavigate(_AiView.chat, prefill: l10n.aiTeacherChipPlan),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _FeatureTile(
                icon: Icons.rate_review_rounded,
                title: l10n.aiTeacherTile3Title,
                subtitle: l10n.aiTeacherTile3Subtitle,
                badge: 'NEU',
                horizontal: true,
                bgColor: _kSurface,
                accentColor: _kPrimary,
                onTap: () => onNavigate(_AiView.chat, prefill: l10n.aiTeacherChipCheck),
              ),
            ),
            const SizedBox(height: 20),
            // Quick chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  l10n.aiTeacherChipTest,
                  l10n.aiTeacherChipPlan,
                  l10n.aiTeacherChipCheck,
                  l10n.aiTeacherChipIdea,
                ].map((chip) => ActionChip(
                  label: Text(chip),
                  onPressed: () => onNavigate(_AiView.chat, prefill: chip),
                  backgroundColor: _kSurface,
                  side: const BorderSide(color: _kBorder),
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    color: _kPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                )).toList(),
              ),
            ),
          ] else if (isParent) ...[
            // Parent hub — advisor + outings top row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _FeatureTile(
                      icon: Icons.support_agent_rounded,
                      title: l10n.aiParentTile1Title,
                      subtitle: l10n.aiParentTile1Subtitle,
                      badge: 'KI',
                      bgColor: _kBg,
                      accentColor: _kGold,
                      onTap: () => onNavigate(_AiView.chat, prefill: l10n.aiParentChipTip),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _FeatureTile(
                      icon: Icons.map_rounded,
                      title: l10n.aiParentTile2Title,
                      subtitle: l10n.aiParentTile2Subtitle,
                      bgColor: const Color(0xFFFFF8E1),
                      accentColor: _kGold,
                      onTap: () => onNavigate(_AiView.chat, prefill: l10n.aiParentChipOuting),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _FeatureTile(
                icon: Icons.edit_note_rounded,
                title: l10n.aiParentTile3Title,
                subtitle: l10n.aiParentTile3Subtitle,
                badge: 'NEU',
                horizontal: true,
                bgColor: const Color(0xFFEEEEEE),
                accentColor: const Color(0xFF1A1A1A),
                onTap: () => onNavigate(_AiView.chat, prefill: l10n.aiParentChipLetter),
              ),
            ),
          ] else ...[
            // Student hub — chat + sticker top row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _FeatureTile(
                      icon: Icons.auto_awesome_rounded,
                      title: l10n.aiChatTitle,
                      subtitle: l10n.aiChatSubtitle,
                      badge: 'GPT',
                      bgColor: _kBg,
                      accentColor: _kGold,
                      onTap: () => onNavigate(_AiView.chat),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _FeatureTile(
                      icon: Icons.brush_rounded,
                      title: l10n.aiStickerTitle,
                      subtitle: l10n.aiStickerSubtitle,
                      bgColor: const Color(0xFFFFEBEE),
                      accentColor: const Color(0xFFCC0000),
                      onTap: () => onNavigate(_AiView.stickerLab),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _FeatureTile(
                icon: Icons.auto_fix_high_rounded,
                title: l10n.aiPhotoTitle,
                subtitle: l10n.aiPhotoSubtitle,
                badge: 'NEU',
                horizontal: true,
                bgColor: const Color(0xFFEEEEEE),
                accentColor: const Color(0xFF1A1A1A),
                onTap: () => onNavigate(_AiView.chat, prefill: l10n.aiPhotoSubtitle),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Feature Tile ──────────────────────────────────────────────────────────────

class _FeatureTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final bool horizontal;
  final Color bgColor;
  final Color accentColor;
  final VoidCallback onTap;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.horizontal = false,
    this.bgColor = _kSurface,
    this.accentColor = _kGold,
  });

  @override
  State<_FeatureTile> createState() => _FeatureTileState();
}

class _FeatureTileState extends State<_FeatureTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.bgColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.accentColor.withValues(alpha: 0.25),
            ),
          ),
          child: widget.horizontal ? _horizontal() : _vertical(),
        ),
      ),
    );
  }

  Widget _vertical() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _iconChip(),
          const SizedBox(height: 16),
          _titleRow(),
          const SizedBox(height: 4),
          Text(
            widget.subtitle,
            style: const TextStyle(fontSize: 13, color: _kSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );

  Widget _horizontal() => Row(
        children: [
          _iconChip(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _titleRow(),
                const SizedBox(height: 4),
                Text(
                  widget.subtitle,
                  style: const TextStyle(fontSize: 13, color: _kSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: _kSecondary, size: 20),
        ],
      );

  Widget _iconChip() => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: widget.accentColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(widget.icon, color: widget.accentColor, size: 22),
      );

  Widget _titleRow() => Row(
        children: [
          Flexible(
            child: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _kPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.badge != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: widget.accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.badge!,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: widget.accentColor,
                ),
              ),
            ),
          ],
        ],
      );
}


// ── Chat View ─────────────────────────────────────────────────────────────────

class _AiChatView extends StatefulWidget {
  final VoidCallback onBack;
  final String? prefill;
  const _AiChatView({required this.onBack, this.prefill, super.key});

  @override
  State<_AiChatView> createState() => _AiChatViewState();
}

class _AiChatViewState extends State<_AiChatView> {
  final List<_ChatMsg> _msgs = [];
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _streaming = false;
  Timer? _streamTimer;

  @override
  void initState() {
    super.initState();
    if (widget.prefill != null && widget.prefill!.isNotEmpty) {
      _input.text = widget.prefill!;
    }
  }

  @override
  void dispose() {
    _streamTimer?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool get _isParent =>
      context.read<AuthController>().currentUser?.role == UserRole.parent;

  void _cancelStream() {
    _streamTimer?.cancel();
    _streamTimer = null;
    if (_msgs.isNotEmpty && _msgs.last.streaming) {
      setState(() {
        _msgs.last.streaming = false;
        _streaming = false;
      });
    } else {
      setState(() => _streaming = false);
    }
  }

  String _pickResponse(String text) {
    final lower = text.toLowerCase();
    if (_isParent) {
      if (lower.contains('tipp') || lower.contains('erziehung') || lower.contains('rat')) {
        return _kParentResponses['tip']!;
      }
      if (lower.contains('ausflug') || lower.contains('aktivit') || lower.contains('ideen')) {
        return _kParentResponses['outing']!;
      }
      if (lower.contains('brief') || lower.contains('schreiben') || lower.contains('letter')) {
        return _kParentResponses['letter']!;
      }
      if (lower.contains('stress') || lower.contains('problem') || lower.contains('schulst')) {
        return _kParentResponses['stress']!;
      }
      return _kParentResponses['default']!;
    }
    if (lower.contains('explain') || lower.contains('erkläre') ||
        lower.contains(RegExp(r'(aiChipExplain|topic|thema)'))) {
      return _kMockResponses['explain']!;
    }
    if (lower.contains('grammar') || lower.contains('grammatik')) {
      return _kMockResponses['grammar']!;
    }
    if (lower.contains('math') || lower.contains('mathe')) {
      return _kMockResponses['math']!;
    }
    if (lower.contains('summarize') || lower.contains('zusammen')) {
      return _kMockResponses['summarize']!;
    }
    return _kMockResponses['default']!;
  }

  void _send([String? override]) {
    final text = (override ?? _input.text).trim();
    if (text.isEmpty || _streaming) return;
    _input.clear();
    setState(() {
      _msgs.add(_ChatMsg(isUser: true, text: text));
    });
    _scrollToBottom();

    final full = _pickResponse(text);
    final aiMsg = _ChatMsg(isUser: false, text: '', streaming: true);
    setState(() {
      _streaming = true;
      _msgs.add(aiMsg);
    });
    _scrollToBottom();

    final rng = Random();
    int idx = 0;
    _streamTimer = Timer.periodic(const Duration(milliseconds: 18), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      final step = 1 + rng.nextInt(3);
      idx = (idx + step).clamp(0, full.length);
      setState(() {
        aiMsg.text = full.substring(0, idx);
      });
      _scrollToBottom();
      if (idx >= full.length) {
        t.cancel();
        setState(() {
          aiMsg.streaming = false;
          _streaming = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        _ChatHeader(
          title: l10n.aiChatTitle,
          onBack: () {
            _cancelStream();
            widget.onBack();
          },
          onNew: () {
            _cancelStream();
            setState(() => _msgs.clear());
          },
          newTooltip: l10n.aiNewChat,
        ),
        Expanded(
          child: _msgs.isEmpty
              ? _EmptyChat(
                  l10n: l10n,
                  onChip: (q) => _send(q),
                )
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: _msgs.length,
                  itemBuilder: (_, i) {
                    final m = _msgs[i];
                    return m.isUser
                        ? _UserBubble(text: m.text)
                        : _AiBubble(text: m.text, streaming: m.streaming);
                  },
                ),
        ),
        _ChatInput(
          controller: _input,
          hint: l10n.aiInputHint,
          stopLabel: l10n.aiStop,
          enabled: !_streaming,
          onSend: () => _send(),
          onStop: _cancelStream,
        ),
      ],
    );
  }
}

// Simple header row used inside Column (replaces nested Scaffold appBar)
class _ChatHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback? onNew;
  final String? newTooltip;
  const _ChatHeader({
    required this.title,
    required this.onBack,
    this.onNew,
    this.newTooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: _kBg,
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _kPrimary),
          onPressed: onBack,
        ),
        Expanded(
          child: Text(title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _kPrimary)),
        ),
        if (onNew != null)
          IconButton(
            icon: const Icon(Icons.add_rounded, color: _kPrimary),
            tooltip: newTooltip,
            onPressed: onNew,
          ),
      ]),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  final AppLocalizations l10n;
  final void Function(String) onChip;
  const _EmptyChat({required this.l10n, required this.onChip});

  @override
  Widget build(BuildContext context) {
    final isParent = context.read<AuthController>().currentUser?.role == UserRole.parent;
    final chips = isParent
        ? [
            (label: l10n.aiParentChipTip, q: l10n.aiParentChipTip),
            (label: l10n.aiParentChipOuting, q: l10n.aiParentChipOuting),
            (label: l10n.aiParentChipLetter, q: l10n.aiParentChipLetter),
            (label: l10n.aiParentChipStress, q: l10n.aiParentChipStress),
          ]
        : [
            (label: l10n.aiChipExplain, q: 'explain'),
            (label: l10n.aiChipGrammar, q: 'grammar'),
            (label: l10n.aiChipSummarize, q: 'summarize'),
            (label: l10n.aiChipMath, q: 'math'),
          ];
    const chipAccent = _kGold;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: chipAccent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isParent ? Icons.family_restroom_rounded : Icons.psychology_rounded,
                color: chipAccent,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isParent ? l10n.aiParentEmptyTitle : l10n.aiEmptyTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _kPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isParent
                  ? l10n.aiParentEmptySubtitle
                  : l10n.aiEmptySubtitle,
              style: const TextStyle(fontSize: 15, color: _kSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: chips.map((c) => ActionChip(
                    label: Text(c.label),
                    onPressed: () => onChip(c.q),
                    backgroundColor: _kSurface,
                    side: const BorderSide(color: _kBorder),
                    labelStyle: const TextStyle(
                      fontSize: 13,
                      color: _kPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  final String text;
  const _UserBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _kGold,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            color: _kPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _AiBubble extends StatelessWidget {
  final String text;
  final bool streaming;
  const _AiBubble({required this.text, required this.streaming});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 48),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          border: Border.all(color: _kBorder),
        ),
        child: streaming && text.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: _ThinkingDots(),
              )
            : Padding(
                padding: const EdgeInsets.all(14),
                child: MarkdownBody(
                  data: text,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(
                        fontSize: 15, color: _kPrimary, height: 1.5),
                    strong: const TextStyle(
                        fontWeight: FontWeight.w700, color: _kPrimary),
                    code: TextStyle(
                      fontFamily: 'monospace',
                      backgroundColor: _kGold.withValues(alpha: 0.10),
                      color: _kPrimary,
                      fontSize: 13,
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: _kGold.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kBorder),
                    ),
                    blockquoteDecoration: BoxDecoration(
                      border: Border(
                          left: BorderSide(
                              color: _kGold.withValues(alpha: 0.6), width: 3)),
                    ),
                    blockquotePadding: const EdgeInsets.only(left: 12),
                    h1: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _kPrimary),
                    h2: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary),
                    h3: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary),
                    listBullet: const TextStyle(color: _kGold, fontSize: 15),
                    tableBody: const TextStyle(fontSize: 13, color: _kPrimary),
                    tableHead: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: _kPrimary),
                    tableBorder: TableBorder.all(color: _kBorder),
                  ),
                ),
              ),
      ),
    );
  }
}

class _ThinkingDots extends StatefulWidget {
  const _ThinkingDots();

  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final opacity =
              ((sin(_ctrl.value * 2 * pi - i * pi / 3) + 1) / 2 * 0.9 + 0.1)
                  .clamp(0.0, 1.0);
          return Opacity(
            opacity: opacity,
            child: Container(
              width: 7,
              height: 7,
              margin: EdgeInsets.only(right: i < 2 ? 5 : 0),
              decoration: const BoxDecoration(
                color: _kGold,
                shape: BoxShape.circle,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String stopLabel;
  final bool enabled;
  final VoidCallback onSend;
  final VoidCallback onStop;

  const _ChatInput({
    required this.controller,
    required this.hint,
    required this.stopLabel,
    required this.enabled,
    required this.onSend,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: _kBg,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stop button row — only visible during streaming
            if (!enabled)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GestureDetector(
                  onTap: onStop,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: _kSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _kBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          stopLabel,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: enabled,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: const TextStyle(color: _kSecondary, fontSize: 15),
                      filled: true,
                      fillColor: _kSurface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: _kBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: _kBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: _kGold, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: enabled ? onSend : null,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: enabled ? _kGold : _kSurface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.send_rounded,
                      size: 20,
                      color: enabled ? _kPrimary : _kSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sticker Lab ───────────────────────────────────────────────────────────────

class _StickerLabView extends StatefulWidget {
  final VoidCallback onBack;
  const _StickerLabView({required this.onBack, super.key});

  @override
  State<_StickerLabView> createState() => _StickerLabViewState();
}

class _StickerLabViewState extends State<_StickerLabView> {
  int _selectedStyle = 0;
  final TextEditingController _prompt = TextEditingController();
  bool _generating = false;
  bool _hasResult = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _prompt.dispose();
    super.dispose();
  }

  void _improvePrompt() {
    final style = _kStyles[_selectedStyle];
    String text = _prompt.text.trim();
    for (final s in style.promptSuffixes) {
      if (text.endsWith(s)) {
        text = text.substring(0, text.length - s.length).trim();
      }
    }
    _prompt.text = text.isEmpty
        ? 'A cute cartoon character${style.promptSuffixes.first}'
        : '$text${style.promptSuffixes.first}';
  }

  void _generate() {
    if (_prompt.text.trim().isEmpty || _generating) return;
    setState(() {
      _generating = true;
      _hasResult = false;
    });
    _timer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _generating = false;
        _hasResult = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _StickerLabBody(
      onBack: widget.onBack,
      selectedStyle: _selectedStyle,
      onStyleSelected: (i) => setState(() => _selectedStyle = i),
      prompt: _prompt,
      generating: _generating,
      hasResult: _hasResult,
      onImprove: _improvePrompt,
      onGenerate: _generate,
    );
  }
}

class _StickerLabBody extends StatelessWidget {
  final VoidCallback onBack;
  final int selectedStyle;
  final void Function(int) onStyleSelected;
  final TextEditingController prompt;
  final bool generating;
  final bool hasResult;
  final VoidCallback onImprove;
  final VoidCallback onGenerate;

  const _StickerLabBody({
    required this.onBack,
    required this.selectedStyle,
    required this.onStyleSelected,
    required this.prompt,
    required this.generating,
    required this.hasResult,
    required this.onImprove,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        _ChatHeader(title: l10n.aiStickerTitle, onBack: onBack),
        Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Style carousel
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _kStyles.length,
                itemBuilder: (_, i) {
                  final s = _kStyles[i];
                  final selected = i == selectedStyle;
                  return GestureDetector(
                    onTap: () => onStyleSelected(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 80,
                      margin: EdgeInsets.only(right: i < _kStyles.length - 1 ? 10 : 0),
                      decoration: BoxDecoration(
                        color: selected ? _kGold.withValues(alpha: 0.12) : _kSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? _kGold : _kBorder,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            s.icon,
                            size: 26,
                            color: selected ? _kGold : _kSecondary,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _styleLabelFromKey(s.labelKey, l10n),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: selected ? _kGold : _kSecondary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Prompt input
            TextField(
              controller: prompt,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: l10n.aiStickerInputHint,
                hintStyle: const TextStyle(color: _kSecondary, fontSize: 15),
                filled: true,
                fillColor: _kSurface,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: _kBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: _kBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: _kGold, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onImprove,
                    icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                    label: Flexible(
                      child: Text(
                        l10n.aiImprovePrompt,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kGold,
                      side: const BorderSide(color: _kGold),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: generating ? null : onGenerate,
                    icon: generating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: _kPrimary))
                        : const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: Flexible(
                      child: Text(
                        generating ? l10n.aiProcessing : l10n.aiGenerate,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kGold,
                      foregroundColor: _kPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
              ],
            ),

            if (hasResult) ...[
              const SizedBox(height: 24),
              _GeneratedCard(l10n: l10n),
            ],
          ],
        ),
      )),
    ],
    );
  }

  String _styleLabelFromKey(String key, AppLocalizations l10n) {
    switch (key) {
      case 'aiStyleAnime':
        return l10n.aiStyleAnime;
      case 'aiStyle3d':
        return l10n.aiStyle3d;
      case 'aiStyleComic':
        return l10n.aiStyleComic;
      case 'aiStylePixel':
        return l10n.aiStylePixel;
      case 'aiStyleRealist':
        return l10n.aiStyleRealist;
      default:
        return key;
    }
  }
}

class _GeneratedCard extends StatefulWidget {
  final AppLocalizations l10n;
  const _GeneratedCard({required this.l10n});

  @override
  State<_GeneratedCard> createState() => _GeneratedCardState();
}

class _GeneratedCardState extends State<_GeneratedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Generated image placeholder
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t = _ctrl.value;
            return Container(
              height: 280,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment(-1 + t * 2, 0),
                  end: Alignment(1 + t * 2, 0),
                  colors: const [
                    Color(0xFFF5F5F5),
                    Color(0xFFEEEEEE),
                    Color(0xFFFFFDE7),
                    Color(0xFFEEEEEE),
                    Color(0xFFF5F5F5),
                  ],
                ),
                border: Border.all(color: _kBorder),
              ),
              child: const Center(
                child: Icon(
                  Icons.image_outlined,
                  size: 64,
                  color: Color(0xFFE0E0E0),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_rounded, size: 16),
                label: Flexible(
                  child: Text(
                    widget.l10n.aiSendAsSticker,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kGold,
                  side: const BorderSide(color: _kGold),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Photo Magic ───────────────────────────────────────────────────────────────

class _PhotoMagicView extends StatefulWidget {
  final VoidCallback onBack;
  const _PhotoMagicView({required this.onBack, super.key});

  @override
  State<_PhotoMagicView> createState() => _PhotoMagicViewState();
}

class _PhotoMagicViewState extends State<_PhotoMagicView> {
  _PhotoState _state = _PhotoState.empty;
  double _split = 0.5;

  void _upload() {
    setState(() => _state = _PhotoState.loaded);
  }

  void _process() {
    setState(() => _state = _PhotoState.processing);
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _state = _PhotoState.done);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        _ChatHeader(title: l10n.aiPhotoTitle, onBack: widget.onBack),
        Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (_state == _PhotoState.empty) _UploadPrompt(onTap: _upload, l10n: l10n),
            if (_state == _PhotoState.loaded || _state == _PhotoState.done)
              _BeforeAfterSlider(
                split: _split,
                onSplitChanged: (v) => setState(() => _split = v),
                isDone: _state == _PhotoState.done,
              ),
            if (_state == _PhotoState.processing)
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _kBorder),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: _kGold, strokeWidth: 2),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            if (_state == _PhotoState.loaded || _state == _PhotoState.done) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _ToolBtn(
                      icon: Icons.content_cut_rounded,
                      label: l10n.aiRemoveBg,
                      onTap: _process,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ToolBtn(
                      icon: Icons.enhance_photo_translate_rounded,
                      label: l10n.aiEnhance,
                      onTap: _process,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ToolBtn(
                      icon: Icons.style_rounded,
                      label: l10n.aiStylize,
                      onTap: _process,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      )),
    ],
    );
  }
}

class _UploadPrompt extends StatelessWidget {
  final VoidCallback onTap;
  final AppLocalizations l10n;
  const _UploadPrompt({required this.onTap, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 260,
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _kGold.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_photo_alternate_rounded,
                  color: _kGold, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.aiUploadPhoto,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'JPG, PNG',
              style: const TextStyle(fontSize: 13, color: _kSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _BeforeAfterSlider extends StatelessWidget {
  final double split;
  final void Function(double) onSplitChanged;
  final bool isDone;
  const _BeforeAfterSlider({
    required this.split,
    required this.onSplitChanged,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (d) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final newSplit = (split + d.delta.dx / box.size.width).clamp(0.05, 0.95);
        onSplitChanged(newSplit);
      },
      child: LayoutBuilder(
        builder: (_, constraints) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 300,
              width: constraints.maxWidth,
              child: Stack(
                children: [
                  // "After" layer (right side — processed)
                  Container(
                    color: isDone
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFF5F5F5),
                    child: Center(
                      child: Icon(
                        Icons.auto_fix_high_rounded,
                        size: 64,
                        color: isDone
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFE0E0E0),
                      ),
                    ),
                  ),
                  // "Before" layer (left side — original), clipped
                  ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: split,
                      child: SizedBox(
                        width: constraints.maxWidth,
                        height: 300,
                        child: Container(
                          color: _kSurface,
                          child: const Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 64,
                              color: Color(0xFFE0E0E0),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Divider line
                  Positioned(
                    left: constraints.maxWidth * split - 1,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      color: _kGold,
                    ),
                  ),
                  // Handle
                  Positioned(
                    left: constraints.maxWidth * split - 18,
                    top: 130,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: _kGold,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.unfold_more_rounded,
                        color: _kPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ToolBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: _kGold, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
