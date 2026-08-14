---
name: app-mirror
description: Builds a browsable static mirror of every page of an app that already exists in code — one URL, one shared theme file, plus a component gallery and a token sheet — so the user can click through the whole product and leave comments on layout, components, theme, copy, or navigation, which then get applied in place. Use this skill when the user asks to mock up or mirror the whole app rather than one screen: "mock up every page", "mirror the app", "I want to review the app's design", "walk me through all the screens", "let's go over the layout and theme of the app", "show me all our pages so I can comment on them", "design review of the product". For a single page or component, use the web-mockups skill's mirror pattern instead.
---

# app-mirror

You build a static mirror of **an entire existing app** under one URL, so the user can walk it end to end and comment on anything — a cramped page, a button that's wrong everywhere, a gray that's too warm, a nav that hides the thing they use daily — and you apply each comment at the layer it belongs to.

This sits on top of the **web-mockups** skill: same server, same live reload, same "Suggest a change" overlay, same style rules. Read these before building:

- `~/.claude/skills/web-mockups/SKILL.md` — server bootstrap, style rules, self-check, printing the URL.
- `~/.claude/skills/web-mockups/references/mirror.md` — how to mirror real code faithfully instead of improvising, and the `.source.md` discipline.

This file owns what's different: whole-app coverage, one shared theme, and routing each comment to the right layer.

## Where it lives

```
~/.claude/mockups/<project>/app/mirror/
  index.html        ← the map: every page as a thumbnail, with one line saying what it is
  home.html         ← the app's own landing page (never index.html — the map owns that name)
  <route>.html      ← one per mirrored route, kebab-cased: /settings/billing → settings-billing.html
  components.html   ← every shared component, in every state
  theme.html        ← the app's tokens on one sheet: color, type, spacing, radius, shadow
  style.css         ← the app's theme + component classes, shared by every page
  .source.md        ← route → source map, coverage table, change log (never served)
```

→ `http://127.0.0.1:4280/<project>/app/mirror/`

**One app mirror per project, edited in place forever.** No `v2`, no second directory — the user keeps the map open in a tab and expects their comments to land in it.

## Workflow

1. **Start the server** and **check pending feedback** exactly as `web-mockups/SKILL.md` steps 1–2 describe. Pending notes on an existing app mirror are the work — go to "Applying comments" and skip the build.

2. **Inventory the routes before writing anything.** Find the router, not the file tree:

   | Stack | Where the routes are |
   | --- | --- |
   | Next.js (app / pages) | `app/**/page.tsx` / `pages/**/*.tsx` minus `_app`, `_document`, `api/` |
   | SvelteKit | `src/routes/**/+page.svelte` |
   | Nuxt / Astro | `pages/**/*.vue` / `src/pages/**` |
   | React Router / Vue Router | the `<Route>` tree or `createBrowserRouter` / `routes: [...]` config |
   | Angular | `*-routing.module.ts`, `RouterModule.forRoot([...])` |
   | Rails / Django / Laravel | `config/routes.rb` / `urls.py` / `routes/web.php`, then the view templates |

   Dynamic routes (`[id]`, `:slug`) become **one representative page** with realistic data. List every route you found in `.source.md` with a status — mirrored, representative, or skipped and why. Never truncate silently; a map that quietly omits half the product is worse than one that says what's missing.

3. **Extract the theme first, into `style.css`.** Pull the real tokens (colors, type scale, spacing, radii, shadows, font stack) from the app's stylesheet, theme file, or Tailwind config into a `:root` block, then base element styles, then the shared component classes **under the app's own class names**. Every page links it with `<link rel="stylesheet" href="./style.css">` and adds only page-specific rules inline. This one file is what makes "make the whole app calmer" a single edit that live-reloads every open page.

4. **Build `components.html` and `theme.html`.** The component gallery renders each shared component — buttons, inputs, selects, cards, tables, modals, toasts, empty states — in every state that exists in the code (default, disabled, error, loading, empty), using the real class names. The token sheet shows swatches, type specimens, a spacing ruler, radius and shadow samples. Together they give the user somewhere to aim component and theme comments that isn't "the button on the third screen".

