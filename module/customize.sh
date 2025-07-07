#!/system/bin/sh
SKIPUNZIP=1

CONFIG_DIR="/data/adb/bloatwareslayer"

CONFIG_FILE="$CONFIG_DIR/settings.conf"
TARGET_LIST="$CONFIG_DIR/target.conf"
LOG_DIR="$CONFIG_DIR/logs"

MOD_NAME="$(grep_prop name "$TMPDIR/module.prop")"
MOD_VER="$(grep_prop version "$TMPDIR/module.prop") ($(grep_prop versionCode "$TMPDIR/module.prop"))"
MOD_INTRO="Remove bloatwares in systemless way."

unzip -o "$ZIPFILE" "aa-util.sh" -d "$TMPDIR" >&2
if [ ! -f "$TMPDIR/aa-util.sh" ]; then
    ui_print "! Failed to extract aa-util.sh!"
    abort "! This zip may be corrupted!"
fi

. "$TMPDIR/aa-util.sh"

logowl "Setting up $MOD_NAME"
logowl "Version: $MOD_VER"
logowl_init "$LOG_DIR"
show_system_info
install_env_check
logowl "Install from $ROOT_SOL app"
logowl "Root: $ROOT_SOL_DETAIL"
extract "customize.sh" "$TMPDIR"
extract "aa-util.sh"
extract "module.prop"
extract "post-fs-data.sh"
extract "service.sh"
extract "action.sh"
extract "uninstall.sh"
[ ! -f "$TARGET_LIST" ] && extract "target.conf" "$CONFIG_DIR"
[ ! -f "$CONFIG_FILE" ] && extract "settings.conf" "$CONFIG_DIR"
logowl "Set permission"
set_permission_recursive "$MODPATH" 0 0 0755 0644
logowl "Welcome to use $MOD_NAME!"
DESC_SLAYER="[💥Check $TARGET_LIST carefully before reboot!] $MOD_INTRO"
update_config_var "description" "$DESC_SLAYER" "$MODPATH/module.prop"
