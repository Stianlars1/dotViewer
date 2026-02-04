#!/usr/bin/env bash
# Script: dotviewer-refresh.sh
# Description: Reset Quick Look cache, clean build, rebuild, install app, and launch.
# Usage: ./scripts/dotviewer-refresh.sh [options]

set -euo pipefail
IFS=$'\n\t'

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly APP_DIR="$ROOT_DIR/dotViewer"
readonly BUILD_DIR="$APP_DIR/build"
readonly PROJECT_PATH="$APP_DIR/dotViewer.xcodeproj"
readonly SCHEME="dotViewer"
readonly APP_NAME="dotViewer.app"

RESET_QL=true
CLEAN_BUILD=true
INSTALL_APP=true
OPEN_APP=true
STREAM_LOGS=false
RUN_XCODEGEN=true
CONFIGURATION="Debug"
DEFAULT_INSTALL_DIR=""
INSTALL_SUCCESS=false
RUN_LSREGISTER=true
ALLOW_PROVISIONING_UPDATES=true
ENABLE_PLUGINS=true

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --no-reset         Skip Quick Look cache reset
  --no-clean         Skip build directory cleanup
  --no-install       Skip copying app to /Applications
  --no-open          Skip launching the app
  --no-lsregister    Skip LaunchServices registration for the installed app
  --no-xcodegen      Skip running xcodegen generate before building
  --no-provisioning-updates  Build without -allowProvisioningUpdates
  --no-enable-plugins Skip enabling Quick Look plugins via pluginkit
  --logs             Stream dotViewer logs after launch (blocks)
  --config <name>    Build configuration (Debug or Release)
  --install-dir <dir> Install destination (default: \$INSTALL_DIR, ~/Applications, or /Applications)
  -h, --help         Show this help message
EOF
}

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
}

error() {
  log "ERROR: $*"
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || error "Required command not found: $1"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-reset)
        RESET_QL=false
        shift
        ;;
      --no-clean)
        CLEAN_BUILD=false
        shift
        ;;
      --no-install)
        INSTALL_APP=false
        shift
        ;;
      --no-open)
        OPEN_APP=false
        shift
        ;;
      --no-lsregister)
        RUN_LSREGISTER=false
        shift
        ;;
      --no-xcodegen)
        RUN_XCODEGEN=false
        shift
        ;;
      --no-provisioning-updates)
        ALLOW_PROVISIONING_UPDATES=false
        shift
        ;;
      --no-enable-plugins)
        ENABLE_PLUGINS=false
        shift
        ;;
      --logs)
        STREAM_LOGS=true
        shift
        ;;
      --config)
        CONFIGURATION="${2:-}"
        [[ -n "$CONFIGURATION" ]] || error "--config requires a value"
        shift 2
        ;;
      --install-dir)
        DEFAULT_INSTALL_DIR="${2:-}"
        [[ -n "$DEFAULT_INSTALL_DIR" ]] || error "--install-dir requires a value"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        error "Unknown argument: $1"
        ;;
    esac
  done
}

resolve_install_dir() {
  # Priority:
  # 1) explicit arg/env (DEFAULT_INSTALL_DIR)
  # 2) INSTALL_DIR env
  # 3) /Applications (preferred for app extension discovery)
  # 4) ~/Applications (fallback)
  if [[ -n "${DEFAULT_INSTALL_DIR:-}" ]]; then
    echo "$DEFAULT_INSTALL_DIR"
    return
  fi
  if [[ -n "${INSTALL_DIR:-}" ]]; then
    echo "$INSTALL_DIR"
    return
  fi
  if [[ -w "/Applications" ]]; then
    echo "/Applications"
    return
  fi
  if [[ -d "$HOME/Applications" ]]; then
    echo "$HOME/Applications"
    return
  fi
  echo "/Applications"
}

run_xcodegen() {
  log "Running xcodegen generate"
  require_cmd xcodegen
  (cd "$APP_DIR" && xcodegen generate)
}

reset_quicklook() {
  log "Resetting Quick Look caches"
  qlmanage -r
  qlmanage -r cache
}

clean_build() {
  if [[ -d "$BUILD_DIR" ]]; then
    log "Removing build directory: $BUILD_DIR"
    rm -rf "$BUILD_DIR"
  fi
}

