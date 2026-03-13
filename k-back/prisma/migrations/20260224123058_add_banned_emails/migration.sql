-- CreateTable
CREATE TABLE "BannedEmail" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "previousUsername" TEXT,
    "previousVtNumber" TEXT,
    "reason" TEXT,
    "bannedBy" TEXT NOT NULL DEFAULT 'admin',
    "bannedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "BannedEmail_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "BannedEmail_email_key" ON "BannedEmail"("email");

-- CreateIndex
CREATE INDEX "BannedEmail_email_idx" ON "BannedEmail"("email");
