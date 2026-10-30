import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String title;
  final String audioUrl;
  final Duration totalDuration;

  const AudioPlayerWidget({
    super.key,
    required this.title,
    required this.audioUrl,
    this.totalDuration = const Duration(minutes: 3, seconds: 45),
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  double _playbackSpeed = 1.0;

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _cycleSpeed() {
    setState(() {
      if (_playbackSpeed == 1.0) {
        _playbackSpeed = 1.25;
      } else if (_playbackSpeed == 1.25) {
        _playbackSpeed = 1.5;
      } else if (_playbackSpeed == 1.5) {
        _playbackSpeed = 2.0;
      } else {
        _playbackSpeed = 1.0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.headphones,
                  color: primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: AppTextStyles.h4(context).copyWith(fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tập tin nghe âm thanh định dạng MP3',
                      style: AppTextStyles.caption(context),
                    ),
                  ],
                ),
              ),
              // Speed control button
              InkWell(
                onTap: _cycleSpeed,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.transparent : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    '${_playbackSpeed}x',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: primaryColor,
              inactiveTrackColor: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
              thumbColor: primaryColor,
            ),
            child: Slider(
              min: 0,
              max: widget.totalDuration.inSeconds.toDouble(),
              value: _currentPosition.inSeconds.toDouble().clamp(0, widget.totalDuration.inSeconds.toDouble()),
              onChanged: (value) {
                setState(() {
                  _currentPosition = Duration(seconds: value.toInt());
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_currentPosition),
                  style: AppTextStyles.caption(context).copyWith(fontSize: 12),
                ),
                Text(
                  _formatDuration(widget.totalDuration),
                  style: AppTextStyles.caption(context).copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Playback Controls Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    final newSec = (_currentPosition.inSeconds - 10).clamp(0, widget.totalDuration.inSeconds);
                    _currentPosition = Duration(seconds: newSec);
                  });
                },
                icon: const Icon(Icons.replay_10_rounded),
                iconSize: 28,
                color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withAlpha(80),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  setState(() {
                    final newSec = (_currentPosition.inSeconds + 10).clamp(0, widget.totalDuration.inSeconds);
                    _currentPosition = Duration(seconds: newSec);
                  });
                },
                icon: const Icon(Icons.forward_10_rounded),
                iconSize: 28,
                color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
