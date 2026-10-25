# org-todoist

Emacs package: bidirectional incremental sync between one org file (`org-todoist-file`, default `todoist.org`) and Todoist, using the unified API v1 (`https://api.todoist.com/api/v1/sync`). Local changes win on conflict. Requires Emacs 30.1+, org 9.7.19, `s`, `ts`, `dash`, `transient`. `curl` is used for async requests when present (else `url-retrieve`).

## Layout
- `org-todoist.el` — the whole package (~3600 lines)
- `test.el` — ERT tests (partly stale; none cover push/parse-response)
- `README.org`, `sample.org`
- `data/*.json` — SOPS-encrypted API dumps. Never commit decrypted copies.
- `.github/workflows/check.yml` — package-lint only (ERT job disabled)

## Data model
Every object is a headline with a property drawer.
- `TODOIST_TYPE`: PROJECT / SECTION / TASK / USER / USER_HEADLINE / METADATA / IGNORE
- `tid`: remote id. `temp_id`: client UUID for objects not yet created remotely.
- Each project has a synthetic "Default Section" (`tid=default`) that is never sent to the API.
- Mappings: TODO keyword <-> `checked`; SCHEDULED <-> `due`; DEADLINE <-> `deadline`; tags <-> labels; priority A-D <-> p1-p4; `EFFORT` <-> duration; LOGBOOK "Note taken on" items <-> comments; `ARCHIVE` tag <-> archived; `CANCELED` -> delete.

## Sync flow
`org-todoist-sync` -> parse buffer to AST -> diff against snapshot (`~/.cache/org-todoist/SYNC-BUFFER`) in `org-todoist--push` -> commands batched (75) -> POST with `SYNC-TOKEN` (`*` = full sync) -> `org-todoist--parse-response` merges into AST -> `update-file` rewrites the buffer.

Debug: `~/.cache/org-todoist/last-request.json`, `last-response.json`, `M-x org-todoist-diagnose`, `org-todoist-reset` (full resync).

## Gotchas
- `json-read` gives symbol keys; command alists use string keys. Mixing them silently fails (`assoc-default`, `eq`).
- Request body encoding is hand-rolled.
- The buffer is fully rewritten after each sync. It is made read-only while a sync is in flight (`org-todoist--freeze-buffer`); if it changed anyway the old contents are saved to `pre-sync-backup.org` in the storage dir.
- A sync lock (`org-todoist--sync-lock`) prevents overlapping syncs; failures land in `org-todoist--sync-err`.
- Persist order after a response is file -> snapshot -> token.
- `item_move` takes exactly one of parent_id/section_id/project_id: see `org-todoist--item-move-args`. Never send a null section_id.
- Recurring tasks completed in Emacs: `org-todoist--item-close-hook` sends `item_close`; the sync then only pushes the new due date. Don't also emit `item_close` from the diff (it would advance the task twice).
- Lookups in `org-todoist--push` use an id index (`org-todoist--build-id-index`); `org-todoist--get-by-id` is still an O(n) walk, used when parsing responses.

## Conventions
- **Do NOT commit.** Never run `git commit` (or push); leave changes in the working tree for the user to review and commit.
- **Do NOT add Claude as a git collaborator**: no `Co-Authored-By` trailers, no "Generated with Claude" lines in commits or PRs.
- Anything Claude-related (`.claude/`, `CLAUDE.md`, `CLAUDE.local.md`) stays in `.gitignore`.
- Commit messages: short, lowercase, imperative (e.g. "fix parens issue on item_add").
- `make compile` (warnings are errors), `make test` (override `DEPS=` for the location of dash.el/s.el/ts.el). All tests in `test.el` should pass.
- Run checkdoc and package-lint before committing. Do not track `.elc` files.
- Prefer a unit test with a stubbed transport for any sync change.
