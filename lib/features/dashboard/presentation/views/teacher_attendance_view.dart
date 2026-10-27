import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../assignments/data/models/assignment_model.dart';
import '../../../assignments/domain/repositories/assignments_repository.dart';
import '../../../attendance/data/models/attendance_model.dart';
import '../../../attendance/domain/repositories/attendance_repository.dart';
import '../../../classes/data/models/class_model.dart';
import '../../../classes/domain/repositories/classes_repository.dart';

class TeacherAttendanceView extends StatefulWidget {
  const TeacherAttendanceView({
    super.key,
    this.classesRepository,
    this.attendanceRepository,
    this.assignmentsRepository,
  });

  final ClassesRepository? classesRepository;
  final AttendanceRepository? attendanceRepository;
  final AssignmentsRepository? assignmentsRepository;

  @override
  State<TeacherAttendanceView> createState() => _TeacherAttendanceViewState();
}

class _TeacherAttendanceViewState extends State<TeacherAttendanceView> {
  late final ClassesRepository _classesRepository;
  late final AttendanceRepository _attendanceRepository;
  late final AssignmentsRepository _assignmentsRepository;
  final _topicController = TextEditingController();
  final _evaluationController = TextEditingController();
  final _homeworkController = TextEditingController();
  final Map<String, TextEditingController> _studentNotes = {};
  final List<AssignmentAttachmentModel> _attachments = [];
  final List<PlatformFile> _pendingAttachments = [];

  List<ClassModel> _classes = [];
  List<ClassSessionModel> _sessions = [];
  SessionAttendanceResponseModel? _attendance;
  String? _selectedClassId;
  String? _selectedSessionId;
  int _filter = 0;
  bool _loading = true;
  bool _savingAttendance = false;
  bool _savingLogbook = false;
  bool _reportSubmitted = false;
  String? _error;

  bool get _locked => _attendance?.status == 'COMPLETED';

  @override
  void initState() {
    super.initState();
    _classesRepository = widget.classesRepository ?? getIt<ClassesRepository>();
    _attendanceRepository =
        widget.attendanceRepository ?? getIt<AttendanceRepository>();
    _assignmentsRepository =
        widget.assignmentsRepository ?? getIt<AssignmentsRepository>();
    _loadClasses();
  }

