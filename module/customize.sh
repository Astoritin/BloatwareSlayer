#!/system/bin/sh
SKIPUNZIP=1
MOD_NAME=$(grep_prop name "${TMPDIR}/module.prop")
CONFIG_DIR=/data/adb/bloatwareslayer
LOG_DIR="$CONFIG_DIR/logs"

ui_print "- Extract aautilities.sh"
ui_print "- MODPATH: $MODPATH"
unzip -o "$ZIPFILE" 'aautilities.sh' -d "$TMPDIR" >&2
if [ ! -f "$TMPDIR/aautilities.sh" ]; then
  ui_print "! Failed to extract aautilities.sh!"
  abort "! This zip may be corrupted!"
fi

. "$TMPDIR/aautilities.sh"

module_install_proc(){
  ui_print "- Setting up $MOD_NAME"
  ui_print "- Extract module(s) file(s)"
  extract "$ZIPFILE" 'aautilities.sh' "$MODPATH"
  extract "$ZIPFILE" 'module.prop'     "$MODPATH"
  extract "$ZIPFILE" 'post-fs-data.sh' "$MODPATH"
  extract "$ZIPFILE" 'service.sh' "$MODPATH"
  extract "$ZIPFILE" 'uninstall.sh' "$MODPATH"
  if [ ! -d "$LOG_DIR" ]; then
    ui_print "- $LOG_DIR does not exist"
    mkdir -p "$LOG_DIR" || abort "! Failed to create $LOG_DIR!"
    ui_print "- Create $LOG_DIR"
  fi
  if [ ! -f "$CONFIG_DIR/target.txt" ]; then
    ui_print "- target.txt does not exist"
    extract "$ZIPFILE" 'target.txt' "$TMPDIR"
    mv "$TMPDIR/target.txt" "$CONFIG_DIR/target.txt" || abort "! Failed to create target.txt!"
  else
    ui_print "- Detect existed target.txt"
    ui_print "- Skip overwriting target.txt"
  fi
}

show_system_info
enforce_install_from_magisk_app "$CONFIG_DIR"
module_install_proc
set_module_files_perm
ui_print "- Welcome to use ${MOD_NAME}!"
