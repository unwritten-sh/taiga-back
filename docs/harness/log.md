# Harness log

One entry per significant change: date, what changed, what was learned, what is left.

## Notes from the harness build

- **Lint is limited in the gates.** `flake8 .` with the `setup.cfg` rules reports 1309 violations in existing code (top codes: F401 163, E501 118, E402 118, E231 84, E252 78). CI never ran flake8 before. The gates run `flake8 --select=E9,F63,F7 .` (syntax errors and invalid comparisons), which passes. `make lint-full` runs the full rules. No rule was added to the flake8 configuration.
- **Undefined names (F821) in product code, left for a human.** `taiga/projects/userstories/filters.py:45-47` uses `logger` and `exc` without importing them: `UserStoryStatusesFilter` raises `NameError` instead of `BadRequest` for a non-integer `project` parameter. On `GET /api/v1/userstories` the bug is masked because `CanViewUsFilterBackend` runs first and already returns 400, so it is latent. `taiga/base/fields.py:111-133` uses `ValidationError` and `NestedValidationError` without importing them. `taiga/projects/attachments/services.py:95` uses string type hints for models that are not imported (no runtime effect). `taiga/events/middleware.py` has three unused `global _local` statements (F824).
- **Unit tests are the fast gate.** `make check-fast` runs `tests/unit` (238 tests, about 30 s with a warm test database). Integration tests run only in `make check`.
- **The full gate needs a fresh test database.** A first `make check` with `--reuse-db` had 51 failures in `tests/integration/test_hooks_*`: transactional tests had flushed the reused database, so the system users created by a data migration were missing. `make check` and `make test` now use `--create-db`, like CI. The fast gate keeps `--reuse-db` (unit tests do not need that data).
- **The full suite is slow.** `make check` runs all 1751 collected tests with coverage in about 15 minutes on a laptop. Most time is in fixture setup: `tests/factories.py` hashes a password for each user with PBKDF2 (`PASSWORD_HASHERS` in `settings/common.py`). A faster hasher in `tests/config.py` would speed it up, but it changes test settings and needs a team decision.
- **Tests need PostgreSQL.** The gates start it with `docker compose up -d --wait postgres` (`make db-up`) unless `CI` is set. The compose service runs with `fsync=off`; without it, the first test run took about 100 s for the unit tests alone on Docker for Mac.
- **Git hook.** The sandbox did not allow writing `.pre-commit-config.yaml`, so the pre-push hook is `.githooks/pre-push`, installed with `git config core.hooksPath .githooks` by `make setup`.
- **CI.** `.github/workflows/tests-and-coverall.yml` now runs `npx -y uw-harness verify` (setup, check-fast, check) instead of calling pytest directly. `make check` keeps the same coverage command, so the Coveralls step still finds `.coverage`. The unit tests run twice in CI (fast gate, then full gate). On 2026-11-01 `npx -y uw-harness` returned 404 from the npm registry: the CI step fails until the package is published (or the step is changed to call `make check` directly).
- **Dev dependency added.** `flake8` in `requirements-devel.in`; `requirements-devel.txt` regenerated with `pip-compile` without `--upgrade` (only additions: flake8, mccabe, pycodestyle, pyflakes).
- **Secret in tracked code, not changed.** `settings/common.py:249` holds a hard-coded `SECRET_KEY`. See the TODO in `AGENTS.md` and the `blocked` list of the harness build.

## 2026-11-01: missing imports in userstories filters fixed

- **What changed.** `taiga/projects/userstories/filters.py` now imports `exceptions as exc` from `taiga.base` and defines a module `logger`, like `taiga/base/filters.py`. `UserStoryStatusesFilter` now raises `BadRequest` instead of `NameError` for a non-integer `project` parameter. New unit test `tests/unit/test_userstories_filters.py` (it failed with `NameError` before the fix). `flake8 --select=F821` on the file is clean. `make check-fast`: 239 passed.
- **What we learned.** Filter backends can be tested in `tests/unit` with a `mock.Mock(QUERY_PARAMS=...)` request, without the database.
- **What is left.** The other F821 items from the harness build notes (`taiga/base/fields.py:111-133`, `taiga/projects/attachments/services.py:95`) are still open.

