---
name: deploy
description: Use when someone asks how to release, deploy or roll back taiga-back, or how to check production after a deploy.
---

# Deploy taiga-back

The deploy procedure is NOT in this repository. Do not invent one. `docs/deploy.md` and `docs/observability.md` hold the open questions (TODO blocks) for the team.

1. Read `docs/deploy.md`. If its TODO blocks are still open, tell the person that the procedure is unknown, quote the open question, and stop. Do not push images, run migrations on a server or connect to production.

2. What you can do safely from the repository: build the image locally to check that it builds.
   ```bash
   docker build -f docker/Dockerfile -t taiga-back:local .
   ```
   The build installs `requirements-contribs.txt` from GitHub, so it needs network access.

3. Before a release, check that the full gate passes on the release commit:
   ```bash
   make check
   ```

4. Remember the migration risk: `docker/entrypoint.sh` runs `python manage.py migrate` on every API start, so an older image does not undo a schema change. A rollback plan must come from the team (`docs/deploy.md`, "How to roll back").

5. After a deploy, the only check the code allows without credentials is `GET /api/v1/` (answers when Django is up; does not prove the database works). Ask the team for the real health signal (`docs/observability.md`).
