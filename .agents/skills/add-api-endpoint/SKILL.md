---
name: add-api-endpoint
description: Use when you add a new REST resource or a new action to an existing viewset under /api/v1/ in taiga-back.
---

# Add an API endpoint

Reference example: `taiga/userstorage/` (small, complete) and its test `tests/integration/resources_permissions/test_storage_resources.py`.

1. Model and migration (skip for an action on an existing model). Add the model to the app's `models.py`, then:
   ```bash
   DJANGO_SETTINGS_MODULE=tests.config .venv/bin/python manage.py makemigrations <app_label>
   make migrations-check
   ```
   A new app must be added to `INSTALLED_APPS` in `settings/common.py`.

2. Serializer and validator. Output goes in `serializers.py` (Taiga serializers, see the app neighbours), input checks in `validators.py` (`validator_class` on the viewset).

3. Permissions in `permissions.py`: subclass `taiga.base.api.permissions.TaigaResourcePermission` and set one entry per action (`retrieve_perms`, `create_perms`, `update_perms`, `destroy_perms`, `list_perms`, or `enough_perms` / `global_perms`). Project resources use `HasProjectPerm("view_us")` and `IsProjectAdmin()` from `taiga.permissions.permissions`; look at `taiga/projects/userstories/permissions.py`.

4. Viewset in `api.py`: subclass a class from `taiga.base.api` (`ModelCrudViewSet`, `ModelListViewSet`, `GenericViewSet`). Set `model`, `serializer_class`, `validator_class`, `permission_classes`, `filter_backends`. Extra actions use `@list_route` / `@detail_route` from `taiga.base.decorators`. Raise errors from `taiga.base.exceptions` (`exc.BadRequest`, `exc.NotFound`, `exc.PermissionDenied`).

5. Register the route in `taiga/routers.py`:
   ```python
   from taiga.<app>.api import <Name>ViewSet
   router.register(r"<prefix>", <Name>ViewSet, base_name="<prefix>")
   ```
   URL names follow `<base_name>-list` and `<base_name>-detail`.

6. Tests:
   - Behaviour: `tests/integration/test_<app>.py`, with `client.login(user)` and `reverse("<base_name>-list")`.
   - Permission matrix: `tests/integration/resources_permissions/test_<app>_resources.py` with `helper_test_http_method(client, "get", url, None, users)` and the expected status list for anonymous, non-member, member, admin.
   - Factories: add one to `tests/factories.py` if the model is new.
   ```bash
   .venv/bin/pytest tests/integration/resources_permissions/test_<app>_resources.py --reuse-db
   ```

7. If the resource changes project data that others watch, check whether it needs history (`taiga/projects/history`), timeline (`taiga/timeline`), webhooks (`taiga/webhooks/signal_handlers.py`) or events (`taiga/events`). Follow how user stories do it.

8. Run `make check-fast`, then the integration files you touched (or `make check`). Commit with `feat: ...`.
