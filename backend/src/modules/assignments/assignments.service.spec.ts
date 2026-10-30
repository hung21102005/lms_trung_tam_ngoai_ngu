import { describe, it, expect, vi, beforeEach } from 'vitest';
import { AssignmentsService } from './assignments.service.js';
import {
  AssignmentStatus,
  AssignmentType,
  SubmissionStatus,
} from '@prisma/client';
import {
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';

describe('AssignmentsService', () => {
  let service: AssignmentsService;
  let prismaMock: any;

  beforeEach(() => {
    prismaMock = {
      class: {
        findUnique: vi.fn(),
      },
      parentStudent: { findFirst: vi.fn() },
      assignment: {
        findMany: vi.fn(),
        create: vi.fn(),
        findUnique: vi.fn(),
      },
      submission: {
        upsert: vi.fn(),
        findUnique: vi.fn(),
        update: vi.fn(),
        create: vi.fn(),
        updateMany: vi.fn(),
      },
    };

    service = new AssignmentsService(prismaMock);
  });

  describe('createAssignment', () => {
    it('should create an assignment for a class', async () => {
      prismaMock.class.findUnique.mockResolvedValue({
        id: 'class-1',
        name: 'IELTS Band 6.5',
        mainTeacherId: 'teacher-1',
      });
      prismaMock.assignment.create.mockResolvedValue({
        id: 'assign-1',
        title: 'Writing Task 2',
        maxScore: 10,
        type: AssignmentType.WRITING,
      });

      const result = await service.createAssignment(
        'class-1',
        {
          title: 'Writing Task 2',
          type: AssignmentType.WRITING,
          maxScore: 10,
        },
        { id: 'teacher-1', roles: ['teacher'] },
      );

      expect(result.id).toBe('assign-1');
      expect(prismaMock.assignment.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            classId: 'class-1',
            createdById: 'teacher-1',
            title: 'Writing Task 2',
          }),
        }),
      );
    });

    it('should throw NotFoundException if class does not exist', async () => {
      prismaMock.class.findUnique.mockResolvedValue(null);
      await expect(
        service.createAssignment(
          'invalid-class',
          { title: 'Test' },
          { id: 'teacher-1', roles: ['teacher'] },
        ),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('class access', () => {
    it('blocks a teacher from another class', async () => {
      prismaMock.class.findUnique.mockResolvedValue({
        id: 'class-1',
        mainTeacherId: 'teacher-1',
        students: [],
      });
      await expect(
        service.createAssignment(
          'class-1',
          { title: 'Bài tập' },
          { id: 'teacher-2', roles: ['teacher'] },
        ),
      ).rejects.toThrow(ForbiddenException);
      expect(prismaMock.assignment.create).not.toHaveBeenCalled();
    });

    it('allows a parent to see assignments only for an enrolled child', async () => {
      prismaMock.class.findUnique.mockResolvedValue({
        id: 'class-1',
        students: [{ studentId: 'student-1' }],
      });
      prismaMock.parentStudent.findFirst.mockResolvedValue({
        id: 'relation-1',
      });
      prismaMock.assignment.findMany.mockResolvedValue([]);
      await expect(
        service.getClassAssignments('class-1', {
          id: 'parent-1',
          roles: ['parent'],
        }),
      ).resolves.toEqual([]);
      expect(prismaMock.parentStudent.findFirst).toHaveBeenCalledWith({
        where: { parentId: 'parent-1', studentId: { in: ['student-1'] } },
      });
    });
  });

  describe('submitAssignment', () => {
    it('rejects an empty submission', async () => {
      await expect(
        service.submitAssignment('assign-1', 'student-1', {}),
      ).rejects.toThrow(BadRequestException);
    });

    it('does not overwrite a graded submission', async () => {
      prismaMock.assignment.findUnique.mockResolvedValue({
        id: 'assign-1',
        status: AssignmentStatus.PUBLISHED,
        deadline: null,
        class: { students: [{ studentId: 'student-1' }] },
      });
      prismaMock.submission.findUnique.mockResolvedValue({
        status: SubmissionStatus.GRADED,
      });
      await expect(
        service.submitAssignment('assign-1', 'student-1', {
          content: 'Sửa bài',
        }),
      ).rejects.toThrow(BadRequestException);
      expect(prismaMock.submission.upsert).not.toHaveBeenCalled();
    });

    it('does not overwrite a submitted assignment after its deadline', async () => {
      prismaMock.assignment.findUnique.mockResolvedValue({
        id: 'assign-1',
        status: AssignmentStatus.PUBLISHED,
        deadline: new Date(Date.now() - 86400000),
        class: { students: [{ studentId: 'student-1' }] },
      });
      prismaMock.submission.findUnique.mockResolvedValue({
        id: 'sub-1',
        status: SubmissionStatus.SUBMITTED,
      });

      await expect(
        service.submitAssignment('assign-1', 'student-1', {
          content: 'Sửa bài sau hạn',
        }),
      ).rejects.toThrow('Đã hết hạn nộp');
      expect(prismaMock.submission.upsert).not.toHaveBeenCalled();
    });

    it('should submit on-time and set status to SUBMITTED', async () => {
      const futureDeadline = new Date(Date.now() + 86400000); // Ngày mai
      prismaMock.assignment.findUnique.mockResolvedValue({
        id: 'assign-1',
        status: AssignmentStatus.PUBLISHED,
        deadline: futureDeadline,
        class: {
          students: [{ studentId: 'student-1', status: 'ENROLLED' }],
        },
      });

      prismaMock.submission.upsert.mockResolvedValue({
        id: 'sub-1',
        status: SubmissionStatus.SUBMITTED,
        content: 'My essay content',
      });

      const result = await service.submitAssignment('assign-1', 'student-1', {
        content: 'My essay content',
      });

      expect(result.status).toBe(SubmissionStatus.SUBMITTED);
      expect(prismaMock.submission.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          create: expect.objectContaining({
            status: SubmissionStatus.SUBMITTED,
          }),
        }),
      );
    });

    it('should mark submission as LATE if submitted after deadline', async () => {
      const pastDeadline = new Date(Date.now() - 86400000); // Hôm qua
      prismaMock.assignment.findUnique.mockResolvedValue({
        id: 'assign-1',
        status: AssignmentStatus.PUBLISHED,
        deadline: pastDeadline,
        class: {
          students: [{ studentId: 'student-1', status: 'ENROLLED' }],
        },
      });

      prismaMock.submission.upsert.mockResolvedValue({
        id: 'sub-1',
        status: SubmissionStatus.LATE,
        content: 'Late essay',
      });

      const result = await service.submitAssignment('assign-1', 'student-1', {
        content: 'Late essay',
      });

      expect(result.status).toBe(SubmissionStatus.LATE);
      expect(prismaMock.submission.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          create: expect.objectContaining({
            status: SubmissionStatus.LATE,
          }),
        }),
      );
    });

    it('should throw ForbiddenException if student is not enrolled in class', async () => {
      prismaMock.assignment.findUnique.mockResolvedValue({
        id: 'assign-1',
        status: AssignmentStatus.PUBLISHED,
        deadline: null,
        class: {
          students: [], // Not enrolled
        },
      });

      await expect(
        service.submitAssignment('assign-1', 'student-outside', {
          content: 'test',
        }),
      ).rejects.toThrow(ForbiddenException);
    });
  });

  describe('gradeSubmission', () => {
    it('should update submission score and feedback', async () => {
      prismaMock.submission.findUnique.mockResolvedValue({
        id: 'sub-1',
        assignment: { maxScore: 10, class: { mainTeacherId: 'teacher-1' } },
      });

      prismaMock.submission.update.mockResolvedValue({
        id: 'sub-1',
        score: 8.5,
        feedback: 'Rất tốt',
        status: SubmissionStatus.GRADED,
      });

      const result = await service.gradeSubmission(
        'sub-1',
        { score: 8.5, feedback: 'Rất tốt' },
        { id: 'teacher-1', roles: ['teacher'] },
      );

      expect(result.score).toBe(8.5);
      expect(result.status).toBe(SubmissionStatus.GRADED);
    });

    it('should throw BadRequestException if score exceeds maxScore', async () => {
      prismaMock.submission.findUnique.mockResolvedValue({
        id: 'sub-1',
        assignment: { maxScore: 10, class: { mainTeacherId: 'teacher-1' } },
      });

      await expect(
        service.gradeSubmission(
          'sub-1',
          { score: 11 },
          { id: 'teacher-1', roles: ['teacher'] },
        ),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('drafts and result visibility', () => {
    it('shows only published assignments and hides unpublished scores from students', async () => {
      prismaMock.class.findUnique.mockResolvedValue({
        id: 'class-1',
        students: [{ studentId: 'student-1' }],
      });
      prismaMock.assignment.findMany.mockResolvedValue([
        {
          id: 'assignment-1',
          classId: 'class-1',
          status: AssignmentStatus.PUBLISHED,
          title: 'Writing',
          type: AssignmentType.WRITING,
          submissions: [
            {
              id: 'sub-1',
              assignmentId: 'assignment-1',
              studentId: 'student-1',
              status: SubmissionStatus.GRADED,
              score: 9,
              feedback: 'Giỏi',
              resultPublishedAt: null,
              fileUrls: [],
            },
          ],
        },
      ]);
      const result = await service.getClassAssignments('class-1', {
        id: 'student-1',
        roles: ['student'],
      });
      expect(prismaMock.assignment.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { classId: 'class-1', status: AssignmentStatus.PUBLISHED },
        }),
      );
      expect(result[0].mySubmission?.status).toBe('GRADED_PENDING');
      expect(result[0].mySubmission?.score).toBeNull();
      expect(result[0].mySubmission?.feedback).toBeNull();
      expect(result[0].stats).toBeUndefined();
    });

    it('saves a draft without marking it submitted', async () => {
      prismaMock.assignment.findUnique.mockResolvedValue({
        id: 'assignment-1',
        status: AssignmentStatus.PUBLISHED,
        deadline: null,
        class: { students: [{ studentId: 'student-1' }] },
      });
      prismaMock.submission.findUnique.mockResolvedValue(null);
      prismaMock.submission.create.mockResolvedValue({
        status: SubmissionStatus.DRAFT,
      });
      await service.saveDraft('assignment-1', 'student-1', {
        content: 'Đang viết',
      });
      expect(prismaMock.submission.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          status: SubmissionStatus.DRAFT,
          submittedAt: null,
          content: 'Đang viết',
        }),
      });
    });

    it('restores only the enrolled learner draft in assignment detail', async () => {
      prismaMock.assignment.findUnique.mockResolvedValue({
        id: 'assignment-1',
        classId: 'class-1',
        status: AssignmentStatus.PUBLISHED,
        title: 'Writing',
        type: AssignmentType.WRITING,
        submissions: [
          {
            id: 'draft-1',
            assignmentId: 'assignment-1',
            studentId: 'student-1',
            status: SubmissionStatus.DRAFT,
            content: 'Đoạn đang viết',
            fileUrls: [],
            submittedAt: null,
          },
        ],
        class: {
          name: 'Lớp A',
          code: 'A',
          course: { title: 'IELTS' },
          students: [{ studentId: 'student-1' }],
        },
      });
      const result = await service.getAssignmentDetail('assignment-1', {
        id: 'student-1',
        roles: ['student'],
      });
      expect(result.mySubmission?.content).toBe('Đoạn đang viết');
      expect(result.mySubmission?.status).toBe(SubmissionStatus.DRAFT);
      expect(result.mySubmission?.submittedAt).toBeNull();
      expect(result.stats).toBeUndefined();
      expect(result.assignment.courseName).toBe('IELTS');
    });

    it('rejects viewing an unpublished assignment by a learner', async () => {
      prismaMock.assignment.findUnique.mockResolvedValue({
        id: 'assignment-1',
        status: AssignmentStatus.DRAFT,
        class: { students: [{ studentId: 'student-1' }] },
      });
      await expect(
        service.getAssignmentDetail('assignment-1', {
          id: 'student-1',
          roles: ['student'],
        }),
      ).rejects.toThrow(NotFoundException);
    });

    it('does not let a draft overwrite an already submitted answer', async () => {
      prismaMock.assignment.findUnique.mockResolvedValue({
        id: 'assignment-1',
        status: AssignmentStatus.PUBLISHED,
        deadline: null,
        class: { students: [{ studentId: 'student-1' }] },
      });
      prismaMock.submission.findUnique.mockResolvedValue({
        status: SubmissionStatus.SUBMITTED,
      });
      await expect(
        service.saveDraft('assignment-1', 'student-1', {}),
      ).rejects.toThrow('Bài đã nộp');
    });

    it('stores a new grade privately until explicit publication', async () => {
      prismaMock.submission.findUnique.mockResolvedValue({
        id: 'sub-1',
        status: SubmissionStatus.SUBMITTED,
        assignment: { maxScore: 10, class: { mainTeacherId: 'teacher-1' } },
      });
      prismaMock.submission.update.mockResolvedValue({ id: 'sub-1' });
      const teacher = { id: 'teacher-1', roles: ['teacher'] };
      await service.gradeSubmission('sub-1', { score: 8 }, teacher);
      expect(prismaMock.submission.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ resultPublishedAt: null }),
        }),
      );
      prismaMock.submission.findUnique.mockResolvedValue({
        id: 'sub-1',
        status: SubmissionStatus.GRADED,
        score: 8,
        assignment: { class: { mainTeacherId: 'teacher-1' } },
      });
      await service.publishResult('sub-1', teacher);
      expect(prismaMock.submission.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: { resultPublishedAt: expect.any(Date) },
        }),
      );
    });

    it('returns an ungraded submission for revision without exposing a score', async () => {
      prismaMock.submission.findUnique.mockResolvedValue({
        id: 'sub-1',
        status: SubmissionStatus.SUBMITTED,
        assignment: { class: { mainTeacherId: 'teacher-1' } },
      });
      prismaMock.submission.update.mockResolvedValue({
        status: SubmissionStatus.RETURNED,
      });
      await service.returnSubmission(
        'sub-1',
        { feedback: 'Viết lại mở bài' },
        {
          id: 'teacher-1',
          roles: ['teacher'],
        },
      );
      expect(prismaMock.submission.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            status: SubmissionStatus.RETURNED,
            feedback: 'Viết lại mở bài',
            score: null,
          }),
        }),
      );
    });
  });
});
