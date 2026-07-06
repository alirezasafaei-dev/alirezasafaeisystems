# Portfolio (alirezasafaeisystems.ir) - Complete Documentation

**Project:** Portfolio & Analytics Hub (Trust Engine)
**URL:** https://alirezasafaeisystems.ir/
**Role:** Middle of Funnel - Trust building & conversion
**Last Updated:** 2026-06-20

> **Reality note:** The analytics API and models exist, but the Prisma datasource is currently SQLite and cross-site production attribution is not proven. Current status and migration priority: [ecosystem research synthesis](../../../docs/reports/ecosystem-research-synthesis-2026-06-20.md).

---

## 🎯 Project Purpose

This portfolio site serves as the **trust engine** in the three-site revenue system. It builds credibility through case studies, hosts the central analytics API, and converts warm leads from PersianToolbox into paying clients.

### Revenue Role
- **Stage:** Consideration & Decision (Middle to Bottom of Funnel)
- **Goal:** Build trust and convert visitors to clients
- **Monetization:** Direct client acquisition + future SaaS dashboard

---

## 🏗️ Architecture

### Tech Stack
- **Framework:** Next.js 16 (App Router)
- **Language:** TypeScript 5.x (strict mode)
- **Database:** Prisma ORM + SQLite (dev) / PostgreSQL (prod)
- **Styling:** Tailwind CSS 3.x
- **Components:** Custom + Radix UI
- **Authentication:** NextAuth.js v5 (planned Week 2)
- **Analytics:** Custom REST API
- **Testing:** Vitest + Playwright
- **Package Manager:** pnpm

### Project Structure
```
sites/live/alirezasafaeisystems/
├── app/
│   ├── api/
│   │   └── track/
│   │       └── route.ts           # Analytics API endpoint
│   ├── [lang]/                    # i18n routes (fa, en)
│   │   ├── about/
│   │   ├── services/
│   │   ├── case-studies/
│   │   ├── contact/
│   │   └── page.tsx
│   ├── layout.tsx
│   └── globals.css
├── prisma/
│   ├── schema.prisma              # Database models
│   ├── migrations/                # Database migrations
│   └── dev.db                     # SQLite database (dev)
├── components/
│   ├── ui/                        # Base UI components
│   ├── sections/                  # Page sections
│   └── forms/                     # Contact forms
├── lib/
│   ├── prisma.ts                  # Prisma client
│   ├── analytics.ts               # Analytics utilities
│   └── auth.ts                    # Auth config (planned)
├── public/
│   ├── case-studies/              # Case study assets
│   └── portfolio/                 # Portfolio images
├── shared/                        # Cross-site shared code
├── tests/
├── REVENUE_SYSTEM.md
├── DOCUMENTATION.md               # This file
└── package.json
```

---

## 🔌 Analytics API

### Endpoint: POST /api/track

**Purpose:** Central tracking endpoint for all three sites

**Request Format:**
```typescript
POST https://alirezasafaeisystems.ir/api/track
Content-Type: application/json

{
  "event": "page_view" | "cta_click" | "tool_usage" | "conversion" | "contact_submit",
  "source": "persiantoolbox" | "alirezasafaeisystems" | "auditsystems",
  "sessionId": "uuid-v4-string",
  "url": "https://persiantoolbox.ir/pdf-merge",
  "referrer": "https://google.com",
  "metadata": {
    "toolName": "pdf-merge",
    "ctaVariant": "tool-result",
    // ... additional event-specific data
  }
}
```

**Response:**
```json
{
  "success": true,
  "eventId": "clx123456789"
}
```

**Error Response:**
```json
{
  "error": "Invalid event type",
  "code": "VALIDATION_ERROR"
}
```

### Supported Events

**1. page_view**
- Tracks page visits across all sites
- Required fields: `event`, `source`, `url`
- Optional: `referrer`, `sessionId`

**2. cta_click**
- Tracks CTA interactions
- Required: `event`, `source`, `ctaType`, `ctaVariant`
- Used for conversion rate optimization

