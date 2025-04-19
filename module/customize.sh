#!/system/bin/sh
SKIPUNZIP=1

CONFIG_DIR="/data/adb/bloatwareslayer"
CONFIG_FILE="$CONFIG_DIR/settings.conf"
LOG_DIR="$CONFIG_DIR/logs"
VERIFY_DIR="$TMPDIR/.aa_verify"
MOD_NAME="$(grep_prop name "$TMPDIR/module.prop")"
MOD_VER="$(grep_prop version "$TMPDIR/module.prop") ($(grep_prop versionCode "$TMPDIR/module.prop"))"

if [ ! -d "$VERIFY_DIR" ]; then
    mkdir -p "$VERIFY_DIR"
fi

echo "- Extract aautilities.sh"
unzip -o "$ZIPFILE" 'aautilities.sh' -d "$TMPDIR" >&2
if [ ! -f "$TMPDIR/aautilities.sh" ]; then
    echo "! Failed to extract aautilities.sh!"
    abort "! This zip may be corrupted!"
fi

. "$TMPDIR/aautilities.sh"

logowl "Setting up $MOD_NAME"
logowl "Version: $MOD_VER"
install_env_check
init_logowl "$LOG_DIR"
clean_old_logs "$LOG_DIR" 20
show_system_info
logowl "Install from $ROOT_SOL"
logowl "Essential checks"
extract "$ZIPFILE" 'aautilities.sh' "$VERIFY_DIR"
extract "$ZIPFILE" 'customize.sh' "$VERIFY_DIR"
logowl "Extract module files"
extract "$ZIPFILE" 'aautilities.sh' "$MODPATH"
extract "$ZIPFILE" 'module.prop' "$MODPATH"
extract "$ZIPFILE" 'post-fs-data.sh' "$MODPATH"
extract "$ZIPFILE" 'service.sh' "$MODPATH"
extract "$ZIPFILE" 'action.sh' "$MODPATH"
extract "$ZIPFILE" 'uninstall.sh' "$MODPATH"
logowl "Extract default config files"
if [ ! -f "$CONFIG_DIR/target.conf" ]; then
    logowl "target.conf does NOT exist"
    extract "$ZIPFILE" 'target.conf' "$CONFIG_DIR"
else
    logowl "target.conf already exists"
    logowl "target.conf will NOT be overwritten"
fi
if [ ! -f "$CONFIG_FILE" ]; then
    logowl "settings.conf does NOT exist"
    extract "$ZIPFILE" 'settings.conf' "$CONFIG_DIR"
else
    logowl "settings.conf already exists"
    logowl "settings.conf will NOT be overwritten"
fi
if [ -n "$VERIFY_DIR" ] && [ -d "$VERIFY_DIR" ] && [ "$VERIFY_DIR" != "/" ]; then
    rm -rf "$VERIFY_DIR"
fi
set_permission_recursive "$MODPATH" 0 0 0755 0644
logowl "Welcome to use $MOD_NAME!"
