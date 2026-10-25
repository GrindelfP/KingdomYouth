# Tickets

One markdown file per planned feature or task, numbered sequentially (`0001-short-slug.md`, `0002-...md`, never reused). Tickets are written and refined before code; implementation should not start on a ticket that isn't in `status: ready`.

## Format

Each ticket file uses this structure:

```markdown
# 00NN — Title

- **Status:** backlog | ready | in-progress | done
- **Milestone:** link to the milestone in docs/roadmap.md
- **Depends on:** 00MM, 00KK (or "none")

## Goal
One or two sentences: what this ticket delivers and why it matters.

## Context
Relevant domain background, prior decisions, or constraints this ticket must respect.

## Scope
Bullet list of what is included.

## Out of scope
Bullet list of what is explicitly deferred, and (if known) which future ticket will cover it.

## Acceptance criteria
Checklist of observable conditions that mean the ticket is done.

## Open questions
Anything still undecided that implementation will need to resolve or that should be raised with the user.
```

## Status lifecycle
- `backlog` — identified, not yet detailed enough to implement.
- `ready` — scoped and unambiguous, can be picked up.
- `in-progress` — actively being implemented.
- `done` — merged and working; keep the file as a historical record, just flip the status.

## Numbering
Tickets are numbered in rough dependency/implementation order, not strict priority. See `docs/roadmap.md` for how tickets group into milestones.
