import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/di/injection.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import 'class_registrations_admin_screen.dart';

class AdmissionsCrmView extends StatefulWidget {
  const AdmissionsCrmView({super.key});

  @override
  State<AdmissionsCrmView> createState() => _AdmissionsCrmViewState();
}

class _AdmissionsCrmViewState extends State<AdmissionsCrmView> {
  final ApiClient _apiClient = getIt<ApiClient>();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _leads = [];
  List<Map<String, dynamic>> _branches = [];
  bool _isKanbanView = true;
  String _selectedBranch = 'ALL';
  String _selectedSource = 'ALL';
  String _mobileStage = 'ALL';

  @override
  void initState() {
    super.initState();
    _fetchLeads(initial: true);
    _fetchBranches();
  }

  Future<void> _fetchBranches() async {
    try {
      final response = await _apiClient.get('/branches');
      final data = response is Map ? response['data'] ?? response : response;
      if (data is List && mounted) {
        setState(
          () => _branches = data
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(),
        );
      }
    } catch (_) {
      // Danh mục chi nhánh có thể tải lại khi mở lại trang.
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _exportLeads() async {
    try {
      final bytes = await _apiClient.download('/admissions/leads/export/xlsx');
      if (bytes.isEmpty) throw StateError('Máy chủ không trả về tệp Excel.');
      final saved = await FilePicker.saveFile(
        fileName: 'danh-sach-leads.xlsx',
        bytes: bytes,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      if (saved != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xuất dữ liệu Leads.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xuất dữ liệu Leads thất bại: $error')),
        );
      }
    }
  }

  Future<void> _openRegistrations() async {
    final phone = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ClassRegistrationsAdminScreen()),
    );
    if (!mounted) return;
    if (phone != null) {
      _searchController.text = phone;
      setState(() {});
      await _fetchLeads();
    }
  }

