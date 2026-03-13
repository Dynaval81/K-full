/// 🏷️ Verification Levels
/// Defines user verification levels for access control
enum VerificationLevel {
  /// Full access - verified user
  verified,
  
  /// Limited access - sandbox mode
  sandbox,
  
  /// No verification - guest/anonymous
  none,
}
