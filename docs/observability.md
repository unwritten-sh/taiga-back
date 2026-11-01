# Observability

This page lists what the code shows about logs, errors and health. Where production logs, dashboards and alerts live is not in this repository. Open questions are marked below.

## Logs

- Configuration: `LOGGING` in `settings/common.py`. All logs go to the console (stdout/stderr) with the format `LEVEL:time: message`.
- Loggers: `taiga` (all application code, level DEBUG), `django.request` (level ERROR, console and email to `ADMINS`), `taiga.export_import` (level ERROR, console and email), `django.server` (runserver access log). The `django` logger is silenced (null handler).
- Error emails: the `mail_admins` handler uses `taiga.base.utils.logs.CustomAdminEmailHandler` and only sends when `DEBUG` is false. `ADMINS` in `settings/common.py` is a placeholder (`example@example.com`).
- Docker: gunicorn runs with `--log-level=info --access-logfile -`, so access logs go to stdout. Celery runs with `-l INFO`. `PYTHONUNBUFFERED=1` is set in the Dockerfile.

> [!WARNING]
> **Needs a human.** Where are the production logs of the API and the Celery workers collected, and how does a developer get access?
> Why it matters and how to do it: https://docs.unwritten.sh/harness/guides/observability/
<!-- uw-harness:todo observability -->

## Errors

- `sentry-sdk` is in `requirements.txt`, but no code in `taiga/`, `settings/` or `docker/` calls `sentry_sdk.init`. A remote branch is named `cha/20251121/migrate-from-raven-to-sentry-sdk`.
- API errors return through `taiga.base.api.views.api_server_error` (`handler500` in `taiga/urls.py`).

> [!WARNING]
> **Needs a human.** Is Sentry (or another error tracker) configured for production outside this repository, for example in a private settings file? Where do the team see errors?
> Why it matters and how to do it: https://docs.unwritten.sh/harness/guides/observability/
<!-- uw-harness:todo observability -->

## Metrics and telemetry

- No metrics library or `/metrics` endpoint in the code.
- Product telemetry: `taiga/telemetry/tasks.py` sends a daily anonymous event to Rudder when `ENABLE_TELEMETRY` is true (beat entry in `taiga/celery.py`). It is usage data, not monitoring.
- Outgoing webhooks keep a log per delivery in the `webhooks_webhooklog` table.

> [!WARNING]
> **Needs a human.** Which dashboards and metrics does the team use for production (request rate, latency, queue length, worker health)?
> Why it matters and how to do it: https://docs.unwritten.sh/harness/guides/observability/
<!-- uw-harness:todo observability -->

## How to tell that something is wrong

- There is no dedicated health endpoint. `GET /api/v1/` returns the list of API routes without authentication and reads no application data (`APIRoot` in `taiga/base/routers.py`), so it shows that gunicorn and Django answer but not that the database works. An authenticated call such as `GET /api/v1/users/me` also checks the database.
- Signs in the logs: `ERROR` lines from `django.request`, `taiga.export_import` errors, Celery task failures in the worker output.

> [!WARNING]
> **Needs a human.** What is the signal that production is broken (health check URL, key metric, alert rule) and which channel receives alerts?
> Why it matters and how to do it: https://docs.unwritten.sh/harness/guides/observability/
<!-- uw-harness:todo observability -->
