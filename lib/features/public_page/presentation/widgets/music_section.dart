import 'package:flutter/material.dart';

import 'botanical.dart';
import 'fade_network_image.dart';
import 'invitation_style.dart';
import 'invitation_widgets.dart';

/// "Nuestra Música": foto con desvanecido (o rama decorativa si no hay
/// foto), tres pasos de cómo participar, el panel interactivo y el
/// botón hacia la playlist de Spotify.
class MusicSection extends StatelessWidget {
  const MusicSection({
    super.key,
    required this.imageUrl,
    required this.playlistUrl,
    required this.panel,
    required this.onOpenUrl,
  });

  final String? imageUrl;
  final String? playlistUrl;
  final Widget panel;
  final void Function(String url) onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    final features = [
      const _Feature(
        icon: Icons.music_note_outlined,
        title: 'Agregar canción',
        text: 'Busca tu canción favorita y agrégala a la playlist.',
      ),
      const _Feature(
        icon: Icons.format_list_bulleted,
        title: 'Votar por una canción',
        text: 'Revisa las canciones ya incluidas y vota por tu favorita.',
      ),
      const _Feature(
        icon: Icons.headphones_outlined,
        title: 'Ver playlist',
        text: 'La playlist se compartirá con el DJ para que suene durante la fiesta.',
      ),
    ];

    final content = Padding(
          padding: EdgeInsets.fromLTRB(isWide ? 48 : 24, isWide ? 72 : 48, isWide ? 48 : 24, 72),
          child: Column(
            crossAxisAlignment: isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  const Icon(Icons.music_note, color: InvitationStyle.wine, size: 30),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text('Nuestra Música', style: InvitationStyle.script(isWide ? 58 : 46)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'La música también es parte de este gran día. Puedes agregar canciones a nuestra playlist o votar por tus favoritas. ¡Será un gusto compartirlas con el DJ!',
                textAlign: TextAlign.center,
                style: InvitationStyle.body(size: 19),
              ),
              const SizedBox(height: 28),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < features.length; i++) ...[
                      if (i > 0) const SizedBox(width: 20),
                      Expanded(child: features[i]),
                    ],
                  ],
                )
              else
                Column(
                  children: [
                    for (var i = 0; i < features.length; i++) ...[
                      if (i > 0) const SizedBox(height: 18),
                      features[i],
                    ],
                  ],
                ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: InvitationStyle.rose.withOpacity(0.6)),
                  boxShadow: InvitationStyle.softShadow,
                ),
                child: panel,
              ),
              if (playlistUrl != null && playlistUrl!.trim().isNotEmpty) ...[
                const SizedBox(height: 26),
                PillButton(
                  label: 'Ir a la playlist',
                  icon: Icons.headphones,
                  trailingIcon: Icons.open_in_new,
                  filled: true,
                  onPressed: () => onOpenUrl(playlistUrl!),
                ),
              ],
            ],
          ),
    );

    return Container(
      width: double.infinity,
      color: InvitationStyle.blush,
      child: Stack(
        children: [
          if (hasImage && isWide)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: width * 0.40,
              child: ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.white, Colors.transparent],
                  stops: [0.55, 1.0],
                ).createShader(rect),
                blendMode: BlendMode.dstIn,
                child: FadeNetworkImage(url: imageUrl!),
              ),
            ),
          if (isWide)
            const Positioned(
              right: 24,
              top: 30,
              child: LeafBranch(color: InvitationStyle.wine, width: 110, height: 200, flipX: true),
            ),
          Column(
            children: [
              if (hasImage && !isWide)
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, Colors.transparent],
                      stops: [0.55, 1.0],
                    ).createShader(rect),
                    blendMode: BlendMode.dstIn,
                    child: FadeNetworkImage(url: imageUrl!),
                  ),
                ),
              content,
            ],
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: InvitationStyle.wine, size: 26),
        const SizedBox(height: 8),
        Text(title, style: InvitationStyle.display(21, fontStyle: FontStyle.italic)),
        const SizedBox(height: 4),
        Text(text, style: InvitationStyle.body(size: 16)),
      ],
    );
  }
}
