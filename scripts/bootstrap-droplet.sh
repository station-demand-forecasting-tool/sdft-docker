#!/usr/bin/env bash
# Post-login bootstrap for a fresh DigitalOcean Docker Marketplace droplet.
# Run as root after SSH:  bash bootstrap-droplet.sh
#
# What it does:
#   1. Creates /opt/sdft-docker and downloads docker-compose.yml (GIT_REF)
#   2. Keeps an existing .env, or generates missing values when needed
#   3. Resolves SDFT_HOST_DIR via Compose (environment overrides .env)
#   4. Creates/chowns that directory to UID/GID 1000 so the UI can write
#   5. Runs docker compose up -d
#
# Doppler: doppler run -- bash bootstrap-droplet.sh
# With POSTGRES_PASSWORD, PASSWORD and SDFT_HOST_DIR injected, no .env is created.
#
# First-time DB init (empty pgdata volume) can take 30–60 minutes (~10GB).
# Watch progress (Ctrl-C detaches without stopping the container):
#   docker attach --sig-proxy=false sdft-db
# When init finishes you will see PostgreSQL ready for connections.
#
# If RStudio warns it can't write /home/rstudio/.local/share/rstudio, fix with:
#   chown -R 1000:1000 "${SDFT_HOST_DIR:-/sdft}"
#
# Env overrides (optional):
#   GIT_REF=task/TASK-1          # branch, tag, or commit for raw GitHub compose
#   INSTALL_DIR=/opt/sdft-docker
#   SDFT_HOST_DIR=/sdft
#   COMPOSE_UP=1                 # set 0 to skip compose up

set -euo pipefail

GIT_REF="${GIT_REF:-task/TASK-1}"
INSTALL_DIR="${INSTALL_DIR:-/opt/sdft-docker}"
COMPOSE_UP="${COMPOSE_UP:-1}"
REPO_RAW="https://raw.githubusercontent.com/station-demand-forecasting-tool/sdft-docker/${GIT_REF}"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run as root (DigitalOcean Ubuntu/Docker images use root SSH)." >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "docker not found; use a Docker Marketplace image." >&2
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "docker compose plugin not found." >&2
  exit 1
fi

mkdir -p "${INSTALL_DIR}"

echo "Fetching docker-compose.yml (${GIT_REF})..."
curl -fsSL -o "${INSTALL_DIR}/docker-compose.yml" \
  "${REPO_RAW}/docker-compose.yml"

if [[ -f "${INSTALL_DIR}/.env" ]]; then
  echo "Keeping existing ${INSTALL_DIR}/.env"
elif [[ -n "${POSTGRES_PASSWORD:-}" && -n "${PASSWORD:-}" && -n "${SDFT_HOST_DIR:-}" ]]; then
  echo "Using injected configuration; no .env file needed."
else
  echo "Writing missing configuration to ${INSTALL_DIR}/.env (file mode 600)..."
  umask 077
  {
    if [[ -z "${POSTGRES_PASSWORD:-}" ]]; then
      printf 'POSTGRES_PASSWORD=%s\n' "$(openssl rand -base64 24)"
    fi
    if [[ -z "${PASSWORD:-}" ]]; then
      printf 'PASSWORD=%s\n' "$(openssl rand -base64 24)"
    fi
    printf 'SDFT_HOST_DIR=%s\n' "${SDFT_HOST_DIR:-/sdft}"
  } > "${INSTALL_DIR}/.env"
  chmod 600 "${INSTALL_DIR}/.env"
fi

# Let Compose parse .env without executing it as shell code or printing secrets.
cd "${INSTALL_DIR}"
SDFT_HOST_DIR="$(docker compose config --environment |
  awk '/^SDFT_HOST_DIR=/ { sub(/^SDFT_HOST_DIR=/, ""); print }')"
if [[ -z "${SDFT_HOST_DIR}" ]]; then
  echo "SDFT_HOST_DIR must resolve to a non-empty directory." >&2
  exit 1
fi
# Relative paths are now relative to the Compose directory, as in the bind mount.
mkdir -p -- "${SDFT_HOST_DIR}"
chown -R 1000:1000 -- "${SDFT_HOST_DIR}"

if [[ "${COMPOSE_UP}" != "1" ]]; then
  echo "COMPOSE_UP=${COMPOSE_UP}: skipping docker compose up."
  exit 0
fi

echo "Starting stack (GHCR pulls + first DB init can take a long time)..."
docker compose up -d

echo
echo "Done. Check: docker compose -f ${INSTALL_DIR}/docker-compose.yml ps"
echo "UI (when ready): http://$(curl -fsS ifconfig.me 2>/dev/null || echo '<droplet-ip>'):8787"
echo "RStudio password is PASSWORD from the injected environment or ${INSTALL_DIR}/.env."
