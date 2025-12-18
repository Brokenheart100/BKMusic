import 'package:json_annotation/json_annotation.dart';

part 'create_playlist_request.g.dart';

@JsonSerializable()
class CreatePlaylistRequest {
  final String name;
  final String? description;

  CreatePlaylistRequest({required this.name, this.description});

  Map<String, dynamic> toJson() => _$CreatePlaylistRequestToJson(this);
}
