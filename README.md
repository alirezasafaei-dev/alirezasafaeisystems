# AlirezaSafaeiSystems

**Personal Portfolio & Enterprise Web Systems Platform**

A production-ready portfolio website and enterprise-grade web systems showcase, built with modern web technologies and deployment best practices.

## 🚀 Quick Start

```bash
# Install dependencies
pnpm install

# Run development server
pnpm dev

# Build for production
pnpm build

# Run production server
pnpm start
```

## 📋 Project Overview

### Technology Stack
- **Framework**: Next.js 16 with App Router
- **UI Library**: React 19 with TypeScript
- **Styling**: Tailwind CSS 4 with Shadcn/UI components
- **Database**: PostgreSQL with Prisma ORM
- **Testing**: Vitest, Playwright for E2E
- **Deployment**: Standalone Node.js deployment, VPS-hosted

### Core Features
- **Portfolio Showcase**: Professional portfolio with case studies
- **Enterprise Demos**: Live demonstrations of web systems
- **Multi-language Support**: Persian (Farsi) with RTL support
- **Performance Optimized**: Lighthouse scores 90+
- **Enterprise Security**: Security-first architecture
- **Monitoring**: Comprehensive health checks and monitoring

### Deployment Status
- **Production**: https://alirezasafaeisystems.ir/fa
- **Environment**: Production VPS
- **Status**: ✅ Live and operational
- **Last Deploy**: June 2026

## 🏗️ Architecture

### Project Structure
```
alirezasafaeisystems/
├── src/
│   ├── app/              # Next.js App Router
│   ├── components/      # React components
│   ├── lib/            # Utilities and helpers
│   ├── __tests__/      # Test files
│   └── styles/         # Global styles
├── prisma/            # Database schema
├── scripts/           # Automation scripts
├── docs/              # Documentation
└── public/            # Static assets
```

### Key Technologies
- **Next.js 16**: Latest React framework with App Router
- **Shadcn/UI**: Modern component library with Radix UI primitives
- **Prisma**: Type-safe ORM for PostgreSQL
- **Tailwind CSS 4**: Utility-first CSS framework
- **Framer Motion**: Production-grade motion library
- **Playwright**: E2E testing framework

## 🧪 Testing

```bash
# Run unit tests
pnpm test

# Run E2E tests
pnpm test:e2e

# Run smoke tests
pnpm test:e2e:smoke

# Run accessibility tests
pnpm test:e2e:a11y

# Run visual regression tests
pnpm test:visual
```

## 📊 Monitoring & Quality

```bash
# Run full test suite
pnpm test:full

# Run lighthouse CI
pnpm lighthouse:ci

# Security audit
pnpm audit:high

# Secret scanning
pnpm scan:secrets
```

## 🔧 Development Scripts

```bash
# Database operations
pnpm db:push
pnpm db:generate
pnpm db:migrate

# Code quality
pnpm lint
pnpm type-check

# Deployment preparation
pnpm vps:preflight
pnpm release:prepare:vps
```

## 🌐 Live URLs

- **Main Site**: https://alirezasafaeisystems.ir/fa
- **Portfolio**: https://alirezasafaeisystems.ir
- **Enterprise Demos**: Various deployed components

## 📈 Performance Metrics

- **Lighthouse Performance**: 90+
- **Lighthouse Accessibility**: 95+
- **Lighthouse Best Practices**: 90+
- **Lighthouse SEO**: 100
- **First Contentful Paint**: <1.5s
- **Largest Contentful Paint**: <2.5s

## 🔒 Security Features

- Environment variable management
- SQL injection prevention (Prisma)
- XSS protection (React sanitization)
- CSRF protection
- Security headers configuration
- Regular dependency audits

## 🤝 Contributing

This is a personal portfolio project. For contributions or questions, please contact the maintainer.

## 📄 License

Proprietary - All rights reserved

## 👤 Author

**Alireza Safaei**
- Website: https://alirezasafaeisystems.ir
- GitHub: [@alirezasafaei-dev](https://github.com/alirezasafaei-dev)

---

**Built with modern web technologies and enterprise-grade practices.**