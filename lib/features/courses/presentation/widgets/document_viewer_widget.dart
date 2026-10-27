import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class DocumentViewerWidget extends StatelessWidget {
  final String title;
  final String fileUrl;
  final String fileType; // DOCUMENT, PDF, etc.
  final int? fileSizeBytes;
  final VoidCallback? onDownload;

  const DocumentViewerWidget({
    super.key,
    required this.title,
    required this.fileUrl,
    this.fileType = 'DOCUMENT',
    this.fileSizeBytes,
    this.onDownload,
  });

  String _formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return 'Tài liệu PDF / Bản in';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 0 : 6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              color: Color(0xFFEF4444),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.h4(context).copyWith(fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'PDF',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatFileSize(fileSizeBytes),
                      style: AppTextStyles.caption(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đang mở xem tài liệu: $title'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.remove_red_eye_outlined),
            tooltip: 'Xem trước tài liệu',
            color: Theme.of(context).primaryColor,
          ),
          IconButton(
            onPressed: onDownload ??
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đang tải xuống tài liệu: $title'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Tải xuống máy',
            color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
          ),
        ],
      ),
    );
  }
}
