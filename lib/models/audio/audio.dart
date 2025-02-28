// lib/models/audio/audio.dart
class AudioMetadata {
  final String title;
  final String artist;
  final String album;
  final String year;
  final String genre;
  final String fileFormat;

  AudioMetadata({
    required this.title,
    required this.artist,
    required this.album,
    required this.year,
    required this.genre,
    required this.fileFormat,
  });

  factory AudioMetadata.fromJson(Map<String, dynamic> json) {
    return AudioMetadata(
      title: json['title'] ?? 'Unknown Title',
      artist: json['artist'] ?? 'Unknown Artist',
      album: json['album'] ?? 'Unknown Album',
      year: json['year'] ?? '',
      genre: json['genre'] ?? '',
      fileFormat: json['fileFormat'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'artist': artist,
      'album': album,
      'year': year,
      'genre': genre,
      'fileFormat': fileFormat,
    };
  }

  @override
  String toString() {
    return 'AudioMetadata{title: $title, artist: $artist, album: $album, year: $year, genre: $genre, fileFormat: $fileFormat}';
  }
}