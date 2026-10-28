import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/searchable_entity_field.dart';
import '../../../../shared/widgets/mobile/mobile_ui.dart';
import '../bloc/classes_bloc.dart';
import '../bloc/classes_event.dart';
import '../bloc/classes_state.dart';

class ClassCreateScreen extends StatefulWidget {
  const ClassCreateScreen({super.key, this.catalogFetch});

  final Future<dynamic> Function(
    String path, {
    Map<String, dynamic>? queryParameters,
  })?
  catalogFetch;

  @override
  State<ClassCreateScreen> createState() => _ClassCreateScreenState();
}

class _ClassCreateScreenState extends State<ClassCreateScreen> {
  Future<dynamic> _getCatalog(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    if (widget.catalogFetch != null) {
      return widget.catalogFetch!(path, queryParameters: queryParameters);
    }
    return getIt<ApiClient>().get(path, queryParameters: queryParameters);
  }

  final _formKey = GlobalKey<FormState>();
  List<EntityOption> _courses = [];
  List<EntityOption> _levels = [];
  List<EntityOption> _branches = [];
  List<EntityOption> _rooms = [];
  List<EntityOption> _teachers = [];
  String? _lookupError;
  bool _loadingLookups = true;

  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _courseIdController = TextEditingController();
  final _levelIdController = TextEditingController();
  final _branchIdController = TextEditingController();
  final _roomIdController = TextEditingController();
  final _teacherIdController = TextEditingController();
  final _totalSessionsController = TextEditingController(text: '24');
  final _capacityController = TextEditingController(text: '20');
  final _tuitionFeeController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _startTime = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 19, minute: 30);

  final List<Map<String, String>> _allDays = [
    {'code': 'MONDAY', 'label': 'Thứ 2'},
    {'code': 'TUESDAY', 'label': 'Thứ 3'},
    {'code': 'WEDNESDAY', 'label': 'Thứ 4'},
    {'code': 'THURSDAY', 'label': 'Thứ 5'},
    {'code': 'FRIDAY', 'label': 'Thứ 6'},
    {'code': 'SATURDAY', 'label': 'Thứ 7'},
    {'code': 'SUNDAY', 'label': 'Chủ nhật'},
  ];

  final Set<String> _selectedDays = {'MONDAY', 'WEDNESDAY', 'FRIDAY'};

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  List<dynamic> _items(dynamic response) {
    final data = response is Map ? response['data'] ?? response : response;
    if (data is List) return data;
    if (data is Map && data['items'] is List) return data['items'] as List;
    return [];
  }

  List<EntityOption> _options(
    List<dynamic> items,
    String labelKey,
    String codeKey,
  ) {
    return items
        .whereType<Map>()
        .map((item) {
          final id = item['id']?.toString() ?? '';
          final name = item[labelKey]?.toString() ?? '';
          final code = item[codeKey]?.toString() ?? '';
          return EntityOption(
            id: id,
            label: code.isEmpty ? name : '$name ($code)',
          );
        })
        .where((option) => option.id.isNotEmpty)
        .toList();
  }

  Future<List<dynamic>> _allCourses() async {
    final courses = <dynamic>[];
    var page = 1;
    var totalPages = 1;
    do {
      final response = await _getCatalog(
        '/courses',
        queryParameters: {'page': page, 'limit': 100},
      );
      courses.addAll(_items(response));
      final data = response is Map ? response['data'] ?? response : response;
      totalPages = data is Map ? int.tryParse('${data['totalPages']}') ?? 1 : 1;
      page++;
    } while (page <= totalPages);
    return courses;
  }

  Future<void> _loadLookups() async {
    setState(() {
      _loadingLookups = true;
      _lookupError = null;
    });
    try {
      final results = await Future.wait([
        _allCourses(),
        _getCatalog('/branches'),
      ]);
      if (!mounted) return;
      setState(() {
        _courses = _options(results[0] as List<dynamic>, 'title', 'code');
        _branches = _options(_items(results[1]), 'name', 'code');
        _loadingLookups = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _lookupError = error.toString();
          _loadingLookups = false;
        });
      }
    }
  }

  Future<void> _selectCourse(String? id) async {
    setState(() {
      _courseIdController.text = id ?? '';
      _levelIdController.clear();
      _levels = [];
    });
    if (id == null) return;
    try {
      final response = await _getCatalog('/courses/$id/levels');
      if (mounted && _courseIdController.text == id) {
        setState(() => _levels = _options(_items(response), 'name', 'code'));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tải được cấp độ: $error')),
        );
      }
    }
  }

  Future<void> _selectBranch(String? id) async {
    setState(() {
      _branchIdController.text = id ?? '';
      _roomIdController.clear();
      _teacherIdController.clear();
      _rooms = [];
      _teachers = [];
    });
    if (id == null) return;
    try {
      final results = await Future.wait([
        _getCatalog('/branches/$id/rooms'),
        _getCatalog(
          '/users/teachers/lookup',
          queryParameters: {'branchId': id},
        ),
      ]);
      if (mounted && _branchIdController.text == id) {
        setState(() {
          _rooms = _options(_items(results[0]), 'name', 'code');
          _teachers = _options(_items(results[1]), 'fullName', 'userCode');
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không tải được phòng học hoặc giáo viên: $error'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _courseIdController.dispose();
    _levelIdController.dispose();
    _branchIdController.dispose();
    _roomIdController.dispose();
    _teacherIdController.dispose();
    _totalSessionsController.dispose();
    _capacityController.dispose();
    _tuitionFeeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;
    if (_courseIdController.text.isEmpty ||
        _levelIdController.text.isEmpty ||
        _branchIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng chọn khóa học, cấp độ và chi nhánh từ danh sách.',
          ),
        ),
      );
      return;
    }
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất 1 ngày học trong tuần'),
        ),
      );
      return;
    }

    final totalSessions =
        int.tryParse(_totalSessionsController.text.trim()) ?? 24;
    final capacity = int.tryParse(_capacityController.text.trim()) ?? 20;
    final fee = double.tryParse(_tuitionFeeController.text.trim());

    context.read<ClassesBloc>().add(
      CreateClassEvent(
        code: _codeController.text.trim().toUpperCase(),
        name: _nameController.text.trim(),
        courseId: _courseIdController.text.trim(),
        levelId: _levelIdController.text.trim(),
        branchId: _branchIdController.text.trim(),
        roomId: _roomIdController.text.trim().isNotEmpty
            ? _roomIdController.text.trim()
            : null,
        mainTeacherId: _teacherIdController.text.trim().isNotEmpty
            ? _teacherIdController.text.trim()
            : null,
        startDate: DateFormat('yyyy-MM-dd').format(_startDate),
        scheduleDays: _selectedDays.toList(),
        startTime: _formatTimeOfDay(_startTime),
        endTime: _formatTimeOfDay(_endTime),
        totalSessions: totalSessions,
        maxCapacity: capacity,
        tuitionFee: fee,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      ),
    );
  }

  Widget _fieldPair({
    required bool isMobile,
    required Widget first,
    required Widget second,
  }) => isMobile
      ? Column(children: [first, const SizedBox(height: 12), second])
      : Row(
          children: [
            Expanded(child: first),
            const SizedBox(width: 12),
            Expanded(child: second),
          ],
        );

  Widget _timeField(
    String label,
    TimeOfDay value,
    VoidCallback onTap,
    bool isDark,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: AppTextStyles.caption(context)
            .copyWith(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 6),
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatTimeOfDay(value),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Icon(Icons.access_time, size: 18),
            ],
          ),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Mở Lớp Học Mới'),
        elevation: 0,
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        foregroundColor: isDark ? Colors.white : AppColors.textPrimaryLight,
      ),
      bottomNavigationBar: isMobile
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: SizedBox(width: double.infinity, child: _submitButton()),
            )
          : null,
      body: BlocListener<ClassesBloc, ClassesState>(
        listener: (context, state) {
          if (state is ClassOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.of(context).pop();
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
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (isMobile) ...[
                const MobileSectionCard(
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Chọn chương trình, xếp lịch và quy mô lớp. Hệ thống sẽ tạo các buổi học sau khi lưu.',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông tin cơ bản của Lớp học',
                      style: AppTextStyles.h4(context),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Mã lớp học *',
                      hintText: 'VD: IELTS-F-2026-01',
                      controller: _codeController,
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Vui lòng nhập mã lớp'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Tên hiển thị của lớp *',
                      hintText: 'VD: IELTS Foundation T2-T4-T6',
                      controller: _nameController,
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Vui lòng nhập tên lớp'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _fieldPair(
                      isMobile: isMobile,
                      first: SearchableEntityField(
                        label: 'Khóa học *',
                        options: _courses,
                        selectedId: _courseIdController.text.isEmpty
                            ? null
                            : _courseIdController.text,
                        onSelected: _selectCourse,
                        enabled: !_loadingLookups,
                      ),
                      second: SearchableEntityField(
                        label: 'Cấp độ *',
                        options: _levels,
                        selectedId: _levelIdController.text.isEmpty
                            ? null
                            : _levelIdController.text,
                        onSelected: (id) =>
                            setState(() => _levelIdController.text = id ?? ''),
                        enabled: _courseIdController.text.isNotEmpty,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _fieldPair(
                      isMobile: isMobile,
                      first: SearchableEntityField(
                        label: 'Chi nhánh *',
                        options: _branches,
                        selectedId: _branchIdController.text.isEmpty
                            ? null
                            : _branchIdController.text,
                        onSelected: _selectBranch,
                        enabled: !_loadingLookups,
                      ),
                      second: SearchableEntityField(
                        label: 'Phòng học',
                        options: _rooms,
                        selectedId: _roomIdController.text.isEmpty
                            ? null
                            : _roomIdController.text,
                        onSelected: (id) =>
                            setState(() => _roomIdController.text = id ?? ''),
                        enabled: _branchIdController.text.isNotEmpty,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SearchableEntityField(
                      label: 'Giáo viên phụ trách chính',
                      options: _teachers,
                      selectedId: _teacherIdController.text.isEmpty
                          ? null
                          : _teacherIdController.text,
                      onSelected: (id) =>
                          setState(() => _teacherIdController.text = id ?? ''),
                      enabled: _branchIdController.text.isNotEmpty,
                    ),
                    if (_lookupError != null) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _loadLookups,
                        child: Text(
                          'Không tải được danh sách. Thử lại: $_lookupError',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Timetable & Scheduling Card
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lịch học & Xếp thời khóa biểu',
                      style: AppTextStyles.h4(context),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Hệ thống sẽ tự động sinh toàn bộ danh sách các buổi học và kiểm tra xung đột phòng/giáo viên.',
                      style: AppTextStyles.caption(context),
                    ),
                    const SizedBox(height: 16),

                    // Start date picker
                    Text(
                      'Ngày khai giảng *',
                      style: AppTextStyles.caption(context)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _pickStartDate,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd/MM/yyyy').format(_startDate),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Icon(Icons.calendar_today, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Days selector
                    Text(
                      'Các ngày học trong tuần *',
                      style: AppTextStyles.caption(context)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allDays.map((d) {
                        final code = d['code']!;
                        final isSel = _selectedDays.contains(code);
                        return FilterChip(
                          label: Text(d['label']!),
                          selected: isSel,
                          selectedColor: primaryColor.withAlpha(40),
                          backgroundColor: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          labelStyle: TextStyle(
                            color: isSel
                                ? primaryColor
                                : (isDark
                                      ? Colors.white70
                                      : AppColors.textSecondaryLight),
                            fontWeight: isSel
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          side: BorderSide(
                            color: isSel
                                ? primaryColor
                                : (isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLight),
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedDays.add(code);
                              } else {
                                _selectedDays.remove(code);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    _fieldPair(
                      isMobile: isMobile,
                      first: _timeField(
                        'Giờ bắt đầu',
                        _startTime,
                        _pickStartTime,
                        isDark,
                      ),
                      second: _timeField(
                        'Giờ kết thúc',
                        _endTime,
                        _pickEndTime,
                        isDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Capacity & Tuition Fee Card
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quy mô & Học phí', style: AppTextStyles.h4(context)),
                    const SizedBox(height: 16),
                    _fieldPair(
                      isMobile: isMobile,
                      first: AppTextField(
                        label: 'Tổng số buổi học',
                        hintText: '24',
                        keyboardType: TextInputType.number,
                        controller: _totalSessionsController,
                      ),
                      second: AppTextField(
                        label: 'Sĩ số tối đa',
                        hintText: '20',
                        keyboardType: TextInputType.number,
                        controller: _capacityController,
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Học phí áp dụng cho lớp (VNĐ)',
                      hintText: 'VD: 4500000',
                      keyboardType: TextInputType.number,
                      controller: _tuitionFeeController,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Ghi chú lớp học',
                      hintText: 'Yêu cầu phòng học, thiết bị máy chiếu...',
                      controller: _notesController,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (!isMobile) _submitButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _submitButton() => BlocBuilder<ClassesBloc, ClassesState>(
    builder: (context, state) => AppButton(
      text: 'Tạo Lớp & Tự Động Sinh Buổi Học',
      isLoading: state is ClassesLoading,
      onPressed: _submitForm,
    ),
  );
}
