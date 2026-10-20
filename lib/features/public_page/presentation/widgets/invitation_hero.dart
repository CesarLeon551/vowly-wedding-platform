import 'package:flutter/material.dart';

import 'botanical.dart';
import 'couple_names.dart';
import 'fade_network_image.dart';
import 'invitation_style.dart';
import 'script_reveal.dart';

/// Portada: foto a pantalla completa con degradado oscuro para que se
/// lea el texto, nombres en caligrafía y ola de marfil en la base. Sin
/// foto cae a un degradado vino.
class InvitationHero extends StatelessWidget {
  const InvitationHero({
    super.key,
    required this.names,
    required this.imageUrl,
    required this.tagline,
    required this.dateLabel,
    required this.locationLabel,
    required this.guestFirstName,
  });

  final CoupleNames names;
  final String? imageUrl;
  final String? tagline;
  final String dateLabel;
  final String? locationLabel;
  final String guestFirstName;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 900;
    final height = (size.height - InvitationStyle.navHeight).clamp(560.0, 880.0);
    final nameSize = isWide ? 104.0 : 66.0;
    final align = isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center;
    const ivory = InvitationStyle.ivory;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null)
            FadeNetworkImage(url: imageUrl!, fallback: const _HeroFallback())
          else
            const _HeroFallback(),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: isWide ? Alignment.centerLeft : Alignment.bottomCenter,
                end: isWide ? Alignment.centerRight : Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.74), Colors.black.withOpacity(0.2)],
              ),
            ),
          ),
          if (isWide)
            const Positioned(
              left: -12,
              top: 70,
              child: LeafBranch(color: ivory, width: 90, height: 190, opacity: 0.6),
            ),
          Align(
            alignment: isWide ? Alignment.centerLeft : Alignment.center,
            child: Padding(
              padding: EdgeInsets.fromLTRB(isWide ? 110 : 24, 24, 24, 90),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: align,
                  children: [
                    Text(
                      'Hola, $guestFirstName',
                      style: InvitationStyle.body(size: 18, color: ivory.withOpacity(0.9)),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'NUESTRA BODA',
                      style: InvitationStyle.label(color: ivory, spacing: 5),
                    ),
                    const SizedBox(height: 6),
                    _NamesBlock(names: names, size: nameSize, alignStart: isWide),
                    if (tagline != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        tagline!,
                        textAlign: isWide ? TextAlign.start : TextAlign.center,
                        style: InvitationStyle.body(size: 21, color: ivory.withOpacity(0.92)),
                      ),
                    ],
                    const SizedBox(height: 26),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 36, height: 1, color: ivory.withOpacity(0.7)),
                        const SizedBox(width: 14),
                        Text(
                          dateLabel,
                          style: InvitationStyle.display(
                            isWide ? 36 : 30,
                            color: ivory,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Container(width: 36, height: 1, color: ivory.withOpacity(0.7)),
                      ],
                    ),
                    if (locationLabel != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        locationLabel!.toUpperCase(),
                        textAlign: isWide ? TextAlign.start : TextAlign.center,
                        style: InvitationStyle.label(color: ivory, size: 13, spacing: 3.4),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (isWide)
            Positioned(
              right: 36,
              bottom: 100,
              child: Transform.rotate(
                angle: -0.1,
                child: Text(
                  '¡Te esperamos!',
                  style: InvitationStyle.script(40, color: ivory),
                ),
              ),
            ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 52,
            child: Center(child: _ScrollCue()),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: -1,
            child: WaveEdge(color: InvitationStyle.ivory),
          ),
        ],
      ),
    );
  }
}

class _NamesBlock extends StatelessWidget {
  const _NamesBlock({required this.names, required this.size, required this.alignStart});

  final CoupleNames names;
  final double size;
  final bool alignStart;

  @override
  Widget build(BuildContext context) {
    const ivory = InvitationStyle.ivory;
    final style = InvitationStyle.script(size, color: ivory);

    return Column(
      crossAxisAlignment: alignStart ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        ScriptReveal(
          text: names.first,
          style: style,
          delay: const Duration(milliseconds: 300),
        ),
        if (names.second != null) ...[
          Padding(
            padding: EdgeInsets.only(left: alignStart ? size * 0.5 : 0),
            child: ScriptReveal(
              text: 'y',
              style: InvitationStyle.script(size * 0.5, color: ivory.withOpacity(0.9)),
              delay: const Duration(milliseconds: 1100),
              duration: const Duration(milliseconds: 500),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: alignStart ? size * 0.28 : 0),
            child: ScriptReveal(
              text: names.second!,
              style: style,
              delay: const Duration(milliseconds: 1500),
            ),
          ),
        ],
      ],
    );
  }
}

class _HeroFallback extends StatelessWidget {
  const _HeroFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [InvitationStyle.burgundyDark, InvitationStyle.burgundy, Color(0xFF7A2E3E)],
        ),
      ),
    );
  }
}

class _ScrollCue extends StatefulWidget {
  const _ScrollCue();

  @override
  State<_ScrollCue> createState() => _ScrollCueState();
}

class _ScrollCueState extends State<_ScrollCue> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, Curves.easeInOut.transform(_controller.value) * 8),
        child: child,
      ),
      child: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: InvitationStyle.ivory.withOpacity(0.85),
        size: 32,
      ),
    );
  }
}
