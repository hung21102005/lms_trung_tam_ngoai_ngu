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
import '../../../../shared/widgets/mobile/mobile_ui.dart';
import '../bloc/courses_bloc.dart';
import '../bloc/courses_event.dart';
import '../bloc/courses_state.dart';
import '../../data/models/course_model.dart';
import 'lesson_detail_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;
  final bool canEditAcademicLevel;

  const CourseDetailScreen({
    super.key,
    required this.courseId,
    this.canEditAcademicLevel = true,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
  );

  @override
  void initState() {
    super.initState();
    context.read<CoursesBloc>().add(FetchCourseDetail(widget.courseId));
  }

  void _showAddLevelDialog() {
    if (MediaQuery.sizeOf(context).width < 1024) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => _MobileCreateLevelSheet(
          onSubmit: (code, name, description, sessions, fee) {
            context.read<CoursesBloc>().add(
              CreateCourseLevelEvent(
                courseId: widget.courseId,
                code: code,
                name: name,
                description: description,
                estimatedSessions: sessions,
                tuitionFee: fee,
              ),
            );
          },
        ),
      );
      return;
    }
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final sessionsCtrl = TextEditingController(text: '24');
    final feeCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Thêm Cấp Độ Đào Tạo Mới',
          style: AppTextStyles.h4(context),
        ),
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
                  hintText:
                      'Chuẩn đầu ra của học viên sau khi hoàn thành level...',
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
              if (codeCtrl.text.trim().isEmpty ||
                  nameCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập đầy đủ mã và tên cấp độ'),
                  ),
                );
                return;
              }
              Navigator.of(dialogCtx).pop();
              final sessions = int.tryParse(sessionsCtrl.text.trim()) ?? 24;
              final fee = double.tryParse(feeCtrl.text.trim()) ?? 0;

              context.read<CoursesBloc>().add(
                CreateCourseLevelEvent(
                  courseId: widget.courseId,
                  code: codeCtrl.text.trim().toUpperCase(),
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim().isEmpty
                      ? null
                      : descCtrl.text.trim(),
                  estimatedSessions: sessions,
                  tuitionFee: fee,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Thêm cấp độ'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditLevelDialog(CourseLevelModel level) async {
    final bloc = context.read<CoursesBloc>();
    if (MediaQuery.sizeOf(context).width < 1024) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: _EditLevelForm(
            level: level,
            onSubmit: (changes) => bloc.add(
              UpdateCourseLevelEvent(
                courseId: widget.courseId,
                levelId: level.id,
                changes: changes,
              ),
            ),
          ),
        ),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 760),
          child: BlocProvider.value(
            value: bloc,
            child: _EditLevelForm(
              level: level,
              onSubmit: (changes) => bloc.add(
                UpdateCourseLevelEvent(
                  courseId: widget.courseId,
                  levelId: level.id,
                  changes: changes,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Chi tiết Khóa học'),
        elevation: 0,
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        foregroundColor: isDark ? Colors.white : AppColors.textPrimaryLight,
        actions: [
          IconButton(
            onPressed: () {
              context.read<CoursesBloc>().add(
                FetchCourseDetail(widget.courseId),
              );
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
            return const LoadingWidget(
              message: 'Đang tải thông tin chi tiết khóa học...',
            );
          } else if (state is CoursesError) {
            if (MediaQuery.sizeOf(context).width < 1024) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: MobileSectionCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                          size: 36,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Không tải được khóa học: ${state.message}',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => context.read<CoursesBloc>().add(
                            FetchCourseDetail(widget.courseId),
                          ),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return AppErrorWidget(
              message: state.message,
              onRetry: () {
                context.read<CoursesBloc>().add(
                  FetchCourseDetail(widget.courseId),
                );
              },
            );
          } else if (state is CourseDetailLoaded) {
            final course = state.course;
            if (MediaQuery.sizeOf(context).width < 1024) {
              return _buildMobileDetail(course);
            }
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
                  ...course.levels.map(
                    (level) => _buildLevelCard(context, level),
                  ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildMobileDetail(CourseModel course) {
    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          MobileSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    MobileStatusPill(
                      label: course.code,
                      color: AppColors.primary,
                    ),
                    MobileStatusPill(
                      label: course.isActive ? 'Đang đào tạo' : 'Tạm dừng',
                      color: course.isActive
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  course.title,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (course.description?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 10),
                  Text(course.description!),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Text('${course.levelsCount} cấp độ'),
                    Text('${course.classesCount} lớp'),
                    Text(course.language),
                  ],
                ),
                if (course.targetAudience?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 10),
                  Text('Đối tượng: ${course.targetAudience}'),
                ],
              ],
            ),
          ),
          const SizedBox(height: MobileTokens.sectionGap),
          Text(
            'Lộ trình học tập',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _showAddLevelDialog,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Thêm cấp độ'),
          ),
          const SizedBox(height: 16),
          if (course.levels.isEmpty)
            const MobileSectionCard(child: Text('Chưa có cấp độ đào tạo nào'))
          else
            for (final level in course.levels) ...[
              _mobileLevelCard(level),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  Widget _mobileLevelCard(CourseLevelModel level) {
    return MobileSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MobileStatusPill(label: level.code, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            level.name,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (level.description?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(level.description!),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              Text('${level.estimatedSessions} buổi'),
              Text(_currencyFormat.format(level.tuitionFee)),
              Text('${level.modules.length} học phần'),
            ],
          ),
          if (widget.canEditAcademicLevel)
            TextButton.icon(
              onPressed: () => _showEditLevelDialog(level),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Sửa cấp độ'),
            ),
          const Divider(height: 24),
          if (level.modules.isEmpty)
            const Text('Chưa có học phần hoặc bài học')
          else
            for (final module in level.modules)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Text(
                  module.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('${module.lessons.length} bài học'),
                children: [
                  if (module.lessons.isEmpty)
                    const ListTile(title: Text('Chưa có bài học'))
                  else
                    for (final lesson in module.lessons)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(lesson.title),
                        subtitle: Text(
                          '${lesson.durationMinutes} phút · ${lesson.materials.length} tài liệu',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LessonDetailScreen(
                              moduleTitle: module.title,
                              lesson: lesson,
                            ),
                          ),
                        ),
                      ),
                ],
              ),
        ],
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.language, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      course.language,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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
                    color: course.isActive
                        ? AppColors.success
                        : AppColors.error,
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
          if (course.targetAudience != null &&
              course.targetAudience!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.people_outline,
                  size: 16,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Đối tượng: ${course.targetAudience}',
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? Colors.white70
                        : AppColors.textSecondaryLight,
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
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 8,
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: isDark
                        ? Colors.white60
                        : AppColors.textSecondaryLight,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${level.estimatedSessions} buổi',
                    style: AppTextStyles.caption(context),
                  ),
                  const SizedBox(width: 14),
                  Icon(
                    Icons.payments_outlined,
                    size: 14,
                    color: isDark
                        ? Colors.white60
                        : AppColors.textSecondaryLight,
                  ),
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
                  Icon(
                    Icons.library_books_outlined,
                    size: 14,
                    color: isDark
                        ? Colors.white60
                        : AppColors.textSecondaryLight,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${level.modules.length} modules',
                    style: AppTextStyles.caption(context),
                  ),
                ],
              ),
            ),
            children: [
              if (widget.canEditAcademicLevel)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _showEditLevelDialog(level),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Sửa cấp độ'),
                  ),
                ),
              const Divider(height: 1),
              if (level.modules.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'Chưa có chương trình/bài học chi tiết cho level này.',
                    ),
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
        color: isDark
            ? const Color(0xFF1E293B).withAlpha(120)
            : const Color(0xFFF8FAFC),
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
                const Icon(
                  Icons.folder_open_rounded,
                  size: 18,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    module.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  '${module.lessons.length} bài học',
                  style: AppTextStyles.caption(context),
                ),
              ],
            ),
          ),
          ...module.lessons.map(
            (lesson) => _buildLessonTile(context, module, lesson),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonTile(
    BuildContext context,
    ModuleModel module,
    LessonModel lesson,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: ListTile(
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
            Icon(
              Icons.timer_outlined,
              size: 13,
              color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
            ),
            const SizedBox(width: 4),
            Text(
              '${lesson.durationMinutes} phút',
              style: const TextStyle(fontSize: 12),
            ),
            if (lesson.materials.isNotEmpty) ...[
              const SizedBox(width: 12),
              Icon(
                Icons.attach_file,
                size: 13,
                color: Theme.of(context).primaryColor,
              ),
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
              builder: (_) =>
                  LessonDetailScreen(moduleTitle: module.title, lesson: lesson),
            ),
          );
        },
      ),
    );
  }
}