  Future<void> _fetchLeads({bool initial = false}) async {
    if (!initial && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final items = <dynamic>[];
      var serverPage = 1;
      var totalPages = 1;
      do {
        final res = await _apiClient.get(
          '/admissions/leads',
          queryParameters: {'limit': 100, 'page': serverPage},
        );
        final data = (res is Map && res['data'] is Map) ? res['data'] : res;
        items.addAll(
          (data is Map && data['items'] is List)
              ? data['items'] as List
              : (res is List ? res : <dynamic>[]),
        );
        totalPages = data is Map
            ? (int.tryParse('${data['totalPages']}') ?? 1)
            : 1;
        serverPage++;
      } while (serverPage <= totalPages);

      if (mounted) {
        setState(() {
          _leads = items;
          _errorMessage = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showAddLeadDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final courseCtrl = TextEditingController();
    String source = 'FACEBOOK';
    String? branchId = _selectedBranch != 'ALL'
        ? _selectedBranch
        : (_branches.length == 1 ? _branches.first['id']?.toString() : null);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person_add_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Tiếp Nhận Lead Mới',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên khách hàng *',
                  hintText: 'VD: Nguyễn Mai Anh',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại liên hệ *',
                  hintText: 'VD: 0982123456',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: courseCtrl,
                decoration: const InputDecoration(
                  labelText: 'Khóa học quan tâm',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: source,
                decoration: const InputDecoration(
                  labelText: 'Nguồn tiếp nhận',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'FACEBOOK',
                    child: Text('Facebook Ads'),
                  ),
                  DropdownMenuItem(
                    value: 'DIRECT_WALKIN',
                    child: Text('Walk-in (Tại quầy)'),
                  ),
                  DropdownMenuItem(
                    value: 'WEBSITE',
                    child: Text('Website Form'),
                  ),
                  DropdownMenuItem(
                    value: 'REFERRAL',
                    child: Text('Người quen giới thiệu'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) source = v;
                },
              ),
              if (_branches.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: branchId,
                  decoration: const InputDecoration(
                    labelText: 'Chi nhánh tiếp nhận *',
                    border: OutlineInputBorder(),
                  ),
                  items: _branches
                      .map(
                        (branch) => DropdownMenuItem<String>(
                          value: branch['id']?.toString(),
                          child: Text(branch['name']?.toString() ?? ''),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => branchId = value,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy bỏ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003FB1),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty ||
                  phoneCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập tên và số điện thoại'),
                  ),
                );
                return;
              }
              if (branchId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng chọn chi nhánh tiếp nhận.'),
                  ),
                );
                return;
              }
              try {
                await _apiClient.post(
                  '/admissions/leads',
                  data: {
                    'fullName': nameCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                    'targetCourse': courseCtrl.text.trim(),
                    'source': source,
                    'branchId': branchId,
                  },
                );
                if (!ctx.mounted || !mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã thêm lead vào CRM thành công!'),
                  ),
                );
                _fetchLeads();
              } catch (error) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Không thể lưu lead: $error')),
                );
              }
            },
            child: const Text('Lưu vào Pipeline'),
          ),
        ],
      ),
    );
  }

  Future<void> _advanceLeadStatus(
    Map<String, dynamic> lead,
    String nextStatus,
    String actionName,
  ) async {
    if (lead['status'] == 'ENROLLED') {
      await _showLeadDetail(lead);
      return;
    }
    try {
      if (nextStatus == 'ENROLLED') {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Chuyển thành học viên'),
            content: Text(
              'Tạo tài khoản học viên chính thức cho ${lead['fullName']}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Xác nhận'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        final response = await _apiClient.post(
          '/admissions/leads/${lead['id']}/convert',
          data: <String, dynamic>{},
        );
        await _fetchLeads();
        if (!mounted) return;
        final payload = response is Map
            ? response['data'] ?? response
            : response;
        final student = payload is Map ? payload['student'] : null;
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Đã tạo tài khoản học viên'),
            content: SelectableText(
              student is Map
                  ? 'Mã học viên: ${student['userCode'] ?? ''}\nMật khẩu tạm thời: ${student['temporaryPassword'] ?? ''}\nHãy lưu lại và chuyển riêng cho học viên.'
                  : 'Hồ sơ đã được chuyển thành học viên.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
        return;
      } else {
        await _apiClient.patch(
          '/admissions/leads/${lead['id']}',
          data: {'status': nextStatus},
        );
      }
      await _fetchLeads();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã cập nhật: ${lead["fullName"]} → $actionName'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không cập nhật được lead: $error')),
      );
    }
  }

  Future<void> _showLeadDetail(Map<String, dynamic> lead) async {
    try {
      final response = await _apiClient.get('/admissions/leads/${lead['id']}');
      if (!mounted) return;
      final payload = response is Map ? response['data'] ?? response : response;
      final details = Map<String, dynamic>.from(payload as Map);
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(details['fullName']?.toString() ?? 'Chi tiết Lead'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Điện thoại: ${details['phone'] ?? ''}'),
                Text('Email: ${details['email'] ?? ''}'),
                Text('Khóa học quan tâm: ${details['targetCourse'] ?? ''}'),
                Text('Nguồn: ${details['source'] ?? ''}'),
                Text('Trạng thái: ${details['status'] ?? ''}'),
                Text('Ghi chú: ${details['notes'] ?? ''}'),
                if (details['convertedUserId'] != null)
                  Text('ID học viên: ${details['convertedUserId']}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tải được chi tiết lead: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1024;
    final todayStr = DateFormat('dd/MM/yyyy').format(DateTime.now());

    // Filter leads by search
    final query = _searchController.text.trim().toLowerCase();
    final filteredLeads = _leads.where((l) {
      final name = (l['fullName'] ?? '').toString().toLowerCase();
      final phone = (l['phone'] ?? '').toString().toLowerCase();
      final course = (l['targetCourse'] ?? '').toString().toLowerCase();
      final branch = l['branch'];
      final branchId = branch is Map ? branch['id']?.toString() : null;
      return (name.contains(query) ||
              phone.contains(query) ||
              course.contains(query)) &&
          (_selectedBranch == 'ALL' || branchId == _selectedBranch) &&
          (_selectedSource == 'ALL' || l['source'] == _selectedSource);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _openRegistrations,
                icon: const Icon(Icons.how_to_reg_outlined),
                label: const Text('Đơn đăng ký lớp'),
              ),
            ),
            const SizedBox(height: 12),
            // 1. PAGE HEADER / HEADING LAYOUT (Stitch style)
            Container(
              padding: const EdgeInsets.only(bottom: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 12,
                                runSpacing: 6,
                                children: [
                                  Text(
                                    'Tuyển sinh & Quản lý Lead tiềm năng',
                                    style: AppTextStyles.h2(context).copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          radius: 3.5,
                                          backgroundColor: Color(0xFF2E7D32),
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Dữ liệu CRM trực tuyến',
                                          style: TextStyle(
                                            color: Color(0xFF2E7D32),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.today_rounded,
                                    size: 16,
                                    color: Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Hôm nay: $todayStr • ${_leads.where((l) => (l['status'] ?? 'NEW') == 'NEW').length} lead mới cần tư vấn trong hệ thống',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _exportLeads,
                              icon: const Icon(
                                Icons.file_download_outlined,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              label: const Text('Xuất dữ liệu (.xlsx)'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF0F172A),
                                side: const BorderSide(
                                  color: Color(0xFFCBD5E1),
                                ),
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _showAddLeadDialog,
                              icon: const Icon(
                                Icons.person_add_rounded,
                                size: 18,
                              ),
                              label: const Text('+ Tiếp nhận Lead mới'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF003FB1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 10,
                          runSpacing: 6,
                          children: [
                            Text(
                              'Tuyển sinh & Quản lý Lead tiềm năng',
                              style: AppTextStyles.h2(context).copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 3.5,
                                    backgroundColor: Color(0xFF2E7D32),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Dữ liệu CRM trực tuyến',
                                    style: TextStyle(
                                      color: Color(0xFF2E7D32),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.today_rounded,
                                size: 15,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Hôm nay: $todayStr • ${_leads.where((l) => (l['status'] ?? 'NEW') == 'NEW').length} lead mới cần tư vấn trong hệ thống',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _exportLeads,
                              icon: const Icon(
                                Icons.file_download_outlined,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              label: const Text('Xuất dữ liệu (.xlsx)'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF0F172A),
                                side: const BorderSide(
                                  color: Color(0xFFCBD5E1),
                                ),
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _showAddLeadDialog,
                              icon: const Icon(
                                Icons.person_add_rounded,
                                size: 16,
                              ),
                              label: const Text('+ Tiếp nhận Lead mới'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF003FB1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),

            // 2. 4 METRIC SUMMARY CARDS (Stitch Layout)
            LayoutBuilder(
              builder: (ctx, constraints) {
                final cardWidth = isDesktop
                    ? (constraints.maxWidth - 48) / 4
                    : (constraints.maxWidth - 16) / 2;
                final totalLeads = _leads.length;
                final pendingLeads = _leads.where((l) {
                  final st = (l['status'] ?? 'NEW').toString();
                  return st == 'NEW' || st == 'CONTACTED';
                }).length;
                final testLeads = _leads.where((l) {
                  final st = (l['status'] ?? '').toString();
                  return st == 'TEST_SCHEDULED' ||
                      st == 'TESTING' ||
                      st == 'TESTED';
                }).length;
                final enrolledLeads = _leads.where((l) {
                  final st = (l['status'] ?? '').toString();
                  return st == 'ENROLLED' ||
                      st == 'CONVERTED' ||
                      st == 'COMPLETED';
                }).length;
                final convRate = totalLeads > 0
                    ? ((enrolledLeads / totalLeads) * 100).toStringAsFixed(0)
                    : '0';

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildMetricCard(
                      title: 'Tổng Lead hệ thống',
                      value: '$totalLeads lead',
                      subtext: 'Dữ liệu trực tiếp từ CRM',
                      icon: Icons.person_add_rounded,
                      iconBg: const Color(0xFFEFF6FF),
                      iconColor: const Color(0xFF2563EB),
                      pillColor: const Color(0xFFECFDF5),
                      pillTextColor: const Color(0xFF047857),
                      width: cardWidth,
                    ),
                    _buildMetricCard(
                      title: 'Chờ tư vấn & xếp lịch test',
                      value: '$pendingLeads lead',
                      subtext: 'Cần liên hệ tư vấn',
                      icon: Icons.phone_forwarded_rounded,
                      iconBg: const Color(0xFFFFFBEB),
                      iconColor: const Color(0xFFD97706),
                      pillColor: const Color(0xFFFEF3C7),
                      pillTextColor: const Color(0xFFB45309),
                      width: cardWidth,
                    ),
                    _buildMetricCard(
                      title: 'Đã test xếp lớp (Placement)',
                      value: '$testLeads học viên',
                      subtext: 'Đang chờ xếp lớp phù hợp',
                      icon: Icons.school_rounded,
                      iconBg: const Color(0xFFEEF2FF),
                      iconColor: const Color(0xFF4F46E5),
                      pillColor: const Color(0xFFEEF2FF),
                      pillTextColor: const Color(0xFF4338CA),
                      width: cardWidth,
                    ),
                    _buildMetricCard(
                      title: 'Chuyển đổi thành công',
                      value: '$enrolledLeads học viên',
                      subtext: 'Tỷ lệ chuyển đổi: $convRate%',
                      icon: Icons.check_circle_rounded,
                      iconBg: const Color(0xFFF0FDF4),
                      iconColor: const Color(0xFF16A34A),
                      pillColor: const Color(0xFFDCFCE7),
                      pillTextColor: const Color(0xFF15803D),
                      width: cardWidth,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // 3. FILTER / VIEW SWITCHER TOOLBAR (Stitch Layout)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // View Toggle Switch
                  if (isDesktop)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildViewToggleButton(
                            title: 'Kanban Pipeline',
                            icon: Icons.view_kanban_rounded,
                            isActive: _isKanbanView,
                            onTap: () => setState(() => _isKanbanView = true),
                          ),
                          const SizedBox(width: 4),
                          _buildViewToggleButton(
                            title: 'Danh sách chi tiết (Table)',
                            icon: Icons.table_chart_rounded,
                            isActive: !_isKanbanView,
                            onTap: () => setState(() => _isKanbanView = false),
                          ),
                        ],
                      ),
                    ),

                  // Search Box
                  SizedBox(
                    width: isDesktop ? 300 : double.infinity,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Tìm tên, SĐT, khóa học...',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),

                  // Filters
                  Wrap(
                    spacing: 10,
                    children: [
                      Container(
                        width: isDesktop ? null : width - 64,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: !isDesktop,
                            value: _selectedBranch,
                            items: [
                              const DropdownMenuItem(
                                value: 'ALL',
                                child: Text('Cơ sở: Tất cả chi nhánh'),
                              ),
                              ..._branches.map(
                                (branch) => DropdownMenuItem(
                                  value: branch['id']?.toString(),
                                  child: Text(branch['name']?.toString() ?? ''),
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _selectedBranch = v);
                              }
                            },
                          ),
                        ),
                      ),
                      Container(
                        width: isDesktop ? null : width - 64,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: !isDesktop,
                            value: _selectedSource,
                            items: const [
                              DropdownMenuItem(
                                value: 'ALL',
                                child: Text('Nguồn: Tất cả nguồn'),
                              ),
                              DropdownMenuItem(
                                value: 'FACEBOOK',
                                child: Text('Facebook Ads'),
                              ),
                              DropdownMenuItem(
                                value: 'DIRECT_WALKIN',
                                child: Text('Walk-in (Tại quầy)'),
                              ),
                              DropdownMenuItem(
                                value: 'WEBSITE',
                                child: Text('Website Form'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _selectedSource = v);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. KANBAN OR TABLE VIEW CONTENT
            if (_isLoading && _leads.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: LoadingWidget(
                  message: 'Đang tải pipeline tuyển sinh & leads...',
                ),
              )
            else if (_errorMessage != null && _leads.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: AppErrorWidget(
                  message: _errorMessage!,
                  onRetry: () => _fetchLeads(),
                ),
              )
            else if (!isDesktop)
              _buildMobileLeads(filteredLeads)
            else if (_isKanbanView)
              _buildKanbanBoard(filteredLeads)
            else
              _buildTableView(filteredLeads),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLeads(List<dynamic> leads) {
    const stages = <String, String>{
      'ALL': 'Tất cả',
      'NEW': 'Mới',
      'CONTACTED': 'Đang tư vấn',
      'TEST': 'Đã hẹn test',
      'ENROLLED': 'Đã ghi danh',
    };
    String stageFor(String status) {
      if (status == 'NEW') return 'NEW';
      if (status == 'CONTACTED') return 'CONTACTED';
      if (['TEST_SCHEDULED', 'TESTING', 'TESTED'].contains(status)) {
        return 'TEST';
      }
      if (['ENROLLED', 'CONVERTED', 'COMPLETED'].contains(status)) {
        return 'ENROLLED';
      }
      return 'ALL';
    }

    final visible = leads.where((raw) {
      final lead = Map<String, dynamic>.from(raw as Map);
      return _mobileStage == 'ALL' ||
          stageFor(lead['status']?.toString() ?? 'NEW') == _mobileStage;
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hồ sơ tuyển sinh',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: stages.entries.map((stage) {
              final count = stage.key == 'ALL'
                  ? leads.length
                  : leads.where((raw) {
                      final lead = Map<String, dynamic>.from(raw as Map);
                      return stageFor(lead['status']?.toString() ?? 'NEW') ==
                          stage.key;
                    }).length;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('${stage.value} ($count)'),
                  selected: _mobileStage == stage.key,
                  onSelected: (_) => setState(() => _mobileStage = stage.key),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),
        if (visible.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(child: Text('Không có hồ sơ phù hợp')),
          )
        else
          ...visible.map((raw) {
            final lead = Map<String, dynamic>.from(raw as Map);
            final name = lead['fullName']?.toString() ?? 'Chưa có tên';
            final status = lead['status']?.toString() ?? 'NEW';
            final next = switch (stageFor(status)) {
              'NEW' => ('Tư vấn ngay', 'CONTACTED'),
              'CONTACTED' => ('Nhận vào test', 'TEST_SCHEDULED'),
              'TEST' => ('Chốt ghi danh', 'ENROLLED'),
              _ => null,
            };
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFEEF2FF),
                        child: Text(name.isEmpty ? '?' : name[0].toUpperCase()),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              lead['phone']?.toString() ??
                                  'Chưa có số điện thoại',
                              style: const TextStyle(color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Trạng thái: ${stages[stageFor(status)] ?? status}'),
                  Text(
                    'Khóa quan tâm: ${lead['targetCourse'] ?? 'Chưa ghi nhận'}',
                  ),
                  Text('Nguồn: ${lead['source'] ?? 'Chưa rõ'}'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () => _showLeadDetail(lead),
                        child: const Text('Xem chi tiết'),
                      ),
                      if (next != null)
                        FilledButton(
                          onPressed: () =>
                              _advanceLeadStatus(lead, next.$2, next.$1),
                          child: Text(next.$1),
                        ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required Color pillColor,
    required Color pillTextColor,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 3,
            offset: Offset(0, 1),
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
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: pillColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              subtext,
              style: TextStyle(
                color: pillTextColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggleButton({
    required String title,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive
              ? const [BoxShadow(color: Color(0x10000000), blurRadius: 2)]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? const Color(0xFF003FB1)
                  : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive
                    ? const Color(0xFF003FB1)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKanbanBoard(List<dynamic> allLeads) {
    // 4 Columns definition
    final newLeads = allLeads
        .where((l) => (l['status'] ?? 'NEW') == 'NEW')
        .toList();
    final contactedLeads = allLeads
        .where((l) => (l['status'] ?? '') == 'CONTACTED')
        .toList();
    final testLeads = allLeads
        .where(
          (l) =>
              (l['status'] ?? '') == 'TEST_SCHEDULED' ||
              (l['status'] ?? '') == 'TESTING' ||
              (l['status'] ?? '') == 'TESTED',
        )
        .toList();
    final enrolledLeads = allLeads
        .where(
          (l) =>
              (l['status'] ?? '') == 'ENROLLED' ||
              (l['status'] ?? '') == 'CONVERTED' ||
              (l['status'] ?? '') == 'COMPLETED',
        )
        .toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKanbanColumn(
            title: 'Mới tiếp nhận (Lead Mới)',
            dotColor: const Color(0xFF94A3B8),
            badgeColor: const Color(0xFFF1F5F9),
            textColor: const Color(0xFF475569),
            leads: newLeads,
            nextActionName: 'Tư vấn ngay',
            nextStatus: 'CONTACTED',
            actionIcon: Icons.phone_in_talk_rounded,
          ),
          const SizedBox(width: 16),
          _buildKanbanColumn(
            title: 'Đang tư vấn & Đặt hẹn test',
            dotColor: const Color(0xFFF59E0B),
            badgeColor: const Color(0xFFFEF3C7),
            textColor: const Color(0xFFB45309),
            leads: contactedLeads,
            nextActionName: 'Nhận vào Test',
            nextStatus: 'TEST_SCHEDULED',
            actionIcon: Icons.fact_check_rounded,
          ),
          const SizedBox(width: 16),
          _buildKanbanColumn(
            title: 'Đã test & Chờ xếp lớp',
            dotColor: const Color(0xFF6366F1),
            badgeColor: const Color(0xFFEEF2FF),
            textColor: const Color(0xFF4338CA),
            leads: testLeads,
            nextActionName: 'Chốt & Thu học phí',
            nextStatus: 'ENROLLED',
            actionIcon: Icons.payments_rounded,
          ),
          const SizedBox(width: 16),
          _buildKanbanColumn(
            title: 'Đã chốt & Đóng học phí',
            dotColor: const Color(0xFF10B981),
            badgeColor: const Color(0xFFD1FAE5),
            textColor: const Color(0xFF047857),
            leads: enrolledLeads,
            nextActionName: 'Xem học viên',
            nextStatus: 'ENROLLED',
            actionIcon: Icons.check_circle_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanColumn({
    required String title,
    required Color dotColor,
    required Color badgeColor,
    required Color textColor,
    required List<dynamic> leads,
    required String nextActionName,
    required String nextStatus,
    required IconData actionIcon,
  }) {
    return Container(
      width: 310,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Column Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(radius: 4, backgroundColor: dotColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${leads.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Cards Stack
          if (leads.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Text(
                  'Chưa có hồ sơ ở bước này',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ...leads.map((lead) {
            final l = lead as Map<String, dynamic>;
            final fullName = l['fullName']?.toString() ?? 'Lead Khách hàng';
            final phone = l['phone']?.toString() ?? '';
            final course = l['targetCourse']?.toString() ?? 'Chưa ghi nhận';
            final source = l['source']?.toString() ?? 'Chưa rõ';
            final initials = fullName
                .split(' ')
                .map((w) => w.isNotEmpty ? w[0] : '')
                .take(2)
                .join();

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
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
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: const Color(0xFFEEF2FF),
                              child: Text(
                                initials.isNotEmpty ? initials : 'L',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  color: Color(0xFF003FB1),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fullName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.call_rounded,
                                        size: 11,
                                        color: Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        phone,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          source,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Detail Box
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Quan tâm:',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                course,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF003FB1),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Phụ trách:',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                l['assignedStaff'] is Map
                                    ? (l['assignedStaff']['fullName']
                                              ?.toString() ??
                                          'Chưa phân công')
                                    : 'Chưa phân công',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _advanceLeadStatus(l, nextStatus, nextActionName),
                      icon: Icon(actionIcon, size: 14),
                      label: Text(
                        nextActionName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003FB1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTableView(List<dynamic> leads) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth = constraints.maxWidth > 760
              ? constraints.maxWidth
              : 760.0;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    color: const Color(0xFFF8FAFC),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'HỌ VÀ TÊN',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'SỐ ĐIỆN THOẠI',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'KHÓA HỌC QUAN TÂM',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'NGUỒN LEAD',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'TRẠNG THÁI',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: Text(
                            'THAO TÁC',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: leads.length,
                    separatorBuilder: (_, index) =>
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (ctx, idx) {
                      final l = leads[idx] as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                l['fullName'] ?? 'N/A',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                l['phone'] ?? 'N/A',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                l['targetCourse'] ?? 'Chưa ghi nhận',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF003FB1),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                l['source'] ?? 'Facebook Ads',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  l['status'] ?? 'NEW',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => _showLeadDetail(l),
                                  child: const Text(
                                    'Chi tiết',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF003FB1),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
