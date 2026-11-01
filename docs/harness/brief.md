# Harness brief: repo

Written by uw-harness 0.3.0 on 2026-11-01 with claude. One page for the people who decide what comes next. It is rewritten on every run: do not edit it by hand.

## What changed

Harness coverage went from 23 to 92 out of 100, level 0 to 2 (self-checking). The coverage score measures structure: the files exist with real content, the commands resolve, the gates ran tests. It does not measure how good the docs or the tests are.

## What was checked by running it

| Gate | Command | Result | Tests |
| --- | --- | --- | --- |
| fast | `make check-fast` | pass | 238 tests |
| full | `make check` | pass | 1751 tests |

Before the harness, the project's tests could not be measured: `pytest` ran no test (exit 127). This says nothing about whether the tests pass, and the gates could not be compared with a starting point.
1 test files only compare literals (for example `assert True`) and protect nothing: `tests/integration/test_webhook_serializers.py`.

The test counts come from the output of the gates on the machine that ran uw-harness. They become proof when CI runs `npx uw-harness verify` on every pull request.

## What is left out or weaker

- 1 changes outside the harness are in a separate commit that `git revert` drops: `requirements-devel.in`.

## Secret-looking values

7 files hold values that look like secrets. If they are real, a human must rotate them and remove them from the git history: `settings/common.py` (framework secret key), `tests/integration/test_application_tokens.py` (password or secret), `tests/integration/test_importers_jira_api.py` (password or secret), `tests/integration/test_projects.py` (password or secret), `tests/integration/test_users.py` (password or secret), `tests/unit/auth/test_backends.py` (private key).

## Open questions

| Question | Who can answer | Where |
| --- | --- | --- |
| `settings/common.py:249` holds a hard-coded `SECRET_KEY`. Is it used by any real installation, and should it be read from an environment variable instead (with rotation)? | tech lead | `AGENTS.md`, [guide](https://docs.unwritten.sh/harness/requirements/env-example/) |
| `settings/common.py:249` holds a hard-coded `SECRET_KEY`. Is it used by any real installation, and should it be read from an environment variable instead (with rotation)? | tech lead | `CLAUDE.md`, [guide](https://docs.unwritten.sh/harness/requirements/env-example/) |
| What is the team's review rule (number of approvals, who can merge to `main`) and is merge commit the required strategy, or is squash allowed? | tech lead | `CONTRIBUTING.md`, [guide](https://docs.unwritten.sh/harness/requirements/agreements/) |
| Which environments exist (staging, production, on-premise customers) and what runs where? | whoever deploys to production | `docs/deploy.md`, [guide](https://docs.unwritten.sh/harness/requirements/deploy-explicit/) |
| Who builds and pushes the taiga-back image, to which registry, with which tags, and from which repository or pipeline? | whoever deploys to production | `docs/deploy.md`, [guide](https://docs.unwritten.sh/harness/requirements/deploy-explicit/) |
| How is tree.taiga.io deployed (tool, trigger, who can deploy), and where are the production compose or orchestration files? | whoever deploys to production | `docs/deploy.md`, [guide](https://docs.unwritten.sh/harness/requirements/deploy-explicit/) |
| How is a release rolled back, and how are migrations handled during a rollback (backup and restore, reverse migrations, forward fix only)? | whoever deploys to production | `docs/deploy.md`, [guide](https://docs.unwritten.sh/harness/requirements/deploy-explicit/) |
| What does the team check after a deploy (smoke test URL, logs, error rate), and who is told? | whoever deploys to production | `docs/deploy.md`, [guide](https://docs.unwritten.sh/harness/requirements/deploy-explicit/) |
| Which local setup do developers use today (a local PostgreSQL, the taiga-docker repository, something else), and should `compose.yaml` also start RabbitMQ by default and taiga-events? | tech lead | `docs/local-dev.md`, [guide](https://docs.unwritten.sh/harness/requirements/local-env/) |
| Where are the production logs of the API and the Celery workers collected, and how does a developer get access? | whoever runs production | `docs/observability.md`, [guide](https://docs.unwritten.sh/harness/requirements/observability/) |
| Is Sentry (or another error tracker) configured for production outside this repository, for example in a private settings file? Where do the team see errors? | whoever runs production | `docs/observability.md`, [guide](https://docs.unwritten.sh/harness/requirements/observability/) |
| Which dashboards and metrics does the team use for production (request rate, latency, queue length, worker health)? | whoever runs production | `docs/observability.md`, [guide](https://docs.unwritten.sh/harness/requirements/observability/) |
| What is the signal that production is broken (health check URL, key metric, alert rule) and which channel receives alerts? | whoever runs production | `docs/observability.md`, [guide](https://docs.unwritten.sh/harness/requirements/observability/) |

## The pilot task: Fix missing imports in taiga/projects/userstories/filters.py (latent NameError)

UserStoryStatusesFilter.filter_queryset uses `logger` and `exc`, but neither is imported, so a non-integer `project` parameter raises NameError instead of BadRequest. The bug is latent on GET /api/v1/userstories, because CanViewUsFilterBackend runs first and already returns 400, but the filter is broken whenever it runs on its own.

- Done when: taiga/projects/userstories/filters.py imports `exc` from taiga.base and defines a module `logger`, like taiga/base/filters.py does
- Done when: A new test in tests/unit calls UserStoryStatusesFilter().filter_queryset with QUERY_PARAMS {'project': 'abc'} and expects taiga.base.exceptions.BadRequest
- Done when: `.venv/bin/flake8 --select=F821 taiga/projects/userstories/filters.py` reports nothing
- Done when: `make check-fast` passes

Run it with `npx uw-harness prove`: an agent does the task with the harness, on its own branch, and the result is added to this page.

## What this does not prove

It does not prove that agents can work on this repository without supervision. It proves that the knowledge is written down and that the gates run and run tests. No pilot task has been run yet. One task is one data point. Review the branch, answer the open questions, and judge the result yourself.
