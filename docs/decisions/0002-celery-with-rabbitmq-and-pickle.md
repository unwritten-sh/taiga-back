# 0002. Celery with RabbitMQ and the pickle serializer, optional in development

Date: 2026-11-01

Status: inferred from the code, to be confirmed by the team.

## Context

Some work is too slow for a request: project exports and imports, bulk notification emails, outgoing webhooks, telemetry, flushing expired tokens. A self-hosted install must still be simple to run.

## Decision

As visible in the code:

- Async work runs on Celery (`taiga/celery.py`). The Docker settings (`docker/config.py`) use RabbitMQ as the broker and enable Celery by default (`CELERY_ENABLED=True`). The same image runs the worker with beat (`docker/async_entrypoint.sh`).
- Celery is optional. `settings/common.py` sets `CELERY_ENABLED = False`, and the code checks the flag before it calls `.delay()` (for example `taiga/projects/api.py`, `taiga/importers/*/api.py`), so tasks run inline without a broker. Tests run with Celery disabled and eager tasks (`tests/config.py`, `tests/conftest.py`).
- Tasks use the pickle serializer (`CELERY_ACCEPT_CONTENT = ['pickle']`, `CELERY_TASK_SERIALIZER = "pickle"` in both settings files), so task arguments can be Django model instances and other Python objects.
- Real-time events use a pluggable backend (`EVENTS_PUSH_BACKEND`): PostgreSQL by default, RabbitMQ in Docker.

## Consequences

- Development and tests need only PostgreSQL.
- Every new async task must work in both modes: add the `CELERY_ENABLED` check like the existing callers.
- Pickle means that anyone who can publish to the broker can run code in the worker. The broker must never be reachable from untrusted networks. Moving to JSON would need all task arguments to be serialisable, which is a larger change.
- Do not change the serializer or the broker settings without a new decision record.
