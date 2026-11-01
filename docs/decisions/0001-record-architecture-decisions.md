# 0001. Record architecture decisions

Date: 2026-11-01

Status: accepted

## Context

taiga-back has a long history (more than 4000 commits). Many choices, such as the own REST layer in `taiga/base/api` or pickle for Celery, are visible in the code but the reasons are not written anywhere. New contributors and coding agents then change things they should not change, or keep things that nobody needs any more.

## Decision

We record each important decision in a short Markdown file in `docs/decisions/`, named `NNNN-title-with-dashes.md`, with these sections:

- **Context**: the situation and the forces at play.
- **Decision**: what we decided, in one or two paragraphs.
- **Consequences**: what becomes easier, what becomes harder, what to watch.

A record is never rewritten after it is accepted. To change a decision, add a new record that supersedes the old one and update the old record's status to "superseded by NNNN".

Records that describe a decision found in the code, without a written source, say: "Inferred from the code, to be confirmed by the team."

## Consequences

- Reviewers can ask for a record when a pull request changes an architectural choice.
- Agents read `docs/decisions/` before they change settings, the REST layer, Celery or events.
