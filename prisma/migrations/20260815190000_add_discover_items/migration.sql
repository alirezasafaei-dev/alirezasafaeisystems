-- Create a dedicated Discover content table without mutating historical Project rows.
CREATE TABLE "DiscoverItem" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "slug" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "externalUrl" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "tags" TEXT NOT NULL,
    "imageUrl" TEXT,
    "instagramUrl" TEXT,
    "featured" BOOLEAN NOT NULL DEFAULT false,
    "published" BOOLEAN NOT NULL DEFAULT false,
    "order" INTEGER NOT NULL DEFAULT 0,
    "publishedAt" DATETIME,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);

CREATE UNIQUE INDEX "DiscoverItem_slug_key" ON "DiscoverItem"("slug");
CREATE INDEX "DiscoverItem_published_featured_order_idx"
ON "DiscoverItem"("published", "featured", "order");
CREATE INDEX "DiscoverItem_category_published_idx"
ON "DiscoverItem"("category", "published");

-- Preserve any Discover content already created through the earlier Project-based implementation.
-- Stable legacy ids/slugs avoid unsafe transliteration and guarantee uniqueness.
-- Legacy URLs predate the strict Discover URL contract, so copy only HTTPS destinations/images.
INSERT INTO "DiscoverItem" (
    "id",
    "slug",
    "title",
    "description",
    "content",
    "externalUrl",
    "category",
    "tags",
    "imageUrl",
    "instagramUrl",
    "featured",
    "published",
    "order",
    "publishedAt",
    "createdAt",
    "updatedAt"
)
SELECT
    'legacy-' || "id",
    'legacy-' || "id",
    "title",
    "description",
    COALESCE(NULLIF("longDescription", ''), "description"),
    CASE
        WHEN lower(COALESCE("liveUrl", '')) LIKE 'https://%' THEN "liveUrl"
        WHEN lower(COALESCE("githubUrl", '')) LIKE 'https://%' THEN "githubUrl"
        ELSE 'https://alirezasafaeisystems.ir/'
    END,
    'Legacy',
    "tags",
    CASE
        WHEN lower(COALESCE("imageUrl", '')) LIKE 'https://%' THEN "imageUrl"
        ELSE NULL
    END,
    NULL,
    "featured",
    "published",
    "order",
    CASE WHEN "published" = true THEN "updatedAt" ELSE NULL END,
    "createdAt",
    "updatedAt"
FROM "Project"
WHERE "contentType" = 'discover';
