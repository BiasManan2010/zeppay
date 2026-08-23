# Publish SahAI to its own repository

SahAI lives in this branch as a **standalone repo tree** (not under a `sahai/` subfolder).
Use it to update https://github.com/BiasManan2010/sahai

## One-time push (from your machine)

```bash
# Clone zeppay (or use your existing clone)
git fetch origin sahai-repo-main
git push https://github.com/BiasManan2010/sahai.git FETCH_HEAD:main
```

Or clone the export branch directly:

```bash
git clone --single-branch -b sahai-repo-main https://github.com/BiasManan2010/zeppay.git sahai-standalone
cd sahai-standalone
git remote set-url origin https://github.com/BiasManan2010/sahai.git
git push -u origin sahai-repo-main:main
```

## Local development (standalone clone)

```bash
git clone https://github.com/BiasManan2010/sahai.git
cd sahai
cp .env.example .env
# See README.md and SETUP_RUNBOOK.md
```

## Why this branch exists

The Cloud Agent can push to `zeppay` but not to `sahai` (integration permissions).
This branch is the handoff artifact until `sahai` grants the agent write access.
