#!/system/bin/sh
SKIPUNZIP=1

CONFIG_DIR=/data/adb/bloatwareslayer
LOG_DIR="$CONFIG_DIR/logs"
MOD_NAME="$(grep_prop name "${TMPDIR}/module.prop")"
MOD_VER="$(grep_prop version "${TMPDIR}/module.prop") ($(grep_prop versionCode "${TMPDIR}/module.prop"))"
VERIFY_DIR="$TMPDIR/.aa_bs_verify"

echo "- Extract aautilities.sh"
echo "- MODPATH: $MODPATH"
unzip -o "$ZIPFILE" 'aautilities.sh' -d "$TMPDIR" >&2
if [ ! -f "$TMPDIR/aautilities.sh" ]; then
  echo "! Failed to extract aautilities.sh!"
  abort "! This zip may be corrupted!"
fi
. "$TMPDIR/aautilities.sh"

module_install_proc(){
  echo "- Installing $MOD_NAME"
  echo "- Version: $MOD_VER"
  echo "- Check old logs"
  if [ -e "$LOG_DIR" ]; then
    echo "- Detect old logs exists, start cleaning..."
    rm -rf "$LOG_DIR"
    echo "- Done, $LOG_DIR has been cleaned."
  else
    echo "- $LOG_DIR does not exist."
  fi
  echo "- Extract module file(s)"
  extract "$ZIPFILE" 'aautilities.sh' "$VERIFY_DIR"
  extract "$ZIPFILE" 'customize.sh' "$VERIFY_DIR"
  extract "$ZIPFILE" 'aautilities.sh' "$MODPATH"
  extract "$ZIPFILE" 'module.prop' "$MODPATH"
  extract "$ZIPFILE" 'post-fs-data.sh' "$MODPATH"
  extract "$ZIPFILE" 'service.sh' "$MODPATH"
  extract "$ZIPFILE" 'uninstall.sh' "$MODPATH"
  if [ ! -d "$LOG_DIR" ]; then
    echo "- $LOG_DIR does not exist"
    mkdir -p "$LOG_DIR" || abort "! Failed to create $LOG_DIR!"
    echo "- Create $LOG_DIR"
  fi
  if [ ! -f "$CONFIG_DIR/target.txt" ]; then
    echo "- target.txt does not exist"
    extract "$ZIPFILE" 'target.txt' "$TMPDIR"
    mv "$TMPDIR/target.txt" "$CONFIG_DIR/target.txt" || abort "! Failed to create target.txt!"
  else
    echo "- Detect existed target.txt"
    echo "- Skip overwriting target.txt"
  fi
}

show_system_info
install_env_check "$CONFIG_DIR"
debug_print_values "$LOG_DIR/log_install_$(date +"%Y-%m-%d_%H-%M-%S").txt"
module_install_proc
set_module_files_perm
echo "- Welcome to use ${MOD_NAME}!"
