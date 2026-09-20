#!/bin/bash
#
# ChromeDocker.sh
# Spins up a throwaway Chrome inside a Docker container (Kasm image) and
# opens it in your Mac's browser via noVNC. Nothing touches your Mac's own
# Chrome, Keychain, or profile. Stop it and every trace is gone.
#
# Usage:
#   bash ~/Desktop/ChromeDocker.sh          # start (or reattach if already running)
#   bash ~/Desktop/ChromeDocker.sh stop     # kill the container (everything inside is destroyed)
#   bash ~/Desktop/ChromeDocker.sh restart  # stop + fresh start
#   bash ~/Desktop/ChromeDocker.sh status   # is it running?
#   bash ~/Desktop/ChromeDocker.sh down     # stop container AND shut down Colima VM
#
# Login in the browser tab:  user  kasm_user   password  (see VNC_PW below)

set -u

NAME="chrome"
IMAGE="kasmweb/chrome:1.16.0"
PORT="6901"
VNC_PW="password"
SHM="512m"
URL="https://localhost:$PORT"

# Timezone the container (and therefore Chrome's Intl/Date APIs) reports.
# Asia/Tokyo is UTC+9 with no daylight-saving, so it's a stable "9 hours ahead".
# Change this to any tz database name (e.g. America/New_York) to move the clock.
TZ_NAME="Asia/Tokyo"

# Chrome flags passed into the container (Kasm reads $APP_ARGS).
# GPU is disabled because the Colima VM has no real GPU (--disable-gpu forces
# software rendering).
CHROME_FLAGS="--start-maximized --no-sandbox --disable-gpu --disable-software-rasterizer --disable-dev-shm-usage --disable-features=RendererCodeIntegrity"

# Colima VM sizing (only used if Colima isn't already running)
COLIMA_CPU=4
COLIMA_MEM=6
# VM backend. On Intel Macs the default Virtualization.framework ("vz") backend
# makes Chrome's V8 JIT SIGSEGV ("Aw, Snap!") on real pages. QEMU fully emulates
# the CPU and fixes it (needs: brew install qemu). See README > Troubleshooting.
COLIMA_VMTYPE=qemu

ACTION="${1:-start}"

# ---------- helpers ----------
docker_ok() { docker info >/dev/null 2>&1; }

ensure_docker() {
  if docker_ok; then return 0; fi

  if command -v colima >/dev/null 2>&1; then
    echo "==> Docker daemon not running. Starting Colima (cpu=$COLIMA_CPU mem=${COLIMA_MEM}g vm=$COLIMA_VMTYPE)..."
    colima start --cpu "$COLIMA_CPU" --memory "$COLIMA_MEM" --vm-type "$COLIMA_VMTYPE" || {
      echo "    Colima failed to start."
      [ "$COLIMA_VMTYPE" = "qemu" ] && echo "    (QEMU backend needs: brew install qemu)"
      exit 1; }
  elif [ -d "/Applications/Docker.app" ]; then
    echo "==> Docker daemon not running. Launching Docker Desktop..."
    open -a Docker
    echo -n "    waiting for Docker"
    for _ in $(seq 1 60); do
      docker_ok && break
      echo -n "."; sleep 2
    done
    echo
  else
    echo "No Docker daemon found. Install Colima (brew install colima docker) or Docker Desktop."
    exit 1
  fi

  docker_ok || { echo "Docker still not reachable. Giving up."; exit 1; }
}

is_running() { docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "$NAME"; }

wait_for_ui() {
  echo -n "==> Waiting for Chrome UI on $URL"
  for _ in $(seq 1 45); do
    if curl -sk --max-time 2 -o /dev/null "$URL"; then echo; return 0; fi
    echo -n "."; sleep 2
  done
  echo
  echo "    UI not responding yet; try opening $URL manually in a moment."
  return 1
}

start() {
  ensure_docker
  if is_running; then
    echo "==> '$NAME' is already running. Reopening $URL"
    open "$URL"
    exit 0
  fi
  # Clean up a dead container with the same name, if any
  docker rm -f "$NAME" >/dev/null 2>&1

  echo "==> Pulling $IMAGE (skips if cached)..."
  docker pull "$IMAGE" || { echo "    Pull failed."; exit 1; }

  echo "==> Starting throwaway Chrome container..."
  # --security-opt seccomp=unconfined: Chrome's renderer SIGSEGVs ("Aw, Snap!")
  # under Colima's virtualized Intel CPU because its seccomp syscall filter
  # misbehaves in the VM. Unconfining seccomp is the real fix for the crashes.
  docker run --rm -d --name "$NAME" \
    --shm-size="$SHM" \
    --security-opt seccomp=unconfined \
    -p "127.0.0.1:$PORT:6901" \
    -e VNC_PW="$VNC_PW" \
    -e TZ="$TZ_NAME" \
    -e APP_ARGS="$CHROME_FLAGS" \
    "$IMAGE" >/dev/null || { echo "    docker run failed."; exit 1; }

  wait_for_ui
  open "$URL"
  echo
  echo "================================================================"
  echo "  Throwaway Chrome is up:  $URL"
  echo "  Login:  kasm_user  /  $VNC_PW"
  echo "  (Self-signed cert: click through the browser warning.)"
  echo
  echo "  Stop & destroy:  bash $0 stop"
  echo "================================================================"
}

stop() {
  if is_running; then
    echo "==> Stopping '$NAME' (container and everything inside are destroyed)..."
    docker stop "$NAME" >/dev/null && echo "    gone."
  else
    echo "==> '$NAME' is not running."
    docker rm -f "$NAME" >/dev/null 2>&1
  fi
}

status() {
  if ! docker_ok; then echo "Docker daemon: NOT running"; exit 1; fi
  echo "Docker daemon: running"
  if is_running; then
    echo "Container '$NAME': RUNNING  ->  $URL"
  else
    echo "Container '$NAME': not running"
  fi
}

case "$ACTION" in
  start)   start ;;
  stop)    stop ;;
  restart) stop; start ;;
  status)  status ;;
  down)
    stop
    if command -v colima >/dev/null 2>&1; then
      echo "==> Stopping Colima VM..."
      colima stop
    fi
    ;;
  *)
    echo "Usage: $0 [start|stop|restart|status|down]"
    exit 1 ;;
esac