## 2026-11-01: fast gate output shows the test run

- **What changed.** `make test-unit` (used by `make check-fast`) ran `pytest tests/unit --reuse-db -q`. The `-q` flag hides the pytest header ("test session starts", "collected N items") and the file names, so the harness verifier reported that the fast gate ran no tests, although 238 tests passed. The target now runs `pytest tests/unit --reuse-db -rA --tb=short`: the output shows the header, one line per test file, one `PASSED <test id>` line per test and the final summary (`238 passed`). No test or check was removed.
- **What we learned.** A local output filter (rtk) can also truncate `make` output in an agent session; use `rtk proxy make check-fast` to see the real output.
- **What is left.** Nothing for this gate.

## 2026-11-01: harness built by uw-harness 0.3.0 with claude

Score 23 → 92, level 0 → 2.

This branch adds a Makefile around the existing pip/pytest/coverage workflow. `make check-fast` runs a limited flake8 plus 238 unit tests in about 30 s; `make check` runs lint, a migrations check and all 1751 tests with the same coverage command as CI, in about 16 min. All of them passed locally from a clean shell, and `make dev` and `make db-reset` were also run against the new compose.yaml PostgreSQL. CI now runs `npx -y uw-harness verify`, but that package returns 404 on npm today, so the step stays red until the package is published. Lint is limited to syntax rules because old code has 1309 flake8 violations, including some undefined names. The hard-coded SECRET_KEY is reported, not changed. New docs cover architecture, product, local dev, decisions, deploy and observability, with 12 TODO blocks for humans; there are also 4 skills, AGENTS.md, and CLAUDE.md as a symlink to it.

The fast gate already ran 238 unit tests, but `pytest -q` hid the session header, the collected count and the file names, so the verifier did not see a test run. The test-unit target now uses `-rA --tb=short` instead of `-q`. `make check-fast` (run without the local rtk output filter) exits 0 and prints "test session starts", "collected 238 items", one line per test file, 238 "PASSED <test id>" lines and "238 passed, 187 warnings in 25.00s". No test, lint rule or configuration was weakened. The change is recorded in docs/harness/log.md.

**Assessment.** Django REST API backend of Taiga, an open-source agile project management platform (Scrum and Kanban). Stack: Python 3.10 (.python-version, CI); Docker image uses Python 3.11, Shell, Django 3.2.25 (requirements.txt), Taiga's own REST layer in taiga/base/api (DRF-like ViewSets and routers), Celery 5.5.3, gunicorn 23, django-jinja, pytest 7.2.1 + pytest-django + factory-boy 3.2.1. The full assessment stays in `.git/uw-harness/assessment.md` on the machine that ran uw-harness.

Risks seen before the harness:

- Tests need a running PostgreSQL (tests/config.py: localhost, user/pass taiga; or postgres/postgres when GITHUB_WORKFLOW is set). The fast gate will fail without the database.
- Hard-coded SECRET_KEY in settings/common.py line 249 and default DB/email passwords: the env-example secret scan will report partial until a human decides.
- Django 3.2.25 is end-of-life; several pins exist only to stay compatible (bleach<5, django-picklefield<3.3, easy-thumbnails<2.9). Upgrades can break installation.
- Python mismatch: .python-version and CI use 3.10, Docker image uses 3.11.
- System libraries needed to install requirements (libpq-dev for psycopg2, libmagic for python-magic, cairo for cairosvg, gettext for compilemessages) are not documented.

**Before the harness**: `pytest`, ran no test (exit 127).

**Gates verified by the CLI**

- pass: `make check-fast` (238 tests)
- pass: `make check` (1751 tests)

**Changes that reduce protection or touch the product**, in a separate commit for review:

- M `requirements-devel.in`: changed existing application code

**Test files that only compare literals** (they protect nothing)

- `tests/integration/test_webhook_serializers.py`

**Secret-looking values already in the repository**

- `settings/common.py` (framework secret key)
- `tests/integration/test_application_tokens.py` (password or secret)
- `tests/integration/test_importers_jira_api.py` (password or secret)
- `tests/integration/test_projects.py` (password or secret)
- `tests/integration/test_users.py` (password or secret)
- `tests/unit/auth/test_backends.py` (private key)
- `tests/unit/auth/test_token_denylist.py` (password or secret)

