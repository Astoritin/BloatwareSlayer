#!/system/bin/sh
MODDIR=${0%/*}

CONFIG_DIR="/data/adb/bloatwareslayer"
CONFIG_FILE="$CONFIG_DIR/settings.conf"
BRICKED_STATUS="$CONFIG_DIR/bricked"
LOG_DIR="$CONFIG_DIR/logs"
LOG_FILE="$LOG_DIR/bs_brickd_$(date +"%Y-%m-%d_%H-%M-%S").log"
TARGET_LIST_BSA="$LOG_DIR/target_bsa.conf"

MODULE_PROP="$MODDIR/module.prop"
MOD_NAME="$(sed -n 's/^name=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_AUTHOR="$(sed -n 's/^author=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_VER="$(sed -n 's/^version=\(.*\)/\1/p' "$MODULE_PROP") ($(sed -n 's/^versionCode=\(.*\)/\1/p' "$MODULE_PROP"))"
MOD_DESC_OLD="$(sed -n 's/^description=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_ROOT_DIR=$(dirname "$MODDIR")
MOD_ZYGISKSU_PATH="${MOD_ROOT_DIR}/zygisksu"

DEBUG=false
SLAY_MODE="MB"
MB_UMOUNT_BIND=true
BRICK_TIMEOUT=180
DISABLE_MODULE_AS_BRICK=true
UPDATE_DESC_ON_ACTION=false

config_loader() {

    logowl "Load config"

    debug=$(init_variables "debug" "$CONFIG_FILE")
    brick_timeout=$(init_variables "brick_timeout" "$CONFIG_FILE")
    disable_module_as_brick=$(init_variables "disable_module_as_brick" "$CONFIG_FILE")
    slay_mode=$(init_variables "slay_mode" "$CONFIG_FILE")
    mb_umount_bind=$(init_variables "mb_umount_bind" "$CONFIG_FILE")
    update_desc_on_action=$(init_variables "update_desc_on_action" "$CONFIG_FILE")

    verify_variables "debug" "$debug" "^(true|false)$"
    verify_variables "brick_timeout" "$brick_timeout" "^[1-9][0-9]*$"
    verify_variables "disable_module_as_brick" "$disable_module_as_brick" "^(true|false)$"
    verify_variables "slay_mode" "$slay_mode" "^(MB|MN|MR)$"
    verify_variables "mb_umount_bind" "$mb_umount_bind" "^(true|false)$"
    verify_variables "update_desc_on_action" "$update_desc_on_action" "^(true|false)$"

}

denylist_enforcing_status_update() {

    MOD_DESC_DE_OLD="$1"

    magisk_enforce_denylist_status
    zygisksu_enforce_denylist_status
    enforce_denylist_desc

    if [ -n "$ROOT_SOL_DE" ]; then

        [ -z "$MOD_DESC_DE_OLD" ] && MOD_DESC_TMP="$MOD_DESC_OLD"
        [ -n "$MOD_DESC_DE_OLD" ] && MOD_DESC_TMP="$MOD_DESC_DE_OLD"

        if echo "$MOD_DESC_TMP" | grep -q "🚫Enforce DenyList: "; then
            MOD_DESC_NEW=$(echo "$MOD_DESC_TMP" | sed -E "s/(🚫Enforce DenyList: )[^]]*/\1${ROOT_SOL_DE}/")
        else
            MOD_DESC_NEW=$(echo "$MOD_DESC_TMP" | sed -E 's/\]/, 🚫Enforce DenyList: '"${ROOT_SOL_DE}"'\]/')
        fi
        update_config_value "description" "$MOD_DESC_NEW" "$MODULE_PROP" "true"
    fi

}

. "$MODDIR/aautilities.sh"

init_logowl "$LOG_DIR"
module_intro >> "$LOG_FILE"
show_system_info >> "$LOG_FILE"
print_line
logowl "Starting service.sh"
config_loader
print_line
[ "$UPDATE_DESC_ON_ACTION" = true ] && denylist_enforcing_status_update

