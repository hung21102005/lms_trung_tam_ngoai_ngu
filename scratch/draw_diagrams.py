import os
import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch

os.makedirs("docs/diagrams", exist_ok=True)

plt.rcParams['font.family'] = 'Segoe UI'
plt.rcParams['font.size'] = 10

def create_box(ax, xy, width, height, text, title=None, facecolor='#EBF5FB', edgecolor='#2980B9', text_color='#1A5276', title_color='#154360', fontsize=9.5, title_fontsize=10.5, boxstyle="round,pad=0.3,rounding_size=0.15", lw=1.5):
    box = FancyBboxPatch(xy, width, height, boxstyle=boxstyle,
                         facecolor=facecolor, edgecolor=edgecolor, linewidth=lw)
    ax.add_patch(box)
    cx = xy[0] + width / 2.0
    cy = xy[1] + height / 2.0
    
    if title:
        ty = xy[1] + height - 0.25
        ax.text(cx, ty, title, ha='center', va='center', fontsize=title_fontsize, fontweight='bold', color=title_color)
        cy_text = xy[1] + (height - 0.35) / 2.0
        ax.text(cx, cy_text, text, ha='center', va='center', fontsize=fontsize, color=text_color, multialignment='center')
    else:
        ax.text(cx, cy, text, ha='center', va='center', fontsize=fontsize, color=text_color, multialignment='center')

def draw_arrow(ax, start, end, label=None, color='#2C3E50', lw=1.8, style='->', label_pos=None, label_color='#2C3E50'):
    arrow = FancyArrowPatch(start, end, arrowstyle=style, mutation_scale=14,
                            color=color, linewidth=lw, linestyle='solid')
    ax.add_patch(arrow)
    if label:
        if label_pos:
            lx, ly = label_pos
        else:
            lx = (start[0] + end[0]) / 2.0
            ly = (start[1] + end[1]) / 2.0
        ax.text(lx, ly, label, ha='center', va='center', fontsize=8.5,
                backgroundcolor='#FFFFFF', color=label_color, fontweight='bold')