**3. tool_usage**
- Tracks tool usage on PersianToolbox
- Required: `event`, `source`, `toolName`
- Optional: `metadata` (tool-specific data)

**4. conversion**
- Tracks successful conversions (contact forms, purchases)
- Required: `event`, `source`, `conversionType`
- Critical for ROI measurement

**5. contact_submit**
- Tracks contact form submissions
- Required: `event`, `source`, `formType`
- Triggers sales notifications

### Implementation Details

**API Route:** `app/api/track/route.ts`

```typescript
import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    
    // Validate event
    const validEvents = ['page_view', 'cta_click', 'tool_usage', 'conversion', 'contact_submit'];
    if (!validEvents.includes(body.event)) {
      return NextResponse.json(
        { error: 'Invalid event type' },
        { status: 400 }
      );
    }
    
    // Store in database
    const event = await prisma.analyticsEvent.create({
      data: {
        event: body.event,
        source: body.source,
        sessionId: body.sessionId,
        url: body.url,
        referrer: body.referrer,
        metadata: body.metadata || {},
      }
    });
    
    // Update funnel if CTA click
    if (body.event === 'cta_click') {
      await updateFunnelConversion(body);
    }
    
    return NextResponse.json({ 
      success: true, 
      eventId: event.id 
    });
    
  } catch (error) {
    console.error('Analytics tracking error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
```

### Database Schema

**AnalyticsEvent Model:**
```prisma
model AnalyticsEvent {
  id         String   @id @default(cuid())
  event      String   // Event type
  source     String   // Source site
  sessionId  String?  // User session
  url        String?  // Page URL
  referrer   String?  // Referrer URL
  metadata   Json?    // Additional data
  createdAt  DateTime @default(now())
  
  @@index([event, source])
  @@index([sessionId])
  @@index([createdAt])
}
```

**FunnelConversion Model:**
```prisma
model FunnelConversion {
  id                String   @id @default(cuid())
  sessionId         String   @unique
  toolboxVisit      DateTime?
  portfolioVisit    DateTime?
  auditVisit        DateTime?
  contactSubmit     DateTime?
  converted         Boolean  @default(false)
  conversionValue   Float?
  createdAt         DateTime @default(now())
  updatedAt         DateTime @updatedAt
  
  @@index([sessionId])
  @@index([converted])
}
```

### Rate Limiting (Planned)
- **Public API:** 100 requests per IP per hour
- **Authenticated:** 1000 requests per user per hour
- **Premium:** Unlimited

---

## 📄 Content Structure

### Pages

**1. Homepage (`/fa` or `/en`)**
- Hero section with value proposition
- Service highlights
- Recent case studies preview
- CTA to contact
- Social proof (testimonials)

**2. About Page (`/fa/about`)**
- Professional bio
- Skills and expertise
- Tech stack proficiency
- Years of experience
- Education and certifications

**3. Services Page (`/fa/services`)**
- Service offerings catalog
- Pricing tiers (starting from...)
- Delivery timeline
- Technical capabilities
- CTA to contact

**4. Case Studies (`/fa/case-studies`)**
- Project portfolio
- Problem-solution format
- Tech stack used
- Results and metrics
- Client testimonials

**5. Contact Page (`/fa/contact`)**
- Contact form
- Email and social links
- Response time expectation
- Free consultation CTA

**6. Blog (Future)**
- Technical articles
- SEO-driven content
- Tutorial series
- Industry insights

### Service Offerings

**Technical Audit Services**
- **Price:** $500 - $2,000
- **Deliverable:** Comprehensive audit report
- **Timeline:** 3-5 business days
- **Includes:** Security, performance, architecture review

**Infrastructure Consulting**
- **Price:** $3,000 - $8,000
- **Deliverable:** Infrastructure design + implementation
- **Timeline:** 2-4 weeks
- **Includes:** Cloud architecture, CI/CD, monitoring

