-- Preserve reel/content-level acquisition attribution through the qualification funnel.
ALTER TABLE "Lead" ADD COLUMN "utmContent" TEXT;