# ==============================================================================
# SƠ ĐỒ 1: CLIENT-SERVER ARCHITECTURE
# ==============================================================================
def draw_diagram_1():
    fig, ax = plt.subplots(figsize=(11, 7.5), dpi=300)
    ax.set_xlim(0, 11)
    ax.set_ylim(0, 7.5)
    ax.axis('off')

    # Title
    ax.text(5.5, 7.2, "SƠ ĐỒ 1: KIẾN TRÚC MÁY KHÁCH - MÁY CHỦ ĐA NỀN TẢNG (CLIENT-SERVER)",
            ha='center', va='center', fontsize=12.5, fontweight='bold', color='#1A5276')

    # Container 1: Client Layer
    c_client = FancyBboxPatch((0.5, 5.0), 10.0, 1.8, boxstyle="round,pad=0.2", facecolor='#E8F8F5', edgecolor='#16A085', lw=1.5, linestyle='--')
    ax.add_patch(c_client)
    ax.text(0.8, 6.6, "[TẦNG ỨNG DỤNG ĐẦU CUỐI (CLIENT LAYER)]", fontsize=10.5, fontweight='bold', color='#117A65')

    create_box(ax, (0.8, 5.2), 4.4, 1.2, "• Dành cho Học viên & Phụ huynh (Tra cứu, học tập, nộp bài)\n• Dành cho Giáo viên (Điểm danh, chấm bài phát âm)",
               title="Flutter Mobile App (iOS / Android)", facecolor='#FFFFFF', edgecolor='#1ABC9C', title_color='#0E6251')
    create_box(ax, (5.8, 5.2), 4.4, 1.2, "• Dành cho Admin, Quản lý học vụ, Thu ngân\n• Xếp lớp, quản lý chi nhánh, đối soát học phí, báo cáo",
               title="Flutter Web Admin Portal (Desktop Web)", facecolor='#FFFFFF', edgecolor='#1ABC9C', title_color='#0E6251')

    # Communication Arrows
    draw_arrow(ax, (3.0, 5.0), (3.0, 3.8), label="HTTPS (RESTful JSON APIs) & WSS (WebSocket)", color='#2980B9', lw=2, label_pos=(5.5, 4.4))
    draw_arrow(ax, (8.0, 5.0), (8.0, 3.8), color='#2980B9', lw=2)

    # Container 2: Server Layer (NestJS)
    c_server = FancyBboxPatch((0.5, 1.8), 10.0, 2.0, boxstyle="round,pad=0.2", facecolor='#EAF2F8', edgecolor='#2980B9', lw=1.5, linestyle='--')
    ax.add_patch(c_server)
    ax.text(0.8, 3.6, "[TẦNG MÁY CHỦ TRUNG TÂM (SERVER LAYER - NestJS Enterprise API)]", fontsize=10.5, fontweight='bold', color='#1B4F72')

    create_box(ax, (0.8, 2.0), 2.8, 1.3, "• JWT Access / Refresh Token\n• Phân quyền RBAC Guard\n• Cấp tài khoản tập trung", title="Auth & Users Module", facecolor='#FFFFFF', edgecolor='#3498DB')
    create_box(ax, (3.9, 2.0), 3.2, 1.3, "• Lớp học, khóa học, xếp lịch\n• Điểm danh & học bù\n• Ngân hàng câu hỏi & thi online", title="Academic & Exams Module", facecolor='#FFFFFF', edgecolor='#3498DB')
    create_box(ax, (7.4, 2.0), 2.8, 1.3, "• Hóa đơn & VNPay Webhook\n• Job Queue thông báo nền\n• Upload file Cloud Storage", title="Finance & Services Module", facecolor='#FFFFFF', edgecolor='#3498DB')

    # Arrows to Data / Cloud Tier
    draw_arrow(ax, (2.2, 1.8), (2.2, 1.0), label="SQL / TCP", color='#27AE60', lw=1.8, label_pos=(2.2, 1.4))
    draw_arrow(ax, (5.5, 1.8), (5.5, 1.0), label="TCP / In-Memory", color='#D35400', lw=1.8, label_pos=(5.5, 1.4))
    draw_arrow(ax, (8.8, 1.8), (8.8, 1.0), label="HTTPS SDK", color='#8E44AD', lw=1.8, label_pos=(8.8, 1.4))

    # Container 3: Data Tier & Cloud
    create_box(ax, (0.8, 0.2), 2.8, 0.8, "PostgreSQL 16 (Primary ACID)\n25+ bảng học vụ, điểm danh, hóa đơn", facecolor='#E8F8F5', edgecolor='#27AE60', text_color='#145A32', fontsize=8.5)
    create_box(ax, (4.1, 0.2), 2.8, 0.8, "Redis 7 (Cache & Bull Queue)\nIn-memory cache, điều phối Job nền", facecolor='#FEF5E7', edgecolor='#E67E22', text_color='#7E5109', fontsize=8.5)
    create_box(ax, (7.4, 0.2), 2.8, 0.8, "Firebase FCM & Storage, VNPay\nPush Notification, Audio/PDF, Payment", facecolor='#F4ECF7', edgecolor='#8E44AD', text_color='#512E5F', fontsize=8.5)

    plt.tight_layout()
    plt.savefig("docs/diagrams/diagram1_client_server.png", bbox_inches='tight', dpi=300)
    plt.close()
    print("Generated diagram1_client_server.png")

