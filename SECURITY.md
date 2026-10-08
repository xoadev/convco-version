# Security Policy

## Supported versions

Only the latest release of convco-version receives security fixes.

## Reporting a vulnerability

Please **do not open a public issue** for a security problem. Report it privately through
[GitHub's private vulnerability reporting](https://github.com/xoadev/convco-version/security/advisories/new)
instead.

Include what you found, how to reproduce it and the impact you expect. You will get an answer as soon as possible,
and credit in the advisory once a fix is released, if you want it.

## How the action protects you

- convco is checked against the sha256 of its release asset before it runs, whether it was downloaded or restored
  from the cache.
- The actions it depends on are pinned by commit SHA.
- Its workflows are checked by [zizmor](https://docs.zizmor.sh/) on every pull request.
