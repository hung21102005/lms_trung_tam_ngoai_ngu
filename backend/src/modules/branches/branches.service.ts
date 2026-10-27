import {
  Injectable,
  NotFoundException,
  ConflictException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../../database/index.js';
import {
  CreateBranchDto,
  UpdateBranchDto,
  CreateRoomDto,
  UpdateRoomDto,
} from './dto/index.js';

@Injectable()
export class BranchesService {
  private readonly logger = new Logger(BranchesService.name);

  constructor(private readonly prisma: PrismaService) {}

  // --------------------------------------------------------------------------
  // CHI NHÁNH (BRANCHES)
  // --------------------------------------------------------------------------

  async createBranch(dto: CreateBranchDto) {
    const code = dto.code.trim().toUpperCase();

    const existing = await this.prisma.branch.findUnique({
      where: { code },
    });

    if (existing) {
      throw new ConflictException(`Mã chi nhánh '${code}' đã tồn tại trong hệ thống.`);
    }

    const branch = await this.prisma.branch.create({
      data: {
        code,
        name: dto.name.trim(),
        address: dto.address.trim(),
        phone: dto.phone?.trim(),
        email: dto.email?.trim().toLowerCase(),
        isActive: true,
      },
    });

    this.logger.log(`Tạo chi nhánh mới: [${branch.code}] ${branch.name}`);

    return {
      message: 'Tạo chi nhánh mới thành công.',
      branch,
    };
  }

  async findAllBranches() {
    const branches = await this.prisma.branch.findMany({
      orderBy: { createdAt: 'asc' },
      include: {
        _count: {
          select: {
            rooms: true,
            users: true,
          },
        },
      },
    });

    return {
      total: branches.length,
      items: branches,
    };
  }

  async findOneBranch(id: string) {
    const branch = await this.prisma.branch.findUnique({
      where: { id },
      include: {
        rooms: {
          orderBy: { code: 'asc' },
        },
        _count: {
          select: {
            users: true,
            leads: true,
          },
        },
      },
    });

    if (!branch) {
      throw new NotFoundException('Không tìm thấy chi nhánh.');
    }

    return branch;
  }

  async updateBranch(id: string, dto: UpdateBranchDto) {
    await this.findOneBranch(id);

    const updated = await this.prisma.branch.update({
      where: { id },
      data: {
        name: dto.name?.trim(),
        address: dto.address?.trim(),
        phone: dto.phone?.trim(),
        email: dto.email?.trim().toLowerCase(),
        isActive: dto.isActive,
      },
    });

    return {
      message: 'Cập nhật thông tin chi nhánh thành công.',
      branch: updated,
    };
  }

  // --------------------------------------------------------------------------
  // PHÒNG HỌC (ROOMS)
  // --------------------------------------------------------------------------

  async findRoomsByBranch(branchId: string) {
    await this.findOneBranch(branchId);

    const rooms = await this.prisma.room.findMany({
      where: { branchId },
      orderBy: { code: 'asc' },
    });

    return {
      branchId,
      total: rooms.length,
      items: rooms,
    };
  }

  async createRoom(dto: CreateRoomDto) {
    await this.findOneBranch(dto.branchId);

    const code = dto.code.trim().toUpperCase();

    const existingRoom = await this.prisma.room.findUnique({
      where: {
        branchId_code: {
          branchId: dto.branchId,
          code,
        },
      },
    });

    if (existingRoom) {
      throw new ConflictException(`Phòng '${code}' đã tồn tại trong chi nhánh này.`);
    }

    const room = await this.prisma.room.create({
      data: {
        branchId: dto.branchId,
        code,
        name: dto.name.trim(),
        capacity: dto.capacity ?? 25,
        equipment: dto.equipment?.trim(),
        isActive: true,
      },
      include: {
        branch: {
          select: { id: true, code: true, name: true },
        },
      },
    });

    this.logger.log(`Tạo phòng học mới: [${room.code}] ${room.name} tại chi nhánh ${dto.branchId}`);

    return {
      message: 'Tạo phòng học mới thành công.',
      room,
    };
  }

  async updateRoom(roomId: string, dto: UpdateRoomDto) {
    const room = await this.prisma.room.findUnique({
      where: { id: roomId },
    });

    if (!room) {
      throw new NotFoundException('Không tìm thấy phòng học.');
    }

    const updated = await this.prisma.room.update({
      where: { id: roomId },
      data: {
        name: dto.name?.trim(),
        capacity: dto.capacity,
        equipment: dto.equipment?.trim(),
        isActive: dto.isActive,
      },
    });

    return {
      message: 'Cập nhật thông tin phòng học thành công.',
      room: updated,
    };
  }
}