  @override
  void dispose() {
    _topicController.dispose();
    _evaluationController.dispose();
    _homeworkController.dispose();
    for (final controller in _studentNotes.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadClasses() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      var classes = await _classesRepository.getMyClasses();
      if (classes.isEmpty) {
        classes = await _classesRepository.getClasses(limit: 100);
      }
      if (!mounted) return;
      _classes = classes;
      if (classes.isNotEmpty) {
        final schedule = await _classesRepository.getMySchedule();
        final initialClassId = schedule.isEmpty
            ? classes.first.id
            : _bestSession(schedule).classId;
        _selectedClassId = classes.any((item) => item.id == initialClassId)
            ? initialClassId
            : classes.first.id;
        await _loadSessions(_selectedClassId!);
      }
    } catch (error) {
      if (mounted) _error = 'Không tải được lớp học: $error';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadSessions(String classId, {String? keepSessionId}) async {
    setState(() {
      _loading = true;
      _error = null;
      _attendance = null;
    });
    try {
      final sessions = await _classesRepository.getClassSessions(classId);
      if (!mounted) return;
      _sessions = sessions;
      if (sessions.isEmpty) {
        _selectedSessionId = null;
        return;
      }
      final kept = sessions
          .where((item) => item.id == keepSessionId)
          .firstOrNull;
      final session = kept ?? _bestSession(sessions);
      _selectedSessionId = session.id;
      await _loadAttendance(session.id);
    } catch (error) {
      if (mounted) _error = 'Không tải được buổi học: $error';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  ClassSessionModel _bestSession(List<ClassSessionModel> sessions) {
    final now = DateTime.now();
    final active = sessions
        .where((item) => item.status == 'IN_PROGRESS')
        .firstOrNull;
    if (active != null) return active;
    final today = sessions.where((item) {
      final date = item.date?.toLocal();
      return date != null &&
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).firstOrNull;
    if (today != null) return today;
    final sorted = [...sessions]
      ..sort((a, b) {
        final ad = a.date ?? DateTime(2100);
        final bd = b.date ?? DateTime(2100);
        return ad.difference(now).abs().compareTo(bd.difference(now).abs());
      });
    return sorted.first;
  }

  Future<void> _loadAttendance(String sessionId) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _attendanceRepository.getSessionAttendance(sessionId);
      if (!mounted) return;
      for (final controller in _studentNotes.values) {
        controller.dispose();
      }
      _studentNotes.clear();
      for (final student in data.students) {
        _studentNotes[student.studentId] = TextEditingController(
          text: student.notes ?? '',
        );
      }
      _attendance = data;
      _loadLogbook(
        _sessions.where((item) => item.id == sessionId).firstOrNull?.notes,
      );
    } catch (error) {
      if (mounted) _error = 'Không tải được danh sách điểm danh: $error';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _loadLogbook(String? rawNotes) {
    _topicController.clear();
    _evaluationController.clear();
    _homeworkController.clear();
    _attachments.clear();
    _pendingAttachments.clear();
    _reportSubmitted = false;
    if (rawNotes == null || rawNotes.trim().isEmpty) return;
    try {
      final value = jsonDecode(rawNotes);
      if (value is! Map<String, dynamic> || value['kind'] != 'TEACHING_LOG') {
        _topicController.text = rawNotes;
        return;
      }
      _topicController.text = value['topic']?.toString() ?? '';
      _evaluationController.text = value['evaluation']?.toString() ?? '';
      _homeworkController.text = value['homework']?.toString() ?? '';
      _reportSubmitted = value['submitted'] == true;
      final files = value['attachments'];
      if (files is List) {
        _attachments.addAll(
          files.whereType<Map>().map(
            (item) => AssignmentAttachmentModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          ),
        );
      }
    } catch (_) {
      _topicController.text = rawNotes;
    }
  }

  void _setStatus(StudentAttendanceItemModel student, String status) {
    if (_locked) return;
    setState(() {
      student.status = status;
      student.checkInTime = status == 'ABSENT' || status == 'EXCUSED'
          ? null
          : DateFormat('HH:mm').format(DateTime.now());
    });
  }

  void _markAllPresent() {
    final data = _attendance;
    if (data == null || _locked) return;
    final time = DateFormat('HH:mm').format(DateTime.now());
    setState(() {
      for (final student in data.students) {
        student.status = 'PRESENT';
        student.checkInTime = time;
      }
    });
    _showMessage('Đã chọn Có mặt cho toàn bộ học viên.', AppColors.success);
  }

  Future<void> _quickCheckIn() async {
    if (_locked || _attendance == null) return;
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Điểm danh bằng mã học viên'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Mã học viên hoặc dữ liệu từ QR',
            hintText: 'Ví dụ: DEMO-HV-05',
            prefixIcon: Icon(Icons.qr_code_scanner),
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (code == null || code.trim().isEmpty || !mounted) return;
    final normalized = code.trim().toUpperCase();
    final student = _attendance!.students
        .where(
          (item) =>
              item.userCode.toUpperCase() == normalized ||
              item.studentId == code.trim(),
        )
        .firstOrNull;
    if (student == null) {
      _showMessage(
        'Không tìm thấy học viên có mã $code trong lớp.',
        AppColors.error,
      );
      return;
    }
    _setStatus(student, 'PRESENT');
    _showMessage('Đã ghi nhận ${student.fullName} có mặt.', AppColors.success);
  }

  List<Map<String, dynamic>> _attendancePayload() {
    final data = _attendance!;
    return data.students.map((student) {
      final notes = _studentNotes[student.studentId]?.text.trim();
      final date = DateTime.tryParse(data.date)?.toLocal() ?? DateTime.now();
      final time = student.checkInTime;
      return <String, dynamic>{
        'studentId': student.studentId,
        'status': student.status,
        if (time != null && time.isNotEmpty)
          'checkInTime': DateTime(
            date.year,
            date.month,
            date.day,
            int.tryParse(time.split(':').first) ?? 0,
            int.tryParse(time.split(':').last) ?? 0,
          ).toIso8601String(),
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };
    }).toList();
  }

  Future<void> _saveAndLockAttendance() async {
    final data = _attendance;
    if (data == null || _savingAttendance || _locked) return;
    final unmarked = data.students.where((item) => item.status == null).length;
    if (unmarked > 0) {
      _showMessage(
        'Còn $unmarked học viên chưa chọn trạng thái.',
        AppColors.warning,
      );
      return;
    }
    setState(() => _savingAttendance = true);
    try {
      await _attendanceRepository.batchMarkAttendance(
        data.sessionId,
        _attendancePayload(),
        lock: true,
      );
      await _loadSessions(data.classId, keepSessionId: data.sessionId);
      if (mounted) {
        _showMessage('Đã lưu và khóa điểm danh buổi học.', AppColors.success);
      }
    } catch (error) {
      if (mounted) {
        _showMessage('Không lưu được điểm danh: $error', AppColors.error);
      }
    } finally {
      if (mounted) setState(() => _savingAttendance = false);
    }
  }

  Future<void> _pickAttachments() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const [
          'pdf',
          'doc',
          'docx',
          'ppt',
          'pptx',
          'xls',
          'xlsx',
          'txt',
          'jpg',
          'jpeg',
          'png',
          'webp',
          'zip',
          'rar',
        ],
      );
      if (!mounted) return;
      for (final file in files) {
        final size = file.lengthSync() ?? await file.length() ?? 0;
        if (size > 50 * 1024 * 1024) {
          _showMessage('${file.name} vượt quá 50 MB.', AppColors.warning);
        } else if (!_pendingAttachments.any((item) => item.name == file.name)) {
          _pendingAttachments.add(file);
        }
      }
      setState(() {});
    } catch (error) {
      if (mounted) {
        _showMessage('Không chọn được tài liệu: $error', AppColors.error);
      }
    }
  }

  Future<void> _saveLogbook({required bool submit}) async {
    final sessionId = _selectedSessionId;
    if (sessionId == null || _savingLogbook) return;
    if (submit &&
        (_topicController.text.trim().isEmpty ||
            _evaluationController.text.trim().isEmpty)) {
      _showMessage(
        'Vui lòng nhập nội dung đã dạy và đánh giá buổi học.',
        AppColors.warning,
      );
      return;
    }
    setState(() => _savingLogbook = true);
    try {
      for (final file in _pendingAttachments) {
        final bytes = await file.readAsBytes();
        _attachments.add(
          await _assignmentsRepository.uploadAttachment(file.name, bytes),
        );
      }
      _pendingAttachments.clear();
      final notes = jsonEncode({
        'kind': 'TEACHING_LOG',
        'topic': _topicController.text.trim(),
        'evaluation': _evaluationController.text.trim(),
        'homework': _homeworkController.text.trim(),
        'attachments': _attachments.map((item) => item.toJson()).toList(),
        'submitted': submit || _reportSubmitted,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      await _classesRepository.updateSession(sessionId, notes: notes);
      _reportSubmitted = submit || _reportSubmitted;
      _sessions = await _classesRepository.getClassSessions(_selectedClassId!);
      if (mounted) {
        setState(() {});
        _showMessage(
          submit ? 'Đã gửi sổ đầu bài cho học vụ.' : 'Đã lưu nháp sổ đầu bài.',
          AppColors.success,
        );
      }
    } catch (error) {
      if (mounted) {
        _showMessage('Không lưu được sổ đầu bài: $error', AppColors.error);
      }
    } finally {
      if (mounted) setState(() => _savingLogbook = false);
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: RefreshIndicator(
        onRefresh: _loadClasses,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Điểm danh & Sổ đầu bài Buổi học',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Chọn lớp và buổi học để cập nhật chuyên cần và nhật ký giảng dạy.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),
            _buildSelectors(),
            const SizedBox(height: 18),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              _buildError()
            else if (_classes.isEmpty)
              _empty('Chưa có lớp học để điểm danh.')
            else if (_sessions.isEmpty)
              _empty('Lớp này chưa có buổi học trong thời khóa biểu.')
            else if (_attendance != null) ...[
              _buildSummary(),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 1080) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 7, child: _buildRoster()),
                        const SizedBox(width: 20),
                        Expanded(flex: 5, child: _buildLogbook()),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      _buildRoster(),
                      const SizedBox(height: 20),
                      _buildLogbook(),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelectors() {
    return _card(
      child: Column(
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 360,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _selectedClassId,
                  decoration: const InputDecoration(
                    labelText: 'Lớp học',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  items: _classes
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(
                            '${item.name} (${item.code})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _loading
                      ? null
                      : (value) async {
                          if (value == null) return;
                          setState(() => _selectedClassId = value);
                          await _loadSessions(value);
                        },
                ),
              ),
              SizedBox(
                width: 390,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue:
                      _sessions.any((item) => item.id == _selectedSessionId)
                      ? _selectedSessionId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Buổi học',
                    prefixIcon: Icon(Icons.event_outlined),
                  ),
                  items: _sessions
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(
                            'Buổi ${item.sessionNumber} · ${_date(item.date)} · ${item.startTime}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _loading
                      ? null
                      : (value) async {
                          if (value == null) return;
                          setState(() => _selectedSessionId = value);
                          await _loadAttendance(value);
                        },
                ),
              ),
            ],
          ),
          if (_attendance != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.meeting_room_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${_attendance!.roomName ?? _attendance!.roomCode ?? 'Chưa xếp phòng'} · '
                    '${_attendance!.startTime} - ${_attendance!.endTime}',
                  ),
                ),
                _statusBadge(_attendance!.status),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _locked ? null : _markAllPresent,
                  icon: const Icon(Icons.done_all),
                  label: const Text('Tất cả có mặt'),
                ),
                OutlinedButton.icon(
                  onPressed: _locked ? null : _quickCheckIn,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Quét / nhập mã'),
                ),
                FilledButton.icon(
                  onPressed: _savingAttendance || _locked
                      ? null
                      : _saveAndLockAttendance,
                  icon: _savingAttendance
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_outline),
                  label: Text(
                    _locked ? 'Điểm danh đã khóa' : 'Lưu & khóa điểm danh',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final students = _attendance!.students;
    final present = students.where((item) => item.status == 'PRESENT').length;
    final late = students.where((item) => item.status == 'LATE').length;
    final absent = students.where((item) => item.status == 'ABSENT').length;
    final unmarked = students.where((item) => item.status == null).length;
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        _stat(
          'Sĩ số',
          students.length,
          Icons.groups_outlined,
          AppColors.primary,
        ),
        _stat('Có mặt', present, Icons.check_circle_outline, AppColors.success),
        _stat('Đi trễ', late, Icons.schedule, AppColors.warning),
        _stat('Vắng', absent, Icons.person_off_outlined, AppColors.error),
        if (unmarked > 0)
          _stat(
            'Chưa đánh dấu',
            unmarked,
            Icons.help_outline,
            AppColors.neutral600,
          ),
      ],
    );
  }

  Widget _buildRoster() {
    final students = _attendance!.students.where((student) {
      if (_filter == 1) return student.status == 'PRESENT';
      if (_filter == 2) return student.status == 'LATE';
      if (_filter == 3) {
        return student.status == 'ABSENT' || student.status == 'EXCUSED';
      }
      return true;
    }).toList();
    return _card(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Danh sách điểm danh',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Tất cả')),
                    ButtonSegment(value: 1, label: Text('Có mặt')),
                    ButtonSegment(value: 2, label: Text('Đi trễ')),
                    ButtonSegment(value: 3, label: Text('Vắng')),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (value) =>
                      setState(() => _filter = value.first),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (students.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text('Không có học viên ở trạng thái này.'),
            )
          else
            ...students.map(_studentRow),
        ],
      ),
    );
  }

  Widget _studentRow(StudentAttendanceItemModel student) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                child: Text(
                  student.fullName.isEmpty
                      ? '?'
                      : student.fullName[0].toUpperCase(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${student.userCode}${student.phone == null ? '' : ' · ${student.phone}'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (student.checkInTime != null)
                Text(
                  student.checkInTime!,
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _statusChoice(student, 'PRESENT', 'Có mặt', AppColors.success),
              _statusChoice(student, 'LATE', 'Đi trễ', AppColors.warning),
              _statusChoice(student, 'EXCUSED', 'Có phép', AppColors.primary),
              _statusChoice(student, 'ABSENT', 'Vắng', AppColors.error),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _studentNotes[student.studentId],
            enabled: !_locked,
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'Đánh giá hoặc ghi chú cho học viên...',
              prefixIcon: Icon(Icons.notes, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChoice(
    StudentAttendanceItemModel student,
    String value,
    String label,
    Color color,
  ) {
    final selected = student.status == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: _locked ? null : (_) => _setStatus(student, value),
      selectedColor: color,
      labelStyle: TextStyle(
        color: selected ? Colors.white : color,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(color: color.withAlpha(120)),
    );
  }

  Widget _buildLogbook() {
    return _card(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Sổ đầu bài & Nhật ký giảng dạy',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                if (_reportSubmitted)
                  const Chip(
                    label: Text('Đã gửi học vụ'),
                    avatar: Icon(Icons.verified, size: 16),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _field(
                  '1. Nội dung kiến thức đã giảng dạy *',
                  _topicController,
                  3,
                ),
                _field(
                  '2. Đánh giá ý thức & chất lượng buổi học *',
                  _evaluationController,
                  3,
                ),
                _field('3. Dặn dò & Bài tập về nhà', _homeworkController, 2),
                const Text(
                  '4. Tài liệu bài giảng đính kèm',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._attachments.map(
                  (file) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.insert_drive_file_outlined),
                    title: Text(file.name),
                    trailing: IconButton(
                      tooltip: 'Bỏ tài liệu',
                      onPressed: _savingLogbook
                          ? null
                          : () => setState(() => _attachments.remove(file)),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ),
                ..._pendingAttachments.map(
                  (file) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.upload_file),
                    title: Text(file.name),
                    subtitle: const Text('Chờ tải lên'),
                    trailing: IconButton(
                      onPressed: _savingLogbook
                          ? null
                          : () => setState(
                              () => _pendingAttachments.remove(file),
                            ),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _savingLogbook ? null : _pickAttachments,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Thêm tài liệu'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                    onPressed: _savingLogbook
                        ? null
                        : () => _saveLogbook(submit: true),
                    icon: const Icon(Icons.send_outlined),
                    label: const Text('Gửi báo cáo học vụ'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _savingLogbook
                        ? null
                        : () => _saveLogbook(submit: false),
                    icon: _savingLogbook
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Lưu nháp sổ đầu bài'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, int lines) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: lines,
            decoration: const InputDecoration(filled: true),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, int value, IconData icon, Color color) {
    return SizedBox(
      width: 205,
      child: _card(
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withAlpha(25),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                  Text(
                    '$value HV',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final locked = status == 'COMPLETED';
    return Chip(
      avatar: Icon(locked ? Icons.lock : Icons.circle, size: 14),
      label: Text(
        locked
            ? 'Đã khóa'
            : status == 'IN_PROGRESS'
            ? 'Đang điểm danh'
            : 'Chưa hoàn tất',
      ),
      backgroundColor: locked
          ? const Color(0xFFE2E8F0)
          : const Color(0xFFDCFCE7),
    );
  }

  Widget _buildError() => _card(
    child: Column(
      children: [
        Text(_error!, style: const TextStyle(color: AppColors.error)),
        const SizedBox(height: 8),
        FilledButton(onPressed: _loadClasses, child: const Text('Thử lại')),
      ],
    ),
  );

  Widget _empty(String message) => _card(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Center(child: Text(message)),
    ),
  );

  Widget _card({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: child,
    );
  }

  String _date(DateTime? value) => value == null
      ? 'Chưa có ngày'
      : DateFormat('dd/MM/yyyy').format(value.toLocal());
}
