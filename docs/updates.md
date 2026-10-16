# Update pipeline

```
 app repo push ──repository_dispatch(app-updated, {input})──┐
 weekly cron ───────────────────────────────────────────────┤
 manual (workflow_dispatch) ────────────────────────────────┤
                                                            v
                         .github/workflows/update.yml (ARM runner)
                           1. nix flake update [input]
                           2. nix build .#toplevel   <- gate: fails = nothing ships
                           3. push closure to Cachix
                           4. commit flake.lock to main
                                                            │
             Pi (hourly, when online) ──────────────────────┘
               nixos-upgrade.service: nixos-rebuild boot --flake github:…#nixauto
               downloads from the cache and installs as the NEXT boot generation
               becomes active at the next ignition / power cycle
```

## Pieces

| Piece | File | Notes |
|-------|------|-------|
| Update gate | `.github/workflows/update.yml` | The only thing that should move `flake.lock` forward on `main`. |
| PR/push CI | `.github/workflows/ci.yml` | Pushes to the cache only for `main`. |
| Device side | `modules/auto-update.nix` | `nixauto.autoUpdate.{enable,flake,dates}` |
| Cache | Cachix. Set the repo variable `CACHIX_CACHE_NAME` and the secret `CACHIX_AUTH_TOKEN`. | The device needs the cache's public key in `nix.settings` (see `modules/base.nix`). |

## Rules

- **Never commit a `flake.lock` that CI hasn't built.** The device trusts `main`.
- If you protect `main` with branch protection, let the `github-actions[bot]` push
  `flake.lock`, or change the workflow to open a PR and auto-merge it.
- **Rollback:** pick an older generation in the boot menu, or run
  `sudo nixos-rebuild boot --rollback` over SSH.

## Known gaps / future work

- **Metered LTE:** the device checks hourly. A no-op check fetches only small git
  metadata, but a real update downloads the changed closure. Consider adding a
  data-budget or Wi-Fi-only policy (`nmcli` metered flag) before using it widely.
- **No cache yet:** until Cachix is configured, a device that finds an update has to
  build it locally, which is slow on a Pi. Configure the cache before you rely on
  auto-updates.
- **Push vs pull:** if near-instant updates are ever needed, add a push trigger
  (an MQTT or webhook agent) that starts `nixos-upgrade.service`. The CI gate stays
  the same.
