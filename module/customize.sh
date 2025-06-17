#!/system/bin/sh
SKIPUNZIP=1

CONFIG_DIR="/data/adb/bloatwareslayer"

CONFIG_FILE="$CONFIG_DIR/settings.conf"
LOG_DIR="$CONFIG_DIR/logs"

VERIFY_DIR="$TMPDIR/.aa_verify"

MOD_NAME="$(grep_prop name "$TMPDIR/module.prop")"
MOD_VER="$(grep_prop version "$TMPDIR/module.prop") ($(grep_prop versionCode "$TMPDIR/module.prop"))"
MOD_INTRO="Remove bloatware in systemless way."

[ ! -d "$VERIFY_DIR" ] && mkdir -p "$VERIFY_DIR"

echo "- Extract aa-util.sh"
unzip -o "$ZIPFILE" 'aa-util.sh' -d "$TMPDIR" >&2
if [ ! -f "$TMPDIR/aa-util.sh" ]; then
    echo "! Failed to extract aa-util.sh!"
    abort "! This zip may be corrupted!"
fi

. "$TMPDIR/aa-util.sh"

logowl "Setting up $MOD_NAME"
logowl "Version: $MOD_VER"
logowl_init "$LOG_DIR"
install_env_check
show_system_info
logowl "Install from $ROOT_SOL app"
logowl "Essential check"
extract "$ZIPFILE" 'aa-util.sh' "$VERIFY_DIR"
extract "$ZIPFILE" 'customize.sh' "$VERIFY_DIR"
logowl "Extract module files"
extract "$ZIPFILE" 'aa-util.sh' "$MODPATH"
extract "$ZIPFILE" 'module.prop' "$MODPATH"
extract "$ZIPFILE" 'post-fs-data.sh' "$MODPATH"
extract "$ZIPFILE" 'service.sh' "$MODPATH"
extract "$ZIPFILE" 'action.sh' "$MODPATH"
extract "$ZIPFILE" 'uninstall.sh' "$MODPATH"
if [ ! -f "$CONFIG_DIR/target.conf" ] || [ ! -f "$CONFIG_FILE" ]; then
    if [ ! -f "$CONFIG_DIR/target.conf" ]; then
        logowl "Extract target list"
        extract "$ZIPFILE" 'target.conf' "$CONFIG_DIR"
    fi
    if [ ! -f "$CONFIG_FILE" ]; then
        logowl "Extract config file"
        extract "$ZIPFILE" 'settings.conf' "$CONFIG_DIR"
    fi
fi
[ "$VERIFY_DIR" != "/" ] && rm -rf "$VERIFY_DIR"
logowl "Set permission"
set_permission_recursive "$MODPATH" 0 0 0755 0644
logowl "Welcome to use $MOD_NAME!"
DESCRIPTION="[✨Please check items inside target.txt carefully before reboot. ⚙️Root: $ROOT_SOL_DETAIL] $MOD_INTRO"
update_config_var "description" "$DESCRIPTION" "$MODPATH/module.prop"
