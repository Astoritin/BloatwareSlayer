#!/system/bin/sh
MODDIR=${0%/*}

CONFIG_DIR="/data/adb/bloatwareslayer"

CONFIG_FILE="$CONFIG_DIR/settings.conf"
BRICKED_STATUS="$CONFIG_DIR/bricked"
EMPTY_DIR="$CONFIG_DIR/empty"
LOG_DIR="$CONFIG_DIR/logs"
LOG_FILE="$LOG_DIR/bs_log_addon_$(date +"%Y-%m-%d_%H-%M-%S").log"
LINK_MB_FILE="$LOG_DIR/target_link_mb.conf"

MODULE_PROP="$MODDIR/module.prop"
MOD_NAME="$(sed -n 's/^name=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_AUTHOR="$(sed -n 's/^author=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_VER="$(sed -n 's/^version=\(.*\)/\1/p' "$MODULE_PROP") ($(sed -n 's/^versionCode=\(.*\)/\1/p' "$MODULE_PROP"))"
MOD_DESC_OLD="$(sed -n 's/^description=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_ROOT_DIR=$(dirname "$MODDIR")
MOD_ZYGISKSU_PATH="${MOD_ROOT_DIR}/zygisksu"

BRICK_TIMEOUT=180
DISABLE_MODULE_AS_BRICK=true
UPDATE_DESC_ON_ACTION=false

config_loader() {

    logowl "Loading config"

    brick_timeout=$(init_variables "brick_timeout" "$CONFIG_FILE")
    disable_module_as_brick=$(init_variables "disable_module_as_brick" "$CONFIG_FILE")
    update_desc_on_action=$(init_variables "update_desc_on_action" "$CONFIG_FILE")

    verify_variables "brick_timeout" "$brick_timeout" "^[1-9][0-9]*$"
    verify_variables "disable_module_as_brick" "$disable_module_as_brick" "^(true|false)$"
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

        if echo "$MOD_DESC_TMP" | grep -q "⛔ DenyList Enforcing: "; then
            MOD_DESC_NEW=$(echo "$MOD_DESC_TMP" | sed -E "s/(⛔ DenyList Enforcing: )[^]]*/\1${ROOT_SOL_DE}/")
        else
            MOD_DESC_NEW=$(echo "$MOD_DESC_TMP" | sed -E 's/\]/, ⛔ DenyList Enforcing: '"${ROOT_SOL_DE}"'\]/')
        fi

        update_config_value "description" "$MOD_DESC_NEW" "$MODULE_PROP"

    fi

}

. "$MODDIR/aautilities.sh"

update_config_value() {

    key_name="$1"
    key_value="$2"
    file_path="$3"

    if [ -z "$key_name" ] || [ -z "$key_value" ] || [ -z "$file_path" ]; then
        logowl "Key name/value/file path is NOT provided yet!" "ERROR"
        return 1
    elif [ ! -f "$file_path" ]; then
        logowl "$file_path is NOT a valid file!" "ERROR"
        return 2
    fi

    sed -i "/^${key_name}=/c\\${key_name}=${key_value}" "$file_path"
    result_update_value=$?

    if [ $result_update_value -eq 0 ]; then
        return 0
    else
        return 1
    fi

}

link_bind_umount() {
    
}

init_logowl "$LOG_DIR"
module_intro >> "$LOG_FILE"
show_system_info >> "$LOG_FILE"
print_line
logowl "Starting service.sh"
config_loader
print_line
denylist_enforcing_status_update

{    

    logowl "Current booting timeout: $BRICK_TIMEOUT"
    while [ "$(getprop sys.boot_completed)" != "1" ]; do
        if [ $BRICK_TIMEOUT -le "0" ]; then
            print_line
            logowl "Detect failed to boot after reaching the set limit, your device may be bricked by $MOD_NAME !" "FATAL"
            logowl "Please make sure no improper APP(s) being blocked!" "FATAL"
            logowl "Marking status as bricked"
            touch "$BRICKED_STATUS"
            if [ "$DISABLE_MODULE_AS_BRICK" = "true" ]; then
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

    MOD_REAL_TIME_DESC=""
    while true; do
        if [ "$UPDATE_DESC_ON_ACTION" = "false" ]; then
            logowl "Detect flag UPDATE_DESC_ON_ACTION=false"
            logowl "Exit background task"
            logowl "service.sh case closed!"
            exit 0
        fi
        if [ -f "$MODDIR/remove" ]; then
            MOD_CURRENT_STATUS="remove"
        elif [ -f "$MODDIR/disable" ]; then
            MOD_CURRENT_STATUS="disable"
        else
            MOD_CURRENT_STATUS="enable"
        fi
    
        if [ "$MOD_CURRENT_STATUS" = "remove" ]; then
            MOD_REAL_TIME_DESC="[🗑️ Remove (Reboot to take effect), 🧭 Root: $ROOT_SOL] A Magisk module to remove bloatware in systemless way"
        elif [ "$MOD_CURRENT_STATUS" = "disable" ]; then
            MOD_REAL_TIME_DESC="[❌ Disable (Reboot to take effect), 🧭 Root: $ROOT_SOL] A Magisk module to remove bloatware in systemless way"
        elif [ "$MOD_CURRENT_STATUS" = "enable" ]; then
            MOD_REAL_TIME_DESC="$MOD_DESC_OLD"
        fi
        denylist_enforcing_status_update "$MOD_REAL_TIME_DESC"
        sleep 5
    done

} &
