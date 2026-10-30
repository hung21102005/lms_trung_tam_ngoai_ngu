import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/di/injection.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../classes/presentation/bloc/classes_bloc.dart';
import '../../../classes/presentation/bloc/classes_event.dart';
import '../../../finance/presentation/bloc/finance_bloc.dart';
import 'class_registrations_admin_screen.dart';

class AdmissionsCrmView extends StatefulWidget {
  final ApiClient? apiClient;
  final int initialTab;
  const AdmissionsCrmView({super.key, this.apiClient, this.initialTab = 0});

  @override
  State<AdmissionsCrmView> createState() => _AdmissionsCrmViewState();
}

class _AdmissionsCrmViewState extends State<AdmissionsCrmView> {
  late final ApiClient _apiClient = widget.apiClient ?? getIt<ApiClient>();
  final TextEditingController _searchController = TextEditingController();
  String? _registrationPhoneToReview;

  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _leads = [];
  List<Map<String, dynamic>> _branches = [];
  bool _isKanbanView = true;
  String _selectedBranch = 'ALL';
  String _selectedSource = 'ALL';
  String _leadLifecycleFilter = 'ACTIVE'; // ACTIVE, CLOSED, ARCHIVED, ALL
  String _mobileStage = 'ALL';

  int _crmTab = 0; // 0: Tư vấn chung (Leads), 1: Đăng ký lớp học (Registrations)
  List<Map<String, dynamic>> _registrations = [];
  bool _isLoadingRegistrations = false;
  String _registrationFilter = 'ALL';
  String? _busyRegistrationId;
  String? _busyLeadId;

  String _formatFriendlyError(Object error, {required String fallback}) {
    debugPrint('[AdmissionsCRM] API error ($fallback): $error');
    if (error is ApiException) {
      final rawMsg = error.message.trim();
      final isRawRoute404 = RegExp(
        r'^Cannot\s+(GET|POST|PUT|PATCH|DELETE)\s+',
        caseSensitive: false,
      ).hasMatch(rawMsg);
      if (isRawRoute404) {
        return 'Dịch vụ máy chủ chưa nạp đầy đủ endpoint xử lý thao tác này (404). Vui lòng kiểm tra tiến trình Backend.';
      }
      if (rawMsg.isNotEmpty &&
          !rawMsg.toLowerCase().startsWith('internal server error') &&
          !rawMsg.toLowerCase().startsWith('dioexception')) {
        return rawMsg;
      }
      final code = error.statusCode;
      if (code == 400) {
        return '$fallback: Dữ liệu hoặc trạng thái hồ sơ không hợp lệ.';
      }
      if (code == 401) {
        return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      }
      if (code == 403) {
        return 'Bạn không đủ quyền thực hiện thao tác này.';
      }
      if (code == 404) {
        return '$fallback: Hồ sơ không tồn tại hoặc đã bị xóa trước đó.';
      }
      if (code == 409) {
        return '$fallback: Hồ sơ đang có dữ liệu liên kết cần bảo toàn. Bạn có thể lưu trữ hồ sơ.';
      }
      if (code != null && code >= 500) {
        return '$fallback: Lỗi hệ thống từ máy chủ. Vui lòng thử lại sau.';
      }
    }
    final text = error.toString().trim();
    if (RegExp(
      r'Cannot\s+(GET|POST|PUT|PATCH|DELETE)\s+',
      caseSensitive: false,
    ).hasMatch(text)) {
      return 'Dịch vụ máy chủ chưa nạp đầy đủ endpoint xử lý thao tác này (404). Vui lòng kiểm tra tiến trình Backend.';
    }
    return '$fallback: $text';
  }

  bool _isLeadArchived(Map<String, dynamic> lead) {
    return lead['isArchived'] == true ||
        ((lead['notes'] ?? '').toString().contains('[ARCHIVED:'));
  }

  bool _isLeadClosed(Map<String, dynamic> lead) {
    return (lead['status'] ?? '').toString() == 'CANCELLED';
  }

  bool _isLeadConverted(Map<String, dynamic> lead) {
    final st = (lead['status'] ?? '').toString();
    return ['ENROLLED', 'CONVERTED', 'COMPLETED'].contains(st) ||
        lead['convertedUserId'] != null;
  }

  bool _canDeleteLead(Map<String, dynamic> lead) {
    if (lead.containsKey('canDelete')) {
      return lead['canDelete'] == true;
    }
    final activeRegs = (lead['activeRegistrationsCount'] as num?)?.toInt() ?? 0;
    final histRegs =
        (lead['historicalRegistrationsCount'] as num?)?.toInt() ?? 0;
    return !_isLeadConverted(lead) && activeRegs == 0 && histRegs == 0;
  }

  String _leadDeleteBlockReason(Map<String, dynamic> lead) {
    final serverReason = lead['deleteBlockReason']?.toString();
    if (serverReason != null && serverReason.trim().isNotEmpty) {
      return serverReason;
    }
    if (_isLeadConverted(lead)) {
      return 'Không thể xóa vĩnh viễn Lead đã chuyển đổi thành học viên chính thức. Vui lòng sử dụng Lưu trữ Lead để ẩn khỏi danh sách đang hoạt động.';
    }
    return 'Lead đang có dữ liệu đơn đăng ký hoặc lịch sử liên kết. Vui lòng Lưu trữ Lead hoặc Đóng Lead để bảo toàn lịch sử.';
  }

