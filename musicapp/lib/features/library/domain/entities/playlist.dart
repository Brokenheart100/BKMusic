class Playlist {
  final String id;
  final String name;
  final String? coverUrl;
  final int songCount;

  const Playlist(
      {required this.id,
      required this.name,
      this.coverUrl,
      required this.songCount});
}
