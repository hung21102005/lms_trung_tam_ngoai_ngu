import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../classes/presentation/bloc/classes_bloc.dart';
import '../../../classes/presentation/bloc/classes_event.dart';
import '../../../classes/data/models/class_model.dart';
import '../../../reports/presentation/bloc/reports_bloc.dart';

class TeacherGradebookView extends StatelessWidget {
  const TeacherGradebookView({super.key});

  @override
  Widget build(BuildContext context) {
    Widget content = const _TeacherGradebookViewContent();
    bool hasClassesBloc = false;
    try {
      context.read<ClassesBloc>();
      hasClassesBloc = true;
    } catch (_) {
      hasClassesBloc = false;
    }

    bool hasReportsBloc = false;
    try {
      context.read<ReportsBloc>();
      hasReportsBloc = true;
    } catch (_) {
      hasReportsBloc = false;
    }

    if (!hasClassesBloc && getIt.isRegistered<ClassesBloc>()) {
      content = BlocProvider<ClassesBloc>(
        create: (_) => getIt<ClassesBloc>()..add(const FetchMyClasses()),
        child: content,
      );
    }
    if (!hasReportsBloc && getIt.isRegistered<ReportsBloc>()) {
      content = BlocProvider<ReportsBloc>(
        create: (_) => getIt<ReportsBloc>(),
        child: content,
      );
    }
    return content;
  }
}

class _TeacherGradebookViewContent extends StatefulWidget {
  const _TeacherGradebookViewContent();

  @override
  State<_TeacherGradebookViewContent> createState() =>
      _TeacherGradebookViewContentState();
}

