# Global rules

## No comments in code

Do not write comments. Write code that explains itself through naming and
structure instead.

- No explanatory comments, no section banners, no "what changed" notes, no
  commented-out code.
- Exceptions, and only these: a license/copyright header a file already
  requires, a machine-read directive (`#!/usr/bin/env ...`, `// @ts-ignore`,
  `# noqa`, `eslint-disable`, codegen markers), or a doc comment that a public
  API's tooling actually publishes.
- Editing a file that already has comments does not mean matching that style —
  leave existing comments alone, but do not add new ones.

## No Claude/AI attribution in commits

Git commits and PRs must read as the user's own work.

- No `Co-Authored-By: Claude ...` trailer.
- No `🤖 Generated with [Claude Code](...)` line in commit messages or PR bodies.
- No mention of Claude, Anthropic, or AI assistance anywhere in the subject,
  body, or trailers.

Write the message as a plain conventional commit describing the change.
