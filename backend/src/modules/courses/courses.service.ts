import {
  Injectable,
  NotFoundException,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import { ClassStatus, PublicationStatus } from '@prisma/client';
import { PrismaService } from '../../database/prisma.service.js';
import {
  CreateCourseDto,
  UpdateCourseDto,
  CreateCourseLevelDto,
  UpdateCourseLevelDto,
  CreateModuleDto,
  UpdateModuleDto,
  CreateLessonDto,
  UpdateLessonDto,
  CreateLessonMaterialDto,
  QueryCoursesDto,
  CreateProgramDto,
  UpdateProgramDto,
} from './dto/index.js';

@Injectable()
export class CoursesService {
  constructor(private readonly prisma: PrismaService) {}

  private async assertCurriculumEditable(
    courseId: string,
    status?: PublicationStatus,
  ) {
    if (status === PublicationStatus.PUBLISHED ||
        status === PublicationStatus.ARCHIVED) {
      throw new ConflictException(
        'Cần ngừng công bố khóa học trước khi sửa nội dung học thuật',
      );
    }
    const protectedClasses = await this.prisma.class.count({
      where: {
        courseId,
        status: {
          in: [
            ClassStatus.OPEN_FOR_ENROLLMENT,
            ClassStatus.IN_PROGRESS,
            ClassStatus.COMPLETED,
          ],
        },
      },
    });
    if (protectedClasses > 0) {
      throw new ConflictException(
        'Khóa học đã có lớp mở hoặc từng giảng dạy; cần tạo phiên bản học thuật mới trước khi sửa giáo trình',
      );
    }
  }

  findPublicPrograms() {
    return this.prisma.trainingProgram.findMany({
      where: { status: PublicationStatus.PUBLISHED, isPublic: true },
      orderBy: [{ displayOrder: 'asc' }, { nameVi: 'asc' }],
      select: {
        id: true,
        code: true,
        slug: true,
        nameVi: true,
        nameEn: true,
        category: true,
        description: true,
        targetAudience: true,
        learningPath: true,
        thumbnailUrl: true,
      },
    });
  }

  findPublicCourses() {
    return this.prisma.course.findMany({
      where: {
        publicationStatus: PublicationStatus.PUBLISHED,
        isActive: true,
        slug: { not: null },
        program: { status: PublicationStatus.PUBLISHED, isPublic: true },
      },
      orderBy: { title: 'asc' },
      select: {
        id: true,
        code: true,
        slug: true,
        title: true,
        publicDescription: true,
        targetAudience: true,
        thumbnailUrl: true,
        program: { select: { slug: true, nameVi: true } },
        levels: {
          orderBy: { order: 'asc' },
          select: {
            id: true,
            code: true,
            name: true,
            cefrLevel: true,
            ieltsTargetBand: true,
            toeicTargetScore: true,
            cambridgeQualification: true,
            recommendedHours: true,
          },
        },
      },
    });
  }

  async findPublicCourse(slug: string) {
    const course = await this.prisma.course.findFirst({
      where: {
        slug,
        publicationStatus: PublicationStatus.PUBLISHED,
        isActive: true,
        program: { status: PublicationStatus.PUBLISHED, isPublic: true },
      },
      select: {
        id: true,
        code: true,
        slug: true,
        title: true,
        publicDescription: true,
        targetAudience: true,
        thumbnailUrl: true,
        program: { select: { slug: true, nameVi: true, nameEn: true } },
        levels: {
          orderBy: { order: 'asc' },
          select: {
            id: true,
            code: true,
            name: true,
            description: true,
            cefrLevel: true,
            ieltsTargetBand: true,
            toeicTargetScore: true,
            cambridgeQualification: true,
            entryRequirements: true,
            expectedOutcomes: true,
            assessmentScheme: true,
            completionCriteria: true,
            recommendedHours: true,
            modules: {
              orderBy: { order: 'asc' },
              select: {
                title: true,
                description: true,
                order: true,
                lessons: {
                  orderBy: { order: 'asc' },
                  select: { title: true, order: true },
                },
              },
            },
          },
        },
      },
    });
    if (!course)
      throw new NotFoundException('Không tìm thấy khóa học công khai');
    return course;
  }

  // --------------------------------------------------------------------------
  // TRAINING PROGRAMS — internal catalog and explicit publication workflow
  // --------------------------------------------------------------------------

  findPrograms() {
    return this.prisma.trainingProgram.findMany({
      orderBy: [{ displayOrder: 'asc' }, { nameVi: 'asc' }],
      include: { _count: { select: { courses: true } } },
    });
  }

  async findProgram(id: string) {
    const program = await this.prisma.trainingProgram.findUnique({
      where: { id },
      include: { courses: { orderBy: { title: 'asc' } } },
    });
    if (!program)
      throw new NotFoundException('Không tìm thấy chương trình đào tạo');
    return program;
  }

  async createProgram(dto: CreateProgramDto) {
    const existing = await this.prisma.trainingProgram.findFirst({
      where: { OR: [{ code: dto.code }, { slug: dto.slug }] },
    });
    if (existing)
      throw new ConflictException('Mã hoặc đường dẫn chương trình đã tồn tại');
    return this.prisma.trainingProgram.create({
      data: { ...dto, status: PublicationStatus.DRAFT, isPublic: false },
    });
  }

  async updateProgram(id: string, dto: UpdateProgramDto) {
    const program = await this.findProgram(id);
    if (program.status === PublicationStatus.ARCHIVED) {
      throw new BadRequestException(
        'Chương trình đã lưu trữ, không thể chỉnh sửa',
      );
    }
    if (dto.code || dto.slug) {
      const existing = await this.prisma.trainingProgram.findFirst({
        where: {
          id: { not: id },
          OR: [
            ...(dto.code ? [{ code: dto.code }] : []),
            ...(dto.slug ? [{ slug: dto.slug }] : []),
          ],
        },
      });
      if (existing)
        throw new ConflictException(
          'Mã hoặc đường dẫn chương trình đã tồn tại',
        );
    }
    return this.prisma.trainingProgram.update({ where: { id }, data: dto });
  }

  async changeProgramStatus(id: string, status: PublicationStatus) {
    const program = await this.findProgram(id);
    const allowed: Record<PublicationStatus, PublicationStatus[]> = {
      DRAFT: [PublicationStatus.IN_REVIEW],
      IN_REVIEW: [PublicationStatus.DRAFT, PublicationStatus.PUBLISHED],
      PUBLISHED: [PublicationStatus.ARCHIVED],
      ARCHIVED: [],
    };
    if (!allowed[program.status].includes(status)) {
      throw new BadRequestException(
        'Chuyển trạng thái chương trình không hợp lệ',
      );
    }
    if (
      status === PublicationStatus.PUBLISHED &&
      (!program.description?.trim() || !program.targetAudience?.trim())
    ) {
      throw new BadRequestException(
        'Cần mô tả và đối tượng học trước khi duyệt chương trình',
      );
    }
    if (
      status === PublicationStatus.ARCHIVED &&
      program.courses.some(
        (course) => course.publicationStatus === PublicationStatus.PUBLISHED,
      )
    ) {
      throw new BadRequestException(
        'Cần lưu trữ các khóa đang công bố trước khi lưu trữ chương trình',
      );
    }
    return this.prisma.trainingProgram.update({
      where: { id },
      data: {
        status,
        ...(status === PublicationStatus.ARCHIVED ? { isPublic: false } : {}),
      },
    });
  }

  async setProgramVisibility(id: string, isPublic: boolean) {
    const program = await this.findProgram(id);
    if (isPublic && program.status !== PublicationStatus.PUBLISHED) {
      throw new BadRequestException(
        'Chỉ chương trình đã duyệt mới được hiển thị công khai',
      );
    }
    return this.prisma.trainingProgram.update({
      where: { id },
      data: { isPublic },
    });
  }

  // --------------------------------------------------------------------------
  // COURSES
  // --------------------------------------------------------------------------

  async findAll(query: QueryCoursesDto) {
    const { page, limit, search, language, isActive } = query;
    const skip = (page - 1) * limit;

    const where: any = {};

    if (search) {
      where.OR = [
        { title: { contains: search, mode: 'insensitive' } },
        { code: { contains: search, mode: 'insensitive' } },
      ];
    }

    if (language) {
      where.language = language;
    }

    if (isActive !== undefined) {
      where.isActive = isActive;
    }

    const [items, total] = await Promise.all([
      this.prisma.course.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          _count: {
            select: {
              levels: true,
              classes: true,
            },
          },
        },
      }),
      this.prisma.course.count({ where }),
    ]);

    return {
      items,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async findOne(id: string) {
    const course = await this.prisma.course.findUnique({
      where: { id },
      include: {
        levels: {
          orderBy: { order: 'asc' },
          include: {
            modules: {
              orderBy: { order: 'asc' },
              include: {
                lessons: {
                  orderBy: { order: 'asc' },
                  include: {
                    materials: {
                      orderBy: { order: 'asc' },
                    },
                  },
                },
              },
            },
            _count: {
              select: {
                classes: true,
              },
            },
          },
        },
      },
    });

    if (!course) {
      throw new NotFoundException(`Không tìm thấy khóa học với ID: ${id}`);
    }

    return course;
  }

  async create(dto: CreateCourseDto) {
    const existing = await this.prisma.course.findUnique({
      where: { code: dto.code },
    });

    if (existing) {
      throw new ConflictException(
        `Mã khóa học '${dto.code}' đã tồn tại trên hệ thống`,
      );
    }

    if (dto.programId) {
      const program = await this.prisma.trainingProgram.findUnique({
        where: { id: dto.programId },
      });
      if (!program || program.status === PublicationStatus.ARCHIVED) {
        throw new BadRequestException(
          'Chương trình đào tạo không hợp lệ hoặc đã lưu trữ',
        );
      }
    }
    if (
      dto.slug &&
      (await this.prisma.course.findUnique({ where: { slug: dto.slug } }))
    ) {
      throw new ConflictException('Đường dẫn khóa học đã tồn tại');
    }

    return this.prisma.course.create({
      data: dto,
    });
  }

  async update(id: string, dto: UpdateCourseDto) {
    const course = await this.findOne(id);
    const academicFields = [
      'code',
      'title',
      'slug',
      'programId',
      'description',
      'targetAudience',
      'language',
      'publicDescription',
    ] as const;
    if (academicFields.some((field) =>
      dto[field] !== undefined && dto[field] !== course[field],
    )) {
      await this.assertCurriculumEditable(id, course.publicationStatus);
    }

    if (dto.code) {
      const existing = await this.prisma.course.findUnique({
        where: { code: dto.code },
      });

      if (existing && existing.id !== id) {
        throw new ConflictException(
          `Mã khóa học '${dto.code}' đã được sử dụng`,
        );
      }
    }

    if (dto.programId) {
      const program = await this.prisma.trainingProgram.findUnique({
        where: { id: dto.programId },
      });
      if (!program || program.status === PublicationStatus.ARCHIVED) {
        throw new BadRequestException(
          'Chương trình đào tạo không hợp lệ hoặc đã lưu trữ',
        );
      }
    }
    if (dto.slug) {
      const existing = await this.prisma.course.findUnique({
        where: { slug: dto.slug },
      });
      if (existing && existing.id !== id) {
        throw new ConflictException('Đường dẫn khóa học đã tồn tại');
      }
    }

    return this.prisma.course.update({
      where: { id },
      data: dto,
    });
  }

  async changeCourseStatus(id: string, status: PublicationStatus) {
    const course = await this.findOne(id);
    const allowed: Record<PublicationStatus, PublicationStatus[]> = {
      DRAFT: [PublicationStatus.IN_REVIEW],
      IN_REVIEW: [PublicationStatus.DRAFT, PublicationStatus.PUBLISHED],
      PUBLISHED: [PublicationStatus.DRAFT, PublicationStatus.ARCHIVED],
      ARCHIVED: [],
    };
    if (!allowed[course.publicationStatus].includes(status)) {
      throw new BadRequestException('Chuyển trạng thái khóa học không hợp lệ');
    }
    if (
      status === PublicationStatus.DRAFT &&
      course.publicationStatus === PublicationStatus.PUBLISHED
    ) {
      const activeClasses = await this.prisma.class.count({
        where: {
          courseId: id,
          status: {
            in: [ClassStatus.OPEN_FOR_ENROLLMENT, ClassStatus.IN_PROGRESS],
          },
        },
      });
      if (activeClasses > 0) {
        throw new ConflictException(
          'Cần đóng đăng ký và kết thúc lớp đang học trước khi ngừng công bố khóa',
        );
      }
    }
    if (status === PublicationStatus.PUBLISHED) {
      if (
        !course.programId ||
        !course.isActive ||
        !course.description?.trim() ||
        !course.publicDescription?.trim() ||
        !course.levels.some((level) =>
          level.modules.some((mod) => mod.lessons.length > 0),
        )
      ) {
        throw new BadRequestException(
          'Khóa học thiếu chương trình, trạng thái hoạt động hoặc nội dung học thuật để công bố',
        );
      }
      const program = await this.prisma.trainingProgram.findUnique({
        where: { id: course.programId },
      });
      if (program?.status !== PublicationStatus.PUBLISHED) {
        throw new BadRequestException(
          'Chương trình đào tạo chưa được duyệt công bố',
        );
      }
    }
    if (
      status === PublicationStatus.ARCHIVED &&
      course.levels.some((level) => level._count.classes > 0)
    ) {
      throw new BadRequestException(
        'Khóa học đang có lớp; cần kết thúc các lớp trước khi lưu trữ',
      );
    }
    return this.prisma.course.update({
      where: { id },
      data: { publicationStatus: status },
    });
  }

  // --------------------------------------------------------------------------
  // COURSE LEVELS
  // --------------------------------------------------------------------------

  async findLevelsByCourse(courseId: string) {
    await this.findOne(courseId);

    return this.prisma.courseLevel.findMany({
      where: { courseId },
      orderBy: { order: 'asc' },
      include: {
        _count: {
          select: {
            modules: true,
            classes: true,
          },
        },
      },
    });
  }

  async createLevel(courseId: string, dto: CreateCourseLevelDto) {
    const course = await this.findOne(courseId);
    await this.assertCurriculumEditable(courseId, course.publicationStatus);

    const existing = await this.prisma.courseLevel.findUnique({
      where: {
        courseId_code: {
          courseId,
          code: dto.code,
        },
      },
    });

    if (existing) {
      throw new ConflictException(
        `Cấp độ '${dto.code}' đã tồn tại trong khóa học này`,
      );
    }

    return this.prisma.courseLevel.create({
      data: {
        ...dto,
        courseId,
      },
    });
  }

  async updateLevel(id: string, dto: UpdateCourseLevelDto) {
    const level = await this.prisma.courseLevel.findUnique({
      where: { id },
      include: { course: { select: { publicationStatus: true } } },
    });
    if (!level) throw new NotFoundException('Không tìm thấy cấp độ khóa học');
    if (level.course.publicationStatus === PublicationStatus.ARCHIVED) {
      throw new BadRequestException(
        'Khóa học đã lưu trữ, không thể chỉnh sửa cấp độ',
      );
    }
    await this.assertCurriculumEditable(level.courseId, level.course.publicationStatus);
    if (dto.code && dto.code !== level.code) {
      const existing = await this.prisma.courseLevel.findUnique({
        where: { courseId_code: { courseId: level.courseId, code: dto.code } },
      });
      if (existing)
        throw new ConflictException('Mã cấp độ đã tồn tại trong khóa học');
    }
    return this.prisma.courseLevel.update({ where: { id }, data: dto });
  }

  // --------------------------------------------------------------------------
  // MODULES
  // --------------------------------------------------------------------------

  async findModulesByLevel(levelId: string) {
    const level = await this.prisma.courseLevel.findUnique({
      where: { id: levelId },
    });

    if (!level) {
      throw new NotFoundException(`Không tìm thấy cấp độ với ID: ${levelId}`);
    }

    return this.prisma.module.findMany({
      where: { levelId },
      orderBy: { order: 'asc' },
      include: {
        lessons: {
          orderBy: { order: 'asc' },
          include: {
            materials: true,
          },
        },
      },
    });
  }

  async createModule(levelId: string, dto: CreateModuleDto) {
    const level = await this.prisma.courseLevel.findUnique({
      where: { id: levelId },
      include: { course: { select: { publicationStatus: true } } },
    });

    if (!level) {
      throw new NotFoundException(`Không tìm thấy cấp độ với ID: ${levelId}`);
    }
    if (level.course.publicationStatus === PublicationStatus.ARCHIVED) {
      throw new BadRequestException(
        'Không thể thêm học phần vào khóa đã lưu trữ',
      );
    }
    await this.assertCurriculumEditable(level.courseId, level.course.publicationStatus);

    return this.prisma.module.create({
      data: {
        ...dto,
        levelId,
      },
    });
  }

  async updateModule(id: string, dto: UpdateModuleDto) {
    const module = await this.prisma.module.findUnique({
      where: { id },
      include: {
        level: { select: { courseId: true, course: { select: { publicationStatus: true } } } },
      },
    });
    if (!module) {
      throw new NotFoundException(`Không tìm thấy học phần với ID: ${id}`);
    }
    if (module.level.course.publicationStatus === PublicationStatus.ARCHIVED) {
      throw new BadRequestException(
        'Không thể sửa học phần của khóa đã lưu trữ',
      );
    }
    await this.assertCurriculumEditable(module.level.courseId, module.level.course.publicationStatus);
    return this.prisma.module.update({ where: { id }, data: dto });
  }

  // --------------------------------------------------------------------------
  // LESSONS
  // --------------------------------------------------------------------------

  async findLessonsByModule(moduleId: string) {
    const mod = await this.prisma.module.findUnique({
      where: { id: moduleId },
    });

    if (!mod) {
      throw new NotFoundException(`Không tìm thấy module với ID: ${moduleId}`);
    }

    return this.prisma.lesson.findMany({
      where: { moduleId },
      orderBy: { order: 'asc' },
      include: {
        materials: {
          orderBy: { order: 'asc' },
        },
      },
    });
  }

  async createLesson(moduleId: string, dto: CreateLessonDto) {
    const mod = await this.prisma.module.findUnique({
      where: { id: moduleId },
      include: {
        level: { include: { course: { select: { publicationStatus: true } } } },
      },
    });

    if (!mod) {
      throw new NotFoundException(`Không tìm thấy module với ID: ${moduleId}`);
    }
    if (mod.level.course.publicationStatus === PublicationStatus.ARCHIVED) {
      throw new BadRequestException(
        'Không thể thêm bài học vào khóa đã lưu trữ',
      );
    }
    await this.assertCurriculumEditable(mod.level.courseId, mod.level.course.publicationStatus);

    return this.prisma.lesson.create({
      data: {
        ...dto,
        moduleId,
      },
    });
  }

  async updateLesson(id: string, dto: UpdateLessonDto) {
    const lesson = await this.prisma.lesson.findUnique({
      where: { id },
      include: {
        module: {
          include: {
            level: {
              include: {
                course: { select: { publicationStatus: true } },
              },
            },
          },
        },
      },
    });
    if (!lesson) {
      throw new NotFoundException(`Không tìm thấy bài học với ID: ${id}`);
    }
    if (
      lesson.module.level.course.publicationStatus ===
      PublicationStatus.ARCHIVED
    ) {
      throw new BadRequestException(
        'Không thể sửa bài học của khóa đã lưu trữ',
      );
    }
    await this.assertCurriculumEditable(lesson.module.level.courseId, lesson.module.level.course.publicationStatus);
    return this.prisma.lesson.update({ where: { id }, data: dto });
  }

  // --------------------------------------------------------------------------
  // MATERIALS
  // --------------------------------------------------------------------------

  async createLessonMaterial(lessonId: string, dto: CreateLessonMaterialDto) {
    const lesson = await this.prisma.lesson.findUnique({
      where: { id: lessonId },
      include: {
        module: {
          include: {
            level: {
              include: { course: { select: { publicationStatus: true } } },
            },
          },
        },
      },
    });

    if (!lesson) {
      throw new NotFoundException(`Không tìm thấy bài học với ID: ${lessonId}`);
    }
    if (
      lesson.module.level.course.publicationStatus ===
      PublicationStatus.ARCHIVED
    ) {
      throw new BadRequestException(
        'Không thể thêm tài liệu vào khóa đã lưu trữ',
      );
    }
    await this.assertCurriculumEditable(lesson.module.level.courseId, lesson.module.level.course.publicationStatus);

    return this.prisma.lessonMaterial.create({
      data: {
        ...dto,
        lessonId,
      },
    });
  }
}