# ==============================================================================
# SƠ ĐỒ 2: LAYERED ARCHITECTURE (CLEAN ARCHITECTURE)
# ==============================================================================
def draw_diagram_2():
    fig, ax = plt.subplots(figsize=(11, 7.2), dpi=300)
    ax.set_xlim(0, 11)
    ax.set_ylim(0, 7.2)
    ax.axis('off')

    ax.text(5.5, 6.9, "SƠ ĐỒ 2: KIẾN TRÚC PHÂN TẦNG (LAYERED ARCHITECTURE / CLEAN ARCHITECTURE)",
            ha='center', va='center', fontsize=12.5, fontweight='bold', color='#1A5276')

    # Column 1: Flutter Client
    c_flutter = FancyBboxPatch((0.5, 0.5), 4.7, 6.0, boxstyle="round,pad=0.2", facecolor='#FDFEFE', edgecolor='#2980B9', lw=1.5)
    ax.add_patch(c_flutter)
    ax.text(2.85, 6.2, "[PHÍA MÁY KHÁCH (FLUTTER APP)]", ha='center', fontsize=11, fontweight='bold', color='#1A5276')

    create_box(ax, (0.8, 4.6), 4.1, 1.2, "• Màn hình: Login, ClassList, ExamTake, Invoices\n• Reusable Widgets: AppButton, AudioRecorder\n• BLoC: Quản lý trạng thái phản hồi giao diện",
               title="1. Presentation Layer (Giao diện & BLoC)", facecolor='#EAF2F8', edgecolor='#3498DB')
    
    draw_arrow(ax, (2.85, 4.6), (2.85, 3.8), color='#7F8C8D')

    create_box(ax, (0.8, 2.6), 4.1, 1.2, "• Use Cases: LoginUseCase, SubmitAudioExam...\n• Entities: User, ClassSession, Invoice (Pure Dart)\n• Repository Interfaces (Trừu tượng hóa)",
               title="2. Domain Layer (Logic nghiệp vụ lõi)", facecolor='#FEF9E7', edgecolor='#F39C12')

    draw_arrow(ax, (2.85, 2.6), (2.85, 1.8), color='#7F8C8D')

    create_box(ax, (0.8, 0.7), 4.1, 1.1, "• Repositories Implementation (Gắn kết dữ liệu)\n• Remote Data Sources (Dio HTTP Client + Interceptors)\n• Secure Storage (Lưu trữ an toàn JWT Token)",
               title="3. Data Layer (Dữ liệu & Gọi API)", facecolor='#E8F8F5', edgecolor='#1ABC9C')

    # Center communication bridge
    draw_arrow(ax, (4.9, 1.25), (6.1, 5.2), label="REST API (HTTPS)\nJWT Tokens", color='#E74C3C', lw=2, label_pos=(5.5, 3.5), label_color='#C0392B')

    # Column 2: NestJS Backend
    c_nest = FancyBboxPatch((5.8, 0.5), 4.7, 6.0, boxstyle="round,pad=0.2", facecolor='#FDFEFE', edgecolor='#27AE60', lw=1.5)
    ax.add_patch(c_nest)
    ax.text(8.15, 6.2, "[PHÍA MÁY CHỦ (NESTJS BACKEND)]", ha='center', fontsize=11, fontweight='bold', color='#145A32')

    create_box(ax, (6.1, 4.6), 4.1, 1.2, "• Controllers: AuthController, AttendanceController...\n• DTOs & Validation Pipes (Xác thực đầu vào)\n• Swagger Documentation (/api/docs)",
               title="1. Presentation Layer (Controllers / API)", facecolor='#EAF2F8', edgecolor='#3498DB')

    draw_arrow(ax, (8.15, 4.6), (8.15, 3.8), color='#7F8C8D')

    create_box(ax, (6.1, 2.6), 4.1, 1.2, "• Services: AuthService, ExamScoring, Attendance...\n• Guards: JwtAuthGuard, RolesGuard (RBAC)\n• Xếp lớp, chống trùng lịch phòng, tạo hóa đơn",
               title="2. Business Logic Layer (Dịch vụ nghiệp vụ)", facecolor='#FEF9E7', edgecolor='#F39C12')

    draw_arrow(ax, (8.15, 2.6), (8.15, 1.8), color='#7F8C8D')

    create_box(ax, (6.1, 0.7), 4.1, 1.1, "• Prisma ORM Client (Truy vấn Type-safe)\n• Database Transactions (Đảm bảo chuẩn ACID)\n• Data Mapping & SQL Indexing Optimization",
               title="3. Data Access Layer (Prisma ORM / CSDL)", facecolor='#E8F8F5', edgecolor='#27AE60')

    plt.tight_layout()
    plt.savefig("docs/diagrams/diagram2_layered.png", bbox_inches='tight', dpi=300)
    plt.close()
    print("Generated diagram2_layered.png")

