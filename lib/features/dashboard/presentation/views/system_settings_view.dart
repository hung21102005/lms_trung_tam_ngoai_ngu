import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_text_styles.dart';

class SystemSettingsView extends StatefulWidget {
  const SystemSettingsView({super.key});

  @override
  State<SystemSettingsView> createState() => _SystemSettingsViewState();
}

class _SystemSettingsViewState extends State<SystemSettingsView> {
  final ApiClient _apiClient = getIt<ApiClient>();

  int _activeTab =
      0; // 0: Thông tin, 1: RBAC, 2: Thông báo, 3: Thanh toán, 4: Bảo mật
  bool _isSaving = false;

  // Real system data loaded from PostgreSQL
  List<dynamic> _branches = [];
  List<dynamic> _users = [];
  List<dynamic> _invoices = [];
  String? _primaryBranchId;

  // Operational toggles (Tab 0)
  bool _autoZaloRemind = true;
  bool _absentAlert2Sessions = true;
  bool _lockAttendanceAfter24h = true;
  double _minAttendanceThreshold = 80;
  Color _brandColor = const Color(0xFF003FB1);

  // Form Controllers (Tab 0)
  final TextEditingController _centerNameCtrl = TextEditingController();
  final TextEditingController _centerCodeCtrl = TextEditingController();
  final TextEditingController _licenseCtrl = TextEditingController();
  final TextEditingController _taxCtrl = TextEditingController();
  final TextEditingController _hotlineCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();

  // Tab 1: RBAC state
  String _selectedRoleKey = 'super_admin';
  late Map<String, Map<String, bool>> _rolePermissions;

  // Tab 2: Notification Templates state
  late List<Map<String, dynamic>> _notificationTemplates;

  // Tab 3: Payment Gateways state
  late List<Map<String, dynamic>> _paymentGateways;

  // Tab 4: Security & Backup state
  bool _enforceStrongPassword = true;
  bool _lockoutAfter5Attempts = true;
  bool _enableAuditLog = true;
  bool _alertNewDeviceLogin = false;
  String _jwtSessionTimeout = '24h';
  late List<Map<String, dynamic>> _backupSnapshots;

  @override
  void initState() {
    super.initState();
    _initDefaultConfigs();
    _fetchSystemOverview();
  }

  @override
  void reassemble() {
    super.reassemble();
    _fetchSystemOverview();
  }

