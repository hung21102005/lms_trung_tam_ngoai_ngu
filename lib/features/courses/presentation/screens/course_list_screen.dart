import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/mobile/mobile_ui.dart';
import '../bloc/courses_bloc.dart';
import '../bloc/courses_event.dart';
import '../bloc/courses_state.dart';
import '../../data/models/course_model.dart';

class CourseListScreen extends StatefulWidget {
  final bool showAppBar;
  const CourseListScreen({super.key, this.showAppBar = true});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _activeCategoryIndex = 0;
  String _selectedLevel = 'ALL';
  String _selectedDuration = 'ALL';
  String _selectedStatus = 'ALL';

  List<Map<String, dynamic>> _buildCategories(List<CourseModel> liveCourses) {
    final total = liveCourses.length;
    final ieltsCount = liveCourses
        .where(
          (c) =>
              c.code.toUpperCase().contains('IELTS') ||
              c.title.toUpperCase().contains('IELTS'),
        )
        .length;
    final toeicCount = liveCourses
        .where(
          (c) =>
              c.code.toUpperCase().contains('TOEIC') ||
              c.title.toUpperCase().contains('TOEIC'),
        )
        .length;
    final commCount = liveCourses
        .where(
          (c) =>
              c.code.toUpperCase().contains('COMM') ||
              c.title.toLowerCase().contains('giao tiếp'),
        )
        .length;
    final kidsCount = liveCourses
        .where(
          (c) =>
              c.code.toUpperCase().contains('KIDS') ||
              c.title.toLowerCase().contains('thiếu nhi') ||
              c.title.toLowerCase().contains('cambridge'),
        )
        .length;

    return [
      {
        'title': 'Tất cả chương trình',
        'count': total,
        'icon': Icons.menu_book_rounded,
      },
      {
        'title': 'Luyện thi IELTS',
        'count': ieltsCount,
        'icon': Icons.military_tech_rounded,
      },
      {
        'title': 'Luyện thi TOEIC',
        'count': toeicCount,
        'icon': Icons.workspace_premium_rounded,
      },
      {
        'title': 'Tiếng Anh Giao tiếp',
        'count': commCount,
        'icon': Icons.record_voice_over_rounded,
      },
      {
        'title': 'Tiếng Anh Trẻ em & Cambridge',
        'count': kidsCount,
        'icon': Icons.child_care_rounded,
      },
    ];
  }

