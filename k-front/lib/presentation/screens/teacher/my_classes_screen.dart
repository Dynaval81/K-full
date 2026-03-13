import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:knoty/core/controllers/auth_controller.dart';
import 'package:knoty/l10n/app_localizations.dart';
import 'package:knoty/presentation/widgets/knoty_app_bar.dart';
import 'package:knoty/presentation/widgets/locked_feature_wrapper.dart';

class MyClassesScreen extends StatelessWidget {
  const MyClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = context.watch<AuthController>().currentUser;
    final isVerified = user?.isSchoolVerified ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: KnotyAppBar(title: l10n.teacherClassesTitle),
      body: LockedFeatureWrapper(
        isLocked: !isVerified,
        title: l10n.lockedTeacherTitle,
        subtitle: l10n.lockedTeacherSubtitle,
        child: Center(child: Text(l10n.teacherClassesComingSoon,
          style: const TextStyle(color: Colors.grey, fontSize: 16))),
      ),
    );
  }
}