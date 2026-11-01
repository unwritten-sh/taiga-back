# How can I contribute to Taiga?

Thank you for your interest in contributing to Taiga. As a contributor, here are the guidelines we would like you to follow. For more information check out our [Taiga community page](https://community.taiga.io/t/how-can-i-contribute/159).

## Code of Conduct

Help us keep the Taiga Community open and inclusive. Please read and follow our [Code of Conduct](https://www.taiga.io/code-of-conduct).

## Code patches, enhacements

There are many different ways to contribute to Taiga's platform, from patches, to documentation and enhancements, just find the one that best fits with your skills. Check out our detailed [contribution guide](https://community.taiga.io/t/how-can-i-contribute/159#code-patches-enhacements-3).

## Issues

If you find a bug in the source code, you can help us by [submitting an issue](https://github.com/taigaio/taiga-back/issues/new/choose). Even better, you can submit a Pull Request with a fix.

## Commit Message Guidelines

Taiga follows the [conventional commits format](https://www.conventionalcommits.org/en/v1.0.0/).

## Branches and pull requests

What the git history shows (inferred, not a written rule):

- Work happens on short branches named `<author>/<YYYYMMDD>/<short-topic>`, for example `seralot/20261026/invitation-token-single-use`.
- Changes reach `main` through GitHub pull requests merged with a merge commit ("Merge pull request #NNN from ...").
- Commits use conventional commit prefixes: `fix:`, `feat:`, `test:`, `chore:`, sometimes with a scope (`fix(auth): ...`). Bug fixes often come as a `test:` commit that shows the bug, followed by the `fix:` commit.

Rules for everyone, humans and coding agents:

- Never push to `main`. Every change goes through a pull request reviewed by a human.
- CI (`.github/workflows/tests-and-coverall.yml`) must be green before merge.

> [!WARNING]
> **Needs a human.** What is the team's review rule (number of approvals, who can merge to `main`) and is merge commit the required strategy, or is squash allowed?
> Why it matters and how to do it: https://docs.unwritten.sh/harness/requirements/agreements/
<!-- uw-harness:todo agreements -->

## Definition of done (proposed)

A change is done when:

1. `make check-fast` passes locally (the pre-push hook runs it).
2. New behaviour has a test in `tests/unit` or `tests/integration`. Bug fixes have a test that failed before the fix.
3. Model changes come with their migration (`make migrations-check` passes).
4. CI is green on the pull request (it runs `make check` through `npx -y uw-harness verify`).
5. Significant changes have an entry in `docs/harness/log.md`. `CHANGELOG.md` is updated in the release commit (`chore: bump to X.Y.Z version`), not in each pull request.

See [docs/local-dev.md](docs/local-dev.md) to set up the project and [AGENTS.md](AGENTS.md) for the commands.

## Developer Certificate of Origin + License

By contributing to Kaleidos INC, You accept and agree to the following terms and conditions for Your present and future Contributions submitted to Kaleidos INC Except for the license granted herein to Kaleidos INC and recipients of software distributed by Kaleidos INC, You reserve all right, title, and interest in and to Your Contributions.

All Contributions are subject to the following DCO + License terms.

[DCO + License](DCOLICENSE)

## Translation

Access our team of translators with the link below, set up an account in Transifex and start contributing. Join us to make sure your language is covered! [Help Taiga to translate content](https://hosted.weblate.org/projects/taiga/)

Localization Bugs: Taiga use Weblate to manage the i18n files so don’t submit a pull request to those files (except -en.json). To fix a translation, just access our team of translators, set up an account in the Taiga Weblate project and start contributing.
