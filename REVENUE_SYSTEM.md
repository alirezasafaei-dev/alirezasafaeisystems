# سیستم درآمدزایی Portfolio

## نقش در شبکه درآمدی

Portfolio نقش **موتور اعتماد‌سازی** و **API مرکزی Analytics** را دارد.

## معماری

```
PersianToolbox → Portfolio (اعتماد + مستندات) → Lead Generation → مشتری
                    ↓
            Analytics API + Database
```

## API تحلیلی

### Endpoint اصلی

**مسیر:** `src/app/api/track/route.ts`

**URL:** `https://alirezasafaeisystems.ir/api/track`

**Method:** POST

**Request Body:**
```typescript
{
  site: 'toolbox' | 'portfolio' | 'audit',
  event: string,
  properties?: Record<string, any>,
  timestamp: number,
  sessionId: string,
  userId?: string
}
```

**Response:**
```json
{ "ok": true }
```

### رویدادهای قابل ردیابی

1. **page_view** - بازدید صفحه
2. **cta_click** - کلیک روی CTA
3. **tool_usage** - استفاده از ابزار
4. **contact_submit** - ارسال فرم تماس
5. **conversion** - تبدیل به مشتری

### مدل‌های دیتابیس

**AnalyticsEvent:**
```prisma
model AnalyticsEvent {
  id         String   @id @default(cuid())
  site       String
  event      String
  properties String   @default("{}") // JSON
  sessionId  String
  userId     String?
  timestamp  DateTime
  ip         String
  userAgent  String
  createdAt  DateTime @default(now())
  
  @@index([sessionId])
  @@index([site, event])
  @@index([timestamp])
}
```

**FunnelConversion:**
```prisma
model FunnelConversion {
  id              String   @id @default(cuid())
  sessionId       String   @unique
  entryPoint      String   // 'toolbox' | 'organic' | 'direct'
  visitedToolbox  Boolean  @default(false)
  visitedPortfolio Boolean @default(false)
  visitedAudit    Boolean  @default(false)
  contacted       Boolean  @default(false)
  converted       Boolean  @default(false)
  conversionValue Float?
  createdAt       DateTime @default(now())
  updatedAt       DateTime @updatedAt
}
```

## قیف تبدیل

### مراحل Funnel

1. **Entry Point Detection**
   - اولین بازدید: toolbox/portfolio/audit
   - ذخیره در `entryPoint`

2. **Cross-Site Navigation**
   - هر بازدید به سایت دیگر ثبت می‌شود
   - `visitedToolbox`, `visitedPortfolio`, `visitedAudit`

3. **Contact/Lead Generation**
   - ارسال فرم تماس
   - `contacted = true`

4. **Conversion**
   - پرداخت یا قرارداد
   - `converted = true`
   - `conversionValue` ثبت می‌شود

## استراتژی درآمدزایی Portfolio

### 1. فریلنس و پروژه‌های سفارشی

**خدمات قیمت‌گذاری شده:**

#### Technical Audit ($500-2,000)
- بررسی امنیتی
- تحلیل عملکرد
- بررسی SEO فنی
- ارزیابی زیرساخت
- **تحویل:** 48-72 ساعت

#### Infrastructure Consulting ($3,000-8,000)
- بومی‌سازی زیرساخت
- سخت‌سازی CI/CD
- مانیتورینگ و ناظر
- طراحی معماری
- **مدت:** 2-4 هفته

#### Full-Stack Development ($5,000-20,000)
- توسعه از صفر
- Next.js + TypeScript
- Prisma + PostgreSQL
- تست خودکار
- **مدت:** 4-12 هفته

### 2. خدمات محصول‌سازی شده

**پکیج‌های آماده:**

- **Site Audit as a Service:** $299-499
- **CI/CD Hardening Package:** $1,999
- **Infrastructure Review:** $2,999

### 3. مشاوره و آموزش

