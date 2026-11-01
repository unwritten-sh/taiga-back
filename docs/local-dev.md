# Local development

The API runs on the host in a Python 3.10 virtualenv (`.venv`). PostgreSQL runs in Docker from `compose.yaml`. RabbitMQ is optional.

> [!WARNING]
> **Needs a human.** Which local setup do developers use today (a local PostgreSQL, the taiga-docker repository, something else), and should `compose.yaml` also start RabbitMQ by default and taiga-events?
> Why it matters and how to do it: https://docs.unwritten.sh/harness/requirements/local-env/
<!-- uw-harness:todo local-env -->

`compose.yaml` and the Makefile targets were added by the harness build on 2026-11-01. They are tested on macOS with Docker Desktop.

## Prerequisites

- Python 3.10 (pinned in `.python-version`, used by CI). `make setup` uses [uv](https://docs.astral.sh/uv/) to get it when uv is installed, otherwise `python3.10`. Note: the Docker image (`docker/Dockerfile`) uses Python 3.11.
- Docker with the `docker compose` plugin.
- System libraries to build and run the requirements: libpq and `pg_config` (psycopg2 is built from source), libmagic (python-magic), cairo (cairosvg), gettext (`compilemessages`). On macOS: `brew install libpq libmagic cairo gettext`.
- The PostgreSQL client tools (`dropdb`, `createdb`) for `make db-reset`.
- Port 5432 free on localhost. If another PostgreSQL uses it, stop it: tests connect to `localhost:5432` with user, password and database `taiga` (`tests/config.py`).

## First run

```bash
make setup     # .venv, requirements, git hook, PostgreSQL, migrations
make db-reset  # optional: admin user (admin/123123), Scrum/Kanban templates, sample data
make dev       # API on http://localhost:8000/api/v1/, Django admin on /admin/
```

`make dev` copies `settings/config.py.dev.example` to `settings/config.py` when the file does not exist (it is in `.gitignore`) and starts `manage.py runserver` with `DJANGO_SETTINGS_MODULE=settings.config`. Edit `settings/config.py` for local overrides.

Without `settings/config.py`, `manage.py` uses `settings.common`. It connects to the same database (`127.0.0.1`, `taiga/taiga`), so `regenerate.sh` and `manage.py` commands work with the compose database.

## Daily run

```bash
make dev          # starts PostgreSQL if needed, then the API
make check-fast   # lint + unit tests, about 30 seconds with a warm test database
make check        # full gate, same as CI (about 15 minutes)
```

Run one test file or one test:

```bash
.venv/bin/pytest tests/unit/test_slug.py
.venv/bin/pytest tests/integration/test_userstories.py -k bulk --reuse-db
```

`--reuse-db` keeps the `test_taiga` database between runs and saves the migration time. Django still applies new migrations to it. Trap: transactional tests (for example in `tests/unit`) flush all tables when they end, which also deletes rows created by data migrations, such as the system users that `taiga/hooks` needs. If a test fails with `DoesNotExist` on data you did not create, run it again with `--create-db`. `make test` and `make check` always use `--create-db`.

## Async work (Celery) and events

By default `settings/common.py` sets `CELERY_ENABLED = False` (tasks run inline) and uses the PostgreSQL events backend (`taiga.events.backends.postgresql`). You do not need RabbitMQ for normal development.

To try Celery: start RabbitMQ with `docker compose --profile async up -d`, set `CELERY_ENABLED = True` and `CELERY_BROKER_URL = "amqp://taiga:taiga@localhost:5672/taiga"` in `settings/config.py`, then run `make worker`.

The real-time service (taiga-events) and the web front end are in other repositories.

## Reset

- `make db-reset` drops and recreates the `taiga` database and loads sample data. It destroys local data.
- `make db-down` stops the containers. The data stays in the `postgres-data` volume.
- `docker compose down -v` also deletes the volume (all local data and the test database).

## Debug

- Logs: `settings/common.py` `LOGGING` sends the `taiga` logger (level DEBUG) to the console, so `make dev` prints them. Request errors go to `django.request`.
- Breakpoints: add `breakpoint()` in the code. With `make dev` the prompt opens in the same terminal. With pytest, add `-s`, or use `.venv/bin/pytest --pdb` to stop at the first failure.
- Data: `.venv/bin/python manage.py shell` or `.venv/bin/python manage.py dbshell`, or `docker compose exec postgres psql -U taiga taiga`.
- Emails: the dev settings print emails to the console (Django console backend from `settings/common.py`).

## Common problems

- `pg_config executable not found` during `make setup`: install libpq and put its `bin` folder on `PATH` (on macOS `/opt/homebrew/opt/libpq/bin`).
- `failed to find libmagic`: install libmagic.
- `password authentication failed for user "taiga"`: another PostgreSQL answers on port 5432. Stop it or change its port.
- Very slow tests: the compose PostgreSQL runs with `fsync=off`. If you use another PostgreSQL, the first test run (database creation and migrations) can take minutes.
- `pyenv: version '3.10' is not installed`: install Python 3.10 (`pyenv install 3.10` or `uv python install 3.10`), or install uv and run `make setup` again.
