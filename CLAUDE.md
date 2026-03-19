# CLAUDE.md

This file provides guidance for AI assistants (Claude and others) working in this repository.

## Repository Overview

**Try_create** is currently a nascent repository with minimal content. It was initialized with a single placeholder file (`Sample`) and is being set up for future development.

- **Owner:** nie0244-mi
- **Remote:** `http://local_proxy@127.0.0.1:44625/git/nie0244-mi/Try_create`

## Current Repository Structure

```
Try_create/
├── CLAUDE.md   # This file
└── Sample      # Placeholder file (1 byte)
```

## Branch Strategy

| Branch | Purpose |
|--------|---------|
| `master` | Stable production branch |
| `Develop` | Integration branch for ongoing work |
| `claude/*` | AI-assisted feature/documentation branches |

- All new work should branch off `Develop` unless targeting a hotfix on `master`.
- Branch names for AI-assisted tasks follow the pattern `claude/<short-description>-<session-id>`.
- Never push directly to `master` without a pull request.

## Git Conventions

- **Commit messages:** Use imperative mood, present tense (e.g., `Add feature X`, not `Added feature X`).
- **Push command:** Always use `git push -u origin <branch-name>`.
- **Merge strategy:** Prefer merge commits on `master`; rebase is acceptable on feature branches before merging.

## Development Setup

> No dependencies or build tools have been configured yet. Update this section as the project grows.

When adding a new language/stack, document here:
1. Prerequisites and installation steps
2. How to install dependencies
3. How to run the project locally
4. How to run tests

## Testing

> No test framework has been configured yet. Update this section when tests are added.

When tests are added, document:
- The test framework and runner command
- How to run a single test
- Coverage requirements

## Code Style & Conventions

> No linter or formatter is configured yet. Update this section when tooling is added.

General conventions to follow until explicit tooling is set up:
- Keep files small and focused on a single responsibility.
- Prefer explicit over implicit code.
- Add comments only where logic is non-obvious.
- Do not commit secrets, credentials, or `.env` files.

## AI Assistant Guidelines

- Read existing files before modifying them.
- Do not create files unless they are necessary for the task.
- Keep changes minimal and focused — avoid refactoring unrelated code.
- All development work should be committed and pushed to the designated `claude/*` branch.
- Always verify the current branch before committing: `git branch`.
- Do not force-push to `master` or `Develop`.
