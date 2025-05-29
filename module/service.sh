#!/system/bin/sh
MODDIR=${0%/*}

CONFIG_DIR="/data/adb/bloatwareslayer"

CONFIG_FILE="$CONFIG_DIR/settings.conf"
BRICKED_STATE="$CONFIG_DIR/bricked"
LOG_DIR="$CONFIG_DIR/logs"
LOG_FILE="$LOG_DIR/bs_brickd_$(date +"%Y%m%dT%H%M%S").log"

TARGET_LIST_BSA="$LOG_DIR/target_bsa.conf"
TARGET_LIST_LW="$LOG_DIR/target_lw.conf"

MODULE_PROP="$MODDIR/module.prop"
MOD_NAME="$(sed -n 's/^name=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_AUTHOR="$(sed -n 's/^author=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_VER="$(sed -n 's/^version=\(.*\)/\1/p' "$MODULE_PROP") ($(sed -n 's/^versionCode=\(.*\)/\1/p' "$MODULE_PROP"))"
MOD_INTRO="A Magisk module to remove bloatware in systemless way."

MOD_DESC_OLD="$(sed -n 's/^description=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_ROOT_DIR=$(dirname "$MODDIR")
MOD_ZYGISKSU_PATH="${MOD_ROOT_DIR}/zygisksu"

BRICK_RESCUE=true
DISABLE_MODULE_AS_BRICK=true
BRICK_TIMEOUT=180
LAST_WORKED_TARGET_LIST=true

SLAY_MODE=MB
MB_UMOUNT_BIND=true

UPDATE_DESC_ON_ACTION=false

config_loader() {

    logowl "Load configuration"

    brick_rescue=$(get_config_var "brick_rescue" "$CONFIG_FILE")
    brick_timeout=$(get_config_var "brick_timeout" "$CONFIG_FILE")
    disable_module_as_brick=$(get_config_var "disable_module_as_brick" "$CONFIG_FILE")
    last_worked_target_list=$(get_config_var "last_worked_target_list" "$CONFIG_FILE")
    slay_mode=$(get_config_var "slay_mode" "$CONFIG_FILE")
    mb_umount_bind=$(get_config_var "mb_umount_bind" "$CONFIG_FILE")
    update_desc_on_action=$(get_config_var "update_desc_on_action" "$CONFIG_FILE")

    verify_var "brick_rescue" "$brick_rescue" "^(true|false)$"
    verify_var "brick_timeout" "$brick_timeout" "^[1-9][0-9]*$"
    verify_var "disable_module_as_brick" "$disable_module_as_brick" "^(true|false)$"
    verify_var "last_worked_target_list" "$last_worked_target_list" "^(true|false)$"
    verify_var "slay_mode" "$slay_mode" "^(MB|MN|MR)$"
    verify_var "mb_umount_bind" "$mb_umount_bind" "^(true|false)$"
    verify_var "update_desc_on_action" "$update_desc_on_action" "^(true|false)$"

}

magisk_enforce_denylist_status() {

    if is_magisk; then
        MAGISK_DE_STATUS=$(magisk --sqlite "SELECT value FROM settings WHERE key='denylist';" | sed 's/^.*=\([01]\)$/\1/')
        if [ -n "$MAGISK_DE_STATUS" ]; then
            if [ "$MAGISK_DE_STATUS" = "1" ]; then
                MAGISK_DE_DESC="ON (Magisk)"
            elif [ "$MAGISK_DE_STATUS" = "0" ]; then
                MAGISK_DE_DESC="OFF (Magisk)"
            fi
        fi
    else
        return 1
    fi

}

zygisksu_enforce_denylist_status() {

    if [ -d "$MOD_ZYGISKSU_PATH" ]; then
        ZYGISKSU_DE_STATUS=$(znctl status | grep "enforce_denylist" | sed 's/^.*:\([01]\)$/\1/')
        if [ -n "$ZYGISKSU_DE_STATUS" ]; then
            if [ "$ZYGISKSU_DE_STATUS" = "1" ]; then
                ZYGISKSU_DE_DESC="ON (Zygisk Next)"
            elif [ "$ZYGISKSU_DE_STATUS" = "0" ]; then
                ZYGISKSU_DE_DESC="OFF (Zygisk Next)"
            fi
        fi
    else
        return 1
    fi

}

enforce_denylist_desc() {

    if [ -n "$ZYGISKSU_DE_DESC" ] && [ -n "$MAGISK_DE_DESC" ]; then
        ROOT_SOL_DE="${MAGISK_DE_DESC}, ${ZYGISKSU_DE_DESC}"
    elif [ -n "$ZYGISKSU_DE_DESC" ]; then
        ROOT_SOL_DE="${ZYGISKSU_DE_DESC}"
    elif [ -n "$MAGISK_DE_DESC" ]; then
        ROOT_SOL_DE="${MAGISK_DE_DESC}"
    else
        ROOT_SOL_DE=""
    fi

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
        update_config_var "description" "$MOD_DESC_NEW" "$MODULE_PROP"
    fi

}

. "$MODDIR/aa-util.sh"

logowl_init "$LOG_DIR"
module_intro >> "$LOG_FILE"
show_system_info >> "$LOG_FILE"
print_line
logowl "Start service.sh"
config_loader
print_line
[ "$UPDATE_DESC_ON_ACTION" = true ] && denylist_enforcing_status_update

{    

    logowl "Current booting timeout: $BRICK_TIMEOUT s"
    while [ "$(getprop sys.boot_completed)" != "1" ]; do

        if [ "$BRICK_RESCUE" = false ]; then
            logowl "Detect flag BRICK_RESCUE=false" "WARN"
            logowl "$MOD_NAME will NOT take action as brick occurred!" "WARN"
            break
        fi

        if [ $BRICK_TIMEOUT -le "0" ]; then
            print_line
            logowl "Detect failed to boot after reaching the limit!" "FATAL"
            logowl "Your device may be bricked by $MOD_NAME!"
            logowl "Mark state as bricked"
            touch "$BRICKED_STATE"
            if [ "$DISABLE_MODULE_AS_BRICK" = true ]; then
                logowl "Detect flag DISABLE_MODULE_AS_BRICK=true"
                logowl "Disable $MOD_NAME"
                touch "$MODDIR/disable"
            else
                logowl "Detect flag DISABLE_MODULE_AS_BRICK=false"
            fi
            DESCRIPTION="[❌No effect. Auto disable from brick! ⚙️Root: $ROOT_SOL_DETAIL] $MOD_INTRO"
            update_config_var "description" "$DESCRIPTION" "$MODULE_PROP"
            logowl "Start reboot process"
            sync && logowl "Notify for sync"
            logowl "Execute: setprop sys.powerctl reboot"
            setprop sys.powerctl reboot
            sleep 5
            logowl "Reboot command does NOT take effect, exiting"
            exit 1
        fi
        BRICK_TIMEOUT=$((BRICK_TIMEOUT-1))
        sleep 1
    done

    logowl "Boot complete! Countdown: $BRICK_TIMEOUTs"
    rm -f "$BRICKED_STATE" && logowl "Bricked state reset"
    [ "$LAST_WORKED_TARGET_LIST" = true ] && cp "$TARGET_LIST_BSA" "$TARGET_LIST_LW" && logowl "Copy last worked target list file"
    print_line

    if [ "$SLAY_MODE" = "MB" ] && [ "$MB_UMOUNT_BIND" = true ]; then
        logowl "$MOD_NAME is running on Mount Bind mode"
        logowl "Detect flag MB_UMOUNT_BIND=true"
        logowl "Execute umount process"
        if [ ! -f "$TARGET_LIST_BSA" ]; then
            logowl "Invalid Target List ($MOD_NAME arranged) file!" "ERROR"
        else
            lines_count=0

            while IFS= read -r line || [ -n "$line" ]; do
                lines_count=$((lines_count + 1))

                if ! check_value_safety "line $lines_count" "$line"; then
                    continue
                fi

                line=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
                first_char=$(printf '%s' "$line" | cut -c1)

                [ -z "$line" ] && continue
                [ "$first_char" = "#" ] && continue

                package=$(echo "$line" | cut -d '#' -f1)
                package=$(echo "$package" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
                
                [ -z "$package" ] && continue
                
                case "$package" in
                    *\\*)
                        package=$(echo "$package" | sed -e 's/\\/\//g')
                        ;;
                esac
                logowl "Process path: $package"
                umount -f $package
                result_umount=$?
                logowl "Execute: umount -f $package"
                app_name="$(basename "$package")"
                if [ $result_umount -eq 0 ]; then
                    logowl "Spot $app_name has been unmounted" "TIPS"
                else
                    logowl "Failed to unmount spot $app_name ($result_umount)" "TIPS"
                fi

            done < "$TARGET_LIST_BSA"
        fi
    fi
    print_line
    logowl "service.sh case closed!"
    
    MOD_REAL_TIME_DESC=""
    while true; do
        if [ "$UPDATE_DESC_ON_ACTION" = false ]; then
            print_line
            logowl "Detect flag UPDATE_DESC_ON_ACTION=false"
            logowl "Exit background task"
            exit 0
        fi
        if [ -f "$MODDIR/update" ]; then
            MOD_CURRENT_STATE="update"
        elif [ -f "$MODDIR/remove" ]; then
            MOD_CURRENT_STATE="remove"
        elif [ -f "$MODDIR/disable" ]; then
            MOD_CURRENT_STATE="disable"
        else
            MOD_CURRENT_STATE="enable"
        fi

        if [ "$MOD_CURRENT_STATE" = "update" ]; then
            logowl "Detect update state"
            logowl "Exit background task"
            exit 0
        elif [ "$MOD_CURRENT_STATE" = "remove" ]; then
            MOD_REAL_TIME_DESC="[🗑️Reboot to remove. ⚙️Root: $ROOT_SOL_DETAIL] $MOD_INTRO"
        elif [ "$MOD_CURRENT_STATE" = "disable" ]; then
            MOD_REAL_TIME_DESC="[❌OFF or reboot to turn off. ⚙️Root: $ROOT_SOL_DETAIL] $MOD_INTRO"
        elif [ "$MOD_CURRENT_STATE" = "enable" ]; then
            MOD_REAL_TIME_DESC="$MOD_DESC_OLD"
        fi
        denylist_enforcing_status_update "$MOD_REAL_TIME_DESC"
        sleep 5
    done

} &