**Full-Stack Development**
- **Price:** $5,000 - $20,000
- **Deliverable:** Custom web application
- **Timeline:** 4-12 weeks
- **Includes:** Design, development, testing, deployment

**SaaS Development**
- **Price:** $10,000 - $50,000
- **Deliverable:** Production-ready SaaS platform
- **Timeline:** 8-16 weeks
- **Includes:** Full stack, auth, billing, analytics

**Maintenance & Support**
- **Price:** $500 - $2,000/month
- **Deliverable:** Ongoing support and updates
- **Timeline:** Monthly retainer
- **Includes:** Bug fixes, updates, monitoring

---

## 🎨 Design System

### Brand Colors
```css
/* Primary */
--primary: #0066cc;
--primary-dark: #004499;
--primary-light: #3388dd;

/* Secondary */
--secondary: #6c757d;
--secondary-dark: #495057;

/* Accent */
--accent: #28a745;

/* Neutral */
--gray-50: #f8f9fa;
--gray-100: #e9ecef;
--gray-200: #dee2e6;
--gray-800: #343a40;
--gray-900: #212529;
```

### Typography
- **Headings:** Inter (Bold)
- **Body:** Inter (Regular)
- **Code:** Fira Code
- **Persian:** Vazirmatn

### Spacing Scale
```
4px, 8px, 12px, 16px, 24px, 32px, 48px, 64px, 96px, 128px
```

### Breakpoints
```typescript
const breakpoints = {
  sm: '640px',   // Mobile landscape
  md: '768px',   // Tablet
  lg: '1024px',  // Desktop
  xl: '1280px',  // Large desktop
  '2xl': '1536px' // Extra large
};
```

---

## 🔐 Authentication (Week 2 - Planned)

### NextAuth.js v5 Setup

**Configuration:** `lib/auth.ts`

```typescript
import NextAuth from 'next-auth';
import CredentialsProvider from 'next-auth/providers/credentials';
import GoogleProvider from 'next-auth/providers/google';
import { PrismaAdapter } from '@auth/prisma-adapter';
import { prisma } from './prisma';

export const { handlers, auth, signIn, signOut } = NextAuth({
  adapter: PrismaAdapter(prisma),
  providers: [
    GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
    }),
    CredentialsProvider({
      name: 'Email',
      credentials: {
        email: { label: 'Email', type: 'email' },
        password: { label: 'Password', type: 'password' },
      },
      async authorize(credentials) {
        // Implement user verification
        return user;
      },
    }),
  ],
  session: {
    strategy: 'jwt',
  },
  pages: {
    signIn: '/auth/signin',
    signOut: '/auth/signout',
    error: '/auth/error',
  },
});
```

**Protected Routes:**
```typescript
// middleware.ts
import { auth } from '@/lib/auth';
import { NextResponse } from 'next/server';

export default auth((req) => {
  if (!req.auth && req.nextUrl.pathname.startsWith('/dashboard')) {
    return NextResponse.redirect(new URL('/auth/signin', req.url));
  }
});

export const config = {
  matcher: ['/dashboard/:path*', '/api/user/:path*'],
};
```

### User Database Schema (Planned)

```prisma
model User {
  id            String    @id @default(cuid())
  name          String?
  email         String    @unique
  emailVerified DateTime?
  image         String?
  password      String?   // Hashed
  tier          String    @default("free") // free, premium, business
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt
  
  accounts      Account[]
  sessions      Session[]
  usage         UsageLog[]
}

model Account {
  id                String  @id @default(cuid())
  userId            String
  type              String
  provider          String
  providerAccountId String
  refresh_token     String?
  access_token      String?
  expires_at        Int?
  token_type        String?
  scope             String?
  id_token          String?
  session_state     String?
  
  user User @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  @@unique([provider, providerAccountId])
}

model Session {
  id           String   @id @default(cuid())
  sessionToken String   @unique
  userId       String
  expires      DateTime
  user         User     @relation(fields: [userId], references: [id], onDelete: Cascade)
}

model UsageLog {
  id        String   @id @default(cuid())
  userId    String
  tool      String
  createdAt DateTime @default(now())
  
  user User @relation(fields: [userId], references: [id])
  
  @@index([userId, createdAt])
}
```

