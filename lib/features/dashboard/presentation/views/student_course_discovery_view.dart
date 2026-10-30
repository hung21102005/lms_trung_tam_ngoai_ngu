import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/adaptive/adaptive_layout.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../classes/data/models/class_model.dart';
import '../../../classes/domain/repositories/classes_repository.dart';
import '../../../public/data/public_catalog_repository.dart';

/// Screen allowing enrolled students to discover courses, view learning path recommendations,
/// register for new open classes with 1-click, and track their application requests.
class StudentCourseDiscoveryView extends StatefulWidget {
  const StudentCourseDiscoveryView({super.key});

  @override
  State<StudentCourseDiscoveryView> createState() => _StudentCourseDiscoveryViewState();
}

class _StudentCourseDiscoveryViewState extends State<StudentCourseDiscoveryView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final PublicCatalogRepository _repository;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;

  List<ClassModel> _myEnrolledClasses = [];
  List<Map<String, dynamic>> _programs = [];
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _myRegistrations = [];

  String _selectedProgram = 'ALL';
  bool _onlyAvailable = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _repository = PublicCatalogRepository(getIt<ApiClient>());
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        getIt.isRegistered<ClassesRepository>()
            ? getIt<ClassesRepository>().getMyClasses()
            : Future.value(<ClassModel>[]),
        _repository.programs(),
        _repository.courses(),
        _repository.classes(page: 1),
        _repository.myRegistrations(),
      ]);

      if (!mounted) return;
      setState(() {
        _myEnrolledClasses = results[0] as List<ClassModel>;
        _programs = results[1] as List<Map<String, dynamic>>;
        _courses = results[2] as List<Map<String, dynamic>>;
        final classData = results[3] as Map<String, dynamic>;
        _classes = (classData['items'] as List? ?? []).cast<Map<String, dynamic>>();
        _myRegistrations = results[4] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshRegistrationsOnly() async {
    try {
      final reqs = await _repository.myRegistrations();
      if (mounted) {
        setState(() => _myRegistrations = reqs);
      }
    } catch (_) {}
  }

  // Next level suggestion based on current enrolled courses
  Map<String, String>? _detectNextCourseRecommendation() {
    if (_myEnrolledClasses.isEmpty) {
      if (_courses.isNotEmpty) {
        final firstCourse = _courses.first;
        return {
          'reason': 'Khởi đầu lộ trình tiếng Anh chuẩn quốc tế',
          'courseTitle': '${firstCourse['title']}',
          'hint': 'Tham gia kiểm tra đầu vào miễn phí để xếp lớp chính xác.',
        };
      }
      return null;
    }

    final currentClass = _myEnrolledClasses.first;
    final currentTitle = currentClass.courseTitle ?? currentClass.name;

    if (currentTitle.toUpperCase().contains('FOUNDATION') || currentTitle.contains('A1') || currentTitle.contains('A2')) {
      return {
        'reason': 'Bạn đang học $currentTitle. Cấp độ tiếp theo đề xuất:',
        'courseTitle': 'IELTS Bứt Phá 5.5 - 6.5 (Band Intermediate)',
        'hint': 'Điều kiện tiên quyết: Hoàn thành cấp độ Foundation hoặc CEFR B1.',
      };
    } else if (currentTitle.contains('5.5') || currentTitle.contains('B1')) {
      return {
        'reason': 'Bạn đang học $currentTitle. Cấp độ tiếp theo đề xuất:',
        'courseTitle': 'IELTS Intensive 6.5+ (Advanced Mastery)',
        'hint': 'Điều kiện tiên quyết: Hoàn thành band 5.5 hoặc bài test đầu vào đạt 5.5+.',
      };
    } else {
      return {
        'reason': 'Lộ trình phát triển tiếp theo sau $currentTitle:',
        'courseTitle': 'Khóa Luyện Thi Chuyên Sâu & Tiếng Anh Học Thuật Cao Cấp',
        'hint': 'Tự động kiểm tra điều kiện tiên quyết và bảo lưu hồ sơ.',
      };
    }
  }

  Future<void> _showRegisterModal(Map<String, dynamic> offering, UserEntity? user) async {
    final noteCtrl = TextEditingController();
    bool submitting = false;

    final course = offering['course'] as Map?;
    final branch = offering['branch'] as Map?;
    final room = offering['room'] as Map?;
    final price = num.tryParse('${offering['tuitionFee']}');
    final feeStr = price == null || price == 0
        ? 'Liên hệ học phí'
        : '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ';

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.school_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Đăng Ký Học Viên Tiếp Nối',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Class Details Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${offering['name']}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mã lớp: ${offering['code']} • Khóa học: ${course?['title'] ?? ""}',
                          style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${branch?['name'] ?? ""}${room != null ? " · Phòng ${room['name']}" : ""}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.schedule_rounded, size: 16, color: Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Text(
                              'Giờ học: ${offering['startTime'] ?? ""} - ${offering['endTime'] ?? ""}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.payments_outlined, size: 16, color: Color(0xFF64748B)),
                                const SizedBox(width: 6),
                                Text(
                                  'Học phí: $feeStr',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Còn ${offering['remainingSeats']} chỗ',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF15803D)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Student Profile Sync Confirmation
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_circle_rounded, color: Color(0xFF2563EB)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Học viên: ${user?.fullName ?? "Học viên hiện tại"} (${user?.userCode ?? "HV"})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Đăng ký 1-chạm: Hồ sơ cá nhân và lịch sử học tập được đồng bộ trực tiếp.',
                                style: TextStyle(fontSize: 11, color: Color(0xFF1D4ED8)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Optional notes
                  TextField(
                    controller: noteCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú thêm cho phòng Đào tạo (nếu có)',
                      hintText: 'VD: Muốn đăng ký học cùng bạn, ca học mong muốn...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.pop(ctx),
              child: const Text('Hủy bỏ'),
            ),
            FilledButton.icon(
              onPressed: submitting
                  ? null
                  : () async {
                      setDialogState(() => submitting = true);
                      try {
                        await _repository.registerStudent(
                          classId: '${offering['id']}',
                          notes: noteCtrl.text.trim(),
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🎉 Gửi đơn đăng ký thành công! Học vụ sẽ xác nhận và cập nhật thời khóa biểu.'),
                            backgroundColor: Color(0xFF0F766E),
                          ),
                        );
                        await _refreshRegistrationsOnly();
                        _tabController.animateTo(1);
                      } catch (error) {
                        setDialogState(() => submitting = false);
                        if (!ctx.mounted) return;
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text('Không thể đăng ký: $error'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
              icon: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(submitting ? 'Đang gửi...' : 'Xác nhận Đăng ký'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = AdaptiveBreakpoints.fromWidth(width) == AdaptiveSize.desktop;
    final user = context.watch<AuthBloc>().state is AuthenticatedState
        ? (context.watch<AuthBloc>().state as AuthenticatedState).user
        : null;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text('Không tải được danh mục: $_errorMessage'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loadAll,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Sub-header navigation with Tabs
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: const Color(0xFF64748B),
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 3,
                    tabs: [
                      const Tab(
                        icon: Icon(Icons.explore_rounded),
                        text: 'Khám phá Khóa học & Lớp mở',
                      ),
                      Tab(
                        icon: const Icon(Icons.assignment_turned_in_rounded),
                        text: 'Đơn đăng ký của tôi (${_myRegistrations.length})',
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Làm mới',
                  onPressed: _loadAll,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDiscoveryTab(isDesktop, user),
                _buildMyRegistrationsTab(isDesktop),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= TAB 1: KHÁM PHÁ & ĐĂNG KÝ =================
  Widget _buildDiscoveryTab(bool isDesktop, UserEntity? user) {
    final recommendation = _detectNextCourseRecommendation();

    // Filter classes
    final query = _searchController.text.trim().toLowerCase();
    final filteredClasses = _classes.where((item) {
      final name = (item['name'] ?? '').toString().toLowerCase();
      final code = (item['code'] ?? '').toString().toLowerCase();
      final course = item['course'] as Map?;
      final courseTitle = (course?['title'] ?? '').toString().toLowerCase();
      final programId = (course?['programId'] ?? (course?['program'] as Map?)?['id'])?.toString();

      final matchesQuery = query.isEmpty ||
          name.contains(query) ||
          code.contains(query) ||
          courseTitle.contains(query);

      final matchesProgram = _selectedProgram == 'ALL' || programId == _selectedProgram;
      final remaining = num.tryParse('${item['remainingSeats']}') ?? 0;
      final matchesSeats = !_onlyAvailable || remaining > 0;

      return matchesQuery && matchesProgram && matchesSeats;
    }).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Next Course Recommendation Banner
          if (recommendation != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recommendation['reason']!,
                          style: const TextStyle(color: Color(0xFFBFDBFE), fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recommendation['courseTitle']!,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '💡 ${recommendation['hint']!}',
                          style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // 2. Search & Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: isDesktop ? 300 : double.infinity,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm khóa học, mã lớp...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                SizedBox(
                  width: isDesktop ? 240 : double.infinity,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedProgram,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Chương trình',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: [
                      const DropdownMenuItem(value: 'ALL', child: Text('Tất cả chương trình')),
                      for (final p in _programs)
                        DropdownMenuItem(
                          value: '${p['id']}',
                          child: Text(
                            '${p['nameVi'] ?? p['nameEn'] ?? p['code']}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedProgram = val);
                    },
                  ),
                ),
                FilterChip(
                  label: const Text('Còn chỗ trống'),
                  selected: _onlyAvailable,
                  onSelected: (val) => setState(() => _onlyAvailable = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Classes Grid
          if (filteredClasses.isEmpty)
            Container(
              padding: const EdgeInsets.all(48),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
                  SizedBox(height: 12),
                  Text(
                    'Không tìm thấy lớp học nào phù hợp.',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Vui lòng thử điều chỉnh bộ lọc hoặc liên hệ học vụ để mở thêm ca học.',
                    style: TextStyle(color: AppColors.textSecondaryLight),
                  ),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = isDesktop ? (constraints.maxWidth - 16) / 2 : double.infinity;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final item in filteredClasses)
                      SizedBox(
                        width: cardWidth,
                        child: _buildClassCard(item, user),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildClassCard(Map<String, dynamic> item, UserEntity? user) {
    final course = item['course'] as Map?;
    final branch = item['branch'] as Map?;
    final room = item['room'] as Map?;
    final price = num.tryParse('${item['tuitionFee']}');
    final start = DateTime.tryParse('${item['startDate']}');
    final remaining = num.tryParse('${item['remainingSeats']}')?.toInt() ?? 0;
    final maxSeats = num.tryParse('${item['maxCapacity'] ?? item['capacity']}')?.toInt() ?? 20;
    final scheduleDays = item['scheduleDays'];
    final scheduleStr = scheduleDays is List ? scheduleDays.join(', ') : '';
    final timeStr = '${item['startTime'] ?? ''} - ${item['endTime'] ?? ''}'.trim();
    final feeFormatted = price == null || price == 0
        ? 'Liên hệ học phí'
        : '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ';

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item['name']}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${course?['title'] ?? ""} • Mã: ${item['code']}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: remaining <= 3 ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Còn $remaining / $maxSeats chỗ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: remaining <= 3 ? const Color(0xFFB91C1C) : const Color(0xFF15803D),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${branch?['name'] ?? ""}${room != null ? " · ${room['name']}" : ""}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${scheduleStr.isNotEmpty ? '$scheduleStr · ' : ''}$timeStr',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            if (start != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text(
                    'Khai giảng: ${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}/${start.year}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  feeFormatted,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                FilledButton.icon(
                  onPressed: remaining > 0 ? () => _showRegisterModal(item, user) : null,
                  icon: const Icon(Icons.touch_app_rounded, size: 18),
                  label: const Text('Đăng ký lớp'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= TAB 2: ĐƠN ĐĂNG KÝ CỦA TÔI =================
  Widget _buildMyRegistrationsTab(bool isDesktop) {
    if (_myRegistrations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inbox_outlined, size: 56, color: Color(0xFF94A3B8)),
              const SizedBox(height: 16),
              const Text(
                'Bạn chưa gửi yêu cầu đăng ký lớp nào.',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              const SizedBox(height: 6),
              const Text(
                'Chuyển sang tab "Khám phá & Đăng ký" để chọn khóa học phù hợp với lộ trình của bạn.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _tabController.animateTo(0),
                icon: const Icon(Icons.explore_rounded),
                label: const Text('Khám phá lớp học ngay'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tiến độ xét duyệt đơn đăng ký của bạn',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Học vụ sẽ đối chiếu lộ trình, kiểm tra số lượng học viên và xác nhận nhập học chính thức.',
                style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
              ),
              const SizedBox(height: 20),
              for (final req in _myRegistrations)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildRegistrationCard(req),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationCard(Map<String, dynamic> req) {
    final status = '${req['status']}';
    final classInfo = req['class'] as Map?;
    final course = classInfo?['course'] as Map?;
    final branch = classInfo?['branch'] as Map?;

    final statusConfig = switch (status) {
      'APPROVED' => (
        'Đã duyệt & Ghi danh',
        const Color(0xFF15803D),
        const Color(0xFFDCFCE7),
        Icons.check_circle_rounded,
        'Yêu cầu đã được học vụ duyệt. Bạn đã là học viên chính thức của lớp này.',
      ),
      'CONTACTED' => (
        'Học vụ đã liên hệ',
        const Color(0xFF1D4ED8),
        const Color(0xFFDBEAFE),
        Icons.phone_in_talk_rounded,
        'Tư vấn viên đã tiếp nhận và liên hệ tư vấn/sắp xếp lịch thi đầu vào.',
      ),
      'REJECTED' => (
        'Từ chối',
        const Color(0xFFB91C1C),
        const Color(0xFFFEE2E2),
        Icons.cancel_rounded,
        'Rất tiếc yêu cầu chưa được chấp thuận do lớp đã đủ sĩ số hoặc không phù hợp lịch.',
      ),
      _ => (
        'Chờ học vụ xử lý',
        const Color(0xFFB45309),
        const Color(0xFFFEF3C7),
        Icons.schedule_rounded,
        'Đơn đang được phòng Đào tạo rà soát hồ sơ và kiểm tra chỗ trống.',
      ),
    };

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${classInfo?['name'] ?? "Lớp học"}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusConfig.$3,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusConfig.$4, size: 14, color: statusConfig.$2),
                      const SizedBox(width: 4),
                      Text(
                        statusConfig.$1,
                        style: TextStyle(
                          color: statusConfig.$2,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${course?['title'] ?? ""} • ${branch?['name'] ?? ""}',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const Divider(height: 20),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    statusConfig.$5,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                  ),
                ),
              ],
            ),
            if (req['notes'] != null && '${req['notes']}'.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Ghi chú của bạn: ${req['notes']}',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF64748B)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
