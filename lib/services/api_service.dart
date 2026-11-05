import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song_model.dart';

class ApiService {
  static const String baseUrl = 'https://itunes.apple.com/search';
  static const String lyricsUrl = 'https://api.lyrics.ovh/v1';

  // Mengambil daftar lagu dari iTunes API
  Future<List<Song>> fetchSongs(String query) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?term=$query&entity=song&limit=15'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'];
        return results.map((json) => Song.fromJson(json)).toList();
      } else {
        throw Exception('Gagal memuat data lagu.');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan jaringan: $e');
    }
  }

  // Mengambil lirik lagu dari Lyrics.ovh API
  Future<String> fetchLyrics(String artist, String title) async {
    try {
      final response = await http.get(Uri.parse('$lyricsUrl/$artist/$title'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['lyrics'] ?? 'Lirik tidak ditemukan.';
      } else {
        return 'Lirik belum tersedia untuk lagu ini.';
      }
    } catch (e) {
      return 'Gagal memuat lirik. Periksa koneksi internet.';
    }
  }
}