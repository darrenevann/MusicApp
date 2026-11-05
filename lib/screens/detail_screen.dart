import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import '../models/song_model.dart';

// Model untuk menampung waktu dan teks lirik
class LyricLine {
  final Duration time;
  final String text;
  LyricLine({required this.time, required this.text});
}

class DetailScreen extends StatefulWidget {
  final Song song;

  const DetailScreen({super.key, required this.song});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  late final AnimationController _animController = AnimationController(
    vsync: this, 
    duration: const Duration(seconds: 6),
  );
  
  bool isPlaying = false;

  List<LyricLine> parsedLyrics = [];
  int currentLyricIndex = -1;
  bool isLoadingLyrics = true;
  String lyricStatusMessage = 'Memuat lirik...';

  Duration _position = Duration.zero;
  Duration _duration = const Duration(seconds: 30);
  
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchSyncedLyrics();

    _durSub = _audioPlayer.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });

    _posSub = _audioPlayer.onPositionChanged.listen((pos) {
      if (!mounted) return;
      setState(() => _position = pos);

      if (parsedLyrics.isEmpty) return;
      
      int idx = -1;
      for (int i = 0; i < parsedLyrics.length; i++) {
        if (pos >= parsedLyrics[i].time) {
          idx = i;
        } else {
          break;
        }
      }
      
      if (idx != currentLyricIndex && idx != -1) {
        setState(() => currentLyricIndex = idx);
        // Otomatis scroll agar baris lirik yang aktif berada di tengah layar ala Spotify
        if (_scrollController.hasClients) {
          double offset = (idx * 50.0) - 100.0;
          if (offset < 0) offset = 0;
          _scrollController.animateTo(
            offset, 
            duration: const Duration(milliseconds: 300), 
            curve: Curves.easeInOut,
          );
        }
      }
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        isPlaying = false;
        _position = Duration.zero;
      });
      _animController.stop();
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _scrollController.dispose();
    _animController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _fetchSyncedLyrics() async {
    final cleanTrackName = widget.song.trackName.replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), '').trim();
    final cleanArtistName = widget.song.artistName.replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), '').trim();

    final url = Uri.https('lrclib.net', '/api/get', {
      'track_name': cleanTrackName,
      'artist_name': cleanArtistName,
    });

    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final String? syncedStr = data['syncedLyrics'];
        final String? plainStr = data['plainLyrics'];

        if (syncedStr != null && syncedStr.trim().isNotEmpty) {
          setState(() {
            parsedLyrics = _parseLyrics(syncedStr);
            isLoadingLyrics = false;
          });
        } else if (plainStr != null && plainStr.trim().isNotEmpty) {
          setState(() {
            parsedLyrics = plainStr.split('\n').map((l) => LyricLine(time: Duration.zero, text: l.trim())).toList();
            isLoadingLyrics = false;
          });
        } else {
          setState(() { 
            parsedLyrics = [LyricLine(time: Duration.zero, text: "Lirik tidak tersedia untuk lagu ini.")];
            isLoadingLyrics = false; 
          });
        }
      } else {
        setState(() { 
          parsedLyrics = [LyricLine(time: Duration.zero, text: "Lirik tidak ditemukan di server.")];
          isLoadingLyrics = false; 
        });
      }
    } catch (_) {
      setState(() { 
        parsedLyrics = [LyricLine(time: Duration.zero, text: "Gagal memuat lirik (Periksa koneksi).")];
        isLoadingLyrics = false; 
      });
    }
  }

  List<LyricLine> _parseLyrics(String lrc) {
    final regExp = RegExp(r'\[(\d+):(\d+\.\d+)\](.*)');
    return lrc.split('\n').map((line) {
      final match = regExp.firstMatch(line.trim());
      if (match == null) return null;
      final m = int.tryParse(match.group(1) ?? '0') ?? 0;
      final s = double.tryParse(match.group(2) ?? '0.0') ?? 0.0;
      final txt = (match.group(3) ?? '').trim();
      return LyricLine(time: Duration(milliseconds: (m * 60 * 1000) + (s * 1000).toInt()), text: txt.isEmpty ? '♪' : txt);
    }).whereType<LyricLine>().toList();
  }

  void _togglePlayPause() async {
    if (widget.song.previewUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio preview tidak tersedia.'), backgroundColor: Colors.black),
      );
      return;
    }

    if (isPlaying) {
      await _audioPlayer.pause();
      _animController.stop();
    } else {
      await _audioPlayer.play(UrlSource(widget.song.previewUrl));
      _animController.repeat();
    }
    setState(() => isPlaying = !isPlaying);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeBorder = isDark ? Colors.white : Colors.black;
    final themeShadow = isDark ? Colors.white : Colors.black;
    final textColor = isDark ? Colors.white : Colors.black;
    
    final artworkUrl = widget.song.artworkUrl.replaceAll('100x100', '400x400');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'NOW PLAYING',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 2),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            children: [
              // Cover Piringan Hitam Berputar
              RotationTransition(
                turns: _animController,
                child: Container(
                  width: 150, 
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, 
                    border: Border.all(color: themeBorder, width: 4),
                    boxShadow: [BoxShadow(color: themeShadow, offset: const Offset(6, 6))],
                    color: Colors.black,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(75),
                        child: Image.network(artworkUrl, width: 150, height: 150, fit: BoxFit.cover),
                      ),
                      Container(
                        width: 25, height: 25, 
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, 
                          color: Theme.of(context).scaffoldBackgroundColor,
                          border: Border.all(color: Colors.black, width: 3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Informasi Lagu
              Text(
                widget.song.trackName, 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor), 
                textAlign: TextAlign.center, 
                maxLines: 1, 
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                widget.song.artistName, 
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.grey[400] : Colors.grey[700]),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // Slider Audio
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 6,
                  activeTrackColor: const Color(0xFFFF66A1),
                  inactiveTrackColor: isDark ? Colors.grey[800] : Colors.grey[300],
                  thumbColor: const Color(0xFFFFDE59),
                  overlayColor: const Color(0xFFFFDE59).withValues(alpha: 0.3),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6, pressedElevation: 0),
                  trackShape: const RectangularSliderTrackShape(),
                ),
                child: Slider(
                  min: 0.0,
                  max: _duration.inSeconds > 0 ? _duration.inSeconds.toDouble() : 30.0,
                  value: _position.inSeconds.toDouble().clamp(0.0, _duration.inSeconds > 0 ? _duration.inSeconds.toDouble() : 30.0),
                  onChanged: (val) async {
                    await _audioPlayer.seek(Duration(seconds: val.toInt()));
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(_position), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor)),
                    Text(_formatDuration(_duration), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor)),
                  ],
                ),
              ),
              
              const SizedBox(height: 6),
              
              // Tombol Play/Pause Neo-Brutalis
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  width: 45, height: 45,
                  decoration: BoxDecoration(
                    color: isPlaying ? const Color(0xFFFF66A1) : const Color(0xFFFFDE59),
                    shape: BoxShape.circle,
                    border: Border.all(color: themeBorder, width: 3),
                    boxShadow: [BoxShadow(color: themeShadow, offset: const Offset(3, 3))],
                  ),
                  child: Icon(isPlaying ? Icons.pause : Icons.play_arrow, size: 24, color: Colors.black),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Tampilan Lirik ala Spotify (Full layar ke bawah, tersinkronisasi, tanpa kotak kaku)
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF), // Latar cyan mencolok ala Neo-Brutalism
                    border: Border.all(color: themeBorder, width: 3),
                    boxShadow: [BoxShadow(color: themeShadow, offset: const Offset(6, 6))],
                  ),
                  child: isLoadingLyrics
                    ? const Center(child: CircularProgressIndicator(color: Colors.black))
                    : parsedLyrics.isEmpty
                    ? Center(child: Text(lyricStatusMessage, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)))
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 100), // Padding atas-bawah agar lirik bisa naik ke tengah
                        itemCount: parsedLyrics.length,
                        itemBuilder: (context, i) {
                          final isHigh = i == currentLyricIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            child: Text(
                              parsedLyrics[i].text,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isHigh ? 22 : 16,
                                fontWeight: isHigh ? FontWeight.w900 : FontWeight.w600,
                                color: isHigh ? Colors.black : Colors.black54,
                                height: 1.4,
                              ),
                            ),
                          );
                        },
                      ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}