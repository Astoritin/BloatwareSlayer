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

if [ ! -d "$LOG_DIR" ]; then
  logowl "$LOG_DIR does not exist"
  mkdir -p "$LOG_DIR" || abort "! Failed to create $LOG_DIR!"
  logowl "Created $LOG_DIR"
fi

logowl "Setting up $MOD_NAME"
logowl "Version: $MOD_VER"
init_logowl "$LOG_DIR"
show_system_info
install_env_check 
clean_old_logs "$LOG_DIR" 20
logowl "Extract module file(s)"
extract "$ZIPFILE" 'aautilities.sh' "$VERIFY_DIR"
extract "$ZIPFILE" 'customize.sh' "$VERIFY_DIR"
extract "$ZIPFILE" 'aautilities.sh' "$MODPATH"
extract "$ZIPFILE" 'module.prop' "$MODPATH"
extract "$ZIPFILE" 'service.sh' "$MODPATH"
extract "$ZIPFILE" 'uninstall.sh' "$MODPATH"
if [ ! -f "$CONFIG_DIR/target.txt" ]; then
  logowl "target.txt does not exist"
  extract "$ZIPFILE" 'target.txt' "$TMPDIR"
  mv "$TMPDIR/target.txt" "$CONFIG_DIR/target.txt" || abort "! Failed to create target.txt!"
else
  logowl "Detect target.txt already existed"
  logowl "Skip overwriting target.txt"
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