class _TeacherGradebookViewContentState
    extends State<_TeacherGradebookViewContent> {
  String _selectedClassId = 'c1';
  String _selectedExamPeriod = 'MIDTERM';
  String _selectedGradingScale = 'IELTS';
  int _activeFilterTab =
      0; // 0 = Tất cả (16), 1 = Đạt mục tiêu (14), 2 = Cần cải thiện (2)
  String _searchQuery = '';

  late List<Map<String, dynamic>> _students;

  @override
  void initState() {
    super.initState();
    _initGradebookData();
    try {
      context.read<ClassesBloc>().add(const FetchMyClasses());
    } catch (_) {}
  }

  void _initGradebookData() {
    _students = [
      {
        'stt': '01',
        'id': 'HV-2026-0001',
        'name': 'Em Lê Minh Khang',
        'phone': '0933.445.566',
        'avatar': 'MK',
        'avatarBg': const Color(0xFF2563EB),
        'attendance': 100.0,
        'homework': 8.5,
        'listening': 7.5,
        'reading': 7.0,
        'writing': 7.0,
        'speaking': 7.5,
        'overall': 7.5,
        'classification': 'Xuất sắc',
        'classifColor': const Color(0xFF059669),
        'classifBg': const Color(0xFFECFDF5),
        'notes': 'Học viên chính thức lớp IELTS Foundation K01. Nắm vững cấu trúc Essay Task 2, phản xạ Speaking tự nhiên.',
      },
    ];
  }

  List<Map<String, dynamic>> _getFilteredStudents() {
    return _students.where((s) {
      if (_activeFilterTab == 1 && (s['overall'] as double) < 6.0) {
        return false;
      }
      if (_activeFilterTab == 2 && (s['overall'] as double) >= 6.0) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = (s['name'] as String).toLowerCase();
        final id = (s['id'] as String).toLowerCase();
        return name.contains(q) || id.contains(q);
      }
      return true;
    }).toList();
  }

  void _showEditScoreModal(Map<String, dynamic> student) {
    final listenCtrl = TextEditingController(
      text: student['listening'].toString(),
    );
    final readCtrl = TextEditingController(text: student['reading'].toString());
    final writeCtrl = TextEditingController(
      text: student['writing'].toString(),
    );
    final speakCtrl = TextEditingController(
      text: student['speaking'].toString(),
    );
    final hwCtrl = TextEditingController(text: student['homework'].toString());
    final noteCtrl = TextEditingController(text: student['notes'].toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: student['avatarBg'],
              child: Text(
                student['avatar'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cập nhật điểm: ${student['name']}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Mã HV: ${student['id']} • Lớp IELTS Fighter B2',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Điểm 4 kỹ năng IELTS (Thang 0.0 - 9.0)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003FB1),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildScoreInputField('Listening', listenCtrl),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _buildScoreInputField('Reading', readCtrl)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildScoreInputField('Writing', writeCtrl),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildScoreInputField('Speaking', speakCtrl),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Điểm bài tập về nhà (10%)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                _buildScoreInputField('Homework Score (0 - 10)', hwCtrl),
                const SizedBox(height: 14),
                const Text(
                  'Nhận xét đánh giá của Giảng viên *',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final l =
                  double.tryParse(listenCtrl.text) ?? student['listening'];
              final r = double.tryParse(readCtrl.text) ?? student['reading'];
              final w = double.tryParse(writeCtrl.text) ?? student['writing'];
              final s = double.tryParse(speakCtrl.text) ?? student['speaking'];
              final hw = double.tryParse(hwCtrl.text) ?? student['homework'];
              final overall = ((l + r + w + s) / 4.0 * 2).round() / 2.0;

              setState(() {
                student['listening'] = l;
                student['reading'] = r;
                student['writing'] = w;
                student['speaking'] = s;
                student['homework'] = hw;
                student['overall'] = overall;
                student['notes'] = noteCtrl.text;
                if (overall >= 7.5) {
                  student['classification'] = 'Xuất sắc';
                  student['classifColor'] = const Color(0xFF059669);
                  student['classifBg'] = const Color(0xFFECFDF5);
                } else if (overall >= 6.5) {
                  student['classification'] = 'Giỏi';
                  student['classifColor'] = const Color(0xFF003FB1);
                  student['classifBg'] = const Color(0xFFEFF6FF);
                } else if (overall >= 6.0) {
                  student['classification'] = 'Khá';
                  student['classifColor'] = const Color(0xFF4F46E5);
                  student['classifBg'] = const Color(0xFFEEF2FF);
                } else {
                  student['classification'] = 'Cần cố gắng';
                  student['classifColor'] = const Color(0xFFD97706);
                  student['classifBg'] = const Color(0xFFFEF3C7);
                }
              });

              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Đã cập nhật điểm cho học viên ${student['name']} (Overall Band $overall)!',
                  ),
                  backgroundColor: const Color(0xFF003FB1),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003FB1),
              foregroundColor: Colors.white,
            ),
            child: const Text('Lưu điểm ngay'),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreInputField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
          ),
        ),
      ],
    );
  }

  void _sendReportsToParents() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.forward_to_inbox, color: Color(0xFF003FB1)),
            SizedBox(width: 8),
            Text('Gửi học bạ đến Phụ huynh'),
          ],
        ),
        content: const Text(
          'Hệ thống sẽ tự động tổng hợp bảng điểm, nhận xét học lực của 16 học viên lớp IELTS Fighter B2 và gửi thông báo qua Zalo ZNS / Ứng dụng Phụ huynh. Bạn có chắc chắn muốn phát hành?',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Đã gửi học bạ điện tử tới 16 phụ huynh học viên thành công!',
                  ),
                  backgroundColor: Color(0xFF003FB1),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003FB1),
              foregroundColor: Colors.white,
            ),
            child: const Text('Gửi ngay'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 960;
    final filteredList = _getFilteredStudents();

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
                // 1. Breadcrumb & Title Section
                _buildHeaderSection(isDesktop),
                const SizedBox(height: 20),

                // 2. Filter & Selector Toolbar
                _buildFilterToolbar(isDesktop),
                const SizedBox(height: 20),

                // 3. Four Overview Metric Cards
                _buildOverviewMetrics(isDesktop),
                const SizedBox(height: 24),

                // 4. Gradebook Table Card
                _buildGradebookTableCard(filteredList),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 1. HEADER SECTION ---
  Widget _buildHeaderSection(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Trang chủ',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
            SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 14, color: Color(0xFF94A3B8)),
            SizedBox(width: 4),
            Text(
              'Bảng điểm & Đánh giá',
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
                    'Sổ Điểm Lớp Học & Đánh Giá Năng Lực Học Viên',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.4,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Theo dõi điểm quá trình, điểm thi 4 kỹ năng (IELTS Listening, Reading, Writing, Speaking), nhận xét học lực và xuất học bạ.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            if (isDesktop) ...[
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: _sendReportsToParents,
                icon: const Icon(Icons.forward_to_inbox, size: 16),
                label: const Text('Gửi học bạ đến Phụ huynh'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF334155),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
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
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đang xuất sổ điểm lớp ra file Excel...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.description,
                  size: 16,
                  color: Color(0xFF059669),
                ),
                label: const Text('Xuất bảng điểm (Excel)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF334155),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mở giao diện nhập điểm đợt thi mới.'),
                    ),
                  );
                },
                icon: const Icon(Icons.add_circle_outline, size: 16),
                label: const Text('+ Nhập điểm đợt thi mới'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003FB1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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

  // --- 2. FILTER & SELECTOR TOOLBAR ---
  Widget _buildFilterToolbar(bool isDesktop) {
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
      child: Wrap(
        spacing: 16,
        runSpacing: 14,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 12,
            children: [
              // Class dropdown
              SizedBox(
                width: isDesktop ? 300 : MediaQuery.sizeOf(context).width - 64,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LỚP GIẢNG DẠY',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 5),
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
                          value: _selectedClassId,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            fontFamily: 'Be Vietnam Pro',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'c1',
                              child: Text('Lớp IELTS Fighter B2 (IELTS-F-01)'),
                            ),
                            DropdownMenuItem(
                              value: 'c2',
                              child: Text('Lớp IELTS Master 6.5+ (IELTS-M-04)'),
                            ),
                            DropdownMenuItem(
                              value: 'c3',
                              child: Text(
                                'Lớp General Communication A2 (GEN-A2-02)',
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'c4',
                              child: Text('Lớp IELTS Intensive (IELTS-INT-09)'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedClassId = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Exam Period
              SizedBox(
                width: isDesktop ? 300 : MediaQuery.sizeOf(context).width - 64,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'KỲ THI / ĐỢT ĐÁNH GIÁ',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 5),
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
                          value: _selectedExamPeriod,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                            fontFamily: 'Be Vietnam Pro',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'MIDTERM',
                              child: Text(
                                'Kiểm tra Giữa kỳ (Mid-term - T10/2026)',
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'TEST09',
                              child: Text('Bài Test Đánh giá tháng 09/2026'),
                            ),
                            DropdownMenuItem(
                              value: 'TEST08',
                              child: Text('Bài Test Đánh giá tháng 08/2026'),
                            ),
                            DropdownMenuItem(
                              value: 'PLACEMENT',
                              child: Text('Bài thi Đầu vào (Placement Test)'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedExamPeriod = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Grading scale
              SizedBox(
                width: isDesktop ? 300 : MediaQuery.sizeOf(context).width - 64,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'THANG ĐIỂM CHUẨN',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 5),
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
                          value: _selectedGradingScale,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                            fontFamily: 'Be Vietnam Pro',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'IELTS',
                              child: Text('IELTS Band Score (0.0 - 9.0)'),
                            ),
                            DropdownMenuItem(
                              value: 'MOET',
                              child: Text('Thang điểm 10 chuẩn Bộ GD&ĐT'),
                            ),
                            DropdownMenuItem(
                              value: 'PERCENT',
                              child: Text('Thang điểm 100 quy đổi'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedGradingScale = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Actions right
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã lưu toàn bộ điểm thay đổi tạm thời!'),
                      backgroundColor: Color(0xFF003FB1),
                    ),
                  );
                },
                icon: const Icon(Icons.save_outlined, size: 15),
                label: const Text('Lưu thay đổi tạm thời'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEFF6FF),
                  foregroundColor: const Color(0xFF003FB1),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Be Vietnam Pro',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Đã khóa sổ điểm. Điểm số sẽ không thể sửa đổi nếu chưa mở khóa.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.lock_outline, size: 15),
                label: const Text('Khóa sổ điểm'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF475569),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
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
            ],
          ),
        ],
      ),
    );
  }

  // --- 3. FOUR OVERVIEW METRIC CARDS ---
  Widget _buildOverviewMetrics(bool isDesktop) {
    final total = _students.length;
    final avgBand = total > 0
        ? _students.fold<double>(
                0.0,
                (s, st) => s + (st['overall'] as double),
              ) /
              total
        : 0.0;
    final passedCount = _students
        .where((s) => (s['overall'] as double) >= 6.0)
        .length;
    final needHelpCount = total - passedCount;
    final passRate = total > 0 ? passedCount / total : 0.0;
    final topStudent = _students.isNotEmpty ? _students.first : null;

    final cards = [
      _buildKpiCard(
        title: 'Điểm TB toàn lớp',
        value: 'Band ${avgBand.toStringAsFixed(1)}',
        subtitle: 'Tính trên $total học viên chính thức',
        isPositive: true,
        icon: Icons.bar_chart_rounded,
        iconBg: const Color(0xFFEFF6FF),
        iconColor: const Color(0xFF003FB1),
      ),
      _buildKpiCard(
        title: 'Điểm cao nhất đợt thi',
        value: 'Band ${topStudent?['overall'] ?? 0.0}',
        subtitle: topStudent != null
            ? 'Học viên: ${topStudent['name']} (${topStudent['id']})'
            : 'Chưa có học viên',
        valueColor: const Color(0xFFB45309),
        icon: Icons.military_tech,
        iconBg: const Color(0xFFFEF3C7),
        iconColor: const Color(0xFFD97706),
      ),
      _buildProgressKpiCard(
        title: 'Tỷ lệ đạt mục tiêu (≥6.0)',
        value: '${(passRate * 100).toStringAsFixed(1)}%',
        fractionText: '$passedCount/$total học viên',
        progress: passRate,
        icon: Icons.check_circle_outline,
        iconBg: const Color(0xFFECFDF5),
        iconColor: const Color(0xFF059669),
      ),
      _buildKpiCard(
        title: 'Học viên cần phụ đạo',
        value: '$needHelpCount học viên',
        subtitle: needHelpCount > 0
            ? 'Band < 6.0 (Cần kèm Writing/Speaking)'
            : 'Tất cả học viên đạt chuẩn đầu ra',
        valueColor: needHelpCount > 0
            ? const Color(0xFFDC2626)
            : const Color(0xFF059669),
        isAlertTag: needHelpCount > 0,
        icon: Icons.warning_amber_rounded,
        iconBg: const Color(0xFFFEF2F2),
        iconColor: const Color(0xFFDC2626),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return Row(
            children: cards
                .map(
                  (c) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: c,
                    ),
                  ),
                )
                .toList(),
          );
        } else if (constraints.maxWidth > 600) {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards
                .map(
                  (c) => SizedBox(
                    width: (constraints.maxWidth - 12) / 2,
                    child: c,
                  ),
                )
                .toList(),
          );
        } else {
          return Column(
            children: cards
                .map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: c,
                  ),
                )
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
    Color? valueColor,
    bool isPositive = false,
    bool isAlertTag = false,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: valueColor ?? const Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          if (isAlertTag)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF92400E),
                ),
              ),
            )
          else if (isPositive)
            Row(
              children: [
                const Icon(
                  Icons.trending_up,
                  size: 14,
                  color: Color(0xFF059669),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF059669),
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildProgressKpiCard({
    required String title,
    required String value,
    required String fractionText,
    required double progress,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
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
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                fractionText,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF059669),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. GRADEBOOK TABLE CARD ---
  Widget _buildGradebookTableCard(List<Map<String, dynamic>> students) {
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
          // Table header & filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Danh Sách Điểm Chi Tiết Học Viên',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    // Filter tabs
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildTableFilterTab(
                              'Tất cả (${_students.length} học viên)',
                              0,
                            ),
                            _buildTableFilterTab(
                              'Đạt mục tiêu (${_students.where((s) => (s['overall'] as double) >= 6.0).length})',
                              1,
                            ),
                            _buildTableFilterTab(
                              'Cần cải thiện (${_students.where((s) => (s['overall'] as double) < 6.0).length})',
                              2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Search input inside
                SizedBox(
                  width: 240,
                  height: 36,
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Tìm theo tên, mã học viên...',
                      hintStyle: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF94A3B8),
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 16,
                        color: Color(0xFF94A3B8),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Main Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 60,
              dataRowMaxHeight: 66,
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
                    'MÃ HV & HỌC VIÊN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'CHUYÊN CẦN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'BTVN (10%)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'LISTENING',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'READING',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'WRITING',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'SPEAKING',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'OVERALL BAND',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'XẾP LOẠI',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'NHẬN XÉT GIẢNG VIÊN',
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
              rows: students.map((s) {
                final isWarning = (s['overall'] as double) < 6.0;

                return DataRow(
                  color: WidgetStateProperty.resolveWith<Color?>((states) {
                    if (isWarning) {
                      return const Color(0xFFFEF3C7).withValues(alpha: 0.2);
                    }
                    return null;
                  }),
                  cells: [
                    // STT
                    DataCell(
                      Text(
                        s['stt'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),

                    // MÃ HV & HỌC VIÊN
                    DataCell(
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: s['avatarBg'],
                            child: Text(
                              s['avatar'],
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
                                s['name'],
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                '${s['id']} • ${s['phone']}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // CHUYÊN CẦN
                    DataCell(
                      Center(
                        child: Text(
                          '${s['attendance']}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: (s['attendance'] as double) < 80.0
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF059669),
                          ),
                        ),
                      ),
                    ),

                    // BTVN (10%)
                    DataCell(
                      Center(
                        child: Text(
                          '${s['homework']}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    // LISTENING
                    DataCell(
                      Center(
                        child: Text(
                          '${s['listening']}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // READING
                    DataCell(
                      Center(
                        child: Text(
                          '${s['reading']}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // WRITING
                    DataCell(
                      Center(
                        child: Text(
                          '${s['writing']}',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: (s['writing'] as double) < 5.0
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ),

                    // SPEAKING
                    DataCell(
                      Center(
                        child: Text(
                          '${s['speaking']}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // OVERALL BAND
                    DataCell(
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isWarning
                                ? const Color(0xFFFEF3C7)
                                : const Color(0xFF003FB1),
                            borderRadius: BorderRadius.circular(6),
                            border: isWarning
                                ? Border.all(color: const Color(0xFFFDE68A))
                                : null,
                          ),
                          child: Text(
                            'Band ${s['overall']}',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: isWarning
                                  ? const Color(0xFF92400E)
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // XẾP LOẠI
                    DataCell(
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: s['classifBg'],
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: (s['classifColor'] as Color).withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Text(
                            s['classification'],
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: s['classifColor'],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // NHẬN XÉT GIẢNG VIÊN
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 280),
                        child: Text(
                          s['notes'],
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF475569),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),

                    // THAO TÁC
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _showEditScoreModal(s),
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            color: const Color(0xFF003FB1),
                            tooltip: 'Chỉnh sửa điểm',
                          ),
                          IconButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Đang xem chi tiết học bạ của ${s['name']}',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.visibility_outlined,
                              size: 16,
                            ),
                            color: const Color(0xFF64748B),
                            tooltip: 'Xem học bạ',
                          ),
                          IconButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Đang chuẩn bị in phiếu điểm ${s['name']}...',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.print_outlined, size: 16),
                            color: const Color(0xFF64748B),
                            tooltip: 'In phiếu điểm',
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableFilterTab(String label, int index) {
    final isActive = _activeFilterTab == index;
    return InkWell(
      onTap: () => setState(() => _activeFilterTab = index),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF003FB1) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
