import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  ConflictException,
} from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service.js';
import {
  CreateAssignmentDto,
  UpdateAssignmentDto,
  SubmitAssignmentDto,
  GradeSubmissionDto,
  ReturnSubmissionDto,
} from './dto/index.js';
import { AssignmentStatus, SubmissionStatus } from '@prisma/client';

export interface AssignmentActor {
  id: string;
  roles: string[];
  branchId?: string | null;
}

@Injectable()
export class AssignmentsService {
  constructor(private readonly prisma: PrismaService) {}

  private studentSubmission(submission: any) {
    if (!submission) return null;
    const published =
      submission.status === SubmissionStatus.GRADED &&
      !!submission.resultPublishedAt;
    return {
      id: submission.id,
      assignmentId: submission.assignmentId,
      studentId: submission.studentId,
      content: submission.content,
      fileUrls: submission.fileUrls,
      submittedAt: submission.submittedAt,
      updatedAt: submission.updatedAt,
      status:
        submission.status === SubmissionStatus.GRADED && !published
          ? 'GRADED_PENDING'
          : submission.status,
      score: published ? submission.score : null,
      feedback:
        published || submission.status === SubmissionStatus.RETURNED
          ? submission.feedback
          : null,
      gradedAt: published ? submission.gradedAt : null,
      gradedById: published ? submission.gradedById : null,
      gradedBy: published ? submission.gradedBy : null,
      resultPublishedAt: published ? submission.resultPublishedAt : null,
    };
  }

  private async assertClassAccess(
    classItem: any,
    actor: AssignmentActor,
    manage: boolean,
  ) {
    if (actor.roles.includes('super_admin')) return;
    if (
      actor.roles.some((role) =>
        ['branch_admin', 'academic_staff'].includes(role),
      )
    ) {
      if (actor.branchId && actor.branchId === classItem.branchId) return;
      throw new ForbiddenException('Lớp học không thuộc chi nhánh của bạn');
    }
    if (
      actor.roles.some((role) =>
        ['teacher', 'teaching_assistant'].includes(role),
      ) &&
      (classItem.mainTeacherId === actor.id ||
        classItem.assistantTeacherId === actor.id)
    )
      return;
    if (
      !manage &&
      actor.roles.includes('student') &&
      classItem.students?.some((student: any) => student.studentId === actor.id)
    )
      return;
    if (!manage && actor.roles.includes('parent')) {
      const childIds = (classItem.students ?? []).map(
        (student: any) => student.studentId,
      );
      if (childIds.length > 0) {
        const relation = await this.prisma.parentStudent.findFirst({
          where: { parentId: actor.id, studentId: { in: childIds } },
        });
        if (relation) return;
      }
    }
    throw new ForbiddenException(
      'Bạn không có quyền truy cập bài tập của lớp này',
    );
  }

  // --------------------------------------------------------------------------
  // 1. GET CLASS ASSIGNMENTS
  // --------------------------------------------------------------------------

