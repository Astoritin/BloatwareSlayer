#!/system/bin/sh
SKIPUNZIP=1

CONFIG_DIR=/data/adb/bloatwareslayer
CONFIG_FILE="$CONFIG_DIR/settings.conf"
LOG_DIR="$CONFIG_DIR/logs"
VERIFY_DIR="$TMPDIR/.aa_bs_verify"
MOD_NAME="$(grep_prop name "${TMPDIR}/module.prop")"
MOD_VER="$(grep_prop version "${TMPDIR}/module.prop") ($(grep_prop versionCode "${TMPDIR}/module.prop"))"

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
show_system_info
init_logowl "$LOG_DIR"
clean_old_logs "$LOG_DIR" 20
logowl "Essential checks"
extract "$ZIPFILE" 'aautilities.sh' "$VERIFY_DIR"
extract "$ZIPFILE" 'customize.sh' "$VERIFY_DIR"
logowl "Extract module files"
extract "$ZIPFILE" 'aautilities.sh' "$MODPATH"
extract "$ZIPFILE" 'module.prop' "$MODPATH"
extract "$ZIPFILE" 'service.sh' "$MODPATH"
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
logowl "Extract WebUI Project files"
extract "$ZIPFILE" 'webroot/index.html' "$MODPATH"
extract "$ZIPFILE" 'webroot/mdui/mdui.css' "$MODPATH"
extract "$ZIPFILE" 'webroot/mdui/mdui.global.js' "$MODPATH"
extract "$ZIPFILE" 'webroot/aaui/aaui.css' "$MODPATH"
rm -rf "$VERIFY_DIR"
set_module_files_perm
logowl "Welcome to use ${MOD_NAME}!"
