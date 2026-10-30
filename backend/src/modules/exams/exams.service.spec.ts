import { describe, it, expect, vi, beforeEach } from 'vitest';
import { ExamsService } from './exams.service.js';
import { PrismaService } from '../../database/prisma.service.js';
import { AttemptStatus, ExamStatus, QuestionType } from '@prisma/client';

describe('ExamsService', () => {
  let service: ExamsService;
  let prisma: any;

  beforeEach(() => {
    prisma = {
      questionBank: {
        findMany: vi.fn(),
        create: vi.fn(),
        findUnique: vi.fn(),
      },
      question: {
        create: vi.fn(),
        findUnique: vi.fn(),
        update: vi.fn(),
        delete: vi.fn(),
      },
      exam: {
        findMany: vi.fn(),
        create: vi.fn(),
        findUnique: vi.fn(),
      },
      examQuestion: {
        createMany: vi.fn(),
      },
      examAttempt: {
        findFirst: vi.fn(),
        findMany: vi.fn(),
        findUnique: vi.fn(),
        create: vi.fn(),
        update: vi.fn(),
        count: vi.fn(),
      },
      examAnswer: {
        findMany: vi.fn(),
        findUnique: vi.fn(),
        create: vi.fn(),
        update: vi.fn(),
        upsert: vi.fn(),
      },
      $transaction: vi.fn(async (cb) => {
        if (typeof cb === 'function') {
          return cb(prisma);
        }
        return Promise.all(cb);
      }),
    };

    service = new ExamsService(prisma as unknown as PrismaService);
  });

  describe('Question Banks', () => {
    it('should create a question bank', async () => {
      const mockBank = {
        id: 'bank-1',
        title: 'IELTS Bank',
        description: 'Test bank',
        language: 'EN',
        level: 'IELTS',
        createdById: 'teacher-1',
      };
      prisma.questionBank.create.mockResolvedValue(mockBank);

      const result = await service.createQuestionBank('teacher-1', {
        title: 'IELTS Bank',
        description: 'Test bank',
        language: 'EN',
        level: 'IELTS',
      });

      expect(result).toEqual(mockBank);
      expect(prisma.questionBank.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          title: 'IELTS Bank',
          createdById: 'teacher-1',
        }),
      });
    });

    it('should add a question to bank', async () => {
      prisma.questionBank.findUnique.mockResolvedValue({ id: 'bank-1', title: 'IELTS Bank' });
      const mockQuestion = {
        id: 'q-1',
        questionBankId: 'bank-1',
        type: QuestionType.MULTIPLE_CHOICE,
        prompt: 'Choose the correct answer',
        options: [{ id: 'A', text: 'Option A' }, { id: 'B', text: 'Option B' }],
        correctAnswers: ['A'],
        points: 2.0,
      };
      prisma.question.create.mockResolvedValue(mockQuestion);

      const result = await service.addQuestionToBank('bank-1', {
        type: QuestionType.MULTIPLE_CHOICE,
        prompt: 'Choose the correct answer',
        options: [{ id: 'A', text: 'Option A' }, { id: 'B', text: 'Option B' }],
        correctAnswers: ['A'],
        points: 2.0,
      });

      expect(result).toEqual(mockQuestion);
      expect(prisma.question.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          questionBankId: 'bank-1',
          type: QuestionType.MULTIPLE_CHOICE,
          points: 2.0,
        }),
      });
    });
  });

  describe('Exams Creation & Details', () => {
    it('should create an exam with questions', async () => {
      const mockExam = {
        id: 'exam-1',
        title: 'Midterm Test',
        classId: 'class-1',
        durationMinutes: 45,
        totalPoints: 10.0,
        status: ExamStatus.PUBLISHED,
        createdById: 'teacher-1',
      };

      prisma.exam.create.mockResolvedValue(mockExam);
      prisma.examQuestion.createMany.mockResolvedValue({ count: 2 });
      prisma.exam.findUnique.mockResolvedValue({
        ...mockExam,
        examQuestions: [
          { id: 'eq-1', questionId: 'q-1', points: 5.0, question: { id: 'q-1', prompt: 'Q1' } },
          { id: 'eq-2', questionId: 'q-2', points: 5.0, question: { id: 'q-2', prompt: 'Q2' } },
        ],
      });

      const result = await service.createExam('teacher-1', {
        title: 'Midterm Test',
        classId: 'class-1',
        durationMinutes: 45,
        totalPoints: 10.0,
        status: ExamStatus.PUBLISHED,
        questions: [
          { questionId: 'q-1', points: 5.0 },
          { questionId: 'q-2', points: 5.0 },
        ],
      });

      expect(result.id).toBe('exam-1');
      expect(prisma.examQuestion.createMany).toHaveBeenCalled();
    });

    it('should sanitize exam answers when requested by student', async () => {
      prisma.exam.findUnique.mockResolvedValue({
        id: 'exam-1',
        title: 'Midterm',
        examQuestions: [
          {
            id: 'eq-1',
            question: {
              id: 'q-1',
              prompt: 'Question 1',
              options: [{ id: 'A', text: 'Yes' }],
              correctAnswers: ['A'],
              explanation: 'Because it is correct',
            },
          },
        ],
      });

      const result = await service.getExamById('exam-1', { id: 'student-1', role: 'student' });
      expect(result.examQuestions[0].question.correctAnswers).toBeUndefined();
      expect(result.examQuestions[0].question.explanation).toBeUndefined();
    });
  });

  describe('Exam Execution & Auto-grading', () => {
    it('should start exam and create attempt for student', async () => {
      const mockExam = {
        id: 'exam-1',
        status: ExamStatus.PUBLISHED,
        durationMinutes: 45,
        totalPoints: 10.0,
        maxAttempts: 1,
        shuffleQuestions: false,
        examQuestions: [
          { id: 'eq-1', questionId: 'q-1', points: 5.0, question: { type: QuestionType.MULTIPLE_CHOICE, prompt: 'Q1' } },
        ],
      };
      prisma.exam.findUnique.mockResolvedValue(mockExam);
      prisma.examAttempt.findFirst.mockResolvedValue(null); // Không có attempt active
      prisma.examAttempt.count.mockResolvedValue(0); // Chưa làm lần nào
      prisma.examAttempt.create.mockResolvedValue({
        id: 'attempt-1',
        examId: 'exam-1',
        studentId: 'student-1',
        attemptNumber: 1,
        status: AttemptStatus.IN_PROGRESS,
        startedAt: new Date(),
        answers: [],
      });

      const result = await service.startExam('exam-1', 'student-1');

      expect(result.attempt.id).toBe('attempt-1');
      expect(result.exam.id).toBe('exam-1');
      expect(prisma.examAttempt.create).toHaveBeenCalled();
    });

    it('should auto-grade multiple choice and fill in blank upon submit', async () => {
      const mockExam = {
        id: 'exam-1',
        totalPoints: 10.0,
        passPercentage: 50.0,
        examQuestions: [
          {
            id: 'eq-1',
            points: 5.0,
            question: {
              type: QuestionType.MULTIPLE_CHOICE,
              correctAnswers: ['A'],
            },
          },
          {
            id: 'eq-2',
            points: 5.0,
            question: {
              type: QuestionType.FILL_BLANK,
              correctAnswers: ['essential', 'vital'],
            },
          },
        ],
      };

      const mockAttempt = {
        id: 'attempt-1',
        exam: mockExam,
        answers: [
          { id: 'ans-1', examQuestionId: 'eq-1', studentAnswer: 'A' }, // Đúng -> 5 điểm
          { id: 'ans-2', examQuestionId: 'eq-2', studentAnswer: ' Essential ' }, // Đúng (case-insensitive) -> 5 điểm
        ],
      };

      prisma.examAttempt.findFirst.mockResolvedValue(mockAttempt);
      prisma.examAnswer.update.mockResolvedValue({});
      prisma.examAttempt.update.mockResolvedValue({
        id: 'attempt-1',
        score: 10.0,
        isPassed: true,
        status: AttemptStatus.GRADED,
      });

      const result = await service.submitExam('exam-1', 'student-1');

      expect(result.attempt.score).toBe(10.0);
      expect(result.attempt.isPassed).toBe(true);
      expect(result.attempt.status).toBe(AttemptStatus.GRADED);
    });

    it('should allow teacher to manually grade essay questions', async () => {
      prisma.examAnswer.findUnique.mockResolvedValue({
        id: 'ans-essay',
        attemptId: 'attempt-1',
        examQuestion: { points: 5.0 },
        attempt: {
          exam: { totalPoints: 10.0, passPercentage: 50.0 },
        },
      });

      prisma.examAnswer.update.mockResolvedValue({
        id: 'ans-essay',
        score: 4.5,
        teacherFeedback: 'Very good argument and grammar',
      });

      prisma.examAnswer.findMany.mockResolvedValue([
        { id: 'ans-1', score: 5.0 },
        { id: 'ans-essay', score: 4.5 },
      ]);

      prisma.examAttempt.update.mockResolvedValue({
        id: 'attempt-1',
        score: 9.5,
        isPassed: true,
        status: AttemptStatus.GRADED,
      });

      const result = await service.gradeExamAnswer('ans-essay', 'teacher-1', {
        score: 4.5,
        feedback: 'Very good argument and grammar',
      });

      expect(result.score).toBe(4.5);
      expect(prisma.examAttempt.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            score: 9.5,
            isPassed: true,
            status: AttemptStatus.GRADED,
          }),
        }),
      );
    });
  });
});
