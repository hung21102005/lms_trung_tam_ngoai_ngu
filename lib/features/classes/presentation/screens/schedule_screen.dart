import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/route_names.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../data/models/class_model.dart';
import '../../domain/repositories/classes_repository.dart';
import '../bloc/classes_bloc.dart';
import '../bloc/classes_event.dart';
import '../bloc/classes_state.dart';

class ScheduleScreen extends StatefulWidget {
  final bool showAppBar;

  const ScheduleScreen({super.key, this.showAppBar = true});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  static const _weekdays = [
    'Thứ Hai',
    'Thứ Ba',
    'Thứ Tư',
    'Thứ Năm',
    'Thứ Sáu',
    'Thứ Bảy',
    'Chủ Nhật',
  ];

  late DateTime _anchor;
  int _viewMode = 0; // 0: tuần, 1: tháng, 2: danh sách trong tháng
  String? _selectedClassId;
  String? _selectedChildId;
  Map<String, String> _children = {};
  Map<String, Set<String>> _childClassIds = {};

  UserEntity? get _user {
    final state = context.read<AuthBloc?>()?.state;
    return state is AuthenticatedState ? state.user : null;
  }

  @override
  void initState() {
    super.initState();
    _anchor = _startOfWeek(DateTime.now());
    _loadSchedule();
    if (_user?.isParent == true) _loadChildren();
  }

  DateTime _startOfWeek(DateTime date) => DateTime(
    date.year,
    date.month,
    date.day,
  ).subtract(Duration(days: date.weekday - 1));

  DateTime _day(ClassSessionModel session) {
    final date = session.date!;
    return DateTime(date.year, date.month, date.day);
  }

  DateTime get _rangeStart => _viewMode == 0
      ? _startOfWeek(_anchor)
      : DateTime(_anchor.year, _anchor.month);

  DateTime get _rangeEnd => _viewMode == 0
      ? _rangeStart.add(const Duration(days: 6))
      : DateTime(_anchor.year, _anchor.month + 1, 0);

  void _loadSchedule() {
    context.read<ClassesBloc>().add(
      FetchMySchedule(fromDate: _rangeStart, toDate: _rangeEnd),
    );
  }

  Future<void> _loadChildren() async {
    try {
      final classes = await getIt<ClassesRepository>().getMyClasses();
      final children = <String, String>{};
      final classIds = <String, Set<String>>{};
      for (final item in classes) {
        for (final student in item.students) {
          children[student.studentId] =
              student.studentName ?? student.studentCode ?? 'Học viên';
          classIds
              .putIfAbsent(student.studentId, () => <String>{})
              .add(item.id);
        }
      }
      if (mounted) {
        setState(() {
          _children = children;
          _childClassIds = classIds;
        });
      }
    } catch (_) {
      // The schedule still shows all linked children's classes if this lookup fails.
    }
  }

  void _move(int amount) {
    setState(() {
      _anchor = _viewMode == 0
          ? _anchor.add(Duration(days: 7 * amount))
          : DateTime(_anchor.year, _anchor.month + amount, 1);
      _selectedClassId = null;
    });
    _loadSchedule();
  }

  void _changeView(int mode) {
    if (_viewMode == mode) return;
    setState(() {
      _viewMode = mode;
      _selectedClassId = null;
    });
    _loadSchedule();
  }

  String get _heading {
    if (_user?.isTeacher == true) return 'Lịch giảng dạy';
    if (_user?.isParent == true) return 'Lịch học của con';
    if (_user?.isStudent == true) return 'Lịch học của tôi';
    return 'Thời khóa biểu trung tâm';
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = _user?.isTeacher == true;
    return Scaffold(
      appBar: widget.showAppBar ? AppBar(title: Text(_heading)) : null,
      body: RefreshIndicator(
        onRefresh: () async {
          _loadSchedule();
          if (_user?.isParent == true) await _loadChildren();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(_heading, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            _buildToolbar(),
            const SizedBox(height: 12),
            BlocBuilder<ClassesBloc, ClassesState>(
              builder: (context, state) {
                if (state is MyScheduleLoading || state is ClassesInitial) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (state is ClassesError) {
                  return Center(
                    child: Column(
                      children: [
                        Text(state.message),
                        TextButton(
                          onPressed: _loadSchedule,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }
                if (state is! MyScheduleLoaded) return const SizedBox.shrink();

                final all =
                    state.sessions.where((session) {
                      if (session.date == null) return false;
                      final day = _day(session);
                      return !day.isBefore(_rangeStart) &&
                          !day.isAfter(_rangeEnd);
                    }).toList()..sort((a, b) {
                      final date = _day(a).compareTo(_day(b));
                      return date != 0
                          ? date
                          : a.startTime.compareTo(b.startTime);
                    });
                final classNames = <String, String>{
                  for (final session in all)
                    session.classId:
                        session.className ?? session.classCode ?? 'Lớp học',
                };
                final sessions = all.where((session) {
                  if (_selectedClassId != null &&
                      session.classId != _selectedClassId) {
                    return false;
                  }
                  if (_selectedChildId != null &&
                      !(_childClassIds[_selectedChildId]?.contains(
                            session.classId,
                          ) ??
                          false)) {
                    return false;
                  }
                  return true;
                }).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilters(classNames),
                    const SizedBox(height: 16),
                    if (sessions.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(36),
                          child: Text(
                            'Không có buổi học trong khoảng thời gian này.',
                          ),
                        ),
                      )
                    else if (_viewMode == 1)
                      _buildMonth(sessions, isTeacher)
                    else if (_viewMode == 0)
                      _buildWeek(sessions, isTeacher)
                    else
                      _buildList(sessions, isTeacher),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    final range = _viewMode == 0
        ? '${DateFormat('dd/MM/yyyy').format(_rangeStart)} – ${DateFormat('dd/MM/yyyy').format(_rangeEnd)}'
        : DateFormat('MM/yyyy').format(_rangeStart);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        IconButton(
          onPressed: () => _move(-1),
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Kỳ trước',
        ),
        Text(range, style: const TextStyle(fontWeight: FontWeight.bold)),
        IconButton(
          onPressed: () => _move(1),
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Kỳ sau',
        ),
        TextButton(
          onPressed: () {
            setState(() => _anchor = DateTime.now());
            _loadSchedule();
          },
          child: const Text('Hôm nay'),
        ),
        IconButton(
          onPressed: _loadSchedule,
          icon: const Icon(Icons.refresh),
          tooltip: 'Tải lại lịch',
        ),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Tuần')),
            ButtonSegment(value: 1, label: Text('Tháng')),
            ButtonSegment(value: 2, label: Text('Danh sách')),
          ],
          selected: {_viewMode},
          onSelectionChanged: (selection) => _changeView(selection.first),
        ),
      ],
    );
  }

  Widget _buildFilters(Map<String, String> classes) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        DropdownButton<String?>(
          value: classes.containsKey(_selectedClassId)
              ? _selectedClassId
              : null,
          hint: const Text('Tất cả lớp'),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Tất cả lớp'),
            ),
            ...classes.entries.map(
              (entry) => DropdownMenuItem<String?>(
                value: entry.key,
                child: Text(entry.value),
              ),
            ),
          ],
          onChanged: (value) => setState(() => _selectedClassId = value),
        ),
        if (_user?.isParent == true && _children.isNotEmpty)
          DropdownButton<String?>(
            value: _selectedChildId,
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Tất cả con'),
              ),
              ..._children.entries.map(
                (entry) => DropdownMenuItem<String?>(
                  value: entry.key,
                  child: Text(entry.value),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _selectedChildId = value),
          ),
      ],
    );
  }

