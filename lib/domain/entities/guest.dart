enum RsvpStatus { pendiente, confirmado, no_asistira }

class Guest {
  const Guest({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.email,
    this.group,
    this.invitedBy,
    required this.allowedCompanions,
    this.companions = const [],
    required this.isAdult,
    required this.rsvpStatus,
    this.dietaryRestrictions,
    this.tableId,
    this.notes,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? email;
  final String? group;
  final String? invitedBy;
  final int allowedCompanions;
  final List<String> companions;
  final bool isAdult;
  final RsvpStatus rsvpStatus;
  final String? dietaryRestrictions;
  final String? tableId;
  final String? notes;

  String get fullName => '$firstName $lastName'.trim();

  factory Guest.fromMap(String id, Map<String, dynamic> map) {
    return Guest(
      id: id,
      firstName: map['firstName'] as String? ?? '',
      lastName: map['lastName'] as String? ?? '',
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      group: map['group'] as String?,
      invitedBy: map['invitedBy'] as String?,
      allowedCompanions: (map['allowedCompanions'] as num?)?.toInt() ?? 0,
      companions: (map['companions'] as List?)?.cast<String>() ?? [],
      isAdult: map['isAdult'] as bool? ?? true,
      rsvpStatus: RsvpStatus.values.firstWhere(
        (s) => s.name == map['rsvpStatus'],
        orElse: () => RsvpStatus.pendiente,
      ),
      dietaryRestrictions: map['dietaryRestrictions'] as String?,
      tableId: map['tableId'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'email': email,
        'group': group,
        'invitedBy': invitedBy,
        'allowedCompanions': allowedCompanions,
        'companions': companions,
        'isAdult': isAdult,
        'rsvpStatus': rsvpStatus.name,
        'dietaryRestrictions': dietaryRestrictions,
        'tableId': tableId,
        'notes': notes,
      };

  /// Solo los campos que un invitado sin cuenta puede modificar desde la
  /// página pública de RSVP — coincide con lo que permiten las Security
  /// Rules para escritura no autenticada.
  Map<String, dynamic> toRsvpUpdateMap() => {
        'rsvpStatus': rsvpStatus.name,
        'companions': companions,
        'dietaryRestrictions': dietaryRestrictions,
      };

  Guest copyWith({
    RsvpStatus? rsvpStatus,
    List<String>? companions,
    String? dietaryRestrictions,
  }) {
    return Guest(
      id: id,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      email: email,
      group: group,
      invitedBy: invitedBy,
      allowedCompanions: allowedCompanions,
      companions: companions ?? this.companions,
      isAdult: isAdult,
      rsvpStatus: rsvpStatus ?? this.rsvpStatus,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      tableId: tableId,
      notes: notes,
    );
  }
}
