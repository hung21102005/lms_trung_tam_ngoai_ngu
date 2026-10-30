import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/adaptive/adaptive_layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/invoice_model.dart';
import '../bloc/finance_bloc.dart';

class PayOnlineScreen extends StatefulWidget {
  final String invoiceId;

  const PayOnlineScreen({super.key, required this.invoiceId});

  @override
  State<PayOnlineScreen> createState() => _PayOnlineScreenState();
}

class _PayOnlineScreenState extends State<PayOnlineScreen> {
  InvoiceModel? _invoice;
  int _selectedTab = 0; // 0: VietQR, 1: VNPay Gateway

  @override
  void initState() {
    super.initState();
    context.read<FinanceBloc>().add(FetchInvoiceDetailEvent(widget.invoiceId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán trực tuyến')),
      body: BlocConsumer<FinanceBloc, FinanceState>(
        listener: (context, state) {
          if (state is InvoiceDetailLoadedState) {
            setState(() {
              _invoice = state.invoice;
            });
          }
          if (state is PayOnlineUrlReadyState) {
            _showVNPayDialog(context, state.paymentUrl);
          }
          if (state is FinanceErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi: ${state.message}'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (_invoice == null && state is FinanceLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_invoice == null) {
            return Center(
              child: ElevatedButton(
                onPressed: () {
                  context.read<FinanceBloc>().add(
                    FetchInvoiceDetailEvent(widget.invoiceId),
                  );
                },
                child: const Text('Tải lại thông tin'),
              ),
            );
          }

          final inv = _invoice!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Amount to pay
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primaryGradientStart,
                        AppColors.primaryGradientEnd,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(50),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Số tiền cần thanh toán',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatCurrency(inv.balance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Hóa đơn: ${inv.code} • ${inv.title}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Method selector tabs
                AdaptiveBreakpoints.fromWidth(
                          MediaQuery.sizeOf(context).width,
                        ) ==
                        AdaptiveSize.mobile
                    ? SingleChildScrollView(
                        key: const ValueKey('payment-methods-mobile'),
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: const Text('Quét mã VietQR'),
                              selected: _selectedTab == 0,
                              onSelected: (_) =>
                                  setState(() => _selectedTab = 0),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Cổng VNPay'),
                              selected: _selectedTab == 1,
                              onSelected: (_) =>
                                  setState(() => _selectedTab = 1),
                            ),
                          ],
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.qr_code_2, size: 20),
                                  SizedBox(width: 6),
                                  Text('Quét mã VietQR'),
                                ],
                              ),
                              selected: _selectedTab == 0,
                              onSelected: (val) =>
                                  setState(() => _selectedTab = 0),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ChoiceChip(
                              label: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.payment, size: 20),
                                  SizedBox(width: 6),
                                  Text('Cổng VNPay'),
                                ],
                              ),
                              selected: _selectedTab == 1,
                              onSelected: (val) =>
                                  setState(() => _selectedTab = 1),
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 20),

                if (_selectedTab == 0)
                  _buildVietQRSection(inv)
                else
                  _buildVNPaySection(inv, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVietQRSection(InvoiceModel inv) {
    const bankId = 'MB'; // MBBank
    const accountNo = '0333888999';
    const accountName = 'TRUNG TAM NGOAI NGU LMS';
    final amount = inv.balance.toInt();
    final memo = 'HOCPHI ${inv.code}';
    final qrUrl =
        'https://img.vietqr.io/image/$bankId-$accountNo-compact2.png?amount=$amount&addInfo=${Uri.encodeComponent(memo)}&accountName=${Uri.encodeComponent(accountName)}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          const Text(
            'Mở App Ngân hàng bất kỳ để quét mã QR',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          const Text(
            'Hệ thống tự động điền số tài khoản, số tiền và nội dung chuyển khoản',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // QR Code Image
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderLight),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.network(
              qrUrl,
              width: 220,
              height: 220,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.qr_code_2,
                size: 160,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Transfer Details
          _buildCopyRow('Ngân hàng', 'MBBank (Ngân hàng Quân Đội)', null),
          const Divider(height: 16),
          _buildCopyRow(
            'Số tài khoản',
            accountNo,
            () => _copyToClipboard(accountNo, 'Số tài khoản'),
          ),
          const Divider(height: 16),
          _buildCopyRow('Tên người thụ hưởng', accountName, null),
          const Divider(height: 16),
          _buildCopyRow('Số tiền chuyển', _formatCurrency(inv.balance), null),
          const Divider(height: 16),
          _buildCopyRow(
            'Nội dung chuyển khoản',
            memo,
            () => _copyToClipboard(memo, 'Nội dung chuyển khoản'),
          ),
          const SizedBox(height: 20),

          // Refresh status button
          OutlinedButton.icon(
            onPressed: () {
              context.read<FinanceBloc>().add(
                FetchInvoiceDetailEvent(widget.invoiceId),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đang kiểm tra trạng thái thanh toán...'),
                ),
              );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Tôi đã chuyển khoản - Kiểm tra trạng thái'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVNPaySection(InvoiceModel inv, FinanceState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF005BAA).withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.payment,
                  color: Color(0xFF005BAA),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cổng thanh toán VNPay',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Hỗ trợ ATM nội địa, thẻ quốc tế Visa/Master, VNPAY-QR',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Bấm nút bên dưới để mở giao diện thanh toán an toàn trực tiếp từ VNPay Sandbox.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: state is FinanceLoadingState
                  ? null
                  : () {
                      context.read<FinanceBloc>().add(PayOnlineEvent(inv.id));
                    },
              icon: const Icon(Icons.lock_outline, color: Colors.white),
              label: state is FinanceLoadingState
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Tạo liên kết thanh toán VNPay',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005BAA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyRow(String label, String value, VoidCallback? onCopy) {
    if (AdaptiveBreakpoints.fromWidth(MediaQuery.sizeOf(context).width) ==
        AdaptiveSize.mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (onCopy != null)
                IconButton(
                  onPressed: onCopy,
                  tooltip: 'Sao chép $label',
                  icon: const Icon(Icons.copy, size: 18),
                ),
            ],
          ),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondaryLight,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            if (onCopy != null) ...[
              const SizedBox(width: 6),
              InkWell(
                onTap: onCopy,
                child: const Icon(
                  Icons.copy,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $label'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showVNPayDialog(BuildContext context, String paymentUrl) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Mở liên kết thanh toán VNPay'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Đường dẫn thanh toán VNPay Sandbox đã sẵn sàng:'),
            const SizedBox(height: 8),
            SelectableText(
              paymentUrl,
              style: const TextStyle(fontSize: 11, color: AppColors.primary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: paymentUrl));
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã sao chép link thanh toán VNPay'),
                ),
              );
            },
            child: const Text('Sao chép Link'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} đ';
  }
}
