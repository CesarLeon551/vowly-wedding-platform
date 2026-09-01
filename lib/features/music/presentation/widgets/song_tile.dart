import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../domain/entities/song.dart';
import '../../application/music_providers.dart';

class SongTile extends ConsumerWidget {
  const SongTile({
    super.key,
    required this.weddingId,
    required this.song,
    required this.uid,
    this.trailingAdmin,
  });

  final String weddingId;
  final Song song;
  final String uid;

  /// Controles extra (aprobar/rechazar/favorita/etc.) — solo se pasan
  /// desde la pestaña de administración, null para invitados.
  final Widget? trailingAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: song.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(song.imageUrl!, width: 48, height: 48, fit: BoxFit.cover),
              )
            : const Icon(Icons.music_note, size: 40),
        title: Text(song.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${song.artist}${song.category != null ? " · ${song.category}" : ""}',
            maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: trailingAdmin ??
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite_border, color: AppColors.terracotta),
                  onPressed: () => ref.read(musicRepositoryProvider).toggleVote(weddingId, song.id, uid),
                ),
                Text('${song.votes}'),
              ],
            ),
      ),
    );
  }
}