---

## 🚀 Development Workflow

### Local Setup

```bash
# Install dependencies
pnpm install

# Setup database
npx prisma generate
npx prisma migrate dev

# Seed database (optional)
npx prisma db seed

# Run development server
pnpm dev
# → http://localhost:3001

# Run tests
pnpm test
pnpm test:e2e

# Type checking
pnpm typecheck

# Linting
pnpm lint

# Build
pnpm build

# Start production
pnpm start
```

### Database Commands

```bash
# Create new migration
npx prisma migrate dev --name add_user_model

# Apply migrations (production)
npx prisma migrate deploy

# Reset database (dev only - destroys data)
npx prisma migrate reset

# Open Prisma Studio (database GUI)
npx prisma studio
# → http://localhost:5555

# Generate Prisma Client
npx prisma generate
```

### Environment Variables

```bash
# .env.local (development)
DATABASE_URL="file:./dev.db"
NEXT_PUBLIC_SITE_URL="http://localhost:3001"
NEXT_PUBLIC_ANALYTICS_ENABLED="true"

# NextAuth (Week 2)
NEXTAUTH_URL="http://localhost:3001"
NEXTAUTH_SECRET="generate-with-openssl-rand-base64-32"
GOOGLE_CLIENT_ID="your-google-client-id"
GOOGLE_CLIENT_SECRET="your-google-client-secret"

# Stripe (Week 4)
STRIPE_SECRET_KEY="sk_test_..."
STRIPE_WEBHOOK_SECRET="whsec_..."
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY="pk_test_..."
```

```bash
# .env.production (VPS)
DATABASE_URL="postgresql://user:pass@localhost:5432/portfolio"
NEXT_PUBLIC_SITE_URL="https://alirezasafaeisystems.ir"
NEXT_PUBLIC_ANALYTICS_ENABLED="true"

# Production secrets set via PM2 ecosystem file
```

---

## 📊 Analytics & Reporting (Future Dashboard)

### Metrics to Track

**Traffic Metrics**
- Daily/weekly/monthly visitors
- Top referrers
- Top landing pages
- Geographic distribution

**Funnel Metrics**
- Toolbox → Portfolio conversion rate
- Portfolio → Contact conversion rate
- Complete funnel conversion rate
- Average time in funnel

**Tool Metrics**
- Most used tools
- Tool usage by session
- Tool-to-CTA click rate
- Premium feature requests

**Revenue Metrics**
- Monthly Recurring Revenue (MRR)
- Customer Acquisition Cost (CAC)
- Lifetime Value (LTV)
- Churn rate

### Admin Dashboard (Week 2-3)

```
/dashboard
├── /overview          # Key metrics summary
├── /analytics         # Detailed analytics
├── /funnel            # Funnel visualization
├── /users             # User management
├── /revenue           # Revenue tracking
└── /settings          # Configuration
```

---

## 🧪 Testing

### Unit Tests

```typescript
// tests/api/track.test.ts
import { POST } from '@/app/api/track/route';
import { prisma } from '@/lib/prisma';

describe('Analytics API', () => {
  it('should track page_view event', async () => {
    const request = new Request('http://localhost/api/track', {
      method: 'POST',
      body: JSON.stringify({
        event: 'page_view',
        source: 'persiantoolbox',
        url: 'https://persiantoolbox.ir/pdf-merge',
      }),
    });
    
    const response = await POST(request);
    const data = await response.json();
    
    expect(response.status).toBe(200);
    expect(data.success).toBe(true);
  });
  
  it('should reject invalid event types', async () => {
    const request = new Request('http://localhost/api/track', {
      method: 'POST',
      body: JSON.stringify({
        event: 'invalid_event',
        source: 'persiantoolbox',
      }),
    });
    
    const response = await POST(request);
    
    expect(response.status).toBe(400);
  });
});
```

