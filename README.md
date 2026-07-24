# Derived OpenCode image

This project builds on the official OpenCode container and adds:

- Rust, Cargo, Clippy, Rustfmt, and native build tools
- Git and GitHub CLI (`gh`)
- runtime `PUID`/`PGID` mapping
- a non-root `opencode` account
- `opencode serve --hostname 0.0.0.0 --port 4096` by default
- Docker Compose's built-in init process via `init: true`

## Configure

Create a `.env` file:

```dotenv
PUID=1000
PGID=1000
OPENCODE_SERVER_PASSWORD=replace-with-a-long-random-password
```

On Linux, obtain the account IDs with:

```sh
id -u
id -g
```

On macOS, the defaults normally work with Docker Desktop, or you can use the
IDs returned by those commands.

## Start

```sh
mkdir -p workspace config
docker compose up --build -d
```

OpenCode listens on `127.0.0.1:4096` on the Docker host. The container listens
on all interfaces so another service on the Compose network can reach it.

## Verify

```sh
docker compose exec opencode id
docker compose exec opencode rustc --version
docker compose exec opencode cargo --version
docker compose exec opencode gh --version
```

The first command should show the configured numeric IDs associated with the
`opencode` account.

## Persistent paths

- `./workspace` — repositories and working files
- `./config` — OpenCode configuration
- `opencode-data` — OpenCode application data
- `opencode-cache` — caches
- `cargo-data` — Cargo state
- `gh-data` — GitHub CLI authentication

The entrypoint starts as root only long enough to update the `opencode`
account and prepare its home directories. It then uses `su-exec` to launch
OpenCode with the configured non-root UID and GID.

Do not add a Compose `user:` setting: the entrypoint needs its initial root
privileges to perform the runtime ID mapping.

## Komodo

Keep these files together in a Git repository and configure the repository
root as the build context. Komodo's builder will then have access to both the
Dockerfile and `docker-entrypoint.sh`.