5. **Build the pages.** Each page follows `mirror.md`'s rules — read the real component, keep real copy and class names, default state, realistic data, no invented polish. Two additions for an app mirror:
   - **Reuse the app's own nav** as the click-through: keep its markup, rewrite its hrefs to `./<page>.html`. The product's real navigation is the walkthrough.
   - **Add a small fixed "← All pages" chip, top-right**, linking `./index.html`. Keep both bottom corners free — the server's nav pill and feedback button live there.

   For more than ~4 pages, fan out with subagents (one page each, in parallel). Each prompt carries: the absolute target path, that route's source files, the instruction to link `./style.css` and add **no** new CSS file, the class names already defined in `style.css`, the nav rewrite rule, the viewport meta, "no live-reload script, no feedback overlay", and a request to return the one-line description for the map. You write `style.css`, `components.html`, `theme.html`, and `index.html` yourself; subagents never run `ensure_server.py`.

6. **Write the map (`index.html`).** A grid of every page: thumbnail, title, one line of what it's for, and links to `components.html` and `theme.html`. Thumbnails are the real pages in scaled iframes requested with **`?__thumb=1`** — that query serves them with no injection at all, so a 20-card map holds zero SSE connections (browsers cap ~6 per origin; live iframes here would silently stall reload everywhere):

   ```html
   <a class="thumb" href="./settings-billing.html">
     <iframe src="./settings-billing.html?__thumb=1" loading="lazy" inert tabindex="-1" aria-hidden="true"></iframe>
   </a>
   ```
   ```css
   .thumb { position: relative; display: block; aspect-ratio: 16/10; overflow: hidden; }
   .thumb iframe { position: absolute; inset: 0; width: calc(500% + 20px); height: calc(500% + 20px);
                   transform: scale(.2); transform-origin: 0 0; border: 0; pointer-events: none; }
   ```

7. **Write `.source.md`** (see `mirror.md`) with the route → source map, the coverage table, and an empty change log.

8. **Self-check and print the URL.** Screenshot the map plus the two or three densest pages per `web-mockups/SKILL.md` step 7. Print the map URL, and mention `theme.html` and `components.html` once — the user won't guess they exist.

## Applying comments

Notes arrive through the overlay into a single `.feedback.md` in the mirror directory, each tagged with the page it came from, or straight from chat. **Classify every note by layer before editing:**

| The note is about | Edit | Then |
| --- | --- | --- |
| one page's layout, order, or copy | that page's `.html` | nothing else |
| a component — button, input, card, table row, modal | `style.css` **and** `components.html` | check every page that uses it |
| color, type, spacing, radius, shadow, density | the `:root` block in `style.css` | reopen the map and scan the thumbnails for fallout |
| navigation, IA, what pages exist or link where | the nav block in **every** page, plus the map | keep `index.html` and the nav in sync |
| something that's wrong on every page | the shared layer, never the page they happened to click | say so in your reply, so they know it propagated |

The failure mode this skill exists to prevent: the user clicks a button on the settings page, says "these are too heavy", and you fix that one button. It's a component note. Fix it in `style.css`, and the whole app changes at once — which is the answer they were actually asking for.

Then: log each change in `.source.md` under "Applied to the mirror, not yet in code", grouped by layer; delete the `.feedback.md` you handled; reply with what changed and which layer it hit — not the URL, they're already looking at it.

## Re-syncing and handing back to code

Both work as `mirror.md` describes, with one app-level addition: **re-run the route inventory** when you re-sync, so pages added or removed since the mirror was built show up in the map and the coverage table rather than silently going stale.

## What not to do

- Don't build 40 pages when 12 carry the design. Mirror what carries layout, components, and theme; record the rest in the coverage table and offer to add any of them.
- Don't inline the theme into each page. Per-page tokens turn "warm this up" into a 20-file edit and kill the one-edit theme loop.
- Don't name the app's landing page `index.html`. The map owns that name; the landing page is `home.html`.
- Don't wire real data, fetches, or auth. Static markup with realistic sample data, and only the interactions the user needs in order to judge (an open dropdown, an active tab).
- Don't create a second mirror, a `v2`, or option pages from here. If the user wants alternatives to compare, say you're stepping out of the app mirror and use the web-mockups options or redesign pattern in a `vN` directory.
