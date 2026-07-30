<!--
SPDX-FileCopyrightText: 2026 Deutsche Telekom AG

SPDX-License-Identifier: CC0-1.0
-->

# Contributing

## Keeping the README in sync

`README.md` is generated from [`README.md.gotmpl`](README.md.gotmpl) and `values.yaml`
using [helm-docs](https://github.com/norwoodj/helm-docs). Never edit `README.md` directly —
edit the template or the values file and regenerate:

```bash
helm-docs
```

CI enforces that `README.md` is up to date (see `.github/workflows/validate.yml`) and
fails the build otherwise.

## Git hooks (lefthook)

This repository ships a [lefthook](https://lefthook.dev/) configuration
([`lefthook.yml`](lefthook.yml)). Opt-in by running `lefthook install`.
The hooks are optional local tooling; CI remains the authoritative gate.
A hook whose tool is missing fails with a hint; install the tool or skip that commit with `LEFTHOOK=0 git commit ...` or `git commit --no-verify`.

The hooks rely on the following tools. Find installation instructions here:

- [lefthook](https://lefthook.dev/#how-to-install-lefthook)
- [helm-docs](https://github.com/norwoodj/helm-docs#installation)
- [helm](https://helm.sh/docs/intro/install/)
- [gitleaks](https://github.com/gitleaks/gitleaks#installing)
- [committed](https://github.com/crate-ci/committed#install)
- [reuse](https://github.com/fsfe/reuse-tool#install)

## Releases

Releases are automatic. Every push to a release branch is validated, and if the commits
since the last release warrant one, a version is published without any manual trigger.
Merging a pull request is therefore a release decision.

### Branch roles

| Branch | Publishes | Example version |
| --- | --- | --- |
| `main` | Stable versions | `9.13.1` |
| `next` | Release candidates, on the `next` channel | `10.0.0-rc.1` |

`main` is the default branch and produces stable releases. `next` is the release-candidate
channel: it exists whenever a change requires validation in a customer-facing environment
before it is promoted to stable. Once that version is promoted into `main`, `next` is
deleted, and it is recreated from `main` when a future prerelease channel is needed. Only
these two branches publish releases, pull request builds validate but never publish.

Versions are calculated from [Conventional Commits](https://www.conventionalcommits.org/).
Every accepted type releases something, so a docs-only or dependency-only merge still
publishes a patch version.

### Which branch a change goes to

A change that belongs in both channels goes into `main` first and is forward-ported to
`next` afterwards. This ensures that stable always receives all features and fixes and
nothing stays only on `next`. A change that applies to only one channel stays on that
channel.

Merge `main` into `next` after a stable release rather than letting the branches drift. This
will publish a release candidate containing the fix.

### Keeping `next` in sync

Every `main` into `next` merge conflicts on `Chart.yaml`, because both branches carry a
`chore(release)` commit rewriting the same `version:` line:

```
<<<<<<< HEAD
version: 10.0.0-rc.1
=======
version: 9.13.2
>>>>>>> main
```

Always resolve in favour of `next`. The prerelease version is the newer one, and the next
release on that branch rewrites the line anyway. This conflict is expected on every sync.

Promotion goes the other way, merging `next` into `main`. `main` requires linear history, so
a merge commit is rejected. Sync `main` into `next` first, which leaves `next` strictly
ahead and makes the promotion a fast-forward.

### Chart publication

Publication to the OCI repo happens on tag, rather than branch, so a re-run cannot pick up
later commits. Exact version tags such as `9.13.1` and `10.0.0-rc.1` are immutable, and a
published chart version is never overwritten.

### Jumper version bumps

The default Jumper image tag in `values.yaml` is maintained by hand. There is no Renovate or
Dependabot in this repository. Bump it in a normal pull request; because the change ships a
different gateway runtime, choose the commit type that reflects its impact rather than
defaulting to `chore`.