{    

    logowl "Current booting timeout: $BRICK_TIMEOUT"
    while [ "$(getprop sys.boot_completed)" != "1" ]; do
        if [ $BRICK_TIMEOUT -le "0" ]; then
            print_line
            logowl "Detect failed to boot after reaching the set limit!" "FATAL"
            logowl "Your device may be bricked by $MOD_NAME!"
            logowl "Mark status as bricked"
            touch "$BRICKED_STATUS"
            if [ "$DISABLE_MODULE_AS_BRICK" = true ]; then
                logowl "Detect flag DISABLE_MODULE_AS_BRICK=true"
                logowl "Disable $MOD_NAME"
                touch "$MODDIR/disable"
            else
                logowl "Detect flag DISABLE_MODULE_AS_BRICK=false"
            fi
            logowl "Rebooting"
            sync
            reboot -f
            sleep 5
            logowl "Reboot command did not take effect, exiting"
            exit 1
        fi
        BRICK_TIMEOUT=$((BRICK_TIMEOUT-1))
        sleep 1
    done

    logowl "Congratulations! Boot complete!"
    logowl "Current final countdown: $BRICK_TIMEOUT s"
    rm -f "$BRICKED_STATUS"
    if [ $? -eq 0 ]; then
        logowl "Bricked status reset"
    else
        logowl "Failed to reset bricked status" "FATAL"
    fi
    print_line

    if [ "$SLAY_MODE" = "MB" ] && [ "$MB_UMOUNT_BIND" = true ]; then
        logowl "$MOD_NAME is running on Mount Bind mode"
        logowl "Detect flag MB_UMOUNT_BIND=true"
        logowl "Execute umount process"
        if [ ! -f "$TARGET_LIST_BSA" ]; then
            logowl "Invalid Target List ($MOD_NAME arranged) file!" "ERROR"
        else
            lines_count=0

            while IFS= read -r line; do
                lines_count=$((lines_count + 1))

                if check_value_safety "line $lines_count" "$line"; then
                    logowl "Current line: $line"
                else
                    continue
                fi

                line=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
                first_char=$(printf '%s' "$line" | cut -c1)
                if [ -z "$line" ]; then
                    logowl "Empty in line $lines_count (code: 2)" "WARN"
                    continue
                elif [ "$first_char" = "#" ]; then
                    logowl "Comment symbol in line $lines_count (code: 3)" "WARN"
                    continue
                fi

                package=$(echo "$line" | cut -d '#' -f1)
                package=$(echo "$package" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
                if [ -z "$package" ]; then
                    logowl "Only comment left in line $lines_count, skip processing" "TIPS"
                    continue
                fi
                case "$package" in
                    *\\*)
                        logowl "Replace '\\' with '/' in path: $package" "WARN"
                        package=$(echo "$package" | sed -e 's/\\/\//g')
                        ;;
                esac
                logowl "After processing: $package"
                umount -f $package
                result_umount=$?
                logowl "Execute umount -f (code: $result_umount)"

            done < "$TARGET_LIST_BSA"
        fi
    fi
    debug_print_values >> "$LOG_FILE"
    logowl "service.sh case closed!"
    
    MOD_REAL_TIME_DESC=""
    while true; do
        if [ "$UPDATE_DESC_ON_ACTION" = false ]; then
            logowl "Detect flag UPDATE_DESC_ON_ACTION=false"
            logowl "Exit background task"
            exit 0
        fi
        if [ -f "$MODDIR/update" ]; then
            MOD_CURRENT_STATUS="update"
        elif [ -f "$MODDIR/remove" ]; then
            MOD_CURRENT_STATUS="remove"
        elif [ -f "$MODDIR/disable" ]; then
            MOD_CURRENT_STATUS="disable"
        else
            MOD_CURRENT_STATUS="enable"
        fi

        if [ "$MOD_CURRENT_STATUS" = "update" ]; then
            logowl "Detect update status"
            logowl "Exit background task"
            exit 0
        elif [ "$MOD_CURRENT_STATUS" = "remove" ]; then
            MOD_REAL_TIME_DESC="[🗑️Remove. 🤖Root: $ROOT_SOL_DETAIL] A Magisk module to remove bloatware in systemless way."
        elif [ "$MOD_CURRENT_STATUS" = "disable" ]; then
            MOD_REAL_TIME_DESC="[❌Disable. 🤖Root: $ROOT_SOL_DETAIL] A Magisk module to remove bloatware in systemless way."
        elif [ "$MOD_CURRENT_STATUS" = "enable" ]; then
            MOD_REAL_TIME_DESC="$MOD_DESC_OLD"
        fi
        denylist_enforcing_status_update "$MOD_REAL_TIME_DESC"
        sleep 5
    done

} &
