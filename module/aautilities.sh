VERIFY_DIR="$TMPDIR/.aa_bs_verify"
mkdir "$VERIFY_DIR"

install_env_check() {
  local MAGISK_BRANCH_NAME="Official"
  ROOT_SOL="Magisk"
  if [[ "$KSU" ]]; then
    logowl "Install from KernelSU"
    logowl "KernelSU version: $KSU_KERNEL_VER_CODE (kernel) + $KSU_VER_CODE (ksud)"
    ROOT_SOL="KernelSU (kernel:$KSU_KERNEL_VER_CODE, ksud:$KSU_VER_CODE)"
    if [[ "$(which magisk)" ]]; then
      logowl "Detect multiple Root implements!" "WARN"
      ROOT_SOL="Multiple"
    fi
  elif [[ "$APATCH" ]]; then
    logowl "Install from APatch"
    logowl "APatch version: $APATCH_VER_CODE"
    ROOT_SOL="APatch ($APATCH_VER_CODE)"
  elif [[ "$MAGISK_VER_CODE" || -n "$(magisk -v || magisk -V)" ]]; then
    MAGISK_V_VER_NAME="$(magisk -v)"
    MAGISK_V_VER_CODE="$(magisk -V)"
    if [[ "$MAGISK_VER" == *"-alpha"* || "$MAGISK_V_VER_NAME" == *"-alpha"* ]]; then
      MAGISK_BRANCH_NAME="Magisk Alpha"
    elif [[ "$MAGISK_VER" == *"-lite"* || "$MAGISK_V_VER_NAME" == *"-lite"* ]]; then
      MAGISK_BRANCH_NAME="Magisk Lite"
    elif [[ "$MAGISK_VER" == *"-kitsune"* || "$MAGISK_V_VER_NAME" == *"-kitsune"* ]]; then
      MAGISK_BRANCH_NAME="Kitsune Mask"
    elif [[ "$MAGISK_VER" == *"-delta"* || "$MAGISK_V_VER_NAME" == *"-delta"* ]]; then
      MAGISK_BRANCH_NAME="Magisk Delta"
    else
      MAGISK_BRANCH_NAME="Magisk"
    fi
    ROOT_SOL="$MAGISK_BRANCH_NAME (${MAGISK_VER_CODE:-$MAGISK_V_VER_CODE})"
    logowl "Install from $ROOT_SOL"
  else
    ROOT_SOL="Recovery"
    print_line
    logowl "Install module in Recovery mode is not support especially for KernelSU / APatch!" "FATAL"
    logowl "Please install this module in Magisk / KernelSU / APatch APP!" "FATAL"
    print_line
    abort
  fi
}

module_intro() {  
    MODULE_PROP="${MODDIR}/module.prop"
    MOD_NAME="$(sed -n 's/^name=\(.*\)/\1/p' "$MODULE_PROP")"
    MOD_AUTHOR="$(sed -n 's/^author=\(.*\)/\1/p' "$MODULE_PROP")"
    MOD_VER="$(sed -n 's/^version=\(.*\)/\1/p' "$MODULE_PROP") ($(sed -n 's/^versionCode=\(.*\)/\1/p' "$MODULE_PROP"))"
    print_line
    logowl "$MOD_NAME"
    logowl "By $MOD_AUTHOR"
    logowl "Version: $MOD_VER"
    logowl "Root solution: $ROOT_SOL"
    logowl "Current time stamp: $(date +"%Y-%m-%d %H:%M:%S")"
    print_line
}

init_logowl() {

  local LOG_DIR="$1"
  if [ -z "$LOG_DIR" ]; then
    echo "- Error: LOG_DIR is not provided!" >&2
    return 1
  fi

 if [ ! -d "$LOG_DIR" ]; then
  echo "- Log directory: $LOG_DIR does not exist. Creating now"
  mkdir -p "$LOG_DIR" || {
    echo "- Error: Failed to create log directory: $LOG_DIR" >&2
    return 2
    }
    echo "- Log directory created successfully: $LOG_DIR"
  else
    echo "- Log directory: $LOG_DIR"
  fi
}

