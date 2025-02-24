#!/system/bin/sh
MODDIR=${0%/*}

enforce_install_from_magisk_app(){

  local CONFIG_DIR="$1"
  local MAGISK_OUI=Official
  local ROOT_IMP=Unknown

  if [ ! -d "$CONFIG_DIR" ]; then
    ui_print "- $CONFIG_DIR does not exist"
    mkdir -p "$CONFIG_DIR" || abort "! Failed to create $CONFIG_DIR!"
    ui_print "- Create $CONFIG_DIR"
  fi

  if [ "$BOOTMODE" ] && [ "$KSU" ]; then
  ui_print "- Install from KernelSU APP"
  ui_print "- KernelSU version: $KSU_KERNEL_VER_CODE (kernel) + $KSU_VER_CODE (ksud)"
  ROOT_IMP="KernelSU (kernel:$KSU_KERNEL_VER_CODE, ksud:$KSU_VER_CODE)"
  if [ "$(which magisk)" ]; then
    ui_print "! Detect multiple Root implements!"
    ROOT_IMP="Multiple"
  fi
  elif [ "$BOOTMODE" ] && [ "$APATCH" ]; then
  ui_print "- Install from APatch APP"
  ui_print "- APatch version: $APATCH_VER_CODE"
  ROOT_IMP="APatch ($APATCH_VER_CODE)"
  elif [ "$BOOTMODE" ] && [ "$MAGISK_VER_CODE" ]; then
    if [[ "$MAGISK_VER" == *"-alpha" ]]; then
    MAGISK_OUI="Magisk Alpha"
    ROOT_IMP="Magisk Alpha ($MAGISK_VER_CODE)"
    elif [[ "$MAGISK_VER" == *"-lite" ]]; then
    MAGISK_OUI="Magisk Lite"
    ROOT_IMP="Magisk Lite ($MAGISK_VER_CODE)"
    elif [[ "$MAGISK_VER" == *"-kitsune" ]]; then
    MAGISK_OUI="Kitsune Mask"
    ROOT_IMP="Kitsune Mask ($MAGISK_VER_CODE)"
    elif [[ "$MAGISK_VER" == *"-delta" ]]; then
    MAGISK_OUI="Magisk Delta"
    ROOT_IMP="Magisk Delta ($MAGISK_VER_CODE)"
    else
    ROOT_IMP="Magisk ($MAGISK_VER_CODE)"
    fi
  ui_print "- Install from $MAGISK_OUI APP"
  ui_print "- Magisk version: $MAGISK_VER ($MAGISK_VER_CODE)"
  else
  ui_print "! Install modules in Recovery mode is not support!"
  about "! Please install this module in Magisk / KernelSU / APatch APP!"
  fi
  echo "$ROOT_IMP" > "$CONFIG_DIR/root.txt"
}

show_system_info(){
  ui_print "- Device brand: `getprop ro.product.brand`"
  ui_print "- Device model: `getprop ro.product.model`"
  ui_print "- Device codeName: `getprop ro.product.device`"
  ui_print "- Device Architecture: $ARCH"
  ui_print "- Android version: `getprop ro.build.version.release` API $API"
  ui_print "- RAM space: `free -m|grep "Mem"|awk '{print $2}'`MB  used:`free -m|grep "Mem"|awk '{print $3}'`MB  free:$((`free -m|grep "Mem"|awk '{print $2}'`-`free -m|grep "Mem"|awk '{print $3}'`))MB"
  ui_print "- SWAP space: `free -m|grep "Swap"|awk '{print $2}'`MB  used:`free -m|grep "Swap"|awk '{print $3}'`MB  free:`free -m|grep "Swap"|awk '{print $4}'`MB"
}

extract() {
  zip=$1
  file=$2
  dir=$3
  junk_paths=$4
  [ -z "$junk_paths" ] && junk_paths=false
  opts="-o"
  [ $junk_paths = true ] && opts="-oj"

  file_path=""
  if [ $junk_paths = true ]; then
    file_path="$dir/$(basename "$file")"
  else
    file_path="$dir/$file"
  fi

  unzip $opts "$zip" "$file" -d "$dir" >&2
  [ -f "$file_path" ] || abort "$file not exists"
  ui_print "- Extract $file -> $file_path" >&1
  
}

set_module_files_perm(){
  ui_print "- Setting permissions"
  set_perm_recursive "$MODPATH" 0 0 0755 0644
}
