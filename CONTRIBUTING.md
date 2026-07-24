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

CI enforces that `README.md` is up to date (see `.github/workflows/helm-docs.yml`) and
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
