import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/searchable_entity_field.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/classes_bloc.dart';
import '../bloc/classes_event.dart';
import '../bloc/classes_state.dart';
import '../../data/models/class_model.dart';

class ClassDetailScreen extends StatefulWidget {
  final String classId;

  const ClassDetailScreen({super.key, required this.classId});

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen>
    with SingleTickerProviderStateMixin {
  final ApiClient _apiClient = getIt<ApiClient>();
  late TabController _tabController;
  String? _curriculumLevelId;
  Future<List<Map<String, dynamic>>>? _curriculumFuture;
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
  );

  bool get _canManageEnrollment {
    final state = context.read<AuthBloc?>()?.state;
    if (state is! AuthenticatedState) return false;
    final user = state.user;
    return user.isSuperAdmin || user.isBranchAdmin || user.isAcademicStaff;
  }

  bool get _canMarkAttendance {
    final state = context.read<AuthBloc?>()?.state;
    if (state is! AuthenticatedState) return false;
    return _canManageEnrollment || state.user.isTeacher;
  }

  bool get _canEditSession {
    return _canManageEnrollment;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<ClassesBloc>().add(FetchClassDetail(widget.classId));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadCurriculum(String levelId) async {
    final response = await _apiClient.get('/levels/$levelId/modules');
    final data = response is Map ? response['data'] ?? response : response;
    final items = data is List
        ? data
        : data is Map && data['items'] is List
        ? data['items'] as List
        : const [];
    return items
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Widget _buildCurriculumTab(ClassModel classObj) {
    if (_curriculumLevelId != classObj.levelId) {
      _curriculumLevelId = classObj.levelId;
      _curriculumFuture = _loadCurriculum(classObj.levelId);
    }
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _curriculumFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Không tải được giáo trình của lớp.'),
                TextButton(
                  onPressed: () => setState(() {
                    _curriculumFuture = _loadCurriculum(classObj.levelId);
                  }),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }
        final modules = snapshot.data ?? const [];
        final lessons = modules
            .expand(
              (module) =>
                  (module['lessons'] as List? ?? const []).whereType<Map>(),
            )
            .toList();
        final completedLessonIds = classObj.sessions
            .where(
              (session) =>
                  session.status == 'COMPLETED' && session.lessonId != null,
            )
            .map((session) => session.lessonId)
            .toSet()
            .intersection(
              lessons.map((lesson) => lesson['id']?.toString()).toSet(),
            );
        final progress = lessons.isEmpty
            ? 0.0
            : completedLessonIds.length / lessons.length;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tiến độ giáo trình',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: progress.clamp(0.0, 1.0)),
                  const SizedBox(height: 8),
                  Text(
                    '${completedLessonIds.length}/${lessons.length} bài học đã hoàn thành',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (modules.isEmpty)
              const Text('Chưa có giáo trình cho cấp độ này.'),
            ...modules.map((module) {
              final moduleLessons = (module['lessons'] as List? ?? const [])
                  .whereType<Map>()
                  .toList();
              return Card(
                child: ExpansionTile(
                  title: Text('${module['title'] ?? 'Chương học'}'),
                  children: moduleLessons.map((lesson) {
                    final id = lesson['id']?.toString();
                    final done = completedLessonIds.contains(id);
                    final materials = (lesson['materials'] as List? ?? const [])
                        .whereType<Map>()
                        .toList();
                    return Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            done
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: done ? Colors.green : null,
                          ),
                          title: Text('${lesson['title'] ?? 'Bài học'}'),
                          subtitle: Text(done ? 'Đã dạy' : 'Chưa hoàn thành'),
                        ),
                        ...materials.map(
                          (material) => ListTile(
                            contentPadding: const EdgeInsets.only(
                              left: 72,
                              right: 16,
                            ),
                            leading: const Icon(Icons.attach_file, size: 18),
                            title: Text('${material['title'] ?? 'Tài liệu'}'),
                            trailing: const Icon(Icons.open_in_new, size: 16),
                            onTap: () async {
                              final uri = Uri.tryParse(
                                '${material['fileUrl'] ?? ''}',
                              );
                              if (uri == null ||
                                  !['http', 'https'].contains(uri.scheme) ||
                                  !await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  )) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Không mở được tài liệu này.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Future<void> _showEnrollStudentDialog() async {
    final classState = context.read<ClassesBloc>().state;
    if (classState is! ClassDetailLoaded) return;
    final classDetail = classState.classDetail;
    final enrolledIds = classDetail.students
        .map((student) => student.studentId)
        .toSet();
    final options = <EntityOption>[];
    try {
      var page = 1;
      var totalPages = 1;
      do {
        final response = await _apiClient.get(
          '/users',
          queryParameters: {
            'role': 'student',
            'branchId': classDetail.branchId,
            'page': page,
            'limit': 100,
          },
        );
        final data = response is Map ? response['data'] ?? response : response;
        if (data is Map && data['items'] is List) {
          for (final raw in data['items'] as List) {
            if (raw is! Map) continue;
            final id = raw['id']?.toString() ?? '';
            if (id.isEmpty || enrolledIds.contains(id)) continue;
            options.add(
              EntityOption(
                id: id,
                label: '${raw['fullName'] ?? ''} (${raw['userCode'] ?? ''})',
              ),
            );
          }
          totalPages = int.tryParse('${data['totalPages']}') ?? 1;
        }
        page++;
      } while (page <= totalPages);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tải được danh sách học viên: $error')),
        );
      }
      return;
    }
    if (!mounted) return;
    String? selectedStudentId;
    final tuitionCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Ghi Danh Học Viên Vào Lớp',
          style: AppTextStyles.h4(context),
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SearchableEntityField(
                  label: 'Học viên *',
                  options: options,
                  hintText: 'Bấm để chọn hoặc gõ tên/mã học viên',
                  onSelected: (id) => selectedStudentId = id,
                ),
                if (options.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Không còn học viên phù hợp để ghi danh.'),
                  ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Số tiền học phí đã nộp (VNĐ)',
                  hintText: 'VD: 4500000',
                  keyboardType: TextInputType.number,
                  controller: tuitionCtrl,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Ghi chú ghi danh',
                  hintText: 'Học bổng, giảm giá, cam kết đầu ra...',
                  controller: notesCtrl,
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
              if (selectedStudentId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng chọn học viên từ danh sách.'),
                  ),
                );
                return;
              }
              Navigator.of(dialogCtx).pop();
              final fee = double.tryParse(tuitionCtrl.text.trim()) ?? 0;
              context.read<ClassesBloc>().add(
                EnrollStudentEvent(
                  classId: widget.classId,
                  studentId: selectedStudentId!,
                  tuitionPaid: fee,
                  notes: notesCtrl.text.trim().isEmpty
                      ? null
                      : notesCtrl.text.trim(),
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
            child: const Text('Ghi danh'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditSessionDialog(ClassSessionModel session) async {
    final classState = context.read<ClassesBloc>().state;
    if (classState is! ClassDetailLoaded) return;
    final branchId = classState.classDetail.branchId;
    final roomOptions = <EntityOption>[];
    final teacherOptions = <EntityOption>[];
    try {
      final roomResponse = await _apiClient.get('/branches/$branchId/rooms');
      final roomData = roomResponse is Map
          ? roomResponse['data'] ?? roomResponse
          : roomResponse;
      final rooms = roomData is List
          ? roomData
          : roomData is Map && roomData['items'] is List
          ? roomData['items'] as List
          : <dynamic>[];
      for (final raw in rooms) {
        if (raw is Map && raw['id'] != null) {
          roomOptions.add(
            EntityOption(
              id: raw['id'].toString(),
              label: '${raw['name'] ?? ''} (${raw['code'] ?? ''})',
            ),
          );
        }
      }
      final response = await _apiClient.get(
        '/users/teachers/lookup',
        queryParameters: {'branchId': branchId},
      );
      final data = response is Map ? response['data'] ?? response : response;
      if (data is List) {
        for (final raw in data) {
          if (raw is Map && raw['id'] != null) {
            teacherOptions.add(
              EntityOption(
                id: raw['id'].toString(),
                label: '${raw['fullName'] ?? ''} (${raw['userCode'] ?? ''})',
              ),
            );
          }
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không tải được phòng học hoặc giáo viên: $error'),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    final startTimeCtrl = TextEditingController(text: session.startTime);
    final endTimeCtrl = TextEditingController(text: session.endTime);
    final roomCtrl = TextEditingController(text: session.roomId ?? '');
    final teacherCtrl = TextEditingController(text: session.teacherId ?? '');
    String status = session.status;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Điều Chỉnh Buổi Học #${session.sessionNumber}',
            style: AppTextStyles.h4(context),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ngày: ${session.date != null ? DateFormat('dd/MM/yyyy').format(session.date!) : 'Chưa định'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Giờ bắt đầu',
                          hintText: '18:00',
                          controller: startTimeCtrl,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          label: 'Giờ kết thúc',
                          hintText: '19:30',
                          controller: endTimeCtrl,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SearchableEntityField(
                    label: 'Phòng học',
                    options: roomOptions,
                    selectedId: roomCtrl.text.isEmpty ? null : roomCtrl.text,
                    onSelected: (id) =>
                        setDialogState(() => roomCtrl.text = id ?? ''),
                  ),
                  const SizedBox(height: 14),
                  SearchableEntityField(
                    label: 'Giáo viên dạy thay',
                    options: teacherOptions,
                    selectedId: teacherCtrl.text.isEmpty
                        ? null
                        : teacherCtrl.text,
                    onSelected: (id) =>
                        setDialogState(() => teacherCtrl.text = id ?? ''),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Trạng thái buổi học',
                    style: AppTextStyles.caption(context)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: status,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'SCHEDULED',
                        child: Text('Đúng lịch (SCHEDULED)'),
                      ),
                      DropdownMenuItem(
                        value: 'COMPLETED',
                        child: Text('Đã hoàn thành (COMPLETED)'),
                      ),
                      DropdownMenuItem(
                        value: 'RESCHEDULED',
                        child: Text('Dời lịch (RESCHEDULED)'),
                      ),
                      DropdownMenuItem(
                        value: 'CANCELLED',
                        child: Text('Đã hủy buổi (CANCELLED)'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => status = val);
                      }
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
                Navigator.of(dialogCtx).pop();
                context.read<ClassesBloc>().add(
                  UpdateSessionEvent(
                    sessionId: session.id,
                    classId: widget.classId,
                    startTime: startTimeCtrl.text.trim(),
                    endTime: endTimeCtrl.text.trim(),
                    roomId: roomCtrl.text.trim().isNotEmpty
                        ? roomCtrl.text.trim()
                        : null,
                    teacherId: teacherCtrl.text.trim().isNotEmpty
                        ? teacherCtrl.text.trim()
                        : null,
                    status: status,
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
              child: const Text('Lưu thay đổi'),
            ),
          ],
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
        title: const Text('Chi tiết Lớp học'),
        elevation: 0,
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        foregroundColor: isDark ? Colors.white : AppColors.textPrimaryLight,
        actions: [
          IconButton(
            onPressed: () {
              context.push(
                '/classes/${widget.classId}/assignments',
                extra: _canMarkAttendance,
              );
            },
            icon: const Icon(Icons.assignment_outlined),
            tooltip: 'Bài tập của lớp',
          ),
          IconButton(
            onPressed: () {
              context.push('/exams', extra: widget.classId);
            },
            icon: const Icon(Icons.quiz_outlined),
            tooltip: 'Đề thi & Kiểm tra',
          ),
          IconButton(
            onPressed: () {
              context.read<ClassesBloc>().add(FetchClassDetail(widget.classId));
            },
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<ClassesBloc, ClassesState>(
        listener: (context, state) {
          if (state is ClassOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is ClassesError) {
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
          if (state is ClassDetailLoading) {
            return const LoadingWidget(
              message: 'Đang tải thông tin chi tiết lớp học...',
            );
          } else if (state is ClassesError) {
            return AppErrorWidget(
              message: state.message,
              onRetry: () {
                context.read<ClassesBloc>().add(
                  FetchClassDetail(widget.classId),
                );
              },
            );
          } else if (state is ClassDetailLoaded) {
            final classObj = state.classDetail;
            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildHeaderCard(context, classObj),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        labelColor: primaryColor,
                        unselectedLabelColor: isDark
                            ? Colors.white60
                            : AppColors.textSecondaryLight,
                        indicatorColor: primaryColor,
                        indicatorWeight: 3,
                        tabs: [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.calendar_month, size: 18),
                                const SizedBox(width: 8),
                                Text('Lịch học (${classObj.sessions.length})'),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.people_alt, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Học viên (${classObj.students.length}/${classObj.maxCapacity})',
                                ),
                              ],
                            ),
                          ),
                          const Tab(
                            icon: Icon(Icons.menu_book_outlined),
                            text: 'Giáo trình & tiến độ',
                          ),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildSessionsTab(context, classObj),
                  _buildStudentsTab(context, classObj),
                  _buildCurriculumTab(classObj),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, ClassModel classObj) {
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
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: primaryColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  classObj.code,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (classObj.courseTitle != null)
                Text(
                  classObj.courseTitle!,
                  style: AppTextStyles.caption(context)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  classObj.status,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            classObj.name,
            style: AppTextStyles.h4(context).copyWith(fontSize: 20),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: AppColors.secondary),
              const SizedBox(width: 6),
              Text(
                classObj.mainTeacherName != null
                    ? 'GV chính: ${classObj.mainTeacherName}'
                    : 'Chưa gán GV',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.room, size: 16, color: AppColors.accent),
              const SizedBox(width: 4),
              Text(
                classObj.roomName != null
                    ? 'Phòng: ${classObj.roomName}'
                    : 'Chưa xếp phòng',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 15,
                color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
              ),
              const SizedBox(width: 6),
              Text(
                '${classObj.startTime} - ${classObj.endTime} • ${classObj.totalSessions} buổi học',
                style: AppTextStyles.caption(context),
              ),
              if (_canManageEnrollment) ...[
                const SizedBox(width: 16),
                Icon(
                  Icons.payments_outlined,
                  size: 15,
                  color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
                ),
                const SizedBox(width: 6),
                Text(
                  _currencyFormat.format(classObj.tuitionFee),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsTab(BuildContext context, ClassModel classObj) {
    if (classObj.sessions.isEmpty) {
      return const EmptyStateWidget(
        title: 'Chưa có buổi học nào',
        description: 'Lớp học chưa được sinh thời khóa biểu.',
        icon: Icons.event_busy_outlined,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: classObj.sessions.length,
      separatorBuilder: (context, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final session = classObj.sessions[index];
        return AppCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '#${session.sessionNumber}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 13,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          session.date != null
                              ? DateFormat('dd/MM/yyyy').format(session.date!)
                              : '--',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.access_time,
                          size: 13,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${session.startTime} - ${session.endTime}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_canMarkAttendance)
                IconButton(
                  onPressed: () {
                    context.push('/sessions/${session.id}/attendance');
                  },
                  icon: const Icon(Icons.how_to_reg_outlined, size: 20),
                  tooltip: 'Điểm danh buổi học',
                  color: AppColors.success,
                ),
              if (_canEditSession)
                IconButton(
                  onPressed: () => _showEditSessionDialog(session),
                  icon: const Icon(Icons.edit_calendar_outlined, size: 20),
                  tooltip: 'Điều chỉnh buổi học',
                  color: Theme.of(context).primaryColor,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStudentsTab(BuildContext context, ClassModel classObj) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _canManageEnrollment
          ? FloatingActionButton.extended(
              onPressed: _showEnrollStudentDialog,
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Ghi danh HV'),
            )
          : null,
      body: classObj.students.isEmpty
          ? const EmptyStateWidget(
              title: 'Lớp chưa có học viên',
              description:
                  'Nhấn nút "Ghi danh HV" để thêm học viên vào danh sách lớp.',
              icon: Icons.person_off_outlined,
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: classObj.students.length,
              separatorBuilder: (context, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final student = classObj.students[index];
                return AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Theme.of(context).primaryColor
                            .withAlpha(30),
                        child: Text(
                          (student.studentName != null &&
                                  student.studentName!.isNotEmpty)
                              ? student.studentName![0].toUpperCase()
                              : 'HV',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.studentName ?? 'Học viên',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Mã: ${student.studentCode ?? student.studentId}${_canManageEnrollment ? ' • ${student.studentPhone ?? student.studentEmail ?? ''}' : ''}',
                              style: AppTextStyles.caption(context),
                            ),
                            if (_canManageEnrollment) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Đã nộp: ${_currencyFormat.format(student.tuitionPaid)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (_canManageEnrollment)
                        IconButton(
                          onPressed: () async {
                            final confirmed = await AppDialog.confirm(
                              context,
                              title: 'Xóa học viên khỏi lớp',
                              message:
                                  'Bạn có chắc chắn muốn xóa học viên ${student.studentName ?? ''} khỏi lớp học này không?',
                              confirmText: 'Xác nhận xóa',
                              confirmColor: AppColors.error,
                            );
                            if (confirmed == true && context.mounted) {
                              context.read<ClassesBloc>().add(
                                RemoveStudentEvent(
                                  classId: widget.classId,
                                  studentId: student.studentId,
                                ),
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.person_remove_outlined,
                            color: AppColors.error,
                            size: 20,
                          ),
                          tooltip: 'Xóa khỏi lớp',
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? AppColors.surfaceDark : Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
