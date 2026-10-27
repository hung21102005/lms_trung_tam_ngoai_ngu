import { Test, TestingModule } from '@nestjs/testing';
import { CoursesService } from './courses.service.js';
import { PrismaService } from '../../database/index.js';
import { NotFoundException, ConflictException } from '@nestjs/common';
import { describe, it, expect, beforeEach, vi } from 'vitest';

describe('CoursesService', () => {
  let service: CoursesService;

  const mockCourse = {
    id: 'course-uuid-1',
    code: 'ENG-IELTS',
    title: 'Khóa học IELTS',
    description: 'Luyện thi toàn diện',
    language: 'English',
    isActive: true,
  };

  const mockPrismaService = {
    course: {
      findMany: vi.fn(),
      count: vi.fn(),
      findUnique: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
    },
    courseLevel: {
      findMany: vi.fn(),
      findUnique: vi.fn(),
      create: vi.fn(),
    },
    module: {
      findMany: vi.fn(),
      findUnique: vi.fn(),
      create: vi.fn(),
    },
    lesson: {
      findMany: vi.fn(),
      findUnique: vi.fn(),
      create: vi.fn(),
    },
    lessonMaterial: {
      create: vi.fn(),
    },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CoursesService,
        { provide: PrismaService, useValue: mockPrismaService },
      ],
    }).compile();

    service = module.get<CoursesService>(CoursesService);
    vi.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('create', () => {
    it('should throw ConflictException if course code exists', async () => {
      mockPrismaService.course.findUnique.mockResolvedValueOnce(mockCourse);

      await expect(
        service.create({ code: 'ENG-IELTS', title: 'Khóa học IELTS mới' }),
      ).rejects.toThrow(ConflictException);
    });

    it('should create course successfully', async () => {
      mockPrismaService.course.findUnique.mockResolvedValueOnce(null);
      mockPrismaService.course.create.mockResolvedValueOnce(mockCourse);

      const result = await service.create({
        code: 'ENG-IELTS',
        title: 'Khóa học IELTS',
      });

      expect(result).toEqual(mockCourse);
    });
  });

  describe('findOne', () => {
    it('should throw NotFoundException if course not found', async () => {
      mockPrismaService.course.findUnique.mockResolvedValueOnce(null);

      await expect(service.findOne('invalid-id')).rejects.toThrow(NotFoundException);
    });

    it('should return course if found', async () => {
      mockPrismaService.course.findUnique.mockResolvedValueOnce(mockCourse);

      const result = await service.findOne('course-uuid-1');
      expect(result).toEqual(mockCourse);
    });
  });
});
