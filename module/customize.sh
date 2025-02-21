#!/system/bin/sh
SKIPUNZIP=1
MODNAME=$(grep_prop name "${TMPDIR}/module.prop")
CONFIGDIR=/data/adb/bloatwareslayer
LOGDIR="$CONFIGDIR/logs"

ui_print "- Extract aautilities.sh"
ui_print "- ZIPFILE: $ZIPFILE"
ui_print "- TMPDIR: $TMPDIR"
ui_print "- MODPATH: $MODPATH"
unzip -o "$ZIPFILE" 'aautilities.sh' -d "$TMPDIR" >&2
if [ ! -f "$TMPDIR/aautilities.sh" ]; then
  ui_print "! Failed to extract aautilities.sh!"
  abort "! This zip may be corrupted!"
fi

. "$TMPDIR/aautilities.sh"

module_install_proc(){
  ui_print "- Configuring $MODNAME"
  ui_print "- Extract module file(s)"
  extract "$ZIPFILE" 'module.prop'     "$MODPATH"
  extract "$ZIPFILE" 'post-fs-data.sh' "$MODPATH"
  extract "$ZIPFILE" 'uninstall.sh' "$MODPATH"
  if [ ! -d "$LOGDIR" ]; then
    ui_print "- $CONFIGDIR does not exist"
    ui_print "- $LOGDIR does not exist"
    mkdir -p "$LOGDIR" || abort "! Failed to create $LOGDIR!"
    ui_print "- Create $CONFIGDIR"
    ui_print "- Create $LOGDIR"
  fi
  if [ ! -f "$CONFIGDIR/target.txt" ]; then
    ui_print "- target.txt does not exist"
    extract "$ZIPFILE" 'target.txt' "$TMPDIR"
    mv "$TMPDIR/target.txt" "$CONFIGDIR/target.txt" || abort "! Failed to create target.txt!"
  else
    ui_print "- Detect existed target.txt"
    ui_print "- Skip overwritting target.txt"
  fi
}

show_system_info
enforce_install_from_magisk_app
module_install_proc
set_module_files_perm
ui_print "- Welcome to use ${MODNAME}!"