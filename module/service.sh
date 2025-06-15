#!/system/bin/sh
MODDIR=${0%/*}

. "$MODDIR/aa-util.sh"

CONFIG_DIR="/data/adb/bloatwareslayer"

CONFIG_FILE="$CONFIG_DIR/settings.conf"
LOG_DIR="$CONFIG_DIR/logs"
LOG_FILE="$LOG_DIR/bs_brickd_$(date +"%Y%m%dT%H%M%S").log"

BRICKED_STATE="$CONFIG_DIR/bricked"

TARGET_LIST="$CONFIG_DIR/target.conf"
TARGET_LIST_BSA="$LOG_DIR/target_bsa.conf"
TARGET_LIST_LW="$LOG_DIR/target_lw.conf"

MOD_INTRO="Remove bloatware in systemless way."

brick_rescue=true
disable_module_as_brick=true
auto_update_target_list=true
brick_timeout=180
last_worked_target_list=true

slay_mode=MB
mb_umount_bind=true

config_loader() {

    logowl "Load config"

    brick_rescue=$(get_config_var "brick_rescue" "$CONFIG_FILE")
    brick_timeout=$(get_config_var "brick_timeout" "$CONFIG_FILE")
    disable_module_as_brick=$(get_config_var "disable_module_as_brick" "$CONFIG_FILE")
    last_worked_target_list=$(get_config_var "last_worked_target_list" "$CONFIG_FILE")
    slay_mode=$(get_config_var "slay_mode" "$CONFIG_FILE")
    mb_umount_bind=$(get_config_var "mb_umount_bind" "$CONFIG_FILE")
    auto_update_target_list=$(get_config_var "auto_update_target_list" "$CONFIG_FILE")

}

logowl_init "$LOG_DIR"
logowl_clean "30"
module_intro >> "$LOG_FILE"
show_system_info >> "$LOG_FILE"
print_line
logowl "Start service.sh"
print_line
config_loader
print_line

if [ "$auto_update_target_list" = true ]; then
    logowl "Update target list"
    cp -p "$TARGET_LIST_BSA" "$TARGET_LIST"
fi

logowl "Current boot timeout: ${brick_timeout}s"
while [ "$(getprop sys.boot_completed)" != "1" ]; do

    if [ "$brick_rescue" = false ]; then
        logowl "Detect flag brick_rescue=false" "WARN"
        logowl "$MOD_NAME will NOT take action as brick" "WARN"
        break
    fi

    if [ $brick_timeout -le "0" ]; then
        print_line
        logowl "Detect failed to boot after reaching the limit!" "FATAL"
        logowl "Your device may be bricked by $MOD_NAME!"
        logowl "Mark state as bricked"
        touch "$BRICKED_STATE"
        if [ "$disable_module_as_brick" = true ]; then
            logowl "Detect flag disable_module_as_brick=true"
            logowl "Disable $MOD_NAME"
            touch "$MODDIR/disable"
        else
            logowl "Detect flag disable_module_as_brick=false"
        fi
        DESCRIPTION="[❌No effect. Auto disable from brick! ⚙️Root: $ROOT_SOL_DETAIL] $MOD_INTRO"
        update_config_var "description" "$DESCRIPTION" "$MODULE_PROP"
        logowl "Start reboot process"
        sync && logowl "Notify for sync"
        logowl "setprop sys.powerctl reboot"
        setprop sys.powerctl reboot
        sleep 5
        logowl "Reboot command does NOT take effect, exiting"
        exit 1
    fi
    brick_timeout=$((brick_timeout-1))
    sleep 1
done

logowl "Boot complete! Countdown: ${brick_timeout}s"
rm -f "$BRICKED_STATE"
logowl "Bricked state reset"

if [ "$last_worked_target_list" = true ]; then
    cp "$TARGET_LIST_BSA" "$TARGET_LIST_LW"
    logowl "Copy last worked target list file"
fi

print_line

if [ "$slay_mode" = "MB" ] && [ "$mb_umount_bind" = true ]; then
    logowl "$MOD_NAME is running on Mount Bind mode"
    logowl "Detect flag mb_umount_bind=true"
    logowl "Execute umount process"
    if [ ! -f "$TARGET_LIST_BSA" ]; then
        logowl "Invalid Target List ($MOD_NAME arranged) file!" "ERROR"
    else
        while IFS= read -r line || [ -n "$line" ]; do
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
            logowl "umount -f $package"
            app_name="$(basename "$package")"
            if [ $result_umount -eq 0 ]; then
                logowl "$app_name has been unmounted" ">"
            else
                logowl "Failed to unmount spot $app_name ($result_umount)" ">"
            fi

        done < "$TARGET_LIST_BSA"
    fi
fi

rm -f "$TARGET_LIST_BSA"
logowl "Clean up temporary file"
print_line
logowl "service.sh case closed!"