  @override
  void initState() {
    super.initState();
    context.read<CoursesBloc>().add(const FetchCourses());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateCourseDialog() {
    if (MediaQuery.sizeOf(context).width < 1024) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => _MobileCreateCourseSheet(
          onSubmit: (code, title, description, targetAudience, language) {
            context.read<CoursesBloc>().add(
              CreateCourseEvent(
                code: code,
                title: title,
                description: description,
                targetAudience: targetAudience,
                language: language,
              ),
            );
          },
        ),
      );
      return;
    }
    final codeCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final feeCtrl = TextEditingController(text: '14500000');
    final durationCtrl = TextEditingController(text: '72 giờ (24 buổi)');
    String dialogLang = 'English';

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.school_rounded, color: Color(0xFF003FB1)),
            SizedBox(width: 8),
            Text(
              'Tạo Khóa Học / Chương Trình Mới',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mã khóa học *',
                    hintText: 'VD: CRS-IELTS-65',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tên khóa học *',
                    hintText: 'VD: IELTS Fighter Intensive (Band 6.5 - 7.5+)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: feeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Học phí trọn khóa (VNĐ)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: durationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Thời lượng đào tạo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: dialogLang,
                  decoration: const InputDecoration(
                    labelText: 'Ngôn ngữ đào tạo',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'English',
                      child: Text('Tiếng Anh (English)'),
                    ),
                    DropdownMenuItem(
                      value: 'Japanese',
                      child: Text('Tiếng Nhật (Japanese)'),
                    ),
                    DropdownMenuItem(
                      value: 'Korean',
                      child: Text('Tiếng Hàn (Korean)'),
                    ),
                    DropdownMenuItem(
                      value: 'Chinese',
                      child: Text('Tiếng Trung (Chinese)'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) dialogLang = v;
                  },
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
                  titleCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng điền đủ mã và tên khóa học'),
                  ),
                );
                return;
              }
              Navigator.of(dialogCtx).pop();
              context.read<CoursesBloc>().add(
                CreateCourseEvent(
                  code: codeCtrl.text.trim().toUpperCase(),
                  title: titleCtrl.text.trim(),
                  language: dialogLang,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003FB1),
              foregroundColor: Colors.white,
            ),
            child: const Text('Tạo khóa học'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1024;
    final todayStr = DateFormat('dd/MM/yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Chương trình Đào tạo & Cấp độ'),
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F172A),
              actions: [
                IconButton(
                  onPressed: () => context.read<CoursesBloc>().add(
                    const FetchCourses(refresh: true),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            )
          : null,
      body: BlocConsumer<CoursesBloc, CoursesState>(
        listener: (context, state) {
          if (state is CourseOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is CoursesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          List<CourseModel> liveCourses = [];
          if (state is CoursesLoaded) {
            liveCourses = state.courses;
          }

          if (width < 1024) {
            return _buildMobileCourses(state, liveCourses);
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 24 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. PAGE HEADER TOOLBAR (Stitch Layout)
                Container(
                  padding: const EdgeInsets.only(bottom: 16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 12,
                                    runSpacing: 6,
                                    children: [
                                      Text(
                                        'Chương trình Đào tạo & Khung Cấp độ',
                                        style: AppTextStyles.h2(context)
                                            .copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF0F172A),
                                            ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F5E9),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircleAvatar(
                                              radius: 3.5,
                                              backgroundColor: Color(
                                                0xFF2E7D32,
                                              ),
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'Chuẩn hóa CEFR & Cambridge',
                                              style: TextStyle(
                                                color: Color(0xFF2E7D32),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.today_rounded,
                                        size: 16,
                                        color: Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Hôm nay: $todayStr • Tổng số ${liveCourses.length} chương trình đào tạo & ${liveCourses.fold<int>(0, (s, c) => s + c.levelsCount)} cấp độ đầu ra',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Đang xuất khung chương trình đào tạo (.xlsx)...',
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.file_download_outlined,
                                    size: 18,
                                    color: Color(0xFF003FB1),
                                  ),
                                  label: const Text('Xuất khung CTĐT (.xlsx)'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF0F172A),
                                    side: const BorderSide(
                                      color: Color(0xFFCBD5E1),
                                    ),
                                    backgroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _showCreateCourseDialog,
                                  icon: const Icon(
                                    Icons.add_circle_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('+ Tạo khóa học mới'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF003FB1),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 10,
                              runSpacing: 6,
                              children: [
                                Text(
                                  'Chương trình Đào tạo & Khung Cấp độ',
                                  style: AppTextStyles.h2(context).copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        radius: 3.5,
                                        backgroundColor: Color(0xFF2E7D32),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Chuẩn hóa CEFR & Cambridge',
                                        style: TextStyle(
                                          color: Color(0xFF2E7D32),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.today_rounded,
                                    size: 15,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Hôm nay: $todayStr • Tổng số ${liveCourses.length} chương trình đào tạo & ${liveCourses.fold<int>(0, (s, c) => s + c.levelsCount)} cấp độ đầu ra',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Đang xuất khung chương trình đào tạo (.xlsx)...',
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.file_download_outlined,
                                    size: 16,
                                    color: Color(0xFF003FB1),
                                  ),
                                  label: const Text('Xuất khung CTĐT (.xlsx)'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF0F172A),
                                    side: const BorderSide(
                                      color: Color(0xFFCBD5E1),
                                    ),
                                    backgroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _showCreateCourseDialog,
                                  icon: const Icon(
                                    Icons.add_circle_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('+ Tạo khóa học mới'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF003FB1),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 20),

                // 2. 4 KPI STAT CARDS (Stitch Layout)
                LayoutBuilder(
                  builder: (ctx, constraints) {
                    final cardWidth = isDesktop
                        ? (constraints.maxWidth - 48) / 4
                        : (constraints.maxWidth - 16) / 2;
                    final totalCourses = liveCourses.length;
                    final totalClasses = liveCourses.fold<int>(
                      0,
                      (s, c) => s + c.classesCount,
                    );
                    final totalLevels = liveCourses.fold<int>(
                      0,
                      (s, c) => s + c.levelsCount,
                    );
                    final activeCourses = liveCourses
                        .where((c) => c.isActive)
                        .length;

                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _buildStatCard(
                          title: 'Tổng số chương trình',
                          value: '$totalCourses khóa học',
                          subtext: totalCourses > 0
                              ? liveCourses.map((c) => c.code).join(', ')
                              : 'Chưa có khóa học',
                          icon: Icons.school_rounded,
                          iconBg: const Color(0xFFEEF2FF),
                          iconColor: const Color(0xFF003FB1),
                          width: cardWidth,
                        ),
                        _buildStatCard(
                          title: 'Lớp học đang áp dụng',
                          value: '$totalClasses lớp',
                          subtext: '100% khớp giáo trình',
                          icon: Icons.class_rounded,
                          iconBg: const Color(0xFFEFF6FF),
                          iconColor: const Color(0xFF2563EB),
                          pillColor: const Color(0xFFEFF6FF),
                          pillTextColor: const Color(0xFF1D4ED8),
                          width: cardWidth,
                        ),
                        _buildStatCard(
                          title: 'Tổng số cấp độ (Levels)',
                          value: '$totalLevels cấp độ',
                          subtext: 'Phân tầng chuẩn CEFR',
                          icon: Icons.layers_rounded,
                          iconBg: const Color(0xFFF0FDF4),
                          iconColor: const Color(0xFF16A34A),
                          pillColor: const Color(0xFFDCFCE7),
                          pillTextColor: const Color(0xFF15803D),
                          width: cardWidth,
                        ),
                        _buildStatCard(
                          title: 'Trạng thái hoạt động',
                          value: '$activeCourses/$totalCourses khóa',
                          subtext: 'Đang mở tuyển sinh',
                          icon: Icons.verified_user_rounded,
                          iconBg: const Color(0xFFECFDF5),
                          iconColor: const Color(0xFF059669),
                          pillColor: const Color(0xFFECFDF5),
                          pillTextColor: const Color(0xFF047857),
                          width: cardWidth,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // 3. TABS PHÂN LOẠI & TOOLBAR BỘ LỌC
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x06000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Perspective Tabs
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _buildCategories(liveCourses)
                              .asMap()
                              .entries
                              .map((entry) {
                                final idx = entry.key;
                                final cat = entry.value;
                                final isSelected = _activeCategoryIndex == idx;

                                return InkWell(
                                  onTap: () => setState(
                                    () => _activeCategoryIndex = idx,
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 20),
                                    padding: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: isSelected
                                              ? const Color(0xFF003FB1)
                                              : Colors.transparent,
                                          width: 2.5,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          cat['icon'] as IconData,
                                          size: 18,
                                          color: isSelected
                                              ? const Color(0xFF003FB1)
                                              : const Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${cat["title"]} (${cat["count"]})',
                                          style: TextStyle(
                                            color: isSelected
                                                ? const Color(0xFF003FB1)
                                                : const Color(0xFF64748B),
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              })
                              .toList(),
                        ),
                      ),
                      const Divider(color: Color(0xFFE2E8F0), height: 1),
                      const SizedBox(height: 14),

                      // Filter controls
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            width: isDesktop ? 340 : double.infinity,
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Tìm theo tên khóa học, mã môn...',
                                hintStyle: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF94A3B8),
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  size: 20,
                                  color: Color(0xFF64748B),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFCBD5E1),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFCBD5E1),
                                  ),
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedLevel,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'ALL',
                                    child: Text('Trình độ: Tất cả cấp bậc'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'A1-A2',
                                    child: Text('Beginner (A1 - A2)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'B1-B2',
                                    child: Text('Intermediate (B1 - B2)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'C1-C2',
                                    child: Text('Advanced (C1 - C2)'),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _selectedLevel = v);
                                  }
                                },
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedDuration,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'ALL',
                                    child: Text('Thời lượng: Tất cả'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'SHORT',
                                    child: Text('Khóa ngắn hạn (Dưới 48h)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'STANDARD',
                                    child: Text('Khóa tiêu chuẩn (60 - 72h)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'LONG',
                                    child: Text('Khóa dài hạn (Trên 90h)'),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _selectedDuration = v);
                                  }
                                },
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedStatus,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'ALL',
                                    child: Text('Trạng thái: Đang mở ghi danh'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'OPEN',
                                    child: Text('Đang tuyển sinh'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'UPCOMING',
                                    child: Text('Dự kiến mở lớp'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'UPDATING',
                                    child: Text('Đang cập nhật giáo trình'),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _selectedStatus = v);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 4. DANH SÁCH / GRID THẺ KHÓA HỌC TRỰC QUAN (2 Columns)
                if (state is CoursesLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: LoadingWidget(
                      message: 'Đang tải danh mục chương trình đào tạo...',
                    ),
                  )
                else if (state is CoursesError)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: AppErrorWidget(
                      message: state.message,
                      onRetry: () =>
                          context.read<CoursesBloc>().add(const FetchCourses()),
                    ),
                  )
                else
                  _buildCourseCardsGrid(liveCourses),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileCourses(CoursesState state, List<CourseModel> courses) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = courses.where((course) {
      final matchesText =
          query.isEmpty ||
          course.title.toLowerCase().contains(query) ||
          course.code.toLowerCase().contains(query);
      final matchesStatus =
          _selectedStatus == 'ALL' ||
          (_selectedStatus == 'ACTIVE' && course.isActive) ||
          (_selectedStatus == 'INACTIVE' && !course.isActive);
      return matchesText && matchesStatus;
    }).toList();
    final activeCount = courses.where((course) => course.isActive).length;

    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          Text(
            'Chương trình đào tạo',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Quản lý khóa học và cấp độ',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 16),
          MobileSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Khóa học hiện có',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '${courses.length}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$activeCount đang hoạt động · ${courses.fold<int>(0, (sum, course) => sum + course.levelsCount)} cấp độ',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: MobileTokens.sectionGap),
          FilledButton.icon(
            onPressed: _showCreateCourseDialog,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tạo khóa học mới'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Tìm tên hoặc mã khóa học',
              prefixIcon: Icon(Icons.search_rounded),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final entry in const [
                  ('ALL', 'Tất cả'),
                  ('ACTIVE', 'Đang hoạt động'),
                  ('INACTIVE', 'Tạm ngưng'),
                ]) ...[
                  ChoiceChip(
                    label: Text(entry.$2),
                    selected: _selectedStatus == entry.$1,
                    onSelected: (_) =>
                        setState(() => _selectedStatus = entry.$1),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (state is CoursesLoading || state is CoursesInitial)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (state is CoursesError)
            MobileSectionCard(
              child: Column(
                children: [
                  Text('Không tải được khóa học: ${state.message}'),
                  TextButton.icon(
                    onPressed: () => context.read<CoursesBloc>().add(
                      const FetchCourses(refresh: true),
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            )
          else if (filtered.isEmpty)
            const MobileSectionCard(child: Text('Không có khóa học phù hợp'))
          else
            for (final course in filtered) ...[
              _mobileCourseCard(course),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  Widget _mobileCourseCard(CourseModel course) {
    return MobileSectionCard(
      child: InkWell(
        onTap: () => context.push('/courses/${course.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    course.code,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(color: AppColors.primary),
                  ),
                ),
                MobileStatusPill(
                  label: course.isActive ? 'Hoạt động' : 'Tạm ngưng',
                  color: course.isActive
                      ? AppColors.success
                      : AppColors.textSecondaryLight,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              course.title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (course.description?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 6),
              Text(
                course.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                Text('${course.levelsCount} cấp độ'),
                Text('${course.classesCount} lớp'),
                Text(course.language),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Xem chi tiết',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    Color? pillColor,
    Color? pillTextColor,
    required double width,
  }) {
    final isCompact = width < 220;
    return Container(
      width: width,
      padding: EdgeInsets.all(isCompact ? 14 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isCompact ? 12 : 13,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: isCompact ? 32 : 38,
                height: isCompact ? 32 : 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: isCompact ? 18 : 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isCompact ? 18 : 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          if (pillColor != null && pillTextColor != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: pillColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                subtext,
                style: TextStyle(
                  color: pillTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Text(
              subtext,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
        ],
      ),
    );
  }

  Widget _buildCourseCardsGrid(List<CourseModel> liveCourses) {
    // If live courses exist, combine with high-fidelity Stitch curriculum templates
    final displayItems = _getCurriculumCourseCards(liveCourses);

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isTwoCol = constraints.maxWidth > 900;
        final cardWidth = isTwoCol
            ? (constraints.maxWidth - 20) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: displayItems
              .map((item) => _buildCourseCard(item, cardWidth))
              .toList(),
        );
      },
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> c, double width) {
    final code = c['code'] ?? 'CRS-IELTS-65';
    final title = c['title'] ?? 'IELTS Fighter Intensive';
    final target = c['target'] ?? 'Band 6.5 - 7.5+';
    final duration = c['duration'] ?? '72 giờ (24 buổi)';
    final frequency = c['frequency'] ?? '3 ca/tuần (2-4-6)';
    final capacity = c['capacity'] ?? '18 học viên/lớp';
    final tuition = c['tuition'] ?? '14.500.000 đ';
    final curriculum =
        c['curriculum'] ?? 'Cambridge IELTS 18-19 & Tài liệu Độc quyền';
    final icon = c['icon'] as IconData? ?? Icons.military_tech_rounded;
    final classesActive = c['classesCount'] ?? 18;
    final studentsCount = c['studentsCount'] ?? 284;

    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF003FB1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            code,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 3,
                                backgroundColor: Color(0xFF059669),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Đang mở ghi danh',
                                style: TextStyle(
                                  color: Color(0xFF047857),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Mục tiêu: $target',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF003FB1), size: 22),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Meta Specs 4-Box Row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: width > 520
                ? Row(
                    children: [
                      Expanded(child: _buildSpecCol('Thời lượng:', duration)),
                      Expanded(child: _buildSpecCol('Tần suất:', frequency)),
                      Expanded(child: _buildSpecCol('Sĩ số tối đa:', capacity)),
                      Expanded(
                        child: _buildSpecCol(
                          'Học phí:',
                          tuition,
                          isPrice: true,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildSpecCol('Thời lượng:', duration),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSpecCol('Tần suất:', frequency),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSpecCol('Sĩ số tối đa:', capacity),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSpecCol(
                              'Học phí:',
                              tuition,
                              isPrice: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),

          // Giáo trình tham chiếu
          Row(
            children: [
              const Icon(
                Icons.auto_stories_rounded,
                size: 16,
                color: Color(0xFF003FB1),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Giáo trình: $curriculum',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Lộ trình 3 giai đoạn (Pathway)
          const Text(
            'LỘ TRÌNH ĐÀO TẠO 3 GIAI ĐOẠN (PATHWAY):',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 8),
          if (width > 520)
            Row(
              children: [
                Expanded(
                  child: _buildPathwayBox(
                    title: 'GĐ 1: Foundation',
                    weeks: 'Tuần 1-3',
                    desc: 'Củng cố ngữ pháp & Phát âm nền tảng',
                    sub: '6 buổi • 18 giờ',
                    bgColor: const Color(0xFFEEF2FF),
                    textColor: const Color(0xFF003FB1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPathwayBox(
                    title: 'GĐ 2: Skill Mastery',
                    weeks: 'Tuần 4-6',
                    desc: 'Chiến lược giải đề & Phản xạ thực chiến',
                    sub: '12 buổi • 36 giờ',
                    bgColor: const Color(0xFFEFF6FF),
                    textColor: const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPathwayBox(
                    title: 'GĐ 3: Mock Test',
                    weeks: 'Tuần 7-8',
                    desc: 'Thi thử phòng thi thật & 1-1 Coaching',
                    sub: '6 buổi • 18 giờ',
                    bgColor: const Color(0xFFECFDF5),
                    textColor: const Color(0xFF047857),
                  ),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPathwayBox(
                  title: 'GĐ 1: Foundation',
                  weeks: 'Tuần 1-3',
                  desc: 'Củng cố ngữ pháp & Phát âm nền tảng',
                  sub: '6 buổi • 18 giờ',
                  bgColor: const Color(0xFFEEF2FF),
                  textColor: const Color(0xFF003FB1),
                ),
                const SizedBox(height: 8),
                _buildPathwayBox(
                  title: 'GĐ 2: Skill Mastery',
                  weeks: 'Tuần 4-6',
                  desc: 'Chiến lược giải đề & Phản xạ thực chiến',
                  sub: '12 buổi • 36 giờ',
                  bgColor: const Color(0xFFEFF6FF),
                  textColor: const Color(0xFF2563EB),
                ),
                const SizedBox(height: 8),
                _buildPathwayBox(
                  title: 'GĐ 3: Mock Test',
                  weeks: 'Tuần 7-8',
                  desc: 'Thi thử phòng thi thật & 1-1 Coaching',
                  sub: '6 buổi • 18 giờ',
                  bgColor: const Color(0xFFECFDF5),
                  textColor: const Color(0xFF047857),
                ),
              ],
            ),
          const SizedBox(height: 16),

          // Footer Card & Action Buttons
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.groups_rounded,
                      size: 16,
                      color: Color(0xFF003FB1),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Đang mở: $classesActive lớp • $studentsCount cấp độ',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Chỉnh sửa giáo trình: $title'),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        'Chỉnh sửa',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Chi tiết lộ trình: $title')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003FB1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Lộ trình',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecCol(String label, String value, {bool isPrice = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isPrice ? const Color(0xFF003FB1) : const Color(0xFF0F172A),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPathwayBox({
    required String title,
    required String weeks,
    required String desc,
    required String sub,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                weeks,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(fontSize: 10, color: Color(0xFF0F172A)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getCurriculumCourseCards(
    List<CourseModel> liveCourses,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = liveCourses.where((lc) {
      if (_activeCategoryIndex == 1 &&
          !lc.code.toUpperCase().contains('IELTS') &&
          !lc.title.toUpperCase().contains('IELTS')) {
        return false;
      }
      if (_activeCategoryIndex == 2 &&
          !lc.code.toUpperCase().contains('TOEIC') &&
          !lc.title.toUpperCase().contains('TOEIC')) {
        return false;
      }
      if (_activeCategoryIndex == 3 &&
          !lc.code.toUpperCase().contains('COMM') &&
          !lc.title.toLowerCase().contains('giao tiếp')) {
        return false;
      }
      if (_activeCategoryIndex == 4 &&
          !lc.code.toUpperCase().contains('KIDS') &&
          !lc.title.toLowerCase().contains('thiếu nhi') &&
          !lc.title.toLowerCase().contains('cambridge')) {
        return false;
      }
      if (query.isNotEmpty) {
        return lc.code.toLowerCase().contains(query) ||
            lc.title.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    return filtered.map((lc) {
      final isIelts =
          lc.code.toUpperCase().contains('IELTS') ||
          lc.title.toUpperCase().contains('IELTS');
      final totalSessions = lc.levels.isNotEmpty
          ? lc.levels.fold<int>(0, (s, l) => s + l.estimatedSessions)
          : (isIelts ? 24 : 20);
      final totalHours = totalSessions * 2;
      final levelNames = lc.levels.isNotEmpty
          ? lc.levels.map((l) => l.name).join(' • ')
          : (lc.description ?? 'Giáo trình chuẩn hóa theo khung CEFR');

      return {
        'code': lc.code,
        'title': lc.title,
        'target': lc.targetAudience ?? 'Chuẩn đầu ra CEFR',
        'duration': '$totalHours giờ ($totalSessions buổi)',
        'frequency': '3 ca/tuần',
        'capacity': isIelts ? '25 học viên/lớp' : '30 học viên/lớp',
        'tuition': isIelts ? '4.500.000 đ' : '3.200.000 đ',
        'curriculum': levelNames,
        'icon': isIelts
            ? Icons.military_tech_rounded
            : Icons.record_voice_over_rounded,
        'classesCount': lc.classesCount,
        'studentsCount': lc.levelsCount,
      };
    }).toList();
  }
}

class _MobileCreateCourseSheet extends StatefulWidget {
  const _MobileCreateCourseSheet({required this.onSubmit});

  final void Function(
    String code,
    String title,
    String? description,
    String? targetAudience,
    String language,
  )
  onSubmit;

  @override
  State<_MobileCreateCourseSheet> createState() =>
      _MobileCreateCourseSheetState();
}

class _MobileCreateCourseSheetState extends State<_MobileCreateCourseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _audienceController = TextEditingController();
  String _language = 'English';

  @override
  void dispose() {
    _codeController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _audienceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(
      _codeController.text.trim().toUpperCase(),
      _titleController.text.trim(),
      _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      _audienceController.text.trim().isEmpty
          ? null
          : _audienceController.text.trim(),
      _language,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: SafeArea(
          top: false,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            children: [
              Text(
                'Tạo khóa học mới',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text('Thiết lập thông tin chương trình đào tạo.'),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Mã khóa học *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.trim().isEmpty == true
                          ? 'Nhập mã khóa học'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tên khóa học *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.trim().isEmpty == true
                          ? 'Nhập tên khóa học'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _audienceController,
                      decoration: const InputDecoration(
                        labelText: 'Đối tượng học viên',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _descriptionController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _language,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Ngôn ngữ',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'English',
                          child: Text('Tiếng Anh'),
                        ),
                        DropdownMenuItem(
                          value: 'Japanese',
                          child: Text('Tiếng Nhật'),
                        ),
                        DropdownMenuItem(
                          value: 'Korean',
                          child: Text('Tiếng Hàn'),
                        ),
                        DropdownMenuItem(
                          value: 'Chinese',
                          child: Text('Tiếng Trung'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _language = value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submit,
                child: const Text('Tạo khóa học'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
