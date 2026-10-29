import { Test, TestingModule } from '@nestjs/testing';
import { CoursesService } from './courses.service.js';
import { PrismaService } from '../../database/index.js';
import {
  NotFoundException,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import { PublicationStatus } from '@prisma/client';
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
    class: {
      count: vi.fn().mockResolvedValue(0),
    },
    trainingProgram: {
      findMany: vi.fn(),
      findFirst: vi.fn(),
      findUnique: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
    },
    course: {
      findMany: vi.fn(),
      findFirst: vi.fn(),
      count: vi.fn(),
      findUnique: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
    },
    courseLevel: {
      findMany: vi.fn(),
      findUnique: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
    },
    module: {
      findMany: vi.fn(),
      findUnique: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
    },
    lesson: {
      findMany: vi.fn(),
      findUnique: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
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
    vi.resetAllMocks();
    mockPrismaService.class.count.mockResolvedValue(0);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('curriculum editing', () => {
    it('rejects changing a lesson used by an active class', async () => {
      mockPrismaService.lesson.findUnique.mockResolvedValueOnce({
        module: {
          level: {
            courseId: 'course-uuid-1',
            course: { publicationStatus: PublicationStatus.DRAFT },
          },
        },
      });
      mockPrismaService.class.count.mockResolvedValueOnce(1);
      await expect(
        service.updateLesson('lesson-1', { title: 'Thay đổi bài học' }),
      ).rejects.toThrow(ConflictException);
      expect(mockPrismaService.lesson.update).not.toHaveBeenCalled();
    });
    it('rejects adding materials to an archived course', async () => {
      mockPrismaService.lesson.findUnique.mockResolvedValueOnce({
        module: {
          level: { course: { publicationStatus: PublicationStatus.ARCHIVED } },
        },
      });
      await expect(
        service.createLessonMaterial('lesson-1', {
          title: 'Slide',
          fileUrl: 'https://example.com/slide.pdf',
        }),
      ).rejects.toThrow(BadRequestException);
      expect(mockPrismaService.lessonMaterial.create).not.toHaveBeenCalled();
    });

    it('rejects creating a module in an archived course', async () => {
      mockPrismaService.courseLevel.findUnique.mockResolvedValueOnce({
        course: { publicationStatus: PublicationStatus.ARCHIVED },
      });
      await expect(
        service.createModule('level-1', { title: 'Học phần mới' }),
      ).rejects.toThrow(BadRequestException);
      expect(mockPrismaService.module.create).not.toHaveBeenCalled();
    });

    it('rejects creating a lesson in an archived course', async () => {
      mockPrismaService.module.findUnique.mockResolvedValueOnce({
        level: { course: { publicationStatus: PublicationStatus.ARCHIVED } },
      });
      await expect(
        service.createLesson('module-1', { title: 'Bài học mới' }),
      ).rejects.toThrow(BadRequestException);
      expect(mockPrismaService.lesson.create).not.toHaveBeenCalled();
    });

    it('updates a module while its course is editable', async () => {
      mockPrismaService.module.findUnique.mockResolvedValueOnce({
        level: { course: { publicationStatus: PublicationStatus.DRAFT } },
      });
      mockPrismaService.module.update.mockResolvedValueOnce({
        id: 'module-1',
        title: 'Ngữ âm',
      });
      await service.updateModule('module-1', { title: 'Ngữ âm' });
      expect(mockPrismaService.module.update).toHaveBeenCalledWith({
        where: { id: 'module-1' },
        data: { title: 'Ngữ âm' },
      });
    });

    it('rejects editing a lesson in an archived course', async () => {
      mockPrismaService.lesson.findUnique.mockResolvedValueOnce({
        module: {
          level: { course: { publicationStatus: PublicationStatus.ARCHIVED } },
        },
      });
      await expect(
        service.updateLesson('lesson-1', { title: 'Bài mới' }),
      ).rejects.toThrow(BadRequestException);
      expect(mockPrismaService.lesson.update).not.toHaveBeenCalled();
    });

    it('updates lesson content without changing its parent', async () => {
      mockPrismaService.lesson.findUnique.mockResolvedValueOnce({
        module: {
          level: { course: { publicationStatus: PublicationStatus.IN_REVIEW } },
        },
      });
      mockPrismaService.lesson.update.mockResolvedValueOnce({ id: 'lesson-1' });
      await service.updateLesson('lesson-1', {
        content: 'Mục tiêu và bài tập',
      });
      expect(mockPrismaService.lesson.update).toHaveBeenCalledWith({
        where: { id: 'lesson-1' },
        data: { content: 'Mục tiêu và bài tập' },
      });
    });
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

      await expect(service.findOne('invalid-id')).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should return course if found', async () => {
      mockPrismaService.course.findUnique.mockResolvedValueOnce(mockCourse);

      const result = await service.findOne('course-uuid-1');
      expect(result).toEqual(mockCourse);
    });
  });

  describe('publication workflow', () => {
    it('filters public catalog by program and course publication state', async () => {
      mockPrismaService.course.findMany.mockResolvedValueOnce([]);
      await service.findPublicCourses();
      expect(mockPrismaService.course.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            publicationStatus: PublicationStatus.PUBLISHED,
            isActive: true,
            program: { status: PublicationStatus.PUBLISHED, isPublic: true },
          }),
        }),
      );
    });

    it('does not disclose an unavailable public course by slug', async () => {
      mockPrismaService.course.findFirst.mockResolvedValueOnce(null);
      await expect(service.findPublicCourse('private-course')).rejects.toThrow(
        NotFoundException,
      );
    });
    it('creates a program as private draft regardless of input', async () => {
      mockPrismaService.trainingProgram.findFirst.mockResolvedValueOnce(null);
      mockPrismaService.trainingProgram.create.mockResolvedValueOnce({
        id: 'program-1',
      });
      await service.createProgram({
        code: 'PRG-NEW',
        slug: 'new-program',
        nameVi: 'Mới',
        nameEn: 'New',
        category: 'GENERAL',
      });
      expect(mockPrismaService.trainingProgram.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          status: PublicationStatus.DRAFT,
          isPublic: false,
        }),
      });
    });

    it('rejects public visibility before program approval', async () => {
      mockPrismaService.trainingProgram.findUnique.mockResolvedValueOnce({
        id: 'program-1',
        status: PublicationStatus.DRAFT,
        courses: [],
      });
      await expect(
        service.setProgramVisibility('program-1', true),
      ).rejects.toThrow(BadRequestException);
      expect(mockPrismaService.trainingProgram.update).not.toHaveBeenCalled();
    });

    it('requires review transition and academic description before program approval', async () => {
      mockPrismaService.trainingProgram.findUnique.mockResolvedValueOnce({
        id: 'program-1',
        status: PublicationStatus.DRAFT,
        courses: [],
      });
      await expect(
        service.changeProgramStatus('program-1', PublicationStatus.PUBLISHED),
      ).rejects.toThrow(BadRequestException);
      mockPrismaService.trainingProgram.findUnique.mockResolvedValueOnce({
        id: 'program-1',
        status: PublicationStatus.IN_REVIEW,
        description: '',
        targetAudience: 'Người học',
        courses: [],
      });
      await expect(
        service.changeProgramStatus('program-1', PublicationStatus.PUBLISHED),
      ).rejects.toThrow(BadRequestException);
    });

    it('blocks draft course publication without an approved program', async () => {
      mockPrismaService.course.findUnique.mockResolvedValue({
        id: 'course-1',
        publicationStatus: PublicationStatus.IN_REVIEW,
        programId: 'program-1',
        isActive: true,
        description: 'Mô tả',
        publicDescription: 'Mô tả công khai',
        levels: [
          {
            modules: [{ lessons: [{ id: 'lesson-1' }] }],
            _count: { classes: 0 },
          },
        ],
      });
      mockPrismaService.trainingProgram.findUnique.mockResolvedValueOnce({
        status: PublicationStatus.DRAFT,
      });
      await expect(
        service.changeCourseStatus('course-1', PublicationStatus.PUBLISHED),
      ).rejects.toThrow(BadRequestException);
      expect(mockPrismaService.course.update).not.toHaveBeenCalled();
    });

    it('publishes a reviewed course with approved program and lessons', async () => {
      const course = {
        id: 'course-1',
        publicationStatus: PublicationStatus.IN_REVIEW,
        programId: 'program-1',
        isActive: true,
        slug: 'reviewed-course',
        description: 'Mô tả',
        publicDescription: 'Mô tả công khai',
        targetAudience: 'Người học',
        academicProfile: { reviewRequired: true },
        levels: [
          {
            code: 'A1',
            entryRequirements: 'Đầu vào',
            expectedOutcomes: ['A1'],
            assessmentScheme: { test: 100 },
            completionCriteria: 'Đạt',
            modules: [
              {
                lessons: [
                  {
                    id: 'lesson-1',
                    title: 'Bài 1',
                    content: 'Nội dung',
                    materials: [],
                  },
                ],
              },
            ],
            _count: { classes: 0 },
          },
        ],
      };
      mockPrismaService.course.findUnique.mockResolvedValue(course);
      mockPrismaService.trainingProgram.findUnique.mockResolvedValue({
        status: PublicationStatus.PUBLISHED,
        isPublic: true,
      });
      mockPrismaService.course.update.mockImplementation(async ({ data }) => {
        Object.assign(course, data);
        return course;
      });
      const beforeReview = await service.validateCoursePublication('course-1');
      expect(beforeReview.canPublish).toBe(false);
      expect(beforeReview.canConfirmReview).toBe(true);
      await service.confirmCourseAcademicReview('course-1', 'academic-1');
      const afterReview = await service.validateCoursePublication('course-1');
      expect(afterReview.canPublish).toBe(true);
      course.levels[0].modules[0].lessons[0].title = 'Bài đã sửa';
      expect(
        (await service.validateCoursePublication('course-1')).canPublish,
      ).toBe(false);
      course.levels[0].modules[0].lessons[0].title = 'Bài 1';
      mockPrismaService.course.update.mockResolvedValueOnce({
        publicationStatus: PublicationStatus.PUBLISHED,
      });
      await service.changeCourseStatus('course-1', PublicationStatus.PUBLISHED);
      expect(mockPrismaService.course.update).toHaveBeenCalledWith({
        where: { id: 'course-1' },
        data: { publicationStatus: PublicationStatus.PUBLISHED },
      });
    });

    it('blocks publication when an academic review is missing', async () => {
      mockPrismaService.course.findUnique.mockResolvedValue({
        publicationStatus: PublicationStatus.IN_REVIEW,
        programId: 'program-1',
        isActive: true,
        slug: 'a1',
        description: 'Mô tả',
        publicDescription: 'Mô tả công khai',
        targetAudience: 'Người học',
        academicProfile: { reviewRequired: true },
        levels: [
          {
            code: 'A1',
            entryRequirements: 'Đầu vào',
            expectedOutcomes: ['A1'],
            assessmentScheme: { test: 100 },
            completionCriteria: 'Đạt',
            modules: [{ lessons: [{ content: 'Nội dung', materials: [] }] }],
          },
        ],
      });
      mockPrismaService.trainingProgram.findUnique.mockResolvedValue({
        status: PublicationStatus.PUBLISHED,
        isPublic: true,
      });
      await expect(
        service.changeCourseStatus('course-1', PublicationStatus.PUBLISHED),
      ).rejects.toThrow(BadRequestException);
      expect(mockPrismaService.course.update).not.toHaveBeenCalled();
    });

    it('blocks unpublishing while a class is open', async () => {
      mockPrismaService.course.findUnique.mockResolvedValueOnce({
        id: 'course-1',
        publicationStatus: PublicationStatus.PUBLISHED,
        levels: [],
      });
      mockPrismaService.class.count.mockResolvedValueOnce(1);
      await expect(
        service.changeCourseStatus('course-1', PublicationStatus.DRAFT),
      ).rejects.toThrow(ConflictException);
      expect(mockPrismaService.course.update).not.toHaveBeenCalled();
    });

    it('unpublishes a course without open or running classes', async () => {
      mockPrismaService.course.findUnique.mockResolvedValueOnce({
        id: 'course-1',
        publicationStatus: PublicationStatus.PUBLISHED,
        levels: [],
      });
      await service.changeCourseStatus('course-1', PublicationStatus.DRAFT);
      expect(mockPrismaService.course.update).toHaveBeenCalledWith({
        where: { id: 'course-1' },
        data: { publicationStatus: PublicationStatus.DRAFT },
      });
    });
  });

  describe('academic level editing', () => {
    it('updates a draft level without replacing the related course', async () => {
      mockPrismaService.courseLevel.findUnique.mockResolvedValueOnce({
        id: 'level-1',
        courseId: 'course-1',
        code: 'CORE',
        course: { publicationStatus: PublicationStatus.DRAFT },
      });
      mockPrismaService.courseLevel.update.mockResolvedValueOnce({
        id: 'level-1',
        cefrLevel: 'B1',
      });
      await service.updateLevel('level-1', {
        cefrLevel: 'B1',
        recommendedHours: 60,
      });
      expect(mockPrismaService.courseLevel.update).toHaveBeenCalledWith({
        where: { id: 'level-1' },
        data: { cefrLevel: 'B1', recommendedHours: 60 },
      });
    });

    it('rejects editing a level in an archived course', async () => {
      mockPrismaService.courseLevel.findUnique.mockResolvedValueOnce({
        id: 'level-1',
        code: 'CORE',
        course: { publicationStatus: PublicationStatus.ARCHIVED },
      });
      await expect(
        service.updateLevel('level-1', { name: 'Đổi tên' }),
      ).rejects.toThrow(BadRequestException);
    });
  });
});
