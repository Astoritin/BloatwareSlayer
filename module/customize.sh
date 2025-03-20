#!/system/bin/sh
SKIPUNZIP=1

CONFIG_DIR="/data/adb/bloatwareslayer"
CONFIG_FILE="$CONFIG_DIR/settings.conf"
LOG_DIR="$CONFIG_DIR/logs"
VERIFY_DIR="$TMPDIR/.aa_verify"
MOD_NAME="$(grep_prop name "${TMPDIR}/module.prop")"
MOD_VER="$(grep_prop version "${TMPDIR}/module.prop") ($(grep_prop versionCode "${TMPDIR}/module.prop"))"

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

migrate_old_files() {
    # migrate the files from old versions of Bloatware Slayer
    logowl "Migrating old files"

    # migrate from v1.0.0 ~ v1.2.0
    if [ -f "$CONFIG_DIR/target.txt" ] && [ ! -f "$CONFIG_DIR/target.conf"  ]; then
        logowl "Detect old config file"
        logowl "Migrate target.txt -> target.conf"
        mv "$CONFIG_DIR/target.txt" "$CONFIG_DIR/target.conf"
    elif [ -f "$CONFIG_DIR/target.txt" ] && [ -f "$CONFIG_DIR/target.conf" ]; then
        logowl "Both target.txt and target.conf exist"
        logowl "Merging contents"
        cat "$CONFIG_DIR/target.txt" >> "$CONFIG_DIR/target.conf"
        sort -u "$CONFIG_DIR/target.txt" >> "$CONFIG_DIR/target.conf"
        logowl "Merged, target.txt has been removed"
        rm -f "$CONFIG_DIR/target.txt"
    fi

    # cleanup remnant from v1.0.5
    if [ -f "$CONFIG_DIR/root.txt" ]; then
        logowl "Detect old root solution logging file"
        rm -f "$CONFIG_DIR/root.txt"
        logowl "Removed root.txt"
    fi

    # cleanup remnant from v1.0.6 ~ v1.1.2
    if [ -f "$CONFIG_DIR/status.info" ]; then
        logowl "Detect old status logging file"
        rm -f "$CONFIG_DIR/status.info"
        logowl "Removed status.info"
    fi
    
    # cleanup remnant of target list bloatware slayer arranged file
    rm -f "$CONFIG_DIR/target_bsa.conf"
    rm -f "$CONFIG_DIR/target_bsa.txt"
}

logowl "Setting up $MOD_NAME"
logowl "Version: $MOD_VER"
install_env_check
init_logowl "$LOG_DIR" > /dev/null 2>&1
clean_old_logs "$LOG_DIR" 20 > /dev/null 2>&1
show_system_info
migrate_old_files
logowl "Essential checks"
extract "$ZIPFILE" 'aautilities.sh' "$VERIFY_DIR"
extract "$ZIPFILE" 'customize.sh' "$VERIFY_DIR"
logowl "Extract module files"
extract "$ZIPFILE" 'aautilities.sh' "$MODPATH"
extract "$ZIPFILE" 'module.prop' "$MODPATH"
extract "$ZIPFILE" 'service.sh' "$MODPATH"
extract "$ZIPFILE" 'action.sh' "$MODPATH"
extract "$ZIPFILE" 'uninstall.sh' "$MODPATH"
logowl "Extract default config files"
if [ ! -f "$CONFIG_DIR/target.conf" ]; then
    logowl "target.conf does NOT exist"
    extract "$ZIPFILE" 'target.conf' "$TMPDIR"
    mv "$TMPDIR/target.conf" "$CONFIG_DIR/target.conf" || abort "! Failed to create target.conf!"
else
    logowl "target.conf already exists"
    logowl "Skip overwriting target.conf"
fi
if [ ! -f "$CONFIG_FILE" ]; then
    logowl "settings.conf does NOT exist"
    extract "$ZIPFILE" 'settings.conf' "$TMPDIR"
    mv "$TMPDIR/settings.conf" "$CONFIG_FILE" || abort "! Failed to create settings.conf!"
else
    logowl "settings.conf already exists"
    logowl "Skip overwriting settings.conf"
fi
rm -rf "$VERIFY_DIR"
set_module_files_perm
logowl "Welcome to use ${MOD_NAME}!"
