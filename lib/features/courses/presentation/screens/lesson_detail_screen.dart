import 'package:flutter/material.dart';

import '../../../../core/adaptive/adaptive_layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/mobile/mobile_ui.dart';
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
        .where(
          (m) =>
              m.fileType == 'AUDIO' ||
              m.title.toLowerCase().contains('audio') ||
              m.fileUrl.endsWith('.mp3'),
        )
        .toList();

    final docMaterials = lesson.materials
        .where(
          (m) =>
              m.fileType != 'AUDIO' &&
              !m.title.toLowerCase().contains('audio') &&
              !m.fileUrl.endsWith('.mp3'),
        )
        .toList();

    if (AdaptiveBreakpoints.fromWidth(MediaQuery.sizeOf(context).width) ==
        AdaptiveSize.mobile) {
      return _buildMobile(context, audioMaterials, docMaterials);
    }

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 13,
                            color: isDark
                                ? Colors.white70
                                : AppColors.textSecondaryLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${lesson.durationMinutes} phút',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textSecondaryLight,
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
                      color: isDark
                          ? Colors.white70
                          : AppColors.textSecondaryLight,
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
            const Text('Chưa có tệp âm thanh cho bài học này.')
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
                'Tài Liệu Đính Kèm (${docMaterials.length})',
                style: AppTextStyles.h4(context).copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (docMaterials.isEmpty)
            const Text('Chưa có tài liệu đính kèm.')
          else
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

  Widget _buildMobile(
    BuildContext context,
    List<LessonMaterialModel> audioMaterials,
    List<LessonMaterialModel> docMaterials,
  ) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bài học')),
      body: SafeArea(
        child: ListView(
          key: const ValueKey('student-lesson-mobile'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(
              'Bài ${lesson.order} · ${lesson.durationMinutes} phút',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              lesson.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              moduleTitle,
              style: const TextStyle(color: AppColors.neutral600),
            ),
            const SizedBox(height: MobileTokens.sectionGap),
            MobileSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nội dung bài học',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    lesson.content?.trim().isNotEmpty == true
                        ? lesson.content!
                        : 'Chưa có nội dung bài học.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Âm thanh (${audioMaterials.length})',
              style: AppTextStyles.h4(context),
            ),
            const SizedBox(height: 10),
            if (audioMaterials.isEmpty)
              const MobileSectionCard(
                child: Text('Chưa có tệp âm thanh cho bài học này.'),
              ),
            for (final material in audioMaterials)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AudioPlayerWidget(
                  title: material.title,
                  audioUrl: material.fileUrl,
                ),
              ),
            const SizedBox(height: 20),
            Text(
              'Tài liệu (${docMaterials.length})',
              style: AppTextStyles.h4(context),
            ),
            const SizedBox(height: 10),
            if (docMaterials.isEmpty)
              const MobileSectionCard(
                child: Text('Chưa có tài liệu đính kèm.'),
              ),
            for (final material in docMaterials)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DocumentViewerWidget(
                  title: material.title,
                  fileUrl: material.fileUrl,
                  fileType: material.fileType,
                  fileSizeBytes: material.fileSizeBytes,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
