class UserLevel {
  static String titleForXp(int xp) {
    if (xp >= 600) return 'Yuqori daraja';
    if (xp >= 500) return "O'rta daraja";
    if (xp >= 100) return 'Tolib darajasi';
    return "Boshlang'ich";
  }

  static String initialsForName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
