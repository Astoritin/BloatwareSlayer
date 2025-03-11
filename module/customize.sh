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

install_env_check
logowl "Setting up $MOD_NAME"
logowl "Version: $MOD_VER"
init_logowl "$LOG_DIR"
show_system_info
clean_old_logs "$LOG_DIR" 20
logowl "Extract module files"
extract "$ZIPFILE" 'aautilities.sh' "$VERIFY_DIR"
extract "$ZIPFILE" 'customize.sh' "$VERIFY_DIR"
extract "$ZIPFILE" 'aautilities.sh' "$MODPATH"
extract "$ZIPFILE" 'module.prop' "$MODPATH"
extract "$ZIPFILE" 'service.sh' "$MODPATH"
extract "$ZIPFILE" 'uninstall.sh' "$MODPATH"
if [ ! -f "$CONFIG_DIR/target.conf" ]; then
  logowl "target.conf does not exist"
  extract "$ZIPFILE" 'target.conf' "$TMPDIR"
  mv "$TMPDIR/target.conf" "$CONFIG_DIR/target.conf" || abort "! Failed to create target.conf!"
else
  logowl "Detect target.conf already existed"
  logowl "Skip overwriting target.conf"
fi
if [ ! -f "$CONFIG_FILE" ]; then
  logowl "settings.conf does not exist"
  extract "$ZIPFILE" 'settings.conf' "$TMPDIR"
  mv "$TMPDIR/settings.conf" "$CONFIG_FILE" || abort "! Failed to create settings.conf!"
else
  logowl "Detect settings.conf already existed"
  logowl "Skip overwriting settings.conf"
fi
set_module_files_perm
logowl "Welcome to use ${MOD_NAME}!"
