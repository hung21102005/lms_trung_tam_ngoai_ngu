-- Additive curriculum catalog foundation. Existing course/class IDs remain unchanged.
CREATE TYPE "PublicationStatus" AS ENUM ('DRAFT', 'IN_REVIEW', 'PUBLISHED', 'ARCHIVED');

CREATE TABLE "training_programs" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "nameVi" TEXT NOT NULL,
    "nameEn" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "description" TEXT,
    "targetAudience" TEXT,
    "learningPath" JSONB,
    "language" TEXT NOT NULL DEFAULT 'English',
    "status" "PublicationStatus" NOT NULL DEFAULT 'DRAFT',
    "isPublic" BOOLEAN NOT NULL DEFAULT false,
    "displayOrder" INTEGER NOT NULL DEFAULT 0,
    "thumbnailUrl" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "training_programs_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "training_programs_code_key" ON "training_programs"("code");
CREATE UNIQUE INDEX "training_programs_slug_key" ON "training_programs"("slug");

ALTER TABLE "courses"
    ADD COLUMN "programId" TEXT,
    ADD COLUMN "slug" TEXT,
    ADD COLUMN "publicationStatus" "PublicationStatus" NOT NULL DEFAULT 'DRAFT',
    ADD COLUMN "curriculumVersion" TEXT NOT NULL DEFAULT '1.0',
    ADD COLUMN "publicDescription" TEXT,
    ADD COLUMN "academicProfile" JSONB;

-- Preserve the current visibility of existing active courses; new courses default to draft.
UPDATE "courses" SET "publicationStatus" = 'PUBLISHED' WHERE "isActive" = true;

CREATE UNIQUE INDEX "courses_slug_key" ON "courses"("slug");
CREATE INDEX "courses_programId_idx" ON "courses"("programId");
ALTER TABLE "courses" ADD CONSTRAINT "courses_programId_fkey"
    FOREIGN KEY ("programId") REFERENCES "training_programs"("id")
    ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "course_levels"
    ADD COLUMN "cefrLevel" TEXT,
    ADD COLUMN "ieltsTargetBand" DECIMAL(3,1),
    ADD COLUMN "toeicTargetScore" INTEGER,
    ADD COLUMN "cambridgeQualification" TEXT,
    ADD COLUMN "entryRequirements" TEXT,
    ADD COLUMN "expectedOutcomes" JSONB,
    ADD COLUMN "assessmentScheme" JSONB,
    ADD COLUMN "completionCriteria" TEXT,
    ADD COLUMN "recommendedHours" INTEGER,
    ADD COLUMN "curriculumVersion" TEXT NOT NULL DEFAULT '1.0';
