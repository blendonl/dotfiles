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

## Split work into small tasks and track them

Break every non-trivial request into the smallest steps that each stand on
their own, and keep the todo list as the single source of truth for progress.

- Use the todo tool (`TodoWrite`) at the start of any task with more than one
  step, and update it as you go.
- One todo = one verifiable outcome. If a step can't be checked off on its own,
  split it further.
- Exactly one todo `in_progress` at a time. Mark it `completed` right after it
  is done — never batch completions at the end.
- New work discovered mid-task gets added as its own todo instead of being
  folded into the current one.
- Skip the list only for a single trivial step (one file read, one small edit,
  a plain question).

## Ask with the question tool

When a decision is genuinely mine to make, use the question tool
(`AskUserQuestion`) instead of guessing or listing options in prose.

- Two options max, each with the context needed to pick fast.
- Put the recommended one first and label it `(Recommended)`.
- Ask at the point the answer is needed — do everything that doesn't depend on
  it first.
- Don't ask when there's an obvious default or the answer is in the codebase.
  Pick it, say what you picked, and keep going.

## No Claude/AI attribution in commits

Git commits and PRs must read as the user's own work.

- No `Co-Authored-By: Claude ...` trailer.
- No `🤖 Generated with [Claude Code](...)` line in commit messages or PR bodies.
- No mention of Claude, Anthropic, or AI assistance anywhere in the subject,
  body, or trailers.

Write the message as a plain conventional commit describing the change.