  async getClassAssignments(classId: string, actor: AssignmentActor) {
    const classItem = await this.prisma.class.findUnique({
      where: { id: classId },
      include: {
        students: {
          where: { status: 'ENROLLED' },
          select: { studentId: true },
        },
      },
    });

    if (!classItem) {
      throw new NotFoundException(`Không tìm thấy lớp học với ID: ${classId}`);
    }
    await this.assertClassAccess(classItem, actor, false);

    const assignments = await this.prisma.assignment.findMany({
      where: {
        classId,
        ...(actor.roles.some((role) => ['student', 'parent'].includes(role))
          ? { status: AssignmentStatus.PUBLISHED }
          : {}),
      },
      include: {
        createdBy: {
          select: {
            id: true,
            fullName: true,
            userCode: true,
            avatarUrl: true,
          },
        },
        submissions: {
          ...(actor.roles.includes('student')
            ? { where: { studentId: actor.id } }
            : {}),
          select: {
            id: true,
            studentId: true,
            status: true,
            score: true,
            submittedAt: true,
            resultPublishedAt: true,
            content: true,
            fileUrls: true,
            updatedAt: true,
            assignmentId: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    const isStudent = actor.roles.includes('student');

    return assignments.map((a) => {
      const totalSubmissions = a.submissions.filter(
        (s) => s.status !== SubmissionStatus.DRAFT,
      ).length;
      const gradedCount = a.submissions.filter(
        (s) => s.status === SubmissionStatus.GRADED,
      ).length;
      const mySubmission = isStudent
        ? this.studentSubmission(
            a.submissions.find((s) => s.studentId === actor.id),
          )
        : null;

      return {
        id: a.id,
        classId: a.classId,
        title: a.title,
        description: a.description,
        type: a.type,
        status: a.status,
        deadline: a.deadline,
        maxScore: a.maxScore,
        attachments: a.attachments,
        createdAt: a.createdAt,
        createdBy: a.createdBy,
        stats: isStudent
          ? undefined
          : {
              totalSubmissions,
              gradedCount,
            },
        mySubmission,
      };
    });
  }

  // --------------------------------------------------------------------------
  // 2. CREATE ASSIGNMENT
  // --------------------------------------------------------------------------

  async createAssignment(
    classId: string,
    dto: CreateAssignmentDto,
    actor: AssignmentActor,
  ) {
    const classItem = await this.prisma.class.findUnique({
      where: { id: classId },
    });

    if (!classItem) {
      throw new NotFoundException(`Không tìm thấy lớp học với ID: ${classId}`);
    }
    await this.assertClassAccess(classItem, actor, true);

    return this.prisma.assignment.create({
      data: {
        classId,
        createdById: actor.id,
        title: dto.title,
        description: dto.description,
        type: dto.type,
        status: dto.status ?? AssignmentStatus.PUBLISHED,
        deadline: dto.deadline ? new Date(dto.deadline) : null,
        maxScore: dto.maxScore ?? 10,
        attachments: dto.attachments ?? [],
      },
      include: {
        createdBy: {
          select: {
            id: true,
            fullName: true,
            userCode: true,
          },
        },
      },
    });
  }

  // --------------------------------------------------------------------------
  // 3. GET ASSIGNMENT DETAIL
  // --------------------------------------------------------------------------

  async getAssignmentDetail(id: string, actor: AssignmentActor) {
    const assignment = await this.prisma.assignment.findUnique({
      where: { id },
      include: {
        class: {
          include: {
            course: { select: { title: true } },
            students: {
              where: { status: 'ENROLLED' },
            },
          },
        },
        createdBy: {
          select: {
            id: true,
            fullName: true,
            userCode: true,
            avatarUrl: true,
          },
        },
        submissions: {
          ...(actor.roles.includes('student')
            ? { where: { studentId: actor.id } }
            : {}),
          include: { gradedBy: { select: { fullName: true } } },
        },
      },
    });

    if (!assignment) {
      throw new NotFoundException(`Không tìm thấy bài tập ID: ${id}`);
    }
    await this.assertClassAccess(assignment.class, actor, false);
    if (
      actor.roles.some((role) => ['student', 'parent'].includes(role)) &&
      assignment.status !== AssignmentStatus.PUBLISHED
    ) {
      throw new NotFoundException('Bài tập chưa được xuất bản');
    }

    const totalEnrolled = assignment.class.students.length;
    const submittedCount = assignment.submissions.filter(
      (s) => s.status !== SubmissionStatus.DRAFT,
    ).length;
    const gradedCount = assignment.submissions.filter(
      (s) => s.status === SubmissionStatus.GRADED,
    ).length;

    let mySubmission = null;
    if (actor.roles.includes('student')) {
      mySubmission = this.studentSubmission(
        assignment.submissions.find((s) => s.studentId === actor.id),
      );
    }

    return {
      assignment: {
        id: assignment.id,
        classId: assignment.classId,
        className: assignment.class.name,
        courseName: assignment.class.course.title,
        classCode: assignment.class.code,
        title: assignment.title,
        description: assignment.description,
        type: assignment.type,
        status: assignment.status,
        deadline: assignment.deadline,
        maxScore: assignment.maxScore,
        attachments: assignment.attachments,
        createdAt: assignment.createdAt,
        createdBy: assignment.createdBy,
      },
      stats: actor.roles.includes('student')
        ? undefined
        : {
            totalEnrolled,
            submittedCount,
            totalSubmissions: submittedCount,
            gradedCount,
            pendingCount: submittedCount - gradedCount,
          },
      mySubmission,
    };
  }

  async updateAssignment(
    id: string,
    dto: UpdateAssignmentDto,
    actor: AssignmentActor,
  ) {
    const assignment = await this.prisma.assignment.findUnique({
      where: { id },
      include: { class: true },
    });
    if (!assignment) {
      throw new NotFoundException(`Không tìm thấy bài tập ID: ${id}`);
    }
    await this.assertClassAccess(assignment.class, actor, true);
    if (dto.maxScore !== undefined) {
      if (dto.maxScore < 1 || dto.maxScore > 100) {
        throw new BadRequestException('Thang điểm phải từ 1 đến 100');
      }
      const highestGrade = await this.prisma.submission.findFirst({
        where: { assignmentId: id, score: { gt: dto.maxScore } },
        select: { id: true },
      });
      if (highestGrade) {
        throw new BadRequestException(
          'Thang điểm mới không được thấp hơn điểm đã chấm',
        );
      }
    }
    return this.prisma.assignment.update({
      where: { id },
      data: {
        title: dto.title,
        description: dto.description,
        type: dto.type,
        status: dto.status,
        deadline:
          dto.deadline === null
            ? null
            : dto.deadline
              ? new Date(dto.deadline)
              : undefined,
        maxScore: dto.maxScore,
        attachments: dto.attachments,
      },
    });
  }

  // --------------------------------------------------------------------------
  // 4. SUBMIT ASSIGNMENT (HỌC VIÊN NỘP BÀI)
  // --------------------------------------------------------------------------

  async submitAssignment(
    assignmentId: string,
    studentId: string,
    dto: SubmitAssignmentDto,
  ) {
    if (!dto.content?.trim() && (!dto.fileUrls || dto.fileUrls.length === 0)) {
      throw new BadRequestException(
        'Bài nộp cần có nội dung hoặc tệp đính kèm',
      );
    }
    const assignment = await this.prisma.assignment.findUnique({
      where: { id: assignmentId },
      include: {
        class: {
          include: {
            students: {
              where: { studentId, status: 'ENROLLED' },
            },
          },
        },
      },
    });

    if (!assignment) {
      throw new NotFoundException(`Không tìm thấy bài tập ID: ${assignmentId}`);
    }

    if (assignment.class.students.length === 0) {
      throw new ForbiddenException(
        'Bạn không thuộc danh sách học viên của lớp này để nộp bài',
      );
    }
    if (assignment.status !== AssignmentStatus.PUBLISHED) {
      throw new ForbiddenException('Bài tập không nhận bài nộp');
    }

    const previous = await this.prisma.submission.findUnique({
      where: { assignmentId_studentId: { assignmentId, studentId } },
    });
    if (previous?.status === SubmissionStatus.GRADED) {
      throw new BadRequestException(
        'Bài đã được chấm; hãy liên hệ giáo viên nếu cần nộp lại',
      );
    }

    const now = new Date();
    if (
      previous &&
      previous.status !== SubmissionStatus.DRAFT &&
      previous.status !== SubmissionStatus.RETURNED &&
      assignment.deadline &&
      now > assignment.deadline
    ) {
      throw new BadRequestException(
        'Đã hết hạn nộp; bạn không thể sửa bài đã nộp',
      );
    }

    // Kiểm tra xem có nộp muộn không
    const isLate = assignment.deadline ? now > assignment.deadline : false;
    const submissionStatus = isLate
      ? SubmissionStatus.LATE
      : SubmissionStatus.SUBMITTED;

    return this.prisma.submission.upsert({
      where: {
        assignmentId_studentId: {
          assignmentId,
          studentId,
        },
      },
      create: {
        assignmentId,
        studentId,
        content: dto.content,
        fileUrls: dto.fileUrls ?? [],
        submittedAt: now,
        status: submissionStatus,
      },
      update: {
        content: dto.content,
        fileUrls: dto.fileUrls ?? [],
        submittedAt: now,
        status: submissionStatus,
        score: null,
        feedback: null,
        gradedById: null,
        gradedAt: null,
        resultPublishedAt: null,
      },
      include: {
        student: {
          select: {
            id: true,
            userCode: true,
            fullName: true,
            avatarUrl: true,
          },
        },
      },
    });
  }

  async saveDraft(
    assignmentId: string,
    studentId: string,
    dto: SubmitAssignmentDto,
  ) {
    const assignment = await this.prisma.assignment.findUnique({
      where: { id: assignmentId },
      include: {
        class: {
          include: {
            students: {
              where: { studentId, status: 'ENROLLED' },
            },
          },
        },
      },
    });
    if (!assignment) throw new NotFoundException('Không tìm thấy bài tập');
    if (
      !assignment.class.students.length ||
      assignment.status !== AssignmentStatus.PUBLISHED
    ) {
      throw new ForbiddenException('Bạn không thể lưu nháp bài tập này');
    }
    if (assignment.deadline && new Date() > assignment.deadline) {
      throw new BadRequestException('Đã hết hạn lưu nháp');
    }
    const previous = await this.prisma.submission.findUnique({
      where: { assignmentId_studentId: { assignmentId, studentId } },
    });
    if (previous && previous.status !== SubmissionStatus.DRAFT) {
      throw new ConflictException(
        'Bài đã nộp; hãy dùng chức năng nộp lại nếu được phép',
      );
    }
    if (previous) {
      const updated = await this.prisma.submission.updateMany({
        where: { id: previous.id, status: SubmissionStatus.DRAFT },
        data: { content: dto.content ?? null, fileUrls: dto.fileUrls ?? [] },
      });
      if (!updated.count)
        throw new ConflictException('Trạng thái bài đã thay đổi');
      return this.prisma.submission.findUnique({ where: { id: previous.id } });
    }
    return this.prisma.submission.create({
      data: {
        assignmentId,
        studentId,
        content: dto.content ?? null,
        fileUrls: dto.fileUrls ?? [],
        submittedAt: null,
        status: SubmissionStatus.DRAFT,
      },
    });
  }

  // --------------------------------------------------------------------------
  // 5. GET ASSIGNMENT SUBMISSIONS (GIÁO VIÊN XEM BÀI NỘP)
  // --------------------------------------------------------------------------

  async getAssignmentSubmissions(assignmentId: string, actor: AssignmentActor) {
    const assignment = await this.prisma.assignment.findUnique({
      where: { id: assignmentId },
      include: {
        class: {
          include: {
            students: {
              where: { status: 'ENROLLED' },
              include: {
                student: {
                  select: {
                    id: true,
                    userCode: true,
                    fullName: true,
                    avatarUrl: true,
                    phone: true,
                    email: true,
                  },
                },
              },
            },
          },
        },
        submissions: {
          include: {
            student: {
              select: {
                id: true,
                userCode: true,
                fullName: true,
                avatarUrl: true,
                phone: true,
                email: true,
              },
            },
            gradedBy: {
              select: {
                id: true,
                fullName: true,
                userCode: true,
              },
            },
          },
        },
      },
    });

    if (!assignment) {
      throw new NotFoundException(`Không tìm thấy bài tập ID: ${assignmentId}`);
    }
    await this.assertClassAccess(assignment.class, actor, true);

    const subMap = new Map<string, any>();
    for (const sub of assignment.submissions) {
      if (sub.status !== SubmissionStatus.DRAFT) subMap.set(sub.studentId, sub);
    }

    const studentList = assignment.class.students.map((cs) => {
      const student = cs.student;
      const sub = subMap.get(student.id);

      return {
        student,
        hasSubmitted: !!sub && sub.status !== SubmissionStatus.DRAFT,
        submission: sub
          ? {
              id: sub.id,
              content: sub.content,
              fileUrls: sub.fileUrls,
              submittedAt: sub.submittedAt,
              score: sub.score,
              feedback: sub.feedback,
              status: sub.status,
              gradedBy: sub.gradedBy,
              gradedAt: sub.gradedAt,
              resultPublishedAt: sub.resultPublishedAt,
            }
          : null,
      };
    });

    const submittedCount = assignment.submissions.filter(
      (s) => s.status !== SubmissionStatus.DRAFT,
    ).length;
    const gradedCount = assignment.submissions.filter(
      (s) => s.status === SubmissionStatus.GRADED,
    ).length;
    const lateCount = assignment.submissions.filter(
      (s) => s.status === SubmissionStatus.LATE,
    ).length;

    return {
      assignment: {
        id: assignment.id,
        title: assignment.title,
        deadline: assignment.deadline,
        maxScore: assignment.maxScore,
        type: assignment.type,
      },
      stats: {
        totalEnrolled: assignment.class.students.length,
        submittedCount,
        gradedCount,
        lateCount,
        notSubmittedCount: assignment.class.students.length - submittedCount,
      },
      students: studentList,
    };
  }

  // --------------------------------------------------------------------------
  // 6. GRADE SUBMISSION (CHẤM ĐIỂM + NHẬN XÉT)
  // --------------------------------------------------------------------------

  async gradeSubmission(
    submissionId: string,
    dto: GradeSubmissionDto,
    actor: AssignmentActor,
  ) {
    const submission = await this.prisma.submission.findUnique({
      where: { id: submissionId },
      include: {
        assignment: { include: { class: true } },
      },
    });

    if (!submission) {
      throw new NotFoundException(`Không tìm thấy bài nộp ID: ${submissionId}`);
    }
    await this.assertClassAccess(submission.assignment.class, actor, true);
    if (
      submission.status === SubmissionStatus.DRAFT ||
      submission.status === SubmissionStatus.RETURNED
    ) {
      throw new BadRequestException('Bài chưa sẵn sàng để chấm điểm');
    }

    const maxScore = Number(submission.assignment.maxScore);
    if (dto.score > maxScore) {
      throw new BadRequestException(
        `Điểm số (${dto.score}) không được vượt quá thang điểm tối đa (${maxScore})`,
      );
    }

    return this.prisma.submission.update({
      where: { id: submissionId },
      data: {
        score: dto.score,
        feedback: dto.feedback,
        status: SubmissionStatus.GRADED,
        gradedById: actor.id,
        gradedAt: new Date(),
        resultPublishedAt: null,
      },
      include: {
        student: {
          select: {
            id: true,
            fullName: true,
            userCode: true,
          },
        },
        gradedBy: {
          select: {
            id: true,
            fullName: true,
            userCode: true,
          },
        },
      },
    });
  }

  async publishResult(submissionId: string, actor: AssignmentActor) {
    const submission = await this.prisma.submission.findUnique({
      where: { id: submissionId },
      include: { assignment: { include: { class: true } } },
    });
    if (!submission) throw new NotFoundException('Không tìm thấy bài nộp');
    await this.assertClassAccess(submission.assignment.class, actor, true);
    if (
      submission.status !== SubmissionStatus.GRADED ||
      submission.score === null
    ) {
      throw new BadRequestException('Chỉ công bố bài đã chấm điểm');
    }
    if (submission.resultPublishedAt) return submission;
    return this.prisma.submission.update({
      where: { id: submissionId },
      data: { resultPublishedAt: new Date() },
    });
  }

  async returnSubmission(
    submissionId: string,
    dto: ReturnSubmissionDto,
    actor: AssignmentActor,
  ) {
    if (!dto.feedback?.trim()) {
      throw new BadRequestException('Cần nhập hướng dẫn để học viên làm lại');
    }
    const submission = await this.prisma.submission.findUnique({
      where: { id: submissionId },
      include: { assignment: { include: { class: true } } },
    });
    if (!submission) throw new NotFoundException('Không tìm thấy bài nộp');
    await this.assertClassAccess(submission.assignment.class, actor, true);
    if (
      submission.status !== SubmissionStatus.SUBMITTED &&
      submission.status !== SubmissionStatus.LATE
    ) {
      throw new BadRequestException(
        'Chỉ có thể yêu cầu làm lại bài đã nộp và chưa chấm',
      );
    }
    return this.prisma.submission.update({
      where: { id: submissionId },
      data: {
        status: SubmissionStatus.RETURNED,
        feedback: dto.feedback.trim(),
        score: null,
        gradedById: actor.id,
        gradedAt: null,
        resultPublishedAt: null,
      },
    });
  }
}
