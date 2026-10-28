import { PrismaClient, PublicationStatus } from '@prisma/client';
import { curriculumCatalog } from './curriculum-catalog.data.js';

export interface CatalogSeedReport {
  programsCreated: number;
  programsSkipped: number;
  coursesCreated: number;
  coursesSkipped: number;
  levelsCreated: number;
  modulesCreated: number;
  lessonsCreated: number;
}

/** Creates draft catalog records only. Existing records are never updated or deleted. */
export async function seedCurriculumCatalog(
  prisma: PrismaClient,
): Promise<CatalogSeedReport> {
  const report: CatalogSeedReport = {
    programsCreated: 0,
    programsSkipped: 0,
    coursesCreated: 0,
    coursesSkipped: 0,
    levelsCreated: 0,
    modulesCreated: 0,
    lessonsCreated: 0,
  };

  for (const [programIndex, programSeed] of curriculumCatalog.entries()) {
    let program = await prisma.trainingProgram.findUnique({
      where: { code: programSeed.code },
    });
    if (program) {
      report.programsSkipped++;
    } else {
      program = await prisma.trainingProgram.create({
        data: {
          code: programSeed.code,
          slug: programSeed.slug,
          nameVi: programSeed.nameVi,
          nameEn: programSeed.nameEn,
          category: programSeed.category,
          description: `Lộ trình ${programSeed.nameVi} do EduLMS biên soạn và chờ duyệt học thuật.`,
          targetAudience: programSeed.audience,
          learningPath: programSeed.courses.map((course) => course.code),
          language: 'English',
          status: PublicationStatus.DRAFT,
          isPublic: false,
          displayOrder: programIndex + 1,
        },
      });
      report.programsCreated++;
    }

    for (const [courseIndex, courseSeed] of programSeed.courses.entries()) {
      const existing = await prisma.course.findUnique({
        where: { code: courseSeed.code },
      });
      if (existing) {
        report.coursesSkipped++;
        continue;
      }

      const modules = [0, 1].map((moduleIndex) => ({
        title: `Học phần ${moduleIndex + 1}: ${courseSeed.units[moduleIndex * 2]}`,
        order: moduleIndex + 1,
        description: `Mục tiêu: ${courseSeed.outcome}`,
        lessons: {
          create: [0, 1].map((lessonIndex) => {
            const unitIndex = moduleIndex * 2 + lessonIndex;
            return {
              title: `Bài ${unitIndex + 1}: ${courseSeed.units[unitIndex]}`,
              order: lessonIndex + 1,
              content: `Chủ đề: ${courseSeed.units[unitIndex]}. Kết quả mong đợi: ${courseSeed.outcome} Hoạt động: thực hành có hướng dẫn, phản hồi và tự đánh giá.`,
              durationMinutes: 90,
            };
          }),
        },
      }));

      await prisma.course.create({
        data: {
          code: courseSeed.code,
          title: courseSeed.nameVi,
          description: `${courseSeed.nameEn}. ${courseSeed.outcome}`,
          targetAudience: programSeed.audience,
          language: 'English',
          isActive: false,
          programId: program.id,
          slug: courseSeed.code.toLowerCase(),
          publicationStatus: PublicationStatus.DRAFT,
          curriculumVersion: '1.0',
          publicDescription: `${courseSeed.nameVi}: ${courseSeed.outcome}`,
          academicProfile: {
            nameEn: courseSeed.nameEn,
            category: programSeed.category,
            skills: programSeed.skills,
            entryRequirements: courseSeed.entry,
            expectedOutcome: courseSeed.outcome,
            recommendedHours: courseSeed.hours,
            teachingMethod:
              'Thực hành có hướng dẫn, phản hồi cá nhân và tự học theo nhiệm vụ.',
            assessment: programSeed.assessment,
            completionCriteria:
              'Hoàn thành các bài học và đạt yêu cầu đánh giá nội bộ do Admin phê duyệt.',
            curriculumVersion: '1.0',
            reviewRequired: true,
          },
          levels: {
            create: {
              code: 'CORE',
              name: courseSeed.nameVi,
              description: courseSeed.outcome,
              order: courseIndex + 1,
              estimatedSessions: Math.ceil(courseSeed.hours / 1.5),
              cefrLevel: courseSeed.cefr,
              ieltsTargetBand: courseSeed.ieltsBand,
              toeicTargetScore: courseSeed.toeicScore,
              cambridgeQualification: courseSeed.cambridge,
              entryRequirements: courseSeed.entry,
              expectedOutcomes: {
                summary: courseSeed.outcome,
                skills: programSeed.skills,
              },
              assessmentScheme: { components: programSeed.assessment },
              completionCriteria:
                'Đạt yêu cầu đánh giá nội bộ và hoàn thành hoạt động học tập.',
              recommendedHours: courseSeed.hours,
              curriculumVersion: '1.0',
              modules: { create: modules },
            },
          },
        },
      });
      report.coursesCreated++;
      report.levelsCreated++;
      report.modulesCreated += 2;
      report.lessonsCreated += 4;
    }
  }

  return report;
}

if (process.argv[1]?.endsWith('seed-curriculum-catalog.ts')) {
  const prisma = new PrismaClient();
  seedCurriculumCatalog(prisma)
    .then((report) => console.log(JSON.stringify(report, null, 2)))
    .catch((error: unknown) => {
      console.error(error);
      process.exitCode = 1;
    })
    .finally(() => prisma.$disconnect());
}
