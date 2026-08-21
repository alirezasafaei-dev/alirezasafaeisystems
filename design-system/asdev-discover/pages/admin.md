# Admin overrides

Apply `../MASTER.md` first. This page adds only the following Discover admin differences.

- Use RTL as the default admin direction for Persian labels, controls, filters, and data. Apply local LTR direction only to semantic English values such as slugs, URLs, identifiers, code-like values, and explicitly English fields; never force mixed-script values into one direction.
- Keep forms task-first: visible labels, helper text, validation on blur, inline errors adjacent to fields, and a keyboard-focusable error summary after a failed submit.
- Treat filter chips as native buttons with an accessible name, selected state, visible focus ring, and wrapped/reflowing collection. Do not hide overflow or depend on hover.
- Use content-first cards: title and status before metadata and actions; preserve a minimum 44px target for every interactive control.
- Motion is limited to 150–250ms state feedback. Respect `prefers-reduced-motion`; never use AI-purple or pink decorative gradients.
