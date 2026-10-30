import urllib.request
import base64
import json
import os
import time

diagrams = {
    "task1_class_diagram": """classDiagram
    class BaseEntity {
        +String id
        +DateTime createdAt
        +DateTime updatedAt
        +delete()
    }
    class User {
        +String username
        -String passwordHash
        +String email
        +String phone
        +UserRole role
        +UserStatus status
        +verifyPassword()
        +changePassword()
    }
    class StudentProfile {
        +String studentCode
        +DateTime dateOfBirth
        +Gender gender
        +getEnrolledClasses()
    }
    class TeacherProfile {
        +String teacherCode
        +String specialization
        +getAssignedClasses()
    }
    class ParentProfile {
        +String parentCode
        +getChildren()
    }
    class Branch {
        +String code
        +String name
        +addRoom()
    }
    class Room {
        +String roomNumber
        +Int capacity
        +isAvailable()
    }
    class Course {
        +String code
        +String title
        +Decimal basePrice
        +createClass()
    }
    class Class {
        +String classCode
        +String name
        +ClassStatus status
        +Int minStudents
        +Int maxStudents
        +generateSessions()
        +enrollStudent()
    }
    class Session {
        +Int sessionNumber
        +DateTime date
        +markAttendance()
    }
    class Enrollment {
        +DateTime enrolledAt
        +EnrollmentStatus status
    }
    class AttendanceRecord {
        +AttendanceStatus status
        +String note
    }
    class Assignment {
        +String title
        +DateTime deadline
    }
    class AssignmentSubmission {
        +String fileAttachmentUrl
        +String audioRecordingUrl
        +Decimal score
        +gradeSubmission()
    }
    class Exam {
        +String title
        +Int durationMinutes
        +publishExam()
    }
    class ExamQuestion {
        +Int orderNumber
        +String promptText
        +Decimal points
    }
    class ExamAttempt {
        +DateTime startedAt
        +Decimal earnedScore
        +autoGradeObjective()
    }
    class Invoice {
        +String invoiceCode
        +Decimal amount
        +InvoiceStatus status
        +markAsPaid()
    }
    class PaymentReceipt {
        +String transactionRef
        +Decimal paidAmount
    }

    BaseEntity <|-- User
    BaseEntity <|-- Branch
    BaseEntity <|-- Course
    BaseEntity <|-- Class
    BaseEntity <|-- Exam
    BaseEntity <|-- Invoice

    User <|-- StudentProfile
    User <|-- TeacherProfile
    User <|-- ParentProfile

    Class "1" *-- "1..*" Session : consists of
    Exam "1" *-- "1..*" ExamQuestion : includes
    Invoice "1" *-- "0..*" PaymentReceipt : produces

    Branch "1" o-- "1..*" Room : houses
    Course "1" o-- "0..*" Class : defines
    Class "1" o-- "0..*" Assignment : assigns
    Class "1" o-- "0..*" Exam : organizes
    Class "1" o-- "0..*" Enrollment : registers

    StudentProfile "1" -- "0..*" Enrollment
    StudentProfile "1" -- "0..*" AssignmentSubmission
    StudentProfile "1" -- "0..*" ExamAttempt
    StudentProfile "1" -- "0..*" Invoice
    ParentProfile "1..*" -- "1..*" StudentProfile
    TeacherProfile "1" -- "0..*" Class
    Session "1" -- "0..*" AttendanceRecord
""",

    "task1_package_diagram": """flowchart TD
    subgraph PRESENTATION["Presentation Layer (Giao dien & Dieu khien)"]
        AUTH_CTRL["AuthController"]
        CLASS_CTRL["ClassController"]
        ATT_CTRL["AttendanceController"]
        EXAM_CTRL["ExamController"]
        FIN_CTRL["FinanceController"]
    end

    subgraph BUSINESS["Business Logic Layer (Dich vu Nghiep vu)"]
        AUTH_SVC["AuthService (Xac thuc, RBAC)"]
        CLASS_SVC["ClassService (Xep lop, chong trung phong)"]
        ATT_SVC["AttendanceService (Diem danh, thong bao)"]
        EXAM_SVC["ExamService (Dem gio, cham trac nghiem)"]
        FIN_SVC["FinanceService (Hoc phi, doi soat VNPay)"]
    end

    subgraph DATA["Data Access Layer (Truy xuat Du lieu)"]
        PRISMA["PrismaClient (PostgreSQL ORM)"]
        USER_REPO["UserRepository"]
        CLASS_REPO["ClassRepository"]
        EXAM_REPO["ExamRepository"]
        FIN_REPO["FinanceRepository"]
    end

    PRESENTATION -->|calls| BUSINESS
    BUSINESS -->|calls| DATA
""",

    "task1_state_class": """stateDiagram-v2
    [*] --> PLANNING : Tao lop hoc du kien
    PLANNING --> OPEN_FOR_ENROLLMENT : Duyet mo tuyen sinh [Da gan GV & Phong]
    OPEN_FOR_ENROLLMENT --> OPEN_FOR_ENROLLMENT : Hoc vien ghi danh [Si so < max_students]
    OPEN_FOR_ENROLLMENT --> CANCELLED : Huy lop [Den han ma Si so < min_students]
    OPEN_FOR_ENROLLMENT --> IN_PROGRESS : Khai giang [Si so >= min_students && Den ngay bat dau]

    state IN_PROGRESS {
        [*] --> TEACHING_SESSION
        TEACHING_SESSION --> ATTENDANCE_MARKED : Giao vien diem danh buoi hoc
        ATTENDANCE_MARKED --> TEACHING_SESSION : Sang buoi tiep theo
        ATTENDANCE_MARKED --> MIDTERM_EXAM : Thi giua ky
        MIDTERM_EXAM --> TEACHING_SESSION : Hoan tat thi
    }

    IN_PROGRESS --> COMPLETED : Ket thuc khoa hoc [Tat ca Session COMPLETED]
    COMPLETED --> ARCHIVED : Luu tru ho so hoc vu
    CANCELLED --> [*] : Hoan hoc phi
    ARCHIVED --> [*]
""",

    "task1_state_exam": """stateDiagram-v2
    [*] --> READY : Hoc vien mo man hinh bai thi
    READY --> IN_PROGRESS : Bam Bat dau lam bai [Server Timer khoi dong]

    state IN_PROGRESS {
        [*] --> ANSWERING
        ANSWERING --> SAVING_TEMP : Tu dong luu dap an cuc bo (moi 15s)
        SAVING_TEMP --> ANSWERING : Luu thanh cong
        ANSWERING --> NETWORK_LOST : Mat ket noi
        NETWORK_LOST --> ANSWERING : Co mang tro lai
    }

    IN_PROGRESS --> SUBMITTED : Hoc vien bam Nop bai
    IN_PROGRESS --> SUBMITTED : Het gio thi [serverTimer <= 0 / Tu dong nop]
    SUBMITTED --> AUTO_GRADING : Tu dong cham trac nghiem
    AUTO_GRADING --> PENDING_TEACHER_REVIEW : De thi co cau tu luan / ghi am noi
    AUTO_GRADING --> GRADED : De thi 100% trac nghiem
    PENDING_TEACHER_REVIEW --> GRADED : Giao vien hoan tat cham diem
    GRADED --> PUBLISHED : Cong bo diem cho Hoc vien & Phu huynh
    PUBLISHED --> [*]
""",

    "task2_process_overview": """flowchart TD
    subgraph CLIENT_TIER["Phia Thiet bi Nguoi dung (Client Processes)"]
        P1["«process» P1: FlutterMobileApp\n(App Android/iOS - Hoc vien / GV / PH)"]
        P2["«process» P2: FlutterWebPortal\n(Browser - Admin / Hoc vu / Thu ngan)"]
    end

    subgraph SERVER_TIER["Phia May chu Trung tam (Server Processes)"]
        P3["«process» P3: NestJS_APIServer\n(Node.js RESTful API & WebSocket Core)"]
        P4["«process» P4: BullQueue_BackgroundWorker\n(Node.js Worker - Async Tasks)"]
    end

    subgraph DATA_TIER["Phia Luu tru & Du lieu (Data Processes)"]
        P5["«process» P5: PostgreSQL_DatabaseEngine\n(Postmaster & Dedicated Backend Workers)"]
        P6["«process» P6: Redis_Server\n(In-Memory Cache & Message Broker)"]
    end

    P1 == "HTTPS / WSS" ==> P3
    P2 == "HTTPS / REST" ==> P3
    P3 == "Job Queue" ==> P6
    P4 == "Pop Jobs" ==> P6
    P3 == "SQL Queries (ACID)" ==> P5
    P4 == "Update State" ==> P5
    P3 == "Session / Cache" ==> P6
""",

    "task2_threads_breakdown": """flowchart LR
    subgraph P1["P1: FlutterMobileApp"]
        T1_1["UI Thread / Main Isolate (60fps)"]
        T1_2["Audio Recorder Isolate"]
        T1_3["SQLite Local Storage Thread"]
    end

    subgraph P3["P3: NestJS_APIServer"]
        T3_1["Node.js Main Event Loop"]
        T3_2["Libuv Worker Thread Pool (Bcrypt/Crypto)"]
        T3_3["Prisma DB Connection Pool"]
    end

    subgraph P4["P4: BullQueue_Worker"]
        T4_1["Queue Consumer Thread"]
        T4_2["FCM Push Notification Thread"]
        T4_3["SMTP Mailer Thread"]
        T4_4["Daily Cron Scheduler Thread"]
    end

    subgraph P5["P5: PostgreSQL Engine"]
        T5_1["Postmaster Listener"]
        T5_2["Backend Query Workers"]
        T5_3["WAL Writer & Checkpointer"]
        T5_4["Autovacuum Thread"]
    end
""",

    "task2_active_class_process": """flowchart LR
    subgraph CLIENT["Client Tier"]
        C1["«process»\nmobileClient: FlutterApp\n{location=MobileDevice}"]
        C2["«process»\nwebPortal: FlutterWeb\n{location=AdminPC}"]
    end

    subgraph API_TIER["Application Server Tier"]
        A1["«process»\napiServer: NestJSInstance\n{location=BackendHost}"]
        A2["«thread»\neventDispatcher: EventEmitter\n{concurrent}"]
    end

    subgraph WORKER_TIER["Async Worker Tier"]
        W1["«process»\njobWorker: BullWorker\n{location=WorkerHost}"]
    end

    subgraph DATA_TIER["Data Storage Tier"]
        D1["«process»\nmsgBroker: RedisServer\n{location=CacheHost}"]
        D2["«process»\ndbMaster: PostgreSQL\n{location=DatabaseHost}"]
    end

    C1 == "«https/json»" ==> A1
    C2 == "«https/json»" ==> A1
    A1 --> A2
    A1 == "«tcp/ip» pool" ==> D2
    A2 == "push job" ==> D1
    D1 == "pop job" ==> W1
    W1 == "update" ==> D2
""",

    "task2_seq_attendance": """sequenceDiagram
    autonumber
    actor GV as Giao vien (Mobile App)
    participant API as NestJS API Server (P3)
    participant DB as PostgreSQL (P5)
    participant REDIS as Redis Bull Queue (P6)
    participant WORKER as Background Worker (P4)
    actor PH as Phu huynh (Mobile)

    Note over GV, API: DONG BO (SYNCHRONOUS RPC) - DUOI 50ms
    GV->>+API: POST /sessions/101/attendance [HV_01: Co, HV_02: Vang]
    API->>+DB: BEGIN TRANSACTION
    API->>DB: INSERT INTO attendance_records
    API->>DB: UPDATE sessions SET status = 'COMPLETED'
    DB-->>-API: COMMIT SUCCESS
    API->)REDIS: LPUSH notification_queue {studentId: HV_02, type: 'ABSENT'}
    API-->>-GV: 200 OK: Diem danh hoan tat thanh cong!
    Note over GV: Giao vien nhan phan hoi ngay lap tuc

    Note over REDIS, PH: BAT DONG BO (ASYNC MESSAGE PASSING)
    WORKER->>+REDIS: BRPOP notification_queue
    REDIS-->>-WORKER: Tra ve Job: studentId: HV_02
    WORKER->>+DB: Query Parent Token
    DB-->>-WORKER: Device Token
    WORKER->>+PH: Push Notification qua Google FCM: Hoc vien vang hoc
    PH-->>-WORKER: Ack 200
    WORKER->>DB: INSERT INTO notifications_history
""",

    "task2_seq_concurrency_lock": """sequenceDiagram
    autonumber
    actor HA as Hoc vien A (App)
    actor HB as Hoc vien B (App)
    participant API as NestJS API Server
    participant DB as PostgreSQL Database

    Note over HA, HB: Lop hoc chi con dung 1 suat (current=19, max=20)
    par A bam truoc 5ms
        HA->>+API: POST /classes/ENG_01/enroll (Hoc vien A)
    and B bam sau 5ms
        HB->>+API: POST /classes/ENG_01/enroll (Hoc vien B)
    end

    API->>+DB: BEGIN TRANSACTION A
    API->>DB: SELECT * FROM classes WHERE id='ENG_01' FOR UPDATE;
    Note over DB: PostgreSQL KHOA HANG (Row Lock) cho Giao dich A

    API->>DB: BEGIN TRANSACTION B
    API->>DB: SELECT * FROM classes WHERE id='ENG_01' FOR UPDATE;
    Note over DB: Giao dich B BI CHAN (BLOCKED) - Cho Giao dich A

    API->>DB: UPDATE classes SET currentStudents = 20 WHERE id='ENG_01';
    API->>DB: INSERT INTO enrollments (student_id='A');
    API->>DB: COMMIT TRANSACTION A;
    DB-->>-API: Commit A Thanh cong
    API-->>-HA: 200 OK: Ghi danh thanh cong!

    Note over DB: Giao dich A hoan tat -> GIAI PHONG KHOA -> Giao dich B CHAY
    DB-->>API: Tra ve data cho B: current=20, max=20
    Note over DB: Giao dich B kiem tra: current (20) >= max (20) -> HET CHO
    API->>DB: ROLLBACK TRANSACTION B;
    API-->>-HB: 409 Conflict: Lop hoc da du si so!
""",

    "task3_source_dependency": """flowchart TD
    subgraph COMMON["src/common/ (Bao ve he thong)"]
        JWT_GUARD["«source»\njwt-auth.guard.ts"]
        ROLES_GUARD["«source»\nroles.guard.ts"]
        VALID_PIPE["«source»\nvalidation.pipe.ts"]
    end

    subgraph CONTROLLERS["src/controllers/ (Tang Dieu khien)"]
        AUTH_CTRL["«source»\nauth.controller.ts"]
        CLASS_CTRL["«source»\nclasses.controller.ts"]
        ATT_CTRL["«source»\nattendance.controller.ts"]
        EXAM_CTRL["«source»\nexams.controller.ts"]
        FIN_CTRL["«source»\nfinance.controller.ts"]
    end

    subgraph SERVICES["src/services/ (Tang Nghiep vu)"]
        AUTH_SVC["«source»\nauth.service.ts"]
        CLASS_SVC["«source»\nclasses.service.ts"]
        ATT_SVC["«source»\nattendance.service.ts"]
        EXAM_SVC["«source»\nexams.service.ts"]
        FIN_SVC["«source»\nfinance.service.ts"]
        VNPAY_SVC["«source»\nvnpay.service.ts"]
    end

    subgraph DATA["prisma/ & database/ (Tang Du lieu)"]
        PRISMA_SVC["«source»\nprisma.service.ts"]
        SCHEMA_PRISMA["«source»\nschema.prisma"]
    end

    AUTH_CTRL -->|«import»| JWT_GUARD
    AUTH_CTRL -->|«import»| VALID_PIPE
    AUTH_CTRL -->|«import»| AUTH_SVC

    CLASS_CTRL -->|«import»| JWT_GUARD
    CLASS_CTRL -->|«import»| ROLES_GUARD
    CLASS_CTRL -->|«import»| CLASS_SVC

    ATT_CTRL -->|«import»| ATT_SVC
    EXAM_CTRL -->|«import»| EXAM_SVC
    FIN_CTRL -->|«import»| FIN_SVC
    FIN_SVC -->|«import»| VNPAY_SVC

    AUTH_SVC -->|«import»| PRISMA_SVC
    CLASS_SVC -->|«import»| PRISMA_SVC
    ATT_SVC -->|«import»| PRISMA_SVC
    EXAM_SVC -->|«import»| PRISMA_SVC
    FIN_SVC -->|«import»| PRISMA_SVC

    PRISMA_SVC -->|«import»| SCHEMA_PRISMA
""",

    "task3_component_interfaces": """flowchart LR
    subgraph PRESENTATION["Presentation Components"]
        CTRL["ApiControllers.bundle\n(NestJS Routing & DTO Pipes)"]
    end

    subgraph SERVICES["Business Service Components"]
        SVCS["LmsCoreServices.bundle\n(Auth, Academic, Scoring, Finance)"]
    end

    subgraph DATA["Data Access Components"]
        PRISMA["PrismaDataAccess.bundle\n(Type-safe Query Engine)"]
    end

    subgraph ADAPTERS["External Adapters"]
        NOTI["NotificationAdapter.bundle\n(FCM & Mailer Engine)"]
        PAY["PaymentAdapter.bundle\n(VNPay Gateway Adapter)"]
    end

    CTRL -->|«use» ICoreService| SVCS
    SVCS -->|«use» IDataPersistence| PRISMA
    SVCS -->|«use» INotificationQueue| NOTI
    SVCS -->|«use» IPaymentProvider| PAY
""",

    "task3_executable_release": """flowchart TD
    subgraph LIBS["«library» / «binary» Thu vien phu thuoc"]
        DIO["«library»\ndio.aar / pod"]
        NEST["«library»\n@nestjs/core.js"]
        PRISMA_BIN["«binary»\nquery-engine-alpine"]
        REDIS_LIB["«library»\nioredis.js"]
    end

    subgraph EXEC["«executable» Ban phat hanh thuc thi"]
        APK["«executable»\nlms_mobile_app.apk\n(Android Release)"]
        WEB["«executable»\nlms_web_portal/\n(HTML5 / JS App)"]
        NODE["«executable»\nnest_backend_server.js\n(Node.js Production Dist)"]
        WORKER["«executable»\nbackground_worker.js\n(Bull Queue Runner)"]
    end

    APK -->|«link»| DIO
    NODE -->|«link»| NEST
    NODE -->|«link»| PRISMA_BIN
    NODE -->|«link»| REDIS_LIB
    WORKER -->|«link»| REDIS_LIB
    WORKER -->|«link»| PRISMA_BIN
""",

    "task3_change_impact": """flowchart TD
    S1["1. Thay doi CSDL:\nschema.prisma\n(Them truong maxStudents)"] --> S2["2. Sinh lai Client:\n@prisma/client\n(prisma generate)"]
    S2 --> S3["3. Cap nhat DTO:\ncreate-class.dto.ts"]
    S3 --> S4["4. Sua logic nghiep vu:\nclasses.service.ts"]
    S4 --> S5["5. Bien dich lai:\nclasses.controller.ts"]
    S5 --> S6["6. Dong goi lai:\nnest_backend_server.js"]
    S3 -.-> S7["7. Cap nhat Model Client:\nclass_model.dart"]
    S7 --> S8["8. Render lai UI:\nclass_form_screen.dart"]
""",

    "task4_deployment_diagram": """flowchart TD
    subgraph NODE_MOBILE["«device» :MobileDevice [Hoc vien / GV / PH]"]
        M_SPEC["OS: Android 8.0+ / iOS 13+\nRAM: 2-4 GB | Network: 4G/Wi-Fi\nHardware: Mic, Speaker, Camera"]
        subgraph M_DEPLOY["Deploys"]
            M_APP["«artifact» lms_mobile_app.apk / .ipa"]
            M_SQLITE["«artifact» SQLite Local Cache"]
        end
    end

    subgraph NODE_ADMIN_PC["«device» :AdminWorkstation [Hoc vu / Thu ngan]"]
        W_SPEC["OS: Windows 11 / macOS\nRAM: >= 4 GB | Resolution: 1920x1080\nBrowser: Chrome / Edge / Safari"]
        subgraph W_DEPLOY["Deploys"]
            W_PORTAL["«artifact» lms_web_portal (Web Browser)"]
        end
    end

    subgraph NODE_PROXY["«processor» S1 :ReverseProxyServer [DMZ Host]"]
        P_SPEC["IP: 103.x.x.x (Public) | OS: Ubuntu 22.04\nCPU: 2 vCPU 2.4GHz | RAM: 2 GB\nPorts: 80, 443"]
        subgraph P_DEPLOY["Deploys"]
            P_NGINX["«artifact» Nginx 1.24 (SSL/TLS 1.3 Term)"]
            P_STATIC["«artifact» Static Web Assets (/web_dist)"]
        end
    end

    subgraph NODE_BACKEND["«processor» S2 :ApplicationServer [Private LAN]"]
        B_SPEC["IP: 10.0.1.10 (Internal) | OS: Ubuntu 22.04\nCPU: 4 vCPU 3.0GHz | RAM: 8 GB\nRuntime: Docker Engine 24.x"]
        subgraph B_DEPLOY["Deploys"]
            B_API["«artifact» lms_api_server (NestJS :3000)"]
            B_WORKER["«artifact» lms_background_worker (Bull Queue)"]
            B_PRISMA["«artifact» prisma_query_engine.so"]
        end
    end

    subgraph NODE_REDIS["«processor» S3 :CacheServer [Database LAN]"]
        R_SPEC["IP: 10.0.1.20 | OS: Alpine Linux\nCPU: 2 vCPU | RAM: 4 GB\nPort: 6379 (requirepass)"]
        subgraph R_DEPLOY["Deploys"]
            R_REDIS["«artifact» Redis 7.2 In-Memory Store"]
        end
    end

    subgraph NODE_POSTGRES["«processor» S4 :DatabaseServer [Database LAN]"]
        D_SPEC["IP: 10.0.1.30 | OS: RHEL 9 / Ubuntu\nCPU: 4 vCPU 3.2GHz | RAM: 8 GB ECC\nStorage: 150 GB NVMe (RAID-10) | Port: 5432"]
        subgraph D_DEPLOY["Deploys"]
            D_PG["«artifact» PostgreSQL 16.2 Engine"]
            D_DB["«artifact» lms_production_db (25+ Tables)"]
        end
    end

    subgraph CLOUD_FIREBASE["«cloud environment» Google Cloud / Firebase"]
        F_FCM["«service» Firebase Cloud Messaging"]
        F_STORAGE["«service» Cloud Storage (Audio/PDF)"]
    end

    subgraph CLOUD_VNPAY["«cloud environment» VNPay Payment Gateway"]
        V_GW["«service» VNPay IPN & Payment Processing"]
    end

    NODE_MOBILE == "«HTTPS / TLS 1.3» (443)" ==> NODE_PROXY
    NODE_MOBILE -. "«WSS» (443)" .-> NODE_PROXY
    NODE_ADMIN_PC == "«HTTPS / TLS 1.3» (443)" ==> NODE_PROXY
    NODE_PROXY == "«HTTP Reverse Proxy» (3000)" ==> NODE_BACKEND
    NODE_BACKEND == "«TCP/IP RESP» (6379)" ==> NODE_REDIS
    NODE_BACKEND == "«TCP/IP PostgreSQL» (5432)" ==> NODE_POSTGRES
    NODE_BACKEND == "«HTTPS / REST» (443)" ==> CLOUD_FIREBASE
    NODE_BACKEND == "«HTTPS / SHA-512» (443)" ==> CLOUD_VNPAY
""",

    "task4_network_architecture": """flowchart LR
    subgraph PUBLIC_ZONE["Public Internet"]
        USER_M["Mobile Users"]
        USER_W["Web Users"]
    end

    subgraph DMZ_ZONE["Demilitarized Zone (DMZ)"]
        NGINX["Nginx SSL Proxy\n(Port 80/443 Public)"]
        FIREWALL_1["External Firewall"]
    end

    subgraph APP_ZONE["Internal Application Zone"]
        APP["NestJS API Cluster\n(Port 3000 Private)"]
        WORKER["Background Worker"]
        FIREWALL_2["Internal Firewall"]
    end

    subgraph DATA_ZONE["Isolated Database Zone"]
        PG["PostgreSQL Primary\n(Port 5432 Strict)"]
        REDIS["Redis Cache\n(Port 6379 Strict)"]
    end

    PUBLIC_ZONE --> FIREWALL_1 --> NGINX
    NGINX --> FIREWALL_2 --> APP
    APP --> WORKER
    APP --> PG
    APP --> REDIS
    WORKER --> REDIS
    WORKER --> PG
""",

    "task4_views_alignment": """flowchart TD
    LV["1. LOGICAL VIEW (Task #1)\n- Cac Class: Class, User, Exam, Attendance\n- Cac quan he: Composition, Aggregation"]
    PV["2. PROCESS VIEW (Task #2)\n- Cac Process: P1 (App), P3 (API), P5 (DB)\n- Co che dong bo: Guarded Lock / Pessimistic"]
    IV["3. IMPLEMENTATION VIEW (Task #3)\n- File nguon: auth.service.ts, class.controller.ts\n- File thuc thi: lms_mobile.apk, dist/main.js"]
    DV["4. DEPLOYMENT VIEW (Task #4)\n- Cac Node: Mobile, Server, DB, Cloud\n- Anh xa: Deploys lms_mobile.apk len Mobile"]

    LV -->|Chi dinh luong runtime| PV
    LV -->|Anh xa sang file ma nguon| IV
    PV -->|Phan bo tien trinh len phan cung| DV
    IV -->|Trien khai file thuc thi len node| DV
"""
}

out_dir = r"c:\Users\Vi-Hung\my_flutter_pj\XD_HT_LMS\lms_trung_tam_ngoai_ngu\docs\diagrams_generated"

for name, code in diagrams.items():
    png_path = os.path.join(out_dir, f"{name}.png")
    if os.path.exists(png_path) and os.path.getsize(png_path) > 1000:
        print(f"Skipping existing: {name}")
        continue
    raw_b64 = base64.b64encode(code.strip().encode('utf-8')).decode('ascii')
    url = f"https://mermaid.ink/img/{raw_b64}"
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'})
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            data = resp.read()
        with open(png_path, "wb") as f:
            f.write(data)
        print(f"Successfully rendered: {name} ({len(data)} bytes)")
    except Exception as e:
        print(f"Failed to render {name}: {e}")
    time.sleep(0.5)

print("All diagrams processed!")
