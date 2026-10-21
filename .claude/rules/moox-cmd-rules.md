# MooX-Cmd House Rules

Apply to every task in this repository unless explicitly overridden. Bias: caution over
speed on non-trivial work; use judgment on trivial tasks. Loaded automatically at launch.
Subagents get their conventions from the force-loaded skills — this file is for the
orchestrating agent.

## Engineering discipline

1. **Think before coding** — State assumptions; when uncertain, ask rather than guess.
   Push back when a simpler approach exists; stop when confused and name what is unclear.
2. **Simplicity first** — Minimum code that solves the problem. Nothing speculative.
   The documented behaviour is the contract; no fallbacks for features that do not exist.
3. **Surgical changes** — Touch only what you must. Don't "improve" adjacent code,
   comments or formatting. Match the existing layout.
4. **Tests verify intent, not just behavior** — Reproduce a bug before fixing it; leave
   a regression test behind. The command chain and the execute contract are the product.
5. **Match the codebase's conventions, even if you disagree** — Conformance > taste.
   Surface a harmful convention; don't fork silently.
6. **Fail loud** — "Done" is wrong if anything was skipped silently. "Tests pass" is
   wrong if any were skipped.
7. **A red test is a claim before it is a failure** — Say what it asserts and whether
   your fix keeps that claim or replaces it.

## Delegation

Depends on whether the Agent/Task tool is available to you.

- **You can spawn subagents** (orchestrating main agent): Do NOT touch behavior-relevant
  code yourself — delegate. Your lane: coordinate, inspect, plan, review diffs, run
  tests, edit non-behavioral docs. Only the `moox-cmd-*` agents get their skills
  force-loaded; you get no briefing.

  | Task | Agent |
  |---|---|
  | Implement / refactor / debug behavior-relevant code | `moox-cmd-worker` (default) |
  | Commits, `Changes`, card → done, pre-release audit | `moox-cmd-release-manager` |

- **You cannot spawn subagents** (you ARE a `moox-cmd-*` agent): The delegation lock
  does not apply — implement, refactor, debug and test per these rules.

Behavior-relevant = `lib/`, the tests, the tester, the roles. README and `Changes`
wording are not.

**Only `moox-cmd-release-manager` commits.** A worker leaves a commit-ready tree and
hands its card to `review`; you then dispatch the release-manager to cut the commit.

## The framework contract is the product — don't regress it silently

This distribution *is* the contract that an application builds on: what `use MooX::Cmd`
composes, the import options and the attributes they override, the `execute`
signature, the rule that only the deepest command of the chain executes, the
discovery of command classes below `command_base`, and the storage of the execute
return value. A change to any of them is visible in every application that uses the
framework: it needs a `Changes` entry and a test that pins it. The optional roles
belong to their external dependency — a `recommends` dependency loaded at compile
time is a bug. Full contract table: skill `moox-cmd-core`.

## Coordination — karr board (always in scope)

Ticket coordination is the orchestrating agent's job: `karr` is always in scope — use it, don't invoke the skill first.
`karr list --compact` / `karr board` for open work, `karr show ID` for detail,
`karr create --title … --priority … --body …` for a ticket, `karr edit ID -a …`,
`karr move ID in-progress --claim NAME` to start, `karr handoff ID --claim NAME` to
review, `karr sync --pull|--push` for explicit exchange.

Card life cycle: you claim and hand out → the worker notes and ends at `review` → the
release-manager commits and moves it to `done`. **Serialize board mutations when
fanning out:** collect the results and then loop the `karr move`/`handoff`/`sync` calls
sequentially — N of them landing at once is a resource event, not a cheap command.
Full command surface: `kanban-issues-karr-coordination`.

## Release — never without permission

`dzil build` / `dzil test` / `prove -lr t/` / `prove -lr xt/` are fine anytime.
`dzil release` and any CPAN upload are STRICTLY forbidden without the maintainer's
explicit go-ahead — even if a plan lists "release" as the next step. Stop and ask.
The last CPAN release is 1.000 (2026-02-28); the repo carries 1.001 — the *next* unreleased version.

## Public issues — never act without instruction

`karr` is the internal agent board, churned freely. The GitHub issue tracker carries
real people's reports under the maintainer's account. Never act on a public issue on
your own initiative — not even to read it. No listing, viewing, commenting, closing or
creating unless the user explicitly says so.

## Perl specifics — reference, don't restate

Perl conventions live in the force-loaded skills; the module map, the import options
and the command contract live in skill `moox-cmd-core`.
