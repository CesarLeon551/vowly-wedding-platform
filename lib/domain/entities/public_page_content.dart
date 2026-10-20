/// Contenido editable de la página pública del invitado.
///
/// Está respaldado por un mapa para poder agregar campos nuevos sin
/// migrar datos: cada campo es un getter. Las claves legacy
/// (ceremonyInfo, receptionInfo, location, locationMapUrl) siguen
/// leyéndose como respaldo para no perder lo que ya se había escrito
/// en la versión anterior del editor.
class PublicPageContent {
  const PublicPageContent([this._data = const {}]);

  final Map<String, String> _data;

  static const textKeys = <String>[
    'coupleNames',
    'heroTagline',
    'heroLocation',
    'story',
    'ceremonyTitle',
    'ceremonyVenue',
    'ceremonyAddress',
    'ceremonyMapUrl',
    'ceremonyTime',
    'ceremonyNote',
    'receptionTitle',
    'receptionVenue',
    'receptionAddress',
    'receptionMapUrl',
    'receptionTime',
    'receptionNote',
    'dressCode',
    'rsvpDeadline',
    'spotifyPlaylistUrl',
    'giftRegistryUrl',
    'giftMessage',
    'instagramUrl',
  ];

  static const imageKeys = <String>[
    'heroImageUrl',
    'ceremonyImageUrl',
    'receptionImageUrl',
    'musicImageUrl',
    'giftImageUrl',
  ];

  static const _legacyKeys = <String>[
    'ceremonyInfo',
    'receptionInfo',
    'location',
    'locationMapUrl',
  ];

  factory PublicPageContent.fromMap(Map<String, dynamic>? map) {
    final data = <String, String>{};
    for (final entry in (map ?? const <String, dynamic>{}).entries) {
      final value = entry.value;
      if (value is String && value.trim().isNotEmpty) {
        data[entry.key] = value.trim();
      }
    }
    return PublicPageContent(data);
  }

  /// Incluye TODAS las claves conocidas (null cuando no hay valor) para
  /// que un set(merge: true) también limpie los campos que el usuario
  /// vació, y para que las claves legacy queden en null al guardar.
  Map<String, dynamic> toMap() => {
        for (final k in [...textKeys, ...imageKeys, ..._legacyKeys]) k: _data[k],
      };

  /// Valor ya resuelto (con respaldo legacy) para prellenar el editor.
  String? valueOf(String key) => switch (key) {
        'ceremonyAddress' => ceremonyAddress,
        'ceremonyMapUrl' => ceremonyMapUrl,
        'ceremonyNote' => ceremonyNote,
        'receptionNote' => receptionNote,
        _ => _data[key],
      };

  // Portada
  String? get coupleNames => _data['coupleNames'];
  String? get heroTagline => _data['heroTagline'];
  String? get heroLocation => _data['heroLocation'];
  String? get heroImageUrl => _data['heroImageUrl'];

  // Historia
  String? get story => _data['story'];

  // Ceremonia
  String? get ceremonyTitle => _data['ceremonyTitle'];
  String? get ceremonyVenue => _data['ceremonyVenue'];
  String? get ceremonyAddress => _data['ceremonyAddress'] ?? _data['location'];
  String? get ceremonyMapUrl => _data['ceremonyMapUrl'] ?? _data['locationMapUrl'];
  String? get ceremonyTime => _data['ceremonyTime'];
  String? get ceremonyNote => _data['ceremonyNote'] ?? _data['ceremonyInfo'];
  String? get ceremonyImageUrl => _data['ceremonyImageUrl'];

  // Recepción
  String? get receptionTitle => _data['receptionTitle'];
  String? get receptionVenue => _data['receptionVenue'];
  String? get receptionAddress => _data['receptionAddress'];
  String? get receptionMapUrl => _data['receptionMapUrl'];
  String? get receptionTime => _data['receptionTime'];
  String? get receptionNote => _data['receptionNote'] ?? _data['receptionInfo'];
  String? get receptionImageUrl => _data['receptionImageUrl'];

  // Otros
  String? get dressCode => _data['dressCode'];
  String? get rsvpDeadline => _data['rsvpDeadline'];
  String? get musicImageUrl => _data['musicImageUrl'];
  String? get spotifyPlaylistUrl => _data['spotifyPlaylistUrl'];
  String? get giftRegistryUrl => _data['giftRegistryUrl'];
  String? get giftMessage => _data['giftMessage'];
  String? get giftImageUrl => _data['giftImageUrl'];
  String? get instagramUrl => _data['instagramUrl'];
}
