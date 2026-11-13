# 🤖 CI builds & releases (GitHub Actions)

> **EN.** Automatic build and release publishing via GitHub Actions.
> **RU:** см. [CI-Build.md](CI-Build.md).

---

## 1. Overview

The repo has two workflows in `.github/workflows/`:

| Workflow | When it runs | What it does |
|----------|--------------|--------------|
| `core-build.yml` | push/PR on `main`/`master` | Master-build emulation: Linux (clang) + Windows (MSVC), core + all vendored modules from `modules/` + mod-ale, server dry-run |
| `windows-release.yml` | manual (workflow_dispatch, with tag) or push tag `v*` | Windows build + release artifact (.zip) + publish to GitHub Releases |

Common tree preparation is in the composite action `.github/actions/setup-tree`.

---

## 2. Components

```
.github/
├── workflows/
│   ├── core-build.yml          # CI build (Linux+Windows), no release
│   └── windows-release.yml     # Windows build + publish Release
└── actions/
    └── setup-tree/             # composite action: checkout core + modules + mod-ale + lua
```

---

## 3. core-build.yml — master-build emulation

Flow:

1. `setup-tree` clones `azerothcore/azerothcore-wotlk@master`, embeds
   all vendored modules from `modules/` (`echo-*`, `mod-ale`, external `mod-*`), copies `lua_scripts/`.
2. **Linux job** (`ubuntu-26.04`, clang-20 + ccache):
   - CMake `SCRIPTS=static`, `MODULES=static`, `-Werror`, Release;
   - build → install → dry-run `authserver`/`worldserver` → check `Errors.log` → unit tests.
3. **Windows job** (`windows-latest`, MSVC):
   - ccache, Boost 1.87 + MySQL 8.4 cache;
   - build via `./acore.sh compiler build`.

---

## 4. windows-release.yml — release artifact

Triggering:

- **Manual:** Actions tab → "windows-release" → **Run workflow** (optionally set a tag).
- **By tag:** `git tag v1.0.0 && git push origin v1.0.0`.

What happens:

1. Windows build of the core (as in core-build), install into `env/dist`.
2. `env/dist` (bin + etc + data + lua_scripts) packed into `azerothcore-<tag>.zip`.
3. A **draft** Release is published via `softprops/action-gh-release@v2` with the tag and the attached archive.

> Creating a Release requires `contents: write` permission for `GITHUB_TOKEN`:
> Settings → Actions → General → **Workflow permissions** → **Read and write**.

---

## 5. Triggers / run policy

- `core-build.yml`: on every push/PR to `main`/`master` — an expensive build. To save
  runners, narrow it to `push` (master) + PR with the `run-build` label.
- `windows-release.yml`: runs **only manually or by tag** — we avoid building release
  artifacts on every commit.

---

## 6. Rerun

- Failed run → Actions → the run → **Re-run jobs**.
- To re-publish a production release from the same sources, re-run
  `windows-release.yml` with the same tag — the Release is recreated (draft).