/// Client-side field validators. Each returns an error string or null if valid.
class Validators {
  Validators._();

  static String? email(String? v, {String errorMsg = 'Ungültige E-Mail'}) {
    if (v == null || v.trim().isEmpty) return 'E-Mail eingeben';
    final re = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    return re.hasMatch(v.trim()) ? null : errorMsg;
  }

  static String? password(String? v, {int minLength = 8, String? errorMsg}) {
    if (v == null || v.isEmpty) return 'Passwort eingeben';
    if (v.length < minLength) return errorMsg ?? 'Mindestens $minLength Zeichen';
    return null;
  }

  static String? firstName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Vorname eingeben';
    return null;
  }

  static String? lastName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Nachname eingeben';
    return null;
  }

  /// Validates KNOTY-XXXX-XXXX format (case-insensitive, 4 alphanumeric per segment).
  static String? activationCode(String? v) {
    if (v == null || v.trim().isEmpty) return 'Aktivierungscode eingeben';
    final re = RegExp(r'^KNOTY-[A-Z0-9]{4}-[A-Z0-9]{4}$', caseSensitive: false);
    return re.hasMatch(v.trim()) ? null : 'Format: KNOTY-XXXX-XXXX';
  }

  static String? notEmpty(String? v, {required String errorMsg}) {
    if (v == null || v.trim().isEmpty) return errorMsg;
    return null;
  }
}