logowl() {

  local LOG_MSG="$1"
  local LOG_LEVEL="$2"

  if [ -z "$LOG_MSG" ]; then
    echo "! LOG_MSG is not provided yet!"
    return 3
  fi

  case "$LOG_LEVEL" in
    "TIPS")
      LOG_LEVEL="*"
      ;;
    "WARN")
      LOG_LEVEL="- Warn:"
      ;;
    "ERROR")
      LOG_LEVEL="! ERROR:"
      ;;
    "FATAL")
      LOG_LEVEL="× FATAL:"
      ;;
    *)
      LOG_LEVEL="-"
      ;;
  esac

  if [ -z "$LOG_FILE" ]; then
    if [ "$BOOTMODE" ]; then
        ui_print "$LOG_LEVEL $LOG_MSG" 2>/dev/null
        return 0
    fi
    echo "$LOG_LEVEL $LOG_MSG"
  else
    if [[ "$LOG_LEVEL" == "! ERROR:" ]] || [[ "$LOG_LEVEL" == "× FATAL:" ]]; then
      print_line >> "$LOG_FILE"
    fi
    echo "$LOG_LEVEL $LOG_MSG" >> "$LOG_FILE" 2>> "$LOG_FILE"
    if [[ "$LOG_LEVEL" == "! ERROR:" ]] || [[ "$LOG_LEVEL" == "× FATAL:" ]]; then
      print_line >> "$LOG_FILE"
    fi
  fi
}

init_variables() {
    local key="$1"
    local config_file="$2"
    local value

    if [[ ! -f "$config_file" ]]; then
        logowl "Configuration file $config_file does not exist." "ERROR" >&2
        return 1
    fi

    value=$(sed -n "s/^$key=\(.*\)/\1/p" "$config_file")

    if [[ -z "$value" ]]; then
        logowl "Key '$key' is NOT found in $config_file" "WARN" >&2
        return 2
    fi

    echo "$value"
}

verify_variables() {
    local config_var_name="$1"
    local config_var_value="$2"
    local validation_pattern="$3"
    # local default_value="$4"
    local script_var_name=$(echo "$config_var_name" | tr '[:lower:]' '[:upper:]')

    if [ -n "$config_var_value" ] && [[ "$config_var_value" =~ $validation_pattern ]]; then
        # logowl "Detect current var: $config_var_name=$config_var_value"
        export "$script_var_name"="$config_var_value"
        logowl "Set $script_var_name=$config_var_value" "TIPS"
    else
        logowl "Unavailable var: $config_var_name=$config_var_value"
        logowl "Will keep the value as default one"
        # if [ -n "$default_value" ]; then
        #     logowl "Keep $script_var_name as default value ($default_value)"
        #     export "$script_var_name"="$default_value"
        # else
        #     logowl "No default value provided for $script_var_name, keep empty"
        #     export "$script_var_name"=""
        # fi
    fi
}

update_module_description() {
  local DESCRIPTION="$1"
  local MODULE_PROP="$2"
  if [ -z "$DESCRIPTION" ] || [ -z "$MODULE_PROP" ]; then
    logowl "DESCRIPTION or MODULE_PROP is not provided yet!" "ERROR"
    return 3
  fi
  logowl "Update description: $DESCRIPTION"
  sed -i "/^description=/c\description=$DESCRIPTION" "$MODULE_PROP"
}

debug_print_values() {
  print_line
  logowl "Environment Info"
  print_line
  env | sed 's/^/- /'
  print_line
  logowl "Specific Info"
  print_line
  set | grep '^[^=]*=' | sed 's/^/- /'
  print_line
}

