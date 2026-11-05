import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;

class LyricLine {
  final Duration time;
  final String text;
  LyricLine({required this.time, required this.text});
}

class DetailPage extends StatefulWidget {
  final Map<String, dynamic> song;
  final AudioPlayer audioPlayer;
  final bool isPlaying;
  final VoidCallback onPlayToggle;
  final VoidCallback onStopAudio;

  const DetailPage({
    super.key,
    required this.song,
    required this.audioPlayer,
    required this.isPlaying,
    required this.onPlayToggle,
    required this.onStopAudio,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late bool _localIsPlaying;

  List<LyricLine> parsedLyrics = [];
  int currentLyricIndex = -1;
  bool isLoadingLyrics = true;
  String lyricStatusMessage = 'Memuat lirik...';

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _localIsPlaying = widget.isPlaying;
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 6));
    if (_localIsPlaying) {
      _animController.repeat();
    }

    fetchLyrics();

    widget.audioPlayer.getDuration().then((d) {
      if (d != null && mounted) setState(() => _duration = d);
    });
    widget.audioPlayer.getCurrentPosition().then((p) {
      if (p != null && mounted) setState(() => _position = p);
    });

    _posSub = widget.audioPlayer.onPositionChanged.listen((pos) {
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
        if (_scrollController.hasClients) {
          _scrollController.animateTo(idx * 45.0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        }
      }
    });

    _durSub = widget.audioPlayer.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> fetchLyrics() async {
    final url = Uri.https('lrclib.net', '/api/get', {
      'track_name': widget.song['trackName'] ?? '',
      'artist_name': widget.song['artistName'] ?? '',
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
          setState(() { lyricStatusMessage = 'Lirik tidak tersedia.'; isLoadingLyrics = false; });
        }
      } else {
        setState(() { lyricStatusMessage = 'Lirik tidak ditemukan.'; isLoadingLyrics = false; });
      }
    } catch (_) {
      setState(() { lyricStatusMessage = 'Gagal memuat lirik.'; isLoadingLyrics = false; });
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

  Future<bool> _showBackDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keluar dari Halaman Musik'),
        content: const Text('Apakah kamu ingin menghentikan lagu atau tetap memutarnya di latar belakang?'),
        actions: [
          TextButton(
            onPressed: () { widget.onStopAudio(); Navigator.pop(context, true); },
            child: const Text('Stop Song', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue Song', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _scrollController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _togglePlay() {
    widget.onPlayToggle();
    setState(() {
      _localIsPlaying = !_localIsPlaying;
      if (_localIsPlaying) {
        _animController.repeat();
      } else {
        _animController.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final artworkUrl = widget.song['artworkUrl100'] ?? '';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _showBackDialog(context) && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () async {
                      if (await _showBackDialog(context) && context.mounted) Navigator.pop(context);
                    },
                  ),
                  const Text('NOW PLAYING', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 2)),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 6),
              RotationTransition(
                turns: _animController,
                child: Container(
                  width: 160, height: 160,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black, boxShadow: [BoxShadow(color: _localIsPlaying ? primary.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.4), blurRadius: _localIsPlaying ? 25 : 12)]),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(80),
                        child: Image.network(artworkUrl, width: 135, height: 135, fit: BoxFit.cover, errorBuilder: (ctx, err, stack) => const Icon(Icons.music_note, size: 40)),
                      ),
                      Container(width: 14, height: 14, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(widget.song['trackName'] ?? '-', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1),
              Text(widget.song['artistName'] ?? '-', style: TextStyle(fontSize: 14, color: Colors.grey.shade400), textAlign: TextAlign.center, maxLines: 1),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Slider(
                      min: 0.0,
                      max: _duration.inSeconds > 0 ? _duration.inSeconds.toDouble() : 30.0,
                      value: _position.inSeconds.toDouble().clamp(
                        0.0,
                        _duration.inSeconds > 0 ? _duration.inSeconds.toDouble() : 30.0,
                      ),
                      onChanged: (val) async {
                        final newPosition = Duration(seconds: val.toInt());
                        await widget.audioPlayer.seek(newPosition);
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(_position), style: const TextStyle(fontSize: 12)),
                          Text(_formatDuration(_duration), style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: primary),
                  child: Icon(_localIsPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 30, color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(24)),
                  child: isLoadingLyrics
                      ? Center(child: CircularProgressIndicator(color: primary))
                      : parsedLyrics.isEmpty
                      ? Center(child: Text(lyricStatusMessage))
                      : ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: parsedLyrics.length,
                    itemBuilder: (context, i) {
                      final isHigh = i == currentLyricIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          parsedLyrics[i].text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isHigh ? 18 : 14,
                            fontWeight: isHigh ? FontWeight.bold : FontWeight.normal,
                            color: isHigh ? primary : Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}