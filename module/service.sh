#!/system/bin/sh
MODDIR=${0%/*}

. "$MODDIR/wanderer.sh"

CONFIG_DIR="/data/adb/bloatwareslayer"

CONFIG_FILE="$CONFIG_DIR/settings.conf"
TARGET_LIST="$CONFIG_DIR/target.conf"
FLAG_BRICKED="$CONFIG_DIR/bricked"

LOG_DIR="$CONFIG_DIR/logs"
LOG_FILE="$LOG_DIR/bs_brickd_$(date +"%Y%m%dT%H%M%S").log"
TARGET_LIST_BSA="$LOG_DIR/target_bsa.conf"

LAST_WORKED_DIR="$CONFIG_DIR/last_worked"
TARGET_LIST_LW="$LAST_WORKED_DIR/target_lw.conf"

MOD_INTRO="Remove bloatwares in systemless way."

config_loader() {

    eco "Load config"

    brick_rescue=$(get_config_var "brick_rescue" "$CONFIG_FILE") || brick_rescue=true
    brick_timeout=$(get_config_var "brick_timeout" "$CONFIG_FILE") || brick_timeout=120
    disable_module_as_brick=$(get_config_var "disable_module_as_brick" "$CONFIG_FILE") || disable_module_as_brick=true
    last_worked_target_list=$(get_config_var "last_worked_target_list" "$CONFIG_FILE") || last_worked_target_list=true
    slay_mode=$(get_config_var "slay_mode" "$CONFIG_FILE") || slay_mode=MB
    mb_umount_bind=$(get_config_var "mb_umount_bind" "$CONFIG_FILE") || mb_umount_bind=true
    auto_update_target_list=$(get_config_var "auto_update_target_list" "$CONFIG_FILE") || auto_update_target_list=true

}

eco_init "$LOG_DIR"
eco_clean "30"
module_intro >> "$LOG_FILE"
show_system_info >> "$LOG_FILE"
print_line
config_loader
print_line

if [ "$brick_rescue" = true ] && [ -f "$FLAG_BRICKED" ]; then
    eco "Find flag bricked!" "F"
    eco "Skip processing"
    exit 1
fi

eco "Current boot timeout: ${brick_timeout}s"
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    if [ $brick_timeout -le "0" ]; then
        print_line
        eco "Unable to boot after reaching the limit!" "F"
        eco "Set flag bricked"
        touch "$FLAG_BRICKED"
        if [ "$brick_rescue" = false ]; then
            eco "Skip birck rescue" "W"
            exit 1
        fi
        if [ "$disable_module_as_brick" = true ]; then
            eco "Disable $MOD_NAME"
            touch "$MODDIR/disable"
        fi
        DESCRIPTION="[❌Trigger brick rescue! 🔮Root: $ROOT_SOL_DETAIL] $MOD_INTRO"
        update_config_var "description" "$MODULE_PROP" "$DESCRIPTION"
        sync && eco "Notify system for sync"
        eco "setprop sys.powerctl reboot"
        setprop sys.powerctl reboot
        sleep 5
        eco "Reboot command does NOT take effect, exiting"
        exit 1
    fi
    brick_timeout=$((brick_timeout-1))
    sleep 1
done

eco "Boot complete! Countdown: ${brick_timeout}s"
rm -f "$FLAG_BRICKED"
eco "Remove flag bricked"

if [ "$slay_mode" = "MB" ] && [ "$mb_umount_bind" = true ]; then
    print_line
    eco "Unmount bind points"
    print_line
    if [ ! -f "$TARGET_LIST_BSA" ]; then
        eco "$TARGET_LIST_BSA does NOT exist, skip unmounting" "W"
    else
        TOTAL_APPS_COUNT=0
        UMOUNT_APPS_COUNT=0
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

            TOTAL_APPS_COUNT=$((TOTAL_APPS_COUNT + 1))
            eco "Process $package"
            umount -f $package
            result_umount=$?
            eco "umount -f $package ($result_umount)"
            app_name="$(basename "$package")"
            if [ $result_umount -eq 0 ]; then
                UMOUNT_APPS_COUNT=$((UMOUNT_APPS_COUNT + 1))
                eco "$app_name has been unmounted" ">"
            fi

        done < "$TARGET_LIST_BSA"
        print_line
        eco "Total: $TOTAL_APPS_COUNT APP(s)"
        eco "Unmount: $UMOUNT_APPS_COUNT APP(s)"
        print_line
    fi
fi
if [ "$last_worked_target_list" = true ]; then
    eco "Backup last worked target list"
    [ ! -d "$LAST_WORKED_DIR" ] && mkdir -p "$LAST_WORKED_DIR"
    if [ "$auto_update_target_list" = true ]; then
        cp "$TARGET_LIST_BSA" "$TARGET_LIST_LW"
    elif [ "$auto_update_target_list" = false ]; then
        cp "$TARGET_LIST" "$TARGET_LIST_LW"
    fi
fi
if [ "$auto_update_target_list" = true ]; then
    eco "Update target list"
    cp -p "$TARGET_LIST_BSA" "$TARGET_LIST"
fi
eco "Cleanup temporary file"
rm -f "$TARGET_LIST_BSA"
print_line
eco "Case closed!"
