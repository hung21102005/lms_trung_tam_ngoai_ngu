import 'dotenv/config';
import * as bcrypt from 'bcryptjs';
import {
  AssignmentType,
  AttendanceStatus,
  ClassStatus,
  EnrollmentStatus,
  Gender,
  PrismaClient,
  SessionStatus,
  SubmissionStatus,
  UserStatus,
} from '@prisma/client';

const prisma = new PrismaClient();
const demoPassword = process.env.DEMO_PASSWORD || 'Password@123';

function vietnamToday(): Date {
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone: 'Asia/Ho_Chi_Minh',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(new Date());
  const part = (type: string) =>
    Number(parts.find((item) => item.type === type)?.value);
  return new Date(Date.UTC(part('year'), part('month') - 1, part('day')));
}

function addDays(date: Date, days: number): Date {
  const result = new Date(date);
  result.setUTCDate(result.getUTCDate() + days);
  return result;
}

async function seedSessions(
  classId: string,
  startDate: Date,
  days: number[],
  count: number,
  startTime: string,
  endTime: string,
  roomId: string,
  teacherId: string,
  today: Date,
) {
  let date = new Date(startDate);
  for (let number = 1; number <= count;) {
    if (days.includes(date.getUTCDay())) {
      await prisma.classSession.upsert({
        where: { classId_sessionNumber: { classId, sessionNumber: number } },
        update: {},
        create: {
          classId,
          sessionNumber: number,
          title: `Buổi ${number}: ${number % 2 === 0 ? 'Luyện tập và phản hồi' : 'Kiến thức mới và thực hành'}`,
          date: new Date(date),
          startTime,
          endTime,
          roomId,
          teacherId,
          status:
            date < today ? SessionStatus.COMPLETED : SessionStatus.SCHEDULED,
        },
      });
      number++;
    }
    date = addDays(date, 1);
  }
}

