import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/adaptive/adaptive_layout.dart';
import '../../../../core/constants/api_endpoints.dart';
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
  final TextEditingController _transferAmountCtrl = TextEditingController();
  final TextEditingController _transactionIdCtrl = TextEditingController();
  final TextEditingController _transferNotesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _invoice = context.read<FinanceBloc>().getCachedInvoiceDetail(
      widget.invoiceId,
    );
    if (_invoice != null) {
      _transferAmountCtrl.text = _invoice!.balance.toInt().toString();
    }
    context.read<FinanceBloc>().add(FetchInvoiceDetailEvent(widget.invoiceId));
  }

  @override
  void dispose() {
    _transferAmountCtrl.dispose();
    _transactionIdCtrl.dispose();
    _transferNotesCtrl.dispose();
    super.dispose();
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
              if (_transferAmountCtrl.text.trim().isEmpty) {
                _transferAmountCtrl.text = state.invoice.balance
                    .toInt()
                    .toString();
              }
            });
          }
          if (state is PayOnlineUrlReadyState) {
            _showVNPayDialog(context, state.paymentUrl);
          }
          if (state is FinanceActionSuccessState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
            context.read<FinanceBloc>().add(FetchMyInvoicesEvent());
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
    final amount =
        (double.tryParse(_transferAmountCtrl.text.trim()) ?? inv.balance)
            .toInt();
    final memo = 'HOCPHI ${inv.code}';
    final qrUrl = kIsWeb
        ? '${ApiEndpoints.baseUrl}/finance/vietqr?bankId=$bankId&accountNo=$accountNo&amount=$amount&addInfo=${Uri.encodeComponent(memo)}&accountName=${Uri.encodeComponent(accountName)}'
        : 'https://img.vietqr.io/image/$bankId-$accountNo-compact2.png?amount=$amount&addInfo=${Uri.encodeComponent(memo)}&accountName=${Uri.encodeComponent(accountName)}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border(context),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Mở App Ngân hàng bất kỳ để quét mã QR',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'Hệ thống tự động điền số tài khoản, số tiền và nội dung chuyển khoản',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // QR Code Image (keep white background for QR scannability)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border(context)),
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

          // Refresh / Submit transfer confirmation section
          if (inv.hasPendingTransfer)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warningBg(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warningFg(context)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.hourglass_top_rounded,
                    color: AppColors.warningFg(context),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Bạn đã gửi xác nhận chuyển khoản cho hóa đơn này. Thu ngân đang kiểm tra sao kê để xác nhận phiếu thu.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warningFg(context),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            const Divider(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Xác nhận đã chuyển khoản để Thu ngân đối soát',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ActionChip(
                  label: const Text('Đóng 100% dư nợ'),
                  onPressed: () {
                    setState(() {
                      _transferAmountCtrl.text = inv.balance.toInt().toString();
                    });
                  },
                ),
                const SizedBox(width: 8),
                if (inv.balance >= 1000000)
                  ActionChip(
                    label: const Text('Đóng 50%'),
                    onPressed: () {
                      setState(() {
                        _transferAmountCtrl.text =
                            (inv.balance / 2).toInt().toString();
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _transferAmountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số tiền đã chuyển khoản (VNĐ) *',
                prefixIcon: Icon(Icons.payments_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _transactionIdCtrl,
              decoration: const InputDecoration(
                labelText: 'Mã giao dịch ngân hàng (tùy chọn)',
                hintText: 'VD: FT261121998877',
                prefixIcon: Icon(Icons.receipt_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: () {
                  final amt =
                      double.tryParse(_transferAmountCtrl.text.trim()) ??
                      inv.balance;
                  if (amt <= 0 || amt > inv.balance) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Số tiền xác nhận không hợp lệ hoặc vượt quá dư nợ.',
                        ),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }
                  context.read<FinanceBloc>().add(
                    SubmitTransferPaymentEvent(
                      invoiceId: inv.id,
                      amount: amt,
                      transactionId: _transactionIdCtrl.text.trim(),
                      notes: 'Xác nhận chuyển khoản VietQR (${inv.code})',
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Gửi xác nhận đã chuyển khoản'),
              ),
            ),
          ],
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              context.read<FinanceBloc>().add(
                FetchInvoiceDetailEvent(widget.invoiceId),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đang làm mới trạng thái thanh toán...'),
                ),
              );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Làm mới trạng thái hóa đơn'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
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
    final vnpayAccent = AppColors.adaptAccent(context, const Color(0xFF005BAA));
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: vnpayAccent.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.payment,
                  color: vnpayAccent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cổng thanh toán VNPay',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hỗ trợ ATM nội địa, thẻ quốc tế Visa/Master, VNPAY-QR',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary(context),
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
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary(context),
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
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary(context),
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
                child: Icon(
                  Icons.copy,
                  size: 16,
                  color: AppColors.primaryOf(context),
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
              style: TextStyle(
                fontSize: 11,
                color: AppColors.primaryOf(dialogCtx),
              ),
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
