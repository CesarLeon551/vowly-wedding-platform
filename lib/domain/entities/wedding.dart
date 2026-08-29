class Wedding {
  const Wedding({
    required this.id,
    required this.name,
    required this.date,
    required this.coupleUids,
    required this.slug,
  });

  final String id;
  final String name;
  final DateTime date;
  final List<String> coupleUids;

  /// Usado en la URL de la página pública: /boda/{slug}
  final String slug;

  int get daysRemaining => date.difference(DateTime.now()).inDays;
}
