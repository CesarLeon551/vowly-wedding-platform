import 'package:flutter/material.dart';

import 'fade_network_image.dart';
import 'invitation_style.dart';
import 'invitation_widgets.dart';

/// "Nuestra Wishlist": mensaje y botón a la lista de regalos, con foto
/// desvanecida al costado en pantallas anchas.
class GiftSection extends StatelessWidget {
  const GiftSection({
    super.key,
    required this.message,
    required this.imageUrl,
    required this.registryUrl,
    required this.onOpenUrl,
  });

  final String? message;
  final String? imageUrl;
  final String registryUrl;
  final void Function(String url) onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;
    final leftPad = isWide ? ((width - InvitationStyle.maxContentWidth) / 2).clamp(48.0, 400.0) : 24.0;

    final text = (message != null && message!.trim().isNotEmpty)
        ? message!.trim()
        : 'Tu presencia es el mejor regalo, pero si deseas contribuir a nuestra nueva etapa, hemos creado una lista de regalos donde puedes elegir el detalle que más te guste.';

    final content = Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWide ? leftPad + 520 : 600),
        child: Padding(
          padding: EdgeInsets.fromLTRB(leftPad, 72, 24, 72),
          child: Column(
            crossAxisAlignment: isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.card_giftcard_outlined, color: InvitationStyle.wine, size: 30),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text('Nuestra Wishlist', style: InvitationStyle.script(isWide ? 58 : 46)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                text,
                textAlign: isWide ? TextAlign.start : TextAlign.center,
                style: InvitationStyle.body(size: 19),
              ),
              const SizedBox(height: 26),
              PillButton(
                label: 'Ver lista de regalos',
                icon: Icons.card_giftcard_outlined,
                trailingIcon: Icons.open_in_new,
                filled: true,
                onPressed: () => onOpenUrl(registryUrl),
              ),
            ],
          ),
        ),
      ),
    );

    return Container(
      width: double.infinity,
      color: InvitationStyle.ivory,
      child: Stack(
        children: [
          if (hasImage && isWide)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: width * 0.42,
              child: ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [Colors.white, Colors.transparent],
                  stops: [0.55, 1.0],
                ).createShader(rect),
                blendMode: BlendMode.dstIn,
                child: FadeNetworkImage(url: imageUrl!),
              ),
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
