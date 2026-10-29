CREATE TYPE "RegistrationStatus" AS ENUM ('PENDING', 'CONTACTED', 'APPROVED', 'REJECTED', 'CANCELLED');

CREATE TABLE "class_registrations" (
    "id" TEXT NOT NULL,
    "classId" TEXT NOT NULL,
    "applicantKey" TEXT NOT NULL,
    "fullName" TEXT NOT NULL,
    "phone" TEXT NOT NULL,
    "email" TEXT,
    "status" "RegistrationStatus" NOT NULL DEFAULT 'PENDING',
    "studentId" TEXT,
    "leadId" TEXT,
    "notes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "class_registrations_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "class_registrations_classId_applicantKey_key" ON "class_registrations"("classId", "applicantKey");
CREATE INDEX "class_registrations_classId_status_createdAt_idx" ON "class_registrations"("classId", "status", "createdAt");
CREATE INDEX "class_registrations_studentId_createdAt_idx" ON "class_registrations"("studentId", "createdAt");

ALTER TABLE "class_registrations" ADD CONSTRAINT "class_registrations_classId_fkey" FOREIGN KEY ("classId") REFERENCES "classes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "class_registrations" ADD CONSTRAINT "class_registrations_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "class_registrations" ADD CONSTRAINT "class_registrations_leadId_fkey" FOREIGN KEY ("leadId") REFERENCES "admission_leads"("id") ON DELETE SET NULL ON UPDATE CASCADE;
