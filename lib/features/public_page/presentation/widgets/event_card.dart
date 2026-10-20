import 'package:flutter/material.dart';

import 'fade_network_image.dart';
import 'invitation_style.dart';
import 'invitation_widgets.dart';

/// Un evento del "gran día" (ceremonia o recepción): foto, icono, título
/// en caligrafía, lugar, dirección, botón de mapa y horario.
class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.icon,
    required this.title,
    required this.photoBeside,
    required this.onOpenUrl,
    this.venue,
    this.address,
    this.mapUrl,
    this.time,
    this.note,
    this.imageUrl,
  });

  final IconData icon;
  final String title;

  /// true: la foto va al lado del texto; false: arriba.
  final bool photoBeside;
  final void Function(String url) onOpenUrl;
  final String? venue;
  final String? address;
  final String? mapUrl;
  final String? time;
  final String? note;
  final String? imageUrl;

  bool _has(String? s) => s != null && s.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final centered = !photoBeside;

    final photo = _has(imageUrl)
        ? ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: photoBeside ? 190 : double.infinity,
              height: photoBeside ? 230 : 220,
              child: FadeNetworkImage(
                url: imageUrl!,
                fallback: Container(color: InvitationStyle.blush),
              ),
            ),
          )
        : null;

    final info = Column(
      crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: InvitationStyle.wine, size: 28),
            const SizedBox(width: 12),
            Flexible(child: Text(title, style: InvitationStyle.script(44))),
          ],
        ),
        if (_has(venue)) ...[
          const SizedBox(height: 6),
          Text(
            venue!.trim(),
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: InvitationStyle.display(24, fontStyle: FontStyle.italic),
          ),
        ],
        if (_has(address)) ...[
          const SizedBox(height: 4),
          Text(
            address!.trim(),
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: InvitationStyle.body(size: 16),
          ),
        ],
        if (_has(mapUrl)) ...[
          const SizedBox(height: 16),
          PillButton(
            label: 'Ver en Google Maps',
            icon: Icons.location_on_outlined,
            trailingIcon: Icons.open_in_new,
            small: true,
            onPressed: () => onOpenUrl(mapUrl!),
          ),
        ],
        if (_has(time) || _has(note)) ...[
          const SizedBox(height: 18),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.schedule, color: InvitationStyle.wine, size: 22),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_has(time))
                      Text(
                        time!.trim(),
                        style: InvitationStyle.display(22, fontStyle: FontStyle.italic),
                      ),
                    if (_has(note))
                      Text(note!.trim(), style: InvitationStyle.body(size: 16)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );

    if (photoBeside) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (photo != null) ...[photo, const SizedBox(width: 24)],
          Expanded(child: info),
        ],
      );
    }

    return Column(
      children: [
        if (photo != null) ...[photo, const SizedBox(height: 20)],
        info,
      ],
    );
  }
}
