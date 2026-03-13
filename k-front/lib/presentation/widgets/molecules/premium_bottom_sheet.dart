import 'package:flutter/material.dart';
import 'package:knoty/core/constants.dart';
import 'package:knoty/presentation/atoms/airy_button.dart';

/// HAI3 Premium paywall bottom sheet – Airy style, 24dp+ corners, 20dp+ padding.
void showPremiumBottomSheet(BuildContext context, {String? title, String? message}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Icon(
              Icons.workspace_premium_rounded,
              size: 56,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              title ?? 'Upgrade to Premium',
              style: AppTextStyles.h3.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message ?? 'Use VPN and other premium features with a subscription.',
              style: AppTextStyles.body.copyWith(
                fontSize: 16,
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            AiryButton(
              text: 'Upgrade to Premium',
              onPressed: () => Navigator.of(context).pop(),
              fullWidth: true,
              height: 52,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Maybe later',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
