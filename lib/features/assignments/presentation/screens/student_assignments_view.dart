import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/adaptive/adaptive_layout.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mobile/mobile_ui.dart';
import '../../../classes/data/models/class_model.dart';
import '../../../classes/presentation/bloc/classes_bloc.dart';
import '../../../classes/presentation/bloc/classes_state.dart';
import '../../data/models/assignment_model.dart';
import '../../domain/repositories/assignments_repository.dart';

class StudentAssignmentsView extends StatefulWidget {
  const StudentAssignmentsView({super.key});

  @override
  State<StudentAssignmentsView> createState() => _StudentAssignmentsViewState();
}

class _StudentAssignmentsViewState extends State<StudentAssignmentsView> {
  Future<List<AssignmentModel>>? _loading;
  String _classSignature = '';
  String _filter = 'Tất cả';
  String _sort = 'Hạn nộp';
  String _query = '';
  String? _classId;

  void _load(List<ClassModel> classes) {
    final signature = classes.map((c) => c.id).join('|');
    if (_loading != null && signature == _classSignature) return;
    _classSignature = signature;
    _loading =
        Future.wait(
          classes.map((c) async {
            final items = await getIt<AssignmentsRepository>()
                .getClassAssignments(c.id);
            return items.map((a) => (assignment: a, classItem: c)).toList();
          }),
        ).then(
          (groups) => groups.expand((group) => group).map((row) {
            final a = row.assignment;
            return AssignmentModel(
              id: a.id,
              classId: a.classId,
              className: row.classItem.name,
              courseName: row.classItem.courseTitle,
              classCode: row.classItem.code,
              title: a.title,
              description: a.description,
              type: a.type,
              status: a.status,
              deadline: a.deadline,
              maxScore: a.maxScore,
              attachments: a.attachments,
              createdByName: a.createdByName ?? row.classItem.mainTeacherName,
              createdAt: a.createdAt,
              mySubmission: a.mySubmission,
            );
          }).toList(),
        );
  }

  void _refresh() => setState(() => _loading = null);

  String _status(AssignmentModel item) {
    final submission = item.mySubmission;
    if (submission?.status == 'DRAFT') return 'Đang làm';
    if (submission?.status == 'RETURNED') return 'Cần làm lại';
    if (submission?.status == 'GRADED') return 'Đã chấm';
    if (submission?.status == 'GRADED_PENDING') return 'Chờ công bố';
    if (submission?.status == 'LATE') return 'Nộp muộn';
    if (submission != null) return 'Chờ chấm';
    final deadline = DateTime.tryParse(item.deadline ?? '');
    if (deadline != null && DateTime.now().isAfter(deadline.toLocal())) {
      return 'Quá hạn';
    }
    return 'Cần làm';
  }

