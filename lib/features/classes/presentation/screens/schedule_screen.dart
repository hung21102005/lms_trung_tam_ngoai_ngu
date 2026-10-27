import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/adaptive/adaptive_layout.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mobile/mobile_ui.dart';
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
  DateTime? _mobileSelectedDay;
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
    _mobileSelectedDay = null;
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
      _mobileSelectedDay = null;
    });
    _loadSchedule();
  }

  void _changeView(int mode) {
    if (_viewMode == mode) return;
    setState(() {
      _viewMode = mode;
      _selectedClassId = null;
      _mobileSelectedDay = null;
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
    final isMobile =
        AdaptiveBreakpoints.fromWidth(MediaQuery.sizeOf(context).width) ==
        AdaptiveSize.mobile;
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
            if (isMobile)
              _buildMobileHeader()
            else ...[
              Text(_heading, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              _buildToolbar(),
            ],
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

                if (isMobile) {
                  return _buildMobileSchedule(sessions, classNames, isTeacher);
                }
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

  Widget _buildMobileHeader() {
    final range = _viewMode == 0
        ? '${DateFormat('dd/MM').format(_rangeStart)} – ${DateFormat('dd/MM/yyyy').format(_rangeEnd)}'
        : DateFormat('MM/yyyy').format(_rangeStart);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _heading,
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'Theo dõi các buổi học và thời gian của bạn',
          style: TextStyle(color: AppColors.neutral600),
        ),
        const SizedBox(height: 16),
        MobileSectionCard(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              IconButton(
                onPressed: () => _move(-1),
                icon: const Icon(Icons.chevron_left_rounded),
                tooltip: 'Kỳ trước',
              ),
              Expanded(
                child: Text(
                  range,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: () => _move(1),
                icon: const Icon(Icons.chevron_right_rounded),
                tooltip: 'Kỳ sau',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final (index, label) in const [
                (0, 'Tuần'),
                (1, 'Tháng'),
                (2, 'Danh sách'),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: _viewMode == index,
                    onSelected: (_) => _changeView(index),
                  ),
                ),
              ActionChip(
                avatar: const Icon(Icons.today_rounded, size: 17),
                label: const Text('Hôm nay'),
                onPressed: () {
                  setState(() {
                    _anchor = _startOfWeek(DateTime.now());
                    _mobileSelectedDay = DateTime.now();
                  });
                  _loadSchedule();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileSchedule(
    List<ClassSessionModel> sessions,
    Map<String, String> classNames,
    bool isTeacher,
  ) {
    final days = List.generate(
      7,
      (index) => _rangeStart.add(Duration(days: index)),
    );
    final visible = _mobileSelectedDay == null || _viewMode == 2
        ? sessions
        : sessions
              .where(
                (session) =>
                    DateUtils.isSameDay(_day(session), _mobileSelectedDay),
              )
              .toList();
    return Column(
      key: const ValueKey('adaptive-mobile-schedule'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Buổi học',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            TextButton.icon(
              onPressed: () => _showMobileScheduleFilters(classNames),
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: const Text('Lọc'),
            ),
          ],
        ),
        if (_viewMode == 0) ...[
          const SizedBox(height: 6),
          SizedBox(
            height: 68,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _mobileDayChip(null, 'Tất cả', sessions.length),
                for (final day in days)
                  _mobileDayChip(
                    day,
                    '${day.day}/${day.month}',
                    sessions
                        .where(
                          (session) => DateUtils.isSameDay(_day(session), day),
                        )
                        .length,
                  ),
              ],
            ),
          ),
        ] else if (_viewMode == 1) ...[
          OutlinedButton.icon(
            onPressed: () async {
              final selected = await showDatePicker(
                context: context,
                initialDate: _mobileSelectedDay ?? _rangeStart,
                firstDate: _rangeStart,
                lastDate: _rangeEnd,
              );
              if (selected != null && mounted) {
                setState(() => _mobileSelectedDay = selected);
              }
            },
            icon: const Icon(Icons.event_rounded),
            label: Text(
              _mobileSelectedDay == null
                  ? 'Chọn ngày trong tháng'
                  : DateFormat('dd/MM/yyyy').format(_mobileSelectedDay!),
            ),
          ),
          if (_mobileSelectedDay != null)
            TextButton(
              onPressed: () => setState(() => _mobileSelectedDay = null),
              child: const Text('Xem cả tháng'),
            ),
        ],
        const SizedBox(height: 12),
        if (visible.isEmpty)
          const MobileSectionCard(
            child: Column(
              children: [
                Icon(
                  Icons.event_busy_outlined,
                  size: 36,
                  color: AppColors.neutral400,
                ),
                SizedBox(height: 8),
                Text('Không có buổi học trong khoảng thời gian này.'),
              ],
            ),
          ),
        for (final session in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildMobileSession(session, isTeacher),
          ),
      ],
    );
  }

  Widget _mobileDayChip(DateTime? day, String label, int count) {
    final selected = day == null
        ? _mobileSelectedDay == null
        : DateUtils.isSameDay(day, _mobileSelectedDay);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            Text('$count buổi', style: const TextStyle(fontSize: 11)),
          ],
        ),
        selected: selected,
        onSelected: (_) => setState(() => _mobileSelectedDay = day),
      ),
    );
  }

  Widget _buildMobileSession(ClassSessionModel session, bool isTeacher) {
    final room = session.roomName ?? session.roomCode;
    return MobileSectionCard(
      child: InkWell(
        onTap: () => _showMobileSession(session, isTeacher),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 64,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    session.startTime,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd/MM').format(_day(session)),
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.className ?? session.classCode ?? 'Lớp học',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    session.lessonTitle ?? session.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${session.startTime}–${session.endTime}'
                    '${room == null ? '' : ' · $room'}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.neutral500,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMobileScheduleFilters(Map<String, String> classes) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Lọc lịch học',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: classes.containsKey(_selectedClassId)
                    ? _selectedClassId
                    : null,
                decoration: const InputDecoration(labelText: 'Lớp học'),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Tất cả lớp'),
                  ),
                  for (final entry in classes.entries)
                    DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) => setState(() => _selectedClassId = value),
              ),
              if (_user?.isParent == true && _children.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedChildId,
                  decoration: const InputDecoration(labelText: 'Con'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Tất cả con'),
                    ),
                    for (final entry in _children.entries)
                      DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedChildId = value),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Xem lịch'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMobileSession(ClassSessionModel session, bool isTeacher) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                session.className ?? session.classCode ?? 'Lớp học',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(session.lessonTitle ?? session.title),
              const SizedBox(height: 12),
              Text(
                '${DateFormat('dd/MM/yyyy').format(_day(session))} · '
                '${session.startTime}–${session.endTime}',
              ),
              if (session.roomName != null || session.roomCode != null)
                Text('Phòng: ${session.roomName ?? session.roomCode}'),
              if (!isTeacher && session.teacherName != null)
                Text('Giảng viên: ${session.teacherName}'),
              Text('Trạng thái: ${session.status}'),
              if (isTeacher && session.status != 'CANCELLED') ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    context.push(
                      RouteNames.attendanceMark.replaceFirst(':id', session.id),
                    );
                  },
                  icon: const Icon(Icons.how_to_reg_rounded),
                  label: const Text('Điểm danh'),
                ),
              ],
            ],
          ),
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
