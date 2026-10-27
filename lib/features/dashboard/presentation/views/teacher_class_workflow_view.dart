import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/adaptive/adaptive_layout.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mobile/mobile_ui.dart';
import '../../../assignments/data/models/assignment_model.dart';
import '../../../assignments/domain/repositories/assignments_repository.dart';
import '../../../classes/data/models/class_model.dart';
import '../../../classes/domain/repositories/classes_repository.dart';

enum TeacherWorkflowMode { attendance, assignments, results }

/// The teacher workspace uses the same class, session, and assignment APIs as
/// the dedicated detail screens. It never invents attendance or grades locally.
class TeacherClassWorkflowView extends StatefulWidget {
  final TeacherWorkflowMode mode;

  const TeacherClassWorkflowView({super.key, required this.mode});

  @override
  State<TeacherClassWorkflowView> createState() =>
      _TeacherClassWorkflowViewState();
}

class _TeacherClassWorkflowViewState extends State<TeacherClassWorkflowView> {
  List<ClassModel> _classes = const [];
  List<ClassSessionModel> _sessions = const [];
  List<AssignmentModel> _assignments = const [];
  List<({AssignmentModel assignment, StudentSubmissionItemModel student})>
  _gradedResults = const [];
  String? _classId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final classes = await getIt<ClassesRepository>().getMyClasses();
      if (!mounted) return;
      final selected = classes.any((item) => item.id == _classId)
          ? _classId
          : classes.isEmpty
          ? null
          : classes.first.id;
      setState(() {
        _classes = classes;
        _classId = selected;
      });
      await _loadItems();
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadItems() async {
    final classId = _classId;
    if (classId == null) {
      setState(() {
        _sessions = const [];
        _assignments = const [];
        _gradedResults = const [];
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.mode == TeacherWorkflowMode.attendance) {
        final sessions = await getIt<ClassesRepository>().getClassSessions(
          classId,
        );
        final now = DateTime.now();
        sessions.sort((a, b) {
          final aDistance = a.date?.difference(now).inDays.abs() ?? 9999;
          final bDistance = b.date?.difference(now).inDays.abs() ?? 9999;
          return aDistance.compareTo(bDistance);
        });
        if (mounted && classId == _classId) {
          setState(() {
            _sessions = sessions;
            _loading = false;
          });
        }
      } else {
        final assignments = await getIt<AssignmentsRepository>()
            .getClassAssignments(classId);
        final gradedResults =
            <
              ({AssignmentModel assignment, StudentSubmissionItemModel student})
            >[];
        if (widget.mode == TeacherWorkflowMode.results) {
          final repository = getIt<AssignmentsRepository>();
          final submissions = await Future.wait(
            assignments
                .where((assignment) => assignment.gradedCount > 0)
                .map(
                  (assignment) =>
                      repository.getAssignmentSubmissions(assignment.id),
                ),
          );
          for (final result in submissions) {
            final assignment = assignments.firstWhere(
              (item) => item.id == result.assignmentId,
            );
            for (final student in result.students) {
              if (student.submission?.score != null) {
                gradedResults.add((assignment: assignment, student: student));
              }
            }
          }
        }
        if (mounted && classId == _classId) {
          setState(() {
            _assignments = assignments;
            _gradedResults = gradedResults;
            _loading = false;
          });
        }
      }
    } catch (error) {
      if (mounted && classId == _classId) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _open(String path, {Object? extra}) async {
    await context.push(path, extra: extra);
    if (mounted) await _loadItems();
  }

  String get _title => switch (widget.mode) {
    TeacherWorkflowMode.attendance => 'Điểm danh theo buổi học',
    TeacherWorkflowMode.assignments => 'Bài tập và chấm bài',
    TeacherWorkflowMode.results => 'Kết quả bài tập',
  };

  @override
  Widget build(BuildContext context) {
    if (AdaptiveBreakpoints.fromWidth(MediaQuery.sizeOf(context).width) ==
        AdaptiveSize.mobile) {
      return _buildMobile();
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _classId,
                      decoration: const InputDecoration(
                        labelText: 'Lớp học',
                        border: OutlineInputBorder(),
                      ),
                      items: _classes
                          .map(
                            (item) => DropdownMenuItem(
                              value: item.id,
                              child: Text(
                                item.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _classId = value);
                        _loadItems();
                      },
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tải lại',
                    onPressed: _loadClasses,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              if (_classId != null &&
                  widget.mode == TeacherWorkflowMode.assignments) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () => _open(
                      RouteNames.createAssignment.replaceFirst(
                        ':classId',
                        _classId!,
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Giao bài tập'),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Expanded(child: _buildList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobile() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Column(
      key: const ValueKey('teacher-workflow-mobile'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _classId,
          decoration: const InputDecoration(labelText: 'Lớp học'),
          items: _classes
              .map(
                (item) => DropdownMenuItem(
                  value: item.id,
                  child: Text(item.name, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() => _classId = value);
            _loadItems();
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            if (_classId != null &&
                widget.mode == TeacherWorkflowMode.assignments)
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _open(
                    RouteNames.createAssignment.replaceFirst(
                      ':classId',
                      _classId!,
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Giao bài tập'),
                ),
              ),
            IconButton(
              tooltip: 'Tải lại',
              onPressed: _loadClasses,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(child: _buildMobileList()),
      ],
    ),
  );

  Widget _buildMobileList() {
    if (_loading || _error != null || _classes.isEmpty) return _buildList();
    if (widget.mode == TeacherWorkflowMode.attendance) {
      if (_sessions.isEmpty) return _buildList();
      return ListView.separated(
        itemCount: _sessions.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final session = _sessions[index];
          return MobileSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  '${session.date?.day ?? ''}/${session.date?.month ?? ''} · ${session.startTime}–${session.endTime}',
                  style: const TextStyle(color: AppColors.neutral600),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: session.status == 'CANCELLED'
                        ? null
                        : () => _open(
                            RouteNames.attendanceMark.replaceFirst(
                              ':id',
                              session.id,
                            ),
                          ),
                    icon: const Icon(Icons.fact_check_outlined),
                    label: const Text('Điểm danh'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
    if (widget.mode == TeacherWorkflowMode.results) {
      if (_gradedResults.isEmpty) return _buildList();
      return ListView.separated(
        itemCount: _gradedResults.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final result = _gradedResults[index];
          final submission = result.student.submission!;
          return MobileSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.student.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(result.assignment.title),
                const SizedBox(height: 8),
                MobileStatusPill(
                  label:
                      '${submission.score!.toStringAsFixed(1)}/${result.assignment.maxScore.toStringAsFixed(0)}',
                  color: AppColors.primary,
                ),
                if (submission.feedback?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(submission.feedback!),
                ],
              ],
            ),
          );
        },
      );
    }
    if (_assignments.isEmpty) return _buildList();
    return ListView.separated(
      itemCount: _assignments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final assignment = _assignments[index];
        return MobileSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                assignment.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                '${assignment.gradedCount}/${assignment.totalSubmissions} bài đã chấm · Thang ${assignment.maxScore.toStringAsFixed(0)} điểm',
                style: const TextStyle(color: AppColors.neutral600),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _open(
                    '${RouteNames.assignmentDetail.replaceFirst(':id', assignment.id)}?teacher=true',
                    extra: true,
                  ),
                  icon: const Icon(Icons.chevron_right_rounded),
                  label: const Text('Xem bài tập'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Không tải được dữ liệu: $_error',
              textAlign: TextAlign.center,
            ),
            TextButton(onPressed: _loadItems, child: const Text('Thử lại')),
          ],
        ),
      );
    }
    if (_classes.isEmpty) {
      return const Center(child: Text('Bạn chưa được phân công lớp học.'));
    }
    if (widget.mode == TeacherWorkflowMode.attendance) {
      if (_sessions.isEmpty) {
        return const Center(child: Text('Lớp này chưa có buổi học.'));
      }
      return ListView.separated(
        itemCount: _sessions.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final session = _sessions[index];
          final date = session.date;
          final dateLabel = date == null
              ? 'Chưa xếp ngày'
              : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
          return Card(
            child: ListTile(
              title: Text(session.title),
              subtitle: Text(
                '$dateLabel · ${session.startTime}–${session.endTime} · ${session.status}',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: session.status == 'CANCELLED'
                  ? null
                  : () => _open(
                      RouteNames.attendanceMark.replaceFirst(':id', session.id),
                    ),
            ),
          );
        },
      );
    }
    if (widget.mode == TeacherWorkflowMode.results) {
      if (_gradedResults.isEmpty) {
        return const Center(child: Text('Lớp này chưa có bài tập được chấm.'));
      }
      return ListView.separated(
        itemCount: _gradedResults.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final result = _gradedResults[index];
          final submission = result.student.submission!;
          return Card(
            child: ListTile(
              title: Text(result.student.fullName),
              subtitle: Text(
                '${result.assignment.title} · ${result.student.userCode}${submission.feedback == null || submission.feedback!.isEmpty ? '' : '\n${submission.feedback}'}',
              ),
              isThreeLine:
                  submission.feedback != null &&
                  submission.feedback!.isNotEmpty,
              trailing: Text(
                '${submission.score!.toStringAsFixed(1)}/${result.assignment.maxScore.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          );
        },
      );
    }
    if (_assignments.isEmpty) {
      return const Center(child: Text('Lớp này chưa có bài tập.'));
    }
    return ListView.separated(
      itemCount: _assignments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final assignment = _assignments[index];
        return Card(
          child: ListTile(
            title: Text(assignment.title),
            subtitle: Text(
              '${assignment.gradedCount}/${assignment.totalSubmissions} bài đã chấm · Thang ${assignment.maxScore.toStringAsFixed(0)} điểm',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _open(
              '${RouteNames.assignmentDetail.replaceFirst(':id', assignment.id)}?teacher=true',
              extra: true,
            ),
          ),
        );
      },
    );
  }
}
