import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

import '../../../../domain/entities/guest.dart';
import '../../../../domain/entities/public_page_content.dart';
import '../../../../domain/entities/wedding.dart';
import '../../../auth/application/auth_providers.dart';
import '../../application/public_page_providers.dart';
import '../widgets/botanical.dart';
import '../widgets/countdown_tiles.dart';
import '../widgets/couple_names.dart';
import '../widgets/event_card.dart';
import '../widgets/gift_section.dart';
import '../widgets/guest_music_panel.dart';
import '../widgets/invitation_hero.dart';
import '../widgets/invitation_nav.dart';
import '../widgets/invitation_style.dart';
import '../widgets/invitation_widgets.dart';
import '../widgets/music_section.dart';
import '../widgets/reveal_on_scroll.dart';
import '../widgets/rsvp_section.dart';

class _NavTarget {
  const _NavTarget(this.label, this.key);

  final String label;

  /// null = "Inicio" (arriba de todo).
  final GlobalKey? key;
}

/// Invitación personalizada del invitado: /boda/:slug/i/:guestId
class GuestLandingScreen extends ConsumerStatefulWidget {
  const GuestLandingScreen({super.key, required this.slug, required this.guestId});

  final String slug;
  final String guestId;

  @override
  ConsumerState<GuestLandingScreen> createState() => _GuestLandingScreenState();
}