  bool _matches(AssignmentModel item) {
    final status = _status(item);
    if (_classId != null && item.classId != _classId) return false;
    if (_query.isNotEmpty &&
        !'${item.title} ${item.className ?? ''} ${item.courseName ?? ''} ${item.type}'
            .toLowerCase()
            .contains(_query.toLowerCase())) {
      return false;
    }
    return switch (_filter) {
      'Cần làm' => status == 'Cần làm' || status == 'Cần làm lại',
      'Đang làm' => status == 'Đang làm',
      'Đã nộp' =>
        status == 'Chờ chấm' || status == 'Nộp muộn' || status == 'Chờ công bố',
      'Đã chấm' => status == 'Đã chấm',
      'Quá hạn' => status == 'Quá hạn',
      _ => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => BlocBuilder<ClassesBloc, ClassesState>(
        builder: (context, state) {
          if (state is ClassesError) return Center(child: Text(state.message));
          if (state is! MyClassesLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          _load(state.classes);
          return FutureBuilder<List<AssignmentModel>>(
            future: _loading,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Không tải được bài tập. Vui lòng kiểm tra kết nối.',
                      ),
                      TextButton(
                        onPressed: _refresh,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final all = snapshot.data!;
              final items = all.where(_matches).toList()
                ..sort((a, b) {
                  if (_sort == 'Mới nhất') {
                    final ac = DateTime.tryParse(a.createdAt) ?? DateTime(1970);
                    final bc = DateTime.tryParse(b.createdAt) ?? DateTime(1970);
                    return bc.compareTo(ac);
                  }
                  final ad =
                      DateTime.tryParse(a.deadline ?? '') ?? DateTime(9999);
                  final bd =
                      DateTime.tryParse(b.deadline ?? '') ?? DateTime(9999);
                  return ad.compareTo(bd);
                });
              final pending = all
                  .where(
                    (a) => [
                      'Cần làm',
                      'Đang làm',
                      'Cần làm lại',
                      'Quá hạn',
                    ].contains(_status(a)),
                  )
                  .length;
              final submitted = all
                  .where(
                    (a) =>
                        a.mySubmission != null &&
                        !['DRAFT', 'RETURNED'].contains(a.mySubmission!.status),
                  )
                  .length;
              final graded = all.where((a) => _status(a) == 'Đã chấm').length;
              final soon = all.where((a) {
                final deadline = DateTime.tryParse(a.deadline ?? '');
                return deadline != null &&
                    deadline.isAfter(DateTime.now()) &&
                    deadline.difference(DateTime.now()).inHours <= 48 &&
                    a.mySubmission == null;
              }).length;
              if (AdaptiveBreakpoints.fromWidth(constraints.maxWidth) ==
                  AdaptiveSize.mobile) {
                return _mobileContent(
                  state.classes,
                  all,
                  items,
                  pending,
                  submitted,
                  graded,
                  soon,
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  setState(() => _loading = null);
                  _load(state.classes);
                  try {
                    await _loading;
                  } catch (_) {
                    // FutureBuilder renders the API error and retry action.
                  }
                },
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bài tập của tôi',
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Tiếp tục bài đang làm và theo dõi kết quả học tập.',
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: _refresh,
                          tooltip: 'Làm mới',
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _stat(
                          'Tổng bài',
                          all.length,
                          Icons.assignment_outlined,
                        ),
                        _stat(
                          'Cần hoàn thành',
                          pending,
                          Icons.pending_actions_outlined,
                        ),
                        _stat('Đã nộp', submitted, Icons.task_alt_outlined),
                        _stat('Đã chấm', graded, Icons.stars_outlined),
                        _stat('Sắp đến hạn', soon, Icons.alarm_outlined),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Tiến độ: $submitted/${all.length} bài đã nộp',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: all.isEmpty ? 0 : submitted / all.length,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Tìm bài tập hoặc lớp học',
                      ),
                      onChanged: (value) => setState(() => _query = value),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final name in const [
                          'Tất cả',
                          'Cần làm',
                          'Đang làm',
                          'Đã nộp',
                          'Đã chấm',
                          'Quá hạn',
                        ])
                          ChoiceChip(
                            label: Text(name),
                            selected: _filter == name,
                            onSelected: (_) => setState(() => _filter = name),
                          ),
                      ],
                    ),
                    if (state.classes.length > 1) ...[
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: _classId,
                        decoration: const InputDecoration(labelText: 'Lớp học'),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Tất cả lớp'),
                          ),
                          for (final c in state.classes)
                            DropdownMenuItem(
                              value: c.id,
                              child: Text(
                                c.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) => setState(() => _classId = value),
                      ),
                    ],
                    Align(
                      alignment: Alignment.centerRight,
                      child: DropdownButton<String>(
                        value: _sort,
                        items: const [
                          DropdownMenuItem(
                            value: 'Hạn nộp',
                            child: Text('Sắp xếp: Hạn nộp'),
                          ),
                          DropdownMenuItem(
                            value: 'Mới nhất',
                            child: Text('Sắp xếp: Mới nhất'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _sort = value);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (items.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Chưa có bài tập phù hợp.'),
                        ),
                      ),
                    for (final item in items) _assignmentCard(item),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _reload(List<ClassModel> classes) async {
    setState(() => _loading = null);
    _load(classes);
    try {
      await _loading;
    } catch (_) {
      // The FutureBuilder presents the retry state.
    }
  }

  Widget _mobileContent(
    List<ClassModel> classes,
    List<AssignmentModel> all,
    List<AssignmentModel> items,
    int pending,
    int submitted,
    int graded,
    int soon,
  ) {
    return RefreshIndicator(
      onRefresh: () => _reload(classes),
      child: ListView(
        key: const ValueKey('student-assignments-mobile'),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_stories_rounded, color: Colors.white),
                const SizedBox(height: 12),
                const Text(
                  'Bài tập của tôi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pending == 0
                      ? 'Bạn đã hoàn thành mọi bài tập hiện có.'
                      : '$pending bài cần bạn hoàn thành',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: all.isEmpty ? 0 : submitted / all.length,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(8),
                        backgroundColor: Colors.white.withAlpha(70),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$submitted/${all.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: MobileTokens.sectionGap),
          SizedBox(
            height: 86,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _mobileStat(
                  'Cần làm',
                  pending,
                  Icons.bolt_rounded,
                  AppColors.warning,
                ),
                _mobileStat(
                  'Đã nộp',
                  submitted,
                  Icons.task_alt_rounded,
                  AppColors.secondary,
                ),
                _mobileStat(
                  'Đã chấm',
                  graded,
                  Icons.stars_rounded,
                  AppColors.primary,
                ),
                if (soon > 0)
                  _mobileStat(
                    'Sắp hạn',
                    soon,
                    Icons.alarm_rounded,
                    AppColors.error,
                  ),
              ],
            ),
          ),
          const SizedBox(height: MobileTokens.sectionGap),
          TextField(
            key: const ValueKey('student-assignments-mobile-search'),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Tìm bài tập, lớp học...',
              suffixIcon: IconButton(
                icon: const Icon(Icons.tune_rounded),
                tooltip: 'Lọc và sắp xếp',
                onPressed: () => _showMobileFilters(classes),
              ),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final name in const [
                  'Tất cả',
                  'Cần làm',
                  'Đang làm',
                  'Đã nộp',
                  'Đã chấm',
                  'Quá hạn',
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(name),
                      selected: _filter == name,
                      onSelected: (_) => setState(() => _filter = name),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: MobileTokens.sectionGap),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Danh sách bài tập',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${items.length} bài',
                style: const TextStyle(color: AppColors.neutral600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const MobileSectionCard(
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 40,
                    color: AppColors.neutral400,
                  ),
                  SizedBox(height: 8),
                  Text('Chưa có bài tập phù hợp.'),
                ],
              ),
            ),
          for (final item in items) _mobileAssignmentCard(item),
        ],
      ),
    );
  }

  Widget _mobileStat(String label, int count, IconData icon, Color color) =>
      Container(
        width: 150,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(18),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(label, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      );

  Future<void> _showMobileFilters(List<ClassModel> classes) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Lọc và sắp xếp',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _classId,
                decoration: const InputDecoration(labelText: 'Lớp học'),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Tất cả lớp'),
                  ),
                  for (final c in classes)
                    DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) => setState(() => _classId = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _sort,
                decoration: const InputDecoration(labelText: 'Sắp xếp'),
                items: const [
                  DropdownMenuItem(
                    value: 'Hạn nộp',
                    child: Text('Hạn nộp gần nhất'),
                  ),
                  DropdownMenuItem(
                    value: 'Mới nhất',
                    child: Text('Mới giao gần nhất'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _sort = value);
                },
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Xem bài tập'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mobileAssignmentCard(AssignmentModel item) {
    final status = _status(item);
    final color = switch (status) {
      'Đã chấm' => AppColors.success,
      'Chờ chấm' || 'Chờ công bố' => AppColors.secondary,
      'Quá hạn' || 'Cần làm lại' => AppColors.error,
      _ => AppColors.primary,
    };
    final icon = switch (item.type) {
      'SPEAKING' => Icons.mic_rounded,
      'WRITING' => Icons.edit_note_rounded,
      'PROJECT' => Icons.folder_rounded,
      _ => Icons.menu_book_rounded,
    };
    final deadline = DateTime.tryParse(item.deadline ?? '')?.toLocal();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MobileSectionCard(
        child: InkWell(
          key: ValueKey('mobile-assignment-${item.id}'),
          onTap: () async {
            await context.push('/assignments/${item.id}');
            if (mounted) _refresh();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.className ?? 'Lớp học',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.neutral600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  MobileStatusPill(label: status, color: color),
                  if (deadline != null)
                    MobileStatusPill(
                      label: 'Hạn ${deadline.day}/${deadline.month}',
                      color: AppColors.neutral600,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Thang ${item.maxScore.toStringAsFixed(0)} điểm',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral600,
                      ),
                    ),
                  ),
                  Text(
                    status == 'Đã chấm' ? 'Xem kết quả' : 'Xem bài tập',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, int value, IconData icon) => SizedBox(
    width: 150,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(label),
          ],
        ),
      ),
    ),
  );

  Widget _assignmentCard(AssignmentModel item) {
    final status = _status(item);
    final deadline = DateTime.tryParse(item.deadline ?? '');
    final createdAt = DateTime.tryParse(item.createdAt);
    final isNew =
        item.mySubmission == null &&
        createdAt != null &&
        DateTime.now().difference(createdAt.toLocal()).inHours < 48;
    final remaining = deadline?.toLocal().difference(DateTime.now());
    final canWork =
        status == 'Cần làm' ||
        status == 'Đang làm' ||
        status == 'Cần làm lại' ||
        status == 'Quá hạn' ||
        ((status == 'Chờ chấm' || status == 'Nộp muộn') &&
            (deadline == null || DateTime.now().isBefore(deadline.toLocal())));
    final action = switch (status) {
      'Đang làm' => 'Tiếp tục làm',
      'Cần làm lại' => 'Làm lại',
      'Đã chấm' => 'Xem kết quả',
      'Cần làm' => 'Bắt đầu làm',
      'Quá hạn' => 'Nộp muộn',
      'Chờ chấm' => canWork ? 'Sửa bài nộp' : 'Xem bài nộp',
      'Chờ công bố' => 'Xem bài đã nộp',
      _ => 'Xem bài tập',
    };
    final icon = switch (item.type) {
      'SPEAKING' => Icons.mic_outlined,
      'WRITING' => Icons.edit_note_outlined,
      'PROJECT' => Icons.folder_outlined,
      _ => Icons.assignment_outlined,
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Chip(label: Text(status)),
              ],
            ),
            const SizedBox(height: 5),
            if (isNew ||
                (remaining != null &&
                    remaining.inHours >= 0 &&
                    remaining.inHours < 48 &&
                    item.mySubmission == null))
              Wrap(
                spacing: 8,
                children: [
                  if (isNew) const Chip(label: Text('Mới giao')),
                  if (remaining != null &&
                      remaining.inHours >= 0 &&
                      remaining.inHours < 48 &&
                      item.mySubmission == null)
                    Chip(
                      label: Text(
                        'Còn ${remaining.inHours < 1 ? '${remaining.inMinutes} phút' : '${remaining.inHours} giờ'}',
                      ),
                    ),
                ],
              ),
            Text(
              '${item.courseName ?? 'Khóa học'} · ${item.className ?? ''} · ${item.createdByName ?? 'Giảng viên'}',
            ),
            if (item.description?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  item.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Hạn nộp: ${deadline == null ? 'Không giới hạn' : '${deadline.toLocal().day}/${deadline.toLocal().month}/${deadline.toLocal().year}'} · Thang ${item.maxScore.toStringAsFixed(1)} điểm',
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () async {
                  await context.push(
                    '/assignments/${item.id}${canWork ? '/submit' : ''}',
                  );
                  if (mounted) _refresh();
                },
                icon: Icon(
                  canWork ? Icons.arrow_forward : Icons.visibility_outlined,
                ),
                label: Text(action),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
