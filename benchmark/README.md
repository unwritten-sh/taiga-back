# uw-harness benchmark: raw data

Method and results: https://docs.unwritten.sh/harness/case-studies/benchmark/

- `tasks.json`: the tasks (upstream commit, kind, task text, hidden tests, `revert_patch` for manual reverts).
- `candidates*.json`, `valid.json`, `validate*.log`: task selection and validation.
- `patches/`: the manual reverts.
- `runs/<task>-<arm>/`: per run, `result.json` (the agent's answer and wall time), `diff.patch`, `transcript.jsonl` (the full agent transcript) and `grade.json`. Arms: `harness`, `control`, `harness-haiku`, `control-haiku`. `*-control.v1/` are the first control runs, invalid because the agent saw the harness skills (round 1, change 10). `grade-v1.json` and `grade-v2.json` are earlier grades replaced by changes 8 to 10.
- `runs/<sha>-reference.json`: the full gate on the reverted tree, during validation.
- `review/`: the blind review of the two diffs of each task.
- `onboard/<arm>/`: onboarding from a fresh clone (round 2, part C). `*.v1/` are runs replaced by round 2, change 2.
