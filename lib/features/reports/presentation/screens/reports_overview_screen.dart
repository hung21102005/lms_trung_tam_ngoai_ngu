import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/searchable_entity_field.dart';
import '../bloc/reports_bloc.dart';
import '../../data/models/report_model.dart';

class ReportsOverviewScreen extends StatefulWidget {
  final bool showAppBar;
  const ReportsOverviewScreen({super.key, this.showAppBar = true});

  @override
  State<ReportsOverviewScreen> createState() => _ReportsOverviewScreenState();
}

class _ReportsOverviewScreenState extends State<ReportsOverviewScreen> {
  final ApiClient _apiClient = getIt<ApiClient>();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  int _activePerspectiveTab = 0; // 0: Biểu đồ doanh thu, 1: Chi tiết chi nhánh, 2: Sổ quỹ giao dịch, 3: Công nợ học phí
  String _selectedBranch = 'ALL';
  String _selectedTime = 'M10';
  String _selectedGateway = 'ALL';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<ReportsBloc>().add(const FetchDashboardOverviewEvent());
  }

  Future<void> _exportReport() async {
    const types = ['revenue', 'revenue', 'revenue', 'debts'];
    final type = types[_activePerspectiveTab];
    try {
      final bytes = await _apiClient.download('/reports/export/$type');
      if (bytes.isEmpty) {
        throw StateError('Máy chủ không trả về dữ liệu Excel.');
      }
      final saved = await FilePicker.saveFile(
        fileName:
            'bao-cao-$type-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.xlsx',
        bytes: bytes,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      if (saved != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã lưu báo cáo Excel.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể xuất báo cáo: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 960;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: AppColors.surface(context),
              elevation: 0,
              title: Text(
                'Báo Cáo & Tài Chính',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary(context),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: AppColors.textSecondary(context),
                  ),
                  onPressed: () => context.read<ReportsBloc>().add(
                    const FetchDashboardOverviewEvent(forceRefresh: true),
                  ),
                ),
              ],
            )
          : null,
      body: BlocBuilder<ReportsBloc, ReportsState>(
        builder: (context, state) {
          if (state is ReportsLoadingState) {
            return const LoadingWidget(
              message: 'Đang tải báo cáo tài chính...',
            );
          }
          if (state is ReportsErrorState) {
            return AppErrorWidget(
              message: state.message,
              onRetry: () => context.read<ReportsBloc>().add(
                const FetchDashboardOverviewEvent(forceRefresh: true),
              ),
            );
          }
          final overview = state is DashboardOverviewLoadedState
              ? state.data
              : null;
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 24 : 16,
              vertical: 20,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header Toolbar
                    _buildHeaderToolbar(isDesktop),
                    const SizedBox(height: 20),

                    // 2. 4 Bento KPI Metric Cards
                    _buildKpiMetricsGrid(isDesktop, overview),
                    const SizedBox(height: 20),

                    // 3. Perspective Tabs & Filter Toolbar
                    _buildFilterToolbar(isDesktop),
                    const SizedBox(height: 24),

                    // 4. Analytics Grid (Left 8 Cols / Right 4 Cols)
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 8,
                            child: _buildRevenueBarChartCard(overview),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 4,
                            child: _buildBranchBreakdownCard(overview),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildRevenueBarChartCard(overview),
                          const SizedBox(height: 20),
                          _buildBranchBreakdownCard(overview),
                        ],
                      ),

                    const SizedBox(height: 24),

                    // 5. Recent Financial Invoices & Transactions Table
                    _buildTransactionsTableCard(overview),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- 1. HEADER TOOLBAR ---
  Widget _buildHeaderToolbar(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      Text(
                        'Báo cáo Doanh thu & Phân tích Tài chính',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary(context),
                          letterSpacing: -0.4,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successBg(context),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: AppColors.successFg(context).withAlpha(80),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 3,
                              backgroundColor: AppColors.successFg(context),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Dữ liệu tài chính trực tuyến',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.successFg(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.today,
                        size: 14,
                        color: AppColors.textMuted(context),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Hôm nay, ${DateFormat('dd/MM/yyyy').format(DateTime.now())} • Kỳ đối soát: Tháng ${DateTime.now().month}/${DateTime.now().year}',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isDesktop) ...[
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: _exportReport,
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Xuất báo cáo (.xlsx)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textBody(context),
                  side: BorderSide(color: AppColors.borderStrong(context)),
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
                onPressed: () => context.read<ReportsBloc>().add(
                  const FetchDashboardOverviewEvent(forceRefresh: true),
                ),
                icon: Icon(
                  Icons.sync_alt_rounded,
                  size: 16,
                  color: AppColors.brand(context),
                ),
                label: const Text('Làm mới số liệu'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brand(context),
                  backgroundColor: AppColors.brandBg(context),
                  side: BorderSide(color: AppColors.brand(context).withAlpha(90)),
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
                onPressed: _showCreateInvoiceDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('+ Lập phiếu thu / hóa đơn'),
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

  // --- 2. FOUR KPI STATS METRIC CARDS ---
  Widget _buildKpiMetricsGrid(
    bool isDesktop,
    DashboardOverviewModel? overview,
  ) {
    final monthlyRev = overview?.monthlyRevenue ?? 0.0;
    final totalDebts = overview?.totalDebts ?? 0.0;
    final debtorsCount = overview?.topDebtors.length ?? 0;
    final totalStudents = overview?.totalStudents ?? 0;
    final activeClasses = overview?.totalActiveClasses ?? 0;

    final cards = [
      _buildStatCard(
        title: 'Tổng Doanh Thu Tháng Này',
        value: _currencyFormat.format(monthlyRev),
        badgeText: '${overview?.monthlyRevenueGrowth ?? 0}% so với tháng trước',
        badgeColor: AppColors.successFg(context),
        icon: Icons.payments_outlined,
        iconBg: AppColors.brandBg(context),
        iconColor: AppColors.brand(context),
      ),
      _buildProgressStatCard(
        title: 'Thực Thu Học Phí (Đã thanh toán)',
        value: _currencyFormat.format(monthlyRev),
        progress: monthlyRev > 0 ? 1.0 : 0.0,
        progressLabel: monthlyRev > 0
            ? 'Đã đối soát tự động trên hệ thống'
            : 'Chưa phát sinh phiếu thu đã thanh toán',
        icon: Icons.check_circle_outline,
        iconBg: AppColors.successBg(context),
        iconColor: AppColors.successFg(context),
      ),
      _buildStatCard(
        title: 'Công Nợ Học Phí Cần Thu',
        value: _currencyFormat.format(totalDebts),
        badgeText: '$debtorsCount học viên nợ học phí',
        badgeColor: totalDebts > 0
            ? AppColors.errorFg(context)
            : AppColors.successFg(context),
        valueColor: totalDebts > 0
            ? AppColors.errorFg(context)
            : AppColors.textPrimary(context),
        icon: Icons.pending_actions_outlined,
        iconBg: AppColors.errorBg(context),
        iconColor: AppColors.errorFg(context),
      ),
      _buildStatCard(
        title: 'Học Viên & Lớp Hoạt Động',
        value: '$totalStudents HV / $activeClasses Lớp',
        badgeText: '1 cơ sở đang vận hành',
        badgeColor: AppColors.brand(context),
        icon: Icons.autorenew_rounded,
        iconBg: AppColors.brandBg(context),
        iconColor: AppColors.brand(context),
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

  Widget _buildStatCard({
    required String title,
    required String value,
    required String badgeText,
    required Color badgeColor,
    Color? valueColor,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context),
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
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary(context),
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
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: valueColor ?? AppColors.textPrimary(context),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: badgeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStatCard({
    required String title,
    required String value,
    required double progress,
    required String progressLabel,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context),
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
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary(context),
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
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary(context),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: AppColors.surfaceSubtle(context),
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.brand(context),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            progressLabel,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.successFg(context),
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. PERSPECTIVE TABS & FILTER TOOLBAR ---
  Widget _buildFilterToolbar(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPerspectiveTabButton(
                        'Biểu đồ doanh thu & dòng tiền',
                        Icons.query_stats,
                        0,
                      ),
                      const SizedBox(width: 8),
                      _buildPerspectiveTabButton(
                        'Báo cáo theo chi nhánh',
                        Icons.apartment,
                        1,
                      ),
                      const SizedBox(width: 8),
                      _buildPerspectiveTabButton(
                        'Sổ quỹ & Lịch sử giao dịch',
                        Icons.receipt_long,
                        2,
                      ),
                      const SizedBox(width: 8),
                      _buildPerspectiveTabButton(
                        'Công nợ & Nhắc học phí',
                        Icons.notification_important_outlined,
                        3,
                      ),
                    ],
                  ),
                ),
              ),
              if (isDesktop) ...[
                const SizedBox(width: 12),
                Row(
                  children: [
                    Icon(Icons.tune, size: 15, color: AppColors.brand(context)),
                    const SizedBox(width: 4),
                    Text(
                      'Kỳ tài chính: 2026',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: AppColors.divider(context)),
          const SizedBox(height: 14),

          // Search and Dropdowns
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              // Search input
              SizedBox(
                width: 320,
                height: 38,
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Tìm mã biên lai, tên học viên, SĐT...',
                    hintStyle: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted(context),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 16,
                      color: AppColors.textMuted(context),
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceSubtle(context),
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                  ),
                ),
              ),

              // Branch dropdown
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderStrong(context)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedBranch,
                    dropdownColor: AppColors.surface(context),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textBody(context),
                      fontFamily: 'Be Vietnam Pro',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'ALL',
                        child: Text('Cơ sở: Tất cả (1 chi nhánh)'),
                      ),
                      DropdownMenuItem(
                        value: 'HCM_Q1',
                        child: Text('BR-Q1: Chi nhánh Quận 1 - Hồ Chí Minh'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedBranch = v);
                    },
                  ),
                ),
              ),

              // Time dropdown
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderStrong(context)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedTime,
                    dropdownColor: AppColors.surface(context),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textBody(context),
                      fontFamily: 'Be Vietnam Pro',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'M10',
                        child: Text('Thời gian: Tháng 10/2026'),
                      ),
                      DropdownMenuItem(
                        value: 'M09',
                        child: Text('Thời gian: Tháng 09/2026'),
                      ),
                      DropdownMenuItem(
                        value: 'Q3',
                        child: Text('Thời gian: Quý 3/2026'),
                      ),
                      DropdownMenuItem(
                        value: 'Y2026',
                        child: Text('Thời gian: Toàn năm 2026'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedTime = v);
                    },
                  ),
                ),
              ),

              // Gateway dropdown
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderStrong(context)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedGateway,
                    dropdownColor: AppColors.surface(context),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textBody(context),
                      fontFamily: 'Be Vietnam Pro',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'ALL',
                        child: Text('Cổng: Tất cả hình thức'),
                      ),
                      DropdownMenuItem(
                        value: 'VNPAY',
                        child: Text('QR VNPay / MoMo'),
                      ),
                      DropdownMenuItem(
                        value: 'BANK',
                        child: Text('Chuyển khoản VCB'),
                      ),
                      DropdownMenuItem(
                        value: 'POS',
                        child: Text('Quẹt thẻ POS'),
                      ),
                      DropdownMenuItem(
                        value: 'CASH',
                        child: Text('Tiền mặt tại quầy'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedGateway = v);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerspectiveTabButton(String label, IconData icon, int index) {
    final isActive = _activePerspectiveTab == index;
    return InkWell(
      onTap: () => setState(() => _activePerspectiveTab = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF003FB1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive ? Colors.white : AppColors.textSecondary(context),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? Colors.white : AppColors.textBody(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 4. REVENUE BAR CHART CARD (Left 8 Cols) ---
  Widget _buildRevenueBarChartCard(DashboardOverviewModel? overview) {
    final trend = overview?.revenueTrend ?? const [];
    final maxRev = trend.fold<double>(
      0.0,
      (m, i) => i.revenue > m ? i.revenue : m,
    );
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Biểu đồ Phân tích Doanh thu & Dòng tiền 2026',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Đối chiếu doanh thu thực thu từ hệ thống theo từng tháng',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _buildLegendItem(
                    'Doanh thu thực tế',
                    AppColors.brand(context),
                  ),
                  _buildLegendItem('Công nợ', AppColors.errorFg(context)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Bar Chart Visualizer
          SizedBox(
            height: 220,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: trend.isNotEmpty
                  ? trend.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      final frac = maxRev > 0
                          ? (item.revenue / maxRev).clamp(0.05, 1.0)
                          : 0.05;
                      final label = item.revenue > 0
                          ? '${(item.revenue / 1000000).toStringAsFixed(1)}M'
                          : '0 đ';
                      return _buildMonthBar(
                        item.month,
                        frac,
                        label,
                        isHighlight: idx == trend.length - 1,
                      );
                    }).toList()
                  : [
                      _buildMonthBar('T5', 0.05, '0 đ'),
                      _buildMonthBar('T6', 0.05, '0 đ'),
                      _buildMonthBar('T7', 0.05, '0 đ'),
                      _buildMonthBar('T8', 0.05, '0 đ'),
                      _buildMonthBar('T9', 0.05, '0 đ'),
                      _buildMonthBar('T10', 0.05, '0 đ', isHighlight: true),
                    ],
            ),
          ),

          const SizedBox(height: 18),
          Divider(height: 1, color: AppColors.divider(context)),
          const SizedBox(height: 14),

          // Course Revenue / Student Share Insights Strip
          Row(
            children: [
              Expanded(
                child: _buildCourseShareItem(
                  'Chương trình Luyện thi IELTS Chuyên sâu',
                  '1 học viên (Lớp IELTS-F-2026-01)',
                  AppColors.brand(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCourseShareItem(
                  'Tiếng Anh Giao Tiếp Phản Xạ Quốc Tế',
                  '0 học viên (Lớp COMM-A1-2026-01)',
                  AppColors.infoFg(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthBar(
    String month,
    double heightFraction,
    String label, {
    bool isHighlight = false,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isHighlight)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF003FB1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          )
        else
          Text(
            label,
            style: TextStyle(fontSize: 9.5, color: AppColors.textMuted(context)),
          ),
        const SizedBox(height: 6),
        Container(
          width: 28,
          height: 160 * heightFraction,
          decoration: BoxDecoration(
            color: isHighlight
                ? AppColors.brand(context)
                : AppColors.brand(context).withAlpha(70),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          month,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
            color: isHighlight
                ? AppColors.brand(context)
                : AppColors.textSecondary(context),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppColors.textBody(context)),
        ),
      ],
    );
  }

  Widget _buildCourseShareItem(String title, String share, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            share,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // --- 5. BRANCH BREAKDOWN CARD (Right 4 Cols) ---
  Widget _buildBranchBreakdownCard(DashboardOverviewModel? overview) {
    final monthlyRev = overview?.monthlyRevenue ?? 0.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context),
            blurRadius: 6,
            offset: const Offset(0, 2),
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
                'Cơ cấu theo Chi nhánh',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
              Text(
                '1 Cơ sở',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brand(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Circular gauge representation
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: monthlyRev > 0 ? 1.0 : 0.0,
                    strokeWidth: 12,
                    backgroundColor: AppColors.border(context),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.brand(context),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _currencyFormat.format(monthlyRev),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    Text(
                      'Tổng thu',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Branch shares
          _buildBranchShareRow(
            'Chi nhánh Quận 1 - Hồ Chí Minh (BR-Q1)',
            '100%',
            AppColors.brand(context),
          ),

          const SizedBox(height: 16),
          Divider(height: 1, color: AppColors.divider(context)),
          const SizedBox(height: 14),

          // Payment Gateway Breakdown
          Text(
            'KÊNH THANH TOÁN THỰC TẾ',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary(context),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          _buildGatewayProgress('Chuyển khoản QR VNPay/MoMo', 0.0, '0% (0 đ)'),
          const SizedBox(height: 8),
          _buildGatewayProgress('Quẹt thẻ POS ngân hàng', 0.0, '0% (0 đ)'),
          const SizedBox(height: 8),
          _buildGatewayProgress('Tiền mặt tại quầy lễ tân', 0.0, '0% (0 đ)'),
        ],
      ),
    );
  }

  Widget _buildBranchShareRow(String name, String percent, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: TextStyle(fontSize: 12, color: AppColors.textBody(context)),
            ),
          ],
        ),
        Text(
          percent,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildGatewayProgress(String label, double value, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                color: AppColors.textBody(context),
              ),
            ),
            Text(
              desc,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 4,
            backgroundColor: AppColors.surfaceSubtle(context),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.brand(context)),
          ),
        ),
      ],
    );
  }

  // --- 6. TRANSACTIONS TABLE CARD ---
  Widget _buildTransactionsTableCard(DashboardOverviewModel? overview) {
    final debtors = overview?.topDebtors ?? const [];
    final headerTextStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: AppColors.textSecondary(context),
    );
    final transactions = debtors
        .map(
          (d) => {
            'invoiceId': d.invoiceId,
            'id': d.invoiceCode,
            'student': d.studentName,
            'code': d.studentCode,
            'course': d.className,
            'method': 'Chờ thanh toán',
            'amount': _currencyFormat.format(d.balance),
            'date': d.dueDate != null
                ? DateFormat('dd/MM/yyyy').format(d.dueDate!)
                : '--',
            'status': 'Chưa thu',
            'color': AppColors.errorFg(context),
          },
        )
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 4,
              children: [
                Text(
                  'Sổ Quỹ & Lịch Sử Giao Dịch Thu Học Phí Gần Đây',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                Text(
                  'Cập nhật tự động theo thời gian thực',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted(context),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.divider(context)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 56,
              dataRowMaxHeight: 60,
              horizontalMargin: 16,
              columnSpacing: 20,
              headingRowColor: WidgetStateProperty.all(
                AppColors.surfaceElevated(context),
              ),
              columns: [
                DataColumn(label: Text('MÃ BIÊN LAI', style: headerTextStyle)),
                DataColumn(label: Text('HỌC VIÊN', style: headerTextStyle)),
                DataColumn(label: Text('KHÓA HỌC', style: headerTextStyle)),
                DataColumn(label: Text('HÌNH THỨC', style: headerTextStyle)),
                DataColumn(label: Text('SỐ TIỀN THU', style: headerTextStyle)),
                DataColumn(label: Text('THỜI GIAN', style: headerTextStyle)),
                DataColumn(label: Text('TRẠNG THÁI', style: headerTextStyle)),
                DataColumn(label: Text('THAO TÁC', style: headerTextStyle)),
              ],
              rows: transactions.map((t) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        t['id'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brand(context),
                        ),
                      ),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            t['student'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                          Text(
                            t['code'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        t['course'] as String,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textBody(context),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        t['method'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        t['amount'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        t['date'] as String,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: (t['color'] as Color).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          t['status'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: t['color'] as Color,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: null,
                            icon: const Icon(Icons.print_outlined, size: 16),
                            color: AppColors.textSecondary(context),
                            tooltip: 'Chưa hỗ trợ in biên lai',
                          ),
                          IconButton(
                            onPressed: () =>
                                _showInvoiceDetail(t['invoiceId'] as String),
                            icon: const Icon(
                              Icons.visibility_outlined,
                              size: 16,
                            ),
                            color: AppColors.brand(context),
                            tooltip: 'Xem chi tiết',
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

  Future<void> _showInvoiceDetail(String invoiceId) async {
    try {
      final response = await _apiClient.get('/finance/invoices/$invoiceId');
      if (!mounted) return;
      final payload = response is Map ? response['data'] ?? response : response;
      final invoice = Map<String, dynamic>.from(payload as Map);
      final student = invoice['student'] is Map
          ? invoice['student'] as Map
          : const {};
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Hóa đơn ${invoice['code'] ?? ''}'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Học viên: ${student['fullName'] ?? ''}'),
                Text('Nội dung: ${invoice['title'] ?? ''}'),
                Text(
                  'Tổng tiền: ${_currencyFormat.format(num.tryParse('${invoice['totalAmount']}') ?? 0)}',
                ),
                Text(
                  'Đã thu: ${_currencyFormat.format(num.tryParse('${invoice['paidAmount']}') ?? 0)}',
                ),
                Text(
                  'Còn nợ: ${_currencyFormat.format(num.tryParse('${invoice['balance']}') ?? 0)}',
                ),
                Text('Trạng thái: ${invoice['status'] ?? ''}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tải được hóa đơn: $error')),
        );
      }
    }
  }

  Future<void> _showCreateInvoiceDialog() async {
    final students = <Map<String, dynamic>>[];
    try {
      var page = 1;
      var totalPages = 1;
      do {
        final response = await _apiClient.get(
          '/users',
          queryParameters: {'role': 'student', 'limit': 100, 'page': page},
        );
        final payload = response is Map
            ? response['data'] ?? response
            : response;
        if (payload is Map && payload['items'] is List) {
          students.addAll(
            (payload['items'] as List).whereType<Map>().map(
              (item) => Map<String, dynamic>.from(item),
            ),
          );
          totalPages = int.tryParse('${payload['totalPages']}') ?? 1;
        }
        page++;
      } while (page <= totalPages);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tải được danh sách học viên: $error')),
        );
      }
      return;
    }
    if (!mounted) return;
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String? studentId;
    var saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, updateDialog) => AlertDialog(
          title: const Text('Lập phiếu thu / Hóa đơn học phí mới'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Học viên *',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                SearchableEntityField(
                  label: 'Học viên *',
                  options: students
                      .where((student) => student['id'] != null)
                      .map(
                        (student) => EntityOption(
                          id: student['id'].toString(),
                          label:
                              '${student['fullName'] ?? ''} (${student['userCode'] ?? ''})',
                        ),
                      )
                      .toList(),
                  selectedId: studentId,
                  enabled: !saving,
                  onSelected: (value) => updateDialog(() => studentId = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tiêu đề hóa đơn *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Học phí cần thu (VNĐ) *',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Ví dụ: 8500000',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final amount = double.tryParse(amountCtrl.text.trim());
                      if (studentId == null ||
                          titleCtrl.text.trim().isEmpty ||
                          amount == null ||
                          amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Chọn học viên, nhập tiêu đề và học phí lớn hơn 0.',
                            ),
                          ),
                        );
                        return;
                      }
                      updateDialog(() => saving = true);
                      try {
                        await _apiClient.post(
                          '/finance/invoices',
                          data: {
                            'studentId': studentId,
                            'title': titleCtrl.text.trim(),
                            'subtotal': amount,
                          },
                        );
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        context.read<ReportsBloc>().add(
                          const FetchDashboardOverviewEvent(forceRefresh: true),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã tạo hóa đơn học phí.'),
                          ),
                        );
                      } catch (error) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Không thể tạo hóa đơn: $error'),
                            ),
                          );
                        }
                      } finally {
                        if (ctx.mounted) updateDialog(() => saving = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003FB1),
                foregroundColor: Colors.white,
              ),
              child: const Text('Tạo hóa đơn'),
            ),
          ],
        ),
      ),
    );
  }
}
