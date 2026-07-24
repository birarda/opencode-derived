# Derived OpenCode image

This project builds on the official OpenCode container and adds:

- Rust, Cargo, Clippy, Rustfmt, and native build tools
- Node.js, npm, and npx for OpenCode plugin installers
- Git and GitHub CLI (`gh`)
- portable runtime `PUID`/`PGID` handling
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

For Unraid, the conventional values are:

```dotenv
PUID=99
PGID=100
```

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
docker compose exec opencode node --version
docker compose exec opencode npm --version
docker compose exec opencode npx --version
docker compose exec opencode gh --version
```

The first command should show the configured numeric IDs. It normally displays
the bundled `opencode` account when the IDs are available. If the IDs already
belong to an account in the image, it may display that existing name instead.
For example, Unraid's `99:100` convention usually appears as:

```text
uid=99(nobody) gid=100(users)
```

This is expected. Linux applies filesystem permissions using numeric IDs, not
their display names.

## Persistent paths

- `./workspace` — repositories and working files
- `./config` — OpenCode configuration
- `opencode-data` — OpenCode application data
- `opencode-cache` — caches
- `cargo-data` — Cargo state
- `npm-cache` — npm/npx download cache
- `gh-data` — GitHub CLI authentication

## Installing plugins with npx

Run plugin installers inside the OpenCode container:

```sh
docker compose exec opencode npx --yes <installer-package>
```

The npm download cache is writable by the configured runtime identity and is
persisted in the `npm-cache` volume. OpenCode configuration written by an
installer is retained through the `/home/opencode/.config/opencode` mount.

The image does not configure a persistent global npm prefix. Prefer `npx` for
installer commands rather than `npm install --global`.

The entrypoint starts as root only long enough to prepare the home directories
and, when safe, remap the bundled `opencode` account. If the requested IDs
already belong to another account or group, those existing records are
preserved. It then uses `su-exec` to launch OpenCode with the configured
numeric, non-root UID and GID.

OpenCode always uses `/home/opencode` as its application home, even when tools
such as `id` display another existing account name.

Do not add a Compose `user:` setting: the entrypoint needs its initial root
privileges to prepare directories and perform safe runtime ID mapping.

## Komodo

Keep these files together in a Git repository and configure the repository
root as the build context. Komodo's builder will then have access to both the
Dockerfile and `docker-entrypoint.sh`.
