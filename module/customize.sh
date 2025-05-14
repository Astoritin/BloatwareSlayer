#!/system/bin/sh
SKIPUNZIP=1

CONFIG_DIR="/data/adb/bloatwareslayer"

CONFIG_FILE="$CONFIG_DIR/settings.conf"
LOG_DIR="$CONFIG_DIR/logs"

VERIFY_DIR="$TMPDIR/.aa_verify"

MOD_NAME="$(grep_prop name "$TMPDIR/module.prop")"
MOD_VER="$(grep_prop version "$TMPDIR/module.prop") ($(grep_prop versionCode "$TMPDIR/module.prop"))"
MOD_INTRO="A Magisk module to remove bloatware in systemless way."

[ ! -d "$VERIFY_DIR" ] && mkdir -p "$VERIFY_DIR"

echo "- Extract aautilities.sh"
unzip -o "$ZIPFILE" 'aautilities.sh' -d "$TMPDIR" >&2
if [ ! -f "$TMPDIR/aautilities.sh" ]; then
    echo "! Failed to extract aautilities.sh!"
    abort "! This zip may be corrupted!"
fi

. "$TMPDIR/aautilities.sh"

migrate_old_files() {

    logowl "Migrate old files"

    if [ -n "$CONFIG_DIR" ] && [ -d "$CONFIG_DIR" ] && [ "$CONFIG_DIR" != "/" ]; then

        if [ -f "$CONFIG_DIR/target.txt" ] && [ ! -f "$CONFIG_DIR/target.conf"  ]; then
            logowl "Detect old config file"
            logowl "Migrate target.txt → target.conf"
            mv "$CONFIG_DIR/target.txt" "$CONFIG_DIR/target.conf"
        elif [ -f "$CONFIG_DIR/target.txt" ] && [ -f "$CONFIG_DIR/target.conf" ]; then
            logowl "Both target.txt and target.conf exist"
            logowl "Merging contents"
            cat "$CONFIG_DIR/target.txt" >> "$CONFIG_DIR/target.conf"
            sort -u "$CONFIG_DIR/target.txt" >> "$CONFIG_DIR/target.conf"
            logowl "Merged, target.txt has been removed"
            rm -f "$CONFIG_DIR/target.txt"
        fi

        if [ -f "$CONFIG_DIR/root.txt" ]; then
            logowl "Detect old root solution logging file"
            rm -f "$CONFIG_DIR/root.txt"
            logowl "Removed root.txt"
        fi

        if [ -f "$CONFIG_DIR/status.info" ]; then
            logowl "Detect old status logging file"
            rm -f "$CONFIG_DIR/status.info"
            logowl "Removed status.info"
        fi
        
        rm -f "$CONFIG_DIR/target_bsa.conf"
        rm -f "$CONFIG_DIR/target_bsa.txt"

        rm -f "$CONFIG_DIR/empty"
    fi

}

logowl "Setting up $MOD_NAME"
logowl "Version: $MOD_VER"
init_logowl "$LOG_DIR"
install_env_check
show_system_info
logowl "Install from $ROOT_SOL app"
logowl "Essential check"
extract "$ZIPFILE" 'aautilities.sh' "$VERIFY_DIR"
extract "$ZIPFILE" 'customize.sh' "$VERIFY_DIR"
clean_old_logs "$LOG_DIR" 20
migrate_old_files
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
[ "$VERIFY_DIR" != "/" ] && rm -rf "$VERIFY_DIR"
logowl "Set permission"
set_permission_recursive "$MODPATH" 0 0 0755 0644
logowl "Welcome to use $MOD_NAME!"
DESCRIPTION="[⏳Reboot to take effect. ⚙️Root: $ROOT_SOL_DETAIL] $MOD_INTRO"
update_config_value "description" "$DESCRIPTION" "$MODPATH/module.prop"