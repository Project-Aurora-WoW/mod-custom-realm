# 🛡️ Notes & limitations (EN)

> **RU:** см. [Notes.md](Notes.md).

---

## 1. Known deployment issues

- **Pinned versions.** The core builds on commit `1459af95…`; `mod-ale` must match that
  revision (ALE uses core internals). The guides default to commit `84b85cc5…` — verify
  against the release.
- **CharDB/WorldDB mismatch in `0002`.** Migration `0002_campaign_progress.sql` creates
  `realm_campaign_progress`. Campaign scripts read it via `CharDBQuery` (characters).
  Recommended: apply `0002` to `acore_characters` (variant A), or replace
  `CharDBQuery`→`WorldDBQuery` in `Campaign1/2/3.lua` (variant B). See `docs/deployment.md` step 8.
- **Spawn coordinates** in Dragonblight and Zul'Drak are approximate — verify on a test realm.
- **Title ID 48 (TitleMask)** is empirical; must be verified in the client.
- **`patch-x.mpq`** holds client changes; do NOT include `Map.dbc` (only in `patch-Z.mpq`).
  Title/mount need a separate DBC patch (`docs/client-patch.md`).
- **AIO debugging.** If `AIO_CODE_OBFUSCATE = true` in `AIO.lua`, client code is minified —
  traceback line numbers break. Set `false` when debugging.

## 2. Security

- Do NOT use the `root` password in production; create a dedicated DB user.
- Lua DB queries are not parameterized in ALE — escape strings with the `REG.escape`
  helper (introduced for names/text).

## 3. Running CI

- Releases need `contents: write` for `GITHUB_TOKEN` (see `CI-Build.md`).
- The Windows build downloads Boost (~200 MB) and MySQL (~50 MB); if those sites are
  unreachable in your region, use a VPN or mirrors.

## 4. Compatibility

- Client strictly **3.3.5a (build 12340)**.
- Max level is **80** (realm concept). Addons and level-255 references from dWrath are
  not applied.