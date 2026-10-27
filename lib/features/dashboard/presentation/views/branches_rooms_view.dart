import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/di/injection.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/empty_state_widget.dart';

class BranchesRoomsView extends StatefulWidget {
  const BranchesRoomsView({super.key});

  @override
  State<BranchesRoomsView> createState() => _BranchesRoomsViewState();
}

class _BranchesRoomsViewState extends State<BranchesRoomsView> {
  final ApiClient _apiClient = getIt<ApiClient>();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _branches = [];
  List<dynamic> _rooms = [];
  List<dynamic> _classes = [];
  final List<Map<String, dynamic>> _maintenanceLogs = [];

  String? _selectedBranchId;
  String _selectedFloor = 'ALL';
  String _selectedStatus = 'ALL';
  int _activeTab = 0; // 0: Rooms, 1: Branches, 2: Equipments, 3: Maintenance

  @override
  void initState() {
    super.initState();
    _fetchBranches(initial: true);
  }

  @override
  void reassemble() {
    super.reassemble();
    _fetchBranches(initial: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _fetchBranches({bool initial = false}) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final results = await Future.wait([
        _apiClient.get('/branches'),
        _apiClient
            .get('/classes', queryParameters: {'limit': 100})
            .catchError((_) => <String, dynamic>{}),
      ]);

      final branchItems = _extractList(results[0]);
      final classItems = _extractList(results[1]);

      if (mounted) {
        setState(() {
          _branches = branchItems;
          _classes = classItems;
          if (_branches.isNotEmpty) {
            final stillExists = _branches.any(
              (b) => b['id']?.toString() == _selectedBranchId,
            );
            if (_selectedBranchId == null || !stillExists) {
              _selectedBranchId = _branches.first['id']?.toString();
            }
          }
        });
      }

      if (_selectedBranchId != null) {
        await _fetchRooms(_selectedBranchId!);
      } else if (mounted) {
        setState(() => _isLoading = false);
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

  Future<void> _fetchRooms(String branchId) async {
    try {
      final res = await _apiClient.get('/branches/$branchId/rooms');
      final roomItems = _extractList(res);

      if (mounted) {
        setState(() {
          _rooms = roomItems;
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

  int _inferFloor(Map<String, dynamic> room) {
    if (room['floor'] is int) return room['floor'] as int;
    final code = (room['code'] ?? '').toString().replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    if (code.length >= 3) {
      return int.tryParse(code.substring(0, 1)) ?? 1;
    }
    return 1;
  }

  List<Map<String, dynamic>> _getClassesForRoom(Map<String, dynamic> room) {
    final roomId = room['id']?.toString();
    final roomCode = room['code']?.toString();
    final matched = <Map<String, dynamic>>[];

    for (final c in _classes) {
      if (c is Map) {
        final cMap = Map<String, dynamic>.from(c);
        final cRoomId =
            cMap['roomId']?.toString() ??
            (cMap['room'] is Map ? cMap['room']['id']?.toString() : null);
        final cRoomCode = cMap['room'] is Map
            ? cMap['room']['code']?.toString()
            : null;
        if ((roomId != null && cRoomId == roomId) ||
            (roomCode != null && cRoomCode == roomCode)) {
          matched.add(cMap);
        }
      }
    }
    return matched;
  }

  String _getRoomOperationalStatus(Map<String, dynamic> room) {
    if (room['isActive'] == false || room['status'] == 'MAINTENANCE') {
      return 'MAINTENANCE';
    }
    final assignedClasses = _getClassesForRoom(room);
    if (assignedClasses.isNotEmpty) {
      return 'OCCUPIED';
    }
    return 'AVAILABLE';
  }

  List<String> _parseEquipmentList(Map<String, dynamic> room) {
    final raw = (room['equipment'] ?? '').toString().trim();
    if (raw.isEmpty) return [];
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  // ---------------------------------------------------------------------------
  // DIALOGS: ADD / EDIT BRANCH & ROOM & EQUIPMENT & MAINTENANCE
  // ---------------------------------------------------------------------------

  void _showAddBranchDialog({Map<String, dynamic>? existingBranch}) {
    final isEdit = existingBranch != null;
    final codeCtrl = TextEditingController(
      text: existingBranch?['code']?.toString() ?? '',
    );
    final nameCtrl = TextEditingController(
      text: existingBranch?['name']?.toString() ?? '',
    );
    final addressCtrl = TextEditingController(
      text: existingBranch?['address']?.toString() ?? '',
    );
    final phoneCtrl = TextEditingController(
      text: existingBranch?['phone']?.toString() ?? '',
    );
    final emailCtrl = TextEditingController(
      text: existingBranch?['email']?.toString() ?? '',
    );
    bool isActive = existingBranch?['isActive'] != false;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.domain_add_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                isEdit ? 'Chỉnh sửa Chi nhánh' : 'Thêm Chi Nhánh Mới',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
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
                    controller: codeCtrl,
                    enabled: !isEdit,
                    decoration: const InputDecoration(
                      labelText: 'Mã chi nhánh * (Chữ hoa, số, gạch ngang)',
                      hintText: 'VD: BR-Q3',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tên chi nhánh *',
                      hintText: 'VD: Chi nhánh Quận 3 - Hồ Chí Minh',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ cơ sở *',
                      hintText: 'VD: 240 Võ Văn Tần, Quận 3, TP.HCM',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: phoneCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Số điện thoại hotline',
                            hintText: '02838123456',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: emailCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Email liên hệ',
                            hintText: 'q3@lms-edu.vn',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isEdit) ...[
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Trạng thái vận hành chi nhánh',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        isActive
                            ? 'Đang hoạt động tuyển sinh & giảng dạy'
                            : 'Tạm ngưng hoạt động',
                      ),
                      value: isActive,
                      activeColor: const Color(0xFF003FB1),
                      onChanged: (v) => setDialogState(() => isActive = v),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Hủy bỏ'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003FB1),
                foregroundColor: Colors.white,
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final code = codeCtrl.text.trim().toUpperCase();
                      final name = nameCtrl.text.trim();
                      final address = addressCtrl.text.trim();
                      if ((!isEdit && code.isEmpty) ||
                          name.isEmpty ||
                          address.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Vui lòng nhập đầy đủ mã, tên và địa chỉ chi nhánh!',
                            ),
                          ),
                        );
                        return;
                      }
                      setDialogState(() => isSubmitting = true);
                      try {
                        if (isEdit) {
                          await _apiClient.patch(
                            '/branches/${existingBranch['id']}',
                            data: {
                              'name': name,
                              'address': address,
                              if (phoneCtrl.text.trim().isNotEmpty)
                                'phone': phoneCtrl.text.trim(),
                              if (emailCtrl.text.trim().isNotEmpty)
                                'email': emailCtrl.text.trim(),
                              'isActive': isActive,
                            },
                          );
                        } else {
                          await _apiClient.post(
                            '/branches',
                            data: {
                              'code': code,
                              'name': name,
                              'address': address,
                              if (phoneCtrl.text.trim().isNotEmpty)
                                'phone': phoneCtrl.text.trim(),
                              if (emailCtrl.text.trim().isNotEmpty)
                                'email': emailCtrl.text.trim(),
                            },
                          );
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                        await _fetchBranches();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isEdit
                                    ? 'Đã cập nhật chi nhánh "$name" thành công!'
                                    : 'Đã tạo chi nhánh "$name" thành công!',
                              ),
                              backgroundColor: const Color(0xFF047857),
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Lỗi: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: Text(
                isSubmitting
                    ? 'Đang lưu...'
                    : (isEdit ? 'Lưu thay đổi' : 'Tạo chi nhánh'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddOrEditRoomDialog({
    Map<String, dynamic>? existingRoom,
    String? forceBranchId,
  }) {
    final isEdit = existingRoom != null;
    String? branchId =
        forceBranchId ??
        existingRoom?['branchId']?.toString() ??
        _selectedBranchId ??
        (_branches.isNotEmpty ? _branches.first['id']?.toString() : null);

    final codeCtrl = TextEditingController(
      text: existingRoom?['code']?.toString() ?? '',
    );
    final nameCtrl = TextEditingController(
      text: existingRoom?['name']?.toString() ?? '',
    );
    final capCtrl = TextEditingController(
      text: (existingRoom?['capacity'] ?? 20).toString(),
    );
    final equipCtrl = TextEditingController(
      text:
          existingRoom?['equipment']?.toString() ??
          'Máy chiếu, Bảng trắng, Điều hòa',
    );
    bool isActive = existingRoom?['isActive'] != false;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.meeting_room_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                isEdit
                    ? 'Cập nhật Phòng Học (${existingRoom['code']})'
                    : 'Thêm Phòng Học Mới',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
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
                  if (!isEdit && _branches.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: branchId,
                      decoration: const InputDecoration(
                        labelText: 'Thuộc Chi nhánh *',
                        border: OutlineInputBorder(),
                      ),
                      items: _branches.map((b) {
                        return DropdownMenuItem<String>(
                          value: b['id']?.toString(),
                          child: Text(b['name']?.toString() ?? 'Chi nhánh'),
                        );
                      }).toList(),
                      onChanged: (v) => setDialogState(() => branchId = v),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: codeCtrl,
                          enabled: !isEdit,
                          decoration: const InputDecoration(
                            labelText: 'Mã phòng *',
                            hintText: 'VD: P103',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: capCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Sức chứa (chỗ) *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tên phòng học *',
                      hintText: 'VD: Phòng Học Thông Minh 103',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: equipCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Trang thiết bị (phân cách bằng dấu phẩy)',
                      hintText: 'VD: Máy chiếu 4K, Loa trợ giảng, Bảng trắng, Điều hòa',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (isEdit) ...[
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Trạng thái sẵn sàng đón học viên',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        isActive
                            ? 'Đang hoạt động bình thường'
                            : 'Đang tạm khóa để Bảo trì kỹ thuật',
                        style: TextStyle(
                          color: isActive
                              ? const Color(0xFF047857)
                              : const Color(0xFFB91C1C),
                          fontSize: 12,
                        ),
                      ),
                      value: isActive,
                      activeColor: const Color(0xFF003FB1),
                      onChanged: (v) => setDialogState(() => isActive = v),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Hủy bỏ'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003FB1),
                foregroundColor: Colors.white,
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final code = codeCtrl.text.trim().toUpperCase();
                      final name = nameCtrl.text.trim();
                      final cap = int.tryParse(capCtrl.text.trim()) ?? 20;
                      final equip = equipCtrl.text.trim();

                      if ((!isEdit && (code.isEmpty || branchId == null)) ||
                          name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Vui lòng nhập đầy đủ mã phòng và tên phòng!',
                            ),
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isSubmitting = true);
                      try {
                        if (isEdit) {
                          await _apiClient.patch(
                            '/rooms/${existingRoom['id']}',
                            data: {
                              'name': name,
                              'capacity': cap,
                              'equipment': equip,
                              'isActive': isActive,
                            },
                          );
                        } else {
                          await _apiClient.post(
                            '/rooms',
                            data: {
                              'branchId': branchId,
                              'code': code,
                              'name': name,
                              'capacity': cap,
                              'equipment': equip,
                            },
                          );
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (branchId != null) {
                          _selectedBranchId = branchId;
                        }
                        await _fetchBranches();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isEdit
                                    ? 'Đã cập nhật thông tin phòng ${existingRoom['code']}!'
                                    : 'Đã thêm phòng $code vào cơ sở dữ liệu thành công!',
                              ),
                              backgroundColor: const Color(0xFF047857),
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Lỗi lưu phòng học: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: Text(
                isSubmitting
                    ? 'Đang lưu...'
                    : (isEdit ? 'Lưu cập nhật' : 'Thêm phòng'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleRoomMaintenance(Map<String, dynamic> room) async {
    final currentActive = room['isActive'] != false;
    final nextActive = !currentActive;
    final code = room['code'] ?? 'Phòng';

    try {
      await _apiClient.patch(
        '/rooms/${room['id']}',
        data: {'isActive': nextActive},
      );
      setState(() {
        _maintenanceLogs.insert(0, {
          'roomCode': code,
          'roomName': room['name'] ?? '',
          'action': nextActive
              ? 'Hoàn tất bảo trì • Mở lại phòng học'
              : 'Chuyển sang trạng thái Bảo trì kỹ thuật',
          'timestamp': DateFormat('HH:mm - dd/MM/yyyy').format(DateTime.now()),
          'status': nextActive ? 'RESOLVED' : 'MAINTENANCE',
        });
      });
      if (_selectedBranchId != null) {
        await _fetchRooms(_selectedBranchId!);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nextActive
                  ? 'Phòng $code đã hoàn tất bảo trì và sẵn sàng hoạt động!'
                  : 'Đã chuyển phòng $code sang chế độ Bảo trì!',
            ),
            backgroundColor: nextActive
                ? const Color(0xFF047857)
                : const Color(0xFFD97706),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể đổi trạng thái phòng: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRoomScheduleDialog(Map<String, dynamic> room) {
    final code = room['code'] ?? '';
    final name = room['name'] ?? '';
    final assignedClasses = _getClassesForRoom(room);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, color: Color(0xFF003FB1)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Lịch sử dụng Phòng $code - $name',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: assignedClasses.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event_available_rounded,
                        size: 48,
                        color: Color(0xFF94A3B8),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Phòng học hiện đang trống, chưa có lớp học nào xếp lịch cố định.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: assignedClasses.map((c) {
                    final classCode = c['code']?.toString() ?? '';
                    final className = c['name']?.toString() ?? '';
                    final teacherName = c['teacher'] is Map
                        ? (c['teacher']['fullName']?.toString() ??
                              'Chưa phân công')
                        : 'Chưa phân công';
                    final enrolled = c['_count'] is Map
                        ? (c['_count']['enrollments'] ?? 0)
                        : 0;
                    final maxStudents =
                        c['maxStudents'] ?? room['capacity'] ?? 20;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
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
                              Text(
                                '$classCode • $className',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
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
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$enrolled / $maxStudents HV',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF047857),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Giảng viên: $teacherName',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003FB1),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _showAddOrEditRoomDialog(existingRoom: room);
            },
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: const Text('Chỉnh sửa phòng'),
          ),
        ],
      ),
    );
  }

  void _showExportSummaryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.table_view_rounded, color: Color(0xFF003FB1)),
            SizedBox(width: 8),
            Text(
              'Báo cáo Sơ đồ Cơ sở & Phòng học',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        content: SizedBox(
          width: 540,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tổng hợp dữ liệu thời gian thực từ hệ thống (${_branches.length} chi nhánh • ${_rooms.length} phòng học):',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 12),
                ..._rooms.map((r) {
                  final map = Map<String, dynamic>.from(r as Map);
                  final classes = _getClassesForRoom(map);
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.meeting_room_rounded,
                      color: Color(0xFF003FB1),
                    ),
                    title: Text(
                      '${map['code']} - ${map['name']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Sức chứa: ${map['capacity']} chỗ • Thiết bị: ${map['equipment'] ?? 'Chưa cập nhật'} • Lớp đang học: ${classes.length} lớp',
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _exportBranchesRoomsCsv();
            },
            child: const Text('Xuất CSV'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBranchesRoomsCsv() async {
    try {
      final rows = <List<String>>[
        [
          'Mã chi nhánh',
          'Tên chi nhánh',
          'Mã phòng',
          'Tên phòng',
          'Sức chứa',
          'Thiết bị',
          'Hoạt động',
        ],
      ];
      for (final rawBranch in _branches) {
        final branch = Map<String, dynamic>.from(rawBranch as Map);
        final branchId = branch['id']?.toString();
        if (branchId == null) continue;
        final response = await _apiClient.get('/branches/$branchId/rooms');
        for (final rawRoom in _extractList(response)) {
          final room = Map<String, dynamic>.from(rawRoom as Map);
          rows.add([
            branch['code']?.toString() ?? '',
            branch['name']?.toString() ?? '',
            room['code']?.toString() ?? '',
            room['name']?.toString() ?? '',
            room['capacity']?.toString() ?? '',
            room['equipment']?.toString() ?? '',
            room['isActive'] == false ? 'Không' : 'Có',
          ]);
        }
      }
      String csvCell(String value) => '"${value.replaceAll('"', '""')}"';
      final csv =
          '\uFEFF${rows.map((row) => row.map(csvCell).join(',')).join('\r\n')}';
      final saved = await FilePicker.saveFile(
        fileName: 'chi-nhanh-phong-hoc.csv',
        bytes: Uint8List.fromList(utf8.encode(csv)),
        mimeType: 'text/csv',
      );
      if (saved != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xuất danh sách chi nhánh và phòng học.'),
          ),
        );
      }
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể xuất danh sách phòng học: $error')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1024;
    final todayStr = DateFormat('dd/MM/yyyy').format(DateTime.now());

    // Filter rooms by search, floor, and status
    final query = _searchController.text.trim().toLowerCase();
    final filteredRooms = _rooms.where((rawRoom) {
      final r = Map<String, dynamic>.from(rawRoom as Map);
      if (query.isNotEmpty) {
        final code = (r['code'] ?? '').toString().toLowerCase();
        final name = (r['name'] ?? '').toString().toLowerCase();
        final equip = (r['equipment'] ?? '').toString().toLowerCase();
        if (!code.contains(query) &&
            !name.contains(query) &&
            !equip.contains(query)) {
          return false;
        }
      }
      if (_selectedFloor != 'ALL') {
        final floor = _inferFloor(r).toString();
        if (floor != _selectedFloor) return false;
      }
      if (_selectedStatus != 'ALL') {
        final st = _getRoomOperationalStatus(r);
        if (st != _selectedStatus) return false;
      }
      return true;
    }).toList();

    final maintenanceCount = _rooms
        .where((r) => (r as Map)['isActive'] == false)
        .length;
    final occupiedCount = _rooms
        .where(
          (r) =>
              _getRoomOperationalStatus(Map<String, dynamic>.from(r as Map)) ==
              'OCCUPIED',
        )
        .length;
    final availableCount = _rooms
        .where(
          (r) =>
              _getRoomOperationalStatus(Map<String, dynamic>.from(r as Map)) ==
              'AVAILABLE',
        )
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. PAGE HEADING & QUICK ACTIONS
            Container(
              padding: const EdgeInsets.only(bottom: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildHeaderTitle(todayStr)),
                        const SizedBox(width: 16),
                        _buildHeaderActions(),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderTitle(todayStr),
                        const SizedBox(height: 12),
                        _buildHeaderActions(),
                      ],
                    ),
            ),
            const SizedBox(height: 20),

            // 2. 4 KPI STAT CARDS (100% Real PostgreSQL Metrics)
            LayoutBuilder(
              builder: (ctx, constraints) {
                final cardWidth = isDesktop
                    ? (constraints.maxWidth - 48) / 4
                    : (constraints.maxWidth - 16) / 2;
                final branchCount = _branches.length;
                final roomCount = _rooms.length;
                final totalCapacity = _rooms.fold<int>(
                  0,
                  (sum, r) => sum + (((r as Map)['capacity'] as int?) ?? 0),
                );
                final activeRooms = roomCount - maintenanceCount;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildStatCard(
                      title: 'Tổng số chi nhánh',
                      value: '$branchCount cơ sở',
                      subtext: branchCount > 0
                          ? (_branches.first['name']?.toString() ??
                                'Đang hoạt động')
                          : 'Chưa có chi nhánh',
                      icon: Icons.apartment_rounded,
                      iconBg: const Color(0xFFEEF2FF),
                      iconColor: const Color(0xFF003FB1),
                      width: cardWidth,
                      onTap: () => setState(() => _activeTab = 1),
                    ),
                    _buildStatCard(
                      title: 'Tổng số phòng học',
                      value: '$roomCount phòng',
                      subtext:
                          '$activeRooms hoạt động • $maintenanceCount bảo trì',
                      icon: Icons.meeting_room_rounded,
                      iconBg: const Color(0xFFEFF6FF),
                      iconColor: const Color(0xFF2563EB),
                      pillColor: const Color(0xFFECFDF5),
                      pillTextColor: const Color(0xFF047857),
                      width: cardWidth,
                      onTap: () => setState(() => _activeTab = 0),
                    ),
                    _buildStatCard(
                      title: 'Tổng sức chứa học viên',
                      value: '$totalCapacity chỗ',
                      subtext: roomCount > 0
                          ? 'Trung bình ${(totalCapacity / roomCount).toStringAsFixed(0)} chỗ/phòng'
                          : '0 chỗ/phòng',
                      icon: Icons.pie_chart_rounded,
                      iconBg: const Color(0xFFF0FDF4),
                      iconColor: const Color(0xFF16A34A),
                      pillColor: const Color(0xFFDCFCE7),
                      pillTextColor: const Color(0xFF15803D),
                      width: cardWidth,
                      onTap: () => setState(() => _activeTab = 2),
                    ),
                    _buildStatCard(
                      title: 'Bảo trì & Kiểm tra',
                      value: '$maintenanceCount phòng',
                      subtext: maintenanceCount == 0
                          ? '100% phòng sẵn sàng'
                          : '$maintenanceCount phòng đang bảo trì',
                      icon: Icons.build_rounded,
                      iconBg: const Color(0xFFFEF3C7),
                      iconColor: const Color(0xFFD97706),
                      pillColor: const Color(0xFFFFFBEB),
                      pillTextColor: const Color(0xFFB45309),
                      width: cardWidth,
                      onTap: () => setState(() => _activeTab = 3),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // 3. TABS & FILTER TOOLBAR
            Container(
              padding: const EdgeInsets.all(16),
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
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTabButton(
                          0,
                          'Phòng học theo chi nhánh (${_rooms.length})',
                          Icons.meeting_room_rounded,
                        ),
                        _buildTabButton(
                          1,
                          'Danh sách chi nhánh (${_branches.length} cơ sở)',
                          Icons.domain_rounded,
                        ),
                        _buildTabButton(
                          2,
                          'Quản lý trang thiết bị (${_rooms.length} phòng)',
                          Icons.devices_rounded,
                        ),
                        _buildTabButton(
                          3,
                          'Lịch bảo trì & Kiểm tra ($maintenanceCount)',
                          Icons.build_circle_rounded,
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Color(0xFFE2E8F0), height: 1),
                  const SizedBox(height: 14),

                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: isDesktop ? 300 : double.infinity,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: _activeTab == 1
                                ? 'Tìm tên chi nhánh, mã cơ sở, địa chỉ...'
                                : 'Tìm tên phòng, mã phòng, thiết bị...',
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF94A3B8),
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              size: 20,
                              color: Color(0xFF64748B),
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
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
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      if (_branches.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedBranchId,
                              items: _branches.map((b) {
                                return DropdownMenuItem<String>(
                                  value: b['id']?.toString(),
                                  child: Text(
                                    b['name']?.toString() ?? 'Chi nhánh',
                                  ),
                                );
                              }).toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _selectedBranchId = v);
                                  _fetchRooms(v);
                                }
                              },
                            ),
                          ),
                        ),
                      if (_activeTab != 1) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedFloor,
                              items: const [
                                DropdownMenuItem(
                                  value: 'ALL',
                                  child: Text('Tất cả các tầng'),
                                ),
                                DropdownMenuItem(
                                  value: '1',
                                  child: Text('Tầng 1'),
                                ),
                                DropdownMenuItem(
                                  value: '2',
                                  child: Text('Tầng 2'),
                                ),
                                DropdownMenuItem(
                                  value: '3',
                                  child: Text('Tầng 3'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null)
                                  setState(() => _selectedFloor = v);
                              },
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedStatus,
                              items: [
                                const DropdownMenuItem(
                                  value: 'ALL',
                                  child: Text('Tất cả trạng thái'),
                                ),
                                DropdownMenuItem(
                                  value: 'OCCUPIED',
                                  child: Text('Đang có lớp ($occupiedCount)'),
                                ),
                                DropdownMenuItem(
                                  value: 'AVAILABLE',
                                  child: Text('Phòng trống ($availableCount)'),
                                ),
                                DropdownMenuItem(
                                  value: 'MAINTENANCE',
                                  child: Text('Bảo trì ($maintenanceCount)'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null)
                                  setState(() => _selectedStatus = v);
                              },
                            ),
                          ),
                        ),
                      ],
                      IconButton(
                        onPressed: () => _fetchBranches(),
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
            const SizedBox(height: 24),

            // 4. ACTIVE TAB CONTENT AREA
            if (_isLoading && _branches.isEmpty && _rooms.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: LoadingWidget(
                  message: 'Đang kết nối cơ sở dữ liệu tải thông tin chi nhánh & phòng học...',
                ),
              )
            else if (_errorMessage != null && _branches.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: AppErrorWidget(
                  message: _errorMessage!,
                  onRetry: () => _fetchBranches(),
                ),
              )
            else
              _buildActiveTabView(isDesktop, width, filteredRooms),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderTitle(String todayStr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 6,
          children: [
            Text(
              'Quản lý Chi nhánh & Hệ thống Phòng học',
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
                    'Giám sát cơ sở thời gian thực',
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
            const Icon(Icons.today_rounded, size: 16, color: Color(0xFF64748B)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Hôm nay: $todayStr • Tổng cộng ${_branches.length} chi nhánh & ${_rooms.length} phòng học vận hành',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderActions() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          onPressed: _showExportSummaryDialog,
          icon: const Icon(
            Icons.file_download_outlined,
            size: 18,
            color: AppColors.primary,
          ),
          label: const Text('Xuất sơ đồ cơ sở (.xlsx)'),
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
        OutlinedButton.icon(
          onPressed: () => _showAddBranchDialog(),
          icon: const Icon(
            Icons.domain_add_rounded,
            size: 18,
            color: Color(0xFF003FB1),
          ),
          label: const Text('+ Thêm chi nhánh'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF003FB1),
            side: const BorderSide(color: Color(0xFF003FB1)),
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _showAddOrEditRoomDialog(),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('+ Thêm phòng học mới'),
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

  Widget _buildActiveTabView(
    bool isDesktop,
    double width,
    List<dynamic> filteredRooms,
  ) {
    switch (_activeTab) {
      case 0:
        return _buildRoomsTab(isDesktop, width, filteredRooms);
      case 1:
        return _buildBranchesTab(isDesktop, width);
      case 2:
        return _buildEquipmentsTab(isDesktop, filteredRooms);
      case 3:
        return _buildMaintenanceTab(isDesktop, filteredRooms);
      default:
        return _buildRoomsTab(isDesktop, width, filteredRooms);
    }
  }

  // ---------------------------------------------------------------------------
  // TAB 0: ROOMS GRID BY BRANCH
  // ---------------------------------------------------------------------------
  Widget _buildRoomsTab(
    bool isDesktop,
    double width,
    List<dynamic> filteredRooms,
  ) {
    if (filteredRooms.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: EmptyStateWidget(
          icon: Icons.meeting_room_outlined,
          title: 'Không tìm thấy phòng học phù hợp',
          description: 'Hãy điều chỉnh bộ lọc tầng/trạng thái hoặc nhấn "+ Thêm phòng học mới" để khởi tạo phòng.',
        ),
      );
    }

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final cols = isDesktop ? 3 : (width > 680 ? 2 : 1);
        final cardWidth = (constraints.maxWidth - (cols - 1) * 20) / cols;

        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: filteredRooms
              .map(
                (r) => _buildRoomCard(
                  Map<String, dynamic>.from(r as Map),
                  cardWidth,
                ),
              )
              .toList(),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: BRANCHES LIST VIEW
  // ---------------------------------------------------------------------------
  Widget _buildBranchesTab(bool isDesktop, double width) {
    final query = _searchController.text.trim().toLowerCase();
    final displayBranches = _branches.where((raw) {
      if (query.isEmpty) return true;
      final b = Map<String, dynamic>.from(raw as Map);
      final name = (b['name'] ?? '').toString().toLowerCase();
      final code = (b['code'] ?? '').toString().toLowerCase();
      final address = (b['address'] ?? '').toString().toLowerCase();
      return name.contains(query) ||
          code.contains(query) ||
          address.contains(query);
    }).toList();

    if (displayBranches.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: EmptyStateWidget(
          icon: Icons.domain_disabled_rounded,
          title: 'Chưa có chi nhánh nào phù hợp',
          description: 'Nhấn "+ Thêm chi nhánh" để mở cơ sở đào tạo mới.',
        ),
      );
    }

    return Column(
      children: displayBranches.map((raw) {
        final b = Map<String, dynamic>.from(raw as Map);
        final id = b['id']?.toString() ?? '';
        final code = b['code']?.toString() ?? 'BR-01';
        final name = b['name']?.toString() ?? 'Chi nhánh';
        final address = b['address']?.toString() ?? 'Chưa cập nhật địa chỉ';
        final phone = b['phone']?.toString() ?? 'Chưa cập nhật';
        final email = b['email']?.toString() ?? 'Chưa cập nhật';
        final isActive = b['isActive'] != false;
        final roomCount = (b['_count'] is Map)
            ? (b['_count']['rooms'] ?? _rooms.length)
            : _rooms.length;
        final userCount = (b['_count'] is Map)
            ? (b['_count']['users'] ?? 0)
            : 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: id == _selectedBranchId
                  ? const Color(0xFF003FB1)
                  : const Color(0xFFE2E8F0),
              width: id == _selectedBranchId ? 1.5 : 1,
            ),
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
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          code,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF003FB1),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActive ? 'Đang hoạt động' : 'Tạm ngưng',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isActive
                            ? const Color(0xFF047857)
                            : const Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 24,
                runSpacing: 10,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          address,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Hotline: $phone',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.email_outlined,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Email: $email',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 28, color: Color(0xFFE2E8F0)),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _Badge(
                        label: '$roomCount phòng học trực thuộc',
                        icon: Icons.meeting_room_rounded,
                      ),
                      _Badge(
                        label: '$userCount nhân sự & học viên thuộc cơ sở',
                        icon: Icons.groups_rounded,
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedBranchId = id;
                            _activeTab = 0;
                          });
                          _fetchRooms(id);
                        },
                        icon: const Icon(Icons.meeting_room_outlined, size: 16),
                        label: const Text('Xem danh sách phòng'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () =>
                            _showAddOrEditRoomDialog(forceBranchId: id),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Thêm phòng'),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003FB1),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () =>
                            _showAddBranchDialog(existingBranch: b),
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('Chỉnh sửa cơ sở'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: EQUIPMENT MANAGEMENT VIEW
  // ---------------------------------------------------------------------------
  Widget _buildEquipmentsTab(bool isDesktop, List<dynamic> filteredRooms) {
    if (filteredRooms.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: EmptyStateWidget(
          icon: Icons.devices_other_rounded,
          title: 'Chưa có dữ liệu trang thiết bị phòng học',
          description: 'Hãy thêm phòng học hoặc chọn cơ sở khác để quản lý danh mục thiết bị.',
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: const Row(
              children: [
                Icon(Icons.devices_rounded, color: Color(0xFF003FB1), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Danh Mục Trang Thiết Bị Giảng Dạy Theo Phòng Học',
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
          ...filteredRooms.map((raw) {
            final room = Map<String, dynamic>.from(raw as Map);
            final code = room['code']?.toString() ?? '';
            final name = room['name']?.toString() ?? '';
            final cap = room['capacity'] ?? 20;
            final isActive = room['isActive'] != false;
            final equips = _parseEquipmentList(room);

            return Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: isDesktop ? 260 : double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              code,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF003FB1),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFFECFDF5)
                                    : const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                isActive ? 'Thiết bị tốt' : 'Đang bảo trì',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isActive
                                      ? const Color(0xFF047857)
                                      : const Color(0xFFB91C1C),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$name ($cap chỗ)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: isDesktop ? 420 : double.infinity,
                    child: equips.isEmpty
                        ? const Text(
                            'Chưa kê khai thiết bị',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: equips
                                .map(
                                  (item) => _Badge(
                                    label: item,
                                    icon: Icons.check_circle_outline_rounded,
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        _showAddOrEditRoomDialog(existingRoom: room),
                    icon: const Icon(Icons.edit_note_rounded, size: 18),
                    label: const Text('Cập nhật thiết bị'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF003FB1),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
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

  // ---------------------------------------------------------------------------
  // TAB 3: MAINTENANCE & INSPECTION SCHEDULE VIEW
  // ---------------------------------------------------------------------------
  Widget _buildMaintenanceTab(bool isDesktop, List<dynamic> filteredRooms) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
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
                  Icon(
                    Icons.build_circle_rounded,
                    color: Color(0xFFD97706),
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Điều Phối Bảo Trì & Kiểm Tra Kỹ Thuật Phòng Học',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Bật/tắt chế độ bảo trì trực tiếp cho từng phòng học để khóa hoặc mở xếp lịch giảng dạy.',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              ...filteredRooms.map((raw) {
                final room = Map<String, dynamic>.from(raw as Map);
                final isActive = room['isActive'] != false;
                final code = room['code']?.toString() ?? '';
                final name = room['name']?.toString() ?? '';
                final equip = room['equipment']?.toString() ?? 'Chưa kê khai';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFF8FAFC)
                        : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFFFCD34D),
                    ),
                  ),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$code • $name',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? const Color(0xFFECFDF5)
                                      : const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isActive
                                      ? 'Sẵn sàng vận hành'
                                      : 'Đang bảo trì kỹ thuật',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isActive
                                        ? const Color(0xFF047857)
                                        : const Color(0xFFB91C1C),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Thiết bị kiểm tra: $equip',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 10,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () =>
                                _showAddOrEditRoomDialog(existingRoom: room),
                            icon: const Icon(Icons.tune_rounded, size: 16),
                            label: const Text('Cấu hình'),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isActive
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF047857),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _toggleRoomMaintenance(room),
                            icon: Icon(
                              isActive
                                  ? Icons.build_rounded
                                  : Icons.check_circle_rounded,
                              size: 16,
                            ),
                            label: Text(
                              isActive
                                  ? 'Chuyển sang Bảo trì'
                                  : 'Hoàn tất bảo trì',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              if (_maintenanceLogs.isNotEmpty) ...[
                const Divider(height: 28),
                const Text(
                  'Nhật ký thao tác bảo trì trong phiên làm việc:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                ..._maintenanceLogs.map(
                  (log) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      log['status'] == 'RESOLVED'
                          ? Icons.check_circle_rounded
                          : Icons.warning_amber_rounded,
                      color: log['status'] == 'RESOLVED'
                          ? const Color(0xFF047857)
                          : const Color(0xFFD97706),
                    ),
                    title: Text(
                      '${log['roomCode']} - ${log['action']}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('Thời gian: ${log['timestamp']}'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
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
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF003FB1)
                    : const Color(0xFF64748B),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
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
    required double width,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room, double width) {
    final code = room['code']?.toString() ?? 'P101';
    final name = room['name']?.toString() ?? 'Phòng học';
    final floor = _inferFloor(room);
    final cap = (room['capacity'] as int?) ?? 20;
    final opStatus = _getRoomOperationalStatus(room);

    final isOccupied = opStatus == 'OCCUPIED';
    final isAvailable = opStatus == 'AVAILABLE';
    final assignedClasses = _getClassesForRoom(room);
    final primaryClass = assignedClasses.isNotEmpty
        ? assignedClasses.first
        : null;
    final enrolledStudents = assignedClasses.fold<int>(
      0,
      (sum, c) =>
          sum +
          ((c['_count'] is Map ? (c['_count']['enrollments'] as int?) : null) ??
              0),
    );
    final occupancyRatio = cap > 0
        ? (enrolledStudents / cap).clamp(0.0, 1.0)
        : 0.0;
    final equips = _parseEquipmentList(room);

    return Container(
      width: width,
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Tầng $floor',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF003FB1),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          code,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isOccupied
                            ? const Color(0xFFECFDF5)
                            : (isAvailable
                                  ? const Color(0xFFF1F5F9)
                                  : const Color(0xFFFEF2F2)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isOccupied
                              ? const Color(0xFFA7F3D0)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 3,
                            backgroundColor: isOccupied
                                ? const Color(0xFF059669)
                                : (isAvailable
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFFDC2626)),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isOccupied
                                ? 'Đang có lớp (${assignedClasses.length})'
                                : (isAvailable ? 'Phòng trống' : 'Bảo trì'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isOccupied
                                  ? const Color(0xFF047857)
                                  : (isAvailable
                                        ? const Color(0xFF475569)
                                        : const Color(0xFFB91C1C)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 12),

                // Real Capacity & Progress Bar
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Sĩ số / Sức chứa:',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            '$enrolledStudents / $cap học viên (${(occupancyRatio * 100).toStringAsFixed(0)}%)',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: occupancyRatio,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isOccupied
                                ? const Color(0xFF003FB1)
                                : const Color(0xFF94A3B8),
                          ),
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Real Assigned Class Box
                Container(
                  padding: const EdgeInsets.only(left: 10, top: 4, bottom: 4),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: isOccupied
                            ? const Color(0xFF003FB1)
                            : const Color(0xFF94A3B8),
                        width: 2.5,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        primaryClass != null
                            ? 'Lớp phụ trách: ${primaryClass['code'] ?? ''}'
                            : 'Chưa xếp lớp cố định',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isOccupied
                              ? const Color(0xFF003FB1)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        primaryClass != null
                            ? (primaryClass['name']?.toString() ?? 'Lớp học')
                            : 'Sẵn sàng xếp ca học mới',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        primaryClass != null && primaryClass['teacher'] is Map
                            ? 'GV: ${primaryClass['teacher']['fullName'] ?? 'Chưa phân công'}'
                            : 'GV: Chưa phân công',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Real Equipment Tags from DB
                const Text(
                  'TRANG THIẾT BỊ:',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 6),
                if (equips.isEmpty)
                  const Text(
                    'Chưa cập nhật thiết bị',
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  )
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: equips
                        .map(
                          (e) =>
                              _Badge(label: e, icon: Icons.verified_outlined),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),

          // Footer Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => _showRoomScheduleDialog(room),
                  icon: const Icon(
                    Icons.event_note_rounded,
                    size: 15,
                    color: Color(0xFF003FB1),
                  ),
                  label: const Text(
                    'Xem lịch phòng',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF003FB1),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showAddOrEditRoomDialog(existingRoom: room),
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 14,
                    color: Color(0xFF0F172A),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  label: const Text(
                    'Chỉnh sửa',
                    style: TextStyle(fontSize: 11, color: Color(0xFF0F172A)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData? icon;

  const _Badge({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: const Color(0xFF003FB1)),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF475569)),
          ),
        ],
      ),
    );
  }
}
