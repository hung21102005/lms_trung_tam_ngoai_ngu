import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../bloc/courses_bloc.dart';
import '../bloc/courses_event.dart';
import '../bloc/courses_state.dart';
import '../../data/models/course_model.dart';
import 'lesson_detail_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    context.read<CoursesBloc>().add(FetchCourseDetail(widget.courseId));
  }

  void _showAddLevelDialog() {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final sessionsCtrl = TextEditingController(text: '24');
    final feeCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Thêm Cấp Độ Đào Tạo Mới', style: AppTextStyles.h4(context)),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  label: 'Mã cấp độ *',
                  hintText: 'VD: BAND-5.5, FOUNDATION...',
                  controller: codeCtrl,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Tên cấp độ *',
                  hintText: 'VD: IELTS Target 5.5 - 6.5',
                  controller: nameCtrl,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Số buổi học',
                        hintText: '24',
                        keyboardType: TextInputType.number,
                        controller: sessionsCtrl,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'Học phí chuẩn (VNĐ)',
                        hintText: 'VD: 4500000',
                        keyboardType: TextInputType.number,
                        controller: feeCtrl,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Mục tiêu chuẩn đầu ra',
                  hintText: 'Chuẩn đầu ra của học viên sau khi hoàn thành level...',
                  controller: descCtrl,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Hủy bỏ'),
          ),
          ElevatedButton(
            onPressed: () {
              if (codeCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập đầy đủ mã và tên cấp độ')),
                );
                return;
              }
              Navigator.of(dialogCtx).pop();
              final sessions = int.tryParse(sessionsCtrl.text.trim()) ?? 24;
              final fee = double.tryParse(feeCtrl.text.trim()) ?? 0;

              context.read<CoursesBloc>().add(CreateCourseLevelEvent(
                courseId: widget.courseId,
                code: codeCtrl.text.trim().toUpperCase(),
                name: nameCtrl.text.trim(),
                description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                estimatedSessions: sessions,
                tuitionFee: fee,
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Thêm cấp độ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Chi tiết Khóa học'),
        elevation: 0,
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        foregroundColor: isDark ? Colors.white : AppColors.textPrimaryLight,
        actions: [
          IconButton(
            onPressed: () {
              context.read<CoursesBloc>().add(FetchCourseDetail(widget.courseId));
            },
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<CoursesBloc, CoursesState>(
        listener: (context, state) {
          if (state is CourseOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is CoursesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CourseDetailLoading) {
            return const LoadingWidget(message: 'Đang tải thông tin chi tiết khóa học...');
          } else if (state is CoursesError) {
            return AppErrorWidget(
              message: state.message,
              onRetry: () {
                context.read<CoursesBloc>().add(FetchCourseDetail(widget.courseId));
              },
            );
          } else if (state is CourseDetailLoaded) {
            final course = state.course;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header Info Card
                _buildCourseHeader(context, course),
                const SizedBox(height: 20),

                // Levels Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Khung Cấp Độ & Giáo Trình (${course.levels.length})',
                      style: AppTextStyles.h4(context).copyWith(fontSize: 18),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddLevelDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Thêm Level'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Levels List
                if (course.levels.isEmpty)
                  const EmptyStateWidget(
                    title: 'Chưa có cấp độ đào tạo nào',
                    description: 'Hãy nhấn nút "Thêm Level" để bắt đầu thiết lập lộ trình học tập.',
                    icon: Icons.layers_clear_outlined,
                  )
                else
                  ...course.levels.map((level) => _buildLevelCard(context, level)),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildCourseHeader(BuildContext context, CourseModel course) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primaryColor.withAlpha(60)),
                ),
                child: Text(
                  course.code,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.language, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      course.language,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: course.isActive
                      ? AppColors.success.withAlpha(25)
                      : AppColors.error.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  course.isActive ? 'ĐANG MỞ ĐÀO TẠO' : 'TẠM DỪNG',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: course.isActive ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            course.title,
            style: AppTextStyles.h4(context).copyWith(fontSize: 20),
          ),
          if (course.targetAudience != null && course.targetAudience!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.people_outline, size: 16, color: AppColors.secondary),
                const SizedBox(width: 6),
                Text(
                  'Đối tượng: ${course.targetAudience}',
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ],
          if (course.description != null && course.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              course.description!,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLevelCard(BuildContext context, CourseLevelModel level) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: true,
            tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    level.code,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    level.name,
                    style: AppTextStyles.h4(context).copyWith(fontSize: 16),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: isDark ? Colors.white60 : AppColors.textSecondaryLight),
                  const SizedBox(width: 4),
                  Text(
                    '${level.estimatedSessions} buổi',
                    style: AppTextStyles.caption(context),
                  ),
                  const SizedBox(width: 14),
                  Icon(Icons.payments_outlined, size: 14, color: isDark ? Colors.white60 : AppColors.textSecondaryLight),
                  const SizedBox(width: 4),
                  Text(
                    _currencyFormat.format(level.tuitionFee),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Icon(Icons.library_books_outlined, size: 14, color: isDark ? Colors.white60 : AppColors.textSecondaryLight),
                  const SizedBox(width: 4),
                  Text(
                    '${level.modules.length} modules',
                    style: AppTextStyles.caption(context),
                  ),
                ],
              ),
            ),
            children: [
              const Divider(height: 1),
              if (level.modules.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text('Chưa có chương trình/bài học chi tiết cho level này.'),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: level.modules.length,
                  itemBuilder: (context, mIdx) {
                    final module = level.modules[mIdx];
                    return _buildModuleItem(context, module);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleItem(BuildContext context, ModuleModel module) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withAlpha(120) : const Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.folder_open_rounded, size: 18, color: AppColors.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    module.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Text(
                  '${module.lessons.length} bài học',
                  style: AppTextStyles.caption(context),
                ),
              ],
            ),
          ),
          ...module.lessons.map((lesson) => _buildLessonTile(context, module, lesson)),
        ],
      ),
    );
  }

  Widget _buildLessonTile(BuildContext context, ModuleModel module, LessonModel lesson) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      leading: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          shape: BoxShape.circle,
        ),
        child: Text(
          '${lesson.order}',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        lesson.title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Row(
        children: [
          Icon(Icons.timer_outlined, size: 13, color: isDark ? Colors.white60 : AppColors.textSecondaryLight),
          const SizedBox(width: 4),
          Text('${lesson.durationMinutes} phút', style: const TextStyle(fontSize: 12)),
          if (lesson.materials.isNotEmpty) ...[
            const SizedBox(width: 12),
            Icon(Icons.attach_file, size: 13, color: Theme.of(context).primaryColor),
            const SizedBox(width: 2),
            Text(
              '${lesson.materials.length} tài liệu',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LessonDetailScreen(
              moduleTitle: module.title,
              lesson: lesson,
            ),
          ),
        );
      },
    );
  }
}
