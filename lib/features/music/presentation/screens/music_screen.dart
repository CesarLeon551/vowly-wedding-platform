import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/roles.dart';
import '../../../auth/application/auth_providers.dart';
import 'our_story_tab.dart';
import 'playlist_tab.dart';
import 'ranking_tab.dart';
import 'search_spotify_tab.dart';

class MusicScreen extends ConsumerWidget {
  const MusicScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final weddingId = user?.weddingId;
    if (weddingId == null || user == null) return const SizedBox.shrink();

    final isAdmin = user.isCouple || user.canAccess(AppModule.music);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('La música de nuestra boda'),
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