build_app() {
  if [[ "$RUN_XCODEGEN" == true ]]; then
    run_xcodegen
  fi
  log "Building ($CONFIGURATION)..."
  local provisioning_flag=()
  if [[ "$ALLOW_PROVISIONING_UPDATES" == true ]]; then
    provisioning_flag+=("-allowProvisioningUpdates")
  fi
  if command -v xcsift >/dev/null 2>&1; then
    xcodebuild "${provisioning_flag[@]}" -project "$PROJECT_PATH" -scheme "$SCHEME" -configuration "$CONFIGURATION" -derivedDataPath "$BUILD_DIR" build 2>&1 | xcsift
  else
    xcodebuild "${provisioning_flag[@]}" -project "$PROJECT_PATH" -scheme "$SCHEME" -configuration "$CONFIGURATION" -derivedDataPath "$BUILD_DIR" build
  fi
}

install_app() {
  local install_dir
  install_dir="$(resolve_install_dir)"
  local built_app="$BUILD_DIR/Build/Products/$CONFIGURATION/$APP_NAME"
  [[ -d "$built_app" ]] || error "Built app not found: $built_app"

  if [[ ! -d "$install_dir" ]]; then
    log "Creating install dir: $install_dir"
    mkdir -p "$install_dir"
  fi

  if [[ -w "$install_dir" ]]; then
    local dest_app="$install_dir/$APP_NAME"
    if [[ -d "$dest_app" ]]; then
      local ts
      ts="$(date +%Y%m%d-%H%M%S)"
      log "Moving existing app aside: $dest_app -> $dest_app.bak-$ts"
      mv "$dest_app" "$dest_app.bak-$ts"
    fi

    log "Installing to $dest_app"
    ditto "$built_app" "$dest_app"
    INSTALL_SUCCESS=true

    if [[ "$RUN_LSREGISTER" == true ]]; then
      local lsregister="/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister"
      if [[ -x "$lsregister" ]]; then
        log "Registering with LaunchServices: $dest_app"
        "$lsregister" -f -R -trusted "$dest_app" >/dev/null 2>&1 || true
      fi
    fi
  else
    log "Install skipped: $install_dir is not writable."
    log "Set INSTALL_DIR=/path you can write to (e.g. $HOME/Applications)."
  fi
}

enable_plugins() {
  log "Enabling Quick Look plugins via pluginkit"
  pluginkit -e use -i com.stianlars1.dotViewer.QuickLookPreview >/dev/null 2>&1 || true
  pluginkit -e use -i com.stianlars1.dotViewer.QuickLookThumbnail >/dev/null 2>&1 || true
}

open_app() {
  local install_dir
  install_dir="$(resolve_install_dir)"
  local installed_app="$install_dir/$APP_NAME"
  local built_app="$BUILD_DIR/Build/Products/$CONFIGURATION/$APP_NAME"

  if [[ "$INSTALL_APP" == true && "$INSTALL_SUCCESS" == true && -d "$installed_app" ]]; then
    log "Launching installed app: $installed_app"
    open "$installed_app"
  elif [[ -d "$built_app" ]]; then
    log "Launching built app: $built_app"
    open "$built_app"
  else
    error "No app bundle found to open."
  fi
}

show_status() {
  log "Quick Look preview registration:"
  pluginkit -m -v -i com.stianlars1.dotViewer.QuickLookPreview || true
  log "Quick Look thumbnail registration:"
  pluginkit -m -v -i com.stianlars1.dotViewer.QuickLookThumbnail || true
}

stream_logs() {
  log "Streaming dotViewer logs (Ctrl+C to stop)"
  /usr/bin/log stream --level default --predicate 'process == "dotViewer" OR process == "QuickLookExtension" OR process == "QuickLookThumbnailExtension" OR process == "HighlightXPC"'
}

main() {
  parse_args "$@"

  require_cmd xcodebuild
  require_cmd qlmanage
  require_cmd pluginkit

  if [[ "$RESET_QL" == true ]]; then
    reset_quicklook
  fi

  if [[ "$CLEAN_BUILD" == true ]]; then
    clean_build
  fi

  build_app

  if [[ "$INSTALL_APP" == true ]]; then
    install_app
  fi

  if [[ "$ENABLE_PLUGINS" == true ]]; then
    enable_plugins
  fi

  # After install/enabling, force Quick Look to reload providers.
  if [[ "$RESET_QL" == true && "$INSTALL_APP" == true && "$INSTALL_SUCCESS" == true ]]; then
    reset_quicklook
  fi

  if [[ "$OPEN_APP" == true ]]; then
    open_app
  fi

  show_status

  if [[ "$STREAM_LOGS" == true ]]; then
    stream_logs
  fi
}

main "$@"
