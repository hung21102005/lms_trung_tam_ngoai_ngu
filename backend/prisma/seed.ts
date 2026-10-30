import {
  PrismaClient,
  UserStatus,
  Gender,
  LeadSource,
  LeadStatus,
  ClassStatus,
  EnrollmentStatus,
  SessionStatus,
  MaterialFileType,
} from '@prisma/client';
import * as bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Bắt đầu gieo mầm dữ liệu (Database Seeding)...');

  // ----------------------------------------------------------------------------
  // 1. SEED ROLES
  // ----------------------------------------------------------------------------
  console.log('1. Đang seed danh sách Roles mặc định...');
  const rolesData = [
    { code: 'super_admin', name: 'Quản trị viên cấp cao', description: 'Toàn quyền điều hành toàn bộ hệ thống các chi nhánh', isSystem: true },
    { code: 'branch_admin', name: 'Quản trị viên chi nhánh', description: 'Quản lý toàn bộ hoạt động trong phạm vi chi nhánh', isSystem: true },
    { code: 'academic_staff', name: 'Nhân viên học vụ', description: 'Quản lý xếp lớp, lịch học, điểm danh và học viên', isSystem: true },
    { code: 'cashier', name: 'Thu ngân', description: 'Thu học phí, lập hóa đơn và đối soát thanh toán', isSystem: true },
    { code: 'teacher', name: 'Giáo viên', description: 'Giảng dạy, điểm danh, giao bài và chấm điểm bài tập', isSystem: true },
    { code: 'teaching_assistant', name: 'Trợ giảng', description: 'Hỗ trợ giáo viên điểm danh và hỗ trợ học viên', isSystem: true },
    { code: 'student', name: 'Học viên', description: 'Tham gia học tập, làm bài thi, nộp bài phát âm và xem kết quả', isSystem: true },
    { code: 'parent', name: 'Phụ huynh', description: 'Theo dõi chuyên cần, tiến độ học tập và học phí của con', isSystem: true },
  ];

  const roleMap: Record<string, string> = {};
  for (const r of rolesData) {
    const role = await prisma.role.upsert({
      where: { code: r.code },
      update: { name: r.name, description: r.description },
      create: r,
    });
    roleMap[role.code] = role.id;
  }
  console.log(`   ✅ Đã gieo ${rolesData.length} vai trò mặc định.`);

  // ----------------------------------------------------------------------------
  // 2. SEED PERMISSIONS (~40 permissions)
  // ----------------------------------------------------------------------------
  console.log('2. Đang seed danh sách Permissions mặc định...');
  const permissionsData = [
    // Module System
    { code: 'system.manage', name: 'Quản trị hệ thống toàn diện', module: 'system' },
    { code: 'system.settings', name: 'Cấu hình tham số hệ thống', module: 'system' },
    { code: 'audit.view', name: 'Xem nhật ký kiểm toán hệ thống', module: 'system' },

    // Module Branches & Rooms
    { code: 'branches.view', name: 'Xem danh sách chi nhánh', module: 'branches' },
    { code: 'branches.manage', name: 'Quản lý chi nhánh (thêm, sửa, đóng cửa)', module: 'branches' },
    { code: 'rooms.view', name: 'Xem danh sách phòng học', module: 'rooms' },
    { code: 'rooms.manage', name: 'Quản lý phòng học & trang thiết bị', module: 'rooms' },

    // Module Users & Roles
    { code: 'users.view', name: 'Xem danh sách người dùng', module: 'users' },
    { code: 'users.create', name: 'Cấp phát tài khoản mới', module: 'users' },
    { code: 'users.update', name: 'Cập nhật thông tin người dùng', module: 'users' },
    { code: 'users.lock', name: 'Khóa / Mở khóa tài khoản', module: 'users' },
    { code: 'users.reset_pwd', name: 'Cấp lại mật khẩu tạm', module: 'users' },
    { code: 'roles.manage', name: 'Quản lý phân quyền RBAC', module: 'users' },

    // Module Admissions (Tuyển sinh)
    { code: 'leads.view', name: 'Xem danh sách đăng ký tư vấn', module: 'admissions' },
    { code: 'leads.create', name: 'Tiếp nhận yêu cầu tư vấn mới', module: 'admissions' },
    { code: 'leads.update', name: 'Cập nhật tiến trình tư vấn, hẹn test', module: 'admissions' },
    { code: 'leads.convert', name: 'Chuyển đổi lead thành học viên chính thức', module: 'admissions' },

    // Module Courses & Classes
    { code: 'courses.view', name: 'Xem danh mục khóa học', module: 'courses' },
    { code: 'courses.manage', name: 'Quản lý chương trình đào tạo & khóa học', module: 'courses' },
    { code: 'classes.view', name: 'Xem danh sách lớp học', module: 'classes' },
    { code: 'classes.manage', name: 'Mở lớp, xếp lớp và phân công giáo viên', module: 'classes' },
    { code: 'schedules.manage', name: 'Quản lý thời khóa biểu & lịch học', module: 'classes' },

    // Module Attendance
    { code: 'attendance.view', name: 'Xem kết quả điểm danh', module: 'attendance' },
    { code: 'attendance.mark', name: 'Thực hiện điểm danh tại lớp', module: 'attendance' },
    { code: 'attendance.makeup_manage', name: 'Xếp lịch học bù cho học viên vắng', module: 'attendance' },

    // Module Exams & Grading
    { code: 'exams.view', name: 'Xem danh sách bài thi & bài tập', module: 'exams' },
    { code: 'exams.create', name: 'Tạo đề thi và ngân hàng câu hỏi', module: 'exams' },
    { code: 'exams.take', name: 'Làm bài thi trực tuyến & nộp bài', module: 'exams' },
    { code: 'exams.grade_speaking', name: 'Chấm điểm bài tập phát âm (nghe audio)', module: 'exams' },
    { code: 'exams.grade_writing', name: 'Chấm bài viết & nhận xét chi tiết', module: 'exams' },

    // Module Finance
    { code: 'invoices.view', name: 'Xem danh sách hóa đơn & công nợ', module: 'finance' },
    { code: 'invoices.create', name: 'Lập thông báo học phí & hóa đơn', module: 'finance' },
    { code: 'invoices.collect', name: 'Thu tiền học phí & xác nhận thanh toán', module: 'finance' },
    { code: 'reports.financial', name: 'Xem báo cáo doanh thu & công nợ', module: 'finance' },

    // Module Notifications
    { code: 'notifications.view', name: 'Xem thông báo cá nhân', module: 'notifications' },
    { code: 'notifications.broadcast', name: 'Bắn thông báo đẩy FCM toàn trung tâm', module: 'notifications' },

    // Module Reports
    { code: 'reports.academic', name: 'Xem báo cáo học vụ & sĩ số', module: 'reports' },
    { code: 'reports.attendance', name: 'Xem thống kê chuyên cần & tỷ lệ vắng', module: 'reports' },
  ];

  const permMap: Record<string, string> = {};
  for (const p of permissionsData) {
    const perm = await prisma.permission.upsert({
      where: { code: p.code },
      update: { name: p.name, module: p.module },
      create: p,
    });
    permMap[perm.code] = perm.id;
  }
  console.log(`   ✅ Đã gieo ${permissionsData.length} quyền hạn (Permissions).`);

  // ----------------------------------------------------------------------------
  // 3. GÁN PERMISSIONS CHO ROLES
  // ----------------------------------------------------------------------------
  console.log('3. Đang liên kết Permissions vào các Roles tương ứng...');
  // Super admin: mọi quyền
  for (const permCode of Object.keys(permMap)) {
    await prisma.rolePermission.upsert({
      where: {
        roleId_permissionId: {
          roleId: roleMap['super_admin'],
          permissionId: permMap[permCode],
        },
      },
      update: {},
      create: {
        roleId: roleMap['super_admin'],
        permissionId: permMap[permCode],
      },
    });
  }

  // Branch Admin: quyền quản lý trong chi nhánh
  const branchAdminPerms = [
    'branches.view', 'rooms.view', 'rooms.manage', 'users.view', 'users.create', 'users.update',
    'users.lock', 'users.reset_pwd', 'leads.view', 'leads.create', 'leads.update', 'leads.convert',
    'courses.view', 'classes.view', 'classes.manage', 'schedules.manage', 'attendance.view',
    'attendance.makeup_manage', 'exams.view', 'invoices.view', 'invoices.create', 'invoices.collect',
    'reports.financial', 'reports.academic', 'reports.attendance', 'notifications.view', 'notifications.broadcast',
  ];
  for (const code of branchAdminPerms) {
    if (permMap[code]) {
      await prisma.rolePermission.upsert({
        where: { roleId_permissionId: { roleId: roleMap['branch_admin'], permissionId: permMap[code] } },
        update: {},
        create: { roleId: roleMap['branch_admin'], permissionId: permMap[code] },
      });
    }
  }

  // Academic Staff
  const academicPerms = [
    'branches.view', 'rooms.view', 'users.view', 'users.create', 'users.update',
    'leads.view', 'leads.create', 'leads.update', 'leads.convert', 'courses.view',
    'classes.view', 'classes.manage', 'schedules.manage', 'attendance.view',
    'attendance.makeup_manage', 'exams.view', 'reports.academic', 'reports.attendance', 'notifications.view',
  ];
  for (const code of academicPerms) {
    if (permMap[code]) {
      await prisma.rolePermission.upsert({
        where: { roleId_permissionId: { roleId: roleMap['academic_staff'], permissionId: permMap[code] } },
        update: {},
        create: { roleId: roleMap['academic_staff'], permissionId: permMap[code] },
      });
    }
  }

  // Teacher
  const teacherPerms = [
    'classes.view', 'attendance.view', 'attendance.mark', 'exams.view',
    'exams.grade_speaking', 'exams.grade_writing', 'notifications.view',
  ];
  for (const code of teacherPerms) {
    if (permMap[code]) {
      await prisma.rolePermission.upsert({
        where: { roleId_permissionId: { roleId: roleMap['teacher'], permissionId: permMap[code] } },
        update: {},
        create: { roleId: roleMap['teacher'], permissionId: permMap[code] },
      });
    }
  }

  // Student
  const studentPerms = [
    'classes.view', 'attendance.view', 'exams.view', 'exams.take', 'invoices.view', 'notifications.view',
  ];
  for (const code of studentPerms) {
    if (permMap[code]) {
      await prisma.rolePermission.upsert({
        where: { roleId_permissionId: { roleId: roleMap['student'], permissionId: permMap[code] } },
        update: {},
        create: { roleId: roleMap['student'], permissionId: permMap[code] },
      });
    }
  }

  // Parent
  const parentPerms = [
    'attendance.view', 'invoices.view', 'notifications.view',
  ];
  for (const code of parentPerms) {
    if (permMap[code]) {
      await prisma.rolePermission.upsert({
        where: { roleId_permissionId: { roleId: roleMap['parent'], permissionId: permMap[code] } },
        update: {},
        create: { roleId: roleMap['parent'], permissionId: permMap[code] },
      });
    }
  }
  console.log('   ✅ Đã cấu hình phân quyền hoàn tất cho tất cả các Roles.');

  // ----------------------------------------------------------------------------
  // 4. SEED CHI NHÁNH & PHÒNG HỌC MẪU
  // ----------------------------------------------------------------------------
  console.log('4. Đang seed Chi nhánh & Phòng học mẫu...');
  const branchQ1 = await prisma.branch.upsert({
    where: { code: 'BR-Q1' },
    update: {},
    create: {
      code: 'BR-Q1',
      name: 'Chi nhánh Quận 1 - Hồ Chí Minh',
      address: '123 Hai Bà Trưng, Phường Bến Nghé, Quận 1, TP. Hồ Chí Minh',
      phone: '02838221122',
      email: 'q1@lms-edu.vn',
      isActive: true,
    },
  });

  const room1 = await prisma.room.upsert({
    where: { branchId_code: { branchId: branchQ1.id, code: 'P101' } },
    update: {},
    create: {
      branchId: branchQ1.id,
      code: 'P101',
      name: 'Phòng Học Smart 101',
      capacity: 25,
      equipment: 'Máy chiếu 4K, Loa âm trần trợ giảng, Bảng kính từ, Máy lạnh Daikin',
      isActive: true,
    },
  });

  const room2 = await prisma.room.upsert({
    where: { branchId_code: { branchId: branchQ1.id, code: 'LAB-01' } },
    update: {},
    create: {
      branchId: branchQ1.id,
      code: 'LAB-01',
      name: 'Phòng Lab Nghe Nói 01',
      capacity: 30,
      equipment: '30 Tai nghe chuyên dụng chống ồn, Máy tính giảng viên, Màn hình tương tác cảm ứng',
      isActive: true,
    },
  });
  console.log(`   ✅ Đã gieo Chi nhánh: ${branchQ1.name} & 2 phòng: ${room1.code}, ${room2.code}.`);

  // ----------------------------------------------------------------------------
  // 5. SEED TÀI KHOẢN SUPER ADMIN MẶC ĐỊNH
  // ----------------------------------------------------------------------------
  console.log('5. Đang seed tài khoản Super Admin mặc định...');
  const salt = 12;
  const adminPasswordHash = bcrypt.hashSync('Admin@123456', salt);

  const superAdmin = await prisma.user.upsert({
    where: { userCode: 'AD-000001' },
    update: {
      email: 'admin@lms-edu.vn',
      passwordHash: adminPasswordHash,
      status: UserStatus.ACTIVE,
      isFirstLogin: false,
    },
    create: {
      userCode: 'AD-000001',
      email: 'admin@lms-edu.vn',
      phone: '0901234567',
      passwordHash: adminPasswordHash,
      fullName: 'Quản Trị Viên Hệ Thống',
      gender: Gender.MALE,
      dateOfBirth: new Date('1990-01-01'),
      status: UserStatus.ACTIVE,
      isFirstLogin: false,
      branchId: branchQ1.id,
    },
  });

  await prisma.userRole.upsert({
    where: { userId_roleId: { userId: superAdmin.id, roleId: roleMap['super_admin'] } },
    update: {},
    create: { userId: superAdmin.id, roleId: roleMap['super_admin'] },
  });
  console.log('   ✅ Đã tạo tài khoản Super Admin: admin@lms-edu.vn / Admin@123456');

  // ----------------------------------------------------------------------------
  // 6. SEED DỮ LIỆU NGƯỜI DÙNG MẪU (TEACHER, STAFF, STUDENT, PARENT)
  // ----------------------------------------------------------------------------
  console.log('6. Đang seed danh sách người dùng mẫu...');
  const defaultPasswordHash = bcrypt.hashSync('Password@123', salt);

  // 6.1 Giáo viên mẫu
  const teacherUser = await prisma.user.upsert({
    where: { userCode: 'GV-0001' },
    update: {},
    create: {
      userCode: 'GV-0001',
      email: 'teacher@lms-edu.vn',
      phone: '0911223344',
      passwordHash: defaultPasswordHash,
      fullName: 'Thầy Nguyễn Văn Dũng',
      gender: Gender.MALE,
      dateOfBirth: new Date('1988-05-15'),
      status: UserStatus.ACTIVE,
      isFirstLogin: false,
      branchId: branchQ1.id,
      teacherProfile: {
        create: {
          degrees: 'Thạc sĩ Ngôn ngữ Anh (ĐH Sư Phạm), IELTS 8.5, TESOL Certificate',
          specialties: 'IELTS Speaking & Writing, Luyện phát âm chuẩn IPA',
          bio: 'Hơn 8 năm kinh nghiệm luyện thi IELTS cho hơn 1.000 học viên đạt mục tiêu.',
          hourlyRate: 350000,
        },
      },
    },
  });
  await prisma.userRole.upsert({
    where: { userId_roleId: { userId: teacherUser.id, roleId: roleMap['teacher'] } },
    update: {},
    create: { userId: teacherUser.id, roleId: roleMap['teacher'] },
  });

  // 6.2 Nhân viên học vụ mẫu
  const staffUser = await prisma.user.upsert({
    where: { userCode: 'HVU-0001' },
    update: {},
    create: {
      userCode: 'HVU-0001',
      email: 'academic@lms-edu.vn',
      phone: '0922334455',
      passwordHash: defaultPasswordHash,
      fullName: 'Cô Trần Mai Lan',
      gender: Gender.FEMALE,
      dateOfBirth: new Date('1994-08-20'),
      status: UserStatus.ACTIVE,
      isFirstLogin: false,
      branchId: branchQ1.id,
    },
  });
  await prisma.userRole.upsert({
    where: { userId_roleId: { userId: staffUser.id, roleId: roleMap['academic_staff'] } },
    update: {},
    create: { userId: staffUser.id, roleId: roleMap['academic_staff'] },
  });

  // 6.3 Học viên mẫu
  const studentUser = await prisma.user.upsert({
    where: { userCode: 'HV-2026-0001' },
    update: {},
    create: {
      userCode: 'HV-2026-0001',
      email: 'student@lms-edu.vn',
      phone: '0933445566',
      passwordHash: defaultPasswordHash,
      fullName: 'Em Lê Minh Khang',
      gender: Gender.MALE,
      dateOfBirth: new Date('2008-10-12'),
      status: UserStatus.ACTIVE,
      isFirstLogin: true, // Thử nghiệm quy trình kích hoạt lần đầu
      branchId: branchQ1.id,
      studentProfile: {
        create: {
          entryLevel: 'IELTS 4.5',
          targetLevel: 'IELTS 6.5',
          schoolName: 'THPT Chuyên Lê Hồng Phong',
          notes: 'Cần rèn luyện thêm kỹ năng phát âm và từ vựng học thuật',
        },
      },
    },
  });
  await prisma.userRole.upsert({
    where: { userId_roleId: { userId: studentUser.id, roleId: roleMap['student'] } },
    update: {},
    create: { userId: studentUser.id, roleId: roleMap['student'] },
  });

  // 6.4 Phụ huynh mẫu
  const parentUser = await prisma.user.upsert({
    where: { userCode: 'PH-0001' },
    update: {},
    create: {
      userCode: 'PH-0001',
      email: 'parent@lms-edu.vn',
      phone: '0944556677',
      passwordHash: defaultPasswordHash,
      fullName: 'Anh Lê Văn Hùng',
      gender: Gender.MALE,
      dateOfBirth: new Date('1980-03-25'),
      status: UserStatus.ACTIVE,
      isFirstLogin: true,
      branchId: branchQ1.id,
    },
  });
  await prisma.userRole.upsert({
    where: { userId_roleId: { userId: parentUser.id, roleId: roleMap['parent'] } },
    update: {},
    create: { userId: parentUser.id, roleId: roleMap['parent'] },
  });

  // Liên kết Phụ huynh - Học viên
  await prisma.parentStudent.upsert({
    where: { parentId_studentId: { parentId: parentUser.id, studentId: studentUser.id } },
    update: {},
    create: {
      parentId: parentUser.id,
      studentId: studentUser.id,
      relationship: 'Bố',
      isPrimaryContact: true,
    },
  });

  // ----------------------------------------------------------------------------
  // 7. SEED ADMISSION LEAD MẪU
  // ----------------------------------------------------------------------------
  console.log('7. Đang seed dữ liệu Lead tư vấn mẫu...');
  await prisma.admissionLead.create({
    data: {
      fullName: 'Nguyễn Hoàng Nam',
      phone: '0988776655',
      email: 'hoangnam.nguyen@gmail.com',
      targetCourse: 'Luyện thi IELTS Cấp Tốc 6.5',
      source: LeadSource.WEBSITE,
      status: LeadStatus.NEW,
      branchId: branchQ1.id,
      assignedStaffId: staffUser.id,
      notes: 'Học sinh lớp 12 muốn thi lấy chứng chỉ IELTS xét tuyển Đại học đợt tháng 12.',
    },
  });
  console.log('   ✅ Đã gieo dữ liệu Lead tư vấn tuyển sinh mẫu.');

  // ----------------------------------------------------------------------------
  // 8. SEED KHÓA HỌC, GIÁO TRÌNH & LỚP HỌC MẪU (PHASE 2: CORE ACADEMIC)
  // ----------------------------------------------------------------------------
  console.log('8. Đang seed Khóa học, Cấp độ, Giáo trình & Lớp học mẫu...');

  // 8.1 Khóa học IELTS
  const courseIelts = await prisma.course.upsert({
    where: { code: 'ENG-IELTS' },
    update: {},
    create: {
      code: 'ENG-IELTS',
      title: 'Chương trình Luyện thi IELTS Chuyên sâu',
      description: 'Chương trình đào tạo toàn diện 4 kỹ năng Nghe - Nói - Đọc - Viết theo chuẩn Cambridge.',
      targetAudience: 'Học sinh THPT, Sinh viên và Người đi làm cần chứng chỉ du học/định cư',
      language: 'English',
      thumbnailUrl: 'https://images.unsplash.com/photo-1546410531-bb4caa6b424d',
      isActive: true,
    },
  });

  const levelIeltsFoundation = await prisma.courseLevel.upsert({
    where: { courseId_code: { courseId: courseIelts.id, code: 'FOUNDATION' } },
    update: {},
    create: {
      courseId: courseIelts.id,
      code: 'FOUNDATION',
      name: 'IELTS Foundation (Nền tảng 4.0 - 5.0)',
      description: 'Xây dựng nền tảng từ vựng, ngữ pháp và phát âm chuẩn học thuật',
      order: 1,
      estimatedSessions: 24,
      tuitionFee: 6500000,
    },
  });

  await prisma.courseLevel.upsert({
    where: { courseId_code: { courseId: courseIelts.id, code: 'FIGHTER' } },
    update: {},
    create: {
      courseId: courseIelts.id,
      code: 'FIGHTER',
      name: 'IELTS Fighter (Mục tiêu 5.5 - 6.5)',
      description: 'Chiến thuật làm bài 4 kỹ năng và luyện đề thi thực tế',
      order: 2,
      estimatedSessions: 30,
      tuitionFee: 8500000,
    },
  });

  // Modules & Lessons cho IELTS Foundation
  let module1 = await prisma.module.findFirst({
    where: { levelId: levelIeltsFoundation.id, order: 1 },
  });
  if (!module1) {
    module1 = await prisma.module.create({
      data: {
        levelId: levelIeltsFoundation.id,
        title: 'Module 1: Ngữ âm & Giao tiếp nền tảng',
        order: 1,
        description: 'Bảng phiên âm quốc tế IPA và phát âm tự nhiên trong giao tiếp',
      },
    });
  }

  let lesson1 = await prisma.lesson.findFirst({
    where: { moduleId: module1.id, order: 1 },
  });
  if (!lesson1) {
    lesson1 = await prisma.lesson.create({
      data: {
        moduleId: module1.id,
        title: 'Unit 1: IPA Vowels & Self-Introduction',
        order: 1,
        content: 'Tổng quan nguyên âm đơn và đôi; cách giới thiệu bản thân trong phần thi IELTS Speaking Part 1.',
        durationMinutes: 90,
      },
    });
  }

  let lesson2 = await prisma.lesson.findFirst({
    where: { moduleId: module1.id, order: 2 },
  });
  if (!lesson2) {
    lesson2 = await prisma.lesson.create({
      data: {
        moduleId: module1.id,
        title: 'Unit 2: IPA Consonants & Daily Routines',
        order: 2,
        content: 'Phát âm phụ âm và phụ âm kép; từ vựng chủ đề Daily Routines.',
        durationMinutes: 90,
      },
    });
  }

  // 8.2 Khóa học Giao tiếp
  const courseComm = await prisma.course.upsert({
    where: { code: 'ENG-COMM' },
    update: {},
    create: {
      code: 'ENG-COMM',
      title: 'Tiếng Anh Giao Tiếp Phản Xạ Quốc Tế',
      description: 'Phương pháp phản xạ tương tác phản hồi tức thì giúp tăng tốc phản xạ giao tiếp.',
      targetAudience: 'Người đi làm, người mất gốc tiếng Anh',
      language: 'English',
      thumbnailUrl: 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f',
      isActive: true,
    },
  });

  const levelCommA1 = await prisma.courseLevel.upsert({
    where: { courseId_code: { courseId: courseComm.id, code: 'COMM-A1' } },
    update: {},
    create: {
      courseId: courseComm.id,
      code: 'COMM-A1',
      name: 'Giao tiếp Cơ bản A1',
      description: 'Làm quen và tự tin trong các tình huống hàng ngày',
      order: 1,
      estimatedSessions: 20,
      tuitionFee: 4500000,
    },
  });

  // 8.3 Lớp học mẫu 1: IELTS-F-2026-01
  const classIelts = await prisma.class.upsert({
    where: { code: 'IELTS-F-2026-01' },
    update: {},
    create: {
      code: 'IELTS-F-2026-01',
      name: 'Lớp IELTS Foundation K01 (T2-T4-T6)',
      courseId: courseIelts.id,
      levelId: levelIeltsFoundation.id,
      branchId: branchQ1.id,
      roomId: room1.id,
      mainTeacherId: teacherUser.id,
      assistantTeacherId: staffUser.id,
      status: ClassStatus.IN_PROGRESS,
      startDate: new Date('2026-10-05'),
      endDate: new Date('2026-11-27'),
      scheduleDays: ['MONDAY', 'WEDNESDAY', 'FRIDAY'],
      startTime: '18:00',
      endTime: '19:30',
      totalSessions: 24,
      maxCapacity: 20,
      tuitionFee: 6500000,
      notes: 'Lớp học trọng điểm quý 4/2026.',
    },
  });

  // Ghi danh học viên studentUser vào lớp
  await prisma.classStudent.upsert({
    where: { classId_studentId: { classId: classIelts.id, studentId: studentUser.id } },
    update: {},
    create: {
      classId: classIelts.id,
      studentId: studentUser.id,
      status: EnrollmentStatus.ENROLLED,
      tuitionPaid: 6500000,
      notes: 'Học viên chuyển tiếp từ Lead tư vấn.',
    },
  });

  // Tự động sinh 24 buổi học mẫu cho lớp IELTS
  const existingSessions = await prisma.classSession.count({ where: { classId: classIelts.id } });
  if (existingSessions === 0) {
    const dayMap: Record<string, number> = {
      SUNDAY: 0,
      MONDAY: 1,
      TUESDAY: 2,
      WEDNESDAY: 3,
      THURSDAY: 4,
      FRIDAY: 5,
      SATURDAY: 6,
    };
    const targetDays = ['MONDAY', 'WEDNESDAY', 'FRIDAY'].map((d) => dayMap[d]);
    let sessionCount = 0;
    const curDate = new Date('2026-10-05');

    while (sessionCount < 24) {
      if (targetDays.includes(curDate.getDay())) {
        sessionCount++;
        await prisma.classSession.create({
          data: {
            classId: classIelts.id,
            sessionNumber: sessionCount,
            title: `Buổi ${sessionCount}: ${sessionCount === 1 ? 'Orientation & Unit 1' : sessionCount === 2 ? 'Unit 2: Pronunciation' : `Chủ đề bài học số ${sessionCount}`}`,
            date: new Date(curDate),
            startTime: '18:00',
            endTime: '19:30',
            roomId: room1.id,
            teacherId: teacherUser.id,
            status: sessionCount <= 4 ? SessionStatus.COMPLETED : SessionStatus.SCHEDULED,
            lessonId: sessionCount === 1 ? lesson1?.id : sessionCount === 2 ? lesson2?.id : null,
          },
        });
      }
      curDate.setDate(curDate.getDate() + 1);
    }
  }

  // 8.4 Lớp học mẫu 2: COMM-A1-2026-01
  await prisma.class.upsert({
    where: { code: 'COMM-A1-2026-01' },
    update: {},
    create: {
      code: 'COMM-A1-2026-01',
      name: 'Lớp Giao Tiếp A1 K01 (T3-T5-T7)',
      courseId: courseComm.id,
      levelId: levelCommA1.id,
      branchId: branchQ1.id,
      roomId: room2.id,
      mainTeacherId: teacherUser.id,
      status: ClassStatus.OPEN_FOR_ENROLLMENT,
      startDate: new Date('2026-11-03'),
      scheduleDays: ['TUESDAY', 'THURSDAY', 'SATURDAY'],
      startTime: '19:30',
      endTime: '21:00',
      totalSessions: 20,
      maxCapacity: 15,
      tuitionFee: 4500000,
      notes: 'Đang mở đăng ký tuyển sinh.',
    },
  });

  console.log('   ✅ Đã gieo Khóa học mẫu, Cấp độ, Giáo trình và 2 Lớp học kèm buổi học.');

  console.log('✨ HOÀN THÀNH TOÀN BỘ QUÁ TRÌNH DATABASE SEEDING!');
}

main()
  .catch((e) => {
    console.error('❌ Lỗi khi seed dữ liệu:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
