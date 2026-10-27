import urllib.request
import base64
import time

diags = {
    'task2_seq_attendance': '''sequenceDiagram
    autonumber
    actor GV as Giao vien (Mobile App)
    participant API as NestJS API Server (P3)
    participant DB as PostgreSQL (P5)
    participant REDIS as Redis Bull Queue (P6)
    participant WORKER as Background Worker (P4)
    actor PH as Phu huynh (Mobile)

    Note over GV, API: DONG BO (SYNCHRONOUS RPC) - DUOI 50ms
    GV->>API: POST /sessions/101/attendance [HV_01: Co, HV_02: Vang]
    API->>DB: BEGIN TRANSACTION
    API->>DB: INSERT INTO attendance_records
    API->>DB: UPDATE sessions SET status = 'COMPLETED'
    DB-->>API: COMMIT SUCCESS
    API->>REDIS: LPUSH notification_queue
    API-->>GV: 200 OK: Diem danh hoan tat thanh cong!

    Note over REDIS, PH: BAT DONG BO (ASYNC MESSAGE PASSING)
    WORKER->>REDIS: BRPOP notification_queue
    REDIS-->>WORKER: Tra ve Job: studentId: HV_02
    WORKER->>DB: Query Parent Token
    DB-->>WORKER: Device Token
    WORKER->>PH: Push Notification qua Google FCM
    PH-->>WORKER: Ack 200
    WORKER->>DB: INSERT INTO notifications_history
''',

    'task3_component_interfaces': '''flowchart LR
    subgraph PRESENTATION["Presentation Components"]
        CTRL["ApiControllers.bundle\n(NestJS Routing and DTO Pipes)"]
    end
    subgraph SERVICES["Business Service Components"]
        SVCS["LmsCoreServices.bundle\n(Auth, Academic, Scoring, Finance)"]
    end
    subgraph DATA["Data Access Components"]
        PRISMA["PrismaDataAccess.bundle\n(Type-safe Query Engine)"]
    end
    subgraph ADAPTERS["External Adapters"]
        NOTI["NotificationAdapter.bundle\n(FCM and Mailer Engine)"]
        PAY["PaymentAdapter.bundle\n(VNPay Gateway Adapter)"]
    end
    CTRL -->|use ICoreService| SVCS
    SVCS -->|use IDataPersistence| PRISMA
    SVCS -->|use INotificationQueue| NOTI
    SVCS -->|use IPaymentProvider| PAY
'''
}

for name, code in diags.items():
    raw_b64 = base64.b64encode(code.strip().encode('utf-8')).decode('ascii')
    url = f'https://mermaid.ink/img/{raw_b64}'
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'})
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            data = resp.read()
        with open(f'docs/diagrams_generated/{name}.png', 'wb') as f:
            f.write(data)
        print(f'{name} SUCCESS: {len(data)} bytes')
    except Exception as e:
        print(f'{name} FAILED:', e)
    time.sleep(1)

print("Done render missing!")