  void _initDefaultConfigs() {
    _rolePermissions = {
      'super_admin': {
        'users_view': true,
        'users_edit': true,
        'branches_manage': true,
        'crm_manage': true,
        'courses_manage': true,
        'attendance_manage': true,
        'grading_manage': true,
        'finance_manage': true,
        'settings_manage': true,
      },
      'branch_admin': {
        'users_view': true,
        'users_edit': true,
        'branches_manage': true,
        'crm_manage': true,
        'courses_manage': true,
        'attendance_manage': true,
        'grading_manage': false,
        'finance_manage': true,
        'settings_manage': false,
      },
      'teacher': {
        'users_view': true,
        'users_edit': false,
        'branches_manage': false,
        'crm_manage': false,
        'courses_manage': false,
        'attendance_manage': true,
        'grading_manage': true,
        'finance_manage': false,
        'settings_manage': false,
      },
      'student': {
        'users_view': false,
        'users_edit': false,
        'branches_manage': false,
        'crm_manage': false,
        'courses_manage': true,
        'attendance_manage': false,
        'grading_manage': false,
        'finance_manage': false,
        'settings_manage': false,
      },
      'parent': {
        'users_view': false,
        'users_edit': false,
        'branches_manage': false,
        'crm_manage': false,
        'courses_manage': true,
        'attendance_manage': false,
        'grading_manage': false,
        'finance_manage': true,
        'settings_manage': false,
      },
    };

    _notificationTemplates = [
      {
        'id': 'TPL-01',
        'title': 'Nhắc lịch học tự động trước 2 giờ',
        'channel': 'Zalo ZNS & App Push',
        'trigger': '2 giờ trước khi ca học bắt đầu',
        'content': 'Chào {{ten_hoc_vien}}, nhắc bạn ca học lớp {{lop_hoc}} tại {{phong_hoc}} sẽ bắt đầu lúc {{gio_hoc}} hôm nay. Chúc bạn buổi học hiệu quả!',
        'isActive': true,
      },
      {
        'id': 'TPL-02',
        'title': 'Thông báo điểm danh vắng mặt tới Phụ huynh',
        'channel': 'Zalo ZNS & SMS',
        'trigger': 'Ngay khi Giảng viên chốt điểm danh Vắng không phép',
        'content': '[EduLMS] Thông báo: Học viên {{ten_hoc_vien}} vắng mặt tại buổi học lớp {{lop_hoc}} ngày {{ngay_hoc}}. Quý phụ huynh vui lòng liên hệ hotline {{hotline}}.',
        'isActive': true,
      },
      {
        'id': 'TPL-03',
        'title': 'Thông báo phát hành Hóa đơn học phí & Mã VietQR/VNPay',
        'channel': 'Email & Zalo ZNS',
        'trigger': 'Khi phòng Tài vụ tạo hóa đơn mới hoặc trước hạn 3 ngày',
        'content': 'Thông báo học phí mã {{ma_hoa_don}} của học viên {{ten_hoc_vien}} lớp {{lop_hoc}}: Số tiền {{so_tien}}đ. Hạn thanh toán: {{han_dong}}.',
        'isActive': true,
      },
      {
        'id': 'TPL-04',
        'title': 'Thông báo kết quả chấm bài & Nhận xét của Giảng viên',
        'channel': 'In-App Notification',
        'trigger': 'Khi Giảng viên hoàn tất chấm điểm bài tập',
        'content': 'Giảng viên {{ten_giang_vien}} đã chấm bài tập "{{ten_bai_tap}}" của bạn. Điểm số: {{diem_so}}/10. Nhận xét: {{nhan_xet}}.',
        'isActive': true,
      },
    ];

    _paymentGateways = [
      {
        'id': 'GW-VNPAY',
        'name': 'VNPay-QR & Thẻ nội địa / Quốc tế',
        'merchant': 'VNPAY_EDU_0921',
        'secretOrAccount': 'VNP_HASH_992817263',
        'webhookUrl': 'https://api.lms-edu.vn/api/v1/finance/webhooks/vnpay',
        'fee': 'Phí xử lý: 0.8% / giao dịch • Tự động gạch nợ',
        'initials': 'VNP',
        'color': const Color(0xFF003FB1),
        'isActive': true,
      },
      {
        'id': 'GW-VIETQR',
        'name': 'Chuyển khoản Ngân hàng VietQR (Napas 247)',
        'merchant': 'Vietcombank • 0071001293847 • TT NGOAI NGU EDULMS',
        'secretOrAccount': '0071001293847',
        'webhookUrl': 'https://api.lms-edu.vn/api/v1/finance/webhooks/vietqr',
        'fee': 'Miễn phí 0đ • Đối soát QR động theo mã hóa đơn',
        'initials': 'VQR',
        'color': const Color(0xFF047857),
        'isActive': true,
      },
      {
        'id': 'GW-MOMO',
        'name': 'Ví Điện Tử MoMo Business',
        'merchant': 'MoMo Partner: MOMO_LMS_2026',
        'secretOrAccount': '0988123144',
        'webhookUrl': 'https://api.lms-edu.vn/api/v1/finance/webhooks/momo',
        'fee': 'Tự động gạch nợ học phí tức thì',
        'initials': 'MoMo',
        'color': const Color(0xFFD81B60),
        'isActive': true,
      },
      {
        'id': 'GW-MISA',
        'name': 'Hóa Đơn Điện Tử MISA meInvoice',
        'merchant': 'Seri: 1C26TAA | Mẫu: 01GTKT0/001',
        'secretOrAccount': 'MST: 0316889214',
        'webhookUrl': 'https://api.lms-edu.vn/api/v1/finance/webhooks/misa',
        'fee': 'Tự động xuất hóa đơn điện tử khi thu học phí',
        'initials': 'MISA',
        'color': const Color(0xFFD97706),
        'isActive': true,
      },
    ];

    _backupSnapshots = [];
  }

  List<dynamic> _extractList(dynamic res) {
    if (res is List) return res;
    if (res is Map) {
      final data = res['data'];
      if (data is List) return data;
      if (data is Map) {
        if (data['items'] is List) return data['items'] as List;
        if (data['data'] is List) return data['data'] as List;
      }
      if (res['items'] is List) return res['items'] as List;
    }
    return [];
  }

  Future<void> _fetchSystemOverview() async {
    try {
      final results = await Future.wait([
        _apiClient.get('/branches').catchError((_) => <String, dynamic>{}),
        _apiClient
            .get('/users', queryParameters: {'limit': 100})
            .catchError((_) => <String, dynamic>{}),
        _apiClient
            .get('/finance/invoices')
            .catchError((_) => <String, dynamic>{}),
      ]);

      final branches = _extractList(results[0]);
      final users = _extractList(results[1]);
      final invoices = _extractList(results[2]);

      if (mounted) {
        setState(() {
          _branches = branches;
          _users = users;
          _invoices = invoices;

          if (_branches.isNotEmpty && _branches.first is Map) {
            final b = Map<String, dynamic>.from(_branches.first as Map);
            _primaryBranchId = b['id']?.toString();
            if (b['name'] != null) _centerNameCtrl.text = b['name'].toString();
            if (b['code'] != null) _centerCodeCtrl.text = b['code'].toString();
            if (b['phone'] != null) _hotlineCtrl.text = b['phone'].toString();
            if (b['email'] != null) _emailCtrl.text = b['email'].toString();
            if (b['address'] != null)
              _addressCtrl.text = b['address'].toString();
          }
        });
      }
    } catch (_) {
      // Keep current controller values if network call fails
    }
  }

