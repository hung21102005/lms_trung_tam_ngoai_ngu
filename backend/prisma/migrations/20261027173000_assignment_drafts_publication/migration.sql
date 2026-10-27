CREATE TYPE "AssignmentStatus" AS ENUM ('DRAFT', 'PUBLISHED', 'CLOSED');

ALTER TYPE "SubmissionStatus" ADD VALUE 'DRAFT';

ALTER TABLE "assignments"
  ADD COLUMN "status" "AssignmentStatus" NOT NULL DEFAULT 'PUBLISHED';

ALTER TABLE "submissions"
  ALTER COLUMN "submittedAt" DROP NOT NULL,
  ALTER COLUMN "submittedAt" DROP DEFAULT,
  ADD COLUMN "resultPublishedAt" TIMESTAMP(3);

-- Existing graded results were already visible before this migration.
UPDATE "submissions"
SET "resultPublishedAt" = COALESCE("gradedAt", "updatedAt")
WHERE "status" = 'GRADED' AND "score" IS NOT NULL;
