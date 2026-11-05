class Song {
  final int id;
  final String title;
  final String artist;
  final String album;
  final String coverUrl;
  final String previewUrl;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.coverUrl,
    required this.previewUrl,
  });

  /// Factory method untuk me-parse response JSON dari API ke objek Song
  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['trackId'] ?? 0,
      title: json['trackName'] ?? 'Unknown Title',
      artist: json['artistName'] ?? 'Unknown Artist',
      album: json['collectionName'] ?? 'Unknown Album',
      // Mengambil resolusi gambar yang lebih baik (300x300)
      coverUrl: (json['artworkUrl100'] as String?)?.replaceAll('100x100bb', '300x300bb') ?? '',
      previewUrl: json['previewUrl'] ?? '',
    );
  }
}