// Run after `npm run seed:learning-flow` with the API running (default PORT=3000).
import 'dotenv/config';
import assert from 'node:assert/strict';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();
const base = process.env.SMOKE_API_URL || 'http://localhost:3000/api/v1';
const password = process.env.DEMO_PASSWORD || 'Password@123';
const adminPassword = process.env.SMOKE_ADMIN_PASSWORD || 'Admin@123456';
let temporaryAssignmentId;
let enrollmentFixture;
let restoredAttendance;
let originalStatus;
let notificationIds = [];
let notificationSnapshotTaken = false;

async function request(path, token, method = 'GET', body, expected = 200) {
  const response = await fetch(`${base}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
  const payload = await response.json();
  assert.equal(
    response.status,
    expected,
    `${method} ${path}: ${payload.message ?? 'unexpected response'}`,
  );
  return payload.data;
}

async function login(code, accountPassword = password) {
  const data = await request('/auth/login', null, 'POST', {
    identifier: code,
    password: accountPassword,
  });
  assert.ok(data.accessToken, `${code} did not receive an access token`);
  return data;
}

async function main() {
  const [
    classIelts,
    classComm,
    studentOne,
    studentFive,
    studentThirteen,
    parentFive,
  ] = await Promise.all([
    prisma.class.findUniqueOrThrow({ where: { code: 'DEMO-IELTS-2026' } }),
    prisma.class.findUniqueOrThrow({ where: { code: 'DEMO-COMM-2026' } }),
    prisma.user.findUniqueOrThrow({ where: { userCode: 'DEMO-HV-01' } }),
    prisma.user.findUniqueOrThrow({ where: { userCode: 'DEMO-HV-05' } }),
    prisma.user.findUniqueOrThrow({ where: { userCode: 'DEMO-HV-13' } }),
    prisma.user.findUniqueOrThrow({ where: { userCode: 'DEMO-PH-05' } }),
  ]);
  const [
    admin,
    teacher,
    teacherOther,
    learner,
    unrelatedLearner,
    guardianOne,
    guardianTwo,
  ] = await Promise.all([
    login('AD-000001', adminPassword),
    login('GV-0001'),
    login('DEMO-GV-02'),
    login('DEMO-HV-05'),
    login('DEMO-HV-13'),
    login('DEMO-PH-01'),
    login('DEMO-PH-05'),
  ]);

  const teacherClasses = await request('/my/classes', teacher.accessToken);
  assert.ok(teacherClasses.some((item) => item.id === classIelts.id));
  assert.ok(!teacherClasses.some((item) => item.id === classComm.id));
  const studentClasses = await request('/my/classes', learner.accessToken);
  assert.ok(studentClasses.some((item) => item.id === classIelts.id));
  const oneChildClasses = await request('/my/classes', guardianOne.accessToken);
  assert.deepEqual(
    [
      ...new Set(
        oneChildClasses.flatMap((item) =>
          item.students.map((student) => student.studentId),
        ),
      ),
    ],
    [studentOne.id],
  );
  const twoChildClasses = await request('/my/classes', guardianTwo.accessToken);
  assert.equal(
    new Set(
      twoChildClasses.flatMap((item) =>
        item.students.map((student) => student.studentId),
      ),
    ).size,
    2,
  );
  await request(
    `/classes/${classIelts.id}`,
    unrelatedLearner.accessToken,
    'GET',
    null,
    403,
  );
  await request(
    `/classes/${classIelts.id}`,
    teacherOther.accessToken,
    'GET',
    null,
    403,
  );
  const ownClass = await request(
    `/classes/${classIelts.id}`,
    learner.accessToken,
  );
  assert.deepEqual(
    ownClass.students.map((item) => item.studentId),
    [studentFive.id],
  );
  const guardianClass = await request(
    `/classes/${classIelts.id}`,
    guardianTwo.accessToken,
  );
  assert.equal(guardianClass.students.length, 2);
  const outsiderList = await request(
    '/classes?page=1&limit=10',
    unrelatedLearner.accessToken,
  );
  assert.ok(!outsiderList.items.some((item) => item.id === classIelts.id));
  await request(
    `/classes/${classIelts.id}/sessions`,
    unrelatedLearner.accessToken,
    'GET',
    null,
    403,
  );

  const assignments = await request(
    `/classes/${classIelts.id}/assignments`,
    learner.accessToken,
  );
  assert.ok(assignments.length >= 2);
  await request(
    `/classes/${classIelts.id}/assignments`,
    unrelatedLearner.accessToken,
    'GET',
    null,
    403,
  );
  await request(
    `/classes/${classIelts.id}/assignments`,
    teacherOther.accessToken,
    'GET',
    null,
    403,
  );

  const created = await request(
    `/classes/${classIelts.id}/assignments`,
    teacher.accessToken,
    'POST',
    {
      title: `Smoke check ${Date.now()}`,
      description: 'Kiểm thử vòng đời tạo, nộp và chấm bài',
      maxScore: 10,
    },
    201,
  );
  temporaryAssignmentId = created.id;
  await request(
    `/assignments/${created.id}/submit`,
    unrelatedLearner.accessToken,
    'POST',
    {
      content: 'Outside class',
    },
    403,
  );
  const submitted = await request(
    `/assignments/${created.id}/submit`,
    learner.accessToken,
    'POST',
    {
      content: 'My short essay for the smoke test.',
    },
    201,
  );
  assert.equal(submitted.studentId, studentFive.id);
  const graded = await request(
    `/submissions/${submitted.id}/grade`,
    teacher.accessToken,
    'PATCH',
    {
      score: 8.5,
      feedback: 'Bố cục rõ ràng',
    },
  );
  assert.equal(Number(graded.score), 8.5);
  await request(
    `/assignments/${created.id}/submit`,
    learner.accessToken,
    'POST',
    {
      content: 'Should not overwrite graded submission.',
    },
    400,
  );

  const session = await prisma.classSession.findFirstOrThrow({
    where: {
      classId: classIelts.id,
      attendances: { some: { studentId: studentFive.id } },
    },
  });
  const roster = await request(
    `/sessions/${session.id}/attendance`,
    teacher.accessToken,
  );
  assert.equal(roster.summary.totalEnrolled, 12);
  await request(
    `/sessions/${session.id}/attendance`,
    teacherOther.accessToken,
    'GET',
    null,
    403,
  );
  await request(
    `/sessions/${session.id}/attendance`,
    teacherOther.accessToken,
    'POST',
    {
      students: [{ studentId: studentFive.id, status: 'ABSENT' }],
    },
    403,
  );
  await request(
    `/sessions/${session.id}/attendance`,
    teacher.accessToken,
    'POST',
    {
      students: [{ studentId: studentThirteen.id, status: 'PRESENT' }],
    },
    403,
  );
  restoredAttendance = await prisma.attendance.findUniqueOrThrow({
    where: {
      sessionId_studentId: { sessionId: session.id, studentId: studentFive.id },
    },
  });
  originalStatus = restoredAttendance.status;
  notificationIds = (
    await prisma.notification.findMany({
      where: { userId: { in: [studentFive.id, parentFive.id] } },
      select: { id: true },
    })
  ).map((item) => item.id);
  notificationSnapshotTaken = true;
  await request(
    `/attendance/${restoredAttendance.id}`,
    teacher.accessToken,
    'PATCH',
    {
      status: 'ABSENT',
      notes: 'Kiểm thử thông báo',
    },
  );
  const studentHistory = await request(
    `/students/${studentFive.id}/attendance`,
    learner.accessToken,
  );
  assert.ok(studentHistory.summary.absent >= 1);
  const parentHistory = await request(
    `/students/${studentFive.id}/attendance`,
    guardianTwo.accessToken,
  );
  assert.equal(parentHistory.student.id, studentFive.id);
  await request(
    `/students/${studentFive.id}/attendance`,
    guardianOne.accessToken,
    'GET',
    null,
    403,
  );
  const newNotifications = await prisma.notification.findMany({
    where: {
      userId: { in: [studentFive.id, parentFive.id] },
      id: { notIn: notificationIds },
    },
  });
  assert.ok(newNotifications.some((item) => item.userId === studentFive.id));
  assert.ok(newNotifications.some((item) => item.userId === parentFive.id));

  const schedule = await request('/my/schedule', guardianTwo.accessToken);
  assert.ok(schedule.some((item) => item.classId === classIelts.id));
  enrollmentFixture = {
    classId: classIelts.id,
    studentId: studentThirteen.id,
    invoiceIds: (
      await prisma.invoice.findMany({
        where: { classId: classIelts.id, studentId: studentThirteen.id },
        select: { id: true },
      })
    ).map((item) => item.id),
  };
  const enrolled = await request(
    `/classes/${classIelts.id}/students`,
    admin.accessToken,
    'POST',
    {
      studentId: 'DEMO-HV-13',
    },
    201,
  );
  assert.equal(enrolled.studentId, studentThirteen.id);
  await request(
    `/classes/${classIelts.id}/students/${studentThirteen.id}`,
    admin.accessToken,
    'DELETE',
  );
  console.log(
    'PASS: login, class membership, parent 1/2 children, enrollment by code, assignment create/submit/grade, attendance, absence alerts, schedule, access control',
  );
}

try {
  await main();
} finally {
  if (restoredAttendance && originalStatus) {
    await prisma.attendance.update({
      where: { id: restoredAttendance.id },
      data: {
        status: originalStatus,
        checkInTime: restoredAttendance.checkInTime,
        notes: restoredAttendance.notes,
        markedById: restoredAttendance.markedById,
        markedAt: restoredAttendance.markedAt,
      },
    });
    if (notificationSnapshotTaken) {
      await prisma.notification.deleteMany({
        where: {
          userId: {
            in: [
              restoredAttendance.studentId,
              (
                await prisma.user.findUniqueOrThrow({
                  where: { userCode: 'DEMO-PH-05' },
                })
              ).id,
            ],
          },
          id: { notIn: notificationIds },
          type: 'ATTENDANCE',
        },
      });
    }
  }
  if (temporaryAssignmentId) {
    await prisma.submission.deleteMany({
      where: { assignmentId: temporaryAssignmentId },
    });
    await prisma.assignment.delete({ where: { id: temporaryAssignmentId } });
  }
  if (enrollmentFixture) {
    await prisma.classStudent.deleteMany({
      where: {
        classId: enrollmentFixture.classId,
        studentId: enrollmentFixture.studentId,
      },
    });
    await prisma.invoice.deleteMany({
      where: {
        classId: enrollmentFixture.classId,
        studentId: enrollmentFixture.studentId,
        id: { notIn: enrollmentFixture.invoiceIds },
      },
    });
  }
  await prisma.$disconnect();
}
