import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../classes/data/models/class_model.dart';
import '../../../classes/domain/repositories/classes_repository.dart';
import '../../../classes/presentation/bloc/classes_bloc.dart';
import '../../../assignments/data/models/assignment_model.dart';
import '../../../assignments/domain/repositories/assignments_repository.dart';
import '../../../assignments/presentation/bloc/assignments_bloc.dart';

class TeacherGradingView extends StatefulWidget {
  const TeacherGradingView({super.key});

  @override
  State<TeacherGradingView> createState() => _TeacherGradingViewState();
}

class _TeacherGradingViewState extends State<TeacherGradingView> {
  ClassesRepository? _classesRepo;
  AssignmentsRepository? _assignmentsRepo;

  final bool _isLoading = false;
  String? _errorMessage;

  List<ClassModel> _classes = [];
  ClassModel? _selectedClass;
  String _selectedClassKey = 'c1';

  // Active tab: 0 = "Danh sách bài nộp cần chấm", 1 = "Bài đã chấm xong", 2 = "Danh sách đề bài đã giao"
  int _activeTab = 0;
  String _selectedSkill = 'ALL'; // ALL, WRITING, SPEAKING, READING
  final String _searchQuery = '';

  // Active grading student submission (index 0 is selected by default)
  int _selectedSubmissionIndex = 0;

  // 4 IELTS Criteria scores (min 4.0, max 9.0, step 0.5)
  double _scoreTR = 7.5; // Task Response
  double _scoreCC = 7.0; // Coherence & Cohesion
  double _scoreLR = 8.0; // Lexical Resource
  double _scoreGRA = 7.5; // Grammatical Range & Accuracy

  final TextEditingController _feedbackController = TextEditingController(
    text:
        'Bài viết triển khai ý rõ ràng, luận điểm chặt chẽ và từ vựng học thuật phong phú (Band 8.0 LR). Cần chú ý cách dùng thì quá khứ ở đoạn thân bài 2 và kiểm tra lỗi mạo từ.',
  );

  // Demo / Initial submissions matching Stitch specification
  late List<Map<String, dynamic>> _submissions;

