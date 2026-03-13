-- CreateTable
CREATE TABLE "VpnNode" (
    "id" TEXT NOT NULL,
    "nodeId" TEXT NOT NULL,
    "location" TEXT NOT NULL,
    "countryCode" TEXT NOT NULL,
    "endpoint" TEXT NOT NULL,
    "purpose" TEXT NOT NULL DEFAULT 'general',
    "capacity" INTEGER NOT NULL DEFAULT 1000,
    "currentLoad" INTEGER NOT NULL DEFAULT 0,
    "configType" TEXT NOT NULL DEFAULT 'vless',
    "vlessUri" TEXT,
    "singboxConfig" TEXT,
    "status" TEXT NOT NULL DEFAULT 'active',
    "healthCheckUrl" TEXT,
    "lastHealthCheck" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "VpnNode_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "VpnNode_nodeId_key" ON "VpnNode"("nodeId");

-- CreateIndex
CREATE INDEX "VpnNode_status_idx" ON "VpnNode"("status");

-- CreateIndex
CREATE INDEX "VpnNode_purpose_idx" ON "VpnNode"("purpose");

-- CreateIndex
CREATE INDEX "VpnNode_countryCode_idx" ON "VpnNode"("countryCode");