### E2E Tests

```typescript
// tests/e2e/contact-form.spec.ts
import { test, expect } from '@playwright/test';

test('contact form submission', async ({ page }) => {
  await page.goto('/fa/contact');
  
  // Fill form
  await page.fill('#name', 'Test User');
  await page.fill('#email', 'test@example.com');
  await page.fill('#message', 'Test message');
  
  // Submit
  await page.click('button[type="submit"]');
  
  // Verify success
  await expect(page.locator('.success-message')).toBeVisible();
  
  // Verify tracking event was sent
  // (mock analytics API in test environment)
});
```

---

## 📦 Deployment

### Production Deployment

```bash
# SSH to VPS
ssh user@alirezasafaeisystems.ir

# Navigate to project
cd /var/www/alirezasafaeisystems

# Pull latest
git pull origin main

# Install dependencies
pnpm install --frozen-lockfile

# Run migrations
npx prisma migrate deploy

# Build
pnpm build

# Restart PM2
pm2 restart alirezasafaeisystems

# Verify
pm2 logs alirezasafaeisystems --lines 50
curl -I https://alirezasafaeisystems.ir/api/track
```

### Deployment Checklist
- ✅ Database backup completed
- ✅ Migrations tested locally
- ✅ Environment variables configured
- ✅ Analytics API responding
- ✅ All tests passing
- ✅ No TypeScript errors
- ✅ SSL certificate valid
- ✅ PM2 process healthy
- ✅ Nginx config correct
- ✅ Prisma client generated

---

## 🐛 Troubleshooting

### Database Issues

**Issue:** Prisma Client not generated
```bash
npx prisma generate
```

**Issue:** Migration fails
```bash
# Check migration status
npx prisma migrate status

# Resolve migrations
npx prisma migrate resolve --applied "migration_name"
```

**Issue:** Database connection error
```bash
# Verify DATABASE_URL
echo $DATABASE_URL

# Test connection
npx prisma db pull
```

### API Issues

**Issue:** Analytics API not responding
```bash
# Check PM2 status
pm2 list

# View logs
pm2 logs alirezasafaeisystems --lines 100

# Check Nginx config
sudo nginx -t

# Restart services
pm2 restart alirezasafaeisystems
sudo systemctl restart nginx
```

**Issue:** CORS errors
- Verify `NEXT_PUBLIC_ANALYTICS_API` URL
- Check Nginx CORS headers
- Ensure credentials mode correct

---

## 📚 Related Documentation

- **[REVENUE_SYSTEM.md](./REVENUE_SYSTEM.md)** - Revenue integration
- **[../../.agents/CONTEXT.md](../../.agents/CONTEXT.md)** - Project context
- **[../../docs/api/analytics-api.md](../../docs/api/analytics-api.md)** - API docs
- **[../../docs/backend/database-schema.md](../../docs/backend/database-schema.md)** - Database schema
- **[../../docs/roadmaps/30-day-mvp.md](../../docs/roadmaps/30-day-mvp.md)** - Roadmap

---

## 🎯 Current Sprint

### Week 1 (Current - 70% Complete)
- [x] Analytics API implementation
- [x] Database schema design
- [x] Prisma migrations
- [x] Basic tracking events
- [ ] Dashboard UI (basic version)
- [ ] End-to-end testing

### Week 2 (Next)
- [ ] NextAuth.js setup
- [ ] User registration flow
- [ ] Login/logout functionality
- [ ] Protected routes
- [ ] User dashboard

### Week 3-4
- [ ] Premium feature gates
- [ ] Stripe integration
- [ ] Subscription management
- [ ] Usage tracking per user
- [ ] Admin panel

---

**Document Version:** 1.0.0
**Last Updated:** 2026-06-18
**Next Review:** 2026-06-25
**Maintained By:** Alireza Safaei + AI Agents
