enum VendorStatus { cotizando, contratado, cancelado }

const kVendorCategories = [
  'Salón',
  'Fotógrafo',
  'Videógrafo',
  'DJ',
  'Banda',
  'Florista',
  'Decoración',
  'Pastel',
  'Vestido',
  'Traje',
  'Maquillaje',
  'Peinado',
  'Transporte',
  'Invitaciones',
  'Otros',
];

class Vendor {
  const Vendor({
    required this.id,
    required this.category,
    required this.name,
    this.company,
    this.phone,
    this.whatsapp,
    this.email,
    required this.price,
    required this.deposit,
    this.status = VendorStatus.cotizando,
    this.notes,
    this.contractUrl,
    this.quoteUrl,
    this.receiptUrls = const [],
  });

  final String id;
  final String category;
  final String name;
  final String? company;
  final String? phone;
  final String? whatsapp;
  final String? email;
  final double price;
  final double deposit;
  final VendorStatus status;
  final String? notes;
  final String? contractUrl;
  final String? quoteUrl;
  final List<String> receiptUrls;

  double get balance => (price - deposit).clamp(0, double.infinity);

  factory Vendor.fromMap(String id, Map<String, dynamic> map) {
    return Vendor(
      id: id,
      category: map['category'] as String? ?? 'Otros',
      name: map['name'] as String? ?? '',
      company: map['company'] as String?,
      phone: map['phone'] as String?,
      whatsapp: map['whatsapp'] as String?,
      email: map['email'] as String?,
      price: (map['price'] as num?)?.toDouble() ?? 0,
      deposit: (map['deposit'] as num?)?.toDouble() ?? 0,
      status: VendorStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => VendorStatus.cotizando,
      ),
      notes: map['notes'] as String?,
      contractUrl: map['contractUrl'] as String?,
      quoteUrl: map['quoteUrl'] as String?,
      receiptUrls: (map['receiptUrls'] as List?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toMap() => {
        'category': category,
        'name': name,
        'company': company,
        'phone': phone,
        'whatsapp': whatsapp,
        'email': email,
        'price': price,
        'deposit': deposit,
        'status': status.name,
        'notes': notes,
        'contractUrl': contractUrl,
        'quoteUrl': quoteUrl,
        'receiptUrls': receiptUrls,
      };
}
