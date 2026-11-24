import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../classes/presentation/bloc/classes_bloc.dart';
import '../../../classes/presentation/bloc/classes_event.dart';
import '../../../reports/presentation/bloc/reports_bloc.dart';
import '../../data/models/invoice_model.dart';
import '../bloc/finance_bloc.dart';

class InvoiceListScreen extends StatefulWidget {
  final bool showAppBar;

  const InvoiceListScreen({super.key, this.showAppBar = true});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final List<String> _statusFilters = [
    'ALL',
    'PENDING',
    'PARTIALLY_PAID',
    'PENDING_TRANSFER',
    'PAID',
    'OVERDUE',
    'CANCELLED',
  ];
  final List<String> _tabLabels = [
    'Tất cả',
    'Chờ nộp',
    'Đóng 1 phần',
    'Chờ duyệt CK',
    'Đã hoàn tất',
    'Quá hạn',
    'Đã hủy',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusFilters.length, vsync: this);
    _loadInvoices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadInvoices() {
    final filter = _statusFilters[_tabController.index];
    final isPendingTransfer = filter == 'PENDING_TRANSFER';
    context.read<FinanceBloc>().add(
      FetchInvoicesEvent(
        status: (filter == 'ALL' || isPendingTransfer) ? null : filter,
        pendingTransferOnly: isPendingTransfer ? true : null,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      ),
    );
  }

  void _syncRelatedBlocs() {
    if (!mounted) return;
    context.read<ClassesBloc?>()?.add(const FetchClasses(refresh: true));
    context.read<ReportsBloc?>()?.add(
      const FetchDashboardOverviewEvent(forceRefresh: true),
    );
  }