show_system_info() {
  logowl "Device: $(getprop ro.product.brand) $(getprop ro.product.model) ($(getprop ro.product.device))"
  logowl "Android $(getprop ro.build.version.release) (API $API), $ARCH"
  mem_info=$(free -m)
  ram_total=$(echo "$mem_info" | awk '/Mem/ {print $2}')
  ram_used=$(echo "$mem_info" | awk '/Mem/ {print $3}')
  ram_free=$((ram_total - ram_used))
  swap_total=$(echo "$mem_info" | awk '/Swap/ {print $2}')
  swap_used=$(echo "$mem_info" | awk '/Swap/ {print $3}')
  swap_free=$(echo "$mem_info" | awk '/Swap/ {print $4}')
  logowl "RAM Space: ${ram_total}MB  Used:${ram_used}MB  Free:${ram_free}MB"
  logowl "SWAP Space: ${swap_total}MB  Used:${swap_used}MB  Free:${swap_free}MB"
}

print_line() {
  local length=${1:-60}
  local line=$(printf "%-${length}s" | tr ' ' '-')
  echo "$line"
}

file_compare() {
  local file_a="$1"
  local file_b="$2"
  if [ -z "$file_a" ] || [ -z "$file_b" ]; then
    logowl "Value a or value b does not exist!" "WARN"
    return 2
  fi
  if [ ! -f "$file_a" ]; then
    logowl "a is NOT a file!" "WARN"
    return 3
  fi
  if [ ! -f "$file_b" ]; then
    logowl "b is NOT a file!" "WARN"
    return 3
  fi
  local hash_file_a=$(sha256sum "$file_a" | awk '{print $1}')
  local hash_file_b=$(sha256sum "$file_b" | awk '{print $1}')
  logowl "File a: $hash_file_a"
  logowl "File b: $hash_file_b"
  if [ "$hash_file_a" == "$hash_file_b" ]; then
    logowl "The hash of file a is equal to file b, they are the same files!"
    return 0
  else
    logowl "The hash of file a is NOT equal to file b, they are NOT the same files!"
    return 1
  fi
}

abort_verify() {
  print_line
  echo "! $1"
  echo "! This zip may be corrupted or have been maliciously modified!"
  echo "! Please try to download again or get it from official source!"
  print_line
  return 1
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
  hash_path=""
  if [ $junk_paths = true ]; then
    file_path="$dir/$(basename "$file")"
    hash_path="$VERIFY_DIR/$(basename "$file").sha256"
  else
    file_path="$dir/$file"
    hash_path="$VERIFY_DIR/$file.sha256"
  fi

  unzip $opts "$zip" "$file" -d "$dir" >&2
  [ -f "$file_path" ] || abort_verify "$file does not exist!"
  logowl "Extract $file -> $file_path" >&1

  unzip $opts "$zip" "$file.sha256" -d "$VERIFY_DIR" >&2
  [ -f "$hash_path" ] || abort_verify "$file.sha256 does not exist!"

  expected_hash="$(cat "$hash_path")"
  calculated_hash="$(sha256sum "$file_path" | cut -d ' ' -f1)"

  if [ "$expected_hash" == "$calculated_hash" ]; then
    logowl "Verified $file" >&1
  else
    abort_verify "Failed to verify $file"
  fi
}

set_module_files_perm() {
  logowl "Setting permissions"
  set_perm_recursive "$MODPATH" 0 0 0755 0644
}

clean_old_logs() {
    local log_dir="$1"
    local files_max="$2"
    
    if [ -z "$log_dir" ] || [ ! -d "$log_dir" ]; then
        logowl "$log_dir is not found or is not a directory!" "ERROR"
        return
    fi

    if [ -z "$files_max" ]; then
        files_max=30
    fi

    files_count=$(ls -1 "$log_dir" | wc -l)
    if [ "$files_count" -gt "$files_max" ]; then
        logowl "Detect too many log files" "WARN"
        logowl "$files_count files, current max allowed: $files_max"
        logowl "Clearing old logs"
        ls -1t "$log_dir" | tail -n +$((files_max + 1)) | while read -r file; do
            rm -f "$log_dir/$file"
        done
        logowl "Cleared!"
    else
        logowl "Detect $files_count files in $log_dir"
    fi
}
