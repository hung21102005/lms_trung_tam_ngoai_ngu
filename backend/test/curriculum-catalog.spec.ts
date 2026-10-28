import { describe, expect, it } from 'vitest';
import type { PrismaClient } from '@prisma/client';
import { curriculumCatalog } from '../prisma/curriculum-catalog.data.js';
import { seedCurriculumCatalog } from '../prisma/seed-curriculum-catalog.js';

describe('curriculum catalog', () => {
  it('has distinct programs and 47 substantially described draft courses', () => {
    expect(curriculumCatalog).toHaveLength(7);
    const programCodes = curriculumCatalog.map((program) => program.code);
    const courses = curriculumCatalog.flatMap((program) => program.courses);
    expect(new Set(programCodes).size).toBe(programCodes.length);
    expect(courses).toHaveLength(47);
    expect(new Set(courses.map((course) => course.code)).size).toBe(
      courses.length,
    );
    for (const course of courses) {
      expect(course.entry.length).toBeGreaterThan(20);
      expect(course.outcome.length).toBeGreaterThan(20);
      expect(course.units).toHaveLength(4);
      expect(new Set(course.units).size).toBe(4);
      expect(course.hours).toBeGreaterThan(0);
    }
    expect(
      courses.find((course) => course.code === 'CAT-IELTS-65')?.ieltsBand,
    ).toBe(6.5);
    expect(
      courses.find((course) => course.code === 'CAT-TOEIC-650')?.toeicScore,
    ).toBe(650);
  });

  it('creates only missing drafts and leaves Admin edits untouched on rerun', async () => {
    const programs = new Map<
      string,
      { id: string; code: string; nameVi: string }
    >();
    const courses = new Map<
      string,
      { code: string; title: string; data: unknown }
    >();
    const fake = {
      trainingProgram: {
        findUnique: async ({ where }: { where: { code: string } }) =>
          programs.get(where.code) ?? null,
        create: async ({
          data,
        }: {
          data: { code: string; nameVi: string };
        }) => {
          const program = {
            id: data.code,
            code: data.code,
            nameVi: data.nameVi,
          };
          programs.set(data.code, program);
          return program;
        },
      },
      course: {
        findUnique: async ({ where }: { where: { code: string } }) =>
          courses.get(where.code) ?? null,
        create: async ({
          data,
        }: {
          data: {
            code: string;
            title: string;
            levels: unknown;
            publicationStatus: string;
            isActive: boolean;
          };
        }) => {
          expect(data.publicationStatus).toBe('DRAFT');
          expect(data.isActive).toBe(false);
          expect(data.levels).toBeDefined();
          const course = { code: data.code, title: data.title, data };
          courses.set(data.code, course);
          return course;
        },
      },
    } as unknown as PrismaClient;

    const first = await seedCurriculumCatalog(fake);
    expect(first).toMatchObject({
      programsCreated: 7,
      coursesCreated: 47,
      levelsCreated: 47,
      modulesCreated: 94,
      lessonsCreated: 188,
    });
    const existing = courses.get('CAT-GEN-A1')!;
    existing.title = 'Admin edited title';
    const second = await seedCurriculumCatalog(fake);
    expect(second).toMatchObject({
      programsCreated: 0,
      programsSkipped: 7,
      coursesCreated: 0,
      coursesSkipped: 47,
    });
    expect(courses.get('CAT-GEN-A1')?.title).toBe('Admin edited title');
    expect(programs.size).toBe(7);
    expect(courses.size).toBe(47);
  });
});
