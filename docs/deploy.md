# Deploy

This page describes what the repository shows about deployment. The pipeline that builds and publishes images and deploys tree.taiga.io is not in this repository. Open questions are marked below.

## Environments

The repository names two kinds of installation: the public SaaS at tree.taiga.io (README) and self-hosted installs that use the Docker image or `settings/config.py.prod.example`. The `INSTANCE_TYPE` setting tells them apart in telemetry (`D` in `docker/config.py`, `SRC` in `settings/common.py`).

> [!WARNING]
> **Needs a human.** Which environments exist (staging, production, on-premise customers) and what runs where?
> Why it matters and how to do it: https://docs.unwritten.sh/harness/guides/deploy/
<!-- uw-harness:todo deploy-explicit -->

## How a release is built

- Version: `CHANGELOG.md` gets a new section in a commit named `chore: bump to X.Y.Z version`.
- Image: `docker/Dockerfile` builds one image from `python:3.11-slim`. It installs `requirements.txt` and `requirements-contribs.txt` (plugins from GitHub), copies `docker/config.py` to `settings/config.py`, runs `compilemessages` and `collectstatic`, and sets `DJANGO_SETTINGS_MODULE=settings.config`.
- Build it locally from the repository root: `docker build -f docker/Dockerfile .` (the `.dockerignore` file removes tests, docs and dev files from the build context).
- No workflow in `.github/workflows` builds or pushes images.

> [!WARNING]
> **Needs a human.** Who builds and pushes the taiga-back image, to which registry, with which tags, and from which repository or pipeline?
> Why it matters and how to do it: https://docs.unwritten.sh/harness/guides/deploy/
<!-- uw-harness:todo deploy-explicit -->

## How it is deployed

The same image runs two containers:

- API: entrypoint `docker/entrypoint.sh`. It runs `python manage.py migrate`, loads `initial_project_templates`, then starts gunicorn on port 8000 with 3 workers.
- Async worker: `docker/async_entrypoint.sh`. It starts `celery -A taiga.celery worker -B --concurrency 4`.

Configuration comes from environment variables read by `docker/config.py`. The full list is in `.env.example`. The containers also need PostgreSQL, RabbitMQ (two vhosts or hosts: `TAIGA_ASYNC_RABBITMQ_HOST`, `TAIGA_EVENTS_RABBITMQ_HOST`) and the separate taiga-events and front-end services. No compose or Kubernetes file for production is in this repository.

Migrations run automatically each time the API container starts.

> [!WARNING]
> **Needs a human.** How is tree.taiga.io deployed (tool, trigger, who can deploy), and where are the production compose or orchestration files?
> Why it matters and how to do it: https://docs.unwritten.sh/harness/guides/deploy/
<!-- uw-harness:todo deploy-explicit -->

## How to roll back

Because the entrypoint applies migrations on start, going back to an older image does not undo schema changes. A rollback needs a written procedure.

> [!WARNING]
> **Needs a human.** How is a release rolled back, and how are migrations handled during a rollback (backup and restore, reverse migrations, forward fix only)?
> Why it matters and how to do it: https://docs.unwritten.sh/harness/guides/deploy/
<!-- uw-harness:todo deploy-explicit -->

## What is checked after a deploy

The code has no health endpoint. See [observability.md](observability.md).

> [!WARNING]
> **Needs a human.** What does the team check after a deploy (smoke test URL, logs, error rate), and who is told?
> Why it matters and how to do it: https://docs.unwritten.sh/harness/guides/deploy/
<!-- uw-harness:todo deploy-explicit -->
