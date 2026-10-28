import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/di/injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/empty_state_widget.dart';

class UsersManagementView extends StatefulWidget {
  const UsersManagementView({super.key});

  @override
  State<UsersManagementView> createState() => _UsersManagementViewState();
}

class _UsersManagementViewState extends State<UsersManagementView> {
  final ApiClient _apiClient = getIt<ApiClient>();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _users = [];
  List<Map<String, dynamic>> _branches = [];
  String _selectedRole = 'ALL';
  String _selectedBranch = 'ALL';
  String _selectedStatus = 'ALL';
  bool _isMutating = false;
  int _page = 1;
  static const int _pageSize = 20;

  List<String> _extractRoleCodes(Map<String, dynamic> u) {
    final codes = <String>[];
    if (u['roles'] is List) {
      for (final r in (u['roles'] as List)) {
        if (r is Map) {
          final c = r['code']?.toString() ?? '';
          final n = r['name']?.toString() ?? '';
          if (c.isNotEmpty) codes.add(c.toLowerCase());
          if (n.isNotEmpty) codes.add(n.toLowerCase());
        } else if (r is String) {
          codes.add(r.toLowerCase());
        }
      }
    }
    if (u['userRoles'] is List) {
      for (final ur in (u['userRoles'] as List)) {
        if (ur is Map && ur['role'] is Map) {
          final c = ur['role']['code']?.toString() ?? '';
          final n = ur['role']['name']?.toString() ?? '';
          if (c.isNotEmpty) codes.add(c.toLowerCase());
          if (n.isNotEmpty) codes.add(n.toLowerCase());
        }
      }
    }
    return codes;
  }

  List<String> _extractRoleNames(Map<String, dynamic> u) {
    final names = <String>[];
    if (u['roles'] is List) {
      for (final r in (u['roles'] as List)) {
        if (r is Map) {
          final n = r['name']?.toString() ?? '';
          if (n.isNotEmpty) names.add(n);
        } else if (r is String && r.isNotEmpty) {
          names.add(r);
        }
      }
    }
    if (names.isEmpty && u['userRoles'] is List) {
      for (final ur in (u['userRoles'] as List)) {
        if (ur is Map && ur['role'] is Map) {
          final n = ur['role']['name']?.toString() ?? '';
          if (n.isNotEmpty) names.add(n);
        }
      }
    }
    return names.isNotEmpty ? names : ['Người dùng'];
  }

  bool _userMatchesRole(Map<String, dynamic> u, String roleFilter) {
    if (roleFilter == 'ALL') return true;
    final codes = _extractRoleCodes(u);
    final filter = roleFilter.toLowerCase();
    if (filter == 'admin') {
      return codes.any((c) => c.contains('admin') || c.contains('quản trị'));
    }
    if (filter == 'student') {
      return codes.any((c) => c.contains('student') || c.contains('học viên'));
    }
    if (filter == 'teacher') {
      return codes.any(
        (c) =>
            c.contains('teacher') ||
            c.contains('giáo viên') ||
            c.contains('giảng viên'),
      );
    }
    if (filter == 'academic_staff') {
      return codes.any(
        (c) =>
            c.contains('staff') || c.contains('học vụ') || c.contains('tư vấn'),
      );
    }
    if (filter == 'parent') {
      return codes.any((c) => c.contains('parent') || c.contains('phụ huynh'));
    }
    return codes.any((c) => c.contains(filter));
  }

  List<Map<String, dynamic>> _buildRoleTabs() {
    final total = _users.length;
    final studentCount = _users
        .where(
          (u) => u is Map<String, dynamic> && _userMatchesRole(u, 'student'),
        )
        .length;
    final teacherCount = _users
        .where(
          (u) => u is Map<String, dynamic> && _userMatchesRole(u, 'teacher'),
        )
        .length;
    final staffCount = _users
        .where(
          (u) =>
              u is Map<String, dynamic> &&
              _userMatchesRole(u, 'academic_staff'),
        )
        .length;
    final parentCount = _users
        .where(
          (u) => u is Map<String, dynamic> && _userMatchesRole(u, 'parent'),
        )
        .length;
    final adminCount = _users
        .where((u) => u is Map<String, dynamic> && _userMatchesRole(u, 'admin'))
        .length;

    return [
      {'label': 'Tất cả người dùng', 'value': 'ALL', 'count': '$total'},
      {'label': 'Học viên', 'value': 'student', 'count': '$studentCount'},
      {
        'label': 'Giảng viên & Trợ giảng',
        'value': 'teacher',
        'count': '$teacherCount',
      },
      {
        'label': 'Nhân viên học vụ',
        'value': 'academic_staff',
        'count': '$staffCount',
      },
      {'label': 'Phụ huynh', 'value': 'parent', 'count': '$parentCount'},
      {'label': 'Quản trị viên', 'value': 'admin', 'count': '$adminCount'},
    ];
  }