  Future<void> _showCreateInvoiceDialog() async {
    final studentIdCtrl = TextEditingController();
    final titleCtrl = TextEditingController(text: 'Học phí khóa học');
    final subtotalCtrl = TextEditingController(text: '4500000');
    final discountCtrl = TextEditingController(text: '0');
    final promoCtrl = TextEditingController();
    final initialPaidCtrl = TextEditingController(text: '0');
    final notesCtrl = TextEditingController();
    String paymentMethod = 'CASH';
    bool collectInitial = false;
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));
    String? promoFeedback;
    double promoDiscount = 0;

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final subtotal = double.tryParse(subtotalCtrl.text.trim()) ?? 0;
          final directDiscount = double.tryParse(discountCtrl.text.trim()) ?? 0;
          final effectiveDiscount =
              promoDiscount > 0 ? promoDiscount : directDiscount;
          final totalAmount =
              (subtotal - effectiveDiscount).clamp(0.0, double.infinity);

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(child: Text('Tạo hóa đơn học phí / phụ phí mới')),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: studentIdCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Mã học viên hoặc UUID * (VD: HV-2026-0001)',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nội dung / Tiêu đề hóa đơn *',
                        prefixIcon: Icon(Icons.description_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: subtotalCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setDlgState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Học phí gốc (VNĐ) *',
                              prefixIcon: Icon(Icons.payments_outlined),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: discountCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setDlgState(() {
                              promoDiscount = 0;
                              promoFeedback = null;
                            }),
                            decoration: const InputDecoration(
                              labelText: 'Giảm trừ trực tiếp (VNĐ)',
                              prefixIcon: Icon(Icons.discount_outlined),
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
                            controller: promoCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Mã khuyến mãi (nếu có)',
                              hintText: 'VD: SUMMER2026',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () async {
                            final code = promoCtrl.text.trim();
                            if (code.isEmpty) return;
                            try {
                              final res = await this
                                  .context
                                  .read<FinanceBloc>()
                                  .repository
                                  .validatePromotion(code, subtotal);
                              final disc =
                                  (res['discountAmount'] as num?)?.toDouble() ??
                                  0;
                              setDlgState(() {
                                promoDiscount = disc;
                                promoFeedback =
                                    'Áp dụng mã ${res['code']}: giảm ${_formatCurrency(disc)}';
                              });
                            } catch (e) {
                              setDlgState(() {
                                promoDiscount = 0;
                                promoFeedback =
                                    'Mã không hợp lệ hoặc hết hạn';
                              });
                            }
                          },
                          child: const Text('Áp dụng mã'),
                        ),
                      ],
                    ),
                    if (promoFeedback != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        promoFeedback!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: promoDiscount > 0
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Ghi nhận thu tiền ngay khi phát hành',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      value: collectInitial,
                      onChanged: (val) {
                        setDlgState(() {
                          collectInitial = val;
                          if (val) {
                            initialPaidCtrl.text = totalAmount.toInt().toString();
                          } else {
                            initialPaidCtrl.text = '0';
                          }
                        });
                      },
                    ),
                    if (collectInitial) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: initialPaidCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Số tiền thu ngay (VNĐ)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: paymentMethod,
                              decoration: const InputDecoration(
                                labelText: 'Phương thức',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'CASH',
                                  child: Text('Tiền mặt'),
                                ),
                                DropdownMenuItem(
                                  value: 'BANK_TRANSFER',
                                  child: Text('Chuyển khoản'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setDlgState(() => paymentMethod = v);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú hóa đơn',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tổng phải thu sau giảm trừ:',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            _formatCurrency(totalAmount),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
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
                onPressed: () {
                  if (studentIdCtrl.text.trim().isEmpty ||
                      titleCtrl.text.trim().isEmpty) {
                    return;
                  }
                  Navigator.pop(ctx, true);
                },
                child: const Text('Phát hành hóa đơn'),
              ),
            ],
          );
        },
      ),
    );

    if (created == true && mounted) {
      final subtotal = double.tryParse(subtotalCtrl.text.trim()) ?? 0;
      final discount = double.tryParse(discountCtrl.text.trim()) ?? 0;
      final initialPaid = collectInitial
          ? (double.tryParse(initialPaidCtrl.text.trim()) ?? 0)
          : 0.0;
      context.read<FinanceBloc>().add(
        CreateInvoiceEvent({
          'studentId': studentIdCtrl.text.trim(),
          'title': titleCtrl.text.trim(),
          'subtotal': subtotal,
          if (discount > 0) 'discount': discount,
          if (promoCtrl.text.trim().isNotEmpty)
            'promotionCode': promoCtrl.text.trim().toUpperCase(),
          'dueDate': DateFormat('yyyy-MM-dd').format(dueDate),
          if (notesCtrl.text.trim().isNotEmpty) 'notes': notesCtrl.text.trim(),
          if (initialPaid > 0) 'initialPaymentAmount': initialPaid,
          if (initialPaid > 0) 'paymentMethod': paymentMethod,
        }),
      );
    }

    studentIdCtrl.dispose();
    titleCtrl.dispose();
    subtotalCtrl.dispose();
    discountCtrl.dispose();
    promoCtrl.dispose();
    initialPaidCtrl.dispose();
    notesCtrl.dispose();
  }

  Future<void> _showPromotionsManagerDialog() async {
    context.read<FinanceBloc>().add(FetchPromotionsEvent());
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final valueCtrl = TextEditingController(text: '10');
    String promoType = 'PERCENTAGE';

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.local_offer_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(child: Text('Quản lý Mã khuyến mãi & Học bổng')),
            ],
          ),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tạo mã ưu đãi mới',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: codeCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Mã CODE * (VD: IELTS10)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Tên chương trình *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: promoType,
                          decoration: const InputDecoration(
                            labelText: 'Loại giảm giá',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'PERCENTAGE',
                              child: Text('Theo phần trăm (%)'),
                            ),
                            DropdownMenuItem(
                              value: 'FIXED_AMOUNT',
                              child: Text('Số tiền cố định (VNĐ)'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setDlgState(() => promoType = v);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: valueCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: promoType == 'PERCENTAGE'
                                ? 'Mức giảm (%)'
                                : 'Số tiền giảm (VNĐ)',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: () {
                          final code = codeCtrl.text.trim().toUpperCase();
                          final name = nameCtrl.text.trim();
                          final val =
                              double.tryParse(valueCtrl.text.trim()) ?? 0;
                          if (code.isEmpty || name.isEmpty || val <= 0) return;
                          final now = DateTime.now();
                          this.context.read<FinanceBloc>().add(
                            CreatePromotionEvent({
                              'code': code,
                              'name': name,
                              'type': promoType,
                              'value': val,
                              'startDate': DateFormat('yyyy-MM-dd').format(now),
                              'endDate': DateFormat('yyyy-MM-dd').format(
                                now.add(const Duration(days: 180)),
                              ),
                            }),
                          );
                          codeCtrl.clear();
                          nameCtrl.clear();
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Tạo mã'),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text(
                    'Danh sách mã khuyến mãi hiện có',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  BlocBuilder<FinanceBloc, FinanceState>(
                    builder: (context, state) {
                      final promos =
                          this.context.read<FinanceBloc>().cachedPromotions;
                      if (promos.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'Chưa có mã khuyến mãi nào. Hãy tạo mã mới ở trên.',
                            style: TextStyle(color: AppColors.textSecondaryLight),
                          ),
                        );
                      }
                      return Column(
                        children: promos.map((p) {
                          final valLabel = p.type == 'PERCENTAGE'
                              ? 'Giảm ${p.value.toStringAsFixed(0)}%'
                              : 'Giảm ${_formatCurrency(p.value)}';
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: p.isActive
                                    ? AppColors.primary.withAlpha(20)
                                    : Colors.grey.withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                p.code,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: p.isActive
                                      ? AppColors.primary
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            title: Text(
                              p.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '$valLabel • Đã dùng: ${p.usedCount}${p.usageLimit != null ? '/${p.usageLimit}' : ''}',
                            ),
                            trailing: Switch.adaptive(
                              value: p.isActive,
                              onChanged: (_) {
                                this.context.read<FinanceBloc>().add(
                                  TogglePromotionEvent(p.id),
                                );
                              },
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng'),
            ),
          ],
        ),
      ),
    );

    codeCtrl.dispose();
    nameCtrl.dispose();
    valueCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Quản lý Học phí & Hóa đơn'),
              actions: [
                IconButton(
                  tooltip: 'Quét & Nhắc nợ quá hạn',
                  icon: const Icon(Icons.notifications_active_outlined),
                  onPressed: () => context.read<FinanceBloc>().add(
                    CheckOverdueInvoicesEvent(),
                  ),
                ),
                IconButton(
                  tooltip: 'Mã khuyến mãi',
                  icon: const Icon(Icons.local_offer_outlined),
                  onPressed: _showPromotionsManagerDialog,
                ),
                IconButton(
                  tooltip: 'Tạo hóa đơn mới',
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _showCreateInvoiceDialog,
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondaryLight,
                tabs: _tabLabels.map((l) => Tab(text: l)).toList(),
                onTap: (_) => _loadInvoices(),
              ),
            )
          : null,
      body: BlocListener<FinanceBloc, FinanceState>(
        listener: (context, state) {
          if (state is InvoiceCreatedSuccessState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Đã phát hành hóa đơn ${state.invoice.code} thành công.',
                ),
                backgroundColor: AppColors.success,
              ),
            );
            _syncRelatedBlocs();
          } else if (state is PaymentRecordedSuccessState) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã ghi nhận thanh toán học phí thành công.'),
                backgroundColor: AppColors.success,
              ),
            );
            _syncRelatedBlocs();
          } else if (state is FinanceActionSuccessState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
            _syncRelatedBlocs();
          } else if (state is FinanceErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.showAppBar) ...[
              // Embedded Header & Action Bar inside AdminHomeScreen
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trung tâm Học phí, Hóa đơn & Thu ngân',
                          style: AppTextStyles.h3(context).copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Phát hành hóa đơn, thu tiền nhiều đợt, đối soát chuyển khoản VietQR và quản lý ưu đãi',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => context.read<FinanceBloc>().add(
                            CheckOverdueInvoicesEvent(),
                          ),
                          icon: const Icon(
                            Icons.notification_important_outlined,
                            size: 18,
                          ),
                          label: const Text('Quét quá hạn'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _showPromotionsManagerDialog,
                          icon: const Icon(
                            Icons.local_offer_outlined,
                            size: 18,
                          ),
                          label: const Text('Mã khuyến mãi'),
                        ),
                        FilledButton.icon(
                          onPressed: _showCreateInvoiceDialog,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Tạo hóa đơn'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondaryLight,
                  tabs: _tabLabels.map((l) => Tab(text: l)).toList(),
                  onTap: (_) => _loadInvoices(),
                ),
              ),
            ],

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm mã HĐ, tên học viên, mã HV, số điện thoại...',
                  prefixIcon: const Icon(Icons.search, size: 22),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _loadInvoices();
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                  filled: true,
                  fillColor: AppColors.neutral100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _loadInvoices(),
              ),
            ),

            // Invoices Content
            Expanded(
              child: BlocBuilder<FinanceBloc, FinanceState>(
                builder: (context, state) {
                  final bloc = context.read<FinanceBloc>();
                  final resp = state is InvoicesLoadedState
                      ? state.response
                      : bloc.cachedInvoicesResponse;

                  if (state is FinanceLoadingState && resp == null) {
                    return const LoadingWidget();
                  }

                  if (state is FinanceErrorState && resp == null) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Lỗi: ${state.message}',
                            style: AppTextStyles.bodyMedium(context),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadInvoices,
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (resp != null) {
                    return RefreshIndicator(
                      onRefresh: () async => _loadInvoices(),
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        children: [
                          _buildSummaryHeader(resp.summary),
                          const SizedBox(height: 16),
                          if (resp.items.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 40),
                              child: EmptyStateWidget(
                                icon: Icons.receipt_long_outlined,
                                title: 'Không tìm thấy hóa đơn nào',
                                description:
                                    'Chưa có hóa đơn học phí nào phù hợp với bộ lọc hiện tại.',
                              ),
                            )
                          else
                            ...resp.items.map((inv) => _buildInvoiceCard(inv)),
                        ],
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(InvoicesSummaryModel summary) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        SizedBox(
          width: 210,
          child: _buildMetricTile(
            title: 'Tổng hóa đơn',
            value: _formatCurrency(summary.totalRevenue),
            color: AppColors.primary,
            icon: Icons.receipt_outlined,
          ),
        ),
        SizedBox(
          width: 210,
          child: _buildMetricTile(
            title: 'Đã thu',
            value: _formatCurrency(summary.paidRevenue),
            color: AppColors.success,
            icon: Icons.check_circle_outline,
          ),
        ),
        SizedBox(
          width: 210,
          child: _buildMetricTile(
            title: 'Còn nợ',
            value: _formatCurrency(summary.outstandingRevenue),
            color: AppColors.error,
            icon: Icons.pending_actions_outlined,
          ),
        ),
        if (summary.pendingTransferCount > 0 || summary.overdueCount > 0)
          SizedBox(
            width: 210,
            child: _buildMetricTile(
              title: 'Chờ duyệt CK / Quá hạn',
              value:
                  '${summary.pendingTransferCount} CK • ${summary.overdueCount} quá hạn',
              color: const Color(0xFFD97706),
              icon: Icons.sync_problem_rounded,
            ),
          ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(InvoiceModel inv) {
    final statusConfig = _getStatusConfig(inv.status);
    final studentName = inv.student?['fullName'] as String? ?? 'N/A';
    final studentCode = inv.student?['userCode'] as String? ?? '';
    final className = inv.classInfo?['name'] as String? ?? '';
    final pendingPayments = inv.pendingPayments;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: pendingPayments.isNotEmpty
              ? const Color(0xFFD97706)
              : AppColors.borderLight,
          width: pendingPayments.isNotEmpty ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Code + Status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    inv.code,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                if (pendingPayments.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFD97706)),
                    ),
                    child: Text(
                      'Chờ duyệt CK (${_formatCurrency(pendingPayments.first.amount)})',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusConfig.color.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusConfig.color.withAlpha(80)),
                  ),
                  child: Text(
                    statusConfig.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusConfig.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Title & Student
            Text(
              inv.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 16,
                  color: AppColors.textSecondaryLight,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '$studentName ($studentCode)',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (className.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.class_outlined,
                    size: 16,
                    color: AppColors.textSecondaryLight,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      className,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondaryLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 20),

            // Amount Breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tổng tiền',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMutedLight,
                      ),
                    ),
                    Text(
                      _formatCurrency(inv.totalAmount),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Đã nộp',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMutedLight,
                      ),
                    ),
                    Text(
                      _formatCurrency(inv.paidAmount),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Còn lại',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMutedLight,
                      ),
                    ),
                    Text(
                      _formatCurrency(inv.balance),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: inv.balance > 0
                            ? AppColors.error
                            : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Actions
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    await context.push('/invoices/${inv.id}');
                    if (mounted) _loadInvoices();
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('Chi tiết'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                if (pendingPayments.isNotEmpty)
                  FilledButton.icon(
                    onPressed: () {
                      context.read<FinanceBloc>().add(
                        ApprovePendingPaymentEvent(
                          paymentId: pendingPayments.first.id,
                          invoiceId: inv.id,
                          notes: 'Đối soát nhanh từ danh sách hóa đơn',
                        ),
                      );
                    },
                    icon: const Icon(Icons.verified_rounded, size: 16),
                    label: const Text('Xác nhận đã nhận CK'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                if (inv.balance > 0 && inv.status != 'CANCELLED')
                  ElevatedButton.icon(
                    onPressed: () async {
                      await context.push('/invoices/${inv.id}/record-payment');
                      if (mounted) _loadInvoices();
                    },
                    icon: const Icon(Icons.point_of_sale_outlined, size: 16),
                    label: const Text('Thu tiền'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status) {
      case 'PAID':
        return _StatusConfig(label: 'ĐÃ THANH TOÁN', color: AppColors.success);
      case 'PARTIALLY_PAID':
        return _StatusConfig(
          label: 'TRẢ MỘT PHẦN',
          color: const Color(0xFF0284C7),
        );
      case 'OVERDUE':
        return _StatusConfig(label: 'QUÁ HẠN', color: AppColors.error);
      case 'CANCELLED':
        return _StatusConfig(label: 'ĐÃ HỦY', color: Colors.grey);
      case 'REFUNDED':
        return _StatusConfig(label: 'ĐÃ HOÀN TIỀN', color: Colors.purple);
      default:
        return _StatusConfig(
          label: 'CHỜ THANH TOÁN',
          color: const Color(0xFFD97706),
        );
    }
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )} đ';
  }
}

class _StatusConfig {
  final String label;
  final Color color;

  _StatusConfig({required this.label, required this.color});
}