async function main() {
  const today = vietnamToday();
  const passwordHash = await bcrypt.hash(demoPassword, 12);
  const [
    branch,
    roomIelts,
    roomComm,
    ieltsCourse,
    commCourse,
    teacher,
    studentRole,
    parentRole,
    teacherRole,
  ] = await Promise.all([
    prisma.branch.findUnique({ where: { code: 'BR-Q1' } }),
    prisma.room.findFirst({
      where: { code: 'P101', branch: { code: 'BR-Q1' } },
    }),
    prisma.room.findFirst({
      where: { code: 'LAB-01', branch: { code: 'BR-Q1' } },
    }),
    prisma.course.findUnique({ where: { code: 'ENG-IELTS' } }),
    prisma.course.findUnique({ where: { code: 'ENG-COMM' } }),
    prisma.user.findUnique({ where: { userCode: 'GV-0001' } }),
    prisma.role.findUnique({ where: { code: 'student' } }),
    prisma.role.findUnique({ where: { code: 'parent' } }),
    prisma.role.findUnique({ where: { code: 'teacher' } }),
  ]);
  if (
    !branch ||
    !roomIelts ||
    !roomComm ||
    !ieltsCourse ||
    !commCourse ||
    !teacher ||
    !studentRole ||
    !parentRole ||
    !teacherRole
  ) {
    throw new Error(
      'Thiếu dữ liệu nền. Chạy npm run seed trước khi chạy seed:learning-flow.',
    );
  }
  const [ieltsLevel, commLevel] = await Promise.all([
    prisma.courseLevel.findUnique({
      where: {
        courseId_code: { courseId: ieltsCourse.id, code: 'FOUNDATION' },
      },
    }),
    prisma.courseLevel.findUnique({
      where: { courseId_code: { courseId: commCourse.id, code: 'COMM-A1' } },
    }),
  ]);
  if (!ieltsLevel || !commLevel) throw new Error('Thiếu cấp độ khóa học nền.');

  const teacher2 = await prisma.user.upsert({
    where: { userCode: 'DEMO-GV-02' },
    update: {},
    create: {
      userCode: 'DEMO-GV-02',
      email: 'demo.teacher02@lms.example',
      fullName: 'Cô Phạm Thu Hà',
      passwordHash,
      gender: Gender.FEMALE,
      status: UserStatus.ACTIVE,
      isFirstLogin: false,
      branchId: branch.id,
      teacherProfile: {
        create: {
          specialties: 'Giao tiếp tiếng Anh A1–B1',
          degrees: 'Cử nhân Sư phạm Tiếng Anh',
        },
      },
    },
  });
  await prisma.userRole.upsert({
    where: { userId_roleId: { userId: teacher2.id, roleId: teacherRole.id } },
    update: {},
    create: { userId: teacher2.id, roleId: teacherRole.id },
  });

  const names = [
    'Nguyễn Minh Anh',
    'Trần Gia Bảo',
    'Lê Khánh Chi',
    'Phạm Quốc Đạt',
    'Hoàng Mỹ Duyên',
    'Vũ Thành Đạt',
    'Đỗ Hà Giang',
    'Bùi Đức Huy',
    'Đặng Thu Hương',
    'Ngô Nhật Khang',
    'Phan Minh Khoa',
    'Huỳnh Ngọc Lan',
    'Trịnh Gia Linh',
    'Mai Quang Minh',
    'Đinh Bảo Ngọc',
    'Cao Hoàng Phúc',
    'Lý Minh Quân',
    'Tạ Hồng Thảo',
    'Lâm Anh Thư',
    'Tô Hải Yến',
  ];
  const students = [];
  for (let index = 0; index < names.length; index++) {
    const number = String(index + 1).padStart(2, '0');
    const student = await prisma.user.upsert({
      where: { userCode: `DEMO-HV-${number}` },
      update: {},
      create: {
        userCode: `DEMO-HV-${number}`,
        email: `demo.student${number}@lms.example`,
        fullName: names[index],
        passwordHash,
        gender: index % 2 === 0 ? Gender.FEMALE : Gender.MALE,
        status: UserStatus.ACTIVE,
        isFirstLogin: false,
        branchId: branch.id,
        studentProfile: {
          create: {
            entryLevel: index < 12 ? 'IELTS 4.0' : 'A1',
            targetLevel: index < 12 ? 'IELTS 5.5' : 'A2',
          },
        },
      },
    });
    students.push(student);
    await prisma.userRole.upsert({
      where: { userId_roleId: { userId: student.id, roleId: studentRole.id } },
      update: {},
      create: { userId: student.id, roleId: studentRole.id },
    });
  }

  // Four one-child families and eight two-child families cover all 20 students.
  const familySizes = [1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2];
  let studentOffset = 0;
  for (let index = 0; index < familySizes.length; index++) {
    const number = String(index + 1).padStart(2, '0');
    const parent = await prisma.user.upsert({
      where: { userCode: `DEMO-PH-${number}` },
      update: {},
      create: {
        userCode: `DEMO-PH-${number}`,
        email: `demo.parent${number}@lms.example`,
        fullName: `Phụ huynh gia đình ${number}`,
        passwordHash,
        status: UserStatus.ACTIVE,
        isFirstLogin: false,
        branchId: branch.id,
      },
    });
    await prisma.userRole.upsert({
      where: { userId_roleId: { userId: parent.id, roleId: parentRole.id } },
      update: {},
      create: { userId: parent.id, roleId: parentRole.id },
    });
    for (let child = 0; child < familySizes[index]; child++) {
      const student = students[studentOffset++];
      await prisma.parentStudent.upsert({
        where: {
          parentId_studentId: { parentId: parent.id, studentId: student.id },
        },
        update: {},
        create: {
          parentId: parent.id,
          studentId: student.id,
          relationship: 'Người giám hộ',
          isPrimaryContact: true,
        },
      });
    }
  }

  const startDate = addDays(today, -14);
  const classIelts = await prisma.class.upsert({
    where: { code: 'DEMO-IELTS-2026' },
    update: {},
    create: {
      code: 'DEMO-IELTS-2026',
      name: 'Lớp IELTS Foundation – Nhóm A',
      courseId: ieltsCourse.id,
      levelId: ieltsLevel.id,
      branchId: branch.id,
      roomId: roomIelts.id,
      mainTeacherId: teacher.id,
      status: ClassStatus.IN_PROGRESS,
      startDate,
      scheduleDays: ['MONDAY', 'WEDNESDAY', 'FRIDAY'],
      startTime: '16:00',
      endTime: '17:30',
      totalSessions: 24,
      maxCapacity: 20,
      tuitionFee: 6500000,
    },
  });
  const classComm = await prisma.class.upsert({
    where: { code: 'DEMO-COMM-2026' },
    update: {},
    create: {
      code: 'DEMO-COMM-2026',
      name: 'Lớp Giao tiếp A1 – Nhóm B',
      courseId: commCourse.id,
      levelId: commLevel.id,
      branchId: branch.id,
      roomId: roomComm.id,
      mainTeacherId: teacher2.id,
      status: ClassStatus.IN_PROGRESS,
      startDate,
      scheduleDays: ['TUESDAY', 'THURSDAY', 'SATURDAY'],
      startTime: '18:00',
      endTime: '19:30',
      totalSessions: 20,
      maxCapacity: 20,
      tuitionFee: 4500000,
    },
  });

  for (let index = 0; index < students.length; index++) {
    const classId = index < 12 ? classIelts.id : classComm.id;
    await prisma.classStudent.upsert({
      where: { classId_studentId: { classId, studentId: students[index].id } },
      update: {},
      create: {
        classId,
        studentId: students[index].id,
        status: EnrollmentStatus.ENROLLED,
      },
    });
  }
  await seedSessions(
    classIelts.id,
    classIelts.startDate,
    [1, 3, 5],
    24,
    '16:00',
    '17:30',
    roomIelts.id,
    teacher.id,
    today,
  );
  await seedSessions(
    classComm.id,
    classComm.startDate,
    [2, 4, 6],
    20,
    '18:00',
    '19:30',
    roomComm.id,
    teacher2.id,
    today,
  );

  const assignmentSpecs = [
    {
      classId: classIelts.id,
      creatorId: teacher.id,
      title: 'Writing Task 1 – My hometown',
      type: AssignmentType.WRITING,
      days: 5,
    },
    {
      classId: classIelts.id,
      creatorId: teacher.id,
      title: 'Speaking – Self introduction',
      type: AssignmentType.SPEAKING,
      days: 3,
    },
    {
      classId: classComm.id,
      creatorId: teacher2.id,
      title: 'Daily conversation practice',
      type: AssignmentType.HOMEWORK,
      days: 4,
    },
  ];
  const assignments = [];
  for (const spec of assignmentSpecs) {
    let assignment = await prisma.assignment.findFirst({
      where: { classId: spec.classId, title: spec.title },
    });
    if (!assignment) {
      assignment = await prisma.assignment.create({
        data: {
          classId: spec.classId,
          createdById: spec.creatorId,
          title: spec.title,
          description: `Hoàn thành ${spec.title} và nộp bài trước hạn. Giáo viên sẽ chấm điểm và nhận xét.`,
          type: spec.type,
          deadline: addDays(today, spec.days),
          maxScore: 10,
        },
      });
    }
    assignments.push(assignment);
  }
  for (let index = 0; index < 3; index++) {
    await prisma.submission.upsert({
      where: {
        assignmentId_studentId: {
          assignmentId: assignments[0].id,
          studentId: students[index].id,
        },
      },
      update: {},
      create: {
        assignmentId: assignments[0].id,
        studentId: students[index].id,
        content: `My hometown is a lively city. This is a sample essay by ${names[index]}.`,
        status:
          index === 0 ? SubmissionStatus.GRADED : SubmissionStatus.SUBMITTED,
        ...(index === 0
          ? {
              score: 8.5,
              feedback: 'Bố cục rõ ràng; cần mở rộng vốn từ.',
              gradedById: teacher.id,
              gradedAt: new Date(),
            }
          : {}),
      },
    });
  }

  for (const [classItem, classStudents, marker] of [
    [classIelts, students.slice(0, 12), teacher],
    [classComm, students.slice(12), teacher2],
  ] as const) {
    const past = await prisma.classSession.findFirst({
      where: { classId: classItem.id, date: { lt: today } },
      orderBy: { date: 'desc' },
    });
    if (!past) continue;
    for (let index = 0; index < classStudents.length; index++) {
      const status =
        index === 0
          ? AttendanceStatus.ABSENT
          : index === 1
            ? AttendanceStatus.LATE
            : AttendanceStatus.PRESENT;
      await prisma.attendance.upsert({
        where: {
          sessionId_studentId: {
            sessionId: past.id,
            studentId: classStudents[index].id,
          },
        },
        update: {},
        create: {
          sessionId: past.id,
          studentId: classStudents[index].id,
          status,
          markedById: marker.id,
          notes:
            status === AttendanceStatus.ABSENT ? 'Vắng buổi học' : undefined,
        },
      });
    }
  }

  console.log(
    JSON.stringify(
      {
        students: students.length,
        teachers: [teacher.userCode, teacher2.userCode],
        parents: familySizes.length,
        oneChildFamilies: familySizes.filter((size) => size === 1).length,
        twoChildFamilies: familySizes.filter((size) => size === 2).length,
        classes: [classIelts.code, classComm.code],
        assignments: assignments.length,
        demoPasswordSource: process.env.DEMO_PASSWORD
          ? 'DEMO_PASSWORD'
          : 'local default',
      },
      null,
      2,
    ),
  );
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
