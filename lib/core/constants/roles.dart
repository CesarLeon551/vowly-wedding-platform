/// Roles definidos en Fase 1. El valor coincide con lo que se guarda
/// en Firestore (`members/{uid}.role`) — no cambiar los strings sin
/// migrar los documentos existentes.
enum MemberRole {
  novio('novio'),
  colaborador('colaborador'),
  invitado('invitado');

  const MemberRole(this.value);
  final String value;

  static MemberRole fromString(String value) => switch (value) {
        'novio' => MemberRole.novio,
        'colaborador' => MemberRole.colaborador,
        _ => MemberRole.invitado,
      };
}

/// Módulos que un colaborador puede tener habilitados/deshabilitados.
/// Coincide con las llaves del mapa `members/{uid}.permissions`.
enum AppModule {
  budget,
  savings,
  guests,
  vendors,
  tasks,
  tables,
  timeline,
  music,
  gallery,
  documents,
}
