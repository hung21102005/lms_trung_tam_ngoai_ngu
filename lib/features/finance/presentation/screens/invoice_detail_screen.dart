import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/invoice_model.dart';
import '../bloc/finance_bloc.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final String invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<FinanceBloc>().add(FetchInvoiceDetailEvent(widget.invoiceId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết Hóa đơn'),
      ),
      body: BlocConsumer<FinanceBloc, FinanceState>(
        listener: (context, state) {
          if (state is FinanceActionSuccessState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.success),
            );
            context.read<FinanceBloc>().add(FetchInvoiceDetailEvent(widget.invoiceId));
          }
        },
        builder: (context, state) {
          if (state is FinanceLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is FinanceErrorState) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text('Lỗi: ${state.message}', style: AppTextStyles.bodyMedium(context)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<FinanceBloc>().add(FetchInvoiceDetailEvent(widget.invoiceId));
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (state is InvoiceDetailLoadedState) {
            final inv = state.invoice;
            return _buildContent(inv);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(InvoiceModel inv) {
    final statusConfig = _getStatusConfig(inv.status);
    final studentName = inv.student?['fullName'] as String? ?? 'N/A';
    final studentPhone = inv.student?['phone'] as String? ?? 'Chưa cập nhật';
    final studentEmail = inv.student?['email'] as String? ?? 'Chưa cập nhật';
    final studentCode = inv.student?['userCode'] as String? ?? '';
    final className = inv.classInfo?['name'] as String? ?? 'Không xác định';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card: Code, Title, Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      inv.code,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusConfig.color.withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: statusConfig.color.withAlpha(80)),
                      ),
                      child: Text(
                        statusConfig.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusConfig.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  inv.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ngày phát hành: ${_formatDate(inv.issuedDate)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
                if (inv.dueDate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Hạn thanh toán: ${_formatDate(inv.dueDate!)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: inv.status == 'OVERDUE' ? AppColors.error : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Student & Class Info Card
          _buildSectionHeader('Thông tin đối tượng thụ hưởng'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                _buildInfoRow('Học viên', '$studentName ($studentCode)'),
                const Divider(height: 16),
                _buildInfoRow('Số điện thoại', studentPhone),
                const Divider(height: 16),
                _buildInfoRow('Email', studentEmail),
                const Divider(height: 16),
                _buildInfoRow('Lớp học áp dụng', className),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Financial Summary Card
          _buildSectionHeader('Chi tiết khoản tiền'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                _buildAmountRow('Học phí gốc', inv.subtotal),
                if (inv.discount > 0) ...[
                  const SizedBox(height: 8),
                  _buildAmountRow('Giảm trừ / Khuyến mãi', -inv.discount, color: AppColors.success),
                  if (inv.promotion != null) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Mã KM: ${inv.promotion!.code} (${inv.promotion!.name})',
                        style: const TextStyle(fontSize: 11, color: AppColors.success),
                      ),
                    ),
                  ],
                ],
                const Divider(height: 20),
                _buildAmountRow('Tổng tiền phải nộp', inv.totalAmount, isBold: true),
                const SizedBox(height: 8),
                _buildAmountRow('Đã thanh toán', inv.paidAmount, color: AppColors.success),
                const Divider(height: 20),
                _buildAmountRow(
                  'Số dư còn lại',
                  inv.balance,
                  isBold: true,
                  color: inv.balance > 0 ? AppColors.error : AppColors.success,
                  fontSize: 16,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Payment History
          _buildSectionHeader('Lịch sử các lần đóng tiền (${inv.payments.length})'),
          const SizedBox(height: 8),
          if (inv.payments.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Text('Chưa có khoản thanh toán nào được ghi nhận.'),
            )
          else
            ...inv.payments.map((p) => _buildPaymentItem(p)),

          const SizedBox(height: 24),

          // Bottom Action Buttons
          if (inv.balance > 0 && inv.status != 'CANCELLED') ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/invoices/${inv.id}/record-payment');
                    },
                    icon: const Icon(Icons.point_of_sale, size: 20),
                    label: const Text('Thu tiền mặt / CK'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/invoices/${inv.id}/pay-online');
                    },
                    icon: const Icon(Icons.payment, size: 20),
                    label: const Text('Thanh toán VNPay'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF005BAA), // VNPay Blue
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          if (inv.status != 'PAID' && inv.status != 'CANCELLED' && inv.paidAmount == 0) ...[
            Center(
              child: TextButton.icon(
                onPressed: () => _confirmCancel(context, inv.id),
                icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
                label: const Text('Hủy hóa đơn này', style: TextStyle(color: AppColors.error)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildAmountRow(
    String label,
    double amount, {
    bool isBold = false,
    Color? color,
    double fontSize = 14,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color ?? AppColors.textPrimaryLight,
          ),
        ),
        Text(
          _formatCurrency(amount),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color ?? AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentItem(PaymentModel payment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: AppColors.success, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      payment.code,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _formatCurrency(payment.amount),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatDate(payment.payDate)} • Phương thức: ${payment.method}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                ),
                if (payment.transactionId != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Mã GD: ${payment.transactionId}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMutedLight),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context, String invoiceId) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Xác nhận hủy hóa đơn'),
        content: const Text('Bạn có chắc chắn muốn hủy hóa đơn này không? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<FinanceBloc>().add(CancelInvoiceEvent(invoiceId, reason: 'Người dùng hủy'));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xác nhận hủy', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status) {
      case 'PAID':
        return _StatusConfig(label: 'ĐÃ THANH TOÁN', color: AppColors.success);
      case 'PARTIALLY_PAID':
        return _StatusConfig(label: 'TRẢ MỘT PHẦN', color: const Color(0xFF0284C7));
      case 'OVERDUE':
        return _StatusConfig(label: 'QUÁ HẠN', color: AppColors.error);
      case 'CANCELLED':
        return _StatusConfig(label: 'ĐÃ HỦY', color: Colors.grey);
      case 'REFUNDED':
        return _StatusConfig(label: 'ĐÃ HOÀN TIỀN', color: Colors.purple);
      default:
        return _StatusConfig(label: 'CHỜ THANH TOÁN', color: const Color(0xFFD97706));
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
