# Design guide

Copy-paste tokens and patterns for the three fidelities. Keep it minimal — the goal is "looks intentional", not "looks shipped".

---

## Wireframe

**Intent:** show structure and hierarchy without committing to visual style. Gray boxes, dashed borders, placeholder text. The user should look at it and think about layout, not colors.

**Tokens:**
```css
:root {
  --bg: #fafafa;
  --fg: #333;
  --muted: #999;
  --line: #bbb;
  --box: #e5e5e5;
  --radius: 4px;
  --gap: 1rem;
  --font: ui-monospace, "SF Mono", Menlo, Consolas, monospace;
}
body { background: var(--bg); color: var(--fg); font-family: var(--font); }
.box { background: var(--box); border: 1px dashed var(--line); border-radius: var(--radius); padding: var(--gap); }
.placeholder { color: var(--muted); font-style: italic; }
```

Use a monospace font — it signals "this is a draft" and stops the user from treating gray-box wireframes as a design review. Use `Lorem ipsum` or short bracketed descriptors like `[hero image]`, `[product grid, 3 cols]` inside boxes rather than trying to write real copy.

---

## High-fidelity

**Intent:** something close to a real product. Real-ish typography, intentional color, soft shadows, rounded corners. Still single-page, still no real backend, but visually convincing.

**Tokens (neutral, modern default — override when the brief suggests otherwise):**
```css
:root {
  color-scheme: light dark;
  --bg: #ffffff;
  --fg: #0f172a;
  --muted: #64748b;
  --subtle: #f1f5f9;
  --border: #e2e8f0;
  --accent: #2563eb;
  --accent-fg: #ffffff;
  --radius: 10px;
  --shadow: 0 1px 3px rgba(0,0,0,0.06), 0 1px 2px rgba(0,0,0,0.04);
  --font: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
}
@media (prefers-color-scheme: dark) {
  :root {
    --bg: #0b1220; --fg: #e2e8f0; --muted: #94a3b8;
    --subtle: #111827; --border: #1f2937;
    --shadow: 0 1px 3px rgba(0,0,0,0.5);
  }
}
body { background: var(--bg); color: var(--fg); font-family: var(--font);
       line-height: 1.5; margin: 0; }
.button { background: var(--accent); color: var(--accent-fg); border: 0;
          padding: 0.6rem 1rem; border-radius: var(--radius); font: inherit;
          cursor: pointer; }
.card { background: var(--bg); border: 1px solid var(--border);
        border-radius: var(--radius); padding: 1.5rem; box-shadow: var(--shadow); }
```

When the user names a brand or product category, shift the accent color accordingly (fintech → deeper blue/green, consumer → warmer hues, developer tools → violet or neutral). But don't labor over it — a sensible default is better than a timid one.

Use real-feeling copy. "Reset password" beats "Button 1". "Your team's quarterly numbers" beats "Header text here". The user is trying to imagine this in front of their audience; generic placeholder copy breaks the illusion.

---

## Multi-page flow

**Intent:** a small clickable walkthrough. Same visual language as high-fi (reuse those tokens), but now the navigation itself is part of the design.

**Pattern:**
- Every page gets the same header/nav so the flow feels cohesive.
- At the bottom of each page (or inside the primary CTA), link to the next page with a relative path: `href="./payment.html"`. Never absolute paths — they'll break under the `/slug/` prefix.
- Include a minimal "flow footer" so the user can skip around without typing URLs:
  ```html
  <footer class="flow-nav">
    <a href="./index.html">1. Cart</a>
    <a href="./shipping.html">2. Shipping</a>
    <a href="./payment.html" aria-current="page">3. Payment</a>
    <a href="./confirmation.html">4. Done</a>
  </footer>
  ```
  Style the `aria-current="page"` one with a bolder weight or accent color.
- If a step has a form, make the submit button link to the next page (`<a class="button" href="./next.html">Continue</a>`). Don't use real `<form>` POSTs — there's no backend, and the browser will try to submit.

**File layout example for `checkout-flow`:**
```
~/.claude/mockups/checkout-flow/
├── index.html          # cart review
├── shipping.html
├── payment.html
└── confirmation.html
```

---

## When the user gives you an aesthetic brief

"Make it feel like Stripe." "More playful." "Monochrome, editorial." Take the brief seriously and override the defaults above. The tokens here are a neutral starting point, not a house style — a good mockup matches the brief's vibe, not this file's.