# ==============================================================================
# SƠ ĐỒ 3: EVENT-DRIVEN ARCHITECTURE & BROKER
# ==============================================================================
def draw_diagram_3():
    fig, ax = plt.subplots(figsize=(11, 6.5), dpi=300)
    ax.set_xlim(0, 11)
    ax.set_ylim(0, 6.5)
    ax.axis('off')

    ax.text(5.5, 6.1, "SƠ ĐỒ 3: KIẾN TRÚC HƯỚNG SỰ KIỆN (EVENT-DRIVEN ARCHITECTURE) & MESSAGE BROKER",
            ha='center', va='center', fontsize=12.5, fontweight='bold', color='#1A5276')

    # Step 1: Teacher action
    create_box(ax, (0.5, 4.5), 2.8, 1.0, "Giáo viên mở ứng dụng di động\nĐánh dấu điểm danh lớp & bấm Lưu",
               title="1. Thao tác trên Mobile", facecolor='#EAF2F8', edgecolor='#3498DB')

    draw_arrow(ax, (3.3, 5.0), (4.3, 5.0), label="POST /attendance", color='#2980B9')

    # Step 2: Attendance Service
    create_box(ax, (4.3, 4.3), 3.0, 1.4, "• Ghi nhận dữ liệu vào PostgreSQL\n• Phát sinh sự kiện hệ thống:\n  AttendanceCompletedEvent\n  (Danh sách học viên vắng)",
               title="2. AttendanceService (NestJS)", facecolor='#FEF9E7', edgecolor='#F39C12')

    # Immediate return
    draw_arrow(ax, (4.3, 4.5), (3.3, 4.5), label="200 OK ngay lập tức\n(Không chờ gửi push)", color='#27AE60', style='<-', label_pos=(3.8, 4.1), label_color='#1E8449')

    draw_arrow(ax, (7.3, 5.0), (8.3, 5.0), label="Emit Event", color='#E67E22')

    # Step 3: Event Listener & Queue
    create_box(ax, (8.3, 4.3), 2.3, 1.4, "Lắng nghe sự kiện\nĐẩy Job vào Message Broker\nđể xử lý nền bất đồng bộ",
               title="3. Event Listener", facecolor='#F4ECF7', edgecolor='#8E44AD')

    draw_arrow(ax, (9.45, 4.3), (9.45, 3.2), label="Push Job", color='#8E44AD')

    # Step 4: Message Broker
    create_box(ax, (7.8, 2.0), 3.0, 1.2, "Redis 7 + Bull Queue Engine\nQuản lý hàng đợi tác vụ nền\nChống nghẽn & thử lại khi lỗi",
               title="Message Broker (Redis)", facecolor='#FDEDEC', edgecolor='#E74C3C', title_color='#922B21')

    # Distribute to Workers
    draw_arrow(ax, (7.8, 2.6), (6.0, 2.6), color='#D35400')

    create_box(ax, (2.6, 1.9), 3.4, 1.4, "• Worker 1: Tra cứu FCM token của Phụ huynh\n  -> Gọi Firebase Admin SDK gửi Push\n• Worker 2: Ghi bản ghi In-app notification\n  vào CSDL để xem lại trên app",
               title="4. Notification Background Workers", facecolor='#E8F8F5', edgecolor='#16A085')

    draw_arrow(ax, (2.6, 2.6), (1.6, 2.6), color='#16A085')

    # Final Result
    create_box(ax, (0.3, 1.9), 1.3, 1.4, "Điện thoại rung:\n'Thông báo: Con\nbạn vắng học\nhôm nay!'",
               title="Phụ huynh Mobile", facecolor='#D4EFDF', edgecolor='#27AE60', title_color='#196F3D', fontsize=8.5)

    plt.tight_layout()
    plt.savefig("docs/diagrams/diagram3_event_driven.png", bbox_inches='tight', dpi=300)
    plt.close()
    print("Generated diagram3_event_driven.png")

# ==============================================================================
# SƠ ĐỒ 4: PIPE-FILTER ARCHITECTURE
# ==============================================================================
def draw_diagram_4():
    fig, ax = plt.subplots(figsize=(11, 4.8), dpi=300)
    ax.set_xlim(0, 11)
    ax.set_ylim(0, 4.8)
    ax.axis('off')

    ax.text(5.5, 4.4, "SƠ ĐỒ 4: KIẾN TRÚC ĐƯỜNG ỐNG VÀ BỘ LỌC (PIPE-FILTER) TRONG XỬ LÝ YÊU CẦU",
            ha='center', va='center', fontsize=12.5, fontweight='bold', color='#1A5276')

    pipes = [
        ("HTTP Request", "Client gửi lên\nHeader & Body", '#EBF5FB', '#2980B9'),
        ("1. CORS & Helmet", "Bộ lọc Header\nChặn truy cập lạ", '#E8F8F5', '#16A085'),
        ("2. JwtAuthGuard", "Bộ lọc xác thực\nKiểm tra Token", '#FEF9E7', '#F39C12'),
        ("3. RolesGuard", "Bộ lọc phân quyền\nRBAC Permissions", '#F4ECF7', '#8E44AD'),
        ("4. ValidationPipe", "Bộ lọc DTO dữ liệu\nclass-validator", '#FDEDEC', '#E74C3C'),
        ("Controller & Service", "Xử lý nghiệp vụ\nLưu trữ CSDL", '#D4EFDF', '#27AE60'),
        ("Transform & Filter", "Chuẩn hóa JSON\nBắt ngoại lệ Exception", '#FEF5E7', '#D35400'),
        ("HTTP Response", "JSON chuẩn hóa\ntrả về Client", '#EBF5FB', '#2980B9')
    ]

    bw = 1.15
    gap = 0.15
    start_x = 0.4
    y = 1.4
    bh = 2.0

    for i, (title, desc, bg, border) in enumerate(pipes):
        x = start_x + i * (bw + gap)
        create_box(ax, (x, y), bw, bh, desc, title=title, facecolor=bg, edgecolor=border,
                   fontsize=8, title_fontsize=8.5, lw=1.4)
        if i < len(pipes) - 1:
            draw_arrow(ax, (x + bw, y + bh / 2.0), (x + bw + gap, y + bh / 2.0), color='#2C3E50', lw=1.5)

    plt.tight_layout()
    plt.savefig("docs/diagrams/diagram4_pipe_filter.png", bbox_inches='tight', dpi=300)
    plt.close()
    print("Generated diagram4_pipe_filter.png")

draw_diagram_1()
draw_diagram_2()
draw_diagram_3()
draw_diagram_4()
print("All 4 diagrams drawn successfully!")
