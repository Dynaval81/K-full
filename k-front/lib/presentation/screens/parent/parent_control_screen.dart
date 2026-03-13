import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:knoty/core/controllers/auth_controller.dart';
import 'package:knoty/l10n/app_localizations.dart';
import 'package:knoty/presentation/widgets/knoty_app_bar.dart';
import 'package:knoty/presentation/widgets/locked_feature_wrapper.dart';

class ParentControlScreen extends StatelessWidget {
  const ParentControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = context.watch<AuthController>().currentUser;
    final isLinked = user?.linkedChildId != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: KnotyAppBar(title: l10n.parentTitle),
      body: LockedFeatureWrapper(
        isLocked: !isLinked,
        title: l10n.lockedNoChildTitle,
        subtitle: l10n.lockedNoChildSubtitle,
        child: const _ParentContent(),
      ),
    );
  }
}

class _ParentContent extends StatelessWidget {
  const _ParentContent();
  @override
  Widget build(BuildContext context) => const Center(
    child: Text('Elternbereich', style: TextStyle(color: Colors.grey, fontSize: 16)),
  );
}