**First task to try with the harness:** Fix missing imports in taiga/projects/userstories/filters.py (latent NameError). UserStoryStatusesFilter.filter_queryset uses `logger` and `exc`, but neither is imported, so a non-integer `project` parameter raises NameError instead of BadRequest. The bug is latent on GET /api/v1/userstories, because CanViewUsFilterBackend runs first and already returns 400, but the filter is broken whenever it runs on its own.

- Done when: taiga/projects/userstories/filters.py imports `exc` from taiga.base and defines a module `logger`, like taiga/base/filters.py does
- Done when: A new test in tests/unit calls UserStoryStatusesFilter().filter_queryset with QUERY_PARAMS {'project': 'abc'} and expects taiga.base.exceptions.BadRequest
- Done when: `.venv/bin/flake8 --select=F821 taiga/projects/userstories/filters.py` reports nothing
- Done when: `make check-fast` passes

**Changed files**

- `.github/workflows/tests-and-coverall.yml` (ci): The direct pytest step is replaced by Node 20 + `npx -y uw-harness verify`. The postgres/rabbitmq services and the Coveralls step stay (make check still writes .coverage).
- `.githooks/pre-push` (hooks): Pre-push hook that runs make check-fast. make setup installs it with git config core.hooksPath .githooks.
- `requirements-devel.in` (fast-gate): Added flake8 as a dev dependency.
- `requirements-devel.txt` (fast-gate): Recompiled with pip-compile, no --upgrade: only adds flake8, mccabe, pycodestyle, pyflakes.
- `.gitignore` (local-env): Added .pytest_cache/, .coverage.*, coverage.xml, htmlcov/.
- `compose.yaml` (local-env): postgres:13 (taiga/taiga/taiga, fsync off, healthcheck, named volume) and an optional rabbitmq service under the async profile.
- `docs/local-dev.md` (local-env): Prerequisites (Python 3.10, libpq, libmagic, cairo, gettext), first run, daily run, async mode, reset, debugging, common problems, the --reuse-db trap, a local-env TODO.
- `.env.example` (env-example): Every variable read by docker/config.py, with safe or empty values. States that local dev on the host does not read them.
- `docs/architecture.md` (architecture): Mermaid diagram plus sections for the API, base framework, domain apps, Celery, events, settings, data stores (real table names), external services, and what is not in the repository.
- `docs/product.md` (product): Value proposition, users, use cases with their API routes and folders, glossary of domain terms.
- `docs/decisions/0001-record-architecture-decisions.md` (decisions): ADR format and rules.
- `docs/decisions/0002-celery-with-rabbitmq-and-pickle.md` (decisions): Inferred decision: Celery with RabbitMQ, optional through CELERY_ENABLED, pickle serializer, pluggable events backend, and what follows from it.
- `CONTRIBUTING.md` (agreements): Added a section on branches and PRs taken from the history, a never-push-to-main rule, a review-rule TODO, and a proposed definition of done that includes make check-fast.
- `docs/deploy.md` (deploy-explicit): What the repo shows: image build, entrypoints, env config, migrations on start. TODO blocks for environments, registry, deploy, rollback and post-deploy checks.
- `docs/observability.md` (observability): What the code shows: LOGGING config, gunicorn/Celery logs, sentry-sdk installed but never initialised, no metrics, API root as the only liveness signal. TODO blocks for logs, errors, dashboards and alerts.
- `.agents/skills/implement-change/SKILL.md` (skills): Steps from task to verified change, using the make gates and project conventions.
- `.agents/skills/debug-local/SKILL.md` (skills): Reproduce with pytest, pdb, running the API with sample data, inspecting data, known traps.
- `.agents/skills/add-api-endpoint/SKILL.md` (skills): Model, validator, permissions, viewset, router registration, permission-matrix tests, based on taiga/userstorage.
- `.agents/skills/deploy/SKILL.md` (skills): Says the deploy procedure is unknown, points to docs/deploy.md TODOs, and lists only safe local steps.
- `AGENTS.md` (agents-file): 88-line index: what this is, commands, layout, conventions, how to verify, never-do list, env-example TODO, links. Tells agents to run make check-fast and to add log entries.
- `CLAUDE.md` (agents-file): Symlink to AGENTS.md.
- `Makefile` (fast gate must show a test run): The test-unit target (used by check-fast) now runs `pytest tests/unit --reuse-db -rA --tb=short` instead of `-q`. The output now shows the pytest header, collected count, one line per test file, one PASSED line per test and the final summary (238 passed). No test was removed or skipped.
- `docs/harness/log.md` (log significant changes): Added a 2026-11-01 entry: why the verifier saw no test run (-q hides the header and file names), what changed, and that a local rtk output filter can truncate make output in agent sessions.

