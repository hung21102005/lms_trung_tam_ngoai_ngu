import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Query,
  Req,
  Request,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiQuery, ApiTags } from '@nestjs/swagger';
import { InvoiceStatus } from '@prisma/client';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { RolesGuard } from '../auth/guards/roles.guard.js';
import { Roles } from '../auth/decorators/roles.decorator.js';
import { FinanceService } from './finance.service.js';
import {
  CreateInvoiceDto,
  RecordPaymentDto,
  CreatePromotionDto,
  ValidatePromotionDto,
  PayOnlineDto,
} from './dto/index.js';

@ApiTags('Finance & Invoices (Tài chính & Học phí)')
@Controller('finance')
export class FinanceController {
  constructor(private readonly financeService: FinanceService) {}

  // --------------------------------------------------------------------------
  // HÓA ĐƠN (INVOICES)
  // --------------------------------------------------------------------------

  @Post('invoices')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin', 'branch_admin', 'cashier')
  @ApiOperation({ summary: 'Tạo hóa đơn học phí mới' })
  async createInvoice(@Request() req: any, @Body() dto: CreateInvoiceDto) {
    return this.financeService.createInvoice(dto, req.user.id);
  }

  @Get('invoices')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin', 'branch_admin', 'cashier', 'academic_staff')
  @ApiOperation({ summary: 'Lấy danh sách hóa đơn học phí (tìm kiếm, lọc, phân trang)' })
  @ApiQuery({ name: 'status', required: false, enum: InvoiceStatus })
  @ApiQuery({ name: 'studentId', required: false })
  @ApiQuery({ name: 'classId', required: false })
  @ApiQuery({ name: 'search', required: false })
  @ApiQuery({ name: 'startDate', required: false })
  @ApiQuery({ name: 'endDate', required: false })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async getInvoices(
    @Query('status') status?: InvoiceStatus,
    @Query('studentId') studentId?: string,
    @Query('classId') classId?: string,
    @Query('search') search?: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.financeService.getInvoices({
      status,
      studentId,
      classId,
      search,
      startDate,
      endDate,
      page: page ? parseInt(page, 10) : 1,
      limit: limit ? parseInt(limit, 10) : 20,
    });
  }

  @Get('my-invoices')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @ApiOperation({ summary: 'Lấy danh sách hóa đơn của học viên hoặc con em (phụ huynh)' })
  async getMyInvoices(@Request() req: any) {
    return this.financeService.getMyInvoices(req.user.id);
  }

  @Get('invoices/:id')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @ApiOperation({ summary: 'Xem chi tiết hóa đơn và lịch sử thanh toán' })
  async getInvoiceById(@Param('id') id: string) {
    return this.financeService.getInvoiceById(id);
  }

  @Post('invoices/:id/payments')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin', 'branch_admin', 'cashier')
  @ApiOperation({ summary: 'Ghi nhận thanh toán học phí (tiền mặt/chuyển khoản)' })
  async recordPayment(
    @Request() req: any,
    @Param('id') id: string,
    @Body() dto: RecordPaymentDto,
  ) {
    return this.financeService.recordPayment(id, dto, req.user.id);
  }

  @Post('invoices/:id/cancel')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin', 'branch_admin', 'cashier')
  @ApiOperation({ summary: 'Hủy hóa đơn học phí' })
  async cancelInvoice(@Param('id') id: string, @Body('reason') reason?: string) {
    return this.financeService.cancelInvoice(id, reason);
  }

  @Post('invoices/:id/refund')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin', 'branch_admin', 'cashier')
  @ApiOperation({ summary: 'Hoàn tiền học phí' })
  async refundInvoice(
    @Request() req: any,
    @Param('id') id: string,
    @Body('amount') amount: number,
    @Body('reason') reason?: string,
  ) {
    return this.financeService.refundInvoice(id, amount, reason, req.user.id);
  }

  @Post('invoices/:id/pay-online')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @ApiOperation({ summary: 'Tạo URL thanh toán trực tuyến qua VNPay' })
  async payOnline(
    @Req() req: any,
    @Param('id') id: string,
    @Body() dto: PayOnlineDto,
  ) {
    const invoice = await this.financeService.getInvoiceById(id);
    const ipAddr =
      req.headers['x-forwarded-for'] ||
      req.connection?.remoteAddress ||
      req.socket?.remoteAddress ||
      '127.0.0.1';

    const paymentUrl = this.financeService.createVNPayPaymentUrl(
      invoice,
      typeof ipAddr === 'string' ? ipAddr.split(',')[0].trim() : '127.0.0.1',
      dto,
    );

    return { paymentUrl, invoiceCode: invoice.code, amount: invoice.balance };
  }

  @Get('payments/vnpay-return')
  @ApiOperation({ summary: 'Callback xử lý kết quả thanh toán từ VNPay' })
  async vnpayReturn(@Query() query: Record<string, any>) {
    return this.financeService.handleVNPayCallback(query);
  }

  @Post('invoices/check-overdue')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin', 'branch_admin')
  @ApiOperation({ summary: 'Kích hoạt quét hóa đơn quá hạn và gửi thông báo nhắc nợ' })
  async checkOverdueInvoices() {
    return this.financeService.checkOverdueInvoices();
  }

  // --------------------------------------------------------------------------
  // MÃ KHUYẾN MÃI (PROMOTIONS)
  // --------------------------------------------------------------------------

  @Post('promotions')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('super_admin', 'branch_admin')
  @ApiOperation({ summary: 'Tạo chương trình ưu đãi / mã khuyến mãi mới' })
  async createPromotion(@Body() dto: CreatePromotionDto) {
    return this.financeService.createPromotion(dto);
  }

  @Get('promotions')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @ApiOperation({ summary: 'Lấy danh sách mã khuyến mãi' })
  @ApiQuery({ name: 'isActive', required: false, type: Boolean })
  async getPromotions(@Query('isActive') isActive?: string) {
    const activeBool = isActive !== undefined ? isActive === 'true' : undefined;
    return this.financeService.getPromotions(activeBool);
  }

  @Post('promotions/validate')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @ApiOperation({ summary: 'Kiểm tra tính hợp lệ và số tiền giảm giá của mã khuyến mãi' })
  async validatePromotion(@Body() dto: ValidatePromotionDto) {
    return this.financeService.validatePromotion(dto);
  }
}