  Widget _buildWeek(List<ClassSessionModel> sessions, bool isTeacher) {
    final days = List.generate(
      7,
      (index) => _rangeStart.add(Duration(days: index)),
    );
    if (MediaQuery.sizeOf(context).width < 760) {
      return Column(
        children: days
            .map((day) => _buildDay(day, sessions, isTeacher))
            .toList(),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 1120,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: days
              .map(
                (day) => Expanded(child: _buildDay(day, sessions, isTeacher)),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildDay(
    DateTime day,
    List<ClassSessionModel> sessions,
    bool isTeacher,
  ) {
    final daily = sessions.where((session) => _day(session) == day).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${_weekdays[day.weekday - 1]} ${DateFormat('dd/MM').format(day)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (daily.isEmpty)
              const Text('Không có lịch', style: TextStyle(color: Colors.grey)),
            ...daily.map((session) => _buildSession(session, isTeacher)),
          ],
        ),
      ),
    );
  }

  Widget _buildMonth(List<ClassSessionModel> sessions, bool isTeacher) {
    final first = DateTime(_anchor.year, _anchor.month, 1);
    final offset = first.weekday - 1;
    final count = DateTime(_anchor.year, _anchor.month + 1, 0).day;
    return Column(
      children: [
        Row(
          children: [
            for (final label in ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'])
              Expanded(child: Center(child: Text(label))),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(((offset + count) / 7).ceil(), (row) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(7, (column) {
              final number = row * 7 + column - offset + 1;
              if (number < 1 || number > count) {
                return const Expanded(child: SizedBox());
              }
              final day = DateTime(first.year, first.month, number);
              final daily = sessions
                  .where((session) => _day(session) == day)
                  .toList();
              return Expanded(
                child: Card(
                  child: InkWell(
                    onTap: daily.isEmpty
                        ? null
                        : () => _showDay(day, daily, isTeacher),
                    child: SizedBox(
                      height: 82,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$number',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (daily.isNotEmpty)
                              Text(
                                '${daily.length} buổi',
                                style: const TextStyle(fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }

  void _showDay(
    DateTime day,
    List<ClassSessionModel> sessions,
    bool isTeacher,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              DateFormat('dd/MM/yyyy').format(day),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            ...sessions.map((session) => _buildSession(session, isTeacher)),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<ClassSessionModel> sessions, bool isTeacher) {
    return Column(
      children: sessions
          .map((session) => _buildSession(session, isTeacher, showDate: true))
          .toList(),
    );
  }

  Widget _buildSession(
    ClassSessionModel session,
    bool isTeacher, {
    bool showDate = false,
  }) {
    final room = session.roomName ?? session.roomCode;
    final teacher = session.teacherName;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showDate) Text(DateFormat('dd/MM/yyyy').format(_day(session))),
            Text(
              '${session.startTime}–${session.endTime}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              session.className ?? session.classCode ?? 'Lớp học',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (session.lessonTitle?.isNotEmpty == true ||
                session.title.isNotEmpty)
              Text(
                session.lessonTitle ?? session.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (room != null)
              Text(
                'Phòng: $room',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (!isTeacher && teacher != null)
              Text(
                'Giáo viên: $teacher',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Text(session.status, style: const TextStyle(color: Colors.grey)),
            if (isTeacher && session.status != 'CANCELLED')
              TextButton.icon(
                onPressed: () => context.push(
                  RouteNames.attendanceMark.replaceFirst(':id', session.id),
                ),
                icon: const Icon(Icons.how_to_reg),
                label: const Text('Điểm danh'),
              ),
          ],
        ),
      ),
    );
  }
}
