# Development Commands

## install / ins

Sets up project and workspace from scratch.

- Creates workspace config for submodules
- Clones selected submodules only
- Sets up branch tracking (prompts for branch name)
- Installs dependencies in selected submodules
- **Project must define install logic in its cli file**

```bash
D ins
D ins ----recursive
```

## update / ude

Pulls changes and syncs project state intelligently.

- Pulls git changes
- Checks version changes (cached)
- Full sync only when version changed: pulls kit image, installs deps, updates submodules
- **Project must define update logic in its cli file**

```bash
D ude
```

## status / sta

Shows project status: version, workspace, git, updates.

```bash
D sta
```

## develop / dev

Starts development environment with workspace filtering.

- Only starts services matching selected workspace modules
- Uses docker-compose.override.yaml
- Graceful shutdown traps

```bash
D dev           # Interactive
D dev -d        # Detached
D dev --build   # Rebuild first
```

## test / tes

Runs test suites.

- `health`: Endpoint check (cached success)
- `e2e`: Playwright tests
- `all`: Complete suite

```bash
D tes health
D tes e2e
D tes all
```

## build / bpa

Builds images in parallel.

```bash
D bpa
D bpa --no-cache
```

## execute / exe

Executes commands in specific services.

- Running service: `docker compose exec`
- Stopped service: `docker compose run --rm --no-deps`
- In container: direct execution

```bash
D exe myservice npm install
D exe myservice --no-message ls
```

## run vs execute

**run**: Executes in main service (repo name)
**execute**: Requires service name

```bash
D run npm test        # In main service
D exe otherservice ls # In specific service
```

## shell / she

Opens bash in main service.

```bash
D she
```

## pull / pul

Pulls and merges changes.

- Pulls from origin
- Merges main branch
- Updates selected submodules

```bash
D pul
D pul --ignore-submodule-pulling
```

## push / pus

Auto-commit with AI and create PR.

- Blocks commits to main
- AI commit messages (needs OPENAI_API_KEY)
- Creates/updates GitHub PR
- **Requires GitHub CLI for PR management**

```bash
D pus
```

## safely / saf

Runs commands in kit container for guaranteed environment.

- All dependencies pre-installed
- Predictable execution
- Avoids missing local dependencies

```bash
D saf pul         # Safe pull
D saf "complex command"
```
