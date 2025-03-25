#!/system/bin/sh
MODDIR=${0%/*}

CONFIG_DIR="/data/adb/bloatwareslayer"

CONFIG_FILE="$CONFIG_DIR/settings.conf"
BRICKED_STATUS="$CONFIG_DIR/bricked"
EMPTY_DIR="$CONFIG_DIR/empty"
TARGET_LIST="$CONFIG_DIR/target.conf"
TARGET_LIST_BSA="$CONFIG_DIR/logs/target_bsa.conf"
LOG_DIR="$CONFIG_DIR/logs"
LOG_FILE="$LOG_DIR/bs_log_brickd_$(date +"%Y-%m-%d_%H-%M-%S").log"

MODULE_PROP="$MODDIR/module.prop"
MOD_NAME="$(sed -n 's/^name=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_AUTHOR="$(sed -n 's/^author=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_VER="$(sed -n 's/^version=\(.*\)/\1/p' "$MODULE_PROP") ($(sed -n 's/^versionCode=\(.*\)/\1/p' "$MODULE_PROP"))"

BRICK_TIMEOUT=180
DISABLE_MODULE_AS_BRICK=true

DIRS_BEING_EFFECTED_FILE="$CONFIG_DIR/logs/timestamp.txt"
SYSTEM_TIMESTAMP="2009-01-01 00:00:00"

config_loader() {
    # config_loader: a function to load the config file saved in $CONFIG_FILE
    # the format of $CONFIG_FILE: value=key, one key-value pair per line
    # for system_app_paths, please keep in a line and separate the paths by a space

    logowl "Loading config"

    brick_timeout=$(init_variables "brick_timeout" "$CONFIG_FILE")
    disable_module_as_brick=$(init_variables "disable_module_as_brick" "$CONFIG_FILE")
    slay_mode=$(init_variables "slay_mode" "$CONFIG_FILE")
    system_timestamp=$(init_variables "system_timestamp" "$DIRS_BEING_EFFECTED_FILE" "true")
    dirs_being_effected=$(init_variables "dirs_being_effected" "$DIRS_BEING_EFFECTED_FILE")

    verify_variables "brick_timeout" "$brick_timeout" "^[1-9][0-9]*$"
    verify_variables "disable_module_as_brick" "$disable_module_as_brick" "^(true|false)$"
    verify_variables "slay_mode" "$slay_mode" "^(MB|MN)$"
    verify_variables "system_timestamp" "$system_timestamp" "^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$"
    verify_variables "dirs_being_effected" "$dirs_being_effected" "^/data/[^/]+(/[^/]+)*$"

}

restore_system_timestamp() {

    logowl "Restore system timestamp"
    logowl "/system timestamp: $SYSTEM_TIMESTAMP"
    logowl "Current being effected dirs: $DIRS_BEING_EFFECTED"

    if [ -n "$DIRS_BEING_EFFECTED" ]; then
        DIRS_BEING_EFFECTED=$(echo "$DIRS_BEING_EFFECTED" | tr ' ' '\n' | sort -u | tr '\n' ' ')
    fi

    logowl "DIRS_BEING_EFFECTED: $DIRS_BEING_EFFECTED (sorted)"

    for dir_being_effected in $DIRS_BEING_EFFECTED; do
        find "$dir_being_effected" -exec touch -d "$SYSTEM_TIMESTAMP" {} \;
    done

    print_line
    logowl "Timestamp result"
    print_line
    if [ -n "$DIRS_BEING_EFFECTED" ]; then
        ls -lR "$DIRS_BEING_EFFECTED" | sed 's/^/- /' >> "$LOG_FILE"
    fi
    print_line
}

. "$MODDIR/aautilities.sh"

init_logowl "$LOG_DIR"
module_intro >> "$LOG_FILE"
show_system_info >> "$LOG_FILE"
print_line
logowl "Starting service.sh"
config_loader
print_line

if [ "$SLAY_MODE" = "MN" ] && [ -f "$DIRS_BEING_EFFECTED_FILE" ]; then
    restore_system_timestamp
fi

{    

    # the code block to wait for system boot complete and judge whether system is being bricked or not
    # this task will run in background mode, it will NOT block the system booting at all so please take it easy
    # $BRICK_TIMEOUT: a key in settings.conf to control the behavior of waiting for system boot complete and the timeout to infer device being bricked
    # DISABLE_MODULE_AS_BRICK: a key in settings.conf to control the behavior when approaching bricked
    # if true, will disable itself and skip mounting
    # if false, will skip mounting ONLY, module itself is still enable

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
    logowl "service.sh case closed!"

} &
