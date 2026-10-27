import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service.js';
import {
  CreateExamDto,
  CreateQuestionBankDto,
  CreateQuestionDto,
  GradeExamAnswerDto,
  SaveExamAnswersDto,
} from './dto/index.js';
import { AttemptStatus, ExamStatus, QuestionType } from '@prisma/client';

@Injectable()
export class ExamsService {
  constructor(private readonly prisma: PrismaService) {}

  // ---------------------------------------------------------------------------
  // 1. QUESTION BANKS
  // ---------------------------------------------------------------------------

  async getQuestionBanks(query: { language?: string; level?: string; search?: string }) {
    const where: any = {};
    if (query.language) where.language = query.language;
    if (query.level) where.level = query.level;
    if (query.search) {
      where.OR = [
        { title: { contains: query.search, mode: 'insensitive' } },
        { description: { contains: query.search, mode: 'insensitive' } },
      ];
    }

    return this.prisma.questionBank.findMany({
      where,
      include: {
        _count: {
          select: { questions: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async createQuestionBank(createdById: string, dto: CreateQuestionBankDto) {
    return this.prisma.questionBank.create({
      data: {
        title: dto.title,
        description: dto.description,
        language: dto.language,
        level: dto.level,
        createdById,
      },
    });
  }

  async getQuestionBankById(id: string) {
    const bank = await this.prisma.questionBank.findUnique({
      where: { id },
      include: {
        questions: {
          orderBy: { createdAt: 'asc' },
        },
      },
    });

    if (!bank) {
      throw new NotFoundException(`Không tìm thấy ngân hàng câu hỏi có ID: ${id}`);
    }

    return bank;
  }

  async addQuestionToBank(questionBankId: string, dto: CreateQuestionDto) {
    await this.getQuestionBankById(questionBankId);

    return this.prisma.question.create({
      data: {
        questionBankId,
        type: dto.type ?? QuestionType.MULTIPLE_CHOICE,
        prompt: dto.prompt,
        audioUrl: dto.audioUrl,
        imageUrl: dto.imageUrl,
        options: dto.options ?? undefined,
        correctAnswers: dto.correctAnswers ?? undefined,
        explanation: dto.explanation,
        points: dto.points ?? 1.0,
      },
    });
  }

  async updateQuestion(id: string, dto: Partial<CreateQuestionDto>) {
    const question = await this.prisma.question.findUnique({ where: { id } });
    if (!question) {
      throw new NotFoundException(`Không tìm thấy câu hỏi có ID: ${id}`);
    }

    const data: any = {};
    if (dto.type !== undefined) data.type = dto.type;
    if (dto.prompt !== undefined) data.prompt = dto.prompt;
    if (dto.audioUrl !== undefined) data.audioUrl = dto.audioUrl;
    if (dto.imageUrl !== undefined) data.imageUrl = dto.imageUrl;
    if (dto.options !== undefined) data.options = dto.options;
    if (dto.correctAnswers !== undefined) data.correctAnswers = dto.correctAnswers;
    if (dto.explanation !== undefined) data.explanation = dto.explanation;
    if (dto.points !== undefined) data.points = dto.points;

    return this.prisma.question.update({
      where: { id },
      data,
    });
  }

  async deleteQuestion(id: string) {
    const question = await this.prisma.question.findUnique({ where: { id } });
    if (!question) {
      throw new NotFoundException(`Không tìm thấy câu hỏi có ID: ${id}`);
    }

    return this.prisma.question.delete({ where: { id } });
  }

  async importQuestions(questionBankId: string, questions: CreateQuestionDto[]) {
    await this.getQuestionBankById(questionBankId);

    const created = await this.prisma.$transaction(
      questions.map((q) =>
        this.prisma.question.create({
          data: {
            questionBankId,
            type: q.type ?? QuestionType.MULTIPLE_CHOICE,
            prompt: q.prompt,
            audioUrl: q.audioUrl,
            imageUrl: q.imageUrl,
            options: q.options ?? undefined,
            correctAnswers: q.correctAnswers ?? undefined,
            explanation: q.explanation,
            points: q.points ?? 1.0,
          },
        }),
      ),
    );

    return {
      message: `Đã import thành công ${created.length} câu hỏi vào ngân hàng.`,
      count: created.length,
    };
  }

  // ---------------------------------------------------------------------------
  // 2. EXAMS MANAGEMENT
  // ---------------------------------------------------------------------------

  async getExams(query: { classId?: string; status?: string; studentId?: string }) {
    const where: any = {};
    if (query.classId) where.classId = query.classId;
    if (query.status) where.status = query.status as ExamStatus;

    const exams = await this.prisma.exam.findMany({
      where,
      include: {
        class: {
          select: { id: true, name: true, code: true },
        },
        _count: {
          select: {
            examQuestions: true,
            attempts: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (query.studentId) {
      // Gắn kèm thông tin lần thi gần nhất của học viên
      const examIds = exams.map((e) => e.id);
      const studentAttempts = await this.prisma.examAttempt.findMany({
        where: {
          examId: { in: examIds },
          studentId: query.studentId,
        },
        orderBy: { attemptNumber: 'desc' },
      });

      return exams.map((exam) => {
        const attempts = studentAttempts.filter((a) => a.examId === exam.id);
        const latestAttempt = attempts[0] || null;
        return {
          ...exam,
          studentAttemptsCount: attempts.length,
          latestAttempt,
        };
      });
    }

    return exams;
  }

  async createExam(createdById: string, dto: CreateExamDto) {
    const questions = dto.questions || [];
    let calculatedTotalPoints = 0;
    questions.forEach((q) => {
      calculatedTotalPoints += q.points ?? 1.0;
    });

    const totalPoints = dto.totalPoints ?? (calculatedTotalPoints > 0 ? calculatedTotalPoints : 10.0);

    return this.prisma.$transaction(async (tx) => {
      const exam = await tx.exam.create({
        data: {
          title: dto.title,
          description: dto.description,
          classId: dto.classId,
          durationMinutes: dto.durationMinutes ?? 45,
          passPercentage: dto.passPercentage ?? 50.0,
          totalPoints,
          shuffleQuestions: dto.shuffleQuestions ?? false,
          maxAttempts: dto.maxAttempts ?? 1,
          status: dto.status ?? ExamStatus.DRAFT,
          startTime: dto.startTime ? new Date(dto.startTime) : null,
          endTime: dto.endTime ? new Date(dto.endTime) : null,
          createdById,
        },
      });

      if (questions.length > 0) {
        await tx.examQuestion.createMany({
          data: questions.map((q, idx) => ({
            examId: exam.id,
            questionId: q.questionId,
            orderIndex: q.orderIndex ?? idx + 1,
            points: q.points ?? 1.0,
          })),
        });
      }

      return tx.exam.findUnique({
        where: { id: exam.id },
        include: {
          examQuestions: {
            include: { question: true },
            orderBy: { orderIndex: 'asc' },
          },
        },
      });
    });
  }

  async getExamById(id: string, user?: { id: string; role?: string }) {
    const exam = await this.prisma.exam.findUnique({
      where: { id },
      include: {
        class: { select: { id: true, name: true, code: true } },
        examQuestions: {
          include: { question: true },
          orderBy: { orderIndex: 'asc' },
        },
      },
    });

    if (!exam) {
      throw new NotFoundException(`Không tìm thấy bài thi có ID: ${id}`);
    }

    const isStudent = user?.role === 'student';

    // Nếu là học viên và chưa thi xong, ẩn đáp án đúng & giải thích
    if (isStudent) {
      const sanitizedQuestions = exam.examQuestions.map((eq) => {
        const { correctAnswers, explanation, ...restQuestion } = eq.question;
        return {
          ...eq,
          question: restQuestion,
        };
      });

      return {
        ...exam,
        examQuestions: sanitizedQuestions,
      };
    }

    return exam;
  }

  // ---------------------------------------------------------------------------
  // 3. EXAM ATTEMPTS & AUTO-GRADING
  // ---------------------------------------------------------------------------

  async startExam(examId: string, studentId: string) {
    const exam = await this.prisma.exam.findUnique({
      where: { id: examId },
      include: {
        examQuestions: {
          include: { question: true },
          orderBy: { orderIndex: 'asc' },
        },
      },
    });

    if (!exam) {
      throw new NotFoundException(`Không tìm thấy bài thi có ID: ${examId}`);
    }

    if (exam.status !== ExamStatus.PUBLISHED) {
      throw new BadRequestException('Bài thi chưa được mở hoặc đã đóng.');
    }

    const now = new Date();
    if (exam.startTime && now < exam.startTime) {
      throw new BadRequestException(`Bài thi chưa đến giờ mở (Bắt đầu lúc: ${exam.startTime.toISOString()}).`);
    }
    if (exam.endTime && now > exam.endTime) {
      throw new BadRequestException(`Bài thi đã kết thúc thời hạn (Hạn chót: ${exam.endTime.toISOString()}).`);
    }

    // Kiểm tra xem đã có lượt làm bài nào đang diễn ra không (IN_PROGRESS)
    const activeAttempt = await this.prisma.examAttempt.findFirst({
      where: {
        examId,
        studentId,
        status: AttemptStatus.IN_PROGRESS,
      },
      include: {
        answers: true,
      },
    });

    if (activeAttempt) {
      // Kiểm tra xem bài đang làm dở có bị quá giờ không
      const elapsedSeconds = (now.getTime() - new Date(activeAttempt.startedAt).getTime()) / 1000;
      const allowedSeconds = exam.durationMinutes * 60 + 120; // 2 phút grace period cho network latency

      if (elapsedSeconds > allowedSeconds) {
        // Tự động thu bài quá giờ
        await this.autoSubmitExpiredAttempt(activeAttempt.id, exam);
        throw new BadRequestException('Thời gian làm bài thi của bạn đã hết.');
      }

      return {
        message: 'Tiếp tục lượt làm bài hiện tại',
        attempt: activeAttempt,
        exam: this.sanitizeExamForStudent(exam),
      };
    }

    // Đếm số lần đã làm
    const pastAttemptsCount = await this.prisma.examAttempt.count({
      where: {
        examId,
        studentId,
      },
    });

    if (pastAttemptsCount >= exam.maxAttempts) {
      throw new BadRequestException(
        `Bạn đã hết số lần làm bài cho phép (${pastAttemptsCount}/${exam.maxAttempts}).`,
      );
    }

    // Xử lý đảo câu hỏi nếu shuffleQuestions = true
    let examQuestions = [...exam.examQuestions];
    if (exam.shuffleQuestions) {
      examQuestions = examQuestions.sort(() => Math.random() - 0.5);
    }

    // Tạo attempt mới
    const newAttempt = await this.prisma.examAttempt.create({
      data: {
        examId,
        studentId,
        attemptNumber: pastAttemptsCount + 1,
        maxScore: exam.totalPoints,
        status: AttemptStatus.IN_PROGRESS,
        startedAt: now,
      },
      include: {
        answers: true,
      },
    });

    return {
      message: 'Bắt đầu làm bài thi thành công',
      attempt: newAttempt,
      exam: this.sanitizeExamForStudent(exam, examQuestions),
    };
  }

  async saveAnswers(attemptId: string, studentId: string, dto: SaveExamAnswersDto) {
    const attempt = await this.prisma.examAttempt.findUnique({
      where: { id: attemptId },
      include: { exam: true },
    });

    if (!attempt) {
      throw new NotFoundException(`Không tìm thấy lượt làm bài ID: ${attemptId}`);
    }

    if (attempt.studentId !== studentId) {
      throw new ForbiddenException('Bạn không có quyền sửa câu trả lời của bài thi này');
    }

    if (attempt.status !== AttemptStatus.IN_PROGRESS) {
      throw new BadRequestException('Lượt làm bài đã được nộp hoặc đã kết thúc');
    }

    // Kiểm tra thời gian
    const now = new Date();
    const elapsedSeconds = (now.getTime() - new Date(attempt.startedAt).getTime()) / 1000;
    const allowedSeconds = attempt.exam.durationMinutes * 60 + 120;

    if (elapsedSeconds > allowedSeconds) {
      await this.autoSubmitExpiredAttempt(attempt.id, attempt.exam);
      throw new BadRequestException('Đã hết thời gian làm bài thi. Hệ thống đã tự động thu bài.');
    }

    // Lưu từng câu trả lời
    for (const ans of dto.answers) {
      await this.prisma.examAnswer.upsert({
        where: {
          attemptId_examQuestionId: {
            attemptId,
            examQuestionId: ans.examQuestionId,
          },
        },
        create: {
          attemptId,
          examQuestionId: ans.examQuestionId,
          studentAnswer: ans.studentAnswer,
        },
        update: {
          studentAnswer: ans.studentAnswer,
        },
      });
    }

    return {
      message: `Đã lưu ${dto.answers.length} câu trả lời thành công`,
      savedCount: dto.answers.length,
    };
  }

  async submitExam(examId: string, studentId: string) {
    const attempt = await this.prisma.examAttempt.findFirst({
      where: {
        examId,
        studentId,
        status: AttemptStatus.IN_PROGRESS,
      },
      include: {
        exam: {
          include: {
            examQuestions: {
              include: { question: true },
            },
          },
        },
        answers: true,
      },
    });

    if (!attempt) {
      throw new NotFoundException('Không có lượt làm bài thi nào đang diễn ra để nộp.');
    }

    return this.gradeAndFinalizeAttempt(attempt);
  }

  private async autoSubmitExpiredAttempt(attemptId: string, exam: any) {
    const attempt = await this.prisma.examAttempt.findUnique({
      where: { id: attemptId },
      include: {
        exam: {
          include: {
            examQuestions: {
              include: { question: true },
            },
          },
        },
        answers: true,
      },
    });

    if (attempt && attempt.status === AttemptStatus.IN_PROGRESS) {
      await this.gradeAndFinalizeAttempt(attempt, true);
    }
  }

  private async gradeAndFinalizeAttempt(attempt: any, isExpired = false) {
    const exam = attempt.exam;
    let totalScore = 0;
    let hasEssay = false;

    // Chấm từng câu hỏi trong đề
    for (const eq of exam.examQuestions) {
      const q = eq.question;
      const points = Number(eq.points ?? 1.0);
      const studentAnsObj = attempt.answers.find((a: any) => a.examQuestionId === eq.id);
      const studentAnswer = studentAnsObj?.studentAnswer;

      let isCorrect: boolean | null = false;
      let questionScore: number | null = 0;

      if (q.type === QuestionType.ESSAY) {
        hasEssay = true;
        isCorrect = null;
        questionScore = null; // Cần giáo viên chấm thủ công
      } else if (!studentAnswer) {
        isCorrect = false;
        questionScore = 0;
      } else if (q.type === QuestionType.MULTIPLE_CHOICE) {
        // So sánh trắc nghiệm
        const correct = Array.isArray(q.correctAnswers)
          ? q.correctAnswers
          : [String(q.correctAnswers)];

        if (Array.isArray(studentAnswer)) {
          const isMatch =
            correct.length === studentAnswer.length &&
            correct.every((val: any) => studentAnswer.includes(val));
          isCorrect = isMatch;
        } else {
          isCorrect = correct.includes(String(studentAnswer));
        }
        questionScore = isCorrect ? points : 0;
      } else if (q.type === QuestionType.FILL_BLANK) {
        // So sánh điền từ (không phân biệt chữ hoa/thường, xóa khoảng trắng thừa)
        const correctList = Array.isArray(q.correctAnswers)
          ? q.correctAnswers.map((s: any) => String(s).trim().toLowerCase())
          : [String(q.correctAnswers).trim().toLowerCase()];

        const cleanStudentAns = String(studentAnswer).trim().toLowerCase();
        isCorrect = correctList.includes(cleanStudentAns);
        questionScore = isCorrect ? points : 0;
      } else if (q.type === QuestionType.ORDERING) {
        // Sắp xếp thứ tự chính xác
        const expectedOrder = Array.isArray(q.correctAnswers) ? q.correctAnswers : [];
        if (Array.isArray(studentAnswer) && expectedOrder.length === studentAnswer.length) {
          isCorrect = expectedOrder.every((val: any, idx: number) => val === studentAnswer[idx]);
        } else {
          isCorrect = false;
        }
        questionScore = isCorrect ? points : 0;
      } else if (q.type === QuestionType.MATCHING) {
        // Nối cặp (object so sánh key-value)
        const expectedMap = (q.correctAnswers as Record<string, any>) || {};
        const studentMap = (studentAnswer as Record<string, any>) || {};
        const keys = Object.keys(expectedMap);
        let matchCount = 0;

        keys.forEach((k) => {
          if (expectedMap[k] === studentMap[k]) matchCount++;
        });

        if (keys.length > 0) {
          questionScore = Number(((matchCount / keys.length) * points).toFixed(2));
          isCorrect = matchCount === keys.length;
        } else {
          questionScore = 0;
          isCorrect = false;
        }
      }

      if (questionScore !== null) {
        totalScore += questionScore;
      }

      // Cập nhật kết quả chấm của từng câu trong DB
      if (studentAnsObj) {
        await this.prisma.examAnswer.update({
          where: { id: studentAnsObj.id },
          data: {
            isCorrect,
            score: questionScore !== null ? questionScore : undefined,
          },
        });
      } else {
        await this.prisma.examAnswer.create({
          data: {
            attemptId: attempt.id,
            examQuestionId: eq.id,
            isCorrect: false,
            score: 0,
          },
        });
      }
    }

    const maxScore = Number(exam.totalPoints ?? 10.0);
    const passPercentage = Number(exam.passPercentage ?? 50.0);
    const passScore = (maxScore * passPercentage) / 100;

    let finalStatus: AttemptStatus = AttemptStatus.GRADED;
    if (hasEssay) {
      finalStatus = AttemptStatus.SUBMITTED;
    } else if (isExpired) {
      finalStatus = AttemptStatus.EXPIRED;
    }

    const isPassed = !hasEssay ? totalScore >= passScore : null;

    const updatedAttempt = await this.prisma.examAttempt.update({
      where: { id: attempt.id },
      data: {
        submittedAt: new Date(),
        score: !hasEssay ? Number(totalScore.toFixed(2)) : null,
        isPassed,
        status: finalStatus,
      },
      include: {
        answers: {
          include: {
            examQuestion: {
              include: { question: true },
            },
          },
        },
      },
    });

    return {
      message: hasEssay
        ? 'Đã nộp bài thành công! Bài thi có phần tự luận đang chờ giáo viên chấm điểm.'
        : `Nộp bài thành công! Điểm số của bạn: ${updatedAttempt.score}/${maxScore} (${isPassed ? 'ĐẠT' : 'CHƯA ĐẠT'}).`,
      attempt: updatedAttempt,
    };
  }

  async getExamResults(examId: string) {
    const exam = await this.prisma.exam.findUnique({
      where: { id: examId },
      include: {
        class: { select: { id: true, name: true, code: true } },
      },
    });

    if (!exam) {
      throw new NotFoundException(`Không tìm thấy bài thi có ID: ${examId}`);
    }

    const attempts = await this.prisma.examAttempt.findMany({
      where: { examId },
      include: {
        student: {
          select: {
            id: true,
            userCode: true,
            fullName: true,
            email: true,
            avatarUrl: true,
          },
        },
        _count: {
          select: { answers: true },
        },
      },
      orderBy: [{ score: 'desc' }, { submittedAt: 'asc' }],
    });

    const totalAttempts = attempts.length;
    const gradedAttempts = attempts.filter((a) => a.score !== null);
    const passedCount = gradedAttempts.filter((a) => a.isPassed === true).length;
    const averageScore =
      gradedAttempts.length > 0
        ? gradedAttempts.reduce((acc, cur) => acc + Number(cur.score), 0) / gradedAttempts.length
        : 0;

    return {
      exam,
      summary: {
        totalAttempts,
        gradedCount: gradedAttempts.length,
        passedCount,
        passRate: totalAttempts > 0 ? Number(((passedCount / totalAttempts) * 100).toFixed(1)) : 0,
        averageScore: Number(averageScore.toFixed(2)),
      },
      attempts,
    };
  }

  async getMyExamResults(studentId: string) {
    return this.prisma.examAttempt.findMany({
      where: { studentId },
      include: {
        exam: {
          select: {
            id: true,
            title: true,
            durationMinutes: true,
            totalPoints: true,
            passPercentage: true,
            class: { select: { id: true, name: true, code: true } },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async gradeExamAnswer(answerId: string, gradedById: string, dto: GradeExamAnswerDto) {
    const answer = await this.prisma.examAnswer.findUnique({
      where: { id: answerId },
      include: {
        attempt: {
          include: {
            exam: true,
            answers: true,
          },
        },
        examQuestion: true,
      },
    });

    if (!answer) {
      throw new NotFoundException(`Không tìm thấy câu trả lời ID: ${answerId}`);
    }

    const maxQuestionPoints = Number(answer.examQuestion.points ?? 1.0);
    if (dto.score > maxQuestionPoints) {
      throw new BadRequestException(
        `Điểm số chấm (${dto.score}) không được vượt quá điểm tối đa của câu (${maxQuestionPoints}).`,
      );
    }

    // Cập nhật câu trả lời
    const updatedAnswer = await this.prisma.examAnswer.update({
      where: { id: answerId },
      data: {
        score: dto.score,
        teacherFeedback: dto.feedback,
        gradedById,
        gradedAt: new Date(),
        isCorrect: dto.score > 0,
      },
    });

    // Tính lại tổng điểm lượt thi
    const allAnswers = await this.prisma.examAnswer.findMany({
      where: { attemptId: answer.attemptId },
    });

    const isAllGraded = allAnswers.every((a) => a.score !== null);
    const totalScore = allAnswers.reduce((acc, cur) => acc + Number(cur.score ?? 0), 0);

    const maxScore = Number(answer.attempt.exam.totalPoints ?? 10.0);
    const passPercentage = Number(answer.attempt.exam.passPercentage ?? 50.0);
    const isPassed = (totalScore / maxScore) * 100 >= passPercentage;

    await this.prisma.examAttempt.update({
      where: { id: answer.attemptId },
      data: {
        score: Number(totalScore.toFixed(2)),
        isPassed: isAllGraded ? isPassed : undefined,
        status: isAllGraded ? AttemptStatus.GRADED : AttemptStatus.SUBMITTED,
      },
    });

    return updatedAnswer;
  }

  private sanitizeExamForStudent(exam: any, customQuestions?: any[]) {
    const questions = customQuestions || exam.examQuestions;
    return {
      id: exam.id,
      title: exam.title,
      description: exam.description,
      durationMinutes: exam.durationMinutes,
      totalPoints: exam.totalPoints,
      passPercentage: exam.passPercentage,
      questions: questions.map((eq: any) => ({
        id: eq.id,
        questionId: eq.questionId,
        orderIndex: eq.orderIndex,
        points: eq.points,
        type: eq.question.type,
        prompt: eq.question.prompt,
        audioUrl: eq.question.audioUrl,
        imageUrl: eq.question.imageUrl,
        options: eq.question.options,
      })),
    };
  }
}