  void _upsertLocalLead(Map<String, dynamic> updated) {
    final unwrapped = updated['lead'] is Map
        ? Map<String, dynamic>.from(updated['lead'] as Map)
        : updated;
    final id = unwrapped['id']?.toString();
    if (id == null || id.isEmpty) return;
    final notesStr = (unwrapped['notes'] ?? '').toString();
    final computedArchived =
        unwrapped.containsKey('isArchived') && unwrapped['isArchived'] is bool
            ? unwrapped['isArchived'] as bool
            : notesStr.contains('[ARCHIVED');
    final normalized = <String, dynamic>{
      ...unwrapped,
      'isArchived': computedArchived,
    };
    setState(() {
      final index = _leads.indexWhere(
        (l) => l is Map && l['id']?.toString() == id,
      );
      if (index >= 0) {
        final next = List<dynamic>.from(_leads);
        final prev = Map<String, dynamic>.from(next[index] as Map);
        next[index] = {...prev, ...normalized};
        _leads = next;
      } else {
        _leads = [normalized, ..._leads];
      }
    });
  }

  void _removeLocalLead(String id) {
    setState(() {
      _leads = _leads
          .where((l) => l is! Map || l['id']?.toString() != id)
          .toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _crmTab = widget.initialTab;
    _fetchLeads(initial: true);
    _fetchBranches();
    _fetchRegistrations();
  }

  Future<void> _fetchBranches() async {
    try {
      final response = await _apiClient.get('/branches');
      final data = response is Map ? response['data'] ?? response : response;
      final items = data is List
          ? data
          : (data is Map && data['items'] is List
              ? data['items'] as List
              : (response is Map && response['items'] is List
                  ? response['items'] as List
                  : null));
      if (items != null && mounted) {
        setState(
          () => _branches = items
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
      _registrationPhoneToReview = phone;
      _searchController.text = phone;
      setState(() {});
      await _fetchLeads();
    }
  }

  Future<void> _fetchRegistrations() async {
    setState(() => _isLoadingRegistrations = true);
    try {
      final res = await _apiClient.get('/admissions/registrations');
      final data = res is Map && res.containsKey('data') ? res['data'] : res;
      if (data is List && mounted) {
        setState(() {
          _registrations = data
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingRegistrations = false);
    }
  }

  Future<void> _actOnRegistration(
    Map<String, dynamic> request, {
    String? reviewStatus,
  }) async {
    final id = '${request['id']}';
    final isApprove = reviewStatus == null;
    final title = reviewStatus == 'REJECTED'
        ? 'Từ chối đăng ký này?'
        : reviewStatus == 'CANCELLED'
        ? 'Hủy đơn đăng ký này?'
        : reviewStatus == 'REOPEN'
        ? 'Mở lại đơn đăng ký?'
        : reviewStatus == 'CONTACTED'
        ? 'Đánh dấu đã liên hệ?'
        : 'Xác nhận duyệt & ghi danh nhập học?';

    final guest = request['studentId'] == null;
    final lead = request['lead'] as Map?;
    final convertedId = lead?['convertedUserId'];

    final contentMessage = isApprove
        ? (guest && convertedId == null
            ? 'Khách mới chưa có tài khoản học viên. Bạn cần tạo tài khoản học viên (Chuyển đổi Lead) trước khi ghi danh vào lớp.'
            : 'Hệ thống sẽ ghi danh học viên vào lớp, lập hóa đơn học phí và cập nhật số chỗ của lớp trong một transaction an toàn.')
        : reviewStatus == 'REJECTED'
        ? 'Đơn đăng ký sẽ chuyển sang trạng thái ĐÃ TỪ CHỐI, không giữ chỗ trong lớp và được lưu vào lịch sử.'
        : reviewStatus == 'REOPEN'
        ? 'Đơn đăng ký sẽ được mở lại về trạng thái ĐÃ LIÊN HỆ để tiếp tục xử lý.'
        : 'Trạng thái đơn sẽ được cập nhật trong CRM.';

    final notesCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contentMessage),
            if (reviewStatus == 'REJECTED' ||
                reviewStatus == 'CANCELLED' ||
                reviewStatus == 'REOPEN') ...[
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: InputDecoration(
                  labelText: reviewStatus == 'REJECTED'
                      ? 'Lý do từ chối (tùy chọn)'
                      : 'Ghi chú xử lý (tùy chọn)',
                  hintText: reviewStatus == 'REJECTED'
                      ? 'VD: Hồ sơ thử nghiệm / Không phù hợp lịch học'
                      : 'Nhập ghi chú...',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 2,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          if (isApprove && guest && convertedId == null)
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext, false);
                final leadId = request['leadId'];
                if (leadId != null) {
                  _searchController.text = '${request['phone']}';
                  setState(() => _crmTab = 0);
                  _fetchLeads();
                }
              },
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Đến chuyển đổi Lead'),
            )
          else
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Xác nhận'),
            ),
        ],
      ),
    );
    final noteText = notesCtrl.text.trim();
    notesCtrl.dispose();

    if (confirmed != true || !mounted || _busyRegistrationId != null) return;
    setState(() => _busyRegistrationId = id);
    try {
      dynamic res;
      if (isApprove) {
        res = await _apiClient.post(
          '/admissions/registrations/$id/approve',
          data: <String, dynamic>{},
        );
      } else {
        res = await _apiClient.patch(
          '/admissions/registrations/$id/review',
          data: {
            'status': reviewStatus,
            if (noteText.isNotEmpty) 'notes': noteText,
          },
        );
      }
      if (!mounted) return;
      final payload = res is Map ? res['data'] ?? res : res;
      setState(() {
        final idx = _registrations.indexWhere((r) => '${r['id']}' == id);
        if (idx >= 0) {
          final next = List<Map<String, dynamic>>.from(_registrations);
          final nextStatus = isApprove
              ? 'APPROVED'
              : (reviewStatus == 'REOPEN' ? 'CONTACTED' : reviewStatus);
          next[idx] = {
            ...next[idx],
            if (payload is Map) ...Map<String, dynamic>.from(payload),
            'status': nextStatus,
            if (nextStatus == 'REJECTED' || nextStatus == 'CANCELLED')
              'canDelete': true,
          };
          _registrations = next;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isApprove
                ? '🎉 Đã duyệt và ghi danh học viên thành công! Đã tạo hóa đơn và cập nhật sĩ số lớp.'
                : reviewStatus == 'REJECTED'
                ? 'Đã từ chối đơn đăng ký và chuyển vào hồ sơ lịch sử.'
                : reviewStatus == 'REOPEN'
                ? 'Đã mở lại đơn đăng ký để tiếp tục tư vấn.'
                : 'Đã cập nhật trạng thái đơn đăng ký.',
          ),
          backgroundColor: isApprove ? const Color(0xFF15803D) : null,
        ),
      );
      _fetchRegistrations();
      _fetchLeads(silent: true);
      if (mounted) {
        context.read<ClassesBloc?>()?.add(const FetchClasses(refresh: true));
        if (isApprove) {
          context.read<FinanceBloc?>()?.add(FetchInvoicesEvent());
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _formatFriendlyError(
                error,
                fallback: 'Không thể xử lý đơn đăng ký lúc này.',
              ),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busyRegistrationId = null);
    }
  }

  Future<void> _deleteTestRegistration(Map<String, dynamic> request) async {
    final id = '${request['id']}';
    final fullName = '${request['fullName'] ?? 'Khách đăng ký'}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Expanded(child: Text('Xóa đơn đăng ký thử nghiệm?')),
          ],
        ),
        content: Text(
          'Đơn đăng ký đã từ chối/đã hủy của "$fullName" sẽ bị xóa vĩnh viễn khỏi hệ thống.\n\nSau khi xóa đơn thử nghiệm này, nếu lớp học chưa phát sinh dữ liệu khác thì bạn có thể xóa vĩnh viễn lớp thử nghiệm.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận xóa đơn'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted || _busyRegistrationId != null) return;
    setState(() => _busyRegistrationId = id);
    try {
      await _apiClient.delete('/admissions/registrations/$id');
      if (!mounted) return;
      setState(() {
        _registrations = _registrations
            .where((r) => '${r['id']}' != id)
            .toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa đơn đăng ký thử nghiệm thành công.'),
          backgroundColor: Color(0xFF047857),
        ),
      );
      _fetchRegistrations();
      _fetchLeads(silent: true);
      if (mounted) {
        context.read<ClassesBloc?>()?.add(const FetchClasses(refresh: true));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _formatFriendlyError(
                error,
                fallback: 'Không thể xóa đơn đăng ký thử nghiệm lúc này.',
              ),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busyRegistrationId = null);
    }
  }

  Future<void> _fetchLeads({bool initial = false, bool silent = false}) async {
    if (!initial && !silent && mounted) {
      setState(() {
        if (_leads.isEmpty) {
          _isLoading = true;
        }
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
          if (_leads.isEmpty && !silent) {
            _errorMessage = e.toString();
          }
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
                final res = await _apiClient.post(
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
                final created = res is Map ? res['data'] ?? res : res;
                if (created is Map) {
                  setState(() {
                    _leads = [
                      Map<String, dynamic>.from(created),
                      ..._leads.where(
                        (l) =>
                            l is! Map ||
                            l['id']?.toString() != created['id']?.toString(),
                      ),
                    ];
                  });
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã thêm lead vào CRM thành công!'),
                  ),
                );
                _fetchLeads(silent: true);
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
        if (!mounted) return;
        final pendingPhone = _registrationPhoneToReview?.replaceAll(
          RegExp(r'\D'),
          '',
        );
        final convertedPhone = '${lead['phone']}'.replaceAll(RegExp(r'\D'), '');
        if (pendingPhone != null && pendingPhone == convertedPhone) {
          _registrationPhoneToReview = null;
          await _openRegistrations();
        }
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
      final details = payload is Map
          ? Map<String, dynamic>.from(payload)
          : Map<String, dynamic>.from(lead);
      final isArchived = _isLeadArchived(details);
      final isClosed = _isLeadClosed(details);
      final canDelete = _canDeleteLead(details);
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.assignment_ind_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(details['fullName']?.toString() ?? 'Chi tiết Lead'),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Điện thoại: ${details['phone'] ?? ''}'),
                Text('Email: ${details['email'] ?? 'Chưa cập nhật'}'),
                Text('Khóa học quan tâm: ${details['targetCourse'] ?? 'Chưa ghi nhận'}'),
                Text('Nguồn: ${details['source'] ?? ''}'),
                Text('Trạng thái: ${details['status'] ?? ''}${isArchived ? ' (Đã lưu trữ)' : ''}'),
                if (details['closeReason'] != null)
                  Text('Lý do đóng: ${details['closeReason']}'),
                Text('Ghi chú: ${details['notes'] ?? ''}'),
                if (details['convertedUserId'] != null)
                  Text('ID học viên: ${details['convertedUserId']}'),
                if (!canDelete) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Text(
                      _leadDeleteBlockReason(details),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'edit'),
              child: const Text('Chỉnh sửa'),
            ),
            if (isArchived || isClosed)
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx, 'restore'),
                child: const Text('Khôi phục Lead'),
              )
            else ...[
              if (!_isLeadConverted(details))
                OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, 'close'),
                  child: const Text('Đóng Lead'),
                ),
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx, 'archive'),
                child: const Text('Lưu trữ'),
              ),
            ],
            if (canDelete)
              TextButton(
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                onPressed: () => Navigator.pop(ctx, 'delete'),
                child: const Text('Xóa Lead thử nghiệm'),
              ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
      if (!mounted || action == null) return;
      switch (action) {
        case 'edit':
          await _showEditLeadDialog(details);
          break;
        case 'close':
          await _showCloseLeadDialog(details);
          break;
        case 'archive':
          await _archiveLead(details);
          break;
        case 'restore':
          await _restoreLead(details);
          break;
        case 'delete':
          await _confirmDeleteLead(details);
          break;
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tải được chi tiết lead: $error')),
        );
      }
    }
  }

  Future<void> _showEditLeadDialog(Map<String, dynamic> lead) async {
    final nameCtrl = TextEditingController(
      text: lead['fullName']?.toString() ?? '',
    );
    final phoneCtrl = TextEditingController(
      text: lead['phone']?.toString() ?? '',
    );
    final emailCtrl = TextEditingController(
      text: lead['email']?.toString() ?? '',
    );
    final courseCtrl = TextEditingController(
      text: lead['targetCourse']?.toString() ?? '',
    );
    final notesCtrl = TextEditingController(
      text: lead['notes']?.toString() ?? '',
    );
    String source = lead['source']?.toString() ?? 'FACEBOOK';
    const validSources = ['FACEBOOK', 'DIRECT_WALKIN', 'WEBSITE', 'REFERRAL'];
    if (!validSources.contains(source)) {
      source = 'FACEBOOK';
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Expanded(child: Text('Chỉnh sửa thông tin Lead')),
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
                    labelText: 'Họ và tên khách hàng *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email',
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
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú tư vấn',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lưu thay đổi'),
          ),
        ],
      ),
    );

    final fullName = nameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final targetCourse = courseCtrl.text.trim();
    final notes = notesCtrl.text.trim();
    nameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    courseCtrl.dispose();
    notesCtrl.dispose();

    if (confirmed != true || !mounted || _busyLeadId != null) return;
    if (fullName.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ họ tên và SĐT.')),
      );
      return;
    }

    final leadId = '${lead['id']}';
    setState(() => _busyLeadId = leadId);
    try {
      final res = await _apiClient.patch(
        '/admissions/leads/$leadId',
        data: {
          'fullName': fullName,
          'phone': phone,
          'email': email.isEmpty ? null : email,
          'targetCourse': targetCourse,
          'source': source,
          'notes': notes,
        },
      );
      if (!mounted) return;
      final payload = res is Map ? res['data'] ?? res : res;
      if (payload is Map) {
        _upsertLocalLead(Map<String, dynamic>.from(payload));
      } else {
        _upsertLocalLead({
          ...lead,
          'fullName': fullName,
          'phone': phone,
          'email': email.isEmpty ? null : email,
          'targetCourse': targetCourse,
          'source': source,
          'notes': notes,
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật thông tin Lead thành công.')),
      );
      _fetchLeads(silent: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _formatFriendlyError(
                e,
                fallback: 'Không thể cập nhật thông tin Lead lúc này.',
              ),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busyLeadId = null);
    }
  }

  Future<void> _showCloseLeadDialog(Map<String, dynamic> lead) async {
    const reasons = <String>[
      'Không còn nhu cầu',
      'Không liên hệ được',
      'Đã chọn giải pháp khác',
      'Hồ sơ không hợp lệ',
      'Trùng hồ sơ',
      'Lý do khác',
    ];
    String selectedReason = reasons.first;
    final notesCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.cancel_presentation_rounded, color: Color(0xFFD97706)),
              SizedBox(width: 8),
              Expanded(child: Text('Đóng Lead / Không còn nhu cầu')),
            ],
          ),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đóng hồ sơ tư vấn của "${lead['fullName'] ?? ''}" (${lead['phone'] ?? ''}). Hồ sơ sẽ rời khỏi Pipeline đang hoạt động nhưng vẫn lưu lịch sử.',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedReason,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Lý do đóng Lead *',
                    border: OutlineInputBorder(),
                  ),
                  items: reasons
                      .map(
                        (r) => DropdownMenuItem<String>(
                          value: r,
                          child: Text(r),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDlgState(() => selectedReason = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú chi tiết (tùy chọn)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Xác nhận đóng Lead'),
            ),
          ],
        ),
      ),
    );
    final noteText = notesCtrl.text.trim();
    notesCtrl.dispose();

    if (confirmed != true || !mounted || _busyLeadId != null) return;
    final leadId = '${lead['id']}';
    setState(() => _busyLeadId = leadId);
    try {
      final res = await _apiClient.post(
        '/admissions/leads/$leadId/close',
        data: {
          'reason': selectedReason,
          if (noteText.isNotEmpty) 'notes': noteText,
        },
      );
      if (!mounted) return;
      final payload = res is Map ? res['data'] ?? res : res;
      if (payload is Map) {
        _upsertLocalLead(Map<String, dynamic>.from(payload));
      } else {
        _upsertLocalLead({
          ...lead,
          'status': 'CANCELLED',
          'closeReason': selectedReason,
          'notes': '[ĐÓNG LEAD - $selectedReason] $noteText'.trim(),
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã đóng Lead "${lead['fullName']}" ($selectedReason).',
          ),
        ),
      );
      _fetchLeads(silent: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _formatFriendlyError(
                e,
                fallback: 'Không thể đóng hồ sơ Lead lúc này.',
              ),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busyLeadId = null);
    }
  }

  Future<void> _archiveLead(Map<String, dynamic> lead) async {
    if (_busyLeadId != null) return;
    final leadId = '${lead['id']}';
    setState(() => _busyLeadId = leadId);
    try {
      final res = await _apiClient.post(
        '/admissions/leads/$leadId/archive',
        data: <String, dynamic>{},
      );
      if (!mounted) return;
      final payload = res is Map ? res['data'] ?? res : res;
      if (payload is Map) {
        _upsertLocalLead(Map<String, dynamic>.from(payload));
      } else {
        final prevStatus = lead['status']?.toString() ?? 'NEW';
        final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        _upsertLocalLead({
          ...lead,
          'isArchived': true,
          'archivedPreviousStatus': prevStatus,
          'notes': '[ARCHIVED:$prevStatus:$dateStr] ${lead['notes'] ?? ''}'
              .trim(),
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã lưu trữ Lead "${lead['fullName']}". Hồ sơ đã ẩn khỏi Pipeline hoạt động.',
          ),
          action: SnackBarAction(
            label: 'Xem đã lưu trữ',
            onPressed: () {
              if (mounted) {
                setState(() => _leadLifecycleFilter = 'ARCHIVED');
              }
            },
          ),
        ),
      );
      _fetchLeads(silent: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _formatFriendlyError(
                e,
                fallback: 'Không thể lưu trữ hồ sơ Lead lúc này.',
              ),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busyLeadId = null);
    }
  }

  Future<void> _restoreLead(Map<String, dynamic> lead) async {
    if (_busyLeadId != null) return;
    final leadId = '${lead['id']}';
    setState(() => _busyLeadId = leadId);
    try {
      final res = await _apiClient.post(
        '/admissions/leads/$leadId/restore',
        data: <String, dynamic>{},
      );
      if (!mounted) return;
      final payload = res is Map ? res['data'] ?? res : res;
      if (payload is Map) {
        _upsertLocalLead(Map<String, dynamic>.from(payload));
      } else {
        final prevStatus = lead['archivedPreviousStatus']?.toString();
        final nextStatus = (prevStatus != null && prevStatus != 'CANCELLED')
            ? prevStatus
            : (lead['status'] == 'CANCELLED' ? 'CONTACTED' : lead['status']);
        final cleanedNotes = (lead['notes']?.toString() ?? '')
            .replaceAll(RegExp(r'\[ARCHIVED:[^\]]+\]\s*'), '')
            .trim();
        _upsertLocalLead({
          ...lead,
          'isArchived': false,
          'status': nextStatus,
          'notes': cleanedNotes,
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã khôi phục Lead "${lead['fullName']}" về Pipeline đang hoạt động.',
          ),
          backgroundColor: const Color(0xFF047857),
        ),
      );
      _fetchLeads(silent: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _formatFriendlyError(
                e,
                fallback: 'Không thể khôi phục hồ sơ Lead lúc này.',
              ),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busyLeadId = null);
    }
  }

  Future<void> _showCannotDeleteLeadDialog(Map<String, dynamic> lead) async {
    final reason = _leadDeleteBlockReason(lead);
    final isArchived = _isLeadArchived(lead);
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Color(0xFFD97706)),
            SizedBox(width: 8),
            Expanded(child: Text('Không thể xóa vĩnh viễn Lead này')),
          ],
        ),
        content: Text(reason),
        actions: [
          if (!isArchived)
            FilledButton.tonal(
              onPressed: () => Navigator.pop(ctx, 'archive'),
              child: const Text('Lưu trữ Lead'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'dismiss'),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
    if (action == 'archive' && mounted) {
      await _archiveLead(lead);
    }
  }

  Future<void> _confirmDeleteLead(Map<String, dynamic> lead) async {
    if (!_canDeleteLead(lead)) {
      await _showCannotDeleteLeadDialog(lead);
      return;
    }
    final id = '${lead['id']}';
    final fullName = '${lead['fullName'] ?? 'Lead'}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Expanded(child: Text('Xác nhận xóa Lead thử nghiệm')),
          ],
        ),
        content: Text(
          'Hồ sơ Lead "$fullName" (${lead['phone'] ?? ''}) chưa chuyển đổi thành học viên và không có dữ liệu tài chính/nhập học liên kết.\n\nBạn có chắc chắn muốn xóa vĩnh viễn hồ sơ thử nghiệm này khỏi hệ thống?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận xóa vĩnh viễn'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted || _busyLeadId != null) return;
    setState(() => _busyLeadId = id);
    try {
      await _apiClient.delete('/admissions/leads/$id');
      if (!mounted) return;
      _removeLocalLead(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa Lead thử nghiệm "$fullName" thành công.'),
          backgroundColor: const Color(0xFF047857),
        ),
      );
      _fetchLeads(silent: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _formatFriendlyError(
                e,
                fallback: 'Không thể xóa hồ sơ Lead thử nghiệm lúc này.',
              ),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busyLeadId = null);
    }
  }

  Widget _buildLeadActionsMenu(Map<String, dynamic> lead) {
    final isBusy = _busyLeadId == '${lead['id']}';
    if (isBusy) {
      return const Padding(
        padding: EdgeInsets.all(6),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    final isArchived = _isLeadArchived(lead);
    final isClosed = _isLeadClosed(lead);
    final isConverted = _isLeadConverted(lead);
    final canDelete = _canDeleteLead(lead);

    return PopupMenuButton<String>(
      tooltip: 'Tùy chọn quản lý Lead',
      icon: const Icon(
        Icons.more_vert_rounded,
        size: 18,
        color: Color(0xFF64748B),
      ),
      padding: EdgeInsets.zero,
      onSelected: (value) async {
        switch (value) {
          case 'detail':
            await _showLeadDetail(lead);
            break;
          case 'edit':
            await _showEditLeadDialog(lead);
            break;
          case 'close':
            await _showCloseLeadDialog(lead);
            break;
          case 'archive':
            await _archiveLead(lead);
            break;
          case 'restore':
            await _restoreLead(lead);
            break;
          case 'delete':
            await _confirmDeleteLead(lead);
            break;
          case 'cannot_delete':
            await _showCannotDeleteLeadDialog(lead);
            break;
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          value: 'detail',
          child: Row(
            children: [
              Icon(Icons.visibility_outlined, size: 16),
              SizedBox(width: 8),
              Text('Xem chi tiết Lead'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 16),
              SizedBox(width: 8),
              Text('Chỉnh sửa thông tin'),
            ],
          ),
        ),
        if (!isClosed && !isConverted && !isArchived)
          const PopupMenuItem(
            value: 'close',
            child: Row(
              children: [
                Icon(
                  Icons.cancel_outlined,
                  size: 16,
                  color: Color(0xFFD97706),
                ),
                SizedBox(width: 8),
                Text(
                  'Đóng Lead (Không nhu cầu)',
                  style: TextStyle(color: Color(0xFFD97706)),
                ),
              ],
            ),
          ),
        if (isArchived || isClosed)
          const PopupMenuItem(
            value: 'restore',
            child: Row(
              children: [
                Icon(
                  Icons.restore_rounded,
                  size: 16,
                  color: Color(0xFF003FB1),
                ),
                SizedBox(width: 8),
                Text(
                  'Khôi phục Lead',
                  style: TextStyle(color: Color(0xFF003FB1)),
                ),
              ],
            ),
          )
        else
          const PopupMenuItem(
            value: 'archive',
            child: Row(
              children: [
                Icon(
                  Icons.archive_outlined,
                  size: 16,
                  color: Color(0xFF475569),
                ),
                SizedBox(width: 8),
                Text('Lưu trữ Lead'),
              ],
            ),
          ),
        if (canDelete)
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(
                  Icons.delete_outline_rounded,
                  size: 16,
                  color: Color(0xFFDC2626),
                ),
                SizedBox(width: 8),
                Text(
                  'Xóa Lead thử nghiệm',
                  style: TextStyle(color: Color(0xFFDC2626)),
                ),
              ],
            ),
          )
        else
          const PopupMenuItem(
            value: 'cannot_delete',
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
                SizedBox(width: 8),
                Text(
                  'Lý do không thể xóa',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1024;
    final todayStr = DateFormat('dd/MM/yyyy').format(DateTime.now());

    // Filter leads by search & lifecycle state
    final query = _searchController.text.trim().toLowerCase();
    final filteredLeads = _leads.where((raw) {
      final l = Map<String, dynamic>.from(raw as Map);
      final name = (l['fullName'] ?? '').toString().toLowerCase();
      final phone = (l['phone'] ?? '').toString().toLowerCase();
      final course = (l['targetCourse'] ?? '').toString().toLowerCase();
      final branch = l['branch'];
      final branchId = branch is Map
          ? branch['id']?.toString()
          : l['branchId']?.toString();

      final isArchived = _isLeadArchived(l);
      final isClosed = _isLeadClosed(l);
      final matchesLifecycle = switch (_leadLifecycleFilter) {
        'ACTIVE' => !isArchived && !isClosed,
        'CLOSED' => isClosed && !isArchived,
        'ARCHIVED' => isArchived,
        _ => true,
      };

      return matchesLifecycle &&
          (name.contains(query) ||
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
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _crmTab = 0),
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _crmTab == 0 ? AppColors.primary : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_alt_rounded,
                              size: 18,
                              color: _crmTab == 0 ? Colors.white : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tư vấn chung (${_leads.length} Leads)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: _crmTab == 0 ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() => _crmTab = 1);
                        _fetchRegistrations();
                      },
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _crmTab == 1 ? AppColors.primary : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(11)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.how_to_reg_rounded,
                              size: 18,
                              color: _crmTab == 1 ? Colors.white : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Đăng ký lớp học (${_registrations.length} đơn)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: _crmTab == 1 ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                            if (_registrations.any((r) => r['status'] == 'PENDING')) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _crmTab == 1 ? Colors.amber.shade400 : Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_registrations.where((r) => r['status'] == 'PENDING').length} mới',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _crmTab == 1 ? Colors.brown.shade900 : Colors.amber.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_crmTab == 1)
              _buildClassRegistrationsView(isDesktop)
            else ...[
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
                final activeOpenLeads = _leads.where((raw) {
                  final l = Map<String, dynamic>.from(raw as Map);
                  return !_isLeadArchived(l) && !_isLeadClosed(l);
                }).length;
                final closedOrArchivedLeads = _leads.where((raw) {
                  final l = Map<String, dynamic>.from(raw as Map);
                  return _isLeadArchived(l) || _isLeadClosed(l);
                }).length;
                final pendingLeads = _leads.where((raw) {
                  final l = Map<String, dynamic>.from(raw as Map);
                  if (_isLeadArchived(l) || _isLeadClosed(l)) return false;
                  final st = (l['status'] ?? 'NEW').toString();
                  return st == 'NEW' || st == 'CONTACTED';
                }).length;
                final testLeads = _leads.where((raw) {
                  final l = Map<String, dynamic>.from(raw as Map);
                  if (_isLeadArchived(l) || _isLeadClosed(l)) return false;
                  final st = (l['status'] ?? '').toString();
                  return st == 'TEST_SCHEDULED' ||
                      st == 'TESTING' ||
                      st == 'TESTED';
                }).length;
                final enrolledLeads = _leads.where((raw) {
                  final l = Map<String, dynamic>.from(raw as Map);
                  return _isLeadConverted(l);
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
                      subtext:
                          'Đang mở: $activeOpenLeads • Đóng/Lưu trữ: $closedOrArchivedLeads',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
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
                                onTap: () =>
                                    setState(() => _isKanbanView = false),
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
                              border:
                                  Border.all(color: const Color(0xFFCBD5E1)),
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
                                      child:
                                          Text(branch['name']?.toString() ?? ''),
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
                              border:
                                  Border.all(color: const Color(0xFFCBD5E1)),
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
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final entry in const <String, String>{
                          'ACTIVE': 'Pipeline đang hoạt động',
                          'CLOSED': 'Đã đóng / Không nhu cầu',
                          'ARCHIVED': 'Đã lưu trữ',
                          'ALL': 'Tất cả hồ sơ',
                        }.entries)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(entry.value),
                              selected: _leadLifecycleFilter == entry.key,
                              onSelected: (_) {
                                setState(() {
                                  _leadLifecycleFilter = entry.key;
                                  if (entry.key == 'CLOSED' && _isKanbanView) {
                                    _isKanbanView = false;
                                  }
                                });
                              },
                            ),
                          ),
                      ],
                    ),
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
            final isArchived = _isLeadArchived(lead);
            final isClosed = _isLeadClosed(lead);
            final next = (isArchived || isClosed)
                ? null
                : switch (stageFor(status)) {
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
                      _buildLeadActionsMenu(lead),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Trạng thái: ${isClosed ? 'Đã đóng' : (stages[stageFor(status)] ?? status)}${isArchived ? ' • Đã lưu trữ' : ''}',
                  ),
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
            final l = Map<String, dynamic>.from(lead as Map);
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
                      const SizedBox(width: 2),
                      _buildLeadActionsMenu(l),
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
                          width: 140,
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
                      final l = Map<String, dynamic>.from(leads[idx] as Map);
                      final isArchived = _isLeadArchived(l);
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
                                '${l['fullName'] ?? 'N/A'}${isArchived ? ' (Lưu trữ)' : ''}',
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
                              width: 140,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => _showLeadDetail(l),
                                    child: const Text(
                                      'Chi tiết',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF003FB1),
                                      ),
                                    ),
                                  ),
                                  _buildLeadActionsMenu(l),
                                ],
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

  Widget _buildClassRegistrationsView(bool isDesktop) {
    if (_isLoadingRegistrations) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final query = _searchController.text.trim().toLowerCase();
    final filtered = _registrations.where((req) {
      final name = '${req['fullName']}'.toLowerCase();
      final phone = '${req['phone']}'.toLowerCase();
      final classInfo = req['class'] as Map?;
      final className = '${classInfo?['name']}'.toLowerCase();
      final classCode = '${classInfo?['code']}'.toLowerCase();
      final status = '${req['status']}';

      final matchesQuery = query.isEmpty ||
          name.contains(query) ||
          phone.contains(query) ||
          className.contains(query) ||
          classCode.contains(query);

      final matchesStatus =
          _registrationFilter == 'ALL' || status == _registrationFilter;
      return matchesQuery && matchesStatus;
    }).toList();

    final total = _registrations.length;
    final pending =
        _registrations.where((r) => r['status'] == 'PENDING').length;
    final contacted =
        _registrations.where((r) => r['status'] == 'CONTACTED').length;
    final approved =
        _registrations.where((r) => r['status'] == 'APPROVED').length;
    final rejected =
        _registrations.where((r) => r['status'] == 'REJECTED').length;
    final cancelled =
        _registrations.where((r) => r['status'] == 'CANCELLED').length;
    final closedCount = rejected + cancelled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hàng chờ Đăng ký Lớp học',
                      style: AppTextStyles.h2(context).copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Khách mới và học viên gửi yêu cầu đăng ký lớp đích danh từ Website hoặc Cổng học viên.',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _fetchRegistrations,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Làm mới hàng chờ',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (ctx, constraints) {
            final cardWidth = isDesktop
                ? (constraints.maxWidth - 64) / 5
                : (constraints.maxWidth - 16) / 2;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildRegistrationMetricCard(
                  'Tổng đơn đăng ký',
                  '$total',
                  Icons.inbox_rounded,
                  const Color(0xFF2563EB),
                  cardWidth,
                ),
                _buildRegistrationMetricCard(
                  'Chờ xử lý',
                  '$pending',
                  Icons.pending_actions_rounded,
                  const Color(0xFFD97706),
                  cardWidth,
                ),
                _buildRegistrationMetricCard(
                  'Đã liên hệ',
                  '$contacted',
                  Icons.phone_in_talk_rounded,
                  const Color(0xFF0284C7),
                  cardWidth,
                ),
                _buildRegistrationMetricCard(
                  'Đã nhập học',
                  '$approved',
                  Icons.check_circle_rounded,
                  const Color(0xFF16A34A),
                  cardWidth,
                ),
                _buildRegistrationMetricCard(
                  'Đã từ chối / Đã đóng',
                  '$closedCount',
                  Icons.block_rounded,
                  const Color(0xFFDC2626),
                  cardWidth,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
                    hintText: 'Tìm theo tên, SĐT, lớp...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (final entry in const <String, String>{
                    'ALL': 'Tất cả',
                    'PENDING': 'Chờ xử lý',
                    'CONTACTED': 'Đã liên hệ',
                    'APPROVED': 'Đã nhập học',
                    'REJECTED': 'Từ chối',
                    'CANCELLED': 'Đã hủy',
                  }.entries)
                    FilterChip(
                      label: Text(entry.value),
                      selected: _registrationFilter == entry.key,
                      onSelected: (_) =>
                          setState(() => _registrationFilter = entry.key),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (filtered.isEmpty)
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
                Icon(
                  Icons.assignment_late_outlined,
                  size: 48,
                  color: Color(0xFF94A3B8),
                ),
                SizedBox(height: 12),
                Text(
                  'Không tìm thấy đơn đăng ký nào trong bộ lọc này.',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          )
        else
          LayoutBuilder(
            builder: (ctx, constraints) {
              final cardWidth = constraints.maxWidth >= 900
                  ? (constraints.maxWidth - 16) / 2
                  : double.infinity;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final item in filtered)
                    SizedBox(
                      width: cardWidth,
                      child: _buildRegistrationItemCard(item),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildRegistrationItemCard(Map<String, dynamic> item) {
    final status = '${item['status']}';
    final id = '${item['id']}';
    final isPending = status == 'PENDING' || status == 'CONTACTED';
    final isTerminal = status == 'REJECTED' || status == 'CANCELLED';
    final canDelete = isTerminal && item['canDelete'] != false;
    final isGuest = item['studentId'] == null;
    final lead = item['lead'] as Map?;
    final convertedId = lead?['convertedUserId'];
    final classInfo = item['class'] as Map?;
    final course = classInfo?['course'] as Map?;
    final branch = classInfo?['branch'] as Map?;
    final room = classInfo?['room'] as Map?;

    final capacity =
        num.tryParse(
          '${classInfo?['maxCapacity'] ?? classInfo?['capacity']}',
        )?.toInt() ??
        20;
    final enrolledCount =
        num.tryParse('${classInfo?['enrolledCount']}')?.toInt() ??
        (classInfo?['students'] as List?)?.length ??
        0;
    final remaining = capacity - enrolledCount;

    final statusStyle = switch (status) {
      'APPROVED' => (
        'ĐÃ NHẬP HỌC',
        const Color(0xFF15803D),
        const Color(0xFFDCFCE7),
      ),
      'CONTACTED' => (
        'ĐÃ LIÊN HỆ',
        const Color(0xFF1D4ED8),
        const Color(0xFFDBEAFE),
      ),
      'REJECTED' => (
        'TỪ CHỐI',
        const Color(0xFFB91C1C),
        const Color(0xFFFEE2E2),
      ),
      'CANCELLED' => (
        'ĐÃ HỦY',
        const Color(0xFF475569),
        const Color(0xFFF1F5F9),
      ),
      _ => ('CHỜ XỬ LÝ', const Color(0xFFB45309), const Color(0xFFFEF3C7)),
    };

    final isBusy = _busyRegistrationId == id;

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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${item['fullName']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isGuest
                                  ? const Color(0xFFFFF7ED)
                                  : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isGuest
                                    ? const Color(0xFFFDBA74)
                                    : const Color(0xFF93C5FD),
                              ),
                            ),
                            child: Text(
                              isGuest ? 'Khách mới' : 'Học viên hiện tại',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isGuest
                                    ? const Color(0xFFC2410C)
                                    : const Color(0xFF1D4ED8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '📞 ${item['phone']}${item['email'] != null ? " • ✉️ ${item['email']}" : ""}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusStyle.$3,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusStyle.$1,
                    style: TextStyle(
                      color: statusStyle.$2,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.school_rounded,
                        size: 16,
                        color: Color(0xFF3B82F6),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${classInfo?['name'] ?? "Lớp học"} (${classInfo?['code'] ?? ""})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Khóa học: ${course?['title'] ?? ""} • ${branch?['name'] ?? ""}${room != null ? " · ${room['name']}" : ""}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Lịch: ${classInfo?['startTime'] ?? ""} - ${classInfo?['endTime'] ?? ""}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        'Sĩ số: $enrolledCount/$capacity (Còn $remaining chỗ)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: remaining <= 0
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isTerminal) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.history_edu_rounded,
                      size: 15,
                      color: Color(0xFF475569),
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Hồ sơ lịch sử • Không giữ chỗ trong lớp',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (item['notes'] != null && '${item['notes']}'.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Ghi chú: ${item['notes']}',
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
            if (isGuest && convertedId == null && isPending) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: Color(0xFFD97706),
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Khách mới cần tạo tài khoản học viên trước khi ghi danh.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            if (isBusy)
              const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (isPending)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  TextButton(
                    onPressed: () =>
                        _actOnRegistration(item, reviewStatus: 'REJECTED'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    child: const Text('Từ chối'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        _actOnRegistration(item, reviewStatus: 'CONTACTED'),
                    icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                    label: const Text('Liên hệ'),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF15803D),
                    ),
                    onPressed: () => _actOnRegistration(item),
                    icon: const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 16,
                    ),
                    label: const Text('Duyệt & Ghi danh'),
                  ),
                ],
              )
            else if (isTerminal)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  if (canDelete)
                    TextButton.icon(
                      onPressed: () => _deleteTestRegistration(item),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: const Text('Xóa đơn thử nghiệm'),
                    ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        _actOnRegistration(item, reviewStatus: 'REOPEN'),
                    icon: const Icon(Icons.restore_rounded, size: 16),
                    label: const Text('Mở lại đơn'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
    double width,
  ) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