  @override
  void initState() {
    super.initState();
    _classesRepo = _resolveClassesRepo();
    _assignmentsRepo = _resolveAssignmentsRepo();
    _initSubmissionsData();
    _loadTeacherClasses();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _initSubmissionsData() {
    _submissions = [
      {
        'stt': '01',
        'studentName': 'Em Lê Minh Khang',
        'studentCode': 'HV-2026-0001',
        'phone': '0933.445.566',
        'avatarText': 'MK',
        'avatarBg': const Color(0xFF2563EB),
        'taskTitle': 'Writing Task 2: Opinion Essay',
        'taskSubtitle': 'Chủ đề: Climate Change Action',
        'fileType': 'PDF',
        'fileMeta': 'PDF • 1.2 MB',
        'fileName': 'MinhKhang_IELTS_Task2.pdf',
        'fileColor': const Color(0xFFEF4444),
        'submittedTime': '08:45 Hôm nay',
        'isOntime': true,
        'timeStatus': 'Đúng hạn',
        'statusText': 'Đang mở chấm',
        'statusColor': const Color(0xFFD97706),
        'statusBg': const Color(0xFFFEF3C7),
        'className': 'Lớp: Lớp IELTS Foundation K01 (IELTS-F-2026-01)',
        'tr': 7.5,
        'cc': 7.0,
        'lr': 8.0,
        'gra': 7.5,
        'feedback':
            'Bài viết của Lê Minh Khang triển khai ý rõ ràng, luận điểm chặt chẽ và từ vựng học thuật phong phú (Band 8.0 LR). Cần chú ý cách dùng thì quá khứ ở đoạn thân bài 2.',
      },
    ];
  }

  ClassesRepository? _resolveClassesRepo() {
    if (getIt.isRegistered<ClassesRepository>()) {
      return getIt<ClassesRepository>();
    }
    if (getIt.isRegistered<ClassesBloc>()) {
      return getIt<ClassesBloc>().repository;
    }
    return null;
  }

  AssignmentsRepository? _resolveAssignmentsRepo() {
    if (getIt.isRegistered<AssignmentsRepository>()) {
      return getIt<AssignmentsRepository>();
    }
    if (getIt.isRegistered<AssignmentsBloc>()) {
      return getIt<AssignmentsBloc>().repository;
    }
    return null;
  }

  Future<void> _loadTeacherClasses() async {
    if (_classesRepo == null) return;
    try {
      final classes = await _classesRepo!.getMyClasses();
      if (mounted && classes.isNotEmpty) {
        setState(() {
          _classes = classes;
          _selectedClass = classes.first;
        });
      }
    } catch (_) {}
  }

  double _calculateOverallBand() {
    final avg = (_scoreTR + _scoreCC + _scoreLR + _scoreGRA) / 4.0;
    // Round to nearest 0.5
    return (avg * 2).round() / 2.0;
  }

  void _selectSubmission(int index) {
    if (index >= 0 && index < _submissions.length) {
      setState(() {
        _selectedSubmissionIndex = index;
        final item = _submissions[index];
        _scoreTR = (item['tr'] as num?)?.toDouble() ?? 7.0;
        _scoreCC = (item['cc'] as num?)?.toDouble() ?? 7.0;
        _scoreLR = (item['lr'] as num?)?.toDouble() ?? 7.0;
        _scoreGRA = (item['gra'] as num?)?.toDouble() ?? 7.0;
        _feedbackController.text = (item['feedback'] as String?) ?? '';
      });
    }
  }

  void _saveGrades() {
    final current = _submissions[_selectedSubmissionIndex];
    final overall = _calculateOverallBand();
    setState(() {
      current['tr'] = _scoreTR;
      current['cc'] = _scoreCC;
      current['lr'] = _scoreLR;
      current['gra'] = _scoreGRA;
      current['feedback'] = _feedbackController.text;
      current['statusText'] = 'Đã chấm (Band $overall)';
      current['statusColor'] = const Color(0xFF10B981);
      current['statusBg'] = const Color(0xFFDCFCE7);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã lưu điểm Band $overall và gửi nhận xét đến học viên ${current['studentName']} thành công!',
        ),
        backgroundColor: const Color(0xFF003FB1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _nextSubmission() {
    if (_selectedSubmissionIndex + 1 < _submissions.length) {
      _selectSubmission(_selectedSubmissionIndex + 1);
    } else {
      _selectSubmission(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 960;
    final currentStudent = _submissions[_selectedSubmissionIndex];
    final overallBand = _calculateOverallBand();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 24 : 16,
          vertical: 20,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Breadcrumb & Page Heading
                _buildBreadcrumbAndHeader(isDesktop),
                const SizedBox(height: 20),

                // 2. Four Quick Stat Cards
                _buildStatCardsGrid(isDesktop),
                const SizedBox(height: 20),

                // 3. Filters & Tab Row
                _buildFilterAndTabsBar(isDesktop),
                const SizedBox(height: 24),

                // 4. Main 2-Column Layout (Left 60% Submissions, Right 40% Grading)
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Submissions Table (~62%)
                      Expanded(
                        flex: 62,
                        child: _buildSubmissionsTableCard(),
                      ),
                      const SizedBox(width: 24),
                      // Interactive Grading Card (~38%)
                      Expanded(
                        flex: 38,
                        child: _buildInteractiveGradingCard(
                          currentStudent,
                          overallBand,
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildInteractiveGradingCard(
                        currentStudent,
                        overallBand,
                      ),
                      const SizedBox(height: 20),
                      _buildSubmissionsTableCard(),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 1. BREADCRUMB & PAGE HEADING ---
  Widget _buildBreadcrumbAndHeader(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Trang chủ',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
            SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 14, color: Color(0xFF94A3B8)),
            SizedBox(width: 4),
            Text(
              'Bài tập & Chấm bài',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quản Lý Bài Tập & Cổng Chấm Bài Trực Tuyến',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.4,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Theo dõi bài nộp của học viên, chấm điểm theo tiêu chí IELTS/TOEIC và nhận xét phản hồi chi tiết.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            if (isDesktop) ...[
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.table_view_outlined, size: 16),
                label: const Text('Xuất bảng điểm (Excel)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF334155),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Be Vietnam Pro',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _showCreateAssignmentDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('+ Tạo bài tập mới'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003FB1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Be Vietnam Pro',
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // --- 2. FOUR QUICK STAT CARDS ---
  Widget _buildStatCardsGrid(bool isDesktop) {
    final totalSubmissions = _submissions.length;
    final gradedCount = _submissions
        .where((s) => (s['statusText'] as String).startsWith('Đã chấm'))
        .length;
    final pendingCount = totalSubmissions - gradedCount;
    final activeClassesCount = _classes.isNotEmpty ? _classes.length : 2;

    final cards = [
      _buildKpiCard(
        title: 'Tổng bài tập đã giao',
        value: '$totalSubmissions bài',
        subtitle: 'Áp dụng cho $activeClassesCount lớp học hệ thống',
        icon: Icons.assignment_outlined,
        iconBgColor: const Color(0xFFEFF6FF),
        iconColor: const Color(0xFF003FB1),
      ),
      _buildKpiCard(
        title: 'Bài nộp cần chấm ngay',
        value: '$pendingCount bài',
        subtitle: pendingCount > 0 ? 'Có bài nộp mới chờ duyệt' : 'Đã chấm hết bài nộp',
        isPing: pendingCount > 0,
        icon: Icons.rate_review,
        iconBgColor: const Color(0xFFFEF3C7),
        iconColor: const Color(0xFFD97706),
      ),
      _buildKpiCard(
        title: 'Đã hoàn thành chấm',
        value: '$gradedCount bài',
        subtitle:
            'Tỷ lệ hoàn thành ${totalSubmissions > 0 ? (gradedCount / totalSubmissions * 100).toStringAsFixed(1) : "0.0"}%',
        icon: Icons.check_circle_outline,
        iconBgColor: const Color(0xFFECFDF5),
        iconColor: const Color(0xFF059669),
      ),
      _buildKpiCard(
        title: 'Chưa nộp / Quá hạn',
        value: '0 học viên',
        subtitle: '100% học viên nộp đúng hạn',
        icon: Icons.pending_actions_outlined,
        iconBgColor: const Color(0xFFFEF2F2),
        iconColor: const Color(0xFFDC2626),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return Row(
            children: cards
                .map((c) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: c,
                      ),
                    ))
                .toList(),
          );
        } else if (constraints.maxWidth > 600) {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards
                .map((c) => SizedBox(
                      width: (constraints.maxWidth - 12) / 2,
                      child: c,
                    ))
                .toList(),
          );
        } else {
          return Column(
            children: cards
                .map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: c,
                    ))
                .toList(),
          );
        }
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    bool isPing = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    if (isPing) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isPing ? const Color(0xFFB45309) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
        ],
      ),
    );
  }

  // --- 3. FILTERS & TAB ROW ---
  Widget _buildFilterAndTabsBar(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Filter tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFilterTabButton(
                  title: 'Danh sách bài nộp cần chấm',
                  count: '${_submissions.where((s) => !(s['statusText'] as String).startsWith('Đã chấm')).length}',
                  index: 0,
                ),
                const SizedBox(width: 6),
                _buildFilterTabButton(
                  title: 'Bài đã chấm xong',
                  count: '${_submissions.where((s) => (s['statusText'] as String).startsWith('Đã chấm')).length}',
                  index: 1,
                ),
                const SizedBox(width: 6),
                _buildFilterTabButton(
                  title: 'Danh sách đề bài đã giao',
                  count: '${_submissions.length}',
                  index: 2,
                ),
              ],
            ),
          ),

          // Selectors
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Class dropdown
              Builder(
                builder: (context) {
                  final hasLiveClasses = _classes.isNotEmpty;
                  final dropdownItems = hasLiveClasses
                      ? _classes
                          .map(
                            (c) => DropdownMenuItem<String>(
                              value: c.id,
                              child: Text('Lớp: ${c.name} (${c.code})'),
                            ),
                          )
                          .toList()
                      : const [
                          DropdownMenuItem(
                            value: 'c1',
                            child: Text('Lớp: IELTS Fighter B2 (IELTS-F-01)'),
                          ),
                          DropdownMenuItem(
                            value: 'c2',
                            child: Text('Lớp: Luyện thi TOEIC 650+ Intensive'),
                          ),
                          DropdownMenuItem(
                            value: 'c3',
                            child: Text('Lớp: Tiếng Anh Giao Tiếp Pro K28'),
                          ),
                          DropdownMenuItem(
                            value: 'c4',
                            child: Text('Lớp: IELTS Master 7.0+ Target'),
                          ),
                        ];
                  final availableValues = dropdownItems
                      .map((e) => e.value)
                      .whereType<String>()
                      .toSet();
                  final rawValue = _selectedClass?.id ?? _selectedClassKey;
                  final safeValue = availableValues.contains(rawValue)
                      ? rawValue
                      : dropdownItems.first.value!;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: safeValue,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                          fontFamily: 'Be Vietnam Pro',
                        ),
                        items: dropdownItems,
                        onChanged: (val) {
                          if (val == null) return;
                          setState(() {
                            _selectedClassKey = val;
                            if (hasLiveClasses) {
                              _selectedClass = _classes.firstWhere(
                                (c) => c.id == val,
                                orElse: () => _classes.first,
                              );
                            }
                          });
                        },
                      ),
                    ),
                  );
                },
              ),

              // Skill dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedSkill,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                      fontFamily: 'Be Vietnam Pro',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'ALL',
                        child: Text('Tất cả kỹ năng (Writing, Speaking, Reading)'),
                      ),
                      DropdownMenuItem(
                        value: 'WRITING',
                        child: Text('Kỹ năng: Writing (Task 1 & Task 2)'),
                      ),
                      DropdownMenuItem(
                        value: 'SPEAKING',
                        child: Text('Kỹ năng: Speaking Audio (Ghi âm MP3)'),
                      ),
                      DropdownMenuItem(
                        value: 'READING',
                        child: Text('Kỹ năng: Reading & Listening Test'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedSkill = val);
                    },
                  ),
                ),
              ),

              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã cập nhật danh sách bài nộp mới nhất.'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.refresh, size: 18),
                color: const Color(0xFF64748B),
                tooltip: 'Làm mới danh sách',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabButton({
    required String title,
    required String count,
    required int index,
  }) {
    final isActive = _activeTab == index;
    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF003FB1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? Colors.white : const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withValues(alpha: 0.2)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                count,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 4. SUBMISSIONS TABLE CARD (Left 60%) ---
  Widget _buildSubmissionsTableCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Danh Sách Bài Nộp Chờ Chấm Điểm',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Text(
                        '14 bài mới nộp',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
                const Text(
                  'Sắp xếp: Mới nộp nhất',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Table content
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 64,
              dataRowMaxHeight: 68,
              horizontalMargin: 16,
              columnSpacing: 18,
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              columns: const [
                DataColumn(
                  label: Text(
                    'STT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'HỌC VIÊN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'TÊN BÀI TẬP & KỸ NĂNG',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'ĐỊNH DẠNG FILE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'THỜI GIAN NỘP',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'TRẠNG THÁI',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'THAO TÁC',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
              rows: _submissions.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = _selectedSubmissionIndex == index;

                return DataRow(
                  selected: isSelected,
                  color: WidgetStateProperty.resolveWith<Color?>((states) {
                    if (isSelected) return const Color(0xFFEFF6FF);
                    return null;
                  }),
                  cells: [
                    // STT
                    DataCell(
                      Text(
                        item['stt'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? const Color(0xFF003FB1) : const Color(0xFF64748B),
                        ),
                      ),
                    ),

                    // Học viên
                    DataCell(
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: item['avatarBg'],
                            child: Text(
                              item['avatarText'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item['studentName'],
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                item['phone'],
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () => _selectSubmission(index),
                    ),

                    // Tên bài tập
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item['taskTitle'],
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            item['taskSubtitle'],
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF003FB1),
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _selectSubmission(index),
                    ),

                    // Định dạng file
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: (item['fileColor'] as Color).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: (item['fileColor'] as Color).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item['fileType'] == 'PDF'
                                  ? Icons.picture_as_pdf
                                  : item['fileType'] == 'AUDIO'
                                      ? Icons.graphic_eq
                                      : Icons.description,
                              size: 13,
                              color: item['fileColor'],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item['fileMeta'],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: item['fileColor'],
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () => _selectSubmission(index),
                    ),

                    // Thời gian nộp
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item['submittedTime'],
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            item['timeStatus'],
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: item['isOntime']
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _selectSubmission(index),
                    ),

                    // Trạng thái
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: item['statusBg'],
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          item['statusText'],
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: item['statusColor'],
                          ),
                        ),
                      ),
                      onTap: () => _selectSubmission(index),
                    ),

                    // Thao tác
                    DataCell(
                      ElevatedButton(
                        onPressed: () => _selectSubmission(index),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected
                              ? const Color(0xFF003FB1)
                              : Colors.white,
                          foregroundColor: isSelected
                              ? Colors.white
                              : const Color(0xFF003FB1),
                          side: isSelected
                              ? BorderSide.none
                              : const BorderSide(color: Color(0xFF003FB1)),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Be Vietnam Pro',
                          ),
                        ),
                        child: Text(isSelected ? 'Đang chấm' : 'Chấm ngay'),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),

          // Pagination footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Hiển thị 5 trên tổng số 14 bài nộp chờ chấm',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: null,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Trước', style: TextStyle(fontSize: 11)),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003FB1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('1', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 4),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('2', style: TextStyle(fontSize: 11)),
                    ),
                    const SizedBox(width: 4),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Sau', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 5. INTERACTIVE GRADING CARD (Right 40%) ---
  Widget _buildInteractiveGradingCard(
    Map<String, dynamic> student,
    double overallBand,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Gradient
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F2B5C), Color(0xFF003FB1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.edit_note, color: Color(0xFF93C5FD), size: 18),
                        SizedBox(width: 6),
                        Text(
                          'GIAO DIỆN CHẤM ĐIỂM TRỰC TIẾP',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFBFDBFE),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Text(
                        'Đang chấm',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                student['studentName'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '(${student['studentCode']})',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFFBFDBFE),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            student['className'],
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Overall band score badge
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Tổng kết dự kiến',
                          style: TextStyle(fontSize: 10, color: Color(0xFFBFDBFE)),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            'Band $overallBand',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Submitted File Preview Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      student['fileType'] == 'PDF'
                          ? Icons.picture_as_pdf
                          : student['fileType'] == 'AUDIO'
                              ? Icons.graphic_eq
                              : Icons.description,
                      size: 18,
                      color: student['fileColor'],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      student['fileName'],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đang mở file ${student['fileName']}...'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 14),
                  label: const Text('Xem bài làm chi tiết'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF003FB1),
                    textStyle: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Be Vietnam Pro',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4 IELTS Criteria Sliders
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '4 TIÊU CHÍ CHẤM IELTS WRITING/SPEAKING',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 13, color: Color(0xFF003FB1)),
                        SizedBox(width: 4),
                        Text(
                          'AI Scoring hỗ trợ',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003FB1),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Criterion 1: Task Response (TR)
                _buildCriterionSlider(
                  label: '1. Task Response (TR)',
                  description: 'Luận điểm đầy đủ, giải quyết trọn vẹn yêu cầu',
                  value: _scoreTR,
                  color: const Color(0xFF003FB1),
                  onChanged: (val) => setState(() => _scoreTR = val),
                ),
                const SizedBox(height: 12),

                // Criterion 2: Coherence & Cohesion (CC)
                _buildCriterionSlider(
                  label: '2. Coherence & Cohesion (CC)',
                  description: 'Chuyển đoạn logic, liên kết câu mượt mà',
                  value: _scoreCC,
                  color: const Color(0xFF003FB1),
                  onChanged: (val) => setState(() => _scoreCC = val),
                ),
                const SizedBox(height: 12),

                // Criterion 3: Lexical Resource (LR)
                _buildCriterionSlider(
                  label: '3. Lexical Resource (LR)',
                  description: 'Từ vựng phong phú, sử dụng idioms tự nhiên',
                  value: _scoreLR,
                  color: const Color(0xFF059669),
                  onChanged: (val) => setState(() => _scoreLR = val),
                ),
                const SizedBox(height: 12),

                // Criterion 4: Grammatical Range & Accuracy (GRA)
                _buildCriterionSlider(
                  label: '4. Grammatical Range & Accuracy (GRA)',
                  description: 'Cấu trúc câu phức chính xác, ít lỗi nhỏ',
                  value: _scoreGRA,
                  color: const Color(0xFF003FB1),
                  onChanged: (val) => setState(() => _scoreGRA = val),
                ),

                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 14),

                // Teacher Feedback Textarea
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nhận xét chi tiết của Giảng viên *',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Học viên sẽ nhận qua Portal & Email',
                      style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _feedbackController,
                  maxLines: 3,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Color(0xFF1E293B),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Nhập phản hồi, lỗi cần sửa và lời khuyên cho học viên...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF003FB1)),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 8),

                // Quick Comment Tags
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildQuickTag('+ Luận điểm tốt'),
                    _buildQuickTag('+ Từ vựng phong phú'),
                    _buildQuickTag('+ Cần rà soát thì động từ'),
                    _buildQuickTag('+ Ý tưởng sáng tạo'),
                  ],
                ),
                const SizedBox(height: 20),

                // Submission Action Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveGrades,
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text('Lưu điểm & Gửi nhận xét cho học viên'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003FB1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(64, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Be Vietnam Pro',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã lưu bản nháp điểm thành công.'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF334155),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Be Vietnam Pro',
                          ),
                        ),
                        child: const Text('Lưu nháp điểm'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _nextSubmission,
                        icon: const Icon(Icons.skip_next, size: 16),
                        label: const Text('Chuyển bài kế tiếp'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF334155),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Be Vietnam Pro',
                          ),
                        ),
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
  }

  Widget _buildCriterionSlider({
    required String label,
    required String description,
    required double value,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Text(
                '${value.toStringAsFixed(1)} / 9.0',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: const Color(0xFFE2E8F0),
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.12),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            min: 4.0,
            max: 9.0,
            divisions: 10,
            value: value,
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Band 4.0',
              style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
            ),
            Text(
              description,
              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
            ),
            const Text(
              'Band 9.0',
              style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickTag(String tagText) {
    return InkWell(
      onTap: () {
        setState(() {
          _feedbackController.text =
              '${_feedbackController.text.trim()} ${tagText.replaceAll('+', '')}.';
        });
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          tagText,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  // --- 6. DIALOG: CREATE NEW ASSIGNMENT ---
  void _showCreateAssignmentDialog() {
    final titleCtrl = TextEditingController();
    final promptCtrl = TextEditingController();
    String skillType = 'WRITING';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text(
              'Giao bài tập mới cho lớp học',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Color(0xFF0F172A),
              ),
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tiêu đề bài tập *',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        hintText: 'Ví dụ: Writing Task 2 - Technology in Education',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text('Kỹ năng rèn luyện',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Writing (Viết luận)', style: TextStyle(fontSize: 12)),
                            value: 'WRITING',
                            groupValue: skillType,
                            onChanged: (v) => setDialogState(() => skillType = v!),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Speaking (Ghi âm MP3)', style: TextStyle(fontSize: 12)),
                            value: 'SPEAKING',
                            groupValue: skillType,
                            onChanged: (v) => setDialogState(() => skillType = v!),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    const Text('Đề bài & Yêu cầu học viên *',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: promptCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Nhập đề bài, số từ tối thiểu hoặc câu hỏi cue card Speaking...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Hạn nộp bài',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.calendar_month, size: 16, color: Color(0xFF003FB1)),
                                    SizedBox(width: 6),
                                    Text('28/10/2026 23:59',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Thang điểm',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: const Text(
                                  'IELTS Band (0.0 - 9.0)',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy bỏ'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (titleCtrl.text.isEmpty) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã tạo và giao bài tập "${titleCtrl.text}" thành công!'),
                      backgroundColor: const Color(0xFF003FB1),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003FB1),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Giao bài tập ngay'),
              ),
            ],
          );
        },
      ),
    );
  }
}