class _MobileCreateLevelSheet extends StatefulWidget {
  const _MobileCreateLevelSheet({required this.onSubmit});

  final void Function(
    String code,
    String name,
    String? description,
    int sessions,
    double fee,
  )
  onSubmit;

  @override
  State<_MobileCreateLevelSheet> createState() =>
      _MobileCreateLevelSheetState();
}

class _MobileCreateLevelSheetState extends State<_MobileCreateLevelSheet> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sessionsController = TextEditingController(text: '24');
  final _feeController = TextEditingController(text: '0');

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _sessionsController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(
      _codeController.text.trim().toUpperCase(),
      _nameController.text.trim(),
      _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      int.parse(_sessionsController.text.trim()),
      double.parse(_feeController.text.trim()),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight:
              (MediaQuery.sizeOf(context).height * 0.9 -
                      MediaQuery.viewInsetsOf(context).bottom)
                  .clamp(120.0, double.infinity),
        ),
        child: SafeArea(
          top: false,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            children: [
              Text(
                'Thêm cấp độ',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text('Thiết lập một bước trong lộ trình học tập.'),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Mã cấp độ *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.trim().isEmpty == true
                          ? 'Nhập mã cấp độ'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên cấp độ *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.trim().isEmpty == true
                          ? 'Nhập tên cấp độ'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _sessionsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Số buổi học *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final count = int.tryParse(value?.trim() ?? '');
                        return count == null || count <= 0
                            ? 'Số buổi phải lớn hơn 0'
                            : null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _feeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Học phí chuẩn (VNĐ)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final fee = double.tryParse(value?.trim() ?? '');
                        return fee == null || fee < 0
                            ? 'Học phí không hợp lệ'
                            : null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _descriptionController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Mục tiêu đầu ra',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(onPressed: _submit, child: const Text('Lưu cấp độ')),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditLevelForm extends StatefulWidget {
  final CourseLevelModel level;
  final ValueChanged<Map<String, dynamic>> onSubmit;

  const _EditLevelForm({required this.level, required this.onSubmit});

  @override
  State<_EditLevelForm> createState() => _EditLevelFormState();
}

class _EditLevelFormState extends State<_EditLevelForm> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final level = widget.level;
    _fields = {
      'code': TextEditingController(text: level.code),
      'name': TextEditingController(text: level.name),
      'description': TextEditingController(text: level.description ?? ''),
      'cefrLevel': TextEditingController(text: level.cefrLevel ?? ''),
      'ieltsTargetBand': TextEditingController(
        text: level.ieltsTargetBand?.toString() ?? '',
      ),
      'toeicTargetScore': TextEditingController(
        text: level.toeicTargetScore?.toString() ?? '',
      ),
      'cambridgeQualification': TextEditingController(
        text: level.cambridgeQualification ?? '',
      ),
      'entryRequirements': TextEditingController(
        text: level.entryRequirements ?? '',
      ),
      'completionCriteria': TextEditingController(
        text: level.completionCriteria ?? '',
      ),
      'recommendedHours': TextEditingController(
        text: level.recommendedHours?.toString() ?? '',
      ),
      'estimatedSessions': TextEditingController(
        text: level.estimatedSessions.toString(),
      ),
    };
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (_saving || !_formKey.currentState!.validate()) return;
    String? text(String key) {
      final value = _fields[key]!.text.trim();
      return value.isEmpty ? null : value;
    }

    setState(() => _saving = true);
    widget.onSubmit({
      'code': text('code'),
      'name': text('name'),
      'description': text('description'),
      'cefrLevel': text('cefrLevel'),
      'ieltsTargetBand': text('ieltsTargetBand') == null
          ? null
          : double.parse(text('ieltsTargetBand')!),
      'toeicTargetScore': text('toeicTargetScore') == null
          ? null
          : int.parse(text('toeicTargetScore')!),
      'cambridgeQualification': text('cambridgeQualification'),
      'entryRequirements': text('entryRequirements'),
      'completionCriteria': text('completionCriteria'),
      'recommendedHours': text('recommendedHours') == null
          ? null
          : int.parse(text('recommendedHours')!),
      'estimatedSessions': int.parse(text('estimatedSessions')!),
    });
  }

  @override
  Widget build(BuildContext context) => BlocListener<CoursesBloc, CoursesState>(
    listener: (context, state) {
      if (!_saving) return;
      if (state is CourseOperationSuccess) {
        Navigator.pop(context);
      } else if (state is CoursesError) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(state.message)));
      }
    },
    child: SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Sửa cấp độ học thuật',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Các mục tiêu khảo thí là tham khảo; cần rà soát trước khi công bố khóa.',
                ),
                const SizedBox(height: 16),
                _field('code', 'Mã cấp độ', required: true),
                _field('name', 'Tên cấp độ', required: true),
                _field('description', 'Mục tiêu đầu ra', lines: 3),
                _field('cefrLevel', 'CEFR (nếu áp dụng)'),
                _field(
                  'ieltsTargetBand',
                  'IELTS target band (nếu áp dụng)',
                  number: true,
                ),
                _field(
                  'toeicTargetScore',
                  'TOEIC target score (nếu áp dụng)',
                  number: true,
                ),
                _field(
                  'cambridgeQualification',
                  'Cambridge qualification (nếu áp dụng)',
                ),
                _field('entryRequirements', 'Yêu cầu đầu vào', lines: 2),
                _field('completionCriteria', 'Tiêu chí hoàn thành', lines: 2),
                _field('recommendedHours', 'Giờ học tham khảo', number: true),
                _field(
                  'estimatedSessions',
                  'Số buổi dự kiến',
                  number: true,
                  required: true,
                ),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: Text(_saving ? 'Đang lưu...' : 'Lưu cấp độ'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _field(
    String key,
    String label, {
    bool required = false,
    bool number = false,
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: _fields[key],
      maxLines: lines,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (required && trimmed.isEmpty) return 'Vui lòng nhập $label';
        if (trimmed.isEmpty || !number) return null;
        if (key == 'ieltsTargetBand') {
          final band = double.tryParse(trimmed);
          if (band == null || band < 0 || band > 9) {
            return 'IELTS phải từ 0 đến 9';
          }
        } else {
          final parsed = int.tryParse(trimmed);
          if (parsed == null || parsed <= 0) {
            return 'Vui lòng nhập số nguyên dương';
          }
          if (key == 'toeicTargetScore' && (parsed < 10 || parsed > 990)) {
            return 'TOEIC phải từ 10 đến 990';
          }
        }
        return null;
      },
    ),
  );
}
