// v1.1.0
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:knoty/core/controllers/auth_controller.dart';
import 'package:knoty/l10n/app_localizations.dart';
import 'package:knoty/presentation/widgets/knoty_app_bar.dart';

class ParentControlScreen extends StatelessWidget {
  const ParentControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = context.watch<AuthController>().currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: KnotyAppBar(title: l10n.parentTitle),
      body: _ParentBody(
        confirmedChildId: user?.linkedChildId,
        linkedAccounts: user?.linkedAccounts ?? [],
      ),
    );
  }
}

class _ParentBody extends StatefulWidget {
  final String? confirmedChildId;
  final List<String> linkedAccounts;

  const _ParentBody({
    required this.confirmedChildId,
    required this.linkedAccounts,
  });

  @override
  State<_ParentBody> createState() => _ParentBodyState();
}

class _ParentBodyState extends State<_ParentBody> {
  final _ctrl = TextEditingController();
  List<String> _pendingKns = [];
  bool _loading = false;
  String? _error;

  static const _prefsKey = 'parent_pending_kns';

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadPending() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefsKey) ?? [];
    // Убираем те, что уже подтверждены
    final confirmed = {
      if (widget.confirmedChildId != null) widget.confirmedChildId!,
      ...widget.linkedAccounts,
    };
    setState(() => _pendingKns = saved.where((k) => !confirmed.contains(k)).toList());
  }

  Future<void> _savePending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _pendingKns);
  }

  Future<void> _submit() async {
    final kn = _ctrl.text.trim().toUpperCase();
    if (kn.isEmpty) return;

    final knRegex = RegExp(r'^KN-\d{6}$');
    if (!knRegex.hasMatch(kn)) {
      setState(() => _error = 'Format: KN-123456');
      return;
    }

    if (_pendingKns.contains(kn) || widget.linkedAccounts.contains(kn) || widget.confirmedChildId == kn) {
      setState(() => _error = 'Bereits hinzugefügt');
      return;
    }

    setState(() { _loading = true; _error = null; });

    // TODO: POST /auth/link-child when backend endpoint is ready
    await Future.delayed(const Duration(milliseconds: 600));

    setState(() {
      _pendingKns.add(kn);
      _loading = false;
      _ctrl.clear();
    });
    await _savePending();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final confirmedList = [
      if (widget.confirmedChildId != null) widget.confirmedChildId!,
      ...widget.linkedAccounts.where((k) => k != widget.confirmedChildId),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Input card ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.registerKnChildLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.registerInfoParent,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(14),
                        border: _error != null
                            ? Border.all(color: Colors.redAccent, width: 1)
                            : null,
                      ),
                      child: TextField(
                        controller: _ctrl,
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(fontSize: 15, fontFamily: 'monospace'),
                        decoration: InputDecoration(
                          hintText: l10n.registerKnChildHint,
                          hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                        onChanged: (_) { if (_error != null) setState(() => _error = null); },
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 52, height: 48,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE6B800),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.add_rounded, size: 22),
                    ),
                  ),
                ]),
                if (_error != null) ...[
                  const SizedBox(height: 6),
                  Text(_error!,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.redAccent)),
                ],
              ],
            ),
          ),

          // ── Confirmed children ───────────────────────────────
          if (confirmedList.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              l10n.parentTitle,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9E9E9E)),
            ),
            const SizedBox(height: 8),
            ...confirmedList.map((kn) => _ChildTile(
                  kn: kn,
                  status: _ChildStatus.confirmed,
                )),
          ],

          // ── Pending children ─────────────────────────────────
          if (_pendingKns.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Warte auf Bestätigung',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9E9E9E)),
            ),
            const SizedBox(height: 8),
            ..._pendingKns.map((kn) => _ChildTile(
                  kn: kn,
                  status: _ChildStatus.pending,
                  onRemove: () async {
                    setState(() => _pendingKns.remove(kn));
                    await _savePending();
                  },
                )),
          ],
        ],
      ),
    );
  }
}

enum _ChildStatus { confirmed, pending }

class _ChildTile extends StatelessWidget {
  final String kn;
  final _ChildStatus status;
  final VoidCallback? onRemove;

  const _ChildTile({required this.kn, required this.status, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final isConfirmed = status == _ChildStatus.confirmed;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          )
        ],
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: isConfirmed
                ? const Color(0xFFE8F5E9)
                : const Color(0xFFFFF8E1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isConfirmed ? Icons.child_care_rounded : Icons.hourglass_top_rounded,
            size: 20,
            color: isConfirmed
                ? const Color(0xFF4CAF50)
                : const Color(0xFFE6B800),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KN-$kn',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                  fontFamily: 'monospace'),
            ),
            const SizedBox(height: 2),
            Text(
              isConfirmed ? 'Bestätigt' : 'Warte auf Bestätigung',
              style: TextStyle(
                  fontSize: 12,
                  color: isConfirmed
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFE6B800)),
            ),
          ],
        )),
        if (!isConfirmed && onRemove != null)
          GestureDetector(
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close_rounded,
                  size: 18, color: Color(0xFFBDBDBD)),
            ),
          ),
      ]),
    );
  }
}
