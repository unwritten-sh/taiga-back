# AGENTS.md

taiga-back is the Django 3.2 REST API of Taiga, an open-source agile project management tool (Scrum and Kanban: backlogs, sprints, Kanban boards, issues, wiki). It stores project data in PostgreSQL, checks permissions, sends notifications and webhooks, and imports projects from Jira, Trello, Asana and GitHub.

## Commands

| Task | Command |
|---|---|
| List all tasks | `make help` |
| Setup (venv with Python 3.10, deps, git hook, PostgreSQL, migrations) | `make setup` |
| Run the API on http://localhost:8000/api/v1/ | `make dev` |
| Load admin/123123 and sample data (destroys local data) | `make db-reset` |
| Fast gate: lint + unit tests (about 30 s) | `make check-fast` |
| Full gate, what CI runs: lint, migrations check, whole suite with coverage (about 15 min) | `make check` |
| Whole suite without coverage | `make test` |
| Full flake8 rules (fails today on old code) | `make lint-full` |

Run one test file or one test:

```bash
.venv/bin/pytest tests/unit/test_slug.py
.venv/bin/pytest tests/integration/test_userstories.py -k <name> --reuse-db
```

`--reuse-db` is faster, but transactional tests flush data created by migrations (for example the system users of `taiga/hooks`). On an unexpected `DoesNotExist`, run again with `--create-db`.

Tests need the compose PostgreSQL on `localhost:5432` (user, password and database `taiga`). `make db-up` starts it; the gates call it for you. Details: [docs/local-dev.md](docs/local-dev.md).

## Layout

| Path | Content |
|---|---|
| `taiga/routers.py`, `taiga/urls.py` | All `/api/v1/` routes, admin, sitemap |
| `taiga/base/` | Taiga's own REST layer (`taiga.base.api`), filters, exceptions, utils |
| `taiga/projects/` | Projects, memberships and sub-apps: `userstories`, `milestones`, `tasks`, `issues`, `epics`, `wiki`, `attachments`, `history`, `notifications`, `occ` |
| `taiga/auth/`, `taiga/users/` | Login, JWT, accounts, password recovery |
| `taiga/timeline/`, `taiga/webhooks/`, `taiga/events/` | Activity feeds, outgoing webhooks, real-time event push |
| `taiga/hooks/`, `taiga/importers/`, `taiga/export_import/` | Incoming Git webhooks, imports from other tools, project dumps |
| `taiga/celery.py` | Celery app and beat schedule |
| `settings/` | `common.py` (defaults), `config.py.*.example`; local `settings/config.py` is gitignored |
| `docker/` | Dockerfile, entrypoints, `config.py` (env-based settings, see `.env.example`) |
| `tests/` | `unit/`, `integration/`, `integration/resources_permissions/`, `factories.py`, `config.py` (test settings) |
| `docs/` | Architecture, product, local dev, deploy, observability, decisions, harness log |

## Conventions that matter

- New endpoints use `taiga.base.api` viewsets and `taiga.base.exceptions`, not Django REST framework. Register them in `taiga/routers.py`.
- Every Python file starts with the MPL 2.0 license header (copy it from a neighbour file).
- User-facing strings use `gettext` (`_()`). Never edit `taiga/locale/*.po`: Weblate manages them.
- Async work must also run when `CELERY_ENABLED` is false ([decision 0002](docs/decisions/0002-celery-with-rabbitmq-and-pickle.md)).
- Model changes ship with their migration in the same pull request.
- Requirements are compiled with pip-tools: edit `requirements*.in`, then compile (see [docs/update-dependencies.md](docs/update-dependencies.md)).
- Commits follow conventional commits (`fix:`, `feat:`, `test:`, `chore:`). Branches look like `<author>/<YYYYMMDD>/<topic>`. See [CONTRIBUTING.md](CONTRIBUTING.md).
- Python 3.10 locally and in CI (`.python-version`); the Docker image uses 3.11.
- flake8 rules live in `setup.cfg` (max line 120). The gates only enforce syntax rules because old code has many violations; keep new code clean with `.venv/bin/flake8 <file>`.

## How to verify a change

1. Add or update a test in `tests/unit` or `tests/integration`. A bug fix comes with a test that failed before.
2. Run `make check-fast`. It must pass before you say a change is done. The pre-push hook runs it too.
3. For API, permission or signal changes, run the related integration test files, or `make check`.
4. If you changed models: `make migrations-check`.
5. Add an entry to [docs/harness/log.md](docs/harness/log.md) after each significant change: date, what changed, what you learned, what is left.

## Never do

- Never push to `main` or merge without a human review. Work on a branch and open a pull request.
- Never edit existing migrations or `taiga/locale/*.po` files.
- Never commit `.env` or `settings/config.py`, or put real secrets in code.
- Never run `make db-reset` or `regenerate.sh` against a database that is not your local compose database.
- Never connect to production or deploy: the procedure is not in this repository ([docs/deploy.md](docs/deploy.md)).
- Never weaken a check to get a green gate (skip tests, add flake8 ignores, exclude folders). Report the problem instead.
- Never change the Celery serializer, the events backend or `docker/config.py` variable names without a decision record.

> [!WARNING]
> **Needs a human.** `settings/common.py:249` holds a hard-coded `SECRET_KEY`. Is it used by any real installation, and should it be read from an environment variable instead (with rotation)?
> Why it matters and how to do it: https://docs.unwritten.sh/harness/requirements/env-example/
<!-- uw-harness:todo env-example -->

## Where to find more

- [docs/architecture.md](docs/architecture.md): components, data stores, external services, diagram.
- [docs/product.md](docs/product.md): users, use cases with entry points, glossary.
- [docs/local-dev.md](docs/local-dev.md): prerequisites, first run, debugging, common problems.
- [docs/decisions/](docs/decisions/): architecture decision records.
- [docs/deploy.md](docs/deploy.md) and [docs/observability.md](docs/observability.md): what is known, open questions.
- [docs/harness/log.md](docs/harness/log.md): implementation log.
- Skills in `.agents/skills/`: `implement-change`, `debug-local`, `add-api-endpoint`, `deploy`.
