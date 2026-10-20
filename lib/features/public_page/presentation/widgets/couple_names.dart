/// Separa "César y Karen" / "Ana & Luis" en dos nombres para poder
/// apilarlos en la portada, y deriva el monograma "C | K".
class CoupleNames {
  const CoupleNames(this.first, this.second);

  final String first;
  final String? second;

  factory CoupleNames.parse(String name) {
    final clean = name.trim();
    final match = RegExp(r'\s+(?:y|&|e|and)\s+', caseSensitive: false).firstMatch(clean);
    if (match == null) return CoupleNames(clean, null);

    final a = clean.substring(0, match.start).trim();
    final b = clean.substring(match.end).trim();
    if (a.isEmpty || b.isEmpty) return CoupleNames(clean, null);
    return CoupleNames(a, b);
  }

  String get monogram {
    String initial(String s) => s.isEmpty ? '' : s.substring(0, 1).toUpperCase();

    if (second != null) return '${initial(first)} | ${initial(second!)}';

    final words = first.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length >= 2) return '${initial(words[0])} | ${initial(words[1])}';
    return initial(first);
  }
}