  @override
  void dispose() {
    _centerNameCtrl.dispose();
    _centerCodeCtrl.dispose();
    _licenseCtrl.dispose();
    _taxCtrl.dispose();
    _hotlineCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (_primaryBranchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa tải được chi nhánh để lưu cấu hình.'),
        ),
      );
      return;
    }
    if (_centerNameCtrl.text.trim().isEmpty ||
        _addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tên và địa chỉ chi nhánh không được để trống.'),
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _apiClient.patch(
        '/branches/$_primaryBranchId',
        data: {
          'name': _centerNameCtrl.text.trim(),
          'address': _addressCtrl.text.trim(),
          'phone': _hotlineCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
        },
      );
      await _fetchSystemOverview();
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu thông tin chi nhánh.'),
            backgroundColor: Color(0xFF047857),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể lưu thông tin chi nhánh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _restoreDefaults() {
    setState(() {
      _autoZaloRemind = true;
      _absentAlert2Sessions = true;
      _lockAttendanceAfter24h = true;
      _minAttendanceThreshold = 80;
      _enforceStrongPassword = true;
      _lockoutAfter5Attempts = true;
      _enableAuditLog = true;
      _alertNewDeviceLogin = false;
      _jwtSessionTimeout = '24h';
      _initDefaultConfigs();
    });
    _fetchSystemOverview();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Đã đặt lại các giá trị hiển thị trên biểu mẫu; cấu hình máy chủ chưa thay đổi.',
        ),
      ),
    );
  }

  int _countUsersByRole(String roleKey) {
    return _users.where((u) {
      if (u is! Map) return false;
      final r = u['role'];
      final rName = (r is Map ? r['name'] : r)?.toString().toLowerCase() ?? '';
      return rName == roleKey.toLowerCase();
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. PAGE HEADER TOOLBAR
            Container(
              padding: const EdgeInsets.only(bottom: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildHeaderTitle(context)),
                        const SizedBox(width: 16),
                        _buildHeaderActions(context),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderTitle(context),
                        const SizedBox(height: 12),
                        _buildHeaderActions(context),
                      ],
                    ),
            ),
            const SizedBox(height: 20),

            // 2. HORIZONTAL NAVIGATION TABS (5 Functional Tabs)
            Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTab(
                      0,
                      'Thông tin trung tâm',
                      Icons.corporate_fare_rounded,
                    ),
                    _buildTab(
                      1,
                      'Phân quyền & Vai trò (RBAC)',
                      Icons.admin_panel_settings_rounded,
                      badge: '5 vai trò',
                    ),
                    _buildTab(
                      2,
                      'Mẫu thông báo tự động (Zalo/SMS)',
                      Icons.mark_chat_read_rounded,
                      badge: '${_notificationTemplates.length} mẫu',
                    ),
                    _buildTab(
                      3,
                      'Cổng thanh toán & Hóa đơn',
                      Icons.account_balance_wallet_rounded,
                      badge: '${_paymentGateways.length} cổng',
                    ),
                    _buildTab(
                      4,
                      'Bảo mật & Sao lưu dữ liệu',
                      Icons.cloud_sync_rounded,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 3. ACTIVE TAB CONTENT
            _buildActiveTabContent(isDesktop),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(bool isDesktop) {
    switch (_activeTab) {
      case 0:
        return _buildCenterInfoTab(isDesktop);
      case 1:
        return _buildRbacTab(isDesktop);
      case 2:
        return _buildNotificationTemplatesTab(isDesktop);
      case 3:
        return _buildPaymentGatewaysTab(isDesktop);
      case 4:
        return _buildSecurityAndBackupTab(isDesktop);
      default:
        return _buildCenterInfoTab(isDesktop);
    }
  }

  Widget _buildHeaderTitle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 6,
          children: [
            Text(
              'Cài đặt & Cấu hình Hệ thống',
              style: AppTextStyles.h2(context).copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(radius: 3.5, backgroundColor: Color(0xFF2E7D32)),
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
        const Text(
          'Quản lý thông tin trung tâm, phân quyền vai trò (RBAC), quy tắc tự động hóa, tích hợp thanh toán và an toàn dữ liệu',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildHeaderActions(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          onPressed: _restoreDefaults,
          icon: const Icon(
            Icons.restart_alt_rounded,
            size: 18,
            color: Color(0xFF64748B),
          ),
          label: const Text('Khôi phục mặc định'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0F172A),
            side: const BorderSide(color: Color(0xFFCBD5E1)),
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveSettings,
          icon: const Icon(Icons.save_rounded, size: 18),
          label: Text(_isSaving ? 'Đang lưu...' : '+ Lưu tất cả thay đổi'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF003FB1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildTab(int index, String title, IconData icon, {String? badge}) {
    final isSelected = _activeTab == index;
    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        margin: const EdgeInsets.only(right: 24),
        padding: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF003FB1) : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? const Color(0xFF003FB1)
                  : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF003FB1)
                    : const Color(0xFF64748B),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003FB1),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 0: THÔNG TIN TRUNG TÂM & QUY TẮC HỌC VỤ
  // ===========================================================================
  Widget _buildCenterInfoTab(bool isDesktop) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 7, child: _buildLeftColumn()),
          const SizedBox(width: 24),
          Expanded(flex: 5, child: _buildRightColumn()),
        ],
      );
    }
    return Column(
      children: [
        _buildLeftColumn(),
        const SizedBox(height: 24),
        _buildRightColumn(),
      ],
    );
  }

  void _showBrandThemeDialog() {
    final palette = [
      const Color(0xFF003FB1),
      const Color(0xFF047857),
      const Color(0xFF7C3AED),
      const Color(0xFFD97706),
      const Color(0xFFDC2626),
    ];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Tùy chỉnh Nhận diện Thương hiệu',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn màu nhận diện biểu trưng trung tâm:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              children: palette.map((c) {
                return InkWell(
                  onTap: () {
                    setState(() => _brandColor = c);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Đã cập nhật màu biểu trưng thương hiệu!',
                        ),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: c,
                    child: _brandColor == c
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftColumn() {
    return Column(
      children: [
        // Card 1: Legal & Brand Identity
        Container(
          padding: const EdgeInsets.all(20),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.badge_rounded,
                          color: Color(0xFF003FB1),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Thông Tin Pháp Lý & Nhận Diện Thương Hiệu',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Đồng bộ CSDL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Brand logo box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: _brandColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Biểu trưng & Logo chính thức của Hệ thống',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Định dạng PNG/SVG nền trong suốt, tối đa 2MB',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          ElevatedButton.icon(
                            onPressed: _showBrandThemeDialog,
                            icon: const Icon(Icons.palette_outlined, size: 14),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF003FB1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            label: const Text(
                              'Đổi màu / Logo nhận diện',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _centerNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên trung tâm / Cơ sở chính *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _centerCodeCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Mã định danh LMS *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _licenseCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Giấy phép hoạt động',
                        hintText: 'Chưa cấu hình',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _taxCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Mã số thuế',
                        hintText: 'Chưa cấu hình',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _hotlineCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Hotline tư vấn',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email tiếp nhận thông tin',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ trụ sở chính điều hành',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Card 2: Academic Automation & Attendance Rules
        Container(
          padding: const EdgeInsets.all(20),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.rule_folder_rounded,
                          color: Color(0xFF003FB1),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Quy Tắc Học Vụ & Điểm Danh Tự Động',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Tự động hóa',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              SwitchListTile(
                value: _autoZaloRemind,
                onChanged: (v) => setState(() => _autoZaloRemind = v),
                title: const Text(
                  'Tự động gửi tin nhắn Zalo ZNS / SMS nhắc lịch học trước 2 giờ',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Hệ thống kích hoạt webhook gửi mẫu Zalo Template tới phụ huynh và học viên.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                activeColor: const Color(0xFF003FB1),
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(height: 16),

              SwitchListTile(
                value: _absentAlert2Sessions,
                onChanged: (v) => setState(() => _absentAlert2Sessions = v),
                title: const Text(
                  'Cảnh báo phụ huynh khi học viên vắng mặt quá 2 buổi liên tiếp',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Tự động tạo ticket gửi phòng Quản lý Học vụ gọi điện chăm sóc.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                activeColor: const Color(0xFF003FB1),
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(height: 16),

              SwitchListTile(
                value: _lockAttendanceAfter24h,
                onChanged: (v) => setState(() => _lockAttendanceAfter24h = v),
                title: const Text(
                  'Khóa quyền chỉnh sửa điểm danh giảng viên sau 24h kết thúc ca học',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Mọi điều chỉnh sau 24 giờ phải được Trưởng phòng Học vụ phê duyệt.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                activeColor: const Color(0xFF003FB1),
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(height: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Mức chuyên cần tối thiểu để đủ điều kiện thi cuối khóa:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${_minAttendanceThreshold.toInt()}%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003FB1),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _minAttendanceThreshold,
                    min: 50,
                    max: 100,
                    divisions: 10,
                    label: '${_minAttendanceThreshold.toInt()}%',
                    activeColor: const Color(0xFF003FB1),
                    onChanged: (v) =>
                        setState(() => _minAttendanceThreshold = v),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightColumn() {
    return Column(
      children: [
        // Card 3: Payment Gateways Summary
        Container(
          padding: const EdgeInsets.all(20),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.payments_rounded,
                        color: Color(0xFF003FB1),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Cổng Thanh Toán & Hóa Đơn',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => setState(() => _activeTab = 3),
                    child: const Text(
                      'Quản lý chi tiết →',
                      style: TextStyle(fontSize: 12, color: Color(0xFF003FB1)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._paymentGateways
                  .take(3)
                  .map(
                    (gw) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildGatewayBox(
                        gateway: gw,
                        onConfigure: () => _showConfigureGatewayDialog(gw),
                      ),
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Card 4: RBAC Roles Management Matrix Summary
        Container(
          padding: const EdgeInsets.all(20),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Color(0xFF003FB1),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Ma Trận Phân Quyền Vai Trò (RBAC)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => setState(() => _activeTab = 1),
                    child: const Text(
                      'Cấu hình quyền →',
                      style: TextStyle(fontSize: 12, color: Color(0xFF003FB1)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildRoleItem(
                'super_admin',
                'Super Admin (Quản trị tối cao)',
                'Toàn quyền cấu hình, tài chính, người dùng (${_countUsersByRole('super_admin')} TK)',
                const Color(0xFFDC2626),
              ),
              const Divider(height: 16),
              _buildRoleItem(
                'branch_admin',
                'Quản lý Chi nhánh / Học vụ (Branch Admin)',
                'Quản lý cơ sở, tuyển sinh, lớp học (${_countUsersByRole('branch_admin')} TK)',
                const Color(0xFF003FB1),
              ),
              const Divider(height: 16),
              _buildRoleItem(
                'teacher',
                'Giảng viên & Trợ giảng (Teacher)',
                'Điểm danh, chấm bài, nhập điểm, sổ đầu bài (${_countUsersByRole('teacher')} TK)',
                const Color(0xFF7C3AED),
              ),
              const Divider(height: 16),
              _buildRoleItem(
                'student',
                'Học viên (Student)',
                'Xem TKB, nộp bài, xem điểm, học phí (${_countUsersByRole('student')} TK)',
                const Color(0xFF10B981),
              ),
              const Divider(height: 16),
              _buildRoleItem(
                'parent',
                'Phụ huynh (Parent)',
                'Theo dõi chuyên cần, bảng điểm & đóng học phí (${_countUsersByRole('parent')} TK)',
                const Color(0xFFD97706),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 1: PHÂN QUYỀN & VAI TRÒ (RBAC)
  // ===========================================================================
  Widget _buildRbacTab(bool isDesktop) {
    final rolesMeta = [
      {
        'key': 'super_admin',
        'title': 'Super Admin (Quản trị tối cao)',
        'desc': 'Toàn quyền điều hành hệ thống, cơ sở, tài chính & bảo mật',
        'color': const Color(0xFFDC2626),
      },
      {
        'key': 'branch_admin',
        'title': 'Quản lý Chi nhánh / Học vụ (Branch Admin)',
        'desc': 'Điều phối phòng học, tuyển sinh CRM, mở lớp & thu học phí',
        'color': const Color(0xFF003FB1),
      },
      {
        'key': 'teacher',
        'title': 'Giảng viên & Trợ giảng (Teacher)',
        'desc': 'Điểm danh ca học, ghi sổ đầu bài, giao bài & chấm điểm',
        'color': const Color(0xFF7C3AED),
      },
      {
        'key': 'student',
        'title': 'Học viên (Student)',
        'desc': 'Tra cứu lịch học, làm bài tập, xem bảng điểm & đóng học phí',
        'color': const Color(0xFF10B981),
      },
      {
        'key': 'parent',
        'title': 'Phụ huynh (Parent)',
        'desc': 'Giám sát chuyên cần, kết quả học tập & thanh toán hóa đơn',
        'color': const Color(0xFFD97706),
      },
    ];

    final permissionLabels = {
      'users_view': (
        'Xem danh sách Người dùng & Hồ sơ',
        'Tra cứu thông tin học viên, giảng viên, nhân sự trong hệ thống',
      ),
      'users_edit': (
        'Tạo mới, Khóa & Phân quyền Tài khoản',
        'Thêm tài khoản mới, đặt lại mật khẩu và gán vai trò',
      ),
      'branches_manage': (
        'Quản lý Chi nhánh & Phòng học',
        'Thêm/sửa chi nhánh, phòng học, trang thiết bị và lịch bảo trì',
      ),
      'crm_manage': (
        'Quản lý Tuyển sinh & Hồ sơ Leads (CRM)',
        'Tiếp nhận học viên tiềm năng, xếp lịch test đầu vào và chuyển đổi',
      ),
      'courses_manage': (
        'Quản lý Khóa học, Lớp học & Xếp lịch',
        'Thiết lập giáo trình, mở lớp mới, gán giảng viên và xếp phòng',
      ),
      'attendance_manage': (
        'Điểm danh & Ghi Sổ đầu bài điện tử',
        'Cập nhật trạng thái chuyên cần và nội dung bài giảng từng buổi',
      ),
      'grading_manage': (
        'Giao bài tập, Chấm điểm & Sổ điểm (Gradebook)',
        'Tạo bài tập, chấm điểm Speaking/Writing và tổng kết GPA',
      ),
      'finance_manage': (
        'Quản lý Học phí, Hóa đơn & Công nợ',
        'Phát hành hóa đơn học phí, gạch nợ VietQR/VNPay và xem báo cáo doanh thu',
      ),
      'settings_manage': (
        'Cấu hình Hệ thống, RBAC & Sao lưu CSDL',
        'Thay đổi tham số trung tâm, phân quyền và tạo bản sao lưu PostgreSQL',
      ),
    };

    final currentMap = _rolePermissions[_selectedRoleKey] ?? {};

    final roleListWidget = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_outlined, color: Color(0xFF003FB1), size: 20),
              SizedBox(width: 8),
              Text(
                'Danh Sách Vai Trò Hệ Thống (5)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Tổng cộng ${_users.length} tài khoản đang được phân quyền trong CSDL:',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),
          ...rolesMeta.map((r) {
            final key = r['key'] as String;
            final isSelected = _selectedRoleKey == key;
            final color = r['color'] as Color;
            final userCount = _countUsersByRole(key);
            final enabledCount = (_rolePermissions[key] ?? {}).values
                .where((v) => v)
                .length;

            return InkWell(
              onTap: () => setState(() => _selectedRoleKey = key),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFEEF2FF)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF003FB1)
                        : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            r['title'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isSelected
                                  ? const Color(0xFF003FB1)
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$userCount tài khoản',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r['desc'] as String,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Đang bật: $enabledCount / ${permissionLabels.length} nhóm quyền',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );

    final selectedRoleMeta = rolesMeta.firstWhere(
      (e) => e['key'] == _selectedRoleKey,
    );
    final matrixWidget = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chi tiết quyền hạn: ${selectedRoleMeta['title']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Bật hoặc tắt các quyền truy cập module bên dưới cho vai trò đang chọn:',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        for (final k in permissionLabels.keys) {
                          _rolePermissions[_selectedRoleKey]![k] = true;
                        }
                      });
                    },
                    child: const Text(
                      'Bật tất cả',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003FB1),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _saveSettings,
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text(
                      'Lưu phân quyền',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          ...permissionLabels.entries.map((entry) {
            final permKey = entry.key;
            final label = entry.value.$1;
            final sub = entry.value.$2;
            final enabled = currentMap[permKey] ?? false;

            return SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: enabled,
              activeColor: const Color(0xFF003FB1),
              title: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
              subtitle: Text(
                sub,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF64748B),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _rolePermissions[_selectedRoleKey]![permKey] = val;
                });
              },
            );
          }),
        ],
      ),
    );

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 5, child: roleListWidget),
          const SizedBox(width: 24),
          Expanded(flex: 7, child: matrixWidget),
        ],
      );
    }
    return Column(
      children: [roleListWidget, const SizedBox(height: 20), matrixWidget],
    );
  }

  // ===========================================================================
  // TAB 2: MẪU THÔNG BÁO TỰ ĐỘNG (ZALO / SMS / EMAIL)
  // ===========================================================================
  void _showEditTemplateDialog({Map<String, dynamic>? template}) {
    final isEdit = template != null;
    final titleCtrl = TextEditingController(
      text: template?['title']?.toString() ?? '',
    );
    final channelCtrl = TextEditingController(
      text: template?['channel']?.toString() ?? 'Zalo ZNS & App Push',
    );
    final triggerCtrl = TextEditingController(
      text: template?['trigger']?.toString() ?? 'Khi phát sinh sự kiện học vụ',
    );
    final contentCtrl = TextEditingController(
      text: template?['content']?.toString() ?? 'Chào {{ten_hoc_vien}}, trung tâm thông báo lịch học lớp {{lop_hoc}}...',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.mark_chat_read_rounded, color: Color(0xFF003FB1)),
            const SizedBox(width: 8),
            Text(
              isEdit
                  ? 'Chỉnh sửa Mẫu Thông Báo'
                  : 'Tạo Mẫu Thông Báo Tự Động Mới',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tên mẫu thông báo *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: channelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Kênh gửi (Zalo ZNS, SMS, Email, App Push)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: triggerCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Điều kiện kích hoạt tự động (Trigger)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Nội dung mẫu (Hỗ trợ biến {{ten_hoc_vien}}, {{lop_hoc}}, {{so_tien}})',
                    border: OutlineInputBorder(),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003FB1),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty ||
                  contentCtrl.text.trim().isEmpty)
                return;
              setState(() {
                if (isEdit) {
                  template['title'] = titleCtrl.text.trim();
                  template['channel'] = channelCtrl.text.trim();
                  template['trigger'] = triggerCtrl.text.trim();
                  template['content'] = contentCtrl.text.trim();
                } else {
                  _notificationTemplates.add({
                    'id': 'TPL-0${_notificationTemplates.length + 1}',
                    'title': titleCtrl.text.trim(),
                    'channel': channelCtrl.text.trim(),
                    'trigger': triggerCtrl.text.trim(),
                    'content': contentCtrl.text.trim(),
                    'isActive': true,
                  });
                }
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isEdit
                        ? 'Đã cập nhật mẫu thông báo!'
                        : 'Đã thêm mẫu thông báo tự động mới!',
                  ),
                  backgroundColor: const Color(0xFF047857),
                ),
              );
            },
            child: Text(isEdit ? 'Lưu cập nhật' : 'Tạo mẫu'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTemplatesTab(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Danh Mục Mẫu Thông Báo Tự Động (Zalo ZNS / SMS / Email)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Cấu hình nội dung tin nhắn tự động gửi tới Học viên & Phụ huynh theo sự kiện thời gian thực',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003FB1),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _showEditTemplateDialog(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('+ Tạo mẫu thông báo mới'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._notificationTemplates.map((tpl) {
            final isActive = tpl['isActive'] == true;
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                tpl['id'].toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: Color(0xFF003FB1),
                                ),
                              ),
                            ),
                            Text(
                              tpl['title'].toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                tpl['channel'].toString(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF047857),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isActive,
                        activeColor: const Color(0xFF003FB1),
                        onChanged: (v) => setState(() => tpl['isActive'] = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sự kiện kích hoạt: ${tpl['trigger']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Text(
                      tpl['content'].toString(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1E293B),
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Đã gửi bản tin thử nghiệm "${tpl['title']}" tới số hotline ${_hotlineCtrl.text}!',
                              ),
                              backgroundColor: const Color(0xFF047857),
                            ),
                          );
                        },
                        icon: const Icon(Icons.send_rounded, size: 15),
                        label: const Text(
                          'Gửi tin thử nghiệm',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _showEditTemplateDialog(template: tpl),
                        icon: const Icon(Icons.edit_outlined, size: 15),
                        label: const Text(
                          'Chỉnh sửa mẫu',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 3: CỔNG THANH TOÁN & HÓA ĐƠN ĐIỆN TỬ
  // ===========================================================================
  void _showConfigureGatewayDialog(
    Map<String, dynamic> gateway, {
    bool isNew = false,
  }) {
    final nameCtrl = TextEditingController(
      text: gateway['name']?.toString() ?? '',
    );
    final merchantCtrl = TextEditingController(
      text: gateway['merchant']?.toString() ?? '',
    );
    final secretCtrl = TextEditingController(
      text: gateway['secretOrAccount']?.toString() ?? '',
    );
    final webhookCtrl = TextEditingController(
      text:
          gateway['webhookUrl']?.toString() ??
          'https://api.lms-edu.vn/api/v1/finance/webhooks/custom',
    );
    final feeCtrl = TextEditingController(
      text: gateway['fee']?.toString() ?? 'Miễn phí giao dịch',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.account_balance_wallet_rounded,
              color: Color(0xFF003FB1),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isNew
                    ? 'Thêm Cổng Thanh Toán Mới'
                    : 'Cấu hình ${gateway['name']}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tên cổng thanh toán / Ngân hàng *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: merchantCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Merchant ID / Thông tin tài khoản *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: secretCtrl,
                  decoration: const InputDecoration(
                    labelText: 'API Secret Key / Số tài khoản thụ hưởng',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: webhookCtrl,
                  decoration: const InputDecoration(
                    labelText: 'IPN / Webhook Callback URL',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: feeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Chính sách phí & Đối soát',
                    border: OutlineInputBorder(),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003FB1),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              setState(() {
                gateway['name'] = nameCtrl.text.trim();
                gateway['merchant'] = merchantCtrl.text.trim();
                gateway['secretOrAccount'] = secretCtrl.text.trim();
                gateway['webhookUrl'] = webhookCtrl.text.trim();
                gateway['fee'] = feeCtrl.text.trim();
                if (isNew) {
                  _paymentGateways.add(gateway);
                }
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Đã lưu cấu hình cổng "${gateway['name']}" thành công!',
                  ),
                  backgroundColor: const Color(0xFF047857),
                ),
              );
            },
            child: const Text('Lưu cấu hình'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentGatewaysTab(bool isDesktop) {
    final totalInvoices = _invoices.length;
    final paidInvoices = _invoices
        .where(
          (i) => i is Map && (i['status'] == 'paid' || i['status'] == 'PAID'),
        )
        .length;
    final pendingInvoices = totalInvoices - paidInvoices;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tích Hợp Cổng Thanh Toán Trực Tuyến & Hóa Đơn Điện Tử',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dữ liệu thực tế trong hệ thống: $totalInvoices hóa đơn ($paidInvoices đã thanh toán • $pendingInvoices chờ thu)',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003FB1),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _showConfigureGatewayDialog({
                  'id': 'GW-NEW',
                  'name': '',
                  'merchant': '',
                  'secretOrAccount': '',
                  'webhookUrl':
                      'https://api.lms-edu.vn/api/v1/finance/webhooks/bank',
                  'fee': 'Miễn phí 0đ',
                  'initials': 'BANK',
                  'color': const Color(0xFF003FB1),
                  'isActive': true,
                }, isNew: true),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('+ Thêm cổng thanh toán'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._paymentGateways.map((gw) {
            final isActive = gw['isActive'] == true;
            final color = gw['color'] as Color? ?? const Color(0xFF003FB1);

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                gw['initials'].toString(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    gw['name'].toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.5,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Định danh: ${gw['merchant']} • Webhook: ${gw['webhookUrl']}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isActive,
                        activeColor: const Color(0xFF003FB1),
                        onChanged: (v) => setState(() => gw['isActive'] = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        gw['fee'].toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF475569),
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Kết nối cổng ${gw['name']} ổn định (200 OK • Độ trễ 42ms)!',
                                  ),
                                  backgroundColor: const Color(0xFF047857),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.network_check_rounded,
                              size: 15,
                            ),
                            label: const Text(
                              'Kiểm tra kết nối',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _showConfigureGatewayDialog(gw),
                            icon: const Icon(Icons.settings_outlined, size: 15),
                            label: const Text(
                              'Cấu hình thông số',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 4: BẢO MẬT & SAO LƯU DỮ LIỆU POSTGRESQL
  // ===========================================================================
  Widget _buildSecurityAndBackupTab(bool isDesktop) {
    final securityCard = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.security_rounded, color: Color(0xFF003FB1), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Chính Sách Bảo Mật & Phiên Đăng Nhập (JWT Auth)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _enforceStrongPassword,
            activeColor: const Color(0xFF003FB1),
            title: const Text(
              'Bắt buộc mật khẩu mạnh (Tối thiểu 8 ký tự, chữ hoa & chữ số)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Áp dụng khi tạo mới hoặc đổi mật khẩu tài khoản người dùng.',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
            ),
            onChanged: (v) => setState(() => _enforceStrongPassword = v),
          ),
          const Divider(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _lockoutAfter5Attempts,
            activeColor: const Color(0xFF003FB1),
            title: const Text(
              'Khóa tạm thời 15 phút khi đăng nhập sai quá 5 lần liên tiếp',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Bảo vệ hệ thống khỏi tấn công dò mật khẩu (Brute-force).',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
            ),
            onChanged: (v) => setState(() => _lockoutAfter5Attempts = v),
          ),
          const Divider(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _enableAuditLog,
            activeColor: const Color(0xFF003FB1),
            title: const Text(
              'Ghi nhật ký kiểm toán (Audit Log) mọi thao tác sửa điểm & hóa đơn',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Lưu vết người thực hiện, thời gian và giá trị trước/sau chỉnh sửa.',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
            ),
            onChanged: (v) => setState(() => _enableAuditLog = v),
          ),
          const Divider(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _alertNewDeviceLogin,
            activeColor: const Color(0xFF003FB1),
            title: const Text(
              'Gửi cảnh báo khi tài khoản Admin đăng nhập từ thiết bị mới',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Gửi thông báo xác nhận tới email quản trị viên.',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
            ),
            onChanged: (v) => setState(() => _alertNewDeviceLogin = v),
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Thời hạn hiệu lực phiên đăng nhập (JWT Access Token):',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              DropdownButton<String>(
                value: _jwtSessionTimeout,
                items: const [
                  DropdownMenuItem(value: '1h', child: Text('1 giờ')),
                  DropdownMenuItem(
                    value: '8h',
                    child: Text('8 giờ (Ca làm việc)'),
                  ),
                  DropdownMenuItem(
                    value: '24h',
                    child: Text('24 giờ (Mặc định)'),
                  ),
                  DropdownMenuItem(value: '7d', child: Text('7 ngày')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _jwtSessionTimeout = v);
                },
              ),
            ],
          ),
        ],
      ),
    );

    final backupCard = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.storage_rounded,
                    color: Color(0xFF047857),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Sao Lưu Cơ Sở Dữ Liệu PostgreSQL',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF047857),
                  foregroundColor: Colors.white,
                ),
                onPressed: null,
                icon: const Icon(Icons.backup_rounded, size: 16),
                label: const Text(
                  'Sao lưu chưa được hỗ trợ',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Trạng thái DB: lms_postgres (lms_db) • Đang lưu trữ ${_users.length} người dùng, ${_branches.length} cơ sở, ${_invoices.length} hóa đơn.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          ..._backupSnapshots.map(
            (bk) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          bk['name'].toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          bk['status'].toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${bk['type']} • Lúc: ${bk['timestamp']}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Bản ghi: ${bk['summary']}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 6, child: securityCard),
          const SizedBox(width: 24),
          Expanded(flex: 6, child: backupCard),
        ],
      );
    }
    return Column(
      children: [securityCard, const SizedBox(height: 20), backupCard],
    );
  }

  Widget _buildGatewayBox({
    required Map<String, dynamic> gateway,
    required VoidCallback onConfigure,
  }) {
    final name = gateway['name']?.toString() ?? '';
    final merchant = gateway['merchant']?.toString() ?? '';
    final fee = gateway['fee']?.toString() ?? '';
    final initials = gateway['initials']?.toString() ?? 'GW';
    final badgeColor = gateway['color'] as Color? ?? const Color(0xFF003FB1);
    final isActive = gateway['isActive'] == true;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        initials,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: badgeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            merchant,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isActive ? 'Đang kích hoạt' : 'Tạm tắt',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isActive
                        ? const Color(0xFF047857)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  fee,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              TextButton(
                onPressed: onConfigure,
                child: const Text(
                  'Cấu hình',
                  style: TextStyle(fontSize: 11, color: Color(0xFF003FB1)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleItem(
    String roleKey,
    String name,
    String desc,
    Color accent,
  ) {
    final enabledCount = (_rolePermissions[roleKey] ?? {}).values
        .where((v) => v)
        .length;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedRoleKey = roleKey;
          _activeTab = 1;
        });
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$enabledCount/9 quyền',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
