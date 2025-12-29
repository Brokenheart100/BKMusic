import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:music_app/core/utils/duration_formatter.dart';
import 'package:music_app/features/home/domain/entities/song.dart';
import 'package:music_app/features/library/presentation/widgets/add_to_playlist_sheet.dart';

class SongListTile extends StatefulWidget {
  final Song song;
  final int index;
  final VoidCallback onTap;

  const SongListTile({
    super.key,
    required this.song,
    required this.index,
    required this.onTap,
  });

  @override
  State<SongListTile> createState() => _SongListTileState();
}

class _SongListTileState extends State<SongListTile> {
  bool isHover = false;

  void _showContextMenu(BuildContext context, Offset position) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final relativePosition = RelativeRect.fromRect(
      Rect.fromPoints(position, position),
      Offset.zero & overlay.size,
    );

    final result = await showMenu<String>(
      context: context,
      position: relativePosition,
      color: const Color(0xFF252529),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      items: [
        _buildMenuItem('play', Icons.play_arrow_rounded, 'Play'),
        _buildMenuItem(
            'add_to_playlist', Icons.playlist_add, 'Add to Playlist'),
        const PopupMenuDivider(height: 1),
        _buildMenuItem('download', Icons.download_rounded, 'Download'),
      ],
    );

    if (result == 'play') {
      widget.onTap();
    } else if (result == 'add_to_playlist') {
      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => AddToPlaylistSheet(songId: widget.song.id),
        );
      }
    }
  }

  PopupMenuItem<String> _buildMenuItem(
      String value, IconData icon, String text) {
    return PopupMenuItem<String>(
      value: value,
      height: 40,
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white70),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 14, color: Colors.white)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHover = true),
      onExit: (_) => setState(() => isHover = false),
      child: Listener(
        onPointerDown: (event) {
          if (event.kind == PointerDeviceKind.mouse &&
              event.buttons == kSecondaryMouseButton) {
            _showContextMenu(context, event.position);
          }
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isHover
                  ? Colors.white.withValues(alpha: 0.2)
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Text(
                  "#${widget.index}",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: widget.song.coverUrl ?? "",
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.song.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.song.artist,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  DurationFormatter.format(widget.song.duration),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTapDown: (details) =>
                      _showContextMenu(context, details.globalPosition),
                  child: Icon(
                    Icons.more_horiz,
                    color: isHover
                        ? Theme.of(context).primaryColor
                        : Colors.white.withValues(alpha: 0.2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
