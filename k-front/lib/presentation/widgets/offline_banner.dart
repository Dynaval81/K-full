import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:knoty/core/connectivity_provider.dart';

/// Animated offline banner. Insert at the top of any Scaffold body.
///
/// ```dart
/// body: Column(children: [
///   const OfflineBanner(),
///   Expanded(child: content),
/// ])
/// ```
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isOnline = context.watch<ConnectivityProvider>().isOnline;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        axisAlignment: -1,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: isOnline
          ? const SizedBox.shrink(key: ValueKey('online'))
          : _Banner(key: const ValueKey('offline')),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 16, color: Color(0xFFE6B800)),
          const SizedBox(width: 8),
          Text(
            _label(context),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _label(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    switch (locale) {
      case 'de': return 'Keine Verbindung';
      case 'ru': return 'Нет подключения';
      default:   return 'No connection';
    }
  }
}
