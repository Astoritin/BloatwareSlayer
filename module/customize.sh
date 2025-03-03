#!/system/bin/sh
SKIPUNZIP=1

CONFIG_DIR=/data/adb/bloatwareslayer
LOG_DIR="$CONFIG_DIR/logs"
VERIFY_DIR="$TMPDIR/.aa_bs_verify"

MOD_NAME="$(grep_prop name "${TMPDIR}/module.prop")"
MOD_VER="$(grep_prop version "${TMPDIR}/module.prop") ($(grep_prop versionCode "${TMPDIR}/module.prop"))"


if [ ! -d "$LOG_DIR" ]; then
  echo "- $LOG_DIR does not exist"
  mkdir -p "$LOG_DIR" || abort "! Failed to create $LOG_DIR!"
  echo "- Created $LOG_DIR"
fi

echo "- Extract aautilities.sh"
# echo "- MODPATH: $MODPATH"
unzip -o "$ZIPFILE" 'aautilities.sh' -d "$TMPDIR" >&2
if [ ! -f "$TMPDIR/aautilities.sh" ]; then
  echo "! Failed to extract aautilities.sh!"
  abort "! This zip may be corrupted!"
fi
. "$TMPDIR/aautilities.sh"

module_install_proc(){
  echo "- Setting up $MOD_NAME"
  echo "- Version: $MOD_VER"
  echo "- Extract module file(s)"
  extract "$ZIPFILE" 'aautilities.sh' "$VERIFY_DIR"
  extract "$ZIPFILE" 'customize.sh' "$VERIFY_DIR"
  extract "$ZIPFILE" 'aautilities.sh' "$MODPATH"
  extract "$ZIPFILE" 'module.prop' "$MODPATH"
  extract "$ZIPFILE" 'service.sh' "$MODPATH"
  extract "$ZIPFILE" 'uninstall.sh' "$MODPATH"
  if [ ! -f "$CONFIG_DIR/target.txt" ]; then
    echo "- target.txt does not exist"
    extract "$ZIPFILE" 'target.txt' "$TMPDIR"
    mv "$TMPDIR/target.txt" "$CONFIG_DIR/target.txt" || abort "! Failed to create target.txt!"
  else
    echo "- Detect target.txt already existed"
    echo "- Skip overwriting target.txt"
  fi
}

show_system_info
install_env_check "$CONFIG_DIR"
clean_old_logs "$LOG_DIR" 30
module_install_proc
set_module_files_perm
echo "- Welcome to use ${MOD_NAME}!"
