import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

enum AudioRecordingState { idle, recording, recorded }

class AudioRecorderWidget extends StatefulWidget {
  final void Function(String fileName, Uint8List bytes, int durationSeconds)
  onAudioRecorded;
  final VoidCallback? onReset;

  const AudioRecorderWidget({
    super.key,
    required this.onAudioRecorded,
    this.onReset,
  });

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget>
    with SingleTickerProviderStateMixin {
  static const _sampleRate = 16000;
  static const _channels = 1;

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final BytesBuilder _pcmBytes = BytesBuilder(copy: false);
  Uint8List? _recordedWav;
  bool _isPlaying = false;
  PlayerState _playbackState = PlayerState.stopped;
  AudioRecordingState _recordingState = AudioRecordingState.idle;
  StreamSubscription<Uint8List>? _audioSubscription;
  StreamSubscription<PlayerState>? _playerSubscription;
  Timer? _timer;
  int _secondsElapsed = 0;
  String? _error;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _playerSubscription = _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _playbackState = state;
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioSubscription?.cancel();
    _playerSubscription?.cancel();
    unawaited(_player.dispose());
    unawaited(_recorder.dispose());
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        if (mounted) {
          setState(
            () => _error = 'Vui lòng cấp quyền sử dụng micro để ghi âm.',
          );
        }
        return;
      }
      _pcmBytes.clear();
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRate,
          numChannels: _channels,
          autoGain: true,
          echoCancel: true,
          noiseSuppress: true,
        ),
      );
      _audioSubscription = stream.listen(
        _pcmBytes.add,
        onError: (Object error) {
          if (mounted) setState(() => _error = 'Lỗi ghi âm: $error');
        },
      );
      if (!mounted) return;
      setState(() {
        _error = null;
        _secondsElapsed = 0;
        _recordingState = AudioRecordingState.recording;
      });
      _pulseController.repeat(reverse: true);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _secondsElapsed++);
        if (_secondsElapsed >= 180) unawaited(_stopRecording());
      });
    } catch (error) {
      if (mounted) setState(() => _error = 'Không bắt đầu được ghi âm: $error');
    }
  }

  Future<void> _stopRecording() async {
    if (_recordingState != AudioRecordingState.recording) return;
    _timer?.cancel();
    _pulseController.stop();
    try {
      await _recorder.stop();
      await _audioSubscription?.cancel();
      _audioSubscription = null;
      final pcm = _pcmBytes.takeBytes();
      if (pcm.isEmpty) throw StateError('Không thu được dữ liệu âm thanh');
      final wav = _wrapPcmAsWav(pcm);
      final fileName = 'speaking_${DateTime.now().millisecondsSinceEpoch}.wav';
      if (!mounted) return;
      setState(() {
        _error = null;
        _recordedWav = wav;
        _recordingState = AudioRecordingState.recorded;
      });
      widget.onAudioRecorded(fileName, wav, _secondsElapsed);
    } catch (error) {
      if (mounted) {
        setState(() {
          _recordingState = AudioRecordingState.idle;
          _error = 'Không lưu được bản ghi: $error';
        });
      }
    }
  }

  Future<void> _resetRecording() async {
    _timer?.cancel();
    _pulseController.stop();
    if (_recordingState == AudioRecordingState.recording) {
      await _recorder.cancel();
    }
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    _pcmBytes.clear();
    await _player.stop();
    if (!mounted) return;
    setState(() {
      _recordedWav = null;
      _isPlaying = false;
      _playbackState = PlayerState.stopped;
      _recordingState = AudioRecordingState.idle;
      _secondsElapsed = 0;
      _error = null;
    });
    widget.onReset?.call();
  }

  Future<void> _togglePlayback() async {
    final wav = _recordedWav;
    if (wav == null) return;
    try {
      if (_isPlaying) {
        await _player.pause();
      } else if (_playbackState == PlayerState.paused) {
        await _player.resume();
      } else {
        await _player.play(BytesSource(wav, mimeType: 'audio/wav'));
      }
      if (mounted) setState(() => _error = null);
    } catch (error) {
      if (mounted) setState(() => _error = 'Không phát được bản ghi: $error');
    }
  }

  Uint8List _wrapPcmAsWav(Uint8List pcm) {
    const bitsPerSample = 16;
    const byteRate = _sampleRate * _channels * bitsPerSample ~/ 8;
    const blockAlign = _channels * bitsPerSample ~/ 8;
    final header = ByteData(44);
    void textAt(int offset, String value) {
      for (var index = 0; index < value.length; index++) {
        header.setUint8(offset + index, value.codeUnitAt(index));
      }
    }

    textAt(0, 'RIFF');
    header.setUint32(4, 36 + pcm.length, Endian.little);
    textAt(8, 'WAVE');
    textAt(12, 'fmt ');
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, _channels, Endian.little);
    header.setUint32(24, _sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    textAt(36, 'data');
    header.setUint32(40, pcm.length, Endian.little);
    return Uint8List.fromList([...header.buffer.asUint8List(), ...pcm]);
  }

  String _formatTimer(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remaining.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _recordingState == AudioRecordingState.recording
              ? AppColors.error.withAlpha(120)
              : AppColors.neutral300,
        ),
      ),
      child: Column(
        children: [
          if (_recordingState == AudioRecordingState.idle) _buildIdleView(),
          if (_recordingState == AudioRecordingState.recording)
            _buildRecordingView(),
          if (_recordingState == AudioRecordingState.recorded)
            _buildRecordedView(),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIdleView() {
    return Column(
      children: [
        IconButton.filled(
          onPressed: _startRecording,
          iconSize: 38,
          padding: const EdgeInsets.all(18),
          icon: const Icon(Icons.mic),
        ),
        const SizedBox(height: 12),
        Text(
          'Nhấn micro để bắt đầu ghi âm bài nói',
          style: AppTextStyles.bodyMedium(context)
              .copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Thời lượng tối đa 3 phút. Trình duyệt hoặc Android sẽ yêu cầu quyền micro.',
          style: AppTextStyles.caption(context)
              .copyWith(color: AppColors.neutral500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecordingView() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) => Transform.scale(
            scale: 1 + (_pulseController.value * 0.12),
            child: IconButton.filled(
              onPressed: _stopRecording,
              style: IconButton.styleFrom(backgroundColor: AppColors.error),
              iconSize: 40,
              padding: const EdgeInsets.all(18),
              icon: const Icon(Icons.stop_rounded),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _formatTimer(_secondsElapsed),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.error,
          ),
        ),
        const SizedBox(height: 8),
        const Text('Đang thu âm từ micro thật...'),
      ],
    );
  }

  Widget _buildRecordedView() {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: AppColors.success, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Đã lưu bản ghi âm',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Thời lượng ${_formatTimer(_secondsElapsed)} · WAV',
                style: AppTextStyles.caption(context),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _togglePlayback,
          tooltip: _isPlaying ? 'Tạm dừng nghe' : 'Nghe lại bản ghi',
          icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle),
        ),
        IconButton(
          onPressed: _resetRecording,
          tooltip: 'Ghi âm lại',
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}