**Open questions for a human**

- settings/common.py:249 holds a hard-coded SECRET_KEY. Is it used by any real installation, and should it be read from an environment variable instead (with rotation)? (in `AGENTS.md`)
- Which local setup do developers use today (a local PostgreSQL, the taiga-docker repository, something else), and should compose.yaml also start RabbitMQ by default and taiga-events? (in `docs/local-dev.md`)
- Which environments exist (staging, production, on-premise customers) and what runs where? (in `docs/deploy.md`)
- Who builds and pushes the taiga-back image, to which registry, with which tags, and from which repository or pipeline? (in `docs/deploy.md`)
- How is tree.taiga.io deployed (tool, trigger, who can deploy), and where are the production compose or orchestration files? (in `docs/deploy.md`)
- How is a release rolled back, and how are migrations handled during a rollback (backup and restore, reverse migrations, forward fix only)? (in `docs/deploy.md`)
- What does the team check after a deploy (smoke test URL, logs, error rate), and who is told? (in `docs/deploy.md`)
- Where are the production logs of the API and the Celery workers collected, and how does a developer get access? (in `docs/observability.md`)
- Is Sentry (or another error tracker) configured for production outside this repository, for example in a private settings file? Where do the team see errors? (in `docs/observability.md`)
- Which dashboards and metrics does the team use for production (request rate, latency, queue length, worker health)? (in `docs/observability.md`)
- What is the signal that production is broken (health check URL, key metric, alert rule) and which channel receives alerts? (in `docs/observability.md`)

## 2026-11-01: pilot task done with the harness by claude

**Task:** Fix missing imports in taiga/projects/userstories/filters.py (latent NameError). UserStoryStatusesFilter.filter_queryset uses `logger` and `exc`, but neither is imported, so a non-integer `project` parameter raises NameError instead of BadRequest. The bug is latent on GET /api/v1/userstories, because CanViewUsFilterBackend runs first and already returns 400, but the filter is broken whenever it runs on its own.

UserStoryStatusesFilter used `logger` and `exc` without importing them, so a non-integer `project` parameter raised NameError instead of BadRequest. I added `import logging`, `from taiga.base import exceptions as exc` and `logger = logging.getLogger(__name__)` to taiga/projects/userstories/filters.py, the same way taiga/base/filters.py does it. A new unit test calls the filter with QUERY_PARAMS {'project': 'abc'}. Before the fix it failed with NameError, and after the fix it passes with BadRequest. flake8 F821 on the file is clean, `make check-fast` exits 0 (239 passed), and I added an entry to docs/harness/log.md.

- Status reported by the agent: done. Acceptance criteria met: 4 of 4.
- Gates after the task: pass. Tests before: 1751 tests. After: 1752 tests.
- Fix rounds after a gate failed: 0. Questions for a human: 0. Unattended: yes.
- Harness gap: `AGENTS.md`: AGENTS.md does not warn that the local rtk output filter truncates `make check-fast` output: I saw only warnings and '248 lines truncated', with no pass/fail summary. The workaround (`rtk proxy make check-fast`) is only written in docs/harness/log.md. It should be in AGENTS.md next to the gate command, or the gate should print a short last line with the result.
- Harness gap: `.agents/skills/implement-change/SKILL.md`: The skill gives only integration-test examples (`tests/integration/test_userstories.py`). It does not say that small units such as filter backends can be tested in tests/unit with a mocked request (`mock.Mock(QUERY_PARAMS=...)`) and no database. I found this pattern myself.
