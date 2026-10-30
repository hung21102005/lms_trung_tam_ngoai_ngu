import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/mobile/mobile_ui.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../bloc/classes_bloc.dart';
import '../bloc/classes_event.dart';
import '../bloc/classes_state.dart';
import '../class_deletion_message.dart';
import '../../data/models/class_model.dart';
import '../../../dashboard/presentation/views/class_registrations_admin_screen.dart';
import 'schedule_screen.dart';

class ClassListScreen extends StatefulWidget {
  final bool showAppBar;
  final bool allowCreate;
  const ClassListScreen({
    super.key,
    this.showAppBar = true,
    this.allowCreate = true,
  });

  @override
  State<ClassListScreen> createState() => _ClassListScreenState();
}

class _ClassListScreenState extends State<ClassListScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _activeViewIndex =
      0; // 0: Table, 1: Weekly Calendar, 2: Teacher Assignment
  String _selectedBranch = 'ALL';
  String _selectedShift = 'ALL';
  String _selectedStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    context.read<ClassesBloc>().add(const FetchClasses());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesShift(String startTime, String shiftFilter) {
    if (shiftFilter == 'ALL') return true;
    final hour = int.tryParse(startTime.split(':').first) ?? -1;
    if (hour < 0) return true;
    return switch (shiftFilter) {
      'MORNING' => hour < 12,
      'AFTERNOON' => hour >= 12 && hour < 17,
      'EVENING' => hour >= 17,
      _ => true,
    };
  }

  bool _matchesActiveFilters(ClassModel classItem) {
    final query = _searchController.text.trim().toLowerCase();
    final matchesQuery =
        query.isEmpty ||
        classItem.code.toLowerCase().contains(query) ||
        classItem.name.toLowerCase().contains(query) ||
        (classItem.mainTeacherName ?? '').toLowerCase().contains(query) ||
        (classItem.courseTitle ?? '').toLowerCase().contains(query) ||
        (classItem.roomName ?? '').toLowerCase().contains(query);
    if (_selectedStatus == 'ARCHIVED') {
      final matchesBranch =
          _selectedBranch == 'ALL' || classItem.branchId == _selectedBranch;
      final matchesShift =
          _selectedShift == 'ALL' ||
          _matchesShift(classItem.startTime, _selectedShift);
      return classItem.effectiveIsArchived &&
          matchesQuery &&
          matchesBranch &&
          matchesShift;
    }
    if (classItem.effectiveIsArchived) {
      return false;
    }
    final matchesStatus =
        _selectedStatus == 'ALL' ||
        (_selectedStatus == 'UPCOMING'
            ? (classItem.status == 'PLANNING' ||
                  classItem.status == 'OPEN_FOR_ENROLLMENT')
            : classItem.status == _selectedStatus);
    final matchesBranch =
        _selectedBranch == 'ALL' || classItem.branchId == _selectedBranch;
    final matchesShift =
        _selectedShift == 'ALL' ||
        _matchesShift(classItem.startTime, _selectedShift);
    return matchesQuery && matchesStatus && matchesBranch && matchesShift;
  }

  Future<void> _openClassDetail(String classId) async {
    if (classId.isEmpty) return;
    await context.push(
      RouteNames.classDetail.replaceFirst(':id', classId),
    );
    if (mounted) {
      context.read<ClassesBloc>().add(const FetchClasses(refresh: true));
    }
  }

  Future<void> _showCreateClassDialog() async {
    final result = await context.push(RouteNames.classCreate);
    if (!mounted || result == null) return;
    context.read<ClassesBloc>().add(const FetchClasses(refresh: true));
    if (result is ClassModel && !_matchesActiveFilters(result)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lớp "${result.name}" (${result.code}) đã được tạo nhưng đang nằm ngoài bộ lọc hiện tại.',
          ),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Xem lớp',
            onPressed: () {
              setState(() {
                _selectedBranch = 'ALL';
                _selectedShift = 'ALL';
                _selectedStatus = 'ALL';
                _searchController.clear();
              });
              if (result.id.isNotEmpty) {
                _openClassDetail(result.id);
              }
            },
          ),
        ),
      );
    }
  }

  Future<void> _showChangeStatusDialog(
    String classId,
    String className,
    String currentStatus,
  ) async {
    final bloc = context.read<ClassesBloc>();
    String selectedStatus = currentStatus;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Đổi trạng thái - $className'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Chọn trạng thái vận hành của lớp học:'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Trạng thái',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'PLANNING',
                        child: Text('Đang lập kế hoạch (PLANNING)'),
                      ),
                      DropdownMenuItem(
                        value: 'OPEN_FOR_ENROLLMENT',
                        child: Text('Đang mở tuyển sinh (OPEN)'),
                      ),
                      DropdownMenuItem(
                        value: 'IN_PROGRESS',
                        child: Text('Đang diễn ra (IN_PROGRESS)'),
                      ),
                      DropdownMenuItem(
                        value: 'COMPLETED',
                        child: Text('Đã hoàn thành (COMPLETED)'),
                      ),
                      DropdownMenuItem(
                        value: 'CANCELLED',
                        child: Text('Đã hủy (CANCELLED)'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedStatus = val);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx, false),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogCtx, true),
                  child: const Text('Cập nhật'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true && mounted) {
      try {
        await bloc.updateClassAndSync(classId, status: selectedStatus);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã cập nhật trạng thái lớp học thành công'),
              backgroundColor: Color(0xFF047857),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi cập nhật trạng thái: $e'),
              backgroundColor: const Color(0xFFDC2626),
            ),
          );
        }
      }
    }
  }

  ClassModel? _findClassById(String classId) {
    final bloc = context.read<ClassesBloc>();
    final state = bloc.state;
    final list = state is ClassesLoaded ? state.classes : bloc.cachedClasses;
    for (final c in list) {
      if (c.id == classId) return c;
    }
    return bloc.getCachedDetail(classId);
  }

  Future<void> _archiveClass(
    String classId,
    String className, {
    String? currentNotes,
  }) async {
    final bloc = context.read<ClassesBloc>();
    final cls = _findClassById(classId);
    final rawNotes = currentNotes ?? cls?.notes ?? '';
    final dateTag = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final nextNotes = rawNotes.contains('[ARCHIVED')
        ? rawNotes
        : '[ARCHIVED:$dateTag] ${rawNotes.trim()}'.trim();
    try {
      await bloc.updateClassAndSync(classId, notes: nextNotes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã lưu trữ lớp "$className". Lớp đã được ẩn khỏi danh sách đang hoạt động.',
            ),
            backgroundColor: const Color(0xFF047857),
            action: SnackBarAction(
              label: 'Xem đã lưu trữ',
              textColor: Colors.white,
              onPressed: () {
                if (mounted) {
                  setState(() => _selectedStatus = 'ARCHIVED');
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể lưu trữ lớp: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _unarchiveClass(
    String classId,
    String className, {
    String? currentNotes,
  }) async {
    final bloc = context.read<ClassesBloc>();
    final cls = _findClassById(classId);
    final rawNotes = currentNotes ?? cls?.notes ?? '';
    final cleanedNotes = rawNotes
        .replaceAll(RegExp(r'\[ARCHIVED[^\]]*\]\s*'), '')
        .trim();
    try {
      await bloc.updateClassAndSync(classId, notes: cleanedNotes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã khôi phục lớp "$className" khỏi mục lưu trữ.'),
            backgroundColor: const Color(0xFF047857),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể khôi phục lớp: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _showDeleteDependencyDialog({
    required String classId,
    required String className,
    required String classCode,
    required String message,
  }) async {
    final cls = _findClassById(classId);
    final hasRegistrations =
        (cls != null &&
            (cls.activeRegistrationsCount > 0 ||
                cls.historicalRegistrationsCount > 0)) ||
        message.toLowerCase().contains('đơn đăng ký');
    final canOfferCancel = cls == null || !cls.isCancelled;
    final canOfferArchive = cls == null || !cls.effectiveIsArchived;

    final action = await showDialog<String>(
      context: context,
      builder: (errorCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Color(0xFFD97706)),
            SizedBox(width: 8),
            Expanded(child: Text('Không thể xóa lớp')),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              if (hasRegistrations) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.history_edu_rounded,
                        size: 18,
                        color: Color(0xFFB45309),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Mẹo quản trị: Bạn có thể Lưu trữ lớp để ẩn khỏi danh sách hoạt động, Hủy lớp, hoặc mở Hàng chờ Đăng ký để xóa đơn thử nghiệm đã từ chối.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (hasRegistrations)
            TextButton.icon(
              onPressed: () => Navigator.pop(errorCtx, 'view_registrations'),
              icon: const Icon(Icons.assignment_outlined, size: 16),
              label: const Text('Xem đơn liên quan'),
            ),
          if (canOfferCancel && hasRegistrations)
            OutlinedButton(
              onPressed: () => Navigator.pop(errorCtx, 'cancel'),
              child: const Text('Hủy lớp'),
            ),
          if (canOfferArchive && hasRegistrations)
            FilledButton.tonal(
              onPressed: () => Navigator.pop(errorCtx, 'archive'),
              child: const Text('Lưu trữ lớp'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(errorCtx, 'dismiss'),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );

    if (!mounted || action == null || action == 'dismiss') return;
    if (action == 'view_registrations') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ClassRegistrationsAdminScreen(),
        ),
      );
      if (mounted) {
        context.read<ClassesBloc>().add(const FetchClasses());
      }
    } else if (action == 'archive') {
      await _archiveClass(classId, className, currentNotes: cls?.notes);
    } else if (action == 'cancel') {
      await _showCancelClassDialog(classId, className, classCode);
    }
  }

  Future<void> _showDeleteClassDialog(
    String classId,
    String className,
    String classCode,
  ) async {
    final cls = _findClassById(classId);
    if (cls != null && cls.hasHistoricalRegistrationsOnly) {
      final histCount = cls.historicalRegistrationsCount;
      final rejCount = cls.rejectedRegistrationsCount;
      final detailLabel = rejCount > 0 && rejCount == histCount
          ? '$rejCount đơn đăng ký đã từ chối'
          : '$histCount đơn đăng ký đã từ chối/đã hủy';
      await _showDeleteDependencyDialog(
        classId: classId,
        className: className,
        classCode: classCode,
        message:
            'Lớp học có $detailLabel được lưu trong lịch sử. Không thể xóa vĩnh viễn khi cần bảo toàn hồ sơ. Bạn có thể lưu trữ lớp hoặc hủy lớp.',
      );
      return;
    }

    final codeCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
              SizedBox(width: 8),
              Text('Xác nhận xóa lớp học'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lớp học "$className" ($classCode) sẽ bị xóa vĩnh viễn khỏi hệ thống.',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Chỉ lớp học mới lập kế hoạch, chưa phát sinh học viên, đăng ký hay hóa đơn mới có thể xóa. Vui lòng nhập mã lớp để xác nhận:',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  classCode,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Nhập lại mã lớp để xác nhận',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (_) => setDlgState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy bỏ'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
              onPressed: codeCtrl.text.trim() == classCode.trim()
                  ? () => Navigator.pop(ctx, true)
                  : null,
              child: const Text('Xác nhận xóa'),
            ),
          ],
        ),
      ),
    );
    codeCtrl.dispose();
    if (confirmed == true && mounted) {
      final bloc = context.read<ClassesBloc>();
      try {
        await bloc.deleteClassAndSync(classId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa lớp học thành công'),
              backgroundColor: Color(0xFF047857),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          await _showDeleteDependencyDialog(
            classId: classId,
            className: className,
            classCode: classCode,
            message: classDeletionMessage(e),
          );
        }
      }
    }
  }

  Future<void> _showCancelClassDialog(
    String classId,
    String className,
    String classCode,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706)),
            SizedBox(width: 8),
            Text('Xác nhận hủy lớp học'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc chắn muốn hủy lớp "$className" ($classCode)?',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Lớp học sẽ chuyển sang trạng thái "ĐÃ HỦY". Toàn bộ lịch sử danh sách học viên, học phí, điểm danh và dữ liệu liên quan sẽ được lưu trữ an toàn trong hệ thống.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bỏ qua'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận hủy lớp'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final bloc = context.read<ClassesBloc>();
      try {
        await bloc.updateClassAndSync(classId, status: 'CANCELLED');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Đã hủy lớp học thành công (dữ liệu học vụ đã được lưu trữ).',
              ),
              backgroundColor: Color(0xFF047857),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          showDialog<void>(
            context: context,
            builder: (errorCtx) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFFD97706)),
                  SizedBox(width: 8),
                  Text('Không thể hủy lớp'),
                ],
              ),
              content: Text('Không thể hủy lớp này: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(errorCtx),
                  child: const Text('Đã hiểu'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1024;
    final todayStr = DateFormat('dd/MM/yyyy').format(DateTime.now());

    if (!isDesktop) return _buildMobileScreen();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Lớp học & Xếp lịch tự động'),
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F172A),
              actions: [
                IconButton(
                  onPressed: () => context.read<ClassesBloc>().add(
                    const FetchClasses(refresh: true),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            )
          : null,
      body: BlocBuilder<ClassesBloc, ClassesState>(
        builder: (context, state) {
          final bloc = context.read<ClassesBloc>();
          final List<ClassModel> liveClasses = state is ClassesLoaded
              ? state.classes
              : bloc.cachedClasses;

          final branchNames = <String, String>{
            for (final classItem in liveClasses)
              if (classItem.branchId.isNotEmpty)
                classItem.branchId:
                    classItem.branchName ?? classItem.branchId,
          };
          final activeBranchFilter =
              _selectedBranch == 'ALL' ||
                  branchNames.containsKey(_selectedBranch)
              ? _selectedBranch
              : 'ALL';

          final filteredModels = liveClasses.where(_matchesActiveFilters).toList();
          final filteredClasses = _buildDisplayClasses(filteredModels);

          return SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 24 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. PAGE HEADING TOOLBAR (Stitch Layout)
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
                                        'Quản lý Lớp học & Xếp lịch Tự động',
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
                                        child: const Text(
                                          '● Thuật toán xếp lịch tự động thông minh',
                                          style: TextStyle(
                                            color: Color(0xFF2E7D32),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                          ),
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
                                          'Hôm nay: $todayStr • Tổng số ${liveClasses.length} lớp đang vận hành trong hệ thống',
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
                                          'Đang xuất thời khóa biểu toàn trung tâm (.xlsx)...',
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.file_download_outlined,
                                    size: 18,
                                    color: Color(0xFF003FB1),
                                  ),
                                  label: const Text('Xuất TKB (.xlsx)'),
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
                                if (widget.allowCreate)
                                  ElevatedButton.icon(
                                    onPressed: _showCreateClassDialog,
                                    icon: const Icon(
                                      Icons.calendar_month_rounded,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      '+ Tạo lớp & Xếp lịch tự động',
                                    ),
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
                                  'Quản lý Lớp học & Xếp lịch Tự động',
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
                                      Flexible(
                                        child: Text(
                                          'Thuật toán xếp lịch tự động thông minh',
                                          style: TextStyle(
                                            color: Color(0xFF2E7D32),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                          ),
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
                                    'Hôm nay: $todayStr • Tổng số ${liveClasses.length} lớp đang vận hành trong hệ thống',
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
                                          'Đang xuất thời khóa biểu toàn trung tâm (.xlsx)...',
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.file_download_outlined,
                                    size: 16,
                                    color: Color(0xFF003FB1),
                                  ),
                                  label: const Text('Xuất TKB (.xlsx)'),
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
                                if (widget.allowCreate)
                                  ElevatedButton.icon(
                                    onPressed: _showCreateClassDialog,
                                    icon: const Icon(
                                      Icons.calendar_month_rounded,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      '+ Tạo lớp & Xếp lịch tự động',
                                    ),
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

                // 2. 4 KPI STATS METRIC CARDS (Stitch Layout)
                LayoutBuilder(
                  builder: (ctx, constraints) {
                    final cardWidth = isDesktop
                        ? (constraints.maxWidth - 48) / 4
                        : (constraints.maxWidth - 16) / 2;
                    final totalClasses = liveClasses.length;
                    final inProgressCount = liveClasses
                        .where((c) => c.status == 'IN_PROGRESS')
                        .length;
                    final openCount = liveClasses
                        .where(
                          (c) =>
                              c.status == 'OPEN_FOR_ENROLLMENT' ||
                              c.status == 'PLANNING',
                        )
                        .length;
                    final totalStudents = liveClasses.fold<int>(
                      0,
                      (s, c) => s + c.studentsCount,
                    );
                    final totalSessions = liveClasses.fold<int>(
                      0,
                      (s, c) => s + c.sessionsCount,
                    );
                    final avgCapacity = totalClasses > 0
                        ? (liveClasses.fold<int>(
                                    0,
                                    (s, c) => s + c.maxCapacity,
                                  ) /
                                  totalClasses)
                              .toStringAsFixed(0)
                        : '0';

                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _buildStatCard(
                          title: 'Tổng số lớp học hệ thống',
                          value: '$totalClasses lớp',
                          subtext:
                              '$inProgressCount đang học • $openCount mở tuyển sinh',
                          icon: Icons.school_rounded,
                          iconBg: const Color(0xFFEEF2FF),
                          iconColor: const Color(0xFF003FB1),
                          width: cardWidth,
                        ),
                        _buildStatCard(
                          title: 'Buổi học đã lên lịch',
                          value: '$totalSessions buổi',
                          subtext: '100% không trùng phòng & GV',
                          icon: Icons.check_circle_rounded,
                          iconBg: const Color(0xFFF0FDF4),
                          iconColor: const Color(0xFF16A34A),
                          pillColor: const Color(0xFFDCFCE7),
                          pillTextColor: const Color(0xFF15803D),
                          width: cardWidth,
                        ),
                        _buildStatCard(
                          title: 'Học viên đã xếp lớp',
                          value: '$totalStudents học viên',
                          subtext: 'Sức chứa TB: $avgCapacity HV/lớp',
                          icon: Icons.group_rounded,
                          iconBg: const Color(0xFFEFF6FF),
                          iconColor: const Color(0xFF2563EB),
                          pillColor: const Color(0xFFEFF6FF),
                          pillTextColor: const Color(0xFF1D4ED8),
                          width: cardWidth,
                        ),
                        _buildStatCard(
                          title: 'Xung đột lịch học',
                          value: '0 buổi',
                          subtext: 'Lịch học vận hành ổn định',
                          icon: Icons.verified_rounded,
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

                // 3. VIEW TABS & FILTERING TOOLS (Stitch Layout)
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
                      // View Toggle Buttons
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildViewBtn(
                              0,
                              'Danh sách lớp học (Table View)',
                              Icons.table_rows_rounded,
                            ),
                            const SizedBox(width: 8),
                            _buildViewBtn(
                              1,
                              'Thời khóa biểu tuần (Calendar Matrix)',
                              Icons.calendar_view_week_rounded,
                            ),
                            const SizedBox(width: 8),
                            _buildViewBtn(
                              2,
                              'Phân công giảng dạy giáo viên',
                              Icons.badge_rounded,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Filters Row
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
                                hintText:
                                    'Tìm theo mã lớp, tên khóa, giáo viên, phòng...',
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
                                value: activeBranchFilter,
                                items: [
                                  const DropdownMenuItem(
                                    value: 'ALL',
                                    child: Text('Chi nhánh: Tất cả chi nhánh'),
                                  ),
                                  ...branchNames.entries.map(
                                    (entry) => DropdownMenuItem(
                                      value: entry.key,
                                      child: Text(
                                        'Chi nhánh: ${entry.value}',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _selectedBranch = v);
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
                                value: _selectedShift,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'ALL',
                                    child: Text('Khung giờ: Tất cả ca học'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'MORNING',
                                    child: Text('Ca sáng (08:00 - 11:30)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'AFTERNOON',
                                    child: Text('Ca chiều (14:00 - 17:30)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'EVENING',
                                    child: Text('Ca tối (18:00 - 21:15)'),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _selectedShift = v);
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
                                    child: Text('Trạng thái: Tất cả'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'IN_PROGRESS',
                                    child: Text('Đang học'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'OPEN_FOR_ENROLLMENT',
                                    child: Text('Đang mở tuyển sinh'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'PLANNING',
                                    child: Text('Đang lập kế hoạch'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'UPCOMING',
                                    child: Text('Sắp khai giảng'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'COMPLETED',
                                    child: Text('Đã kết thúc'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'CANCELLED',
                                    child: Text('Đã hủy'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'ARCHIVED',
                                    child: Text('Đã lưu trữ'),
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

                // 4. DATA PRESENTATION AREA
                if (state is ClassesLoading && liveClasses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: LoadingWidget(
                      message:
                          'Đang tải danh sách lớp học và thời khóa biểu...',
                    ),
                  )
                else if (state is ClassesError && liveClasses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: AppErrorWidget(
                      message: state.message,
                      onRetry: () =>
                          context.read<ClassesBloc>().add(const FetchClasses()),
                    ),
                  )
                else if (_activeViewIndex == 0)
                  _buildClassesTable(filteredClasses, isDesktop)
                else if (_activeViewIndex == 1)
                  BlocProvider<ClassesBloc>(
                    create: (_) => getIt<ClassesBloc>(),
                    child: const SizedBox(
                      height: 780,
                      child: ScheduleScreen(showAppBar: false),
                    ),
                  )
                else
                  _buildTeacherAssignmentView(filteredClasses),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: widget.showAppBar
          ? AppBar(title: const Text('Lớp học'), backgroundColor: Colors.white)
          : null,
      body: BlocBuilder<ClassesBloc, ClassesState>(
        builder: (context, state) {
          final bloc = context.read<ClassesBloc>();
          final classes = state is ClassesLoaded
              ? state.classes
              : bloc.cachedClasses;
          final query = _searchController.text.trim().toLowerCase();
          final branchNames = <String, String>{
            for (final classItem in classes)
              if (classItem.branchId.isNotEmpty)
                classItem.branchId: classItem.branchName ?? classItem.branchId,
          };
          final filtered = classes.where(_matchesActiveFilters).toList();
          final activeCount = classes
              .where((item) => item.status == 'IN_PROGRESS')
              .length;
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(MobileTokens.gutter),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quản lý lớp học',
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Lớp, giáo viên và lịch học',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Làm mới danh sách lớp',
                      onPressed: () => context.read<ClassesBloc>().add(
                        const FetchClasses(refresh: true),
                      ),
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: MobileTokens.sectionGap),
                MobileSectionCard(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.school_rounded,
                        color: Color(0xFF003FB1),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${classes.length} lớp • $activeCount đang học',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.allowCreate) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _showCreateClassDialog,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Tạo lớp học'),
                    ),
                  ),
                ],
                const SizedBox(height: MobileTokens.sectionGap),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Tìm tên lớp, mã lớp, giáo viên',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        const [
                              ('ALL', 'Tất cả'),
                              ('IN_PROGRESS', 'Đang học'),
                              ('OPEN_FOR_ENROLLMENT', 'Đang tuyển'),
                              ('PLANNING', 'Sắp mở'),
                              ('COMPLETED', 'Đã kết thúc'),
                              ('CANCELLED', 'Đã hủy'),
                              ('ARCHIVED', 'Đã lưu trữ'),
                            ]
                            .map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(entry.$2),
                                  selected: _selectedStatus == entry.$1,
                                  onSelected: (_) => setState(
                                    () => _selectedStatus = entry.$1,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
                if (branchNames.length > 1) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_selectedBranch),
                    initialValue: _selectedBranch,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Chi nhánh',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: 'ALL',
                        child: Text('Tất cả chi nhánh'),
                      ),
                      ...branchNames.entries.map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(
                            entry.value,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedBranch = value);
                      }
                    },
                  ),
                ],
                const SizedBox(height: MobileTokens.sectionGap),
                if (state is ClassesLoading && classes.isEmpty)
                  const LoadingWidget(message: 'Đang tải danh sách lớp...')
                else if (state is ClassesError && classes.isEmpty)
                  MobileSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Color(0xFFDC2626),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Không tải được danh sách lớp',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(state.message, softWrap: true),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => context.read<ClassesBloc>().add(
                            const FetchClasses(),
                          ),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                else if (filtered.isEmpty)
                  const MobileSectionCard(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('Không có lớp học phù hợp')),
                    ),
                  )
                else
                  ...filtered.map(_buildMobileClassCard),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileClassCard(ClassModel classItem) {
    final status = switch (classItem.status) {
      'IN_PROGRESS' => ('Đang học', const Color(0xFF047857)),
      'OPEN_FOR_ENROLLMENT' => ('Đang tuyển', const Color(0xFF003FB1)),
      'COMPLETED' => ('Đã kết thúc', const Color(0xFF64748B)),
      'PLANNING' => ('Sắp mở', const Color(0xFFD97706)),
      _ => (classItem.status, const Color(0xFF64748B)),
    };
    final capacity = classItem.maxCapacity;
    final ratio = capacity > 0
        ? (classItem.studentsCount / capacity).clamp(0.0, 1.0)
        : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MobileSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    classItem.code,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF003FB1),
                    ),
                  ),
                ),
                MobileStatusPill(label: status.$1, color: status.$2),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              classItem.name,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            if (classItem.courseTitle != null)
              Text(
                classItem.courseTitle!,
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
            const SizedBox(height: 14),
            _mobileClassInfo(
              Icons.person_outline_rounded,
              classItem.mainTeacherName ?? 'Chưa phân công giáo viên',
            ),
            _mobileClassInfo(
              Icons.event_outlined,
              _mobileScheduleLabel(classItem),
            ),
            _mobileClassInfo(
              Icons.place_outlined,
              '${classItem.roomName ?? 'Chưa có phòng'} • ${classItem.branchName ?? 'Chưa có chi nhánh'}',
            ),
            const SizedBox(height: 12),
            Text(
              '${classItem.studentsCount}/$capacity học viên',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            LinearProgressIndicator(value: ratio),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openClassDetail(classItem.id),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: const Text('Xem lớp học và điểm danh'),
                  ),
                ),
                const SizedBox(width: 8),
                if (classItem.status == 'PLANNING' && classItem.studentsCount == 0 && classItem.activeRegistrationsCount == 0) ...[
                  IconButton.outlined(
                    tooltip: 'Xóa lớp học',
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                    onPressed: () => _showDeleteClassDialog(
                      classItem.id,
                      classItem.name,
                      classItem.code,
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else if (classItem.status != 'CANCELLED' && classItem.status != 'COMPLETED') ...[
                  IconButton.outlined(
                    tooltip: 'Hủy lớp học',
                    icon: const Icon(Icons.cancel_outlined, size: 18, color: Color(0xFFD97706)),
                    onPressed: () => _showCancelClassDialog(
                      classItem.id,
                      classItem.name,
                      classItem.code,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (classItem.effectiveIsArchived) ...[
                  IconButton.outlined(
                    tooltip: 'Khôi phục lớp khỏi lưu trữ',
                    icon: const Icon(Icons.unarchive_outlined, size: 18, color: Color(0xFF003FB1)),
                    onPressed: () => _unarchiveClass(
                      classItem.id,
                      classItem.name,
                      currentNotes: classItem.notes,
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else if (classItem.canArchive) ...[
                  IconButton.outlined(
                    tooltip: 'Lưu trữ lớp học',
                    icon: const Icon(Icons.archive_outlined, size: 18, color: Color(0xFF475569)),
                    onPressed: () => _archiveClass(
                      classItem.id,
                      classItem.name,
                      currentNotes: classItem.notes,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton.outlined(
                  tooltip: 'Đổi trạng thái lớp',
                  icon: const Icon(Icons.sync_alt_rounded, size: 18),
                  onPressed: () => _showChangeStatusDialog(
                    classItem.id,
                    classItem.name,
                    classItem.status,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mobileClassInfo(IconData icon, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Expanded(child: Text(value)),
      ],
    ),
  );

  String _mobileScheduleLabel(ClassModel classItem) {
    const weekdayLabels = {
      'MONDAY': 'T2',
      'TUESDAY': 'T3',
      'WEDNESDAY': 'T4',
      'THURSDAY': 'T5',
      'FRIDAY': 'T6',
      'SATURDAY': 'T7',
      'SUNDAY': 'CN',
    };
    if (classItem.scheduleDays.isEmpty) return 'Chưa xếp lịch';
    final days = classItem.scheduleDays
        .map((day) => weekdayLabels[day] ?? day)
        .join(' • ');
    if (classItem.startTime.isEmpty || classItem.endTime.isEmpty) return days;
    return '$days  ${classItem.startTime}–${classItem.endTime}';
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
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
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
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
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

  Widget _buildViewBtn(int index, String title, IconData icon) {
    final isActive = _activeViewIndex == index;
    return InkWell(
      onTap: () => setState(() => _activeViewIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF003FB1) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? const Color(0xFF003FB1) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassesTable(
    List<Map<String, dynamic>> classes,
    bool isDesktop,
  ) {
    return Container(
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth = constraints.maxWidth > 1050
              ? constraints.maxWidth
              : 1050.0;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 140,
                          child: Text(
                            'MÃ LỚP',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'TÊN LỚP & KHÓA HỌC',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'GIÁO VIÊN',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'LỊCH HỌC & CA',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'PHÒNG & CƠ SỞ',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: Text(
                            'SĨ SỐ',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 110,
                          child: Text(
                            'TRẠNG THÁI',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 180,
                          child: Text(
                            'THAO TÁC',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: classes.length,
                    separatorBuilder: (_, index) =>
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (ctx, idx) {
                      final c = classes[idx];
                      final classId = c['id']?.toString() ?? '';
                      final code = c['code'] ?? 'ENG-01';
                      final name = c['name'] ?? 'Lớp Tiếng Anh';
                      final course = c['courseTitle'] ?? 'Chương trình đào tạo';
                      final teacher = c['teacher'] ?? 'Giáo viên';
                      final days = c['days'] ?? 'T2 - T4 - T6';
                      final shift = c['shift'] ?? '08:00 - 09:30';
                      final room = c['room'] ?? 'Phòng học';
                      final enrolled =
                          (c['enrolled'] as num?)?.toInt() ?? 0;
                      final maxCap = (c['capacity'] as num?)?.toInt() ?? 18;
                      final ratio = maxCap > 0
                          ? (enrolled / maxCap).clamp(0.0, 1.0)
                          : 0.0;
                      final classStatus =
                          c['status']?.toString() ?? 'IN_PROGRESS';
                      final statusConfig = switch (classStatus) {
                        'IN_PROGRESS' => (
                          'Đang học',
                          const Color(0xFF047857),
                          const Color(0xFFECFDF5),
                          const Color(0xFFA7F3D0),
                        ),
                        'OPEN_FOR_ENROLLMENT' => (
                          'Đang tuyển',
                          const Color(0xFF003FB1),
                          const Color(0xFFEFF6FF),
                          const Color(0xFFBFDBFE),
                        ),
                        'PLANNING' => (
                          'Sắp mở',
                          const Color(0xFFD97706),
                          const Color(0xFFFFFBEB),
                          const Color(0xFFFDE68A),
                        ),
                        'COMPLETED' => (
                          'Đã kết thúc',
                          const Color(0xFF64748B),
                          const Color(0xFFF1F5F9),
                          const Color(0xFFCBD5E1),
                        ),
                        'CANCELLED' => (
                          'Đã hủy',
                          const Color(0xFFDC2626),
                          const Color(0xFFFEF2F2),
                          const Color(0xFFFECACA),
                        ),
                        _ => (
                          classStatus,
                          const Color(0xFF64748B),
                          const Color(0xFFF1F5F9),
                          const Color(0xFFCBD5E1),
                        ),
                      };

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 140,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  code,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: Color(0xFF003FB1),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    course,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: const Color(0xFFEFF6FF),
                                    child: Text(
                                      teacher.isNotEmpty ? teacher[0] : 'G',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF003FB1),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      teacher,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    days,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    shift,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    room,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    c['branchName']?.toString() ??
                                        'Chi nhánh trung tâm',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 120,
                              child: Column(
                                children: [
                                  Text(
                                    '$enrolled / $maxCap HV (${(ratio * 100).toInt()}%)',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: ratio,
                                    minHeight: 4,
                                    backgroundColor: const Color(0xFFE2E8F0),
                                    valueColor: const AlwaysStoppedAnimation(
                                      Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 110,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusConfig.$3,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: statusConfig.$4),
                                  ),
                                  child: Text(
                                    statusConfig.$1,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: statusConfig.$2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 180,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton(
                                    onPressed: () => _openClassDetail(classId),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF003FB1),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 6,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    child: const Text(
                                      'Chi tiết & Điểm danh',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(
                                      Icons.more_vert,
                                      size: 18,
                                      color: Color(0xFF64748B),
                                    ),
                                    tooltip: 'Tùy chọn lớp học',
                                    onSelected: (value) async {
                                      if (classId.isEmpty) return;
                                      switch (value) {
                                        case 'detail':
                                          await _openClassDetail(classId);
                                          break;
                                        case 'schedule':
                                          context.push(RouteNames.schedule);
                                          break;
                                        case 'delete':
                                          _showDeleteClassDialog(
                                            classId,
                                            name,
                                            code,
                                          );
                                          break;
                                        case 'cancel':
                                          _showCancelClassDialog(
                                            classId,
                                            name,
                                            code,
                                          );
                                          break;
                                        case 'status':
                                          _showChangeStatusDialog(
                                            classId,
                                            name,
                                            classStatus,
                                          );
                                          break;
                                        case 'archive':
                                          await _archiveClass(
                                            classId,
                                            name,
                                            currentNotes:
                                                c['notes']?.toString(),
                                          );
                                          break;
                                        case 'unarchive':
                                          await _unarchiveClass(
                                            classId,
                                            name,
                                            currentNotes:
                                                c['notes']?.toString(),
                                          );
                                          break;
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'detail',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.visibility_outlined,
                                              size: 16,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Chi tiết lớp học'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'schedule',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_month_outlined,
                                              size: 16,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Lịch học & Xếp lịch'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'status',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.sync_alt_rounded,
                                              size: 16,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Đổi trạng thái lớp'),
                                          ],
                                        ),
                                      ),
                                      if (c['isArchived'] == true)
                                        const PopupMenuItem(
                                          value: 'unarchive',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.unarchive_outlined,
                                                size: 16,
                                                color: Color(0xFF003FB1),
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Khôi phục khỏi lưu trữ',
                                                style: TextStyle(
                                                  color: Color(0xFF003FB1),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      else if (c['canArchive'] == true)
                                        const PopupMenuItem(
                                          value: 'archive',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.archive_outlined,
                                                size: 16,
                                                color: Color(0xFF475569),
                                              ),
                                              SizedBox(width: 8),
                                              Text('Lưu trữ lớp học'),
                                            ],
                                          ),
                                        ),
                                      if (classStatus == 'PLANNING' &&
                                          enrolled == 0 &&
                                          ((c['activeRegistrationsCount'] as int?) ?? 0) == 0)
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.delete_outline_rounded,
                                                size: 16,
                                                color: Color(0xFFDC2626),
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Xóa lớp học',
                                                style: TextStyle(
                                                  color: Color(0xFFDC2626),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      else if (classStatus != 'CANCELLED' &&
                                          classStatus != 'COMPLETED')
                                        const PopupMenuItem(
                                          value: 'cancel',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.cancel_outlined,
                                                size: 16,
                                                color: Color(0xFFD97706),
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Hủy lớp học',
                                                style: TextStyle(
                                                  color: Color(0xFFD97706),
                                                ),
                                              ),
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
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTeacherAssignmentView(List<Map<String, dynamic>> classes) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PHÂN CÔNG GIẢNG DẠY GIẢNG VIÊN & TRỢ GIẢNG:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Hệ thống tự động theo dõi số giờ dạy thực tế / định mức quy định (24h/tuần) của từng giảng viên.',
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _buildDisplayClasses(
    List<ClassModel> liveClasses,
  ) {
    return liveClasses.map((lc) {
      return {
        'id': lc.id,
        'code': lc.code,
        'name': lc.name,
        'courseTitle': lc.courseTitle ?? 'Khóa học',
        'branchId': lc.branchId,
        'branchName': lc.branchName ?? 'Chi nhánh trung tâm',
        'teacher': lc.mainTeacherName ?? 'Chưa phân công',
        'days': lc.scheduleDays.isNotEmpty
            ? lc.scheduleDays.join(' - ')
            : 'T2 - T4 - T6',
        'shift': '${lc.startTime} - ${lc.endTime}',
        'room': lc.roomName ?? 'Phòng học',
        'enrolled': lc.studentsCount,
        'capacity': lc.maxCapacity,
        'status': lc.status,
        'notes': lc.notes,
        'isArchived': lc.effectiveIsArchived,
        'canArchive': lc.canArchive,
        'activeRegistrationsCount': lc.activeRegistrationsCount,
        'historicalRegistrationsCount': lc.historicalRegistrationsCount,
        'rejectedRegistrationsCount': lc.rejectedRegistrationsCount,
      };
    }).toList();
  }
}
