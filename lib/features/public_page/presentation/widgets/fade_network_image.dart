import 'package:flutter/material.dart';

/// Image.network con fade-in y respaldo si la imagen falla. Si una foto
/// de R2 no carga, casi siempre es porque el bucket no tiene CORS para
/// GET (ver README) — por eso el respaldo es silencioso y la página
/// sigue viéndose bien sin foto.
class FadeNetworkImage extends StatelessWidget {
  const FadeNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  final String url;
  final BoxFit fit;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
          child: child,
        );
      },
      errorBuilder: (context, error, stack) => fallback ?? const SizedBox.shrink(),
    );
  }
}
