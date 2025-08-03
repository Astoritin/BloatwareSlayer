#!/system/bin/sh
SKIPUNZIP=1

CONFIG_DIR="/data/adb/bloatwareslayer"

CONFIG_FILE="$CONFIG_DIR/settings.conf"
TARGET_LIST="$CONFIG_DIR/target.conf"
LOG_DIR="$CONFIG_DIR/logs"

MOD_PROP="${TMPDIR}/module.prop"
MOD_NAME="$(grep_prop name "$MOD_PROP")"
MOD_VER="$(grep_prop version "$MOD_PROP") ($(grep_prop versionCode "$MOD_PROP"))"
MOD_INTRO="Remove bloatwares systemlessly."

unzip -o "$ZIPFILE" "wanderer.sh" -d "$TMPDIR" >&2
if [ ! -f "$TMPDIR/wanderer.sh" ]; then
    ui_print "! Failed to extract wanderer.sh!"
    abort "! This zip may be corrupted!"
fi

. "$TMPDIR/wanderer.sh"

eco "Setting up $MOD_NAME"
eco "Version: $MOD_VER"
eco_init "$LOG_DIR"
show_system_info
install_env_check
eco "Install from $ROOT_SOL app"
eco "Root: $ROOT_SOL_DETAIL"
extract "customize.sh" "$TMPDIR"
extract "module.prop"
extract "wanderer.sh"
extract "post-fs-data.sh"
extract "service.sh"
extract "action.sh"
extract "uninstall.sh"
[ ! -f "$CONFIG_FILE" ] && extract "settings.conf" "$CONFIG_DIR"
[ ! -f "$TARGET_LIST" ] && extract "target.conf" "$CONFIG_DIR"
DESCRIPTION="[⚡Check $TARGET_LIST carefully before reboot! 🔮Root: ${ROOT_SOL_DETAIL}] $MOD_INTRO"
update_config_var "description" "$MODPATH/module.prop" "$DESCRIPTION"
eco "Set permission"
set_perm_recursive "$MODPATH" 0 0 0755 0644
eco "Welcome to use $MOD_NAME!"