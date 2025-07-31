### TL;DR

- **No, `.codexignore` does not exist (yet).** It’s only a community-filed feature request on the Codex GitHub repo.
- **`AGENTS.md` (or `Agent.md` / `AGENTS.md` in any folder, plus an optional `~/.codex/AGENTS.md`) is the \*only\* first-class, officially-supported way to give Codex written instructions today.**
- You *can* write “please ignore `foo/` and `*.env`” in an `AGENTS.md`, and Codex will usually comply, but that’s a social contract, not an enforced sandbox rule.
- Until an ignore mechanism ships, handle secrets the same way you would for human reviewers: keep them un-committed or injected through the “Secrets / Env Vars” panel when you start a task.

------

## 1. What *is* supported today?

| Purpose                                                      | File / Setting                                               | Status            | Notes                                                        |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ----------------- | ------------------------------------------------------------ |
| Give natural-language rules, build/test commands, code-style guides, “focus on these folders”, etc. | **`AGENTS.md`** (hierarchical: `~/.codex/AGENTS.md` ➜ repo-root ➜ sub-folder) | **✅ Stable**      | Codex merges all visible files from top to bottom ([OpenAI](https://openai.com/index/introducing-codex/), [GitHub](https://github.com/openai/codex)) |
| Personal / global defaults (model, sandbox flags, etc.) when using the **Codex CLI** | `~/.codex/config.toml`                                       | ✅ Stable          | No ignore-list yet, but you can pre-set approvals, sand- boxing mode, etc. |
| Per-task environment setup                                   | “Setup script” field in ChatGPT UI / `--setup` flag in CLI   | ✅ Stable          | Ideal place to download deps or remove artefacts **after** clone but **before** sandbox locks network. |
| Ignore files from AI context                                 | *(none)*                                                     | **❌ Not shipped** | `.codexignore` and pattern-based ignores are only open GitHub issues ([GitHub](https://github.com/openai/codex/issues/205), [GitHub](https://github.com/openai/codex/issues/1397)) |

------

## 2. The state of “`.codexignore`”

- **April 17 2025** – first request (#205) proposes a `.codexignore` modelled on `.gitignore` ([GitHub](https://github.com/openai/codex/issues/205)).
- **June 27 2025** – a follow-up request (#1397) suggests ignore patterns at *global*, *project*, and *file* scopes ([GitHub](https://github.com/openai/codex/issues/1397)).
- **Current status (31 July 2025):** both issues are still open; no changelog entry or doc update mentions an ignore file. Codex will happily read any file that is present in the cloned repo and not blocked by the sandbox policy.

------

## 3. Practical work-arounds while we wait

### 3 A. Keep sensitive files out of the repo

- **.gitignore > .codexignore for now.** If the file is never committed, Codex never sees it.
- Use dotenv templates (`.env.template`) instead of committed secrets.
- Store large binary assets (designs, models) in a separate storage bucket or Git LFS and fetch them lazily from your setup script.

### 3 B. Scope what Codex *should* look at in `AGENTS.md`

```md
# AGENTS.md  (root)

## Repository scope
Only the following paths are in scope for the agent:
- `src/`
- `tests/`
- `package.json`, `tsconfig.json`

The agent **must not read or edit**:
- `scripts/deploy/**`
- Anything matching `*.env`, `*.pem`, `*.key`
```

Codex will treat these instructions the same way a human reviewer would; if you later ask it to modify an ignored file it will refuse or ask for confirmation.

### 3 C. Shrink the clone

When launching a task you can point Codex at a *sub-directory* or a shallow clone/temporary branch that contains only the code you want reviewed.

### 3 D. Use sandbox flags (CLI only)

`codex --sandbox workspace-read-only --cd src`
 limits read/write to `src/`, though this is coarse-grained and not available in the ChatGPT UI yet.

------

## 4. Recommended pattern going forward

1. **Document rules up front** in `AGENTS.md`; include a short “ignore list” section.
2. **Keep secrets and generated artefacts untracked.** Rely on env-vars or setup scripts.
3. **Monitor the GitHub issues (#205, #1397) and the Codex Changelog** for `.codexignore` updates; once the feature lands you can migrate the ignore section out of `AGENTS.md` into a real ignore file without changing your workflow.

That’s all you have to work with *today*—but it’s usually enough to keep Codex on the safe path until first-class ignore support arrives.