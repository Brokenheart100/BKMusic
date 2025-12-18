import 'package:equatable/equatable.dart';

class Song extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String url; // m3u8 地址
  final String? coverUrl;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.url,
    this.coverUrl,
  });

  @override
  List<Object?> get props => [id, title, url];
}
