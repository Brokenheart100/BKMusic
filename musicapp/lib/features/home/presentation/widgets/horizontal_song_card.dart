import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:music_app/features/home/domain/entities/song.dart';

class HorizontalSongCard extends StatefulWidget {
  final Song song;
  final VoidCallback onTap;

  const HorizontalSongCard({
    super.key,
    required this.song,
    required this.onTap,
  });

  @override
  State<HorizontalSongCard> createState() => _HorizontalSongCardState();
}

class _HorizontalSongCardState extends State<HorizontalSongCard> {
  bool isHover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHover = true),
      onExit: (_) => setState(() => isHover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 160,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          transform: isHover
              ? Matrix4.translationValues(0, -5, 0)
              : Matrix4.identity(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(
                          widget.song.coverUrl ?? ""),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: isHover
                      ? Center(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white24,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow,
                                color: Colors.white),
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                widget.song.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
