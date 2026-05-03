---
name: web-mockups
description: Creates web-view mockups (wireframes, high-fidelity pages, or multi-page clickable prototypes) as vanilla HTML+CSS and hosts them on a persistent local server so the user gets a real URL to open in their browser. Use this skill whenever the user asks for a mockup, wireframe, prototype, landing page idea, design, "click-through", "show me what this could look like", "draw up a screen for...", a UI sketch, or any visual draft of a web interface — even if they don't say the word "mockup". Also use this skill if they ask for a quick HTML page to demo a UI idea, because hosting the result at a stable URL is almost always what they actually want. Prefer this skill over writing a loose .html file; the server and index page are the whole point.
---

# web-mockups

You produce vanilla HTML+CSS mockups and serve them from a persistent local server at `http://127.0.0.1:4280/`. Every mockup lives in its own directory under `~/.claude/mockups/<slug>/` and is reachable at `http://127.0.0.1:4280/<slug>/`. A root index page lists them all.

## Workflow

On every invocation:

1. **Start the server (idempotent).** Run:
   ```bash
   python ~/.claude/skills/web-mockups/scripts/ensure_server.py
   ```
   It prints the server URL and exits 0 whether it started the server or it was already running. You don't need to narrate this to the user — it's plumbing.

2. **Pick a slug.** Kebab-case, short, derived from the request. `password-manager-settings`, not `mockup1` or `PasswordManagerSettings_v2`.

3. **Pick a fidelity.** Choose one based on cues in the request:
   - **Wireframe** — words like "sketch", "rough", "layout idea", "structure", "boxes and lines". Grayscale, no real imagery, focus on hierarchy.
   - **High-fidelity** — words like "mockup", "design", "what it'd look like", "polished", or no cue at all. This is the default when the user is ambiguous, because polish is usually what stakeholders want to see.
   - **Multi-page flow** — words like "flow", "click-through", "walkthrough", "journey", more than one screen implied ("login then dashboard"). Build a small set of pages that link to each other with plain `<a href="./next-page.html">` style nav.

   If you want more guidance on any of these three (tokens, example snippets, navigation patterns), read `references/design-guide.md`. It's short.

4. **Write the files.** Create `~/.claude/mockups/<slug>/index.html` (and any additional pages for flows). Each file should be self-contained: inline `<style>` in the `<head>`, no external CSS/JS files. Inline styles keep each mockup grep-able and portable — the user can copy a whole directory to share it without pulling along a stylesheet tree, and there's no "did I forget to save styles.css" failure mode.

5. **Print the URL.** One line at the end of your response:
   ```
   → http://127.0.0.1:4280/<slug>/
   ```
   That's it. The user opens it in their browser and the page live-reloads when you edit it.

## Style rules

- **Semantic HTML**: `<header>`, `<nav>`, `<main>`, `<section>`, `<button>`, `<form>`. These carry meaning the user can riff on ("can you make the nav sticky?") without you having to infer intent from `<div class="navigation-thing">`.
- **System font stack**: `font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;`. Renders instantly, looks native-ish on every OS, zero network cost.
- **Generous whitespace and readable line length.** Mockups that are too dense feel like a finished product the user is afraid to criticize; airy layouts invite feedback.
- **No JavaScript unless the mockup genuinely needs interaction.** A pricing page doesn't. A tab widget does. When you do need JS, inline it in a `<script>` tag — no external files.
- **Color scheme**: declare `:root { color-scheme: light dark; }` and consider a `@media (prefers-color-scheme: dark)` block when the mockup is likely to be viewed on a dark-mode machine. Not required, but a nice touch.
- **Do not add a live-reload script yourself.** The server injects one into every HTML response. If you write your own you'll get duplicate EventSource connections.

## Extending an existing mockup

If the user says "update the login page" or "add a forgot-password screen to the auth flow" and a relevant slug already exists under `~/.claude/mockups/`, edit in place rather than creating a new slug. List the directory first so you know what's there. Live reload means their open browser tab will refresh as soon as you save, so iterating feels immediate.

## Multi-page flows — navigation pattern

For a flow, link between pages with relative paths that assume the slug prefix. If the slug is `checkout-flow` and you have `index.html`, `shipping.html`, `payment.html`, `confirmation.html`, link them with `href="./shipping.html"` etc. — never `/shipping.html` (would resolve to server root) and never absolute `http://` URLs.

Put a tiny breadcrumb or "next" affordance at the bottom of each page so the user can click through without a URL bar. This is the whole point of a flow.

## What not to do

- Don't invent brand logos or use copyrighted imagery. Use the company name as text, or a plain SVG circle/square placeholder with initials. The user can swap in real assets later.
- Don't scaffold build tooling. No `package.json`, no `vite.config`, no Tailwind CDN, no React. The skill is vanilla-only on purpose — fewer moving parts, smaller surface area, and every mockup is one `.html` file anyone can open without a toolchain.
- Don't write a README or commentary alongside the mockup. The mockup is the artifact; prose is noise. If the user asks "why did you choose X?", answer in the chat.