- **مشاوره رایگان 30 دقیقه‌ای:** Lead magnet
- **مشاوره ساعتی:** $150/ساعت
- **وِرکشاپ تیمی:** $2,000/روز

## صفحات کلیدی

### 1. Homepage (/)
- Hero با proof points
- Featured case studies
- Service offerings
- CTA: "Schedule Free Consultation"

### 2. Case Studies (/case-studies/[slug])
- PersianToolbox: 51 tools, production-ready
- Audit System: Automated auditing
- Portfolio Infrastructure: Self-hosted, CI/CD

### 3. Services (/services)
- Productized services با قیمت شفاف
- Clear deliverables
- Timeline estimates

### 4. Contact (/contact)
- Calendly integration
- فرم تماس
- گزینه‌های ارتباطی متعدد

## نقاط تبدیل (CTAs)

### از Toolbox به Portfolio

**UTM Parameters:**
```
utm_source=toolbox
utm_medium=footer|tool_result|premium_gate|sidebar
utm_campaign=cross_site|conversion|saas|branding
```

### از Portfolio به Conversion

1. **Hero CTA:** "Schedule Free Consultation"
2. **Case Study CTAs:** "See how I solved X"
3. **Service CTAs:** "Get a quote"
4. **Audit CTA:** "Try my free audit tool"

## معیارهای موفقیت

### ترافیک
- **از Toolbox:** هدف 500-1,000 بازدید/ماه
- **ارگانیک:** هدف 200-500 بازدید/ماه
- **مستقیم:** هدف 100-200 بازدید/ماه

### تبدیل
- **Portfolio → Contact:** 20-30%
- **Contact → Paid:** 50-70%
- **Average Deal Value:** $3,000-8,000

### درآمد
- **ماه 1:** $1K-3K (اولین مشتریان)
- **ماه 3:** $5K-10K (pipeline پر شده)
- **ماه 6:** $15K-30K (عملیات مقیاس‌پذیر)

## Analytics Queries

### Top Funnels
```sql
SELECT 
  entryPoint,
  COUNT(*) as total,
  SUM(CASE WHEN converted THEN 1 ELSE 0 END) as conversions,
  AVG(conversionValue) as avg_value
FROM FunnelConversion
WHERE createdAt > DATE('now', '-30 days')
GROUP BY entryPoint;
```

### CTA Performance
```sql
SELECT 
  json_extract(properties, '$.variant') as variant,
  COUNT(*) as clicks
FROM AnalyticsEvent
WHERE site = 'toolbox'
  AND event = 'cta_click'
  AND timestamp > DATE('now', '-7 days')
GROUP BY variant
ORDER BY clicks DESC;
```

## راه‌اندازی محلی

```bash
# تنظیم دیتابیس
echo 'DATABASE_URL="file:./dev.db"' > .env

# نصب و مایگریت
pnpm install
npx prisma migrate dev
npx prisma generate

# اجرا
pnpm dev

# تست Analytics API
curl -X POST http://localhost:3000/api/track \
  -H "Content-Type: application/json" \
  -d '{
    "site": "toolbox",
    "event": "test_event",
    "sessionId": "test-123",
    "timestamp": 1234567890
  }'

# مشاهده داده‌ها
npx prisma studio
```

## دیپلوی Production

```bash
# بیلد
pnpm build

# مایگریت دیتابیس Production
DATABASE_URL="postgresql://..." npx prisma migrate deploy

# دیپلوی به VPS
# استفاده از اسکریپت‌های موجود

# ریستارت سرویس
sudo systemctl restart portfolio
```

## مستندات تکمیلی

- [System Overview](../../docs/architecture/system-overview.md)
- [Analytics API](../../docs/api/analytics.md)
- [Database Schema](../../docs/backend/database-schema.md)

---

**آخرین بروزرسانی:** 2026-06-18
**نسخه:** 0.2.0
**وضعیت:** Production-ready (Analytics API operational)
