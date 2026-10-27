import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
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
    return BlocBuilder<ClassesBloc, ClassesState>(
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
                      _stat('Tổng bài', all.length, Icons.assignment_outlined),
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