class _GuestLandingScreenState extends ConsumerState<GuestLandingScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scrollController = ScrollController();
  final _activeSection = ValueNotifier<int>(0);

  final _storyKey = GlobalKey();
  final _detailsKey = GlobalKey();
  final _musicKey = GlobalKey();
  final _giftKey = GlobalKey();
  final _rsvpKey = GlobalKey();

  List<_NavTarget> _targets = const [];

  Wedding? _wedding;
  Guest? _guest;
  bool _loading = true;
  String? _error;
  String? _sessionUid;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _activeSection.dispose();
    super.dispose();
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = message;
    });
  }

  Future<void> _load() async {
    try {
      final wedding = await ref.read(rsvpRepositoryProvider).findWeddingBySlug(widget.slug);
      if (wedding == null) return _fail('No encontramos esta boda.');

      final guest =
          await ref.read(rsvpRepositoryProvider).getGuestById(wedding.id, widget.guestId);
      if (guest == null) return _fail('Este link de invitación no es válido.');

      // La sesión anónima solo sirve para votar canciones. Si falla (por
      // ejemplo, el método anónimo no está activado en Firebase), la
      // invitación y el RSVP siguen funcionando; solo la música se oculta.
      String? uid;
      try {
        uid = await ensureGuestSession(ref.read(firebaseAuthProvider));
      } catch (_) {
        uid = null;
      }

      if (!mounted) return;
      setState(() {
        _wedding = wedding;
        _guest = guest;
        _sessionUid = uid;
        _loading = false;
      });
    } catch (_) {
      _fail('Ocurrió un error. Intenta de nuevo.');
    }
  }

  // Marca como activa la última sección cuyo borde superior ya pasó
  // por debajo de la barra de navegación.
  void _onScroll() {
    var active = 0;
    for (var i = 0; i < _targets.length; i++) {
      final box = _targets[i].key?.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached) continue;
      if (box.localToGlobal(Offset.zero).dy <= InvitationStyle.navHeight + 140) active = i;
    }
    if (_activeSection.value != active) _activeSection.value = active;
  }

  void _goTo(_NavTarget target) {
    final ctx = target.key?.currentContext;
    if (target.key == null || ctx == null) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
      return;
    }
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOutCubic,
      alignment: 0,
    );
  }

  Future<void> _open(String raw) async {
    final url = raw.trim();
    final uri = Uri.tryParse(url.startsWith('http') ? url : 'https://$url');
    if (uri == null) return;
    await launchUrl(uri, webOnlyWindowName: '_blank');
  }

  bool _has(String? s) => s != null && s.trim().isNotEmpty;

  bool _hasCeremony(PublicPageContent c) => [
        c.ceremonyVenue,
        c.ceremonyAddress,
        c.ceremonyMapUrl,
        c.ceremonyTime,
        c.ceremonyNote,
        c.ceremonyImageUrl,
      ].any(_has);

  bool _hasReception(PublicPageContent c) => [
        c.receptionVenue,
        c.receptionAddress,
        c.receptionMapUrl,
        c.receptionTime,
        c.receptionNote,
        c.receptionImageUrl,
      ].any(_has);

  Widget _centered(Widget child, {double maxWidth = InvitationStyle.maxContentWidth}) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: child),
      ),
    );
  }

  Widget _reveal(Widget child) => RevealOnScroll(controller: _scrollController, child: child);

  Widget _eventsRow(PublicPageContent c, double width) {
    final twoUp = width >= 900;
    final photoBeside = twoUp ? width >= 1180 : width >= 600;

    final cards = <Widget>[
      if (_hasCeremony(c))
        EventCard(
          icon: Icons.church_outlined,
          title: c.ceremonyTitle ?? 'Ceremonia',
          photoBeside: photoBeside,
          venue: c.ceremonyVenue,
          address: c.ceremonyAddress,
          mapUrl: c.ceremonyMapUrl,
          time: c.ceremonyTime,
          note: c.ceremonyNote,
          imageUrl: c.ceremonyImageUrl,
          onOpenUrl: _open,
        ),
      if (_hasReception(c))
        EventCard(
          icon: Icons.apartment_outlined,
          title: c.receptionTitle ?? 'Recepción',
          photoBeside: photoBeside,
          venue: c.receptionVenue,
          address: c.receptionAddress,
          mapUrl: c.receptionMapUrl,
          time: c.receptionTime,
          note: c.receptionNote,
          imageUrl: c.receptionImageUrl,
          onOpenUrl: _open,
        ),
    ];

    if (cards.isEmpty) return const SizedBox.shrink();

    if (twoUp && cards.length == 2) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: cards[0]),
          Container(
            width: 1,
            height: 260,
            margin: const EdgeInsets.symmetric(horizontal: 28),
            color: InvitationStyle.rose.withOpacity(0.7),
          ),
          Expanded(child: cards[1]),
        ],
      );
    }

    return Column(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: const OrnamentDivider(width: 140),
            ),
          cards[i],
        ],
      ],
    );
  }

  Widget _footer(String monogram, String displayName, String dateLabel, PublicPageContent c) {
    final line = Container(width: 80, height: 1, color: InvitationStyle.rose);

    return Container(
      width: double.infinity,
      color: InvitationStyle.ivory,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 48),
      child: Stack(
        children: [
          const Positioned(
            left: 0,
            bottom: 0,
            child: LeafBranch(color: InvitationStyle.wine, width: 100, height: 140),
          ),
          const Positioned(
            right: 0,
            bottom: 0,
            child: LeafBranch(color: InvitationStyle.wine, width: 100, height: 140, flipX: true),
          ),
          SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    line,
                    const SizedBox(width: 16),
                    Text(monogram, style: InvitationStyle.display(28, color: InvitationStyle.wine)),
                    const SizedBox(width: 16),
                    line,
                  ],
                ),
                const SizedBox(height: 10),
                Text(displayName, style: InvitationStyle.script(40), textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(
                  dateLabel,
                  style: InvitationStyle.display(20, fontStyle: FontStyle.italic),
                ),
                if (_has(c.heroLocation)) ...[
                  const SizedBox(height: 8),
                  Text(
                    c.heroLocation!.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: InvitationStyle.label(size: 11, spacing: 2.6),
                  ),
                ],
                if (_has(c.instagramUrl) || _has(c.spotifyPlaylistUrl)) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_has(c.instagramUrl))
                        IconButton(
                          tooltip: 'Instagram',
                          icon: const Icon(Icons.camera_alt_outlined, color: InvitationStyle.wine),
                          onPressed: () => _open(c.instagramUrl!),
                        ),
                      if (_has(c.spotifyPlaylistUrl))
                        IconButton(
                          tooltip: 'Playlist en Spotify',
                          icon: const Icon(Icons.headphones_outlined, color: InvitationStyle.wine),
                          onPressed: () => _open(c.spotifyPlaylistUrl!),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: InvitationStyle.ivory,
        body: Center(
          child: CircularProgressIndicator(color: InvitationStyle.burgundy, strokeWidth: 2),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: InvitationStyle.ivory,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite_border, color: InvitationStyle.wine, size: 40),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center, style: InvitationStyle.script(36)),
              ],
            ),
          ),
        ),
      );
    }

    final wedding = _wedding!;
    final guest = _guest!;
    final content = ref.watch(publicPageContentStreamProvider(wedding.id)).valueOrNull ??
        const PublicPageContent();
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;

    final displayName = content.coupleNames ?? wedding.name;
    final names = CoupleNames.parse(displayName);
    final dateLabel = DateFormat('dd · MM · yyyy').format(wedding.date);

    final hasStory = _has(content.story);
    final hasEvents = _hasCeremony(content) || _hasReception(content) || _has(content.dressCode);
    final hasGift = _has(content.giftRegistryUrl);

    _targets = [
      const _NavTarget('Inicio', null),
      if (hasStory) _NavTarget('Nuestra Historia', _storyKey),
      if (hasEvents) _NavTarget('Detalles', _detailsKey),
      _NavTarget('Música', _musicKey),
      if (hasGift) _NavTarget('Regalos', _giftKey),
      _NavTarget('Confirmar Asistencia', _rsvpKey),
    ];

    // Todo lo que está dentro usa la paleta vino en vez de la del panel.
    final base = Theme.of(context);
    final themed = base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: InvitationStyle.burgundy,
        secondary: InvitationStyle.wine,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: InvitationStyle.burgundy,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: InvitationStyle.wine),
      ),
    );

    return Theme(
      data: themed,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: InvitationStyle.ivory,
        endDrawer: Drawer(
          backgroundColor: InvitationStyle.burgundyDark,
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  names.monogram,
                  style: InvitationStyle.display(32, color: InvitationStyle.ivory)
                      .copyWith(letterSpacing: 2),
                ),
                const SizedBox(height: 24),
                for (final target in _targets)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      target.label,
                      style: InvitationStyle.body(size: 22, color: InvitationStyle.ivory),
                    ),
                    onTap: () {
                      _scaffoldKey.currentState?.closeEndDrawer();
                      Future.delayed(const Duration(milliseconds: 280), () => _goTo(target));
                    },
                  ),
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: InvitationStyle.navHeight),
                  InvitationHero(
                    names: names,
                    imageUrl: content.heroImageUrl,
                    tagline: content.heroTagline,
                    dateLabel: dateLabel,
                    locationLabel: content.heroLocation,
                    guestFirstName: guest.firstName,
                  ),

                  // Cuenta regresiva
                  Container(
                    color: InvitationStyle.ivory,
                    padding: const EdgeInsets.fromLTRB(0, 28, 0, 8),
                    child: _centered(_reveal(Column(
                      children: [
                        Text('FALTAN', style: InvitationStyle.label()),
                        const SizedBox(height: 16),
                        CountdownTiles(target: wedding.date),
                      ],
                    ))),
                  ),

                  // Historia
                  if (hasStory)
                    Container(
                      key: _storyKey,
                      color: InvitationStyle.ivory,
                      padding: const EdgeInsets.symmetric(vertical: 72),
                      child: _centered(
                        maxWidth: 760,
                        _reveal(Column(
                          children: [
                            const ScriptHeading(title: 'Nuestra Historia'),
                            const SizedBox(height: 28),
                            Text(
                              content.story!.trim(),
                              textAlign: TextAlign.center,
                              style: InvitationStyle.body(size: isWide ? 22 : 19),
                            ),
                          ],
                        )),
                      ),
                    ),

                  // El gran día
                  if (hasEvents)
                    Container(
                      key: _detailsKey,
                      color: InvitationStyle.ivory,
                      padding: const EdgeInsets.symmetric(vertical: 72),
                      child: _centered(_reveal(Column(
                        children: [
                          const ScriptHeading(title: 'El gran día'),
                          const SizedBox(height: 44),
                          _eventsRow(content, width),
                          if (_has(content.dressCode)) ...[
                            const SizedBox(height: 44),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 480),
                              child: InfoCard(
                                icon: Icons.checkroom_outlined,
                                title: 'CÓDIGO DE VESTIMENTA',
                                body: content.dressCode!.trim(),
                              ),
                            ),
                          ],
                        ],
                      ))),
                    ),

                  // Música
                  const SectionWave(from: InvitationStyle.ivory, to: InvitationStyle.blush),
                  MusicSection(
                    key: _musicKey,
                    imageUrl: content.musicImageUrl,
                    playlistUrl: content.spotifyPlaylistUrl,
                    onOpenUrl: _open,
                    panel: _sessionUid != null
                        ? GuestMusicPanel(weddingId: wedding.id, uid: _sessionUid!)
                        : Text(
                            'La música no está disponible en este momento.',
                            textAlign: TextAlign.center,
                            style: InvitationStyle.body(),
                          ),
                  ),
                  const SectionWave(from: InvitationStyle.blush, to: InvitationStyle.ivory),

                  // Regalos
                  if (hasGift)
                    GiftSection(
                      key: _giftKey,
                      message: content.giftMessage,
                      imageUrl: content.giftImageUrl,
                      registryUrl: content.giftRegistryUrl!,
                      onOpenUrl: _open,
                    ),

                  // Confirmación de asistencia
                  Container(
                    key: _rsvpKey,
                    color: InvitationStyle.ivory,
                    padding: const EdgeInsets.symmetric(vertical: 72),
                    child: _centered(
                      maxWidth: 620,
                      _reveal(Column(
                        children: [
                          const ScriptHeading(title: 'Confirma tu asistencia'),
                          const SizedBox(height: 16),
                          Text(
                            _has(content.rsvpDeadline)
                                ? 'Por favor confirma tu asistencia antes del ${content.rsvpDeadline!.trim()}.'
                                : 'Por favor confirma tu asistencia para que podamos prepararlo todo con cariño.',
                            textAlign: TextAlign.center,
                            style: InvitationStyle.body(size: 18),
                          ),
                          const SizedBox(height: 28),
                          RsvpSection(weddingId: wedding.id, guest: guest),
                          const SizedBox(height: 36),
                          Text(
                            'Si no puedes acompañarnos, agradecemos mucho tu mensaje y buenos deseos.',
                            textAlign: TextAlign.center,
                            style: InvitationStyle.body(size: 17),
                          ),
                          const SizedBox(height: 8),
                          Text('¡Te esperamos!', style: InvitationStyle.script(44)),
                        ],
                      )),
                    ),
                  ),

                  _footer(names.monogram, displayName, dateLabel, content),
                ],
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: InvitationNav(
                monogram: names.monogram,
                activeIndex: _activeSection,
                onMenuTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                items: [
                  for (final target in _targets) NavItem(target.label, () => _goTo(target)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