  @override
  void initState() {
    super.initState();
    _fetchUsers(initial: true);
    _fetchBranches();
  }

  Future<void> _fetchBranches() async {
    try {
      final response = await _apiClient.get('/branches');
      final data = response is Map ? response['data'] ?? response : response;
      if (data is List && mounted)
        setState(
          () => _branches = data
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(),
        );
    } catch (_) {
      // Danh mục chi nhánh có thể tải lại khi mở lại trang.
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    _fetchUsers(initial: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _importStudents() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['xlsx', 'xls'],
      );
      if (files.isEmpty) return;
      final file = files.first;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) throw StateError('Tệp Excel trống.');
      if (mounted) setState(() => _isMutating = true);
      final response = await _apiClient.post(
        '/users/import',
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(bytes, filename: file.name),
        }),
        options: Options(contentType: Headers.multipartFormDataContentType),
      );
      await _fetchUsers();
      if (!mounted) return;
      final result = response is Map ? response['data'] ?? response : response;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Kết quả nhập Excel: $result')));
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Nhập Excel thất bại: $error')));
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  Future<void> _exportUsers() async {
    try {
      final bytes = await _apiClient.download('/users/export/xlsx');
      if (bytes.isEmpty) throw StateError('Máy chủ không trả về tệp Excel.');
      final saved = await FilePicker.saveFile(
        fileName: 'danh-sach-nguoi-dung.xlsx',
        bytes: bytes,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      if (saved != null && mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xuất danh sách người dùng.')),
        );
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xuất danh sách thất bại: $error')),
        );
    }
  }

  Future<void> _fetchUsers({bool initial = false}) async {
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
          '/users',
          queryParameters: {'limit': 100, 'page': serverPage},
        );
        final data = (res is Map && res['data'] is Map) ? res['data'] : res;
        final pageItems = (data is Map && data['items'] is List)
            ? data['items'] as List
            : (res is Map && res['data'] is List)
            ? res['data'] as List
            : (res is List ? res : <dynamic>[]);
        items.addAll(pageItems);
        totalPages = data is Map
            ? (int.tryParse('${data['totalPages']}') ?? 1)
            : 1;
        serverPage++;
      } while (serverPage <= totalPages);

      if (mounted) {
        setState(() {
          _users = items;
          _page = 1;
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

  void _showAddUserDialog() {
    final authState = context.read<AuthBloc>().state;
    final canCreateBranchAdmin =
        authState is AuthenticatedState && authState.user.isSuperAdmin;
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String role = 'student';
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
              'Thêm Người Dùng Mới',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên *',
                    hintText: 'VD: Trần Thị Mai Lan',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    hintText: 'VD: lan.tran@gmail.com',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    hintText: 'VD: 0912345678',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: role,
                  decoration: const InputDecoration(
                    labelText: 'Vai trò tài khoản',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'student',
                      child: Text('Học viên'),
                    ),
                    const DropdownMenuItem(
                      value: 'teacher',
                      child: Text('Giảng viên'),
                    ),
                    const DropdownMenuItem(
                      value: 'academic_staff',
                      child: Text('Nhân viên tư vấn/học vụ'),
                    ),
                    if (canCreateBranchAdmin)
                      const DropdownMenuItem(
                        value: 'branch_admin',
                        child: Text('Quản trị chi nhánh'),
                      ),
                    const DropdownMenuItem(
                      value: 'parent',
                      child: Text('Phụ huynh'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) role = v;
                  },
                ),
                if (_branches.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: branchId,
                    decoration: const InputDecoration(
                      labelText: 'Chi nhánh',
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy bỏ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: _isMutating
                ? null
                : () async {
                    final name = nameCtrl.text.trim();
                    final email = emailCtrl.text.trim();
                    final phone = phoneCtrl.text.trim();
                    if (name.isEmpty ||
                        (role != 'student' && email.isEmpty) ||
                        (role == 'parent' && phone.isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Vui lòng nhập đầy đủ thông tin bắt buộc cho vai trò đã chọn.',
                          ),
                        ),
                      );
                      return;
                    }
                    if (email.isNotEmpty &&
                        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch(email)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Email không đúng định dạng.'),
                        ),
                      );
                      return;
                    }
                    setState(() => _isMutating = true);
                    try {
                      final path = role == 'student'
                          ? '/users/students'
                          : role == 'parent'
                          ? '/users/parents'
                          : '/users/staff';
                      final response = await _apiClient.post(
                        path,
                        data: {
                          'fullName': name,
                          if (email.isNotEmpty) 'email': email,
                          if (phone.isNotEmpty) 'phone': phone,
                          if (branchId != null) 'branchId': branchId,
                          if (role != 'student' && role != 'parent')
                            'roleCode': role,
                        },
                      );
                      if (!mounted) return;
                      Navigator.pop(ctx);
                      await _fetchUsers();
                      if (!mounted) return;
                      final created = response is Map
                          ? response['data'] ?? response
                          : response;
                      final password = created is Map
                          ? created['temporaryPassword']?.toString()
                          : null;
                      await showDialog<void>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Đã tạo tài khoản'),
                          content: SelectableText(
                            password == null
                                ? 'Tài khoản đã được tạo thành công.'
                                : 'Mật khẩu tạm thời: $password\nHãy lưu lại và chuyển riêng cho người dùng.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('Đóng'),
                            ),
                          ],
                        ),
                      );
                    } catch (e) {
                      if (mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Không tạo được người dùng: $e'),
                          ),
                        );
                    } finally {
                      if (mounted) setState(() => _isMutating = false);
                    }
                  },
            child: const Text('Xác nhận tạo'),
          ),
        ],
      ),
    );
  }

  Future<void> _showUserAction(Map<String, dynamic> user, String action) async {
    final id = user['id']?.toString();
    if (id == null || id.isEmpty) return;
    if (action == 'Chỉnh sửa' || action == 'Thao tác') {
      final nameCtrl = TextEditingController(
        text: user['fullName']?.toString() ?? '',
      );
      final emailCtrl = TextEditingController(
        text: user['email']?.toString() ?? '',
      );
      final phoneCtrl = TextEditingController(
        text: user['phone']?.toString() ?? '',
      );
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Chỉnh sửa ${user['userCode'] ?? ''}'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Họ và tên *'),
                ),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Số điện thoại'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: _isMutating
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Họ và tên không được để trống.'),
                          ),
                        );
                        return;
                      }
                      try {
                        setState(() => _isMutating = true);
                        await _apiClient.patch(
                          '/users/$id',
                          data: {
                            'fullName': nameCtrl.text.trim(),
                            if (emailCtrl.text.trim().isNotEmpty)
                              'email': emailCtrl.text.trim(),
                            'phone': phoneCtrl.text.trim(),
                          },
                        );
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        await _fetchUsers();
                        if (mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã cập nhật người dùng.'),
                            ),
                          );
                      } catch (error) {
                        if (mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Cập nhật thất bại: $error'),
                            ),
                          );
                      } finally {
                        if (mounted) setState(() => _isMutating = false);
                      }
                    },
              child: const Text('Lưu thay đổi'),
            ),
          ],
        ),
      );
      nameCtrl.dispose();
      emailCtrl.dispose();
      phoneCtrl.dispose();
      return;
    }
    if (action == 'Cấp lại mật khẩu') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cấp lại mật khẩu'),
          content: Text(
            'Cấp mật khẩu tạm cho ${user['fullName']}? Người dùng sẽ phải đổi mật khẩu khi đăng nhập.',
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
      if (confirmed != true || _isMutating) return;
      try {
        setState(() => _isMutating = true);
        final response = await _apiClient.post(
          '/users/$id/reset-password',
          data: <String, dynamic>{},
        );
        if (!mounted) return;
        final payload = response is Map
            ? response['data'] ?? response
            : response;
        final password = payload is Map
            ? payload['temporaryPassword']?.toString()
            : null;
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Mật khẩu tạm đã tạo'),
            content: SelectableText(
              password ?? 'Đã cấp lại mật khẩu. Kiểm tra email của người dùng.',
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
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cấp lại mật khẩu thất bại: $error')),
          );
      } finally {
        if (mounted) setState(() => _isMutating = false);
      }
      return;
    }
    final nextStatus = action.contains('Khóa') ? 'LOCKED' : 'ACTIVE';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(action),
        content: Text('$action cho ${user['fullName']}?'),
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
    if (confirmed != true || _isMutating) return;
    try {
      setState(() => _isMutating = true);
      await _apiClient.patch('/users/$id/status', data: {'status': nextStatus});
      await _fetchUsers();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật trạng thái ${user['fullName']}.'),
          ),
        );
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không đổi được trạng thái: $error')),
        );
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1024;
    final todayStr = DateFormat('dd/MM/yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. PAGE ACTION HEADER TOOLBAR (Stitch SaaS style)
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
                                    'Quản lý Người dùng & Phân quyền Tài khoản',
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
                                          'Hệ thống bảo mật trực tuyến',
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
                                      'Hôm nay: $todayStr • Tổng số tài khoản vận hành: ${_users.length}',
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
                              onPressed: _exportUsers,
                              icon: const Icon(
                                Icons.file_download_outlined,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              label: const Text('Xuất danh sách (.xlsx)'),
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
                              onPressed: _showAddUserDialog,
                              icon: const Icon(
                                Icons.person_add_rounded,
                                size: 18,
                              ),
                              label: const Text('+ Thêm người dùng mới'),
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
                              'Quản lý Người dùng & Phân quyền Tài khoản',
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
                              child: const Text(
                                '● Hệ thống bảo mật trực tuyến',
                                softWrap: true,
                                style: TextStyle(
                                  color: Color(0xFF2E7D32),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
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
                                'Hôm nay: $todayStr • Tổng số tài khoản vận hành: ${_users.length}',
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
                              onPressed: _exportUsers,
                              icon: const Icon(
                                Icons.file_download_outlined,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              label: const Text('Xuất danh sách (.xlsx)'),
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
                              onPressed: _showAddUserDialog,
                              icon: const Icon(
                                Icons.person_add_rounded,
                                size: 16,
                              ),
                              label: const Text('+ Thêm người dùng mới'),
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

            // 2. 4 KPI STAT CARDS (Stitch Layout)
            LayoutBuilder(
              builder: (ctx, constraints) {
                final cardWidth = isDesktop
                    ? (constraints.maxWidth - 48) / 4
                    : (constraints.maxWidth - 16) / 2;
                final totalUsers = _users.length;
                final studentCount = _users
                    .where(
                      (u) =>
                          u is Map<String, dynamic> &&
                          _userMatchesRole(u, 'student'),
                    )
                    .length;
                final teacherCount = _users
                    .where(
                      (u) =>
                          u is Map<String, dynamic> &&
                          _userMatchesRole(u, 'teacher'),
                    )
                    .length;
                final staffCount = _users
                    .where(
                      (u) =>
                          u is Map<String, dynamic> &&
                          (_userMatchesRole(u, 'academic_staff') ||
                              _userMatchesRole(u, 'admin')),
                    )
                    .length;
                final activeCount = _users
                    .where(
                      (u) =>
                          u is Map<String, dynamic> &&
                          (u['status'] ?? 'ACTIVE') == 'ACTIVE',
                    )
                    .length;
                final activeRate = totalUsers > 0
                    ? ((activeCount / totalUsers) * 100).toStringAsFixed(0)
                    : '0';
                final firstLoginCount = _users
                    .where(
                      (u) =>
                          u is Map<String, dynamic> &&
                          u['isFirstLogin'] == true,
                    )
                    .length;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildStatCard(
                      title: 'Tổng người dùng',
                      value: '$totalUsers',
                      subtext:
                          'HV: $studentCount • GV: $teacherCount • NV/QT: $staffCount',
                      icon: Icons.group_rounded,
                      iconBg: const Color(0xFFEEF2FF),
                      iconColor: const Color(0xFF003FB1),
                      width: cardWidth,
                    ),
                    _buildStatCard(
                      title: 'Giảng viên hệ thống',
                      value: '$teacherCount GV',
                      subtext: 'Đang phụ trách giảng dạy',
                      icon: Icons.school_rounded,
                      iconBg: const Color(0xFFEFF6FF),
                      iconColor: const Color(0xFF2563EB),
                      pillColor: const Color(0xFFECFDF5),
                      pillTextColor: const Color(0xFF047857),
                      width: cardWidth,
                    ),
                    _buildStatCard(
                      title: 'Tài khoản hoạt động',
                      value: '$activeCount',
                      subtext: '$activeRate% kích hoạt',
                      icon: Icons.verified_user_rounded,
                      iconBg: const Color(0xFFF0FDF4),
                      iconColor: const Color(0xFF16A34A),
                      pillColor: const Color(0xFFF0FDF4),
                      pillTextColor: const Color(0xFF15803D),
                      width: cardWidth,
                    ),
                    _buildStatCard(
                      title: 'Chờ đổi mật khẩu lần đầu',
                      value: '$firstLoginCount tài khoản',
                      subtext: 'Tài khoản mới cấp phát',
                      icon: Icons.pending_actions_rounded,
                      iconBg: const Color(0xFFFEF3C7),
                      iconColor: const Color(0xFFD97706),
                      pillColor: const Color(0xFFFFFBEB),
                      pillTextColor: const Color(0xFFB45309),
                      valueColor: firstLoginCount > 0
                          ? const Color(0xFFD97706)
                          : const Color(0xFF0F172A),
                      width: cardWidth,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // 3. TABS & FILTER TOOLBAR (Stitch SaaS style)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Role perspective tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _buildRoleTabs().map((tab) {
                        final isSelected = _selectedRole == tab['value'];
                        return InkWell(
                          onTap: () {
                            setState(() => _selectedRole = tab['value']);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 20),
                            padding: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: isSelected
                                      ? const Color(0xFF003FB1)
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  tab['label']!,
                                  style: TextStyle(
                                    color: isSelected
                                        ? const Color(0xFF003FB1)
                                        : const Color(0xFF64748B),
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFE0E7FF)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    tab['count']!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? const Color(0xFF003FB1)
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(color: Color(0xFFE2E8F0), height: 1),
                  const SizedBox(height: 14),

                  // Search & Dropdown Filters
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Search box
                      SizedBox(
                        width: isDesktop ? 320 : double.infinity,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText:
                                'Tìm theo Họ tên, Email, SĐT hoặc Mã ID...',
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF94A3B8),
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              size: 20,
                              color: Color(0xFF64748B),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
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
                          onChanged: (_) => setState(() => _page = 1),
                        ),
                      ),
                      // Branch Filter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
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
                              if (v != null)
                                setState(() => _selectedBranch = v);
                            },
                          ),
                        ),
                      ),
                      // Status Filter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedStatus,
                            items: const [
                              DropdownMenuItem(
                                value: 'ALL',
                                child: Text('Trạng thái: Tất cả'),
                              ),
                              DropdownMenuItem(
                                value: 'ACTIVE',
                                child: Text('Đang hoạt động'),
                              ),
                              DropdownMenuItem(
                                value: 'INACTIVE',
                                child: Text('Tạm khóa'),
                              ),
                              DropdownMenuItem(
                                value: 'PENDING',
                                child: Text('Chờ kích hoạt'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null)
                                setState(() => _selectedStatus = v);
                            },
                          ),
                        ),
                      ),
                      // Quick actions
                      OutlinedButton.icon(
                        onPressed: _isMutating ? null : _importStudents,
                        icon: const Icon(
                          Icons.upload_file_rounded,
                          size: 18,
                          color: Color(0xFF003FB1),
                        ),
                        label: const Text('Nhập từ Excel'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F172A),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          backgroundColor: const Color(0xFFF8FAFC),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _fetchUsers(),
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: Color(0xFF64748B),
                        ),
                        tooltip: 'Làm mới dữ liệu',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. DATA TABLE / LIST AREA
            if (_isLoading && _users.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: LoadingWidget(
                  message:
                      'Đang kết nối cơ sở dữ liệu tải danh sách tài khoản...',
                ),
              )
            else if (_errorMessage != null && _users.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: AppErrorWidget(
                  message: _errorMessage!,
                  onRetry: () => _fetchUsers(),
                ),
              )
            else
              Builder(
                builder: (context) {
                  final displayUsers = _getFilteredUsers();
                  if (displayUsers.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: EmptyStateWidget(
                        icon: Icons.group_off_rounded,
                        title: 'Không tìm thấy người dùng',
                        description: 'Chưa có tài khoản nào phù hợp với bộ lọc tìm kiếm hiện tại.',
                      ),
                    );
                  }
                  final pageCount =
                      (displayUsers.length + _pageSize - 1) ~/ _pageSize;
                  final visiblePage = _page.clamp(1, pageCount);
                  final start = (visiblePage - 1) * _pageSize;
                  final pageUsers = displayUsers
                      .skip(start)
                      .take(_pageSize)
                      .toList();
                  return Column(
                    children: [
                      Container(
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
                        child: isDesktop
                            ? _buildDesktopTable(pageUsers)
                            : _buildMobileCards(pageUsers),
                      ),
                      if (pageCount > 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Trang $visiblePage/$pageCount • ${displayUsers.length} tài khoản',
                              ),
                              IconButton(
                                tooltip: 'Trang trước',
                                onPressed: visiblePage > 1
                                    ? () => setState(
                                        () => _page = visiblePage - 1,
                                      )
                                    : null,
                                icon: const Icon(Icons.chevron_left),
                              ),
                              IconButton(
                                tooltip: 'Trang sau',
                                onPressed: visiblePage < pageCount
                                    ? () => setState(
                                        () => _page = visiblePage + 1,
                                      )
                                    : null,
                                icon: const Icon(Icons.chevron_right),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    Color? pillColor,
    Color? pillTextColor,
    Color? valueColor,
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
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: valueColor ?? const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          if (pillColor != null && pillTextColor != null)
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
            )
          else
            Text(
              subtext,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
        ],
      ),
    );
  }

  List<dynamic> _getFilteredUsers() {
    final query = _searchController.text.trim().toLowerCase();

    return _users.where((u) {
      final m = u as Map<String, dynamic>;
      final fullName = (m['fullName'] ?? '').toString().toLowerCase();
      final userCode = (m['userCode'] ?? '').toString().toLowerCase();
      final email = (m['email'] ?? '').toString().toLowerCase();
      final phone = (m['phone'] ?? '').toString().toLowerCase();

      final matchesQuery =
          query.isEmpty ||
          fullName.contains(query) ||
          userCode.contains(query) ||
          email.contains(query) ||
          phone.contains(query);

      if (!matchesQuery) return false;

      if (_selectedRole != 'ALL') {
        if (!_userMatchesRole(m, _selectedRole)) return false;
      }

      if (_selectedBranch != 'ALL') {
        final branchMap = m['branch'];
        final branchId = branchMap is Map ? branchMap['id']?.toString() : null;
        if (branchId != _selectedBranch) return false;
      }

      if (_selectedStatus != 'ALL') {
        final status = (m['status'] ?? 'ACTIVE').toString();
        if (status != _selectedStatus) return false;
      }

      return true;
    }).toList();
  }

  Widget _buildDesktopTable(List<dynamic> usersList) {
    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  'MÃ ID',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'HỌ VÀ TÊN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'VAI TRÒ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'CHI NHÁNH',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'LẦN ĐĂNG NHẬP',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              SizedBox(
                width: 110,
                child: Text(
                  'TRẠNG THÁI',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              SizedBox(
                width: 144,
                child: Text(
                  'THAO TÁC',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Table Body
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: usersList.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
          itemBuilder: (context, index) {
            final u = usersList[index] as Map<String, dynamic>;
            final fullName = u['fullName']?.toString() ?? 'Người dùng';
            final userCode = u['userCode']?.toString() ?? 'ID-${index + 1001}';
            final email = u['email']?.toString() ?? 'chua_co@edulms.vn';
            final phone = u['phone']?.toString() ?? 'Chưa có SĐT';
            final roles = _extractRoleNames(u);
            final branchMap = u['branch'];
            final branchName = branchMap is Map
                ? (branchMap['name']?.toString() ?? 'Hệ thống Trung tâm')
                : (branchMap?.toString() ?? 'Hệ thống Trung tâm');
            final isFirstLogin = u['isFirstLogin'] == true;
            final status = u['status']?.toString() ?? 'ACTIVE';
            final isActive = status == 'ACTIVE';

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  // Mã ID
                  SizedBox(
                    width: 120,
                    child: Text(
                      userCode,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF003FB1),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  // Họ và tên (Avatar + Name + Phone)
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFFEEF2FF),
                          child: Text(
                            fullName.isNotEmpty
                                ? fullName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF003FB1),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      fullName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Color(0xFF0F172A),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.verified_rounded,
                                    size: 14,
                                    color: Color(0xFF2563EB),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$email • $phone',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Vai trò Badge
                  Expanded(
                    flex: 2,
                    child: Wrap(
                      spacing: 4,
                      children: roles.map((r) => _buildRoleBadge(r)).toList(),
                    ),
                  ),
                  // Chi nhánh
                  Expanded(
                    flex: 2,
                    child: Text(
                      branchName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF334155),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Lần đăng nhập cuối
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isFirstLogin ? 'Chưa đổi mật khẩu' : 'Đã kích hoạt',
                          style: TextStyle(
                            fontSize: 12,
                            color: isFirstLogin
                                ? const Color(0xFFD97706)
                                : const Color(0xFF0F172A),
                            fontWeight: isFirstLogin
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        Text(
                          isFirstLogin
                              ? 'Cần đổi MK lần đầu'
                              : 'Tài khoản hệ thống',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Trạng thái
                  SizedBox(
                    width: 110,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFFA7F3D0)
                              : const Color(0xFFFECACA),
                        ),
                      ),
                      child: Text(
                        isActive ? '● Hoạt động' : '● Tạm khóa',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isActive
                              ? const Color(0xFF047857)
                              : const Color(0xFFB91C1C),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  // Thao tác
                  SizedBox(
                    width: 144,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: Color(0xFF64748B),
                          ),
                          tooltip: 'Chỉnh sửa thông tin',
                          onPressed: () => _showUserAction(u, 'Chỉnh sửa'),
                        ),
                        IconButton(
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.key_rounded,
                            size: 18,
                            color: Color(0xFFD97706),
                          ),
                          tooltip: 'Đổi mật khẩu',
                          onPressed: () =>
                              _showUserAction(u, 'Cấp lại mật khẩu'),
                        ),
                        IconButton(
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            isActive
                                ? Icons.lock_outline_rounded
                                : Icons.lock_open_rounded,
                            size: 18,
                            color: isActive
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF16A34A),
                          ),
                          tooltip: isActive
                              ? 'Khóa tài khoản'
                              : 'Mở khóa tài khoản',
                          onPressed: () => _showUserAction(
                            u,
                            isActive ? 'Khóa tài khoản' : 'Mở khóa',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRoleBadge(String roleName) {
    Color bg = const Color(0xFFEFF6FF);
    Color text = const Color(0xFF1D4ED8);
    Color border = const Color(0xFFBFDBFE);

    final lower = roleName.toLowerCase();
    if (lower.contains('giáo viên') ||
        lower.contains('teacher') ||
        lower.contains('giảng viên')) {
      bg = const Color(0xFFF3E8FF);
      text = const Color(0xFF6B21A8);
      border = const Color(0xFFE9D5FF);
    } else if (lower.contains('admin') || lower.contains('quản trị')) {
      bg = const Color(0xFFFFE4E6);
      text = const Color(0xFFBE123C);
      border = const Color(0xFFFECDD3);
    } else if (lower.contains('tư vấn') ||
        lower.contains('học vụ') ||
        lower.contains('staff')) {
      bg = const Color(0xFFFEF3C7);
      text = const Color(0xFFB45309);
      border = const Color(0xFFFDE68A);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Text(
        roleName,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMobileCards(List<dynamic> usersList) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: usersList.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
      itemBuilder: (context, index) {
        final u = usersList[index] as Map<String, dynamic>;
        final fullName = u['fullName']?.toString() ?? 'Người dùng';
        final userCode = u['userCode']?.toString() ?? 'ID-${index + 1001}';
        final email = u['email']?.toString() ?? 'chua_co@edulms.vn';
        final roles = _extractRoleNames(u).join(', ');
        final status = u['status']?.toString() ?? 'ACTIVE';
        final isActive = status == 'ACTIVE';

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFEEF2FF),
            child: Text(
              fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF003FB1),
              ),
            ),
          ),
          title: Text(
            fullName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          subtitle: Text(
            '$userCode • $roles\n$email • Trạng thái: ${isActive ? "Hoạt động" : "Tạm khóa"}',
            style: const TextStyle(fontSize: 12),
          ),
          isThreeLine: true,
          trailing: IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showUserAction(u, 'Thao tác'),
          ),
        );
      },
    );
  }
}
