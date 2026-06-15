# Agent Governance - AlirezaSafaeiSystems

**Last Updated**: 2026-06-12
**Status**: ✅ Active

---

## 🤖 Agent Guidelines

### Preferred Agent Profiles
- **deep-review**: Use for complex architectural decisions, security reviews, and major refactoring
- **fast-fix**: Use for quick bug fixes, small feature additions, and routine maintenance
- **subagent_explore**: Use for codebase exploration, research, and understanding patterns
- **subagent_general**: Use for general development tasks requiring write access

### Agent Working Directory
- **Base Path**: `/home/dev13/my-project/sites/live/alirezasafaeisystems`
- **Allowed Directories**: `src/`, `scripts/`, `prisma/`, `docs/`, `tests/`
- **Restricted Directories**: `.git/`, `node_modules/`, `.next/`, `dist/`

### Key Constraints
- **No Global Installs**: Use project-local dependencies only
- **Testing Required**: All changes must pass `pnpm test` and `pnpm lint`
- **Type Safety**: Must pass `pnpm type-check`
- **Security First**: No hardcoded secrets, use environment variables
- **Performance**: Changes must not degrade Lighthouse scores below 90

---

## 🚦 Decision Rules

### When to Use `deep-review`
- Major architectural changes
- Security-sensitive implementations
- Database schema modifications
- Performance-critical changes
- Integration with third-party services

### When to Use `fast-fix`
- Typo corrections
- Simple bug fixes
- Minor UI improvements
- Documentation updates
- Configuration adjustments

### When to Ask for Approval
- Breaking changes to existing APIs
- Database migrations that delete data
- Changes to authentication/authorization
- Performance regressions >5%
- Security-related changes

---

## 📋 Execution Checklist

### Pre-Development
- [ ] Read relevant existing code and tests
- [ ] Understand the impact on existing features
- [ ] Check for similar implementations in the codebase
- [ ] Review security implications
- [ ] Consider performance impact

### During Development
- [ ] Follow existing code patterns
- [ ] Write/update tests for new functionality
- [ ] Use TypeScript strictly (no `any`)
- [ ] Follow accessibility best practices
- [ ] Implement proper error handling

### Post-Development
- [ ] Run `pnpm lint` - must pass
- [ ] Run `pnpm type-check` - must pass  
- [ ] Run `pnpm test` - must pass
- [ ] Run `pnpm build` - must succeed
- [ ] Test manually in development environment
- [ ] Check for accessibility issues
- [ ] Verify no performance regression

### Before Commit
- [ ] Write clear, conventional commit message
- [ ] Ensure changes are minimal and focused
- [ ] Check for accidentally committed files
- [ ] Verify environment variables are not committed
- [ ] Run `pnpm test:full` for critical changes

---

## 🔧 Common Tasks

### Adding New Component
```bash
# Use existing component patterns in src/components/
# Follow Shadcn/UI conventions
# Include TypeScript interfaces
# Add unit tests in src/__tests__/
# Update relevant documentation
```

### Database Schema Change
```bash
# 1. Modify schema in prisma/schema.prisma
# 2. Run: pnpm db:push
# 3. Generate migration: pnpm db:migrate
# 4. Update TypeScript types: pnpm db:generate
# 5. Add migration rollback plan
# 6. Test in development environment
```

### API Route Addition
```bash
# 1. Create route in src/app/api/
# 2. Implement proper error handling
# 3. Add input validation with Zod
# 4. Include authentication if needed
# 5. Add rate limiting
# 6. Write API tests
# 7. Update API documentation
```

### Performance Optimization
```bash
# 1. Run: pnpm lighthouse:ci
# 2. Identify bottlenecks
# 3. Implement optimizations
# 4. Verify no regression
# 5. Update performance budgets
# 6. Document changes
```

---

## 🚨 Critical Rules

### NEVER
- Commit `.env` files or secrets
- Remove error handling without replacement
- Disable security features
- Commit directly to `main` branch
- Skip tests for any reason
- Use `eval()` or similar dangerous functions
- Hardcode credentials or API keys
- Ignore TypeScript errors
- Commit `node_modules` or build artifacts

### ALWAYS
- Use environment variables for configuration
- Write tests for new functionality
- Follow existing code patterns
- Consider accessibility implications
- Think about performance impact
- Document complex logic
- Handle errors gracefully
- Validate user inputs
- Use parameterized queries

---

## 📊 Quality Gates

### Must Pass Before Merge
- ✅ All linting rules (`pnpm lint`)
- ✅ TypeScript compilation (`pnpm type-check`)
- ✅ Unit tests (`pnpm test`)
- ✅ E2E smoke tests (`pnpm test:e2e:smoke`)
- ✅ Accessibility tests (`pnpm test:e2e:a11y`)
- ✅ No security vulnerabilities (`pnpm audit:high`)
- ✅ No secrets in code (`pnpm scan:secrets`)
- ✅ Performance budgets met (`pnpm performance:budgets`)

### Optional But Recommended
- 📈 Full E2E test suite (`pnpm test:e2e`)
- 🎨 Visual regression tests (`pnpm test:visual`)
- 🚀 Lighthouse CI (`pnpm lighthouse:ci`)
- 📊 Test coverage report (`pnpm test:coverage`)

---

## 🆘 Troubleshooting

### Build Failures
```bash
# Clear Next.js cache
rm -rf .next

# Clear node_modules and reinstall
rm -rf node_modules
pnpm install

# Regenerate Prisma client
pnpm db:generate
```

### Test Failures
```bash
# Run tests in verbose mode
pnpm test --verbose

# Run specific test file
pnpm test path/to/test.test.ts

# Update snapshots if needed
pnpm test:visual:update
```

### Type Errors
```bash
# Check TypeScript configuration
cat tsconfig.json

# Generate types
pnpm db:generate

# Check for any types
pnpm type-check
```

---

## 📚 Project-Specific Resources

### Key Files
- **Package Configuration**: `package.json`
- **TypeScript Config**: `tsconfig.json`
- **Database Schema**: `prisma/schema.prisma`
- **Environment Variables**: `.env.example`
- **Testing Config**: `vitest.config.ts`
- **Playwright Config**: `playwright.config.mjs`

### Important Scripts
- **Development**: `pnpm dev`
- **Build**: `pnpm build`
- **Test**: `pnpm test`
- **Lint**: `pnpm lint`
- **Type Check**: `pnpm type-check`
- **Database**: `pnpm db:push`

### External Links
- **Live Site**: https://alirezasafaeisystems.ir/fa
- **GitHub Repository**: https://github.com/alirezasafaei-dev/alirezasafaeisystems
- **Deployment Documentation**: `docs/runtime/`
- **API Documentation**: (when available)

---

## 🔄 Continuous Improvement

### Regular Maintenance Tasks
- **Weekly**: Dependency updates (`pnpm update`)
- **Monthly**: Security audits (`pnpm audit:high`)
- **Quarterly**: Performance reviews (`pnpm lighthouse:ci`)
- **Biannually**: Architecture review and refactoring

### Agent Feedback Loop
- Report any patterns that could be automated
- Suggest improvements to testing coverage
- Identify areas needing documentation
- Flag technical debt for future sprints
- Recommend tooling improvements

---

*This governance document ensures consistent, high-quality contributions while maintaining the production-readiness of the AlirezaSafaeiSystems platform.*