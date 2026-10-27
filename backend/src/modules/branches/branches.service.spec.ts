import { Test, TestingModule } from '@nestjs/testing';
import { BranchesService } from './branches.service.js';
import { PrismaService } from '../../database/index.js';
import { NotFoundException, ConflictException } from '@nestjs/common';

describe('BranchesService', () => {
  let service: BranchesService;

  const mockBranch = {
    id: 'br-uuid-1',
    code: 'BR-BT',
    name: 'Chi nhánh Bình Thạnh',
    address: '456 Điện Biên Phủ',
    phone: '0283998877',
    email: 'bt@lms-edu.vn',
    isActive: true,
  };

  const mockRoom = {
    id: 'room-uuid-1',
    branchId: 'br-uuid-1',
    code: 'P201',
    name: 'Phòng 201',
    capacity: 25,
    equipment: 'Máy chiếu, loa',
    isActive: true,
  };

  const mockPrismaService = {
    branch: {
      create: vi.fn(),
      findMany: vi.fn(),
      findUnique: vi.fn(),
      update: vi.fn(),
    },
    room: {
      create: vi.fn(),
      findMany: vi.fn(),
      findUnique: vi.fn(),
      update: vi.fn(),
    },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        BranchesService,
        { provide: PrismaService, useValue: mockPrismaService },
      ],
    }).compile();

    service = module.get<BranchesService>(BranchesService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('createBranch', () => {
    it('should throw ConflictException if branch code already exists', async () => {
      mockPrismaService.branch.findUnique.mockResolvedValue(mockBranch);

      await expect(
        service.createBranch({
          code: 'BR-BT',
          name: 'Chi nhánh Bình Thạnh',
          address: '456 Điện Biên Phủ',
        }),
      ).rejects.toThrow(ConflictException);
    });

    it('should successfully create a new branch', async () => {
      mockPrismaService.branch.findUnique.mockResolvedValue(null);
      mockPrismaService.branch.create.mockResolvedValue(mockBranch);

      const res = await service.createBranch({
        code: 'BR-BT',
        name: 'Chi nhánh Bình Thạnh',
        address: '456 Điện Biên Phủ',
      });

      expect(res.branch.code).toBe('BR-BT');
    });
  });

  describe('findOneBranch', () => {
    it('should throw NotFoundException if branch does not exist', async () => {
      mockPrismaService.branch.findUnique.mockResolvedValue(null);

      await expect(service.findOneBranch('invalid-id')).rejects.toThrow(NotFoundException);
    });
  });

  describe('createRoom', () => {
    it('should throw ConflictException if room code already exists in branch', async () => {
      mockPrismaService.branch.findUnique.mockResolvedValue(mockBranch);
      mockPrismaService.room.findUnique.mockResolvedValue(mockRoom);

      await expect(
        service.createRoom({
          branchId: 'br-uuid-1',
          code: 'P201',
          name: 'Phòng 201',
        }),
      ).rejects.toThrow(ConflictException);
    });
  });
});
