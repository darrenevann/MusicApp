import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/song_model.dart';

/// Service khusus untuk menangani komunikasi data dengan API luar
class ApiService {
  static const String baseUrl = 'https://itunes.apple.com/search';

  /// Mengambil daftar lagu berdasarkan kata kunci pencarian
  static Future<List<Song>> fetchSongs(String query) async {
    final Uri url = Uri.parse('$baseUrl?term=${Uri.encodeComponent(query)}&entity=song&limit=25');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        // Filter data agar hanya mengambil yang memiliki preview URL audio
        return results
            .where((item) => item['previewUrl'] != null)
            .map((json) => Song.fromJson(json))
            .toList();
      } else {
        throw Exception('Gagal memuat data lagu. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan jaringan atau server: $e');
    }
  }
}