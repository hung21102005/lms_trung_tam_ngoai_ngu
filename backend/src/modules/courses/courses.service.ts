import {
  Injectable,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service.js';
import {
  CreateCourseDto,
  UpdateCourseDto,
  CreateCourseLevelDto,
  CreateModuleDto,
  CreateLessonDto,
  CreateLessonMaterialDto,
  QueryCoursesDto,
} from './dto/index.js';

@Injectable()
export class CoursesService {
  constructor(private readonly prisma: PrismaService) {}

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
      throw new ConflictException(`Mã khóa học '${dto.code}' đã tồn tại trên hệ thống`);
    }

    return this.prisma.course.create({
      data: dto,
    });
  }

  async update(id: string, dto: UpdateCourseDto) {
    await this.findOne(id);

    if (dto.code) {
      const existing = await this.prisma.course.findUnique({
        where: { code: dto.code },
      });

      if (existing && existing.id !== id) {
        throw new ConflictException(`Mã khóa học '${dto.code}' đã được sử dụng`);
      }
    }

    return this.prisma.course.update({
      where: { id },
      data: dto,
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
    await this.findOne(courseId);

    const existing = await this.prisma.courseLevel.findUnique({
      where: {
        courseId_code: {
          courseId,
          code: dto.code,
        },
      },
    });

    if (existing) {
      throw new ConflictException(`Cấp độ '${dto.code}' đã tồn tại trong khóa học này`);
    }

    return this.prisma.courseLevel.create({
      data: {
        ...dto,
        courseId,
      },
    });
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
    });

    if (!level) {
      throw new NotFoundException(`Không tìm thấy cấp độ với ID: ${levelId}`);
    }

    return this.prisma.module.create({
      data: {
        ...dto,
        levelId,
      },
    });
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
    });

    if (!mod) {
      throw new NotFoundException(`Không tìm thấy module với ID: ${moduleId}`);
    }

    return this.prisma.lesson.create({
      data: {
        ...dto,
        moduleId,
      },
    });
  }

  // --------------------------------------------------------------------------
  // MATERIALS
  // --------------------------------------------------------------------------

  async createLessonMaterial(lessonId: string, dto: CreateLessonMaterialDto) {
    const lesson = await this.prisma.lesson.findUnique({
      where: { id: lessonId },
    });

    if (!lesson) {
      throw new NotFoundException(`Không tìm thấy bài học với ID: ${lessonId}`);
    }

    return this.prisma.lessonMaterial.create({
      data: {
        ...dto,
        lessonId,
      },
    });
  }
}
