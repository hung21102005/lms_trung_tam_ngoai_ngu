import { Test, TestingModule } from '@nestjs/testing';
import { ClassesService } from './classes.service.js';
import { PrismaService } from '../../database/index.js';
import {
  ConflictException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { ClassStatus, EnrollmentStatus, UserStatus } from '@prisma/client';

describe('ClassesService', () => {
  let service: ClassesService;
  const adminActor = { id: 'admin-1', roles: ['super_admin'] };

  const mockCourse = { id: 'course-1', code: 'ENG-IELTS', title: 'IELTS' };
  const mockLevel = {
    id: 'level-1',
    courseId: 'course-1',
    code: 'F',
    name: 'Foundation',
    estimatedSessions: 4,
    tuitionFee: 5000000,
  };
  const mockBranch = { id: 'branch-1', code: 'BR-Q1', name: 'Chi nhánh Q1' };
  const mockRoom = {
    id: 'room-1',
    branchId: 'branch-1',
    code: 'P101',
    name: 'Phòng 101',
    capacity: 25,
    isActive: true,
  };
  const mockTeacher = {
    id: 'teacher-1',
    fullName: 'Cô Lan',
    userCode: 'GV-001',
  };

  const mockClass = {
    id: 'class-1',
    code: 'IELTS-F-01',
    name: 'Lớp IELTS Foundation 01',
    courseId: 'course-1',
    levelId: 'level-1',
    branchId: 'branch-1',
    roomId: 'room-1',
    mainTeacherId: 'teacher-1',
    status: ClassStatus.IN_PROGRESS,
    startDate: new Date('2026-11-02'),
    endDate: new Date('2026-11-09'),
    scheduleDays: ['MONDAY', 'WEDNESDAY'],
    startTime: '18:00',
    endTime: '19:30',
    totalSessions: 4,
    maxCapacity: 20,
    tuitionFee: 5000000,
  };

  const mockPrismaService = {
    class: {
      findMany: vi.fn(),
      count: vi.fn(),
      findUnique: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
    },
    course: { findUnique: vi.fn() },
    courseLevel: { findUnique: vi.fn() },
    branch: { findUnique: vi.fn() },
    room: { findUnique: vi.fn() },
    user: { findUnique: vi.fn(), findFirst: vi.fn() },
    lesson: { findMany: vi.fn() },
    classSession: {
      findMany: vi.fn(),
      findFirst: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
      findUnique: vi.fn(),
    },
    classStudent: {
      findUnique: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
      delete: vi.fn(),
    },
    parentStudent: {
      findMany: vi.fn(),
      findFirst: vi.fn(),
    },
    $transaction: vi.fn((callback) => callback(mockPrismaService)),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ClassesService,
        { provide: PrismaService, useValue: mockPrismaService },
      ],
    }).compile();

    service = module.get<ClassesService>(ClassesService);
    vi.clearAllMocks();
    mockPrismaService.room.findUnique.mockResolvedValue(mockRoom);
    mockPrismaService.user.findFirst.mockResolvedValue(mockTeacher);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('prevents an assigned teacher from changing the official timetable', async () => {
    mockPrismaService.classSession.findUnique.mockResolvedValue({
      id: 'session-1',
      teacherId: 'teacher-1',
      class: mockClass,
      date: new Date('2026-11-02'),
      startTime: '18:00',
      endTime: '19:30',
    });
    await expect(
      service.updateSession(
        'session-1',
        { startTime: '19:00' },
        { id: 'teacher-1', roles: ['teacher'] },
      ),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(mockPrismaService.classSession.update).not.toHaveBeenCalled();
  });

  describe('create class & auto-generate sessions', () => {
    const baseCreate = {
      code: 'NEW-CLASS-01',
      name: 'Lớp mới',
      courseId: 'course-1',
      levelId: 'level-1',
      branchId: 'branch-1',
      startDate: '2026-11-02',
      scheduleDays: ['MONDAY'],
      startTime: '18:00',
      endTime: '19:30',
    };

    async function prepareCatalog() {
      mockPrismaService.class.findUnique.mockResolvedValueOnce(null);
      mockPrismaService.course.findUnique.mockResolvedValueOnce(mockCourse);
      mockPrismaService.courseLevel.findUnique.mockResolvedValueOnce(mockLevel);
      mockPrismaService.branch.findUnique.mockResolvedValueOnce(mockBranch);
    }

    it('rejects a room from another branch', async () => {
      await prepareCatalog();
      mockPrismaService.room.findUnique.mockResolvedValueOnce({
        ...mockRoom,
        branchId: 'branch-2',
      });
      await expect(
        service.create({ ...baseCreate, roomId: 'room-1' }, adminActor),
      ).rejects.toThrow('Phòng học không thuộc chi nhánh');
      expect(mockPrismaService.class.create).not.toHaveBeenCalled();
    });

    it.each([
      [{ ...mockRoom, isActive: false }, 'ngừng hoạt động'],
      [{ ...mockRoom, capacity: 10 }, 'vượt quá sức chứa'],
    ])('rejects an unavailable room', async (room, message) => {
      await prepareCatalog();
      mockPrismaService.room.findUnique.mockResolvedValueOnce(room);
      await expect(
        service.create({ ...baseCreate, roomId: 'room-1' }, adminActor),
      ).rejects.toThrow(message);
    });

    it('rejects a teacher that does not belong to the active branch teacher lookup', async () => {
      await prepareCatalog();
      mockPrismaService.user.findFirst.mockResolvedValueOnce(null);
      await expect(
        service.create(
          { ...baseCreate, mainTeacherId: 'teacher-2' },
          adminActor,
        ),
      ).rejects.toThrow('Giáo viên được chọn không hoạt động');
      expect(mockPrismaService.user.findFirst).toHaveBeenCalledWith({
        where: {
          id: 'teacher-2',
          branchId: 'branch-1',
          status: UserStatus.ACTIVE,
          userRoles: { some: { role: { code: 'teacher' } } },
        },
        select: { id: true },
      });
    });

    it('rejects the same account as teacher and assistant', async () => {
      await prepareCatalog();
      await expect(
        service.create(
          {
            ...baseCreate,
            mainTeacherId: 'teacher-1',
            assistantTeacherId: 'teacher-1',
          },
          adminActor,
        ),
      ).rejects.toThrow('phải khác nhau');
    });

    it.each([
      [{ ...baseCreate, startTime: '19:30' }, 'Giờ kết thúc phải sau'],
      [{ ...baseCreate, scheduleDays: [] }, 'ít nhất một ngày học'],
      [
        { ...baseCreate, scheduleDays: ['MONDAY', 'monday'] },
        'không được trùng lặp',
      ],
      [{ ...baseCreate, registrationOpenAt: '2026-10-31' }, 'Cần nhập đủ ngày'],
      [
        {
          ...baseCreate,
          registrationOpenAt: '2026-11-01',
          registrationCloseAt: '2026-10-31',
        },
        'Ngày mở đăng ký',
      ],
      [
        {
          ...baseCreate,
          registrationOpenAt: '2026-10-31',
          registrationCloseAt: '2026-11-03',
        },
        'không được sau ngày khai giảng',
      ],
    ])('rejects invalid class schedule', async (dto, message) => {
      await prepareCatalog();
      await expect(service.create(dto, adminActor)).rejects.toThrow(message);
      expect(mockPrismaService.class.create).not.toHaveBeenCalled();
    });

    it('rejects a level from a different course', async () => {
      mockPrismaService.class.findUnique.mockResolvedValueOnce(null);
      mockPrismaService.course.findUnique.mockResolvedValueOnce(mockCourse);
      mockPrismaService.courseLevel.findUnique.mockResolvedValueOnce({
        ...mockLevel,
        courseId: 'other-course',
      });
      mockPrismaService.branch.findUnique.mockResolvedValueOnce(mockBranch);
      await expect(service.create(baseCreate, adminActor)).rejects.toThrow(
        'Cấp độ không thuộc khóa học',
      );
      expect(mockPrismaService.class.create).not.toHaveBeenCalled();
    });

    it('does not open a class from a draft catalog course', async () => {
      mockPrismaService.class.findUnique.mockResolvedValueOnce(null);
      mockPrismaService.course.findUnique.mockResolvedValueOnce({
        ...mockCourse,
        isActive: false,
        publicationStatus: 'DRAFT',
      });
      mockPrismaService.courseLevel.findUnique.mockResolvedValueOnce(mockLevel);
      mockPrismaService.branch.findUnique.mockResolvedValueOnce(mockBranch);
      await expect(service.create(baseCreate, adminActor)).rejects.toThrow(
        'Khóa học chưa được duyệt',
      );
      expect(mockPrismaService.class.create).not.toHaveBeenCalled();
    });

    it('rejects class creation outside the staff branch', async () => {
      await expect(
        service.create(
          {
            code: 'OTHER-01',
            name: 'Lớp khác chi nhánh',
            courseId: 'course-1',
            levelId: 'level-1',
            branchId: 'branch-2',
            startDate: '2026-11-02',
            scheduleDays: ['MONDAY'],
            startTime: '18:00',
            endTime: '19:30',
          },
          { id: 'staff-1', roles: ['academic_staff'], branchId: 'branch-1' },
        ),
      ).rejects.toThrow(ForbiddenException);
      expect(mockPrismaService.class.create).not.toHaveBeenCalled();
    });

    it('should throw ConflictException if class code already exists', async () => {
      mockPrismaService.class.findUnique.mockResolvedValueOnce(mockClass);

      await expect(
        service.create(
          {
            code: 'IELTS-F-01',
            name: 'Lớp IELTS',
            courseId: 'course-1',
            levelId: 'level-1',
            branchId: 'branch-1',
            startDate: '2026-11-02',
            scheduleDays: ['MONDAY', 'WEDNESDAY'],
            startTime: '18:00',
            endTime: '19:30',
          },
          adminActor,
        ),
      ).rejects.toThrow(ConflictException);
    });

    it('should throw BadRequestException if scheduleDay is invalid', async () => {
      mockPrismaService.class.findUnique.mockResolvedValueOnce(null);
      mockPrismaService.course.findUnique.mockResolvedValueOnce(mockCourse);
      mockPrismaService.courseLevel.findUnique.mockResolvedValueOnce(mockLevel);
      mockPrismaService.branch.findUnique.mockResolvedValueOnce(mockBranch);

      await expect(
        service.create(
          {
            code: 'IELTS-F-02',
            name: 'Lớp IELTS',
            courseId: 'course-1',
            levelId: 'level-1',
            branchId: 'branch-1',
            startDate: '2026-11-02',
            scheduleDays: ['INVALID_DAY'],
            startTime: '18:00',
            endTime: '19:30',
          },
          adminActor,
        ),
      ).rejects.toThrow(BadRequestException);
    });

    it('should throw ConflictException if room has a schedule conflict', async () => {
      mockPrismaService.class.findUnique.mockResolvedValueOnce(null);
      mockPrismaService.course.findUnique.mockResolvedValueOnce(mockCourse);
      mockPrismaService.courseLevel.findUnique.mockResolvedValueOnce(mockLevel);
      mockPrismaService.branch.findUnique.mockResolvedValueOnce(mockBranch);

      // Giả lập phòng bị trùng vào buổi đầu tiên
      mockPrismaService.classSession.findFirst.mockResolvedValueOnce({
        id: 'session-conflict',
        class: { code: 'OTHER-01', name: 'Lớp Trùng' },
        room: { code: 'P101', name: 'Phòng 101' },
        startTime: '17:30',
        endTime: '19:00',
      });

      await expect(
        service.create(
          {
            code: 'IELTS-F-03',
            name: 'Lớp IELTS',
            courseId: 'course-1',
            levelId: 'level-1',
            branchId: 'branch-1',
            roomId: 'room-1',
            startDate: '2026-11-02',
            scheduleDays: ['MONDAY', 'WEDNESDAY'],
            startTime: '18:00',
            endTime: '19:30',
            totalSessions: 4,
          },
          adminActor,
        ),
      ).rejects.toThrow(ConflictException);
    });

    it('should throw ConflictException if mainTeacher has a schedule conflict', async () => {
      mockPrismaService.class.findUnique.mockResolvedValueOnce(null);
      mockPrismaService.course.findUnique.mockResolvedValueOnce(mockCourse);
      mockPrismaService.courseLevel.findUnique.mockResolvedValueOnce(mockLevel);
      mockPrismaService.branch.findUnique.mockResolvedValueOnce(mockBranch);

      // Không trùng phòng
      mockPrismaService.classSession.findFirst
        .mockResolvedValueOnce(null) // room check 1
        .mockResolvedValueOnce({
          // teacher check 1
          id: 'teacher-conflict',
          class: { code: 'OTHER-02', name: 'Lớp Đang Dạy' },
          teacher: { fullName: 'Cô Lan' },
          startTime: '18:00',
          endTime: '19:30',
        });

      await expect(
        service.create(
          {
            code: 'IELTS-F-04',
            name: 'Lớp IELTS',
            courseId: 'course-1',
            levelId: 'level-1',
            branchId: 'branch-1',
            roomId: 'room-1',
            mainTeacherId: 'teacher-1',
            startDate: '2026-11-02',
            scheduleDays: ['MONDAY', 'WEDNESDAY'],
            startTime: '18:00',
            endTime: '19:30',
            totalSessions: 4,
          },
          adminActor,
        ),
      ).rejects.toThrow(ConflictException);
    });

    it('should create class and generate correct sessions when no conflict', async () => {
      mockPrismaService.class.findUnique
        .mockResolvedValueOnce(null) // check code
        .mockResolvedValueOnce(mockClass); // final findUnique in tx
      mockPrismaService.course.findUnique.mockResolvedValueOnce(mockCourse);
      mockPrismaService.courseLevel.findUnique.mockResolvedValueOnce(mockLevel);
      mockPrismaService.branch.findUnique.mockResolvedValueOnce(mockBranch);
      mockPrismaService.classSession.findFirst.mockResolvedValue(null); // No conflicts
      mockPrismaService.lesson.findMany.mockResolvedValueOnce([
        { id: 'les-1', title: 'Lesson 1' },
        { id: 'les-2', title: 'Lesson 2' },
      ]);
      mockPrismaService.class.create.mockResolvedValueOnce(mockClass);

      const result = await service.create(
        {
          code: 'IELTS-F-01',
          name: 'Lớp IELTS Foundation 01',
          courseId: 'course-1',
          levelId: 'level-1',
          branchId: 'branch-1',
          roomId: 'room-1',
          mainTeacherId: 'teacher-1',
          startDate: '2026-11-02',
          scheduleDays: ['MONDAY', 'WEDNESDAY'],
          startTime: '18:00',
          endTime: '19:30',
          totalSessions: 4,
          registrationOpenAt: '2026-10-01',
          registrationCloseAt: '2026-10-31',
        },
        adminActor,
      );

      expect(result).toBeDefined();
      expect(mockPrismaService.classSession.create).toHaveBeenCalledTimes(4);
      expect(mockPrismaService.classSession.findFirst).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            date: new Date('2026-11-02T00:00:00.000Z'),
          }),
        }),
      );
      expect(mockPrismaService.class.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            registrationOpenAt: new Date('2026-10-01'),
            registrationCloseAt: new Date('2026-10-31'),
          }),
        }),
      );
    });
  });

  describe('enrollStudent', () => {
    it('should throw ConflictException if class reached max capacity', async () => {
      mockPrismaService.class.findUnique.mockResolvedValueOnce({
        id: 'class-1',
        maxCapacity: 20,
        _count: { students: 20 },
      });
      mockPrismaService.user.findFirst.mockResolvedValueOnce({
        id: 'student-1',
        status: 'ACTIVE',
        userRoles: [{ role: { code: 'student' } }],
      });
      mockPrismaService.classStudent.findUnique.mockResolvedValueOnce(null);

      await expect(
        service.enrollStudent(
          'class-1',
          { studentId: 'student-1' },
          { id: 'admin-1', roles: ['super_admin'] },
        ),
      ).rejects.toThrow(ConflictException);
    });

    it('should enroll student successfully', async () => {
      mockPrismaService.class.findUnique.mockResolvedValueOnce({
        id: 'class-1',
        maxCapacity: 20,
        _count: { students: 15 },
      });
      mockPrismaService.user.findFirst.mockResolvedValueOnce({
        id: 'student-1',
        status: 'ACTIVE',
        userRoles: [{ role: { code: 'student' } }],
      });
      mockPrismaService.classStudent.findUnique.mockResolvedValueOnce(null);
      mockPrismaService.classStudent.create.mockResolvedValueOnce({
        id: 'enroll-1',
        classId: 'class-1',
        studentId: 'student-1',
        status: EnrollmentStatus.ENROLLED,
      });

      const res = await service.enrollStudent(
        'class-1',
        {
          studentId: 'DEMO-HV-01',
        },
        { id: 'admin-1', roles: ['super_admin'] },
      );
      expect(res).toBeDefined();
      expect(mockPrismaService.user.findFirst).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { OR: [{ id: 'DEMO-HV-01' }, { userCode: 'DEMO-HV-01' }] },
        }),
      );
      expect(mockPrismaService.classStudent.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ studentId: 'student-1' }),
        }),
      );
    });

    it('does not enroll an account without the student role', async () => {
      mockPrismaService.class.findUnique.mockResolvedValueOnce({
        id: 'class-1',
        maxCapacity: 20,
        _count: { students: 15 },
      });
      mockPrismaService.user.findFirst.mockResolvedValueOnce({
        id: 'teacher-1',
        status: 'ACTIVE',
        userRoles: [{ role: { code: 'teacher' } }],
      });
      await expect(
        service.enrollStudent(
          'class-1',
          { studentId: 'teacher-1' },
          { id: 'admin-1', roles: ['super_admin'] },
        ),
      ).rejects.toThrow(BadRequestException);
      expect(mockPrismaService.classStudent.create).not.toHaveBeenCalled();
    });

    it('does not let branch staff enroll into a different branch', async () => {
      mockPrismaService.class.findUnique.mockResolvedValueOnce({
        id: 'class-1',
        branchId: 'branch-1',
        maxCapacity: 20,
        _count: { students: 15 },
      });
      await expect(
        service.enrollStudent(
          'class-1',
          { studentId: 'DEMO-HV-01' },
          {
            id: 'staff-2',
            roles: ['academic_staff'],
            branchId: 'branch-2',
          },
        ),
      ).rejects.toThrow(ForbiddenException);
      expect(mockPrismaService.user.findFirst).not.toHaveBeenCalled();
    });
  });

  describe('getMySchedule', () => {
    it('limits branch staff to their assigned branch', async () => {
      mockPrismaService.classSession.findMany.mockResolvedValueOnce([]);

      await service.getMySchedule(
        'staff-1',
        ['academic_staff'],
        '2026-10-01',
        '2026-10-31',
        'branch-1',
      );

      expect(mockPrismaService.classSession.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({ class: { branchId: 'branch-1' } }),
        }),
      );
    });

    it('rejects unassigned branch staff and unsupported roles', async () => {
      await expect(
        service.getMySchedule('staff-1', ['branch_admin']),
      ).rejects.toThrow(ForbiddenException);
      await expect(
        service.getMySchedule('user-1', ['cashier']),
      ).rejects.toThrow(ForbiddenException);
      expect(mockPrismaService.classSession.findMany).not.toHaveBeenCalled();
    });
  });

  describe('removeStudent', () => {
    it('rejects branch staff from deleting a different branch enrollment', async () => {
      mockPrismaService.classStudent.findUnique.mockResolvedValue({
        id: 'enrollment-1',
        class: { branchId: 'branch-1' },
      });
      await expect(
        service.removeStudent('class-1', 'student-1', {
          id: 'staff-2',
          roles: ['academic_staff'],
          branchId: 'branch-2',
        }),
      ).rejects.toThrow(ForbiddenException);
      expect(mockPrismaService.classStudent.delete).not.toHaveBeenCalled();
    });
  });

  describe('class read access', () => {
    it('returns a teaching roster without tuition or contact details', async () => {
      mockPrismaService.class.findUnique.mockResolvedValue({
        ...mockClass,
        students: [
          {
            id: 'enrollment-1',
            classId: 'class-1',
            studentId: 'student-1',
            status: EnrollmentStatus.ENROLLED,
            tuitionPaid: 5000000,
            student: {
              id: 'student-1',
              userCode: 'HV-01',
              fullName: 'Minh Anh',
              email: 'private@example.com',
              phone: '0900000000',
              status: 'ACTIVE',
            },
          },
        ],
      });
      const result = await service.findOne('class-1', {
        id: 'teacher-1',
        roles: ['teacher'],
      });
      expect(result.students[0]).not.toHaveProperty('tuitionPaid');
      expect(result.students[0].student).not.toHaveProperty('email');
      expect(result.students[0].student).not.toHaveProperty('phone');
      expect(result.students[0].student.fullName).toBe('Minh Anh');
    });
    it('combines search and teacher filters with assigned teacher access', async () => {
      mockPrismaService.class.findMany.mockResolvedValue([]);
      mockPrismaService.class.count.mockResolvedValue(0);
      await service.findAll(
        { page: 1, limit: 10, search: 'IELTS', teacherId: 'teacher-2' },
        {
          id: 'teacher-1',
          roles: ['teacher'],
        },
      );
      expect(mockPrismaService.class.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            OR: expect.arrayContaining([
              { code: { contains: 'IELTS', mode: 'insensitive' } },
            ]),
            AND: expect.arrayContaining([
              {
                OR: [
                  { mainTeacherId: 'teacher-2' },
                  { assistantTeacherId: 'teacher-2' },
                ],
              },
              {
                OR: [
                  { mainTeacherId: 'teacher-1' },
                  { assistantTeacherId: 'teacher-1' },
                ],
              },
            ]),
          }),
        }),
      );
    });

    it('prevents a parent from reading an unrelated class roster', async () => {
      mockPrismaService.class.findUnique.mockResolvedValue({
        ...mockClass,
        students: [
          { studentId: 'student-1', status: EnrollmentStatus.ENROLLED },
        ],
      });
      mockPrismaService.parentStudent.findMany.mockResolvedValue([]);
      await expect(
        service.findOne('class-1', { id: 'parent-1', roles: ['parent'] }),
      ).rejects.toThrow(ForbiddenException);
    });
  });
});
