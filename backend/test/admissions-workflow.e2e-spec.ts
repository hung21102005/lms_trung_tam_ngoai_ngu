import { Test } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import * as bcrypt from 'bcryptjs';
import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';
import { AppModule } from '../src/app.module.js';
import { PrismaService } from '../src/database/prisma.service.js';
import { MailService } from '../src/modules/mail/mail.service.js';
import { ClassStatus, PublicationStatus, UserStatus } from '@prisma/client';

// This suite must never write to the operational database. Create a fresh
// lms_codex_e2e_* database and apply migrations before running it.
const isolatedDatabase = (() => {
  try {
    return /^\/lms_codex_e2e_[a-z0-9]+$/.test(
      new URL(process.env.DATABASE_URL ?? '').pathname,
    );
  } catch {
    return false;
  }
})();

const run = isolatedDatabase ? describe : describe.skip;

run('Public admissions through enrollment (isolated PostgreSQL E2E)', () => {
  let app: INestApplication;
  let db: PrismaService;
  let adminToken: string;
  let teacherToken: string;
  let classId: string;
  let secondClassId: string;
  let failureClassId: string;
  let manualClassId: string;
  let teacherId: string;
  let courseId: string;
  let programId: string;
  let levelId: string;
  let branchId: string;
  let roomId: string;
  let sessionDate: Date;
  const guestPhone = '0901234567';
  const suffix = randomUUID().slice(0, 8);

  const login = async (identifier: string, password: string) => {
    const response = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ identifier, password });
    expect(response.status).toBe(200);
    expect(response.body.accessToken).toBeTypeOf('string');
    return response.body;
  };

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(MailService)
      .useValue({ sendWelcomeEmail: vi.fn().mockResolvedValue(true) })
      .compile();
    app = moduleRef.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({ whitelist: true, transform: true }),
    );
    await app.init();
    db = app.get(PrismaService);

    const [adminRole, teacherRole] = await Promise.all([
      db.role.create({ data: { code: 'super_admin', name: 'Admin test' } }),
      db.role.create({ data: { code: 'teacher', name: 'Teacher test' } }),
      db.role.create({ data: { code: 'student', name: 'Student test' } }),
    ]);
    const branch = await db.branch.create({
      data: {
        code: `E2E-${suffix}`,
        name: 'Chi nhánh E2E',
        address: 'Test only',
      },
    });
    const room = await db.room.create({
      data: { branchId: branch.id, code: 'R1', name: 'Phòng E2E', capacity: 2 },
    });
    branchId = branch.id;
    roomId = room.id;
    const passwordHash = bcrypt.hashSync('E2eAdmin@123', 4);
    await db.user.create({
      data: {
        userCode: `ADMIN-${suffix}`,
        fullName: 'Admin E2E',
        passwordHash,
        status: UserStatus.ACTIVE,
        isFirstLogin: false,
        branchId: branch.id,
        userRoles: { create: { roleId: adminRole.id } },
      },
    });
    const teacher = await db.user.create({
      data: {
        userCode: `TEACHER-${suffix}`,
        fullName: 'Teacher E2E',
        passwordHash,
        status: UserStatus.ACTIVE,
        isFirstLogin: false,
        branchId: branch.id,
        userRoles: { create: { roleId: teacherRole.id } },
        teacherProfile: { create: {} },
      },
    });
    teacherId = teacher.id;
    const program = await db.trainingProgram.create({
      data: {
        code: `PRG-${suffix}`,
        slug: `e2e-program-${suffix}`,
        nameVi: 'Chương trình E2E',
        nameEn: 'E2E Program',
        category: 'GENERAL_ENGLISH',
        status: PublicationStatus.PUBLISHED,
        isPublic: true,
      },
    });
    programId = program.id;
    const course = await db.course.create({
      data: {
        code: `COURSE-${suffix}`,
        title: 'Khóa E2E',
        slug: `e2e-course-${suffix}`,
        publicationStatus: PublicationStatus.PUBLISHED,
        programId: program.id,
      },
    });
    const level = await db.courseLevel.create({
      data: { courseId: course.id, code: 'A1', name: 'A1 E2E' },
    });
    courseId = course.id;
    levelId = level.id;
    const today = new Date();
    const day = (offset: number) => {
      const date = new Date(
        Date.UTC(
          today.getUTCFullYear(),
          today.getUTCMonth(),
          today.getUTCDate(),
        ),
      );
      date.setUTCDate(date.getUTCDate() + offset);
      return date;
    };
    const base = {
      courseId: course.id,
      levelId: level.id,
      branchId: branch.id,
      roomId: room.id,
      mainTeacherId: teacher.id,
      status: ClassStatus.OPEN_FOR_ENROLLMENT,
      startDate: day(14),
      endDate: day(28),
      scheduleDays: ['MONDAY'],
      startTime: '18:00',
      endTime: '19:30',
      totalSessions: 1,
      tuitionFee: 1500000,
      registrationOpenAt: day(-1),
      registrationCloseAt: day(7),
    };
    sessionDate = day(14);
    const firstClass = await db.class.create({
      data: {
        ...base,
        code: `CLASS-${suffix}-1`,
        name: 'Lớp E2E A',
        maxCapacity: 2,
      },
    });
    classId = firstClass.id;
    const secondClass = await db.class.create({
      data: {
        ...base,
        code: `CLASS-${suffix}-2`,
        name: 'Lớp E2E B',
        maxCapacity: 1,
      },
    });
    secondClassId = secondClass.id;
    const failureClass = await db.class.create({
      data: {
        ...base,
        code: `CLASS-${suffix}-3`,
        name: 'Lớp kiểm tra rollback',
        maxCapacity: 1,
      },
    });
    failureClassId = failureClass.id;
    const manualClass = await db.class.create({
      data: {
        ...base,
        code: `CLASS-${suffix}-4`,
        name: 'Lớp ghi danh đồng thời',
        maxCapacity: 1,
      },
    });
    manualClassId = manualClass.id;
    await db.classSession.create({
      data: {
        classId,
        sessionNumber: 1,
        title: 'Buổi E2E',
        date: day(14),
        startTime: '18:00',
        endTime: '19:30',
        roomId: room.id,
        teacherId: teacher.id,
      },
    });
    adminToken = (await login(`ADMIN-${suffix}`, 'E2eAdmin@123')).accessToken;
    teacherToken = (await login(`TEACHER-${suffix}`, 'E2eAdmin@123'))
      .accessToken;
  }, 60000);

  afterAll(async () => {
    if (app) await app.close();
  });

  it('takes a guest from public catalog through CRM, approval and LMS views', async () => {
    const server = app.getHttpServer();
    const programs = await request(server).get('/public/programs');
    expect(programs.status).toBe(200);
    expect(
      programs.body.some(
        (item: { slug: string }) => item.slug === `e2e-program-${suffix}`,
      ),
    ).toBe(true);
    const courses = await request(server).get('/public/courses');
    expect(courses.status).toBe(200);
    expect(
      courses.body.some(
        (item: { slug: string }) => item.slug === `e2e-course-${suffix}`,
      ),
    ).toBe(true);
    const offerings = await request(server).get('/public/classes');
    expect(offerings.status).toBe(200);
    expect(
      offerings.body.items.some((item: { id: string }) => item.id === classId),
    ).toBe(true);

    const registration = {
      classId,
      fullName: 'Học viên E2E',
      phone: guestPhone,
    };
    const submitted = await request(server)
      .post('/public/registrations')
      .send(registration);
    expect(submitted.status).toBe(201);
    expect(
      (await request(server).post('/public/registrations').send(registration))
        .status,
    ).toBe(201);
    const staff = await request(server)
      .get('/admissions/registrations')
      .set('Authorization', `Bearer ${adminToken}`);
    expect(staff.status).toBe(200);
    const pending = staff.body.find(
      (item: { classId: string }) => item.classId === classId,
    );
    expect(pending.status).toBe('PENDING');
    expect(await db.classRegistration.count({ where: { classId } })).toBe(1);
    expect(await db.admissionLead.count({ where: { phone: guestPhone } })).toBe(
      1,
    );

    const contacted = await request(server)
      .patch(`/admissions/registrations/${pending.id}/review`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ status: 'CONTACTED' });
    expect(contacted.status).toBe(200);
    const converted = await request(server)
      .post(`/admissions/leads/${pending.leadId}/convert`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({});
    expect(converted.status).toBe(200);
    const studentId = converted.body.student.id as string;
    const studentLogin = await login(
      converted.body.student.userCode,
      converted.body.student.temporaryPassword,
    );
    const studentToken = studentLogin.accessToken as string;
    expect(studentLogin.requiresPasswordChange).toBe(true);
    const beforeApproval = await request(server)
      .get('/my/registrations')
      .set('Authorization', `Bearer ${studentToken}`);
    expect(beforeApproval.status).toBe(200);
    expect(
      beforeApproval.body.find((item: { id: string }) => item.id === pending.id)
        .status,
    ).toBe('CONTACTED');

    const approval = await request(server)
      .post(`/admissions/registrations/${pending.id}/approve`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({});
    expect(approval.status).toBe(201);
    expect(approval.body.status).toBe('APPROVED');
    expect(
      await db.classStudent.count({
        where: { classId, studentId, status: 'ENROLLED' },
      }),
    ).toBe(1);
    const invoice = await db.invoice.findFirst({
      where: { classId, studentId },
    });
    expect(invoice).toMatchObject({ status: 'PENDING' });
    expect(Number(invoice?.totalAmount)).toBe(1500000);
    expect(Number(invoice?.paidAmount)).toBe(0);
    expect(
      await db.classStudent.count({ where: { classId, status: 'ENROLLED' } }),
    ).toBe(1);

    const studentClasses = await request(server)
      .get('/my/classes')
      .set('Authorization', `Bearer ${studentToken}`);
    expect(studentClasses.status).toBe(200);
    expect(
      studentClasses.body.some((item: { id: string }) => item.id === classId),
    ).toBe(true);
    const studentSchedule = await request(server)
      .get('/my/schedule')
      .set('Authorization', `Bearer ${studentToken}`);
    expect(studentSchedule.status).toBe(200);
    expect(
      studentSchedule.body.some(
        (item: { classId: string }) => item.classId === classId,
      ),
    ).toBe(true);
    const teacherClass = await request(server)
      .get(`/classes/${classId}`)
      .set('Authorization', `Bearer ${teacherToken}`);
    expect(teacherClass.status).toBe(200);
    expect(
      teacherClass.body.students.some(
        (item: { studentId: string }) => item.studentId === studentId,
      ),
    ).toBe(true);
    expect(teacherClass.body.mainTeacherId).toBe(teacherId);
  }, 60000);

  it('keeps one seat under concurrent approvals and rolls back the losing request', async () => {
    const server = app.getHttpServer();
    const phones = ['0901234568', '0901234569'];
    const submissions = await Promise.all(
      phones.map((phone) =>
        request(server)
          .post('/public/registrations')
          .send({
            classId: secondClassId,
            fullName: `Học viên ${phone}`,
            phone,
          }),
      ),
    );
    expect(submissions.map((item) => item.status)).toEqual([201, 201]);
    const requests = await db.classRegistration.findMany({
      where: { classId: secondClassId },
      orderBy: { phone: 'asc' },
    });
    expect(requests).toHaveLength(2);
    const convertedAccounts: { userCode: string; temporaryPassword: string }[] =
      [];
    for (const item of requests) {
      const result = await request(server)
        .post(`/admissions/leads/${item.leadId}/convert`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({});
      expect(result.status).toBe(200);
      convertedAccounts.push(result.body.student);
    }
    const approved = await Promise.all(
      requests.map((item) =>
        request(server)
          .post(`/admissions/registrations/${item.id}/approve`)
          .set('Authorization', `Bearer ${adminToken}`)
          .send({}),
      ),
    );
    expect(approved.map((item) => item.status).sort()).toEqual([201, 409]);
    expect(
      await db.classStudent.count({
        where: { classId: secondClassId, status: 'ENROLLED' },
      }),
    ).toBe(1);
    expect(await db.invoice.count({ where: { classId: secondClassId } })).toBe(
      1,
    );
    expect(
      await db.classRegistration.count({
        where: { classId: secondClassId, status: 'PENDING' },
      }),
    ).toBe(1);
    const fullClass = await request(server).post('/public/registrations').send({
      classId: secondClassId,
      fullName: 'Học viên đến sau',
      phone: '0901234570',
    });
    expect(fullClass.status).toBe(409);
    const duplicate = await request(server).post('/public/registrations').send({
      classId: secondClassId,
      fullName: 'Học viên đã đăng ký',
      phone: phones[0],
    });
    expect(duplicate.status).toBe(201);
    const pendingIndex = approved.findIndex((item) => item.status === 409);
    const pendingStudentLogin = await login(
      convertedAccounts[pendingIndex].userCode,
      convertedAccounts[pendingIndex].temporaryPassword,
    );
    const existingStudentRequest = await request(server)
      .post('/my/registrations')
      .set('Authorization', `Bearer ${pendingStudentLogin.accessToken}`)
      .send({ classId: secondClassId });
    expect(existingStudentRequest.status).toBe(201);
    expect(existingStudentRequest.body.id).toBe(requests[pendingIndex].id);
    expect(
      await db.classRegistration.count({ where: { classId: secondClassId } }),
    ).toBe(2);
  }, 60000);

  it('rejects a new class whose room and teacher overlap an existing session', async () => {
    const weekdays = [
      'SUNDAY',
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
    ];
    const response = await request(app.getHttpServer())
      .post('/classes')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        code: `CONFLICT-${suffix.toUpperCase()}`,
        name: 'Lớp xung đột E2E',
        courseId,
        levelId,
        branchId,
        roomId,
        mainTeacherId: teacherId,
        startDate: sessionDate.toISOString().slice(0, 10),
        scheduleDays: [weekdays[sessionDate.getUTCDay()]],
        startTime: '18:30',
        endTime: '19:45',
        totalSessions: 1,
        maxCapacity: 2,
      });
    expect(response.status).toBe(409);
    expect(
      await db.class.count({
        where: { code: `CONFLICT-${suffix.toUpperCase()}` },
      }),
    ).toBe(0);
  });

  it('keeps registration and invoice consistent when manual enrollment races approval', async () => {
    const server = app.getHttpServer();
    expect(
      (
        await request(server).post('/public/registrations').send({
          classId: manualClassId,
          fullName: 'Học viên ghi danh đồng thời',
          phone: '0901234572',
        })
      ).status,
    ).toBe(201);
    const registration = await db.classRegistration.findFirstOrThrow({
      where: { classId: manualClassId },
    });
    const converted = await request(server)
      .post(`/admissions/leads/${registration.leadId}/convert`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({});
    expect(converted.status).toBe(200);
    const studentId = converted.body.student.id as string;
    const responses = await Promise.all([
      request(server)
        .post(`/admissions/registrations/${registration.id}/approve`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({}),
      request(server)
        .post(`/classes/${manualClassId}/students`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ studentId }),
    ]);
    expect(
      responses
        .map((item) => item.status)
        .every((status) => [201, 409].includes(status)),
    ).toBe(true);
    expect(responses.some((item) => item.status === 201)).toBe(true);
    expect(
      await db.classStudent.count({
        where: { classId: manualClassId, studentId },
      }),
    ).toBe(1);
    expect(
      await db.invoice.count({ where: { classId: manualClassId, studentId } }),
    ).toBe(1);
    expect(
      await db.classRegistration.findUniqueOrThrow({
        where: { id: registration.id },
      }),
    ).toMatchObject({ status: 'APPROVED', studentId });
  });

  it('rolls back enrollment when invoice creation fails inside the transaction', async () => {
    const server = app.getHttpServer();
    const submitted = await request(server).post('/public/registrations').send({
      classId: failureClassId,
      fullName: 'Học viên kiểm tra rollback',
      phone: '0901234571',
    });
    expect(submitted.status).toBe(201);
    const pending = await db.classRegistration.findFirstOrThrow({
      where: { classId: failureClassId },
    });
    const converted = await request(server)
      .post(`/admissions/leads/${pending.leadId}/convert`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({});
    expect(converted.status).toBe(200);

    // The trigger exists only in the guarded, disposable E2E database.
    const triggerName = `e2e_invoice_${suffix}`;
    await db.$executeRawUnsafe(`
      CREATE FUNCTION ${triggerName}() RETURNS trigger AS $$
      BEGIN
        IF NEW."classId" = '${failureClassId}' THEN
          RAISE EXCEPTION 'e2e invoice failure';
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql
    `);
    await db.$executeRawUnsafe(`
      CREATE TRIGGER ${triggerName} BEFORE INSERT ON invoices
      FOR EACH ROW EXECUTE FUNCTION ${triggerName}()
    `);

    const approval = await request(server)
      .post(`/admissions/registrations/${pending.id}/approve`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({});
    expect(approval.status).toBe(500);
    expect(
      await db.classRegistration.findUniqueOrThrow({
        where: { id: pending.id },
        select: { status: true },
      }),
    ).toMatchObject({ status: 'PENDING' });
    expect(
      await db.classStudent.count({ where: { classId: failureClassId } }),
    ).toBe(0);
    expect(await db.invoice.count({ where: { classId: failureClassId } })).toBe(
      0,
    );
    expect(converted.body.student.id).toBeTypeOf('string');
  });

  it('creates, reviews, publishes and unpublishes a course through HTTP', async () => {
    const server = app.getHttpServer();
    const auth = `Bearer ${adminToken}`;
    const slug = `academic-${suffix}`;
    const created = await request(server)
      .post('/courses')
      .set('Authorization', auth)
      .send({
        code: `ACADEMIC-${suffix.toUpperCase()}`,
        title: 'Khóa học thử nghiệm',
        slug,
        programId,
        isActive: true,
        description: 'Mô tả nội bộ',
        publicDescription: 'Mô tả công khai',
        targetAudience: 'Người học mới',
      });
    expect(created.status).toBe(201);
    const id = created.body.id as string;
    const edited = await request(server)
      .patch(`/courses/${id}`)
      .set('Authorization', auth)
      .send({ title: 'Khóa học thử nghiệm đã sửa', curriculumVersion: '1.1' });
    expect(edited.status).toBe(200);
    expect(edited.body.title).toBe('Khóa học thử nghiệm đã sửa');
    expect(edited.body.curriculumVersion).toBe('1.1');
    const draftCatalog = await request(server).get('/public/courses');
    expect(
      draftCatalog.body.some((item: { slug: string }) => item.slug === slug),
    ).toBe(false);

    const level = await request(server)
      .post(`/courses/${id}/levels`)
      .set('Authorization', auth)
      .send({
        code: 'CORE',
        name: 'Nền tảng',
        entryRequirements: 'Chưa cần nền tảng',
        expectedOutcomes: { summary: 'Giao tiếp cơ bản' },
        assessmentScheme: { components: 'Bài kiểm tra cuối khóa' },
        completionCriteria: 'Hoàn thành bài kiểm tra',
      });
    expect(level.status).toBe(201);
    const module = await request(server)
      .post(`/levels/${level.body.id}/modules`)
      .set('Authorization', auth)
      .send({ title: 'Giao tiếp' });
    expect(module.status).toBe(201);
    const lesson = await request(server)
      .post(`/modules/${module.body.id}/lessons`)
      .set('Authorization', auth)
      .send({
        title: 'Giới thiệu bản thân',
        content: 'Học từ vựng và hội thoại',
      });
    expect(lesson.status).toBe(201);
    const submitted = await request(server)
      .patch(`/courses/${id}/publication`)
      .set('Authorization', auth)
      .send({ status: 'IN_REVIEW' });
    expect(submitted.status).toBe(200);
    const blocked = await request(server)
      .patch(`/courses/${id}/publication`)
      .set('Authorization', auth)
      .send({ status: 'PUBLISHED' });
    expect(blocked.status).toBe(400);
    const review = await request(server)
      .post(`/courses/${id}/academic-review`)
      .set('Authorization', auth)
      .send({});
    expect(review.status).toBe(201);
    const check = await request(server)
      .get(`/courses/${id}/publication-check`)
      .set('Authorization', auth);
    expect(check.body.canPublish).toBe(true);
    const published = await request(server)
      .patch(`/courses/${id}/publication`)
      .set('Authorization', auth)
      .send({ status: 'PUBLISHED' });
    expect(published.status).toBe(200);
    const publishedCatalog = await request(server).get('/public/courses');
    expect(
      publishedCatalog.body.some(
        (item: { slug: string }) => item.slug === slug,
      ),
    ).toBe(true);
    const publicDetail = await request(server).get(`/public/courses/${slug}`);
    expect(publicDetail.status).toBe(200);
    expect(publicDetail.body.levels[0].modules[0].lessons[0].title).toBe(
      'Giới thiệu bản thân',
    );
    const unsafeEdit = await request(server)
      .patch(`/courses/${id}`)
      .set('Authorization', auth)
      .send({ title: 'Đổi sau công bố' });
    expect(unsafeEdit.status).toBe(409);
    const unpublished = await request(server)
      .patch(`/courses/${id}/publication`)
      .set('Authorization', auth)
      .send({ status: 'DRAFT' });
    expect(unpublished.status).toBe(200);
    const after = await request(server).get('/public/courses');
    expect(
      after.body.some((item: { slug: string }) => item.slug === slug),
    ).toBe(false);
  });
});
