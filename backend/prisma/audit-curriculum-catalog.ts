import 'dotenv/config';
import { PrismaClient, PublicationStatus } from '@prisma/client';
import { curriculumCatalog } from './curriculum-catalog.data.js';

type CatalogDatabase = Pick<PrismaClient, 'trainingProgram' | 'course'>;

/** Read-only structural audit. Academic quality still requires human review. */
export async function auditCurriculumCatalog(prisma: CatalogDatabase) {
  const programCodes = curriculumCatalog.map((program) => program.code);
  const courseCodes = curriculumCatalog.flatMap((program) =>
    program.courses.map((course) => course.code),
  );
  const [programs, courses] = await Promise.all([
    prisma.trainingProgram.findMany({
      where: { code: { in: programCodes } },
      select: { code: true, status: true, isPublic: true },
    }),
    prisma.course.findMany({
      where: { code: { in: courseCodes } },
      select: {
        code: true,
        publicationStatus: true,
        isActive: true,
        program: { select: { code: true } },
        academicProfile: true,
        levels: {
          select: {
            entryRequirements: true,
            expectedOutcomes: true,
            assessmentScheme: true,
            completionCriteria: true,
            modules: {
              select: { lessons: { select: { content: true } } },
            },
          },
        },
      },
    }),
  ]);

  const foundPrograms = new Set(programs.map((program) => program.code));
  const foundCourses = new Set(courses.map((course) => course.code));
  const expectedProgramByCourse = new Map(
    curriculumCatalog.flatMap((program) =>
      program.courses.map((course) => [course.code, program.code] as const),
    ),
  );
  const issues: string[] = [];
  for (const code of programCodes) {
    if (!foundPrograms.has(code)) issues.push(`Thiếu chương trình ${code}`);
  }
  for (const code of courseCodes) {
    if (!foundCourses.has(code)) issues.push(`Thiếu khóa ${code}`);
  }
  for (const program of programs) {
    if (program.status !== PublicationStatus.DRAFT || program.isPublic) {
      issues.push(
        `Chương trình seed ${program.code} đã công bố hoặc hiển thị công khai`,
      );
    }
  }
  let pendingAcademicReview = 0;
  for (const course of courses) {
    if (
      course.publicationStatus !== PublicationStatus.DRAFT ||
      course.isActive
    ) {
      issues.push(`Khóa seed ${course.code} đã kích hoạt hoặc công bố`);
    }
    if (course.program?.code !== expectedProgramByCourse.get(course.code)) {
      issues.push(`Khóa ${course.code} không thuộc đúng chương trình seed`);
    }
    if (course.levels.length === 0) {
      issues.push(`Khóa ${course.code} thiếu cấp độ`);
    }
    const profile = course.academicProfile;
    if (
      profile &&
      typeof profile === 'object' &&
      !Array.isArray(profile) &&
      'reviewRequired' in profile &&
      profile.reviewRequired === true
    ) {
      pendingAcademicReview++;
    }
    for (const level of course.levels) {
      if (
        !level.entryRequirements?.trim() ||
        !level.expectedOutcomes ||
        !level.assessmentScheme ||
        !level.completionCriteria?.trim() ||
        level.modules.length === 0 ||
        level.modules.some(
          (module) =>
            module.lessons.length === 0 ||
            module.lessons.some((lesson) => !lesson.content?.trim()),
        )
      ) {
        issues.push(`Khóa ${course.code} thiếu cấu trúc học thuật`);
      }
    }
  }
  return {
    expectedPrograms: programCodes.length,
    foundPrograms: programs.length,
    expectedCourses: courseCodes.length,
    foundCourses: courses.length,
    pendingAcademicReview,
    issues,
  };
}

if (process.argv[1]?.endsWith('audit-curriculum-catalog.ts')) {
  const prisma = new PrismaClient();
  auditCurriculumCatalog(prisma)
    .then((report) => {
      console.log(JSON.stringify(report, null, 2));
      if (report.issues.length > 0) process.exitCode = 1;
    })
    .catch((error: unknown) => {
      console.error(error);
      process.exitCode = 1;
    })
    .finally(() => prisma.$disconnect());
}
