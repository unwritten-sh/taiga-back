# Product

Taiga is an open-source project management tool for agile teams that use Scrum or Kanban. Teams plan and track work with backlogs, sprints, Kanban boards, epics, user stories, tasks, issues and a wiki. This repository is the API server: it stores all project data, checks permissions, sends notifications and webhooks, and imports projects from other tools. Self-hosters run it with Docker. The public SaaS is tree.taiga.io, and the Taiga team uses it to manage Taiga itself (README badge).

## Users

- Project members (developers, product owners, scrum masters). They use the Taiga web front end, which calls this API.
- Project administrators. They configure roles, memberships, statuses, points, swimlanes, due dates and custom attributes.
- Instance administrators who self-host Taiga. They use the Django admin (`/admin/`), management commands and the Docker image.
- External systems: Git hosting services that send webhooks (GitHub, GitLab, Bitbucket, Gogs) and services that receive Taiga outgoing webhooks.
- Third-party API clients, authenticated with application tokens (`taiga/external_apps`).

## Main use cases

All API routes are registered in `taiga/routers.py` under `/api/v1/`.

| Use case | What it does | Entry points |
|---|---|---|
| Authentication and accounts | Login, registration, JWT and refresh tokens, password recovery, invitation acceptance, profile | `/api/v1/auth` (`taiga/auth/api.py` `AuthViewSet`), `/api/v1/users` (`taiga/users/api.py`), `taiga/auth/tokens.py`, `taiga/auth/token_denylist/` |
| Projects and memberships | Create projects from Scrum or Kanban templates, invite members, manage roles, statuses, points, swimlanes | `/api/v1/projects` (`taiga/projects/api.py` `ProjectViewSet`), `/api/v1/memberships`, `/api/v1/invitations`, `/api/v1/project-templates`, `/api/v1/swimlanes` |
| Backlog, sprints and Kanban | User stories, milestones, tasks, epics, tags, ordering in backlog and board | `taiga/projects/userstories/`, `milestones/`, `tasks/`, `epics/`, `tagging/` |
| Issues, wiki and attachments | Issues with types, priorities and severities, wiki pages in Markdown, file attachments | `taiga/projects/issues/`, `wiki/`, `attachments/`, `taiga/mdrender/` |
| Notifications, history and timeline | Change history of each object, email and web notifications to watchers, activity feeds | `taiga/projects/history/`, `taiga/projects/notifications/` (`/api/v1/web-notifications`, `/api/v1/notify-policies`), `taiga/timeline/` |
| Real-time events and webhooks | Push change events to taiga-events, send signed POSTs to project webhook URLs | `taiga/events/`, `taiga/webhooks/` (`/api/v1/webhooks`) |
| Git hosting integrations | Change the status of stories, tasks and issues from commit messages and issue events | `taiga/hooks/github/`, `gitlab/`, `bitbucket/`, `gogs/` |
| Import and export | Import from Jira, Trello, Asana, GitHub, Pivotal; export and import Taiga dumps | `/api/v1/importers/<tool>` (`taiga/importers/`), `/api/v1/importer`, `/api/v1/exporter` (`taiga/export_import/`) |
| Search and stats | Search inside a project, project and system statistics | `/api/v1/search` (`taiga/searches/`), `taiga/stats/` |
| Telemetry | Daily anonymous usage data to Rudder when `ENABLE_TELEMETRY` is true | `taiga/telemetry/tasks.py`, beat entry in `taiga/celery.py` |
| Local sample data | Reset the database, load the admin user and templates, generate sample projects | `regenerate.sh` (`make db-reset`), `taiga/projects/management/commands/sample_data.py` |

## Glossary

| Term | Meaning in the code |
|---|---|
| US, user story | Unit of backlog work (`taiga/projects/userstories`, table `userstories_userstory`) |
| Milestone | A sprint in Scrum projects (`taiga/projects/milestones`) |
| Epic | Group of related user stories (`taiga/projects/epics`, `epics_relateduserstory`) |
| Swimlane | Horizontal lane on a Kanban board (`projects_swimlane`, `/api/v1/swimlanes`) |
| Points, role points | Story-point values; a user story has one estimate per role (`projects_points`, `userstories_rolepoints`) |
| Membership | Link between a user and a project with a role; also used for pending invitations |
| Fan, watcher, vote, like | Ways a user follows or supports a project or item (`taiga/projects/votes`, `likes`, `notifications`) |
| OCC | Optimistic concurrency control: edits send a `version` and fail on conflict (`taiga/projects/occ`) |
| Ref, reference | Per-project sequential number shown as `#123` (`taiga/projects/references`) |
| Timeline | Activity feed for users and projects (`taiga/timeline`) |
| Taiga events | Separate real-time service that receives pushes from `taiga/events` backends (other repository) |
| Contribs | Optional plugins (Slack, GitHub and GitLab login, protected storage) from `requirements-contribs.txt` |
| Application token | Token for third-party apps (`taiga/external_apps`) |
| INSTANCE_TYPE | Installation type sent with telemetry: `SRC` in `settings/common.py`, `D` in `docker/config.py` |
| Kaleidos INC | Company that owns the copyright (license headers, `CONTRIBUTING.md`) |
