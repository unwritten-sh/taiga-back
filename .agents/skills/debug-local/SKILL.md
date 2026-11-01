---
name: debug-local
description: Use when a test fails, an API call returns an unexpected status, or behaviour differs from what you expect, and you need to reproduce and inspect it on your machine.
---

# Debug taiga-back locally

1. Check the environment first:
   ```bash
   docker compose ps                 # postgres must be "healthy"
   make db-up                        # starts it if needed
   .venv/bin/python --version        # must be 3.10.x
   ```
   `password authentication failed for user "taiga"` means another PostgreSQL answers on port 5432 (see `docs/local-dev.md`, Common problems).

2. Reproduce with the smallest test:
   ```bash
   .venv/bin/pytest tests/unit/test_slug.py -k <name> --reuse-db -x -vv --tb=long
   ```
   For an API bug, write a test in `tests/integration` with the `client` fixture from `tests/fixtures.py` and `tests/factories.py`; it is faster and more repeatable than clicking in a front end.

3. Stop in the code:
   ```bash
   .venv/bin/pytest <test> --reuse-db --pdb      # debugger at the failure
   .venv/bin/pytest <test> --reuse-db -s         # needed when you add breakpoint()
   ```

4. Reproduce against a running API when needed:
   ```bash
   make db-reset   # DESTROYS local data; loads admin/123123 and sample projects
   make dev        # http://localhost:8000/api/v1/
   curl -s -X POST http://localhost:8000/api/v1/auth -H 'Content-Type: application/json' \
        -d '{"type": "normal", "username": "admin", "password": "123123"}'
   ```
   Use the returned `auth_token` as `Authorization: Bearer <token>`. Logs of the `taiga` logger print in the `make dev` terminal (`LOGGING` in `settings/common.py`).

5. Inspect data:
   ```bash
   .venv/bin/python manage.py shell
   docker compose exec postgres psql -U taiga taiga        # dev database
   docker compose exec postgres psql -U taiga test_taiga   # test database kept by --reuse-db
   ```

6. Known traps:
   - Tests run with `CELERY_ENABLED = False` and eager tasks; a bug that only happens in the worker needs `make worker` and RabbitMQ (`docker compose --profile async up -d`).
   - Many resource-permission tests call `disconnect_signals()`; history, timeline and notifications are then not created.
   - Throttling is disabled in `tests/config.py` but active in `make dev`.
   - `--reuse-db` keeps a database that transactional tests have flushed: rows from data migrations (for example the `is_system` users that `taiga/hooks` looks up) are gone. A `DoesNotExist` on data the test did not create usually means this: run again with `--create-db`.

7. When fixed, follow the `implement-change` skill from step 5 (migrations, `make check-fast`, log entry).
