class Song {
  final String trackName;
  final String artistName;
  final String artworkUrl;
  final String previewUrl;

  Song({
    required this.trackName,
    required this.artistName,
    required this.artworkUrl,
    required this.previewUrl,
  });

  // Parsing data JSON ke objek Song
  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      trackName: json['trackName'] ?? 'Unknown Track',
      artistName: json['artistName'] ?? 'Unknown Artist',
      artworkUrl: json['artworkUrl100'] ?? 'https://via.placeholder.com/100',
      previewUrl: json['previewUrl'] ?? '', 
    );
  }
}