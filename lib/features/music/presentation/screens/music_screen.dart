import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/back_to_dashboard_button.dart';
import '../../../../core/constants/roles.dart';
import '../../../../domain/entities/spotify_integration.dart';
import '../../../auth/application/auth_providers.dart';
import '../../application/music_providers.dart';
import 'our_story_tab.dart';
import 'playlist_tab.dart';
import 'ranking_tab.dart';
import 'search_spotify_tab.dart';

class MusicScreen extends ConsumerStatefulWidget {
  const MusicScreen({super.key});

  @override
  ConsumerState<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends ConsumerState<MusicScreen> {
  html.EventListener? _messageListener;

  @override
  void dispose() {
    if (_messageListener != null) {
      html.window.removeEventListener('message', _messageListener);
    }
    super.dispose();
  }

  /// Abre Spotify OAuth en una ventana aparte (popup), NO en la misma
  /// pestaña. Así la app Flutter que ya está corriendo nunca se
  /// recarga — solo la ventanita liviana del popup navega hacia
  /// Spotify y de vuelta al Worker, que le manda el resultado por
  /// postMessage y se cierra sola. Evita el problema de que Flutter
  /// tarde mucho (o se quede colgado) reconstruyéndose desde cero tras
  /// una navegación completa de la pestaña principal.
  void _connectSpotify(String weddingId) {
    final url = ref.read(spotifySyncRepositoryProvider).buildAuthorizeUrl(weddingId);
    html.window.open(url, 'spotify_oauth', 'width=500,height=700');

    _messageListener = (event) async {
      final msgEvent = event as html.MessageEvent;
      final raw = msgEvent.data;
      if (raw is! String) return;

      Map<String, dynamic> data;
      try {
        data = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        return; // mensaje de otro origen/no relacionado, se ignora
      }

      if (data['type'] == 'spotify-connected') {
        final uid = ref.read(authStateProvider).valueOrNull?.uid ?? '';
        await ref.read(spotifySyncRepositoryProvider).saveIntegration(
              weddingId,
              SpotifyIntegration(
                refreshToken: data['refreshToken'] as String,
                playlistId: data['playlistId'] as String,
                playlistUrl: data['playlistUrl'] as String? ?? '',
                connectedBy: uid,
              ),
            );
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('¡Spotify conectado!')));
        }
      } else if (data['type'] == 'spotify-error') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo conectar con Spotify: ${data['error']}')),
          );
        }
      }

      if (_messageListener != null) {
        html.window.removeEventListener('message', _messageListener);
        _messageListener = null;
      }
    };

    html.window.addEventListener('message', _messageListener);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final weddingId = user?.weddingId;
    if (weddingId == null || user == null) return const SizedBox.shrink();

    final isAdmin = user.isCouple || user.canAccess(AppModule.music);
    final integrationAsync = ref.watch(spotifyIntegrationStreamProvider(weddingId));

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          leading: BackToDashboardButton(weddingId: weddingId),
          title: const Text('La música de nuestra boda'),
          actions: [
            if (user.isCouple)
              integrationAsync.when(
                data: (integration) => integration == null
                    ? TextButton.icon(
                        icon: const Icon(Icons.link, color: Colors.white),
                        label: const Text('Conectar Spotify', style: TextStyle(color: Colors.white)),
                        onPressed: () => _connectSpotify(weddingId),
                      )
                    : IconButton(
                        icon: const Icon(Icons.check_circle, color: AppColors.sage),
                        tooltip: 'Conectado a Spotify — abrir playlist',
                        onPressed: () => launchUrl(Uri.parse(integration.playlistUrl)),
                      ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Buscar'),
              Tab(text: 'Playlist'),
              Tab(text: 'Ranking'),
              Tab(text: 'Nuestra historia'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SearchSpotifyTab(weddingId: weddingId, uid: user.uid),
            PlaylistTab(weddingId: weddingId, uid: user.uid, isAdmin: isAdmin),
            RankingTab(weddingId: weddingId, uid: user.uid),
            OurStoryTab(weddingId: weddingId, uid: user.uid, isCouple: user.isCouple),
          ],
        ),
      ),
    );
  }
}
