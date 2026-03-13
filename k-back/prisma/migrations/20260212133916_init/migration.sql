-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "password" TEXT NOT NULL,
    "username" TEXT NOT NULL,
    "vtNumber" TEXT NOT NULL,
    "emailVerified" BOOLEAN NOT NULL DEFAULT false,
    "emailVerificationToken" TEXT,
    "isPremium" BOOLEAN NOT NULL DEFAULT false,
    "premiumPlan" TEXT,
    "premiumExpiresAt" TIMESTAMP(3),
    "premiumActivatedWith" TEXT,
    "lastUsernameChangeAt" TIMESTAMP(3),
    "matrixUserId" TEXT,
    "matrixAccessToken" TEXT,
    "region" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ActivationPassword" (
    "id" TEXT NOT NULL,
    "password" TEXT NOT NULL,
    "plan" TEXT NOT NULL,
    "duration" INTEGER NOT NULL,
    "maxUses" INTEGER NOT NULL DEFAULT 1,
    "currentUses" INTEGER NOT NULL DEFAULT 0,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdBy" TEXT NOT NULL DEFAULT 'admin',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ActivationPassword_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "User_vtNumber_key" ON "User"("vtNumber");

-- CreateIndex
CREATE UNIQUE INDEX "User_matrixUserId_key" ON "User"("matrixUserId");

-- CreateIndex
CREATE INDEX "User_email_idx" ON "User"("email");

-- CreateIndex
CREATE INDEX "User_vtNumber_idx" ON "User"("vtNumber");

-- CreateIndex
CREATE UNIQUE INDEX "ActivationPassword_password_key" ON "ActivationPassword"("password");

-- CreateIndex
CREATE INDEX "ActivationPassword_password_idx" ON "ActivationPassword"("password");
