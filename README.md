# uw-harness case study: evidence

This branch holds the raw files of one uw-harness case study. The docs page quotes them:
https://docs.unwritten.sh/harness/case-studies/

- `meta.json`, `meta.txt`: upstream commit, uw-harness commit, agent version, times.
- `detect-*.json`: the score before the run, after the run, and with the final uw-harness commit.
- `run.log`, `prove.log`: the output of `uw-harness run` and `uw-harness prove`.
- `control/`: the control arm (the same task, the same agent, on the base commit, without the harness).
- `baseline-*`, `*-manual.*`: measurements made after the run, with the script that made them.
- `transcripts/`: the agent transcripts of the run and the pilot task.
- `attempts/`: earlier attempts that failed, kept for the record.
- `summary.json`: the numbers, collected by scripts/case-study/collect.mjs.

The harness itself is on the branches `uw-harness/20261101-1408` and `uw-harness/prove-20261101-1551` of this repository.
