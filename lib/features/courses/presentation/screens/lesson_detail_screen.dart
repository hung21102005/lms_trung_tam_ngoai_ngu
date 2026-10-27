import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../data/models/course_model.dart';
import '../widgets/audio_player_widget.dart';
import '../widgets/document_viewer_widget.dart';

class LessonDetailScreen extends StatelessWidget {
  final String moduleTitle;
  final LessonModel lesson;

  const LessonDetailScreen({
    super.key,
    required this.moduleTitle,
    required this.lesson,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    // Separate materials into audio and document/slides
    final audioMaterials = lesson.materials
        .where((m) => m.fileType == 'AUDIO' || m.title.toLowerCase().contains('audio') || m.fileUrl.endsWith('.mp3'))
        .toList();

    final docMaterials = lesson.materials
        .where((m) => m.fileType != 'AUDIO' && !m.title.toLowerCase().contains('audio') && !m.fileUrl.endsWith('.mp3'))
        .toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(lesson.title),
        elevation: 0,
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        foregroundColor: isDark ? Colors.white : AppColors.textPrimaryLight,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'BÀI HỌC #${lesson.order}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 13,
                            color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${lesson.durationMinutes} phút',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  lesson.title,
                  style: AppTextStyles.h4(context).copyWith(fontSize: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  'Thuộc chương: $moduleTitle',
                  style: AppTextStyles.caption(context).copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (lesson.content != null && lesson.content!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Text(
                    'Mục tiêu & Tóm tắt bài học:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lesson.content!,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Audio Materials Section
          Text(
            'Luyện Nghe / Audio Bài Học',
            style: AppTextStyles.h4(context).copyWith(fontSize: 16),
          ),
          const SizedBox(height: 10),
          if (audioMaterials.isEmpty)
            AudioPlayerWidget(
              title: '${lesson.title} - Listening Practice Track 01',
              audioUrl: 'https://example.com/audio/unit-track.mp3',
              totalDuration: Duration(minutes: lesson.durationMinutes > 60 ? 4 : 2, seconds: 45),
            )
          else
            ...audioMaterials.map(
              (mat) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AudioPlayerWidget(
                  title: mat.title,
                  audioUrl: mat.fileUrl,
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Documents / PDF Materials Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tài Liệu Đính Kèm (${docMaterials.isEmpty ? 2 : docMaterials.length})',
                style: AppTextStyles.h4(context).copyWith(fontSize: 16),
              ),
              Text(
                'Tải trọn bộ PDF',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (docMaterials.isEmpty) ...[
            DocumentViewerWidget(
              title: 'Slide bài giảng - ${lesson.title}.pdf',
              fileUrl: 'https://example.com/materials/slide.pdf',
              fileSizeBytes: 2450000,
            ),
            const SizedBox(height: 12),
            const DocumentViewerWidget(
              title: 'Phiếu bài tập tự luyện & Handout.pdf',
              fileUrl: 'https://example.com/materials/handout.pdf',
              fileSizeBytes: 1200000,
            ),
          ] else
            ...docMaterials.map(
              (mat) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DocumentViewerWidget(
                  title: mat.title,
                  fileUrl: mat.fileUrl,
                  fileType: mat.fileType,
                  fileSizeBytes: mat.fileSizeBytes,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
