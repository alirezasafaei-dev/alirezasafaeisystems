ALTER TABLE "DiscoverItem" ADD COLUMN "titleEn" TEXT;
ALTER TABLE "DiscoverItem" ADD COLUMN "descriptionEn" TEXT;
ALTER TABLE "DiscoverItem" ADD COLUMN "contentEn" TEXT;
ALTER TABLE "DiscoverItem" ADD COLUMN "publishedEn" BOOLEAN NOT NULL DEFAULT false;
