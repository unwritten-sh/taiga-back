# Task entry point for taiga-back. Run `make` or `make help` to list targets.
# All Python commands run from the .venv virtualenv created by `make setup`.

SHELL := /bin/bash
.DEFAULT_GOAL := help

VENV := .venv
PY := $(VENV)/bin/python
PYTEST := $(VENV)/bin/pytest
FLAKE8 := $(VENV)/bin/flake8

# Same coverage command as the CI workflow before the harness.
COVERAGE_OMIT := *tests*,*commands*,*migrations*,*admin*,*.jinja,*dashboard*,*settings*,*wsgi*,*questions*,*documents*

# flake8 rules enforced by the gates: syntax errors and invalid comparisons only.
# The full rule set from setup.cfg (`make lint-full`) reports existing violations
# in old code, see docs/harness/log.md.
LINT_GATE_SELECT := E9,F63,F7

.PHONY: help setup venv deps hooks db-up db-down db-migrate db-reset dev worker \
        test test-unit lint lint-full migrations-check check-fast check

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-17s\033[0m %s\n", $$1, $$2}'

setup: deps hooks db-up db-migrate ## Install dependencies, install the git hook, start PostgreSQL and apply migrations

$(PY):
	@if command -v uv >/dev/null 2>&1; then \
		uv venv --seed --python 3.10 $(VENV); \
	elif command -v python3.10 >/dev/null 2>&1; then \
		python3.10 -m venv $(VENV); \
	else \
		python3 -m venv $(VENV); \
	fi
	@$(PY) -c 'import sys; v = sys.version_info[:2]; print("WARNING: .venv uses Python %d.%d, the project pins 3.10" % v) if v != (3, 10) else None'

venv: $(PY) ## Create the .venv virtualenv with Python 3.10 (uses uv when available)

deps: $(PY) ## Install requirements.txt and requirements-devel.txt into .venv (like scripts/install)
	$(PY) -m pip install --upgrade pip wheel setuptools
	$(PY) -m pip install -r requirements.txt -r requirements-devel.txt

hooks: ## Install the pre-push git hook (.githooks/pre-push) that runs `make check-fast`
	@git config core.hooksPath .githooks || \
		echo "WARNING: could not install the git hook (no .git or read-only git metadata)"

db-up: ## Start PostgreSQL from compose.yaml (skipped when CI is set: CI has its own service)
	@if [ -n "$$CI" ]; then \
		echo "CI is set: using the PostgreSQL service of the CI job"; \
	else \
		docker compose up -d --wait postgres; \
	fi

db-down: ## Stop the compose services (data stays in the postgres-data volume)
	docker compose --profile async down

db-migrate: ## Apply migrations to the local development database (skipped in CI)
	@if [ -n "$$CI" ]; then \
		echo "CI is set: tests create their own database, skipping"; \
	else \
		$(PY) manage.py migrate --noinput; \
	fi

db-reset: db-up ## DESTROYS local data: recreate the database with admin/123123 and sample data (regenerate.sh)
	PGPASSWORD=taiga PATH="$(CURDIR)/$(VENV)/bin:$$PATH" ./regenerate.sh -y < /dev/null

dev: db-up ## Run the API on http://localhost:8000 with settings/config.py (copied from the dev example if missing)
	@test -f settings/config.py || cp settings/config.py.dev.example settings/config.py
	DJANGO_SETTINGS_MODULE=settings.config $(PY) manage.py runserver

worker: ## Run a Celery worker with beat (needs CELERY_ENABLED=True in settings/config.py and `docker compose --profile async up -d`)
	DJANGO_SETTINGS_MODULE=settings.config $(VENV)/bin/celery -A taiga.celery worker -B -l INFO

# The whole suite needs a fresh test database (--create-db): transactional tests
# flush all tables on teardown, which removes rows created by data migrations
# (for example the system users of taiga/hooks). A reused database breaks the
# tests/integration/test_hooks_* files. Unit tests do not need that data, so the
# fast gate keeps --reuse-db.
test: db-up ## Run the whole test suite (one test: .venv/bin/pytest tests/unit/test_slug.py -k <name>)
	$(PYTEST) --create-db

test-unit: db-up ## Run the unit tests only (tests/unit)
	$(PYTEST) tests/unit --reuse-db -rA --tb=short

lint: ## Run flake8 with the rules enforced by the gates (syntax errors, invalid comparisons)
	$(FLAKE8) --select=$(LINT_GATE_SELECT) .

lint-full: ## Run flake8 with the full setup.cfg rules (fails today on existing code, see docs/harness/log.md)
	$(FLAKE8) .

migrations-check: ## Fail when a model change has no migration
	DJANGO_SETTINGS_MODULE=tests.config $(PY) manage.py makemigrations --check --dry-run

check-fast: lint test-unit ## Fast gate: lint plus unit tests. Run before every push

check: lint db-up migrations-check ## Full gate, what CI runs: lint, migrations check, whole suite with coverage
	$(VENV)/bin/coverage run --source=taiga --omit='$(COVERAGE_OMIT)' \
		-m pytest -v --tb=native --pythonwarnings=default --create-db
