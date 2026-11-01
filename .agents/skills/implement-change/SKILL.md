---
name: implement-change
description: Use when you take a task (bug fix, feature, refactor) in taiga-back and need to go from the request to a verified change ready for a pull request.
---

# Implement a change in taiga-back

1. Prepare the environment once per clone:
   ```bash
   make setup
   ```
   It creates `.venv` (Python 3.10), installs the requirements, installs the pre-push hook and starts PostgreSQL from `compose.yaml`. Details and common problems: `docs/local-dev.md`.

2. Find the code. API routes are in `taiga/routers.py`; each domain app has `api.py`, `models.py`, `services.py`, `serializers.py`, `validators.py`, `permissions.py`. Read `docs/architecture.md` for the map and `docs/product.md` for domain terms (milestone = sprint, US = user story, OCC).

3. Write the test first when you fix a bug. Unit tests live in `tests/unit`, API tests in `tests/integration`, permission matrices in `tests/integration/resources_permissions`. Build data with `tests/factories.py` (`from tests import factories as f`). Run only your test:
   ```bash
   .venv/bin/pytest tests/integration/test_userstories.py -k <name> --reuse-db
   ```
   Confirm it fails for the right reason.

4. Make the change. Rules:
   - Use `taiga.base.api` viewsets and `taiga.base.exceptions` (for example `exc.BadRequest`), not Django REST framework.
   - Wrap user-facing strings in `gettext` (`_()`); do not edit `taiga/locale/*.po` (Weblate manages them).
   - Keep the MPL license header at the top of new Python files (copy it from a neighbour file).
   - Async work must also run when `CELERY_ENABLED` is false (see `docs/decisions/0002-celery-with-rabbitmq-and-pickle.md`).

5. If you changed a model, create the migration and check it:
   ```bash
   DJANGO_SETTINGS_MODULE=tests.config .venv/bin/python manage.py makemigrations <app_label>
   make migrations-check
   ```

6. Run the fast gate. It must pass before you say the change is done:
   ```bash
   make check-fast
   ```
   For changes outside `tests/unit` coverage (API, permissions, signals), also run the related integration files, or `make check` (whole suite, slow).

7. Optional style check on the files you touched (the gate only enforces syntax rules, old code has many violations):
   ```bash
   .venv/bin/flake8 path/to/changed_file.py
   ```

8. Commit with a conventional commit message (`fix: ...`, `feat: ...`, `test: ...`), on a branch, never on `main`. Add an entry to `docs/harness/log.md` if the change is significant (date, what changed, what you learned, what is left).
