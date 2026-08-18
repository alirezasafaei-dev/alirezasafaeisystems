-- Add the lead table before the UTM content extension migration.
CREATE TABLE "Lead" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "status" TEXT NOT NULL DEFAULT 'new',
    "source" TEXT NOT NULL DEFAULT 'qualification_form',
    "contactName" TEXT NOT NULL,
    "organizationName" TEXT NOT NULL,
    "organizationType" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "phone" TEXT,
    "teamSize" TEXT NOT NULL,
    "currentStack" TEXT NOT NULL,
    "criticalRisk" TEXT NOT NULL,
    "timeline" TEXT NOT NULL,
    "budgetRange" TEXT NOT NULL,
    "preferredContact" TEXT NOT NULL,
    "notes" TEXT,
    "attachmentPath" TEXT,
    "utmSource" TEXT,
    "utmMedium" TEXT,
    "utmCampaign" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);