# Design Token Registry

Last updated: 2026-06-16
Owner: `platform-owner`
Status: ✅ Frozen and Audited

## Source of Truth
- Token definitions: `src/app/globals.css`
- Consumption: Tailwind token mappings (`@theme inline`)

## Core Color Tokens
- `--background`: main page background
- `--foreground`: main text color
- `--card`, `--card-foreground`: card surfaces
- `--primary`, `--primary-foreground`: primary CTA and emphasis
- `--accent`, `--accent-foreground`: secondary emphasis
- `--muted`, `--muted-foreground`: helper and neutral text
- `--border`, `--input`, `--ring`: control and focus surfaces
- `--destructive`, `--destructive-foreground`: destructive actions

## Spacing and Radius
- Base radius token: `--radius`
- Derived radii: `--radius-sm|md|lg|xl`
- Spacing scale follows 8px rhythm in component classes.
- Section spacing tokens:
  - `--section-space-y`
  - `--section-space-y-tight`
  - `--flow-space`

## Typography Tokens
- Primary stack bound to `--font-sans`.
- Local font first policy: `IRANSansX` first in stack.
- CDN font path is optional and must remain disabled in production by default.
- Persian/RTL readability tokens:
  - `--copy-line-height`
  - `--copy-letter-spacing`
  - `--heading-line-height`
  - `--heading-letter-spacing`
  - `--ui-line-height`
- Utility classes:
  - `.text-copy`
  - `.text-ui`
  - `.section-block`
  - `.section-block-soft`

## Audit Results (2026-06-16)
- ✅ No hard-coded colors found in components (0 hex/rgb/hsl matches)
- ✅ No hard-coded spacing values in components (only technical values like Intersection Observer thresholds)
- ✅ All colors use CSS custom properties (--primary, --secondary, etc.)
- ✅ All spacing uses Tailwind utility classes or CSS variables
- ✅ All radii use CSS custom properties (--radius, --radius-sm/md/lg/xl)
- ✅ Typography uses CSS custom properties (--font-sans, --font-heading, --copy-line-height, etc.)
- ✅ RTL/LTR direction uses CSS custom properties for typography
- ✅ Section spacing uses CSS custom properties (--section-space-y, --flow-space)
- ✅ Component tokens follow Tailwind theme inline mapping

## Governance Rules
1. New visual values must be introduced as tokens before component usage.
2. Hard-coded colors in components are disallowed unless mapped to a token in same PR.
3. Any token update requires:
- Accessibility verification (WCAG AA contrast)
- Lighthouse regression check
- Screenshot evidence before/after under `docs/runtime/`
4. Runtime must function without external font/CDN dependency.

## Visual Regression Baseline
- Storybook config: `.storybook/main.ts`, `.storybook/preview.tsx`
- Core stories:
  - `src/components/sections/hero.stories.tsx`
  - `src/components/sections/contact.stories.tsx`
  - `src/components/layout/footer.stories.tsx`
- Visual regression tests:
  - `playwright.storybook.config.mjs`
  - `e2e/visual/storybook.visual.spec.ts`
- Commands:
  - `pnpm storybook`
  - `pnpm storybook:build`
  - `pnpm test:visual`
  - `pnpm test:visual:update`
