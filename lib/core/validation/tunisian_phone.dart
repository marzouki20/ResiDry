/// Valid telephone format, not proof of allocation or ownership.
/// INT numbering plan: eight digits; telephone services start with 2,3,4,5,7,9.
class TunisianPhone {
  static final _national = RegExp(r'^[234579][0-9]{7}$');
  static bool isValidNational(String value) => _national.hasMatch(value);
  static bool isValidInternational(String value) =>
      value.startsWith('+216') && isValidNational(value.substring(4));
  static String toInternational(String value) {
    if (!isValidNational(value)) {
      throw ArgumentError('Invalid Tunisian phone format');
    }
    return '+216$value';
  }
}